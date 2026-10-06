// Harnais PARTAGÉ des tests d'annonces in-app : fixtures, charge utile de
// test, harnais d'overlay et session persistée simulée.
//
// Un SEUL fichier porte ces éléments : les suites découpées par sujet y puisent,
// elles n'en recopient rien. Ce fichier n'est pas une suite de tests (il ne
// finit pas par `_test.dart`), donc le lanceur ne le collecte pas.
//
// Hermétisme : le magasin sécurisé n'a pas de plugin natif en test, donc
// `MainApiSettingsStore.loadSession()` retomberait sur le fichier chiffré de la
// MACHINE qui lance les tests. La voie système est court-circuitée par un canal
// simulé : sans cela, « aucune session » dépendrait de qui exécute la suite.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator_ui/src/l10n/app_localizations_fr.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/secure/secure_storage_service.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';
import 'package:bot_creator/features/announcements/logic/announcement_service.dart';

/// Textes localisés, tels que l'utilisateur les voit.
final AppLocalizationsFr tr = AppLocalizationsFr();

// ── Annonces de test ───────────────────────────────────────────────────────

/// Annonce valide utilisée partout : c'est son TITRE qui doit apparaître.
const String bannerId = 'ann-maintenance';
const String bannerTitle = 'Maintenance planifiée';
const String bannerBody = 'Le service sera indisponible 10 minutes.';

/// Annonce CRITIQUE : le dialogue doit passer par `modalCloseRoutes`.
const String criticalId = 'ann-panne';
const String criticalTitle = 'Panne majeure en cours';

/// Charge utile minimale d'une bannière `info` valide.
List<Map<String, dynamic>> bannerPayload() => <Map<String, dynamic>>[
  <String, dynamic>{
    'id': bannerId,
    'title': bannerTitle,
    'body': bannerBody,
    'severity': 'info',
  },
];

/// Charge utile d'une annonce CRITIQUE, refermable ou non.
List<Map<String, dynamic>> criticalPayload({required bool dismissible}) =>
    <Map<String, dynamic>>[
      <String, dynamic>{
        'id': criticalId,
        'title': criticalTitle,
        'body': 'Le service est indisponible.',
        'severity': 'critical',
        'dismissible': dismissible,
      },
    ];

/// Annonce pure, pour les tests de décision (aucune plateforme en jeu).
Announcement announcement({
  required String id,
  AnnouncementSeverity severity = AnnouncementSeverity.info,
  bool dismissible = true,
}) {
  return Announcement(
    id: id,
    title: 'Titre $id',
    body: 'Corps $id',
    severity: severity,
    dismissible: dismissible,
  );
}

/// Client factice : il n'est JAMAIS utilisé pour une vraie requête, car
/// `debugAnnouncementsFetcher` prend la main avant `getAnnouncements()`.
MainApiClient fakeAnnouncementClient() => MainApiClient(
  baseUrl: 'https://announcements.test',
  accessToken: 'jeton-de-test',
);

/// Racine de navigation réelle : c'est elle que le service utilise pour monter
/// la bannière dans l'overlay et le dialogue.
Widget announcementHost(GlobalKey<NavigatorState> navigatorKey) => MaterialApp(
  navigatorKey: navigatorKey,
  locale: const Locale('fr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  home: const Scaffold(body: SizedBox.shrink()),
);

/// Clés « vue » réellement écrites dans `SharedPreferences`.
Set<String> seenIds(SharedPreferences prefs) =>
    AnnouncementSeenStore.idsFromKeys(prefs.getKeys());

/// Panne réseau simulée (appareil hors ligne).
///
/// Le type exact n'a pas d'importance : le service ne distingue que « le
/// serveur a répondu » (`MainApiClientException`) de « rien n'est arrivé ».
class SimulatedOfflineFailure implements Exception {
  const SimulatedOfflineFailure();

  @override
  String toString() => 'Exception réseau simulée : appareil hors ligne';
}

// ── Session persistée simulée ──────────────────────────────────────────────
//
// `MainApiSettingsStore.loadSession()` lit d'abord le magasin sécurisé du
// système. En test, son implémentation native n'existe pas : le canal est donc
// simulé, et la valeur rendue décide s'il y a une session ou non.

const MethodChannel _secureStorageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

/// Ce que « le trousseau » rend pour la clé de session.
String _secureSessionPayload = '{}';

/// Charge utile d'un magasin sécurisé SANS session : non vide (donc la lecture
/// n'est pas renvoyée vers le fichier chiffré réel), mais sans jeton
/// exploitable.
const String _noSessionPayload = '{}';

Future<Object?> _handleSecureStorageCall(MethodCall call) async {
  switch (call.method) {
    case 'read':
      final arguments = call.arguments;
      final key = arguments is Map ? arguments['key'] : null;
      return key == 'main_api_session' ? _secureSessionPayload : null;
    case 'containsKey':
      // Utilisé par la sonde du plugin : « le plugin natif n'est pas là ».
      return false;
    default:
      return null;
  }
}

/// Annonce une session valide et exploitable au service.
void useValidSession() {
  _secureSessionPayload = jsonEncode(
    MainApiSession(
      accessToken: 'jeton-de-test',
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
    ).toJson(),
  );
}

// ── Branchement du harnais ─────────────────────────────────────────────────

/// À passer à `setUpAll`.
Future<void> setUpAnnouncementHarness() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        _secureStorageChannel,
        _handleSecureStorageCall,
      );
  // Préchauffage : la création du singleton touche le disque (dossiers du
  // coffre), ce qui n'est possible qu'ICI, hors de la zone « fake async » dans
  // laquelle tournent les `testWidgets`.
  await SecureStorageService.instance;
}

/// À passer à `setUp` : préférences vides, aucune session, service remis à zéro.
void resetAnnouncementHarness() {
  SharedPreferences.setMockInitialValues(const <String, Object>{});
  MainApiSettingsStore.invalidateSessionCache();
  AnnouncementService.debugResetForTests();
  AnnouncementService.navigatorKey = null;
  _secureSessionPayload = _noSessionPayload;
}

/// À passer à `tearDown` : l'observateur de cycle de vie est global, le laisser
/// derrière soi ferait réagir le service du test suivant.
void disposeAnnouncementHarness() {
  AnnouncementService.debugDetach();
  AnnouncementService.debugResetForTests();
  AnnouncementService.navigatorKey = null;
}
