// TRANSPORT des annonces in-app : session persistée, client authentifié, appel
// réseau et lecture de la cadence autorisée.
//
// Extrait de `AnnouncementService` par RESPONSABILITÉ. Ce fichier ne décide
// RIEN de ce qui s'affiche : il rend les candidats à présenter — ou `null`
// quand il n'y a rien à montrer. Le service affiche, le présentateur monte.
// Le budget de cadence et les constantes de durée restent la propriété du
// service : ils lui sont passés, jamais recopiés ici.
//
// Règle non négociable : aucune requête n'est martelée et aucun `Timer` de
// sondage n'est armé — la cadence est CONSULTÉE à chaque déclenchement, pas
// bouclée. Le budget peut refuser la requête et laisser quand même afficher un
// contenu déjà en main : c'est le seul cas où l'on rend sans avoir parlé au
// serveur.
import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';

/// Résout le client authentifié (`null` = pas de client exploitable).
typedef AnnouncementClientResolver = Future<MainApiClient?> Function();

/// Lit la charge utile brute des annonces auprès du manager.
typedef AnnouncementEntriesFetcher =
    Future<List<Map<String, dynamic>>> Function(MainApiClient client);

/// Récupère les annonces et rend celles qui peuvent être présentées.
class AnnouncementFetcher {
  AnnouncementFetcher._();

  static DateTime? _lastAttemptAt;
  static DateTime? _offlineUntil;
  static List<Announcement> _candidates = const <Announcement>[];
  static List<String> _lastIds = const <String>[];

  /// Remet à zéro ce qui a été appris du réseau (entre deux tests).
  static void reset() {
    _lastAttemptAt = null;
    _offlineUntil = null;
    _candidates = const <Announcement>[];
    _lastIds = const <String>[];
  }

  /// Dernière charge utile reçue.
  ///
  /// Le service la relit pour relancer l'affichage quand un emplacement se
  /// libère (bannière fermée, dialogue refermé) : un seul cache, ici.
  static List<Announcement> get candidates => _candidates;

  /// Un cycle complet : garde de session, cadence, requête, décodage.
  ///
  /// Rend les candidats à présenter — la charge fraîche, ou celle déjà en main
  /// si le budget a refusé la requête — ou `null` si rien ne doit s'afficher
  /// (pas de session, hors ligne, serveur qui refuse, charge illisible).
  static Future<List<Announcement>?> run({
    required bool force,
    required AnnouncementFetchPolicy policy,
    required Duration offlineCooldown,
    required AnnouncementClientResolver? clientResolver,
    required AnnouncementEntriesFetcher? entriesFetcher,
  }) async {
    final now = DateTime.now().toUtc();
    final session = await loadMainApiSession();
    final config = await MainApiSettingsStore.loadConfig();

    var block = blockAnnouncementFetch(
      hasSession: session != null,
      sessionExpired: session?.isExpired ?? true,
      serverBaseUrl: config.baseUrl,
      now: now,
      lastAttemptAt: _lastAttemptAt,
      offlineUntil: _offlineUntil,
      policy: policy,
    );
    if (force &&
        (block == AnnouncementFetchBlock.budget ||
            block == AnnouncementFetchBlock.offlineCooldown)) {
      block = null;
    }

    if (block != null) {
      unawaited(
        AppDiagnostics.logInfo(
          'Announcements: fetch skipped',
          data: <String, Object?>{'reason': block.name},
        ),
      );
      // Aucune requête — mais une annonce déjà en main et jamais vue peut
      // encore s'afficher maintenant qu'un emplacement s'est libéré.
      return block == AnnouncementFetchBlock.budget ? _candidates : null;
    }

    final client = await _resolveClient(
      session,
      config.baseUrl,
      clientResolver,
    );
    if (client == null) {
      unawaited(
        AppDiagnostics.logInfo('Announcements: no authenticated client'),
      );
      return null;
    }

    // Horodaté sur la TENTATIVE, pas sur le succès : une app ouverte hors ligne
    // ne relance pas un appel à chaque retour au premier plan.
    _lastAttemptAt = now;

    final List<Map<String, dynamic>> entries;
    try {
      entries = await _fetch(client, entriesFetcher);
      _offlineUntil = null;
    } on MainApiClientException catch (error) {
      // 4xx/5xx : le serveur a répondu, ce n'est pas une panne réseau.
      policy.recordFailure();
      unawaited(
        AppDiagnostics.logInfo(
          'Announcements: server refused the read',
          data: <String, Object?>{'status': error.statusCode ?? 0},
        ),
      );
      return null;
    } catch (error, stack) {
      policy.recordFailure();
      _offlineUntil = now.add(offlineCooldown);
      unawaited(
        AppDiagnostics.logError(
          'Announcements: fetch failed (device offline?)',
          error,
          stack,
          fatal: false,
        ),
      );
      return null;
    }

    final previousIds = _lastIds;
    _candidates = Announcement.parseEntries(entries);
    final ids = _candidates
        .map((announcement) => announcement.id)
        .toList(growable: false);
    _lastIds = ids;
    policy.recordSuccess(contentChanged: !listEquals(previousIds, ids));

    unawaited(
      AppDiagnostics.logInfo(
        'Announcements: fetched',
        data: <String, Object?>{'count': _candidates.length},
      ),
    );

    return _candidates;
  }

  static Future<List<Map<String, dynamic>>> _fetch(
    MainApiClient client,
    AnnouncementEntriesFetcher? override,
  ) {
    if (override != null) return override(client);
    return client.getAnnouncements();
  }

  /// Client authentifié du manager, ou `null` s'il n'y a pas de jeton
  /// exploitable — dans ce cas on ne requête pas du tout.
  static Future<MainApiClient?> _resolveClient(
    MainApiSession? session,
    String baseUrl,
    AnnouncementClientResolver? override,
  ) async {
    if (override != null) return override();
    final token = session?.accessToken.trim() ?? '';
    if (token.isEmpty) return null;
    if (baseUrl.trim().isEmpty) return null;
    return MainApiClient(baseUrl: baseUrl, accessToken: token);
  }
}
