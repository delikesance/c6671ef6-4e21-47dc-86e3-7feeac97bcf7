import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../commands/action_list.dart';
import '../screens/variables_page.dart';
import '../screens/workflows_page.dart';

/// [EditorHost] du Studio : tout passe par l'API du Manager.
///
/// Pas d'éditeur BDFD ni d'éditeur d'image pour l'instant : les champs
/// correspondants restent éditables en texte (`supportsBdfdEditor` = faux).
class StudioEditorHost extends EditorHost {
  const StudioEditorHost({required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  Future<List<Map<String, dynamic>>> scopedVariableDefinitions(
    String botId,
  ) async => [
    for (final def in await api.scopedDefinitions(botId))
      {
        'key': def.key,
        'scope': def.scope,
        'valueType': def.valueType,
        'defaultValue': def.defaultValue,
      },
  ];

  @override
  Future<Map<String, dynamic>> globalVariables(String botId) =>
      api.globalVariables(botId);

  @override
  Future<List<Map<String, dynamic>>> workflows(String botId) async => [
    for (final w in await api.listWorkflows(botId))
      {
        'name': w.name,
        'workflowType': w.type,
        'executionMode': w.executionMode,
      },
  ];

  @override
  Future<List<Map<String, dynamic>>> appCommands(String botId) async => [
    for (final c in await api.listCommands(botId))
      {'name': c.name, 'folder': ''},
  ];

  @override
  bool get supportsBdfdEditor => true;

  @override
  Future<String?> editBdfdScript(
    BuildContext context, {
    required String initialCode,
    required String backend,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) =>
          BdfdEditorPage(initialCode: initialCode, bdfdBackend: backend),
    ),
  );

  @override
  bool get supportsImageEditor => true;

  @override
  Future<List<Map<String, dynamic>>?> editImageOperations(
    BuildContext context, {
    required List<Map<String, dynamic>> operations,
    required List<VariableSuggestion> variableSuggestions,
  }) => Navigator.of(context).push<List<Map<String, dynamic>>>(
    MaterialPageRoute<List<Map<String, dynamic>>>(
      builder: (_) => ImageEditorPage(
        operations: operations,
        variableSuggestions: variableSuggestions,
      ),
    ),
  );

  @override
  bool get supportsJavascriptEditor => true;

  @override
  Future<String?> editJavascript(
    BuildContext context, {
    required String initialCode,
    required String title,
    required List<Object> snippets,
  }) => Navigator.of(context).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => JsEditorPage(
        initialCode: initialCode,
        title: title,
        snippets: snippets.cast<JsEditorSnippet>(),
      ),
    ),
  );

  @override
  Future<void> manageGlobalVariables(BuildContext context, String botId) =>
      _push(context, VariablesPage(api: api, bot: bot));

  @override
  Future<void> manageWorkflows(BuildContext context, String botId) =>
      _push(context, WorkflowsPage(api: api, bot: bot));

  Future<void> _push(BuildContext context, Widget page) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(appBar: AppBar(), body: page),
        ),
      );
}

/// Planificateur du Studio : les déclencheurs passent par l'API du Manager.
class StudioSchedulerController extends SchedulerController {
  const StudioSchedulerController({
    required this.api,
    required this.botId,
    required this.available,
  });

  final StudioApi api;
  final String botId;

  /// Le forfait du compte ouvre le planificateur.
  final bool available;

  @override
  Future<List<Map<String, dynamic>>> triggers() =>
      api.listScheduledTriggers(botId);

  @override
  Future<List<Map<String, dynamic>>> workflows() async => [
    for (final w in await api.listWorkflows(botId))
      {'name': w.name, 'workflowType': w.type},
  ];

  @override
  Future<void> save({
    required String workflowName,
    required int everyMinutes,
    required bool enabled,
    String? triggerId,
    String? label,
  }) => api.saveScheduledTrigger(botId, triggerId ?? newStorageId(), {
    'workflowName': workflowName,
    'everyMinutes': everyMinutes,
    'enabled': enabled,
    'label': ?label,
  });

