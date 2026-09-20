// Logique PURE de la détection de mise à jour : aucune E/S, aucune
// plateforme, aucun plugin. Tout ce fichier est testable tel quel sur la VM
// Dart (`flutter test`), ce qui est la seule façon de verrouiller les deux
// pièges du sujet : la comparaison de versions et la relance du dialogue.
//
// Le service (`app_update_service.dart`) n'a le droit de décider « une mise à
// jour est disponible » QUE via `isNewerVersion` / la réponse Play Core.
import 'dart:convert';

/// Intervalle minimal entre deux vérifications automatiques (démarrage de
/// l'app). Une constante nommée, jamais un littéral sémantique enterré dans le
/// service : c'est un réglage produit.
const Duration kAppUpdateCheckInterval = Duration(hours: 24);

/// Identifiant de boutique de l'app (identique iOS `PRODUCT_BUNDLE_IDENTIFIER`
/// et Android `applicationId` — c'est l'`applicationId` que voit le Play
/// Store, pas le `namespace` Gradle historique).
const String kStoreApplicationId = 'fr.botcreator.app';

/// Endpoint officiel iTunes/App Store, sans clé d'API.
const String kAppStoreLookupEndpoint = 'https://itunes.apple.com/lookup';

/// Pays de repli du lookup quand la locale de l'appareil n'en porte pas.
const String kAppStoreFallbackCountry = 'fr';

/// Fiche Play Store (repli quand Play Core est indisponible : APK sideloadé,
/// Play Store absent ou désactivé sur l'appareil).
Uri playStoreListingUri({String packageId = kStoreApplicationId}) => Uri.https(
  'play.google.com',
  '/store/apps/details',
  <String, String>{'id': packageId},
);

/// Fiche App Store de repli, construite depuis l'id numérique de l'app quand
/// l'API n'a pas rendu de `trackViewUrl`.
Uri appStoreListingUri({required String trackId, required String country}) =>
    Uri.parse('https://apps.apple.com/$country/app/id$trackId');

/// Sources de vérité possibles pour « une mise à jour existe ».
enum AppUpdateSource {
  /// Play Core (`in_app_update`) : la source officielle Android.
  playCore,

  /// Lookup App Store officiel (iOS n'a AUCUNE API d'update in-app).
  appStore,

  /// Rien à interroger (plateforme de bureau, web).
  none,
}

/// Résultat honnête d'une vérification. `unavailable` n'est pas un échec
/// silencieux : l'UI a une clé i18n dédiée pour le dire.
enum AppUpdateCheckStatus {
  /// Une nouvelle version est publiée.
  updateAvailable,

  /// Le store annonce la version installée (ou plus ancienne).
  upToDate,

  /// Réseau absent, JSON illisible, erreur Play Core : on ne SAIT pas.
  unavailable,

  /// Plateforme sans store in-app (desktop, web) : rien à vérifier.
  notSupported,

  /// Vérification sautée par la politique de relance (< 24 h depuis la
  /// dernière tentative). Jamais affiché : c'est le cas normal au démarrage.
  throttled,
}

/// Réponse utile du lookup App Store pour une app donnée.
class AppStoreRelease {
  const AppStoreRelease({
    required this.version,
    required this.storeUri,
    this.trackId,
    this.releaseNotes,
    this.releaseDate,
  });

  /// `results[0].version` — version publiée sur l'App Store.
  final String version;

  /// Fiche App Store (`trackViewUrl`, ou reconstruite depuis `trackId`).
  final Uri storeUri;

  /// `results[0].trackId` (id numérique App Store) quand fourni.
  final String? trackId;

  /// `results[0].releaseNotes` — jamais affiché tel quel dans le dialogue
  /// (non traduit), seulement journalisé / disponible pour un écran détaillé.
  final String? releaseNotes;

  /// `results[0].currentVersionReleaseDate`.
  final String? releaseDate;
}

