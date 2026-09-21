// Résilience de l'AFFICHAGE des annonces : ce que ce fichier verrouille, c'est
// qu'une annonce n'est JAMAIS consommée sans avoir été lue.
//
// Deux défauts, tous deux invisibles à l'œil :
//   * le lookup de l'emplacement d'affichage cherchait un widget FOURNI PAR UN
//     DESCENDANT du contexte de référence — `Overlay.maybeOf` sur le contexte
//     du Navigator (l'overlay est SOUS le Navigator) rendait donc toujours
//     `null` : aucune bannière n'était montée ;
//   * la marque « vue » est écrite AVANT l'affichage (c'est elle qui garantit
//     « jamais deux fois »), donc un échec de présentation CONSOMMAIT l'annonce
//     en silence : elle ne se représentait jamais.
//
// Les quatre tests ci-dessous tombent quand l'une ou l'autre correction
// manque, et l'invariant d'origine reste vérifié : une annonce réellement
// affichée ne se remontre pas.
//
// Hermétisme : le magasin sécurisé n'a pas de plugin natif en test, la lecture
// de session passe donc par un canal simulé (sans quoi « pas de session »
// dépendrait de la machine qui lance la suite).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations_fr.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/secure/secure_storage_service.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';
import 'package:bot_creator/features/announcements/logic/announcement_presenter.dart';
import 'package:bot_creator/features/announcements/logic/announcement_service.dart';
import 'package:bot_creator/features/announcements/presentation/announcement_banner.dart';

final AppLocalizationsFr tr = AppLocalizationsFr();

const String _bannerId = 'ann-resilience';
const String _bannerTitle = 'Maintenance planifiée';
const String _bannerBody = 'Le service sera indisponible 10 minutes.';

List<Map<String, dynamic>> _bannerPayload() => <Map<String, dynamic>>[
  <String, dynamic>{
    'id': _bannerId,
    'title': _bannerTitle,
    'body': _bannerBody,
    'severity': 'info',
  },
];

MainApiClient _fakeClient() => MainApiClient(
  baseUrl: 'https://announcements.test',
  accessToken: 'jeton-de-test',
);

/// Racine de navigation réelle : c'est elle que le service utilise pour monter
/// la bannière (l'overlay est un DESCENDANT de ce contexte).
Widget _host(GlobalKey<NavigatorState> navigatorKey) => MaterialApp(
  navigatorKey: navigatorKey,
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const Scaffold(body: SizedBox.shrink()),
);

/// Clés « vue » réellement écrites dans `SharedPreferences`.
Set<String> _seenIds(SharedPreferences prefs) =>
    AnnouncementSeenStore.idsFromKeys(prefs.getKeys());

// ── Session persistée simulée (même montage que les tests de câblage) ───────

const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

