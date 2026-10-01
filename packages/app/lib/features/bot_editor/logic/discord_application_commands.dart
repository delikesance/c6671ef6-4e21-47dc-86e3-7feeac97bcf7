import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:flutter/foundation.dart';
import 'package:bot_creator_shared/utils/command_trigger_type.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/utils/application_command_lookup.dart';

bool isUnknownDiscordApplicationCommandError(Object error) {
  final message = error.toString();
  return message.contains('10063') ||
      message.contains('Unknown application command');
}

/// Deletes every global application command registered on Discord for [botId].
///
/// Returns the number of commands successfully deleted. No-ops when the bot
/// token is missing or [botId] is empty.
Future<int> deleteAllDiscordApplicationCommands(String botId) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return 0;
  }

  final app = await AppManager().getApp(trimmedBotId);
  final token = (app['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    debugPrint(
      '[DiscordCommands] Skipping delete: no token for bot $trimmedBotId.',
    );
    return 0;
  }

  try {
    final rest = await Nyxx.connectRest(token);
    try {
      return await _deleteEveryRegisteredCommand(rest);
    } finally {
      rest.close();
    }
  } on Object catch (error) {
    debugPrint(
      '[DiscordCommands] Failed to delete commands for bot $trimmedBotId: $error',
    );
    return 0;
  }
}

Future<int> _deleteEveryRegisteredCommand(NyxxRest rest) async {
  final remoteCommands = await rest.commands.list();
  var deletedCount = 0;
  for (final command in remoteCommands) {
    try {
      await rest.commands.delete(command.id);
      deletedCount++;
    } catch (error) {
      if (!isUnknownDiscordApplicationCommandError(error)) {
        rethrow;
      }
    }
  }
  debugPrint('[DiscordCommands] Deleted $deletedCount command(s) on Discord.');
  return deletedCount;
}

/// Ce qu'une commande locale doit devenir sur Discord.
///
/// `null` (voir [discordCommandPlanFromStoredCommand]) signifie : cette commande
/// ne doit PAS exister sur Discord.
@immutable
class DiscordCommandPlan {
  const DiscordCommandPlan({
    required this.name,
    required this.type,
    required this.description,
    required this.options,
    this.defaultMemberPermissions,
  });

  final String name;
  final ApplicationCommandType type;
  final String description;
  final List<CommandOptionBuilder> options;
  final Permissions? defaultMemberPermissions;
}

/// Une commande déjà présente sur Discord, réduite à ce dont la réconciliation a
/// besoin : de quoi la reconnaître (son NOM) et de quoi la retirer (son id).
@immutable
class DiscordRemoteCommand {
  const DiscordRemoteCommand({
    required this.id,
    required this.name,
    this.type = ApplicationCommandType.chatInput,
  });

  final String id;
  final String name;
  final ApplicationCommandType type;
}

/// Ce que la réconciliation attend de Discord.
///
/// POURQUOI cette interface : le noyau de la réconciliation est ainsi testable
/// sans réseau ni jeton. Un faux de trois méthodes prouve qu'une commande
/// manquante est recréée et qu'une commande locale seulement n'est jamais
/// exposée — exactement ce que le bouton ne faisait pas.
abstract class DiscordApplicationCommandsApi {
  Future<List<DiscordRemoteCommand>> listCommands();

  /// Crée la commande et rend son identifiant Discord.
  Future<DiscordRemoteCommand> createCommand(DiscordCommandPlan plan);

  Future<void> deleteCommand(String id);
}

