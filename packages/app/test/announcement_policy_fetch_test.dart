// Budget et garde de RÉCUPÉRATION des annonces : quand une requête a le droit
// de partir, et quand elle doit attendre.
//
// Tout est pur : aucun réseau, aucun `SharedPreferences`. Ce que ces tests
// verrouillent : une requête qui n'arrive jamais plus vite que le budget ne
// l'autorise (rien n'est martelé), l'espacement automatique jusqu'au plafond,
// le retour au nominal dès qu'une annonce nouvelle arrive — et les quatre cas
// où l'on ne parle PAS au serveur (pas de session, session expirée, adresse du
// manager inconnue, appareil hors ligne).
//
// Elle appartient à la suite des décisions pures, découpée par sujet : les
// fixtures partagées vivent dans `announcement_test_support.dart`, dont ce
// fichier n'a besoin d'aucune (tout est calculé ici).
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';

void main() {
  group('budget de récupération', () {
    final t0 = DateTime.utc(2026, 9, 20, 12);

    test('premier appel : dû, puis plus rien avant l\'intervalle courant', () {
      final policy = AnnouncementFetchPolicy(
        nominal: const Duration(minutes: 5),
        ceiling: const Duration(minutes: 30),
      );

      expect(policy.isDue(now: t0, lastAttemptAt: null), isTrue);
      expect(
        policy.isDue(
          now: t0.add(const Duration(minutes: 4, seconds: 59)),
          lastAttemptAt: t0,
        ),
        isFalse,
      );
      expect(
        policy.isDue(
          now: t0.add(const Duration(minutes: 5)),
          lastAttemptAt: t0,
        ),
        isTrue,
      );
    });

    test('contenu inchangé : l\'intervalle s\'espace jusqu\'au plafond', () {
      final policy = AnnouncementFetchPolicy(
        nominal: const Duration(minutes: 5),
        ceiling: const Duration(minutes: 30),
      );

      expect(policy.interval, const Duration(minutes: 5));
      policy.recordSuccess(contentChanged: false); // 1er tick identique
      expect(policy.interval, const Duration(minutes: 5));
      policy.recordSuccess(contentChanged: false);
      expect(policy.interval, const Duration(minutes: 10));
      policy.recordSuccess(contentChanged: false);
      expect(policy.interval, const Duration(minutes: 20));
      policy.recordSuccess(contentChanged: false);
      expect(policy.interval, const Duration(minutes: 30));
      policy.recordSuccess(contentChanged: false);
      expect(policy.interval, const Duration(minutes: 30));
    });

    test('NON-VACUITÉ : hors ligne, l\'app ne martèle pas le serveur', () {
      final policy = AnnouncementFetchPolicy(
        nominal: const Duration(minutes: 5),
        ceiling: const Duration(minutes: 30),
      );
      var lastAttemptAt = t0;

      policy.recordFailure();
      policy.recordFailure();

      // Sans cet espacement, un retour au premier plan relancerait une requête
      // toutes les 5 minutes vers un serveur injoignable.
      expect(policy.interval, const Duration(minutes: 10));
      expect(
        policy.isDue(
          now: t0.add(const Duration(minutes: 6)),
          lastAttemptAt: lastAttemptAt,
        ),
        isFalse,
      );
      expect(
        policy.isDue(
          now: t0.add(const Duration(minutes: 11)),
          lastAttemptAt: lastAttemptAt,
        ),
        isTrue,
      );

      lastAttemptAt = t0.add(const Duration(minutes: 11));
      policy.recordSuccess(contentChanged: true);
      expect(policy.interval, const Duration(minutes: 5));
    });

    test('une annonce nouvelle ramène la cadence au nominal', () {
      final policy = AnnouncementFetchPolicy();
      policy.recordFailure();
      policy.recordFailure();
      expect(policy.interval, greaterThan(const Duration(minutes: 5)));

      policy.recordSuccess(contentChanged: true);
      expect(policy.interval, const Duration(minutes: 5));
    });

    test('reset : retour au nominal (réveil après longue absence)', () {
      final policy = AnnouncementFetchPolicy();
      policy.recordFailure();
      policy.recordFailure();
      policy.reset();

      expect(policy.interval, const Duration(minutes: 5));
    });
  });

  group('garde de récupération (aucune requête dans ces cas)', () {
    final t0 = DateTime.utc(2026, 9, 20, 12);

    AnnouncementFetchBlock? decide({
      bool hasSession = true,
      bool sessionExpired = false,
      String serverBaseUrl = 'https://manager.example.com',
      DateTime? lastAttemptAt,
      DateTime? offlineUntil,
      DateTime? now,
      AnnouncementFetchPolicy? policy,
    }) {
      return blockAnnouncementFetch(
        hasSession: hasSession,
        sessionExpired: sessionExpired,
        serverBaseUrl: serverBaseUrl,
        now: now ?? t0.add(const Duration(minutes: 10)),
        lastAttemptAt: lastAttemptAt ?? t0,
        offlineUntil: offlineUntil,
        policy: policy ?? AnnouncementFetchPolicy(),
      );
    }

    test('pas de session → on ne requête pas', () {
      expect(decide(hasSession: false), AnnouncementFetchBlock.notConnected);
    });

    test('session expirée → on ne requête pas', () {
      expect(
        decide(sessionExpired: true),
        AnnouncementFetchBlock.sessionExpired,
      );
    });

    test('adresse du manager inconnue → on ne requête pas', () {
      expect(decide(serverBaseUrl: '  '), AnnouncementFetchBlock.noServer);
    });

    test('app hors ligne (dernier essai en échec réseau) → on attend', () {
      expect(
        decide(offlineUntil: t0.add(const Duration(minutes: 20))),
        AnnouncementFetchBlock.offlineCooldown,
      );
      expect(
        decide(offlineUntil: t0.add(const Duration(minutes: 1))),
        isNull,
      );
    });

    test('budget épuisé → on ne requête pas', () {
      expect(
        decide(
          lastAttemptAt: t0,
          now: t0.add(const Duration(minutes: 1)),
        ),
        AnnouncementFetchBlock.budget,
      );
    });

    test('tout est réuni → la requête peut partir', () {
      expect(decide(), isNull);
    });
  });
}