Future<Object?> _handleSecureStorageCall(MethodCall call) async {
  switch (call.method) {
    case 'read':
      final arguments = call.arguments;
      final key = arguments is Map ? arguments['key'] : null;
      if (key != 'main_api_session') return null;
      return jsonEncode(
        MainApiSession(
          accessToken: 'jeton-de-test',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
        ).toJson(),
      );
    case 'containsKey':
      return false;
    default:
      return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          _secureStorageChannel,
          _handleSecureStorageCall,
        );
    await SecureStorageService.instance;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    MainApiSettingsStore.invalidateSessionCache();
    AnnouncementService.debugResetForTests();
    AnnouncementService.navigatorKey = null;
  });

  tearDown(() {
    AnnouncementService.debugDetach();
    AnnouncementService.debugResetForTests();
    AnnouncementService.navigatorKey = null;
  });

  testWidgets(
    'la bannière se monte réellement : le lookup vise l\'overlay de la racine '
    'de navigation, pas un repère fourni par une entrée d\'overlay',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      AnnouncementService.debugClientResolver = () async => _fakeClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async =>
          _bannerPayload();

      await tester.pumpWidget(_host(navigatorKey));

      await AnnouncementService.refresh();
      await tester.pump();

      expect(
        find.byType(AnnouncementBanner),
        findsOneWidget,
        reason:
            'L\'overlay est un DESCENDANT du contexte du Navigator : le lookup '
            'doit viser `NavigatorState.overlay`.',
      );
      expect(find.text(_bannerTitle), findsOneWidget);
      expect(find.text(_bannerBody), findsOneWidget);
      // Sur écran large (test par défaut 800x600) : toast en bas à droite
      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(AnnouncementBanner),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.bottom, isNotNull);
      expect(positioned.right, 16);
      expect(positioned.top, isNull);

      // Affichée pour de vrai : la marque « vue » est posée.
      final prefs = await SharedPreferences.getInstance();
      expect(_seenIds(prefs), <String>{_bannerId});
    },
  );

  testWidgets(
    'sur écran compact : la bannière se place en haut sous la barre d\'état',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      AnnouncementService.debugClientResolver = () async => _fakeClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async =>
          _bannerPayload();

      await tester.pumpWidget(_host(navigatorKey));
      await AnnouncementService.refresh();
      await tester.pump();

      expect(find.byType(AnnouncementBanner), findsOneWidget);
      final positioned = tester.widget<Positioned>(
        find.ancestor(
          of: find.byType(AnnouncementBanner),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.top, isNotNull);
      expect(positioned.left, 12);
      expect(positioned.right, 12);
      expect(positioned.bottom, isNull);
    },
  );

  testWidgets(
    'emplacement d\'affichage indisponible : l\'annonce n\'est PAS consommée, '
    'la marque « vue » est annulée et l\'échec est journalisé',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      AnnouncementService.debugClientResolver = () async => _fakeClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async =>
          _bannerPayload();
      // L'overlay est résolu APRÈS l'écriture de la marque : l'app peut s'être
      // démontée pendant cette attente (cas réel, non reproductible par le seul
      // ordonnancement des `pump`).
      AnnouncementService.debugBannerHostOverride = () => null;

      await tester.pumpWidget(_host(navigatorKey));

      await AnnouncementService.refresh();
      await tester.pump();

      // Rien à l'écran — mais surtout : rien de CONSOMMÉ.
      expect(find.byType(AnnouncementBanner), findsNothing);
      expect(tester.takeException(), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(
        _seenIds(prefs),
        isEmpty,
        reason:
            'Une présentation qui échoue ne doit pas marquer l\'annonce comme '
            'vue : sinon elle serait perdue sans avoir été lue.',
      );
      expect(
        AnnouncementService.debugLastDisplayFailure,
        isNotNull,
        reason: 'L\'échec doit être journalisé, jamais un no-op muet.',
      );
    },
  );

  testWidgets(
    'après un échec de présentation, la récupération suivante représente '
    'l\'annonce',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      AnnouncementService.debugClientResolver = () async => _fakeClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async =>
          _bannerPayload();
      AnnouncementService.debugBannerHostOverride = () => null;

      await tester.pumpWidget(_host(navigatorKey));

      await AnnouncementService.refresh();
      await tester.pump();
      expect(find.byType(AnnouncementBanner), findsNothing);

      // L'emplacement existe à nouveau (premier plan, app remontée).
      AnnouncementService.debugBannerHostOverride = null;
      await AnnouncementService.refresh(force: true);
      await tester.pump();

      expect(
        find.byType(AnnouncementBanner),
        findsOneWidget,
        reason: 'L\'annonce non lue doit être représentée.',
      );
      expect(find.text(_bannerTitle), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(_seenIds(prefs), <String>{_bannerId});
    },
  );

  testWidgets(
    'une annonce réellement affichée ne se remontre jamais (la garantie '
    'd\'origine reste intacte après annulation)',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      AnnouncementService.debugClientResolver = () async => _fakeClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async =>
          _bannerPayload();

      await tester.pumpWidget(_host(navigatorKey));

      await AnnouncementService.refresh();
      await tester.pump();
      expect(find.byType(AnnouncementBanner), findsOneWidget);
      expect(AnnouncementService.debugLastDisplayFailure, isNull);

      // Fermeture par la croix, puis nouvelle récupération.
      await tester.tap(find.byTooltip(tr.announcement_dismiss));
      await tester.pump();
      expect(find.byType(AnnouncementBanner), findsNothing);

      await AnnouncementService.refresh(force: true);
      await tester.pump();
      expect(
        find.byType(AnnouncementBanner),
        findsNothing,
        reason: 'Vue, donc jamais deux fois — même après une relance.',
      );
      expect(find.text(_bannerTitle), findsNothing);
    },
  );

  testWidgets(
    'quand un hôte en ligne écoute, la bannière s\'affiche sans créer d\'overlay',
    (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      AnnouncementService.navigatorKey = navigatorKey;
      AnnouncementService.debugClientResolver = () async => _fakeClient();
      AnnouncementService.debugAnnouncementsFetcher = (_) async =>
          _bannerPayload();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('fr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ValueListenableBuilder<Announcement?>(
              valueListenable: AnnouncementPresenter.bannerNotifier,
              builder: (context, announcement, _) {
                if (announcement == null) return const Text('aucun bandeau');
                return AnnouncementBanner(
                  announcement: announcement,
                  onDismiss: AnnouncementPresenter.dismissBanner,
                );
              },
            ),
          ),
        ),
      );

      expect(AnnouncementPresenter.hasInlineHost, isTrue);
      await AnnouncementService.refresh();
      await tester.pump();

      // Rendu dans le corps directement, pas dans un Positioned d'overlay flottant.
      expect(find.byType(AnnouncementBanner), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(AnnouncementBanner),
          matching: find.byType(Positioned),
        ),
        findsNothing,
      );

      // Fermeture via dismissBanner
      await tester.tap(find.byTooltip(tr.announcement_dismiss));
      await tester.pump();

      expect(find.byType(AnnouncementBanner), findsNothing);
      expect(find.text('aucun bandeau'), findsOneWidget);
    },
  );
}