/// Traduit un enregistrement local en ce qui doit être enregistré sur Discord.
///
/// Rend `null` quand la commande ne doit PAS y figurer :
/// - pas de nom exploitable ;
/// - commande LOCALE SEULEMENT ou en mode legacy (préfixe BDScript) : l'éditeur
///   ne les enregistre jamais sur Discord, les recréer ici les exposerait.
///
/// Les `integrationTypes`/`contexts` ne sont pas conservés localement (l'éditeur
/// les pose sur Discord sans les stocker) : une commande recréée reprend les
/// valeurs Discord par défaut.
DiscordCommandPlan? discordCommandPlanFromStoredCommand(
  Map<String, dynamic> stored,
) {
  final name = (stored['name'] ?? '').toString().trim();
  if (name.isEmpty) {
    return null;
  }

  final rawData = stored['data'];
  final data = rawData is Map
      ? Map<String, dynamic>.from(rawData)
      : const <String, dynamic>{};

  if (const {'prefix', 'none'}.contains(commandTriggerType(stored))) {
    return null;
  }

  final typeText = (stored['type'] ?? 'chatInput').toString().trim();
  final type = switch (typeText) {
    'user' => ApplicationCommandType.user,
    'message' => ApplicationCommandType.message,
    _ => ApplicationCommandType.chatInput,
  };

  final rawOptions = data['options'];
  final options = type == ApplicationCommandType.chatInput && rawOptions is List
      ? deserializeCommandOptions(rawOptions)
      : const <CommandOptionBuilder>[];

  final description = (stored['description'] ?? '').toString().trim();
  final permissions = int.tryParse(
    (data['defaultMemberPermissions'] ?? '').toString().trim(),
  );

  return DiscordCommandPlan(
    name: name,
    type: type,
    // Discord refuse une description vide sur une commande `/`.
    description: description.isEmpty ? name : description,
    options: options,
    defaultMemberPermissions: permissions == null || permissions < 0
        ? null
        : Permissions(permissions),
  );
}

/// Bilan honnête de la réconciliation : ce qui a changé, et ce qui a échoué.
@immutable
class DiscordCommandReconcileOutcome {
  const DiscordCommandReconcileOutcome({
    required this.created,
    required this.relinked,
    required this.deleted,
    required this.skipped,
    required this.firstFailure,
  });

  final int created;
  final int relinked;
  final int deleted;
  final int skipped;

  /// Première erreur rencontrée : elle doit être DITE, pas noyée dans un bilan
  /// qui ne compterait que les succès.
  final String? firstFailure;

  bool get hasChanges => created + relinked + deleted > 0;
}

/// Aligne les commandes de Discord sur celles du bot.
///
/// Match by name AND type: Discord IDs may differ after an import or restore.
///
/// [onRelink] receives (storage ID, Discord ID, record). The storage ID must
/// remain stable because server history is indexed by that identity.
Future<DiscordCommandReconcileOutcome> reconcileDiscordApplicationCommands({
  required DiscordApplicationCommandsApi api,
  required List<Map<String, dynamic>> localCommands,
  required Future<void> Function(
    String oldId,
    String newId,
    Map<String, dynamic> stored,
  )
  onRelink,
}) async {
  final remoteCommands = await api.listCommands();
  final remoteByName = <String, DiscordRemoteCommand>{
    for (final command in remoteCommands)
      '${command.type}:${command.name.toLowerCase()}': command,
  };

  var created = 0;
  var relinked = 0;
  var skipped = 0;
  String? firstFailure;
  final keptRemoteIds = <String>{};

  for (final stored in localCommands) {
    final plan = discordCommandPlanFromStoredCommand(stored);
    if (plan == null) {
      skipped++;
      continue;
    }

    final localId = (stored['id'] ?? '').toString().trim();
    final discordId = (stored['discordId'] ?? localId).toString().trim();
    final match = remoteByName['${plan.type}:${plan.name.toLowerCase()}'];

    if (match != null) {
      keptRemoteIds.add(match.id);
      if (localId.isEmpty || discordId == match.id) {
        continue;
      }
      try {
        await onRelink(localId, match.id, stored);
        relinked++;
      } catch (error) {
        firstFailure ??= '$error';
      }
      continue;
    }

    try {
      final createdCommand = await api.createCommand(plan);
      keptRemoteIds.add(createdCommand.id);
      created++;
      if (localId.isEmpty || discordId == createdCommand.id) {
        continue;
      }
      try {
        await onRelink(localId, createdCommand.id, stored);
      } catch (error) {
        firstFailure ??= '$error';
      }
    } catch (error) {
      firstFailure ??= '$error';
    }
  }

  var deleted = 0;
  for (final command in remoteCommands) {
    if (keptRemoteIds.contains(command.id)) {
      continue;
    }
    try {
      await api.deleteCommand(command.id);
      deleted++;
    } catch (error) {
      if (isUnknownDiscordApplicationCommandError(error)) {
        continue;
      }
      firstFailure ??= '$error';
    }
  }

  return DiscordCommandReconcileOutcome(
    created: created,
    relinked: relinked,
    deleted: deleted,
    skipped: skipped,
    firstFailure: firstFailure,
  );
}

