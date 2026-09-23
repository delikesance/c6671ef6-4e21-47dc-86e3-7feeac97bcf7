// Tests de l'onglet « Team & Chat » (`TeamChatPage`) : qui travaille sur le bot,
// et ce que l'équipe se dit.
//
// La page est montée pour de vrai, avec ses deux coutures d'injection — un
// client d'API simulé et un `portalLookup` (équipe officielle du portail
// Discord) — donc AUCUN réseau : le canal temps réel est une session jamais
// démarrée (flux inerte), et les autres appels du client tapent un `MockClient`.
//
// Cinq cas, ceux de la livraison — quatre verts, un hors d'atteinte :
//   1. les deux collaborateurs simulés sont rendus ;
//   2. droits du lecteur : un collaborateur sans `can_invite` ne voit AUCUN
//      contrôle de gestion de l'équipe (jamais grisé : absent) ;
//   3. le propriétaire garde le contrôle d'ajout, sans pouvoir se retirer ;
//   4. le bandeau C1 (« pas dans l'équipe du portail ») est piloté par le
//      `portalLookup` et ne bloque NI la page NI la validation ;
//   5. le fil de tchat rend les messages du plus ancien au plus récent.
// S'y ajoutent les cas de la correction : droits RÉELS du lecteur (les quatre
// combinaisons : accordé, refusé, inconnu, appel en échec) et filtre du fil par
// le `bot_id` que le serveur nomme sur l'événement, avec repli sur l'heuristique
// quand il ne le nomme pas.
//
// Le jeton du bot est lu par la page sur le DISQUE (`AppManager.getApp`) : le
// test mocke donc le dossier documents de `path_provider` et écrit le fichier
// du bot, exactement comme `login_sync_retention_test.dart`.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations_fr.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/features/team/logic/team_models.dart';
import 'package:bot_creator/features/team/presentation/team_chat_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _botId = '987654321098765432';
const String _botToken = 'jeton-du-bot-de-test';

/// Le propriétaire, tel que le serveur le renvoie dans la liste d'équipe.
const String _ownerUserId = '111111111111111111';
const String _ownerName = 'Alice Martin';

/// Un collaborateur qui n'a AUCUN droit d'édition : seul le tchat lui est
/// accordé (c'est aussi la forme par défaut de la modale d'ajout).
const String _memberUserId = '222222222222222222';
const String _memberName = 'Bob Durand';
const BotPermissions _noEditRights = BotPermissions(canViewChat: true);

/// Un identifiant qui n'a jamais été vu par le portail Discord.
const String _outsiderUserId = '999999999999999999';

/// Un AUTRE bot du même compte : ses messages passent par le même canal temps
/// réel et ne doivent jamais s'afficher dans le fil de [_botId].
const String _otherBotId = '123456789012345678';

/// Les traductions affichées par la page (elle est montée en français).
final AppLocalizationsFr tr = AppLocalizationsFr();

// --- Données simulées, dans la forme exacte des `fromJson` ------------------

Map<String, dynamic> _collaborator({
  required String userId,
  required String displayName,
  bool isOwner = false,
  BotPermissions permissions = _noEditRights,
}) => <String, dynamic>{
  'user_id': userId,
  'role': isOwner ? 'owner' : 'collaborator',
  'display_name': displayName,
  'is_owner': isOwner,
  'in_discord_team': false,
  'permissions': permissions.toJson(),
};

Map<String, dynamic> _message({
  required int id,
  required String authorUserId,
  required String authorName,
  required String content,
  required DateTime at,
}) => <String, dynamic>{
  'id': id,
  'author_user_id': authorUserId,
  'author_display_name': authorName,
  'content': content,
  'created_at': at.millisecondsSinceEpoch,
};

/// Droits EFFECTIFS du LECTEUR, dans la forme exacte du bloc `my_permissions`
/// de la route d'équipe (`MainApiClient.fetchMyTeamPermissions`).
Map<String, dynamic> _myRights({bool canInvite = false}) => <String, dynamic>{
  'can_edit_commands': false,
  'can_start_stop': false,
  'can_claim_ads': false,
  'can_invite': canInvite,
  'can_view_chat': true,
};