  @override
  Future<void> delete(String triggerId) =>
      api.deleteScheduledTrigger(botId, triggerId);

  @override
  bool get hasCapability => available;

  @override
  Widget? upsell(
    BuildContext context,
    Future<void> Function() reload,
  ) => const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Text(
      "Le planificateur est réservé aux comptes Premium. L'abonnement se gère dans l'app.",
    ),
  );
}

/// Webhooks entrants du Studio : le secret n'est jamais relu (le Manager ne le
/// renvoie pas) ; un secret laissé vide est conservé, ou généré par le serveur
/// à la création et montré une seule fois.
class StudioInboundWebhooksController extends InboundWebhooksController {
  const StudioInboundWebhooksController({
    required this.api,
    required this.botId,
    required this.available,
  });

  final StudioApi api;
  final String botId;
  final bool available;

  @override
  Future<List<Map<String, dynamic>>> webhooks() =>
      api.listInboundWebhooks(botId);

  @override
  Future<List<Map<String, dynamic>>> workflows() async => [
    for (final w in await api.listWorkflows(botId))
      {'name': w.name, 'workflowType': w.type},
  ];

  @override
  Future<String?> save({
    required String path,
    required String workflowName,
    required String? secret,
    required bool enabled,
    String? webhookId,
  }) => api.saveInboundWebhook(botId, webhookId ?? newStorageId(), {
    'path': path,
    'workflowName': workflowName,
    'enabled': enabled,
    'secret': ?secret,
  });

  @override
  Future<void> delete(String webhookId) =>
      api.deleteInboundWebhook(botId, webhookId);

  @override
  bool get secretReadable => false;

  @override
  bool get hasCapability => available;

  @override
  Widget? upsell(
    BuildContext context,
    Future<void> Function() reload,
  ) => const Padding(
    padding: EdgeInsets.only(top: 12),
    child: Text(
      "Les webhooks entrants sont réservés aux comptes Premium. L'abonnement se gère dans l'app.",
    ),
  );
}

/// Émojis d'application du Studio : Discord est joint par le Manager.
class StudioEmojisController extends EmojisController {
  const StudioEmojisController({required this.api, required this.botId});

  final StudioApi api;
  final String botId;

  @override
  Future<List<AppEmoji>> list() async => [
    for (final e in await api.listAppEmojis(botId)) AppEmoji.fromJson(e),
  ];

  @override
  Future<AppEmoji> create(String name, String imageDataUri) async =>
      AppEmoji.fromJson(await api.createAppEmoji(botId, name, imageDataUri));

  @override
  Future<AppEmoji> rename(String emojiId, String name) async =>
      AppEmoji.fromJson(await api.renameAppEmoji(botId, emojiId, name));

  @override
  Future<void> delete(String emojiId) => api.deleteAppEmoji(botId, emojiId);
}

/// Marketplace du Studio : le catalogue vient du Manager ; un modèle s'applique
/// par les routes de commandes, de workflows et de variables.
class StudioMarketplaceController extends MarketplaceController {
  const StudioMarketplaceController({
    required this.api,
    required this.bot,
    this.userId,
    this.userName,
  });

  final StudioApi api;
  final StudioBot bot;
  final String? userId;
  final String? userName;

  @override
  bool get canPublish => userId != null && userId!.isNotEmpty;

  @override
  String get authorId => userId ?? '';

  @override
  String get authorName => userName ?? '';

  @override
  Future<TemplatePublishSource> publishSource(String botId) async {
    // Commandes et workflows complets (la liste du Manager est allégée) : une
    // lecture par entrée, en parallèle.
    final commands = await Future.wait([
      for (final c in await api.listCommands(botId))
        api.getCommand(botId, c.id).then((d) => d.raw),
    ]);
    final workflows = await Future.wait([
      for (final w in await api.listWorkflows(botId))
        api.getWorkflow(botId, w.name).then((d) => d.raw),
    ]);
    return TemplatePublishSource(
      commands: commands,
      workflows: workflows,
      appData: {'globalVariables': await api.globalVariables(botId)},
    );
  }

