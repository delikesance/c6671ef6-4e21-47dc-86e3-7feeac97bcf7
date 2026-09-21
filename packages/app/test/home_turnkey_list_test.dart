// Tests de la liste d'accueil (« MY PROJECTS »).
//
// L'accueil doit réunir les DEUX familles de bots du compte :
//   * les bots classiques (`HomeBotCard`) — rien ne doit disparaître ;
//   * les conteneurs clé en main / « turnkey » (créés depuis « Deploy Turnkey
//     Bot », ex. image ghcr.io/.../beatdock:latest), qui n'apparaissaient
//     jusqu'ici que dans l'écran séparé « Turnkey Bots ».
//
// La composition testée est celle réellement rendue par `HomePage` :
// `buildHomeProjectCards` produit la séquence de cartes (bots puis conteneurs),
// et chaque carte vient du même widget que la production.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/presentation/home_turnkey_container_card.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

const String _beatdockImage = 'ghcr.io/albertgzmz/beatdock:latest';
const String _turnkeyContainerId = '95d85ac8-bd42-41c6-9392-3a1f0c9b7d21';
const String _classicBotName = 'JeanMichel';

/// Conteneur clé en main tel que le renvoie `GET /containers`.
ContainerInfo _container({
  String id = _turnkeyContainerId,
  String state = 'RUNNING',
  String image = _beatdockImage,
  Duration ttl = const Duration(hours: 3),
}) {
  final now = DateTime.now().toUtc();
  return ContainerInfo.fromJson(<String, dynamic>{
    'id': id,
    'owner_id': 'owner-1',
    'swarm_service_id': 'svc-1',
    'image': image,
    'cpu_millis': 250,
    'memory_mb': 256,
    'storage_gb': 1,
    'state': state,
    'health_status': 'healthy',
    'expires_at': now.add(ttl).toIso8601String(),
    'created_at': now.toIso8601String(),
    'updated_at': now.toIso8601String(),
  });
}

/// Carte d'un bot classique du pool, telle que `HomePage` la construit.
HomeBotCard _classicBotCard({
  required TickerProvider vsync,
  String name = _classicBotName,
  String id = '222222222222222222',
  int guildCount = 2,
  bool isRunning = true,
}) {
  return HomeBotCard(
    name: name,
    id: id,
    avatar: null,
    guildCount: guildCount,
    isRunning: isRunning,
    canToggle: true,
    isTogglingThisBot: false,
    initiallyExpanded: true,
    pulseController: AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 900),
    ),
    onManage: () {},
    onToggle: () {},
    onAddTime: () {},
    onLogs: () {},
    showPremiumLabels: false,
    freeMinutes: 30,
  );
}