/// Un événement `team.chat.message` EXACTEMENT comme le serveur le pousse : un
/// message pour le bot [botId] (`null` = serveur qui ne le nomme pas).
Map<String, dynamic> _teamChatEvent({
  required String? botId,
  required int id,
  required String authorUserId,
  required String content,
}) => <String, dynamic>{
  'type': 'team.chat.message',
  'owner_id': _botId,
  'team_message': <String, dynamic>{
    'id': id,
    'bot_id': ?botId,
    'author_user_id': authorUserId,
    'author_display_name': authorUserId,
    'content': content,
    'created_at': DateTime.utc(2026, 9, 21, 10).toIso8601String(),
  },
};

// --- Client simulé ---------------------------------------------------------

/// Session temps réel INERTE : jamais démarrée, donc aucun WebSocket ouvert ;
/// son flux ne pousse rien et ne se ferme pas.
GatewayBotEventsSession _inertGatewaySession() => GatewayBotEventsSession(
  wsUrl: Uri.parse('ws://manager.test/gateway/bots/events'),
  headers: const <String, String>{},
);

/// Faux WebSocket piloté par le test : branché sur la VRAIE session du canal
/// temps réel, il permet de pousser un événement serveur pour de vrai
/// ([_FakeChannel.push]) au lieu de simuler l'effet attendu.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri) {
    _ready.complete();
  }

  final Uri uri;
  final StreamController<dynamic> incoming =
      StreamController<dynamic>.broadcast();
  final _FakeSink _sink = _FakeSink();
  final Completer<void> _ready = Completer<void>();

  /// Pousse un message du serveur (encodé JSON) dans le canal.
  void push(Map<String, dynamic> payload) => incoming.add(jsonEncode(payload));

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  final Completer<void> _closed = Completer<void>();

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    if (!_closed.isCompleted) _closed.complete();
  }

  @override
  void add(dynamic data) {}

  @override
  Future<void> get done => _closed.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Client d'API simulé : équipe, tchat, droits du lecteur et canal
/// d'événements sont servis par le test. Tout appel non surchargé tomberait sur
/// le `MockClient` ci-dessous, qui ne sort jamais du processus.
class _FakeTeamClient extends MainApiClient {
  _FakeTeamClient({
    required this.collaborators,
    required this.messages,
    this.myPermissions,
    this.permissionsFail = false,
    this.gatewaySession,
  }) : super(
         baseUrl: 'https://manager.test',
         accessToken: 'jeton-de-compte',
         httpClient: MockClient(
           (http.Request request) async => http.Response(
             '{}',
             200,
             headers: const <String, String>{
               'content-type': 'application/json',
             },
           ),
         ),
       );

  final List<Map<String, dynamic>> collaborators;
  final List<Map<String, dynamic>> messages;

  /// Droits EFFECTIFS du lecteur (`my_permissions`) : `null` = le serveur n'en
  /// annonce aucun, donc droits INCONNUS et page fermée.
  final Map<String, dynamic>? myPermissions;

  /// Le serveur ne répond pas du tout (panne) : l'appel des droits JETTE.
  final bool permissionsFail;

  /// Session temps réel du test : branchée sur un faux WebSocket, elle permet
  /// de pousser de vrais événements serveur. `null` = session inerte.
  final GatewayBotEventsSession? gatewaySession;

  @override
  Future<List<Map<String, dynamic>>> listTeamCollaborators(
    String botId,
  ) async => collaborators;

  @override
  Future<List<Map<String, dynamic>>> listTeamChatMessages(
    String botId, {
    int? beforeId,
    int limit = 50,
  }) async => messages;

  @override
  Future<Map<String, dynamic>?> fetchMyTeamPermissions(String botId) async {
    if (permissionsFail) {
      throw StateError('droits indisponibles');
    }
    return myPermissions;
  }