/// Extrait la version publiée de la réponse iTunes.
///
/// Rend `null` — honnêtement — quand la réponse est illisible
/// (`FormatException`), quand `resultCount == 0` (app absente du store),
/// quand `results` est vide/inattendu, ou quand `version` est absente/vide.
/// Jamais d'exception, jamais de valeur inventée : l'appelant traduit `null`
/// en « vérification impossible ».
AppStoreRelease? parseAppStoreLookup(
  String rawJson, {
  String fallbackCountry = kAppStoreFallbackCountry,
}) {
  if (rawJson.trim().isEmpty) return null;

  Object? decoded;
  try {
    decoded = jsonDecode(rawJson);
  } catch (_) {
    return null;
  }

  if (decoded is! Map) return null;

  final resultCount = decoded['resultCount'];
  final count = resultCount is num ? resultCount.toInt() : null;
  if (count == null || count <= 0) return null;

  final results = decoded['results'];
  if (results is! List || results.isEmpty) return null;

  final first = results.first;
  if (first is! Map) return null;

  final rawVersion = first['version'];
  if (rawVersion is! String || rawVersion.trim().isEmpty) return null;

  final trackId = _nonEmptyString(first['trackId']);
  final trackViewUrl = _nonEmptyString(first['trackViewUrl']);
  // Le pays de repli vient de l'APPELANT (le pays qu'on a interrogé), jamais du
  // champ `country` de la réponse : Apple y met un code à 3 lettres (« FRA »,
  // « USA ») qui n'est pas un segment d'URL de fiche.
  final storeUri = trackViewUrl != null
      ? Uri.tryParse(trackViewUrl)
      : (trackId == null
            ? null
            : appStoreListingUri(
                trackId: trackId,
                country: resolveLookupCountry(fallbackCountry),
              ));
  if (storeUri == null) return null;

  return AppStoreRelease(
    version: rawVersion.trim(),
    storeUri: storeUri,
    trackId: trackId,
    releaseNotes: _nonEmptyString(first['releaseNotes']),
    releaseDate: _nonEmptyString(first['currentVersionReleaseDate']),
  );
}

String? _nonEmptyString(Object? value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

/// Pays (minuscule, 2 lettres) à interroger sur l'App Store.
///
/// Dérivé de la locale de l'appareil ; repli `fr` quand elle ne porte pas de
/// pays (locale posée à la main, `und`, environnement de test) — l'app est
/// publiée en France en premier.
String resolveLookupCountry(String? countryCode) {
  final code = countryCode?.trim().toLowerCase();
  if (code == null || code.isEmpty) return kAppStoreFallbackCountry;
  if (!RegExp(r'^[a-z]{2}$').hasMatch(code)) return kAppStoreFallbackCountry;
  return code;
}

/// Vrai si [storeVersion] est STRICTEMENT plus récente que [installedVersion].
///
/// Comparaison NUMÉRIQUE segment par segment, jamais de comparaison de
/// chaînes : `'2.10.0' < '2.9.0'` en lexicographique, ce qui proposerait une
/// mise à jour à chaque démarrage une fois la 2.10 sortie (et jamais à partir
/// de la 2.2). Règles :
///   - longueurs inégales : segments manquants = 0 (`2.2` vs `2.2.0` → égal) ;
///   - suffixe `+build` ignoré (`2.2.0+94` vs `2.2.0` → égal) ;
///   - suffixe de pré-version `-rc1` ignoré (jamais publié sur un store) ;
///   - préfixe `v` toléré ;
///   - version vide ou format inattendu → `false` : on ne propose JAMAIS une
///     mise à jour sur une comparaison qu'on ne sait pas faire.
bool isNewerVersion(String storeVersion, String installedVersion) {
  final store = _parseVersionSegments(storeVersion);
  final installed = _parseVersionSegments(installedVersion);
  if (store == null || installed == null) return false;

  final length = store.length > installed.length
      ? store.length
      : installed.length;
  for (var index = 0; index < length; index++) {
    final storeSegment = index < store.length ? store[index] : 0;
    final installedSegment = index < installed.length ? installed[index] : 0;
    if (storeSegment != installedSegment) return storeSegment > installedSegment;
  }
  return false;
}

/// Découpe une version en segments numériques, ou `null` si le format n'est
/// pas comparable (chaîne vide, segment non numérique).
List<int>? _parseVersionSegments(String raw) {
  var text = raw.trim();
  if (text.isEmpty) return null;

  if (text.startsWith('v') || text.startsWith('V')) {
    text = text.substring(1).trim();
  }
  // `+build` (Android/iOS build number) et `-prerelease` ne départagent jamais
  // deux versions publiées : ils ne comptent pas dans la décision.
  final plusIndex = text.indexOf('+');
  if (plusIndex >= 0) text = text.substring(0, plusIndex);
  final dashIndex = text.indexOf('-');
  if (dashIndex >= 0) text = text.substring(0, dashIndex);
  text = text.trim();
  if (text.isEmpty) return null;

  final segments = <int>[];
  for (final part in text.split('.')) {
    final segment = part.trim();
    if (segment.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(segment)) return null;
    // `tryParse` et non `parse` : un segment de 20 chiffres fait déborder un
    // entier 64 bits et lèverait `FormatException` — `isNewerVersion` ne doit
    // JAMAIS lever, seulement refuser de conclure.
    final value = int.tryParse(segment);
    if (value == null) return null;
    segments.add(value);
  }
  return segments.isEmpty ? null : segments;
}

/// Résultat d'une vérification, prêt pour l'UI et les diagnostics.
class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.status,
    required this.source,
    required this.installedVersion,
    this.availableVersion,
    this.comparisonKey,
    this.storeUri,
    this.releaseNotes,
    this.detail,
  });

  const AppUpdateCheckResult.notSupported({required String installedVersion})
    : this(
        status: AppUpdateCheckStatus.notSupported,
        source: AppUpdateSource.none,
        installedVersion: installedVersion,
      );

  const AppUpdateCheckResult.throttled({required String installedVersion})
    : this(
        status: AppUpdateCheckStatus.throttled,
        source: AppUpdateSource.none,
        installedVersion: installedVersion,
      );

  final AppUpdateCheckStatus status;
  final AppUpdateSource source;

  /// Version installée telle que rapportée par `package_info_plus`.
  final String installedVersion;

  /// Version publiée (App Store) ou code de version Play Core, quand connue.
  final String? availableVersion;

  /// Clé de déduplication du dialogue : « on a déjà proposé CETTE version ».
  /// Volontairement distincte de [availableVersion] (elle porte la source),
  /// pour qu'un changement de source ne re-propose pas une version identique.
  final String? comparisonKey;

  /// Fiche du store à ouvrir (App Store ou Play Store).
  final Uri? storeUri;

  /// Notes de version du store (non traduites : journalisées, pas affichées).
  final String? releaseNotes;

  /// Message technique pour `AppDiagnostics` — jamais affiché à l'utilisateur.
  final String? detail;

  bool get isUpdateAvailable => status == AppUpdateCheckStatus.updateAvailable;
}