  @override
  Future<void> createTemplate(Map<String, dynamic> template) =>
      api.createMarketplaceTemplate(template);

  @override
  Future<void> updateTemplate(String id, Map<String, dynamic> template) =>
      api.updateMarketplaceTemplate(id, template);

  @override
  Future<List<MarketplaceTemplate>> list() async => [
    for (final t in await api.listMarketplace())
      MarketplaceTemplate.fromJson(t),
  ];

  @override
  Future<MarketplaceTemplate?> get(String id) async =>
      MarketplaceTemplate.fromJson(await api.getMarketplaceTemplate(id));

  @override
  Future<void> rate(String id, double rating) =>
      api.rateMarketplaceTemplate(id, rating);

  @override
  Future<void> delete(String id) => api.deleteMarketplaceTemplate(id);

  @override
  Future<String?> currentUserId() async => userId;

  @override
  Future<String?> apply(
    BuildContext context,
    MarketplaceTemplate template,
    String botId,
    Map<String, String> variables,
  ) async {
    final doneMessage = context.tr.marketplace_apply_success;
    await api.countMarketplaceDownload(template.id, botId, variables);
    for (final entry in variables.entries) {
      await api.setGlobalVariable(botId, entry.key, entry.value);
    }

    final existing = {
      for (final c in await api.listCommands(botId)) c.name.toLowerCase(): c,
    };
    final conflicts = <Map<String, dynamic>>[];
    final fresh = <MapEntry<String, dynamic>>[];
    for (final cmd in template.commands) {
      final name = (resolveTemplateVariables(cmd.name, variables) as String)
          .toLowerCase();
      final local = existing[name];
      if (local == null) {
        fresh.add(MapEntry(name, cmd));
      } else {
        final data = local.card['data'];
        conflicts.add({
          'templateName': cmd.name,
          'resolvedName': name,
          'cmd': cmd,
          'localActions': data is Map && data['actions'] is List
              ? (data['actions'] as List).length
              : 0,
          'templateActions': countTemplateActions(
            Map<String, dynamic>.from(cmd.data),
          ),
        });
      }
    }
    Map<String, bool>? choices;
    if (conflicts.isNotEmpty) {
      if (!context.mounted) return null;
      choices = await showTemplateConflictDialog(context, conflicts, variables);
      if (choices == null || choices.isEmpty) return null;
    }

    var added = 0, replaced = 0, kept = 0;
    Future<void> write(String name, dynamic cmd) async {
      final description =
          resolveTemplateVariables(cmd.description, variables) as String;
      final data =
          resolveTemplateVariables(cmd.data, variables) as Map<String, dynamic>;
      if (data['response'] is Map &&
          (data['response'] as Map).containsKey('_migrated')) {
        data.remove('response');
      }
      data.remove('simpleConfig');
      final id = newStorageId();
      await api.saveCommand(botId, id, {
        'id': id,
        'name': name,
        'description': description,
        'type': data['commandType'] ?? data['type'] ?? 'chatInput',
        'data': data,
      });
    }

    for (final entry in fresh) {
      await write(entry.key, entry.value);
      added++;
    }
    for (final conflict in conflicts) {
      final name = conflict['resolvedName'] as String;
      if (choices?[name] != true) {
        kept++;
        continue;
      }
      await api.deleteCommand(botId, existing[name]!.id, botName: bot.name);
      await write(name, conflict['cmd']);
      replaced++;
    }

    for (final workflow in template.workflows) {
      final resolved =
          resolveTemplateVariables(workflow, variables) as Map<String, dynamic>;
      await api.saveWorkflow(botId, bot.name, resolved);
    }

    final parts = [
      if (added > 0) '$added added',
      if (replaced > 0) '$replaced replaced',
      if (kept > 0) '$kept kept',
    ];
    return parts.isEmpty
        ? doneMessage
        : 'Template applied: ${parts.join(', ')}';
  }
}