  @override
  Future<Map<String, dynamic>> sendTeamChatMessage(
    String botId,
    String content,
  ) async => const <String, dynamic>{};

  @override
  GatewayBotEventsSession connectGatewayBotEvents() =>
      gatewaySession ?? _inertGatewaySession();
}

// --- Montage --------------------------------------------------------------

Widget _host(Widget page) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: AppTheme.darkTheme(),
  home: page,
);

/// Monte la page puis lui laisse finir son chargement.
///
/// Le jeton du bot vient du disque et le portail est résolu en asynchrone
/// réel : les pompages doivent donc céder la main à l'ordonnanceur réel
/// (`runAsync`), sinon la page resterait sur son indicateur de chargement.
Future<void> _pumpTeamPage(
  WidgetTester tester, {
  required MainApiClient client,
  Future<DiscordApplicationOwnerMetadata?> Function(String botToken)?
  portalLookup,
}) async {
  tester.view.physicalSize = const Size(1000, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    _host(
      TeamChatPage(botId: _botId, client: client, portalLookup: portalLookup),
    ),
  );
  await _settleTeamPage(tester);
}

Future<void> _settleTeamPage(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 2));
    });
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// Ouvre la modale d'ajout et y saisit un identifiant Discord.
Future<void> _openAddDialog(WidgetTester tester, String userId) async {
  await tester.tap(find.widgetWithText(TextButton, tr.team_add_by_discord_id));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);

  await tester.enterText(
    find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    ),
    userId,
  );
  await tester.pumpAndSettle();
}

Finder _dialogButton(Type type) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.byType(type));

/// Le contenu d'un message est rendu par un `SelectableText` : `find.text` ne
/// suffit pas à le désigner.
Finder _chatContent(String content) => find.byWidgetPredicate(
  (Widget widget) => widget is SelectableText && widget.data == content,
  description: 'contenu de message « $content »',
);

/// Enregistre le bot dans le dossier documents mocké, avec son jeton.
void _writeBotRecord(Directory documentsDir) {
  final appsDir = Directory('${documentsDir.path}/apps')
    ..createSync(recursive: true);
  File('${appsDir.path}/$_botId.json').writeAsStringSync(
    jsonEncode(<String, dynamic>{
      'id': _botId,
      'name': 'Bot équipe',
      'token': _botToken,
      'workflows': <dynamic>[],
    }),
  );
}

/// Pseudonyme Discord du propriétaire du portail — volontairement distinct du
/// nom d'affichage de l'équipe applicative, pour que `find.text` reste sans
/// ambiguïté entre la carte des collaborateurs et l'encart du portail.
const String _portalOwnerName = 'alice-dev';

/// Équipe du portail Discord : seul le propriétaire de l'application en fait
/// partie — donc l'identifiant [_outsiderUserId] n'y est PAS.
DiscordApplicationOwnerMetadata _portalWithoutOutsider() =>
    DiscordApplicationOwnerMetadata(
      ownerId: _ownerUserId,
      ownerUsername: _portalOwnerName,
      teamId: '',
      teamOwnerUserId: '',
      teamMemberUserIds: const <String>[],
    );