/// Actions inertes : la carte n'est pas actionnée dans ces tests.
HomeContainerActions _noopActions() {
  return HomeContainerActions(
    onStart: () {},
    onStop: () {},
    onLogs: () {},
    onDetail: () {},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Les polices utilisées par l'accueil sont embarquées : interdire le
    // téléchargement à l'exécution transforme toute famille non embarquée en
    // échec visible au lieu d'une requête réseau silencieuse.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget host(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets(
    'un conteneur clé en main apparaît dans la liste d\'accueil, à côté du bot classique',
    (tester) async {
      final cards = buildHomeProjectCards(
        botCards: <Widget>[_classicBotCard(vsync: tester)],
        containers: <ContainerInfo>[_container()],
        actionsFor: (_) => _noopActions(),
      );

      await tester.pumpWidget(host(Column(children: cards)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Les deux familles cohabitent dans la même liste.
      expect(find.byType(HomeBotCard), findsOneWidget);
      expect(find.byType(HomeTurnkeyContainerCard), findsOneWidget);

      // Le bot classique reste affiché, inchangé.
      expect(find.text(_classicBotName), findsOneWidget);
      expect(find.text('Actif sur 2 serveurs'), findsOneWidget);

      // Le conteneur clé en main est identifiable : modèle, image, état.
      expect(find.text('Bot musique simple'), findsOneWidget);
      expect(find.text('Image: $_beatdockImage'), findsOneWidget);
      expect(find.text('En cours'), findsOneWidget);
      expect(find.text('Bot Clé en main'), findsOneWidget);

      // Ses actions propres : démarrer/arrêter, logs, ajouter du temps.
      final containerCard = find.byType(HomeTurnkeyContainerCard);
      expect(
        find.descendant(of: containerCard, matching: find.text('Arrêter')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: containerCard, matching: find.text('Logs du bot')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: containerCard,
          // L'entrée de la carte mène à la GESTION (page de détail : temps,
          // ressources, suppression). C'était « Ajouter du temps » — un raccourci
          // qui n'avait de sens que parce qu'il ouvrait cette page par effet de bord.
          matching: find.text('Détails'),
        ),
        findsOneWidget,
      );

      // Un bot hébergé n'a AUCUNE configuration à éditer : pas de « Gérer ».
      expect(
        find.descendant(of: containerCard, matching: find.text('Gérer')),
        findsNothing,
      );
      // Le bot classique, lui, garde son action de gestion.
      expect(
        find.descendant(
          of: find.byType(HomeBotCard),
          matching: find.text('Gérer'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'un conteneur clé en main arrêté et expiré est signalé clairement',
    (tester) async {
      final cards = buildHomeProjectCards(
        botCards: <Widget>[_classicBotCard(vsync: tester)],
        containers: <ContainerInfo>[
          _container(state: 'STOPPED', ttl: const Duration(minutes: -5)),
        ],
        actionsFor: (_) => _noopActions(),
      );

      await tester.pumpWidget(host(Column(children: cards)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Arrêté'), findsOneWidget);
      expect(find.text('Expiré'), findsOneWidget);
      // Le bot classique n'est pas masqué par l'état du conteneur.
      expect(find.text(_classicBotName), findsOneWidget);
    },
  );

  testWidgets(
    'sans conteneur, la liste d\'accueil reste exactement celle des bots classiques',
    (tester) async {
      final cards = buildHomeProjectCards(
        botCards: <Widget>[_classicBotCard(vsync: tester)],
        containers: const <ContainerInfo>[],
        actionsFor: (_) => _noopActions(),
      );

      await tester.pumpWidget(host(Column(children: cards)));
      await tester.pumpAndSettle();

      expect(cards.length, 1);
      expect(find.byType(HomeTurnkeyContainerCard), findsNothing);
      expect(find.text(_classicBotName), findsOneWidget);
    },
  );

  testWidgets(
    'deux conteneurs clé en main sont tous deux listés (clés distinctes)',
    (tester) async {
      final cards = buildHomeProjectCards(
        botCards: <Widget>[_classicBotCard(vsync: tester)],
        containers: <ContainerInfo>[
          _container(),
          _container(
            id: '7c1f0e4a-0000-4000-8000-abcdef123456',
            state: 'STOPPED',
            image: 'ghcr.io/example/other-bot:v2',
          ),
        ],
        actionsFor: (_) => _noopActions(),
      );

      await tester.pumpWidget(host(Column(children: cards)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeTurnkeyContainerCard), findsNWidgets(2));
      expect(find.text('ghcr.io/example/other-bot:v2'), findsOneWidget);
      expect(find.text('Arrêté'), findsOneWidget);
    },
  );

  testWidgets(
    'un conteneur clé en main avec nom et avatar Discord affiche le nom du bot, HomeBotAvatar et le badge clé en main',
    (tester) async {
      final now = DateTime.now().toUtc();
      final container = ContainerInfo.fromJson(<String, dynamic>{
        'id': 'turnkey-with-identity',
        'owner_id': 'owner-1',
        'image': _beatdockImage,
        'cpu_millis': 250,
        'memory_mb': 256,
        'storage_gb': 1,
        'state': 'RUNNING',
        'discord_application_id': '123456789012345678',
        'discord_bot_name': 'Super Beat Bot',
        'discord_bot_avatar': 'abcdef1234567890',
        'expires_at': now.add(const Duration(hours: 2)).toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      });

      final cards = buildHomeProjectCards(
        botCards: const <Widget>[],
        containers: <ContainerInfo>[container],
        actionsFor: (_) => _noopActions(),
      );

      await tester.pumpWidget(host(Column(children: cards)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // Le nom Discord du bot est affiché plutôt que le nom générique du template ("Bot musique simple")
      expect(find.text('Super Beat Bot'), findsOneWidget);
      expect(find.text('Bot musique simple'), findsNothing);

      // Le badge Clé en main est strictement conservé
      expect(find.text('Bot Clé en main'), findsOneWidget);

      // HomeBotAvatar est utilisé pour afficher l'avatar Discord
      expect(find.byType(HomeBotAvatar), findsOneWidget);
      final avatarWidget = tester.widget<HomeBotAvatar>(
        find.byType(HomeBotAvatar),
      );
      expect(
        avatarWidget.imageUrl,
        contains('123456789012345678/abcdef1234567890.png'),
      );
    },
  );

  test(
    'botNameHidesIdentity identifie correctement les noms masquant l\'identité',
    () {
      const botId = '1488275294295949504';
      expect(botNameHidesIdentity(null, botId), isTrue);
      expect(botNameHidesIdentity('', botId), isTrue);
      expect(botNameHidesIdentity('   ', botId), isTrue);
      expect(botNameHidesIdentity('Unnamed Bot', botId), isTrue);
      expect(botNameHidesIdentity('Unknown App', botId), isTrue);
      expect(botNameHidesIdentity(botId, botId), isTrue);
      expect(botNameHidesIdentity('1488275294295949504', botId), isTrue);
      expect(botNameHidesIdentity('987654321012345678', botId), isTrue);

      // Vrais noms valides
      expect(botNameHidesIdentity('My Cool Music Bot', botId), isFalse);
      expect(botNameHidesIdentity('JeremyBot', botId), isFalse);
    },
  );
}
