// Service de détection de mise à jour : c'est ici (et seulement ici) qu'on
// touche aux entrées/sorties — plugin Play Core, lookup App Store, ouverture
// de la fiche du store, persistance de la politique de relance.
//
// Les décisions (« existe-t-il une version plus récente ? », « faut-il
// reproposer le dialogue ? ») vivent dans `app_update_models.dart`, testable
// sans plateforme. Ce fichier ne fait que brancher les vraies sources dessus.
//
// Deux plateformes, deux voies officielles :
//   - Android : Play Core (`in_app_update`), flux FLEXIBLE — l'utilisateur
//     continue d'utiliser l'app pendant le téléchargement, puis
//     `completeFlexibleUpdate()` installe. Jamais le flux immédiat (bloquant),
//     même quand Play l'autorise : c'est le flux le moins agressif.
//   - iOS : aucune API d'update in-app. On compare la version installée à
//     celle publiée via le lookup iTunes officiel, puis on ouvre la fiche.
//
// Règle de robustesse : aucune erreur ne remonte à l'utilisateur sous forme de
// crash. Réseau absent, Play absent, APK sideloadé → « vérification
// impossible », journalisé par AppDiagnostics, avec la fiche du store en
// repli quand on la connaît.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/app_update/logic/app_update_models.dart';
import 'package:bot_creator/features/app_update/presentation/app_update_dialog.dart';

/// Ce qui est arrivé quand l'utilisateur a accepté la mise à jour.
enum AppUpdateLaunchOutcome {
  /// Flux flexible Play Core démarré (téléchargement en arrière-plan).
  flexibleStarted,

  /// Mise à jour déjà téléchargée : `completeFlexibleUpdate()` a été demandé.
  flexibleCompleted,

  /// Le flux in-app a échoué : on a ouvert la fiche du store à la place.
  storeOpened,

  /// Utilisateur a refusé la proposition Play (« Annuler »).
  declined,

  /// Rien à ouvrir / ouverture refusée par la plateforme.
  failed,
}

class AppUpdateService {
  AppUpdateService._();

  // ── Clés de persistance ──────────────────────────────────────────────────
  static const String _lastCheckPrefKey = 'app_update.last_check_ms';
  static const String _lastPromptPrefKey = 'app_update.last_prompt_key';

  /// Délai du lookup App Store : au-delà, on répond « vérification
  /// impossible » plutôt que de laisser une tâche ouverte au démarrage.
  static const Duration lookupTimeout = Duration(seconds: 8);

  /// Politique de relance : au plus une vérification / 24 h, au plus un
  /// dialogue par version disponible.
  static final AppUpdateCheckPolicy policy = AppUpdateCheckPolicy();

  /// Racine de navigation, injectée par `main.dart`
  /// (`MyApp.navigatorKey`) : le service ne dépend pas de la racine de l'app.
  static GlobalKey<NavigatorState>? navigatorKey;

  // ── Points d'injection pour les tests (jamais utilisés en production) ────
  @visibleForTesting
  static Future<AppStoreRelease?> Function(String country)?
  debugAppStoreLookupOverride;

  @visibleForTesting
  static Future<http.Response> Function(Uri uri)? debugHttpGetOverride;

  @visibleForTesting
  static Future<AppUpdateCheckResult?> Function(String installed)?
  debugAndroidCheckOverride;

  @visibleForTesting
  static Future<AppUpdateResult> Function()? debugFlexibleStartOverride;

  @visibleForTesting
  static Future<void> Function()? debugFlexibleCompleteOverride;

  @visibleForTesting
  static Future<bool> Function(Uri uri)? debugOpenStoreOverride;

  @visibleForTesting
  static String? debugCountryOverride;

  @visibleForTesting
  static String? debugInstalledVersionOverride;

  /// Remet les points d'injection à zéro (entre deux tests).
  @visibleForTesting
  static void debugResetForTests() {
    debugAppStoreLookupOverride = null;
    debugHttpGetOverride = null;
    debugAndroidCheckOverride = null;
    debugFlexibleStartOverride = null;
    debugFlexibleCompleteOverride = null;
    debugOpenStoreOverride = null;
    debugCountryOverride = null;
    debugInstalledVersionOverride = null;
  }