/// Réconciliation branchée sur Discord pour le bot [botId].
///
/// [api] permet de réutiliser une connexion déjà ouverte (l'écran Réglages a la
/// sienne) ; sans elle, une connexion est créée à partir du jeton stocké, puis
/// fermée.
///
/// Rend `null` quand il n'y a rien à faire SANS erreur — pas de jeton, bot
/// inconnu, ou AUCUNE commande locale à enregistrer. L'appelant doit alors le
/// dire : une liste locale vide n'est pas « rien à faire », c'est le cas où une
/// réconciliation naïve efface toutes les commandes de Discord (configuration
/// locale perdue), donc on refuse.
Future<DiscordCommandReconcileOutcome?> reconcileDiscordCommandsForBot(
  String botId, {
  DiscordApplicationCommandsApi? api,
}) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return null;
  }

  final manager = AppManager();
  final localCommands = await manager.listAppCommands(
    trimmedBotId,
    forceRefresh: true,
  );
  final registrableCount = localCommands
      .where((command) => discordCommandPlanFromStoredCommand(command) != null)
      .length;
  if (registrableCount == 0) {
    debugPrint(
      '[DiscordCommands] Refusing to reconcile bot $trimmedBotId: no local command to register.',
    );
    return null;
  }

  Future<DiscordCommandReconcileOutcome> run(
    DiscordApplicationCommandsApi commandsApi,
  ) {
    return reconcileDiscordApplicationCommands(
      api: commandsApi,
      localCommands: localCommands,
      onRelink: (oldId, newId, stored) async {
        // The file ID is also the server's history key. Never rename it when
        // Discord assigns a new registration ID (including after a restore).
        await manager.saveAppCommand(
          trimmedBotId,
          oldId,
          withDiscordCommandId(stored, oldId, newId),
        );
      },
    );
  }

  if (api != null) {
    return run(api);
  }

  final app = await manager.getApp(trimmedBotId);
  final token = (app['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    debugPrint(
      '[DiscordCommands] Skipping reconcile: no token for bot $trimmedBotId.',
    );
    return null;
  }

  final rest = await Nyxx.connectRest(token);
  try {
    return await run(NyxxApplicationCommandsApi(rest));
  } finally {
    rest.close();
  }
}

/// Adapte le client Nyxx à [DiscordApplicationCommandsApi].
class NyxxApplicationCommandsApi implements DiscordApplicationCommandsApi {
  const NyxxApplicationCommandsApi(this._rest);

  final NyxxRest _rest;

  @override
  Future<List<DiscordRemoteCommand>> listCommands() async {
    final remote = await _rest.commands.list();
    return remote
        .map(
          (command) => DiscordRemoteCommand(
            id: command.id.toString(),
            name: command.name,
            type: command.type,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<DiscordRemoteCommand> createCommand(DiscordCommandPlan plan) async {
    // `ApplicationCommandType` n'est pas une enum dans nyxx : pas de switch
    // exhaustif possible, on teste les deux types sans description puis le
    // cas `/` par défaut (même forme que l'éditeur de commande).
    final ApplicationCommandBuilder builder;
    if (plan.type == ApplicationCommandType.user) {
      builder = ApplicationCommandBuilder.user(name: plan.name);
    } else if (plan.type == ApplicationCommandType.message) {
      builder = ApplicationCommandBuilder.message(name: plan.name);
    } else {
      builder = ApplicationCommandBuilder.chatInput(
        name: plan.name,
        description: plan.description,
        options: plan.options,
      );
    }
    final permissions = plan.defaultMemberPermissions;
    if (permissions != null) {
      builder.defaultMemberPermissions = permissions;
    }

    final created = await _rest.commands.create(builder);
    return DiscordRemoteCommand(
      id: created.id.toString(),
      name: created.name,
      type: created.type,
    );
  }

  @override
  Future<void> deleteCommand(String id) =>
      _rest.commands.delete(Snowflake.parse(id));
}
