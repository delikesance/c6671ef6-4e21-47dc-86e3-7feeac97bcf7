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
//   2. droits du lecteur : jamais lus par la page livrée (`skip: true`, le
//      détail est au-dessus du test) ;
//   3. le propriétaire garde le contrôle d'ajout, sans pouvoir se retirer ;
//   4. le bandeau C1 (« pas dans l'équipe du portail ») est piloté par le
//      `portalLookup` et ne bloque NI la page NI la validation ;
//   5. le fil de tchat rend les messages du plus ancien au plus récent.
//
// Le jeton du bot est lu par la page sur le DISQUE (`AppManager.getApp`) : le
// test mocke donc le dossier documents de `path_provider` et écrit le fichier
// du bot, exactement comme `login_sync_retention_test.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations_fr.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
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

// --- Client simulé ---------------------------------------------------------

/// Session temps réel INERTE : jamais démarrée, donc aucun WebSocket ouvert ;
/// son flux ne pousse rien et ne se ferme pas.
GatewayBotEventsSession _inertGatewaySession() => GatewayBotEventsSession(
  wsUrl: Uri.parse('ws://manager.test/gateway/bots/events'),
  headers: const <String, String>{},
);

/// Client d'API simulé : équipe, tchat et canal d'événements sont servis par
/// le test. Tout appel non surchargé tomberait sur le `MockClient` ci-dessous,
/// qui ne sort jamais du processus.
class _FakeTeamClient extends MainApiClient {
  _FakeTeamClient({required this.collaborators, required this.messages})
    : super(
        baseUrl: 'https://manager.test',
        accessToken: 'jeton-de-compte',
        httpClient: MockClient(
          (http.Request request) async => http.Response(
            '{}',
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          ),
        ),
      );

  final List<Map<String, dynamic>> collaborators;
  final List<Map<String, dynamic>> messages;

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
  Future<Map<String, dynamic>> sendTeamChatMessage(
    String botId,
    String content,
  ) async => const <String, dynamic>{};

  @override
  GatewayBotEventsSession connectGatewayBotEvents() => _inertGatewaySession();
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

  setUp(() => _writeBotRecord(documentsDir));

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

  // CAS 2 — HORS D'ATTEINTE sans refactoriser la page, donc `skip: true` et
  // non un test vert : `TeamChatPage` ne lit JAMAIS les droits du lecteur.
  // La route d'équipe expose bien un bloc `my_permissions`
  // (`MainApiClient.fetchMyTeamPermissions`, utilisé par l'accueil), mais cet
  // onglet ne le demande pas : le bouton « Ajouter par identifiant Discord »
  // est rendu dès qu'un client existe, et l'icône de retrait pour tout
  // collaborateur qui n'est pas le propriétaire — quel que soit le droit du
  // lecteur. C'est le serveur qui refuse (`team_add_error` /
  // `team_remove_error`). Le corps ci-dessous décrit le comportement ATTENDU le
  // jour où l'onglet lira `my_permissions` : il suffira alors de retirer
  // `skip: true` pour l'exiger.
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
      );

      await _pumpTeamPage(tester, client: client);

      // Aucun contrôle d'ajout ni de retrait ne doit être rendu.
      expect(
        find.widgetWithText(TextButton, tr.team_add_by_discord_id),
        findsNothing,
      );
      expect(find.byIcon(Icons.person_remove_outlined), findsNothing);
    },
    skip: true,
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
}