  // ── Plateformes ──────────────────────────────────────────────────────────

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isSupported => isAndroid || isIos;

  /// Fiche Play Store (repli universel Android).
  static Uri get playStoreUri => playStoreListingUri();

  // ── Version installée ────────────────────────────────────────────────────

  /// Version installée, `null` si elle est illisible (info absente, plugin
  /// indisponible) — l'appelant doit alors refuser de conclure.
  static Future<String?> installedVersion() async {
    final override = debugInstalledVersionOverride;
    if (override != null) return override;
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      final build = info.buildNumber.trim();
      if (version.isEmpty) return null;
      return build.isEmpty ? version : '$version+$build';
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'App update: installed version unavailable',
          error,
          stack,
          fatal: false,
        ),
      );
      return null;
    }
  }

  /// Pays à interroger sur l'App Store, dérivé de la locale de l'appareil
  /// (repli `fr`).
  static String lookupCountry() {
    final override = debugCountryOverride;
    if (override != null) return resolveLookupCountry(override);
    try {
      return resolveLookupCountry(
        PlatformDispatcher.instance.locale.countryCode,
      );
    } catch (_) {
      return kAppStoreFallbackCountry;
    }
  }

  // ── Vérification ─────────────────────────────────────────────────────────

  /// Vérifie l'existence d'une mise à jour.
  ///
  /// [force] court-circuite la politique de relance (bouton « Vérifier les
  /// mises à jour » de Settings). L'appel automatique du démarrage utilise
  /// `force: false` : la politique répond alors [AppUpdateCheckStatus.throttled]
  /// sans aucun appel réseau.
  static Future<AppUpdateCheckResult> check({bool force = false}) async {
    final installed = await installedVersion() ?? '';
    final source = isAndroid
        ? AppUpdateSource.playCore
        : (isIos ? AppUpdateSource.appStore : AppUpdateSource.none);

    if (source == AppUpdateSource.none) {
      return AppUpdateCheckResult.notSupported(installedVersion: installed);
    }

    final prefs = await _preferences();
    if (!force && !policy.isCheckDue(lastCheckAt: _lastCheckAt(prefs))) {
      return AppUpdateCheckResult.throttled(installedVersion: installed);
    }

    AppUpdateCheckResult result;
    if (source == AppUpdateSource.playCore) {
      result = await _checkPlayCore(installed);
    } else {
      result = await _checkAppStore(installed);
    }

    // L'horodatage est posé sur la TENTATIVE, pas sur le succès : une app
    // ouverte hors ligne ne relance pas un appel store à chaque lancement.
    if (prefs != null && !force) {
      unawaited(
        prefs
            .setInt(_lastCheckPrefKey, DateTime.now().millisecondsSinceEpoch)
            .catchError((Object _) => false),
      );
    }

    unawaited(
      AppDiagnostics.logInfo(
        'App update check finished',
        data: <String, Object?>{
          'status': result.status.name,
          'source': result.source.name,
          'installed': result.installedVersion,
          'available': result.availableVersion,
          if (result.detail != null) 'detail': result.detail,
        },
      ),
    );
    return result;
  }

  /// Android : Play Core, la source officielle.
  static Future<AppUpdateCheckResult> _checkPlayCore(String installed) async {
    final fallback = playStoreUri;
    final override = debugAndroidCheckOverride;
    if (override != null) {
      final result = await override(installed);
      if (result != null) return result;
    }
    try {
      final info = await InAppUpdate.checkForUpdate();
      switch (info.updateAvailability) {
        case UpdateAvailability.updateAvailable:
          final versionCode = info.availableVersionCode?.toString();
          return AppUpdateCheckResult(
            status: AppUpdateCheckStatus.updateAvailable,
            source: AppUpdateSource.playCore,
            installedVersion: installed,
            availableVersion: versionCode,
            // Clé de déduplication : le code de version Play, jamais le nom de
            // version (Play ne le sert pas via Play Core).
            comparisonKey: versionCode == null
                ? 'play:unknown'
                : 'play:$versionCode',
            storeUri: fallback,
            detail: info.installStatus == InstallStatus.downloaded
                ? 'flexible-update-downloaded'
                : 'flexible-allowed=${info.flexibleUpdateAllowed}',
          );
        case UpdateAvailability.updateNotAvailable:
          return AppUpdateCheckResult(
            status: AppUpdateCheckStatus.upToDate,
            source: AppUpdateSource.playCore,
            installedVersion: installed,
            storeUri: fallback,
          );
        case UpdateAvailability.developerTriggeredUpdateInProgress:
        case UpdateAvailability.unknown:
          return AppUpdateCheckResult(
            status: AppUpdateCheckStatus.unavailable,
            source: AppUpdateSource.playCore,
            installedVersion: installed,
            storeUri: fallback,
            detail: 'availability=${info.updateAvailability.name}',
          );
      }
    } catch (error, stack) {
      // APK sideloadé, Play Store absent/désactivé, service Play indisponible :
      // cas NORMAL hors distribution Play. Aucune erreur visible ; on rend
      // simplement la fiche Play Store en repli pour que l'utilisateur puisse
      // se mettre à jour à la main.
      unawaited(
        AppDiagnostics.logError(
          'App update: Play Core check failed',
          error,
          stack,
          fatal: false,
        ),
      );
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.unavailable,
        source: AppUpdateSource.playCore,
        installedVersion: installed,
        storeUri: fallback,
        detail: 'play-core-unavailable',
      );
    }
  }

  /// iOS : lookup App Store officiel, puis décision par le comparateur PUR.
  static Future<AppUpdateCheckResult> _checkAppStore(String installed) async {
    final country = lookupCountry();
    final release = await lookupAppStore(country);
    if (release == null) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.unavailable,
        source: AppUpdateSource.appStore,
        installedVersion: installed,
        detail: 'app-store-lookup-empty',
      );
    }

    if (!isNewerVersion(release.version, installed)) {
      return AppUpdateCheckResult(
        status: AppUpdateCheckStatus.upToDate,
        source: AppUpdateSource.appStore,
        installedVersion: installed,
        availableVersion: release.version,
        storeUri: release.storeUri,
      );
    }

    return AppUpdateCheckResult(
      status: AppUpdateCheckStatus.updateAvailable,
      source: AppUpdateSource.appStore,
      installedVersion: installed,
      availableVersion: release.version,
      comparisonKey: 'ios:${release.version}',
      storeUri: release.storeUri,
      releaseNotes: release.releaseNotes,
      detail: release.releaseDate,
    );
  }

  /// Interroge le lookup iTunes officiel (sans clé d'API) et rend `null` sur
  /// toute anomalie — jamais d'exception.
  static Future<AppStoreRelease?> lookupAppStore(String country) async {
    final override = debugAppStoreLookupOverride;

    final uri = Uri.parse(kAppStoreLookupEndpoint).replace(
      queryParameters: <String, String>{
        'bundleId': kStoreApplicationId,
        'country': country,
      },
    );
    try {
      // L'injection de test passe aussi par le garde-fou : elle sert justement a
      // simuler « l'appareil est hors ligne », et une exception qui s'echapperait
      // ici remonterait jusqu'a l'ecran au lieu d'etre rendue « verification
      // impossible ». `await` est OBLIGATOIRE : dans une fonction async,
      // `return future` rend la main sans passer par le catch local, alors que
      // `return await future` y fait remonter l'erreur.
      if (override != null) return await override(country);
      final http.Response response;
      final httpOverride = debugHttpGetOverride;
      if (httpOverride != null) {
        response = await httpOverride(uri);
      } else {
        final client = http.Client();
        try {
          response = await client.get(uri).timeout(lookupTimeout);
        } finally {
          client.close();
        }
      }
      if (response.statusCode != 200) {
        unawaited(
          AppDiagnostics.logInfo(
            'App update: App Store lookup non-200',
            data: <String, Object?>{'status': response.statusCode},
          ),
        );
        return null;
      }
      return parseAppStoreLookup(response.body, fallbackCountry: country);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'App update: App Store lookup failed',
          error,
          stack,
          fatal: false,
        ),
      );
      return null;
    }
  }

  // ── Relance automatique + dialogue ───────────────────────────────────────

  /// Appelé au démarrage, APRÈS la première peinture (`unawaited`, jamais
  /// `await` dans la chaîne d'init critique).
  ///
  /// Ne fait rien si la politique dit « pas maintenant », ou si cette version
  /// a déjà été proposée. Ne bloque jamais : en cas d'échec, rien n'est montré.
  static Future<void> checkAndPromptIfNeeded() async {
    try {
      final result = await check(force: false);
      if (!result.isUpdateAvailable) return;

      final prefs = await _preferences();
      final lastPrompted = prefs?.getString(_lastPromptPrefKey);
      if (!policy.shouldPrompt(
        comparisonKey: result.comparisonKey,
        lastPromptedKey: lastPrompted,
      )) {
        return;
      }

      final context = navigatorKey?.currentContext;
      if (context == null || !context.mounted) return;

      // Marquée AVANT l'affichage : une app tuée pendant que le dialogue est
      // ouvert ne doit pas le reproposer au lancement suivant.
      unawaited(
        prefs
            ?.setString(_lastPromptPrefKey, result.comparisonKey ?? '')
            .catchError((Object _) => false),
      );

      final accepted = await showAppUpdateDialog(
        context,
        availableVersion: result.availableVersion ?? '',
        installedVersion: result.installedVersion,
      );
      if (accepted) await launchUpdate(result);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'App update: startup prompt failed',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  /// Oublie la dernière version proposée (utile au bouton Settings après une
  /// mise à jour réussie, et aux tests).
  @visibleForTesting
  static Future<void> clearPromptState() async {
    final prefs = await _preferences();
    await prefs?.remove(_lastPromptPrefKey);
  }

  // ── Mise à jour ──────────────────────────────────────────────────────────

  /// Exécute la mise à jour demandée par l'utilisateur.
  static Future<AppUpdateLaunchOutcome> launchUpdate(
    AppUpdateCheckResult result,
  ) async {
    if (result.source == AppUpdateSource.playCore) {
      final outcome = await _startPlayCoreUpdate(result);
      if (outcome != null) return outcome;
    }
    final uri = result.storeUri;
    if (uri == null) return AppUpdateLaunchOutcome.failed;
    return await openStore(uri)
        ? AppUpdateLaunchOutcome.storeOpened
        : AppUpdateLaunchOutcome.failed;
  }

  /// `null` = le flux in-app n'était pas possible, l'appelant doit ouvrir la
  /// fiche du store à la place.
  static Future<AppUpdateLaunchOutcome?> _startPlayCoreUpdate(
    AppUpdateCheckResult result,
  ) async {
    try {
      if (result.detail == 'flexible-update-downloaded') {
        await (debugFlexibleCompleteOverride?.call() ??
            InAppUpdate.completeFlexibleUpdate());
        return AppUpdateLaunchOutcome.flexibleCompleted;
      }

      final update =
          await (debugFlexibleStartOverride?.call() ??
              InAppUpdate.startFlexibleUpdate());
      switch (update) {
        case AppUpdateResult.success:
          return AppUpdateLaunchOutcome.flexibleStarted;
        case AppUpdateResult.userDeniedUpdate:
          // Refus explicite de l'utilisateur : ne PAS ouvrir le store par
          // dessus, ce serait ignorer sa décision.
          return AppUpdateLaunchOutcome.declined;
        case AppUpdateResult.inAppUpdateFailed:
          return null;
      }
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'App update: flexible flow failed, falling back to store listing',
          error,
          stack,
          fatal: false,
        ),
      );
      return null;
    }
  }

  /// Ouvre la fiche du store (App Store ou Play Store).
  static Future<bool> openStore(Uri uri) async {
    final override = debugOpenStoreOverride;
    if (override != null) return override(uri);
    try {
      return await openExternalUrl(uri);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'App update: opening store listing failed',
          error,
          stack,
          fatal: false,
        ),
      );
      return false;
    }
  }

  // ── Persistance ──────────────────────────────────────────────────────────

  static Future<SharedPreferences?> _preferences() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'App update: preferences unavailable',
          error,
          stack,
          fatal: false,
        ),
      );
      return null;
    }
  }

  static DateTime? _lastCheckAt(SharedPreferences? prefs) {
    final millis = prefs?.getInt(_lastCheckPrefKey);
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }
}