/// Politique de relance : au plus une vérification par [kAppUpdateCheckInterval],
/// et au plus un dialogue par version disponible.
///
/// Sans elle : un appel réseau au store à CHAQUE ouverture de l'app (et une
/// requête par `check` en plus des 24 h), et surtout un dialogue qui
/// réapparaîtrait à chaque lancement tant que l'utilisateur n'a pas mis à
/// jour — le comportement le plus sûr pour faire désinstaller une app.
///
/// L'horloge est injectable : la politique reste testable sans `sleep` ni
/// dépendance à l'heure réelle.
class AppUpdateCheckPolicy {
  AppUpdateCheckPolicy({
    this.interval = kAppUpdateCheckInterval,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Intervalle minimal entre deux vérifications automatiques.
  final Duration interval;

  final DateTime Function() _clock;

  /// Vrai si une vérification automatique est due.
  ///
  /// Une horloge qui recule (changement d'heure manuel, restauration de
  /// sauvegarde) ne déclenche pas de vérification : on ne veut pas d'un appel
  /// store surprise parce que l'horloge a sauté en arrière.
  bool isCheckDue({required DateTime? lastCheckAt}) =>
      isCheckDueAt(now: _clock(), lastCheckAt: lastCheckAt);

  /// Variante déterministe (tests, appelants qui ont déjà l'heure).
  bool isCheckDueAt({required DateTime now, required DateTime? lastCheckAt}) {
    if (lastCheckAt == null) return true;
    if (!now.isAfter(lastCheckAt)) return false;
    return now.difference(lastCheckAt) >= interval;
  }

  /// Vrai si le dialogue doit être montré pour [comparisonKey].
  ///
  /// Une clé vide ne peut jamais être proposée : sans identité de version, on
  /// ne saurait pas dédupliquer et on relancerait le dialogue à l'infini.
  bool shouldPrompt({
    required String? comparisonKey,
    required String? lastPromptedKey,
  }) {
    final key = comparisonKey?.trim();
    if (key == null || key.isEmpty) return false;
    return key != lastPromptedKey?.trim();
  }
}
