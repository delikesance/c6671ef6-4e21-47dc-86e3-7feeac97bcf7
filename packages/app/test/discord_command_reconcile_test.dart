import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';

/// Faux Discord : liste, création et suppression en mémoire.
///
/// POURQUOI un faux : le défaut corrigé ici est une décision de comparaison
/// (nom contre identifiant). Il se prouve sans réseau — et il DOIT être prouvé,
/// parce que la version par identifiant supprimait les commandes de l'utilisateur.
class _FakeDiscordCommands implements DiscordApplicationCommandsApi {
  _FakeDiscordCommands({
    List<DiscordRemoteCommand> remote = const <DiscordRemoteCommand>[],
    this.createError,
    this.deleteError,
  }) : _remote = List<DiscordRemoteCommand>.of(remote);

  final List<DiscordRemoteCommand> _remote;
  final Object? createError;
  final Object? deleteError;

  final List<DiscordCommandPlan> createdPlans = <DiscordCommandPlan>[];
  final List<String> deletedIds = <String>[];

  int _nextId = 900;

  @override
  Future<List<DiscordRemoteCommand>> listCommands() async =>
      List<DiscordRemoteCommand>.of(_remote);

  @override
  Future<DiscordRemoteCommand> createCommand(DiscordCommandPlan plan) async {
    final error = createError;
    if (error != null) {
      throw error;
    }
    createdPlans.add(plan);
    final created = DiscordRemoteCommand(id: '${_nextId++}', name: plan.name);
    _remote.add(created);
    return created;
  }

  @override
  Future<void> deleteCommand(String id) async {
    final error = deleteError;
    if (error != null) {
      throw error;
    }
    deletedIds.add(id);
    _remote.removeWhere((command) => command.id == id);
  }
}

Map<String, dynamic> _localCommand({
  required String name,
  String id = '',
  String type = 'chatInput',
  String description = 'desc',
  Map<String, dynamic> data = const <String, dynamic>{},
}) {
  return <String, dynamic>{
    'id': id,
    'name': name,
    'type': type,
    'description': description,
    'data': data,
  };
}