/// L'inverse : le portail répond que [_outsiderUserId] EST de l'équipe.
DiscordApplicationOwnerMetadata _portalWithOutsider() =>
    DiscordApplicationOwnerMetadata(
      ownerId: _ownerUserId,
      ownerUsername: _portalOwnerName,
      teamId: '777777777777777777',
      teamName: 'Équipe officielle',
      teamOwnerUserId: _outsiderUserId,
      teamMemberUserIds: const <String>[_memberUserId],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    documentsDir = await Directory.systemTemp.createTemp('team_chat_page_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {
        // Fichiers verrouillés sous Windows : sans importance pour le test.
      }
    }
  });

  setUp(() async {
    _writeBotRecord(documentsDir);
    // Amorce `AppManager` hors du temps simulé pour éviter le timer de _startStreamUpdateLoop
    final appManager = AppManager();
    await appManager.getAllApps();
    for (var i = 0; i < 300 && !appManager.isInitialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  testWidgets('cas 1 — les deux collaborateurs simulés sont rendus', (
    tester,
  ) async {
    final client = _FakeTeamClient(
      collaborators: <Map<String, dynamic>>[
        _collaborator(
          userId: _ownerUserId,
          displayName: _ownerName,
          isOwner: true,
        ),
        _collaborator(userId: _memberUserId, displayName: _memberName),
      ],
      messages: const <Map<String, dynamic>>[],
    );

    await _pumpTeamPage(tester, client: client);

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Les deux identifiants du serveur sont à l'écran : le collaborateur sans
    // droit d'édition y est comme le propriétaire (le tchat ne se ferme à
    // personne).
    expect(find.text(_ownerName), findsOneWidget);
    expect(find.text(_ownerUserId), findsOneWidget);
    expect(find.text(_memberName), findsOneWidget);
    expect(find.text(_memberUserId), findsOneWidget);

    // Le tchat, vide, le dit sans bloquer la page.
    expect(find.text(tr.team_chat_empty), findsOneWidget);
  });

  // Droits du LECTEUR : la page lit `my_permissions` (via
  // `MainApiClient.fetchMyTeamPermissions`) et ne rend les contrôles d'ajout et
  // de retrait que si le SERVEUR les a accordés. Les quatre combinaisons sont
  // couvertes ici : accordés (cas 3, 6, 4a/4b), refusés (cas 2), inconnus
  // (cas 1, 5 : aucune permission n'est annoncée) et appel en échec (cas 7b).
  testWidgets(
    'cas 2 — un collaborateur sans droit d\'édition ne se voit proposer aucun '
    'contrôle de gestion de l\'équipe',
    (tester) async {
      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          // Le LECTEUR est ici un simple collaborateur : `is_owner: false` et
          // toutes les permissions à `false` (seul le tchat est accordé).
          _collaborator(userId: _memberUserId, displayName: _memberName),
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
        ],
        messages: const <Map<String, dynamic>>[],
        // Le serveur RÉPOND, et il refuse : le lecteur n'a que la lecture du
        // tchat. Les contrôles doivent donc être ABSENTS, pas grisés.
        myPermissions: _myRights(),
      );

      await _pumpTeamPage(tester, client: client);

      // Aucun contrôle d'ajout ni de retrait ne doit être rendu.
      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsNothing,
      );
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);

      // Le reste de la page reste affiché normalement : le refus des droits de
      // gestion ne ferme NI la liste des collaborateurs NI le tchat.
      expect(find.text(_ownerName), findsOneWidget);
      expect(find.text(_memberName), findsOneWidget);
      expect(find.text(tr.team_chat_empty), findsOneWidget);
    },
  );

  testWidgets(
    'cas 3 — le propriétaire garde le contrôle d\'ajout, sans pouvoir se '
    'retirer lui-même',
    (tester) async {
      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
          _collaborator(userId: _memberUserId, displayName: _memberName),
        ],
        messages: const <Map<String, dynamic>>[],
        // Le lecteur est le propriétaire : la route renvoie ses droits
        // EFFECTIFS, et il les a tous (dont `can_invite`).
        myPermissions: _myRights(canInvite: true),
      );

      await _pumpTeamPage(tester, client: client);

      // Le contrôle d'ajout est bien rendu.
      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsOneWidget,
      );

      // Le retrait est proposé pour un collaborateur...
      final memberRow = find.ancestor(
        of: find.text(_memberName),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: memberRow,
          matching: find.byIcon(Icons.person_remove_outlined),
        ),
        findsOneWidget,
      );

      // ... mais jamais pour le propriétaire lui-même.
      final ownerRow = find.ancestor(
        of: find.text(_ownerName),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: ownerRow,
          matching: find.byIcon(Icons.person_remove_outlined),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: ownerRow, matching: find.text(tr.team_owner_badge)),
        findsOneWidget,
      );
    },
  );

  // Le cas 4 tient en DEUX tests : deux montages successifs dans le même test
  // laisseraient la modale du premier vivante dans le `Navigator` réutilisé, et
  // Flutter refuse alors de rebâtir son `StatefulBuilder` (« Looking up a
  // deactivated widget's ancestor »). Chaque montage a donc son propre arbre.
  testWidgets(
    'cas 4a — identifiant absent de l\'équipe du portail : le bandeau C1 est '
    'affiché, sans bloquer ni la page ni la validation',
    (tester) async {
      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
        ],
        messages: const <Map<String, dynamic>>[],
        // La modale d'ajout n'est atteignable que si le droit est accordé.
        myPermissions: _myRights(canInvite: true),
      );
      // Le portail répond que l'identifiant n'est PAS dans son équipe.
      await _pumpTeamPage(
        tester,
        client: client,
        portalLookup: (String botToken) async => _portalWithoutOutsider(),
      );

      await _openAddDialog(tester, _outsiderUserId);

      expect(find.text(tr.team_not_in_portal_warning), findsOneWidget);
      // Informatif, JAMAIS bloquant : le reste de la page est toujours là...
      expect(find.text(_ownerName), findsOneWidget);
      // ...et la validation reste possible malgré le bandeau.
      final saveButton = tester.widget<FilledButton>(
        _dialogButton(FilledButton),
      );
      expect(saveButton.onPressed, isNotNull);
    },
  );

  testWidgets('cas 4b — portail qui répond l\'inverse : aucun bandeau C1', (
    tester,
  ) async {
    final client = _FakeTeamClient(
      collaborators: <Map<String, dynamic>>[
        _collaborator(
          userId: _ownerUserId,
          displayName: _ownerName,
          isOwner: true,
        ),
      ],
      messages: const <Map<String, dynamic>>[],
      // Même droit accordé qu'au cas 4a : seule la réponse du portail change.
      myPermissions: _myRights(canInvite: true),
    );
    // Même identifiant que le cas 4a, mais le portail dit qu'il EST de
    // l'équipe officielle.
    await _pumpTeamPage(
      tester,
      client: client,
      portalLookup: (String botToken) async => _portalWithOutsider(),
    );

    await _openAddDialog(tester, _outsiderUserId);

    expect(find.text(tr.team_not_in_portal_warning), findsNothing);
  });

  testWidgets('cas 5 — le fil de tchat se lit du plus ancien au plus récent', (
    tester,
  ) async {
    const String olderContent = 'Qui relit la commande /ban avant ce soir ?';
    const String newerContent = 'Moi, je la relis après le déploiement.';
    final older = DateTime.utc(2026, 9, 21, 8, 30);
    final newer = DateTime.utc(2026, 9, 21, 9, 45);

    final client = _FakeTeamClient(
      collaborators: <Map<String, dynamic>>[
        _collaborator(
          userId: _ownerUserId,
          displayName: _ownerName,
          isOwner: true,
        ),
      ],
      // Le serveur pagine du PLUS RÉCENT au plus ancien : la page doit
      // remettre le fil dans l'autre sens.
      messages: <Map<String, dynamic>>[
        _message(
          id: 22,
          authorUserId: _memberUserId,
          authorName: _memberName,
          content: newerContent,
          at: newer,
        ),
        _message(
          id: 21,
          authorUserId: _ownerUserId,
          authorName: _ownerName,
          content: olderContent,
          at: older,
        ),
      ],
    );

    await _pumpTeamPage(tester, client: client);

    expect(_chatContent(olderContent), findsOneWidget);
    expect(_chatContent(newerContent), findsOneWidget);
    // Auteurs différents : le message de Bob est bien attribué à Bob.
    expect(find.text(_memberName), findsOneWidget);

    // Ordre chronologique à l'écran.
    expect(
      tester.getTopLeft(_chatContent(olderContent)).dy,
      lessThan(tester.getTopLeft(_chatContent(newerContent)).dy),
    );
  });

  testWidgets(
    'cas 6 — un collaborateur qui a `can_invite` voit le contrôle d\'ajout, '
    'sans pouvoir retirer le propriétaire',
    (tester) async {
      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          // Le LECTEUR est un simple collaborateur (`is_owner: false`) à qui
          // le propriétaire a accordé le droit d'inviter.
          _collaborator(userId: _memberUserId, displayName: _memberName),
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
        ],
        messages: const <Map<String, dynamic>>[],
        myPermissions: _myRights(canInvite: true),
      );

      await _pumpTeamPage(tester, client: client);

      // Le droit d'inviter suffit : le contrôle d'ajout EST rendu.
      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsOneWidget,
      );

      // Le retrait suit le même droit — donc sur la ligne du collaborateur...
      final memberRow = find.ancestor(
        of: find.text(_memberName),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: memberRow,
          matching: find.byIcon(Icons.person_remove_outlined),
        ),
        findsOneWidget,
      );

      // ... mais JAMAIS sur celle du propriétaire, quel que soit le droit du
      // lecteur : il ne se retire pas de son propre bot.
      final ownerRow = find.ancestor(
        of: find.text(_ownerName),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: ownerRow,
          matching: find.byIcon(Icons.person_remove_outlined),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'cas 7a — droits INCONNUS (le serveur n\'annonce rien) : aucun contrôle '
    'de gestion, page intacte',
    (tester) async {
      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          _collaborator(userId: _memberUserId, displayName: _memberName),
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
        ],
        messages: const <Map<String, dynamic>>[],
        // `myPermissions` laissé à `null` : serveur plus ancien, qui ne renvoie
        // pas le bloc. Ne rien savoir ferme les contrôles, jamais l'inverse.
      );

      await _pumpTeamPage(tester, client: client);

      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsNothing,
      );
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);

      // La page, elle, s'affiche normalement.
      expect(tester.takeException(), isNull);
      expect(find.text(_ownerName), findsOneWidget);
      expect(find.text(_memberName), findsOneWidget);
      expect(find.text(tr.team_chat_empty), findsOneWidget);
    },
  );

  testWidgets(
    'cas 7b — l\'appel des droits échoue : aucun contrôle de gestion, page '
    'intacte',
    (tester) async {
      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          _collaborator(userId: _memberUserId, displayName: _memberName),
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
        ],
        messages: const <Map<String, dynamic>>[],
        // Le serveur ne répond pas du tout : l'appel JETTE.
        permissionsFail: true,
      );

      await _pumpTeamPage(tester, client: client);

      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsNothing,
      );
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);

      // L'échec des droits ne casse ni la liste ni le tchat.
      expect(tester.takeException(), isNull);
      expect(find.text(_ownerName), findsOneWidget);
      expect(find.text(_memberName), findsOneWidget);
      expect(find.text(tr.team_chat_empty), findsOneWidget);
    },
  );

  // Le canal temps réel est celui du COMPTE : il pousse les messages de TOUS les
  // bots. L'événement nomme donc le bot concerné (`bot_id`) — et c'est cette
  // autorité qui décide, l'heuristique « l'auteur est-il un membre connu ? » ne
  // servant plus que de repli quand le serveur ne nomme rien.
  testWidgets(
    'cas 8 — le message est retenu sur son `bot_id`, l\'heuristique ne sert '
    'que de repli',
    (tester) async {
      const String newcomerContent = 'Je viens d\'être ajouté, bonjour !';
      const String otherBotContent = 'Message d\'un autre bot de mon compte.';
      const String fallbackContent = 'Serveur qui ne nomme pas le bot.';

      final channel = _FakeChannel(
        Uri.parse('ws://manager.test/gateway/bots/events'),
      );
      final session = GatewayBotEventsSession(
        wsUrl: channel.uri,
        headers: const <String, String>{},
        connector: (Uri uri) => channel,
      );
      addTearDown(session.dispose);
      session.start();

      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
          _collaborator(userId: _memberUserId, displayName: _memberName),
        ],
        messages: const <Map<String, dynamic>>[],
        myPermissions: _myRights(canInvite: true),
        gatewaySession: session,
      );

      await _pumpTeamPage(tester, client: client);

      // 1. Le bon bot est nommé : le message est retenu même si son auteur
      //    n'est PAS encore dans la liste connue — un collaborateur tout juste
      //    ajouté ne perd plus ses premiers messages.
      channel.push(
        _teamChatEvent(
          botId: _botId,
          id: 101,
          authorUserId: _outsiderUserId,
          content: newcomerContent,
        ),
      );
      await _settleTeamPage(tester);
      expect(_chatContent(newcomerContent), findsOneWidget);

      // 2. Un AUTRE bot est nommé : le message est écarté, même si son auteur
      //    est membre de l'équipe de CE bot (l'heuristique le laissait entrer).
      channel.push(
        _teamChatEvent(
          botId: _otherBotId,
          id: 102,
          authorUserId: _memberUserId,
          content: otherBotContent,
        ),
      );
      await _settleTeamPage(tester);
      expect(_chatContent(otherBotContent), findsNothing);

      // 3. Repli : le serveur ne nomme pas le bot, l'auteur est le seul indice
      //    disponible — un membre connu garde alors ses messages.
      channel.push(
        _teamChatEvent(
          botId: null,
          id: 103,
          authorUserId: _memberUserId,
          content: fallbackContent,
        ),
      );
      await _settleTeamPage(tester);
      expect(_chatContent(fallbackContent), findsOneWidget);
    },
  );

  testWidgets(
    'cas 9 — le message sans display_name résout le pseudo depuis le portail',
    (tester) async {
      const String portalUsername = 'garder500';
      const String messageContent = 'Hey';

      final client = _FakeTeamClient(
        collaborators: <Map<String, dynamic>>[
          _collaborator(
            userId: _ownerUserId,
            displayName: _ownerName,
            isOwner: true,
          ),
        ],
        messages: <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 201,
            'author_user_id': _outsiderUserId,
            'author_display_name': '', // pas d'username fourni par le serveur
            'content': messageContent,
            'created_at': DateTime.utc(
              2026,
              9,
              21,
              14,
              54,
            ).millisecondsSinceEpoch,
          },
        ],
      );

      // Le portail connait cet utilisateur sous le pseudo 'garder500'
      await _pumpTeamPage(
        tester,
        client: client,
        portalLookup: (String botToken) async =>
            DiscordApplicationOwnerMetadata(
              ownerId: _ownerUserId,
              ownerUsername: _portalOwnerName,
              teamId: '777777777777777777',
              teamName: 'Équipe officielle',
              teamOwnerUserId: _outsiderUserId,
              teamOwnerUsername: portalUsername,
              teamMemberUserIds: const <String>[_outsiderUserId],
              teamMembersInfo: const <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': _outsiderUserId,
                  'username': portalUsername,
                  'avatar': '',
                  'role': 'admin',
                },
              ],
            ),
      );

      // Le pseudo résolu 'garder500' est affiché comme auteur du message, et non son ID brut
      expect(find.text(portalUsername), findsWidgets);
      expect(_chatContent(messageContent), findsOneWidget);
    },
  );

  testWidgets(
    'cas 10 — sur écran mobile compact, le titre Collaborateurs et le bouton d\'ajout s\'affichent sans écrasement',
    (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final client = _FakeTeamClient(
        collaborators: const <Map<String, dynamic>>[],
        messages: const <Map<String, dynamic>>[],
        myPermissions: _myRights(canInvite: true),
      );

      await tester.pumpWidget(
        _host(TeamChatPage(botId: _botId, client: client)),
      );
      await _settleTeamPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(tr.team_collaborators_title), findsOneWidget);
      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsOneWidget,
      );
    },
  );
}