void main() {
  group('réconciliation des commandes avec Discord', () {
    test(
      'une commande absente sur Discord est recréée (le bouton ne faisait que supprimer)',
      () async {
        final api = _FakeDiscordCommands();
        final relinks = <String>[];

        final outcome = await reconcileDiscordApplicationCommands(
          api: api,
          localCommands: <Map<String, dynamic>>[_localCommand(name: 'ping', id: 'local-1')],
          onRelink: (oldId, newId, stored) async => relinks.add('$oldId->$newId'),
        );

        expect(outcome.created, 1);
        expect(outcome.deleted, 0);
        expect(api.createdPlans.single.name, 'ping');
        // L'identifiant local est réécrit sous l'identifiant Discord réel : sans
        // cela la dérive recommence au prochain enregistrement du runner.
        expect(relinks, <String>['local-1->900']);
      },
    );

    test(
      'le NOM prime sur l\'identifiant : une commande renommée côté Discord n\'est ni supprimée ni dupliquée',
      () async {
        // C'est le cas de production : le runner réenregistre ses commandes SANS
        // identifiant, donc Discord en attribue de nouveaux à chaque fois.
        final api = _FakeDiscordCommands(
          remote: const <DiscordRemoteCommand>[
            DiscordRemoteCommand(id: '777', name: 'ping'),
          ],
        );
        final relinks = <String>[];

        final outcome = await reconcileDiscordApplicationCommands(
          api: api,
          localCommands: <Map<String, dynamic>>[_localCommand(name: 'ping', id: '241')],
          onRelink: (oldId, newId, stored) async => relinks.add('$oldId->$newId'),
        );

        expect(outcome.created, 0, reason: 'la commande existe déjà, par son nom');
        expect(outcome.deleted, 0, reason: 'elle ne doit surtout pas être supprimée');
        expect(outcome.relinked, 1);
        expect(relinks, <String>['241->777']);
        expect(api.deletedIds, isEmpty);
      },
    );

    test('une commande distante sans équivalent local est supprimée', () async {
      final api = _FakeDiscordCommands(
        remote: const <DiscordRemoteCommand>[
          DiscordRemoteCommand(id: '1', name: 'ping'),
          DiscordRemoteCommand(id: '2', name: 'orpheline'),
        ],
      );

      final outcome = await reconcileDiscordApplicationCommands(
        api: api,
        localCommands: <Map<String, dynamic>>[
          _localCommand(name: 'ping', id: '1'),
          _localCommand(name: 'salut', id: '3'),
        ],
        onRelink: (oldId, newId, stored) async {},
      );

      expect(outcome.deleted, 1);
      expect(api.deletedIds, <String>['2']);
      expect(outcome.created, 1);
      expect(api.createdPlans.single.name, 'salut');
    });

    test('un échec de rattachement ne fait PAS supprimer la commande de Discord', () async {
      final api = _FakeDiscordCommands(
        remote: const <DiscordRemoteCommand>[
          DiscordRemoteCommand(id: '777', name: 'ping'),
        ],
      );

      final outcome = await reconcileDiscordApplicationCommands(
        api: api,
        localCommands: <Map<String, dynamic>>[_localCommand(name: 'ping', id: '241')],
        onRelink: (oldId, newId, stored) async => throw StateError('disque plein'),
      );

      expect(outcome.relinked, 0);
      expect(api.deletedIds, isEmpty);
      expect(outcome.firstFailure, contains('disque plein'));
    });

    test('un échec de création est DIT, jamais compté comme un succès', () async {
      final api = _FakeDiscordCommands(
        createError: StateError('invalid form body'),
      );

      final outcome = await reconcileDiscordApplicationCommands(
        api: api,
        localCommands: <Map<String, dynamic>>[_localCommand(name: 'ping', id: '1')],
        onRelink: (oldId, newId, stored) async {},
      );

      expect(outcome.created, 0);
      expect(outcome.firstFailure, contains('invalid form body'));
      expect(outcome.hasChanges, isFalse);
    });

    test('une suppression refusée n\'est pas comptée, et la commande reste sur Discord', () async {
      final api = _FakeDiscordCommands(
        remote: const <DiscordRemoteCommand>[
          DiscordRemoteCommand(id: '2', name: 'orpheline'),
        ],
        deleteError: StateError('missing permissions'),
      );

      final outcome = await reconcileDiscordApplicationCommands(
        api: api,
        localCommands: <Map<String, dynamic>>[_localCommand(name: 'ping', id: '1')],
        onRelink: (oldId, newId, stored) async {},
      );

      expect(outcome.deleted, 0);
      expect(outcome.firstFailure, contains('missing permissions'));
      expect(
        api.listCommands().then((commands) => commands.map((c) => c.id)),
        completion(contains('2')),
        reason: 'la commande orpheline n\'a pas été supprimée : elle est toujours là',
      );
    });

    test('une commande locale seulement n\'est jamais exposée sur Discord', () async {
      final api = _FakeDiscordCommands();

      final outcome = await reconcileDiscordApplicationCommands(
        api: api,
        localCommands: <Map<String, dynamic>>[
          _localCommand(name: 'secret', data: <String, dynamic>{'legacyLocalOnly': true}),
          _localCommand(name: 'préfixe', data: <String, dynamic>{'legacyModeEnabled': true}),
        ],
        onRelink: (oldId, newId, stored) async {},
      );

      expect(api.createdPlans, isEmpty);
      expect(outcome.created, 0);
      expect(outcome.skipped, 2);
    });
  });

  group('plan d\'enregistrement d\'une commande locale', () {
    test('reprend type, description, options et permissions', () {
      final options = serializeCommandOptions(<CommandOptionBuilder>[
        CommandOptionBuilder(
          type: CommandOptionType.string,
          name: 'cible',
          description: 'Qui viser',
          isRequired: true,
        ),
      ]);

      final plan = discordCommandPlanFromStoredCommand(
        _localCommand(
          name: 'ban',
          data: <String, dynamic>{
            'options': options,
            'defaultMemberPermissions': '8',
          },
        ),
      );

      expect(plan, isNotNull);
      expect(plan!.type, ApplicationCommandType.chatInput);
      expect(plan.options.single.name, 'cible');
      expect(plan.options.single.isRequired, isTrue);
      // Sans les permissions, une commande réservée aux administrateurs
      // redeviendrait ouverte à tous : elles doivent suivre.
      expect(plan.defaultMemberPermissions?.value, 8);
    });

    test('une commande utilisateur/message n\'emporte pas de description ni d\'options', () {
      final plan = discordCommandPlanFromStoredCommand(
        _localCommand(
          name: 'Mon profil',
          type: 'user',
          description: '',
          data: <String, dynamic>{'options': <dynamic>[]},
        ),
      );

      expect(plan, isNotNull);
      expect(plan!.type, ApplicationCommandType.user);
      expect(plan.options, isEmpty);
    });

    test('une description vide reprend le nom (Discord refuse une description vide)', () {
      final plan = discordCommandPlanFromStoredCommand(
        _localCommand(name: 'ping', description: '   '),
      );

      expect(plan!.description, 'ping');
    });

    test('une commande sans nom n\'est pas un plan', () {
      expect(discordCommandPlanFromStoredCommand(_localCommand(name: '  ')), isNull);
    });
  });
}
