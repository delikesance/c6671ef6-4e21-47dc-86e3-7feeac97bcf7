// Choix de l'annonce affichée et mémoire « déjà vue » : tout est pur, aucune
// plateforme en jeu.
//
// Ce que ces tests verrouillent : UNE SEULE annonce à la fois, un choix
// déterministe (la plus grave, départagée par identifiant — jamais par l'ordre
// rendu par le serveur), une clé de mémoire par identifiant, et une mémoire
// bornée qui oublie les plus anciennes.
//
// Elle appartient à la suite des décisions pures, découpée par sujet ; la
// fixture commune vit dans `announcement_test_support.dart`.
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';

import 'announcement_test_support.dart';

void main() {
  group('UNE SEULE annonce à la fois, choix déterministe', () {
    test('la plus grave non vue est choisie', () {
      final selection = selectAnnouncementToShow(
        candidates: <Announcement>[
          announcement(id: 'b', severity: AnnouncementSeverity.info),
          announcement(id: 'a', severity: AnnouncementSeverity.critical),
          announcement(id: 'c', severity: AnnouncementSeverity.important),
        ],
        seenIds: const <String>{},
      );

      expect(selection?.id, 'a');
    });

    test('déjà vue → la suivante, du plus grave au moins grave', () {
      final candidates = <Announcement>[
        announcement(id: 'info', severity: AnnouncementSeverity.info),
        announcement(id: 'critique', severity: AnnouncementSeverity.critical),
        announcement(id: 'important', severity: AnnouncementSeverity.important),
      ];

      expect(
        selectAnnouncementToShow(
          candidates: candidates,
          seenIds: const <String>{'critique'},
        )?.id,
        'important',
      );
      expect(
        selectAnnouncementToShow(
          candidates: candidates,
          seenIds: const <String>{'critique', 'important'},
        )?.id,
        'info',
      );
      expect(
        selectAnnouncementToShow(
          candidates: candidates,
          seenIds: const <String>{'critique', 'important', 'info'},
        ),
        isNull,
      );
    });

    test('le choix ne dépend PAS de l\'ordre rendu par le serveur', () {
      final candidates = <Announcement>[
        announcement(id: 'z', severity: AnnouncementSeverity.important),
        announcement(id: 'm', severity: AnnouncementSeverity.critical),
        announcement(id: 'b', severity: AnnouncementSeverity.critical),
        announcement(id: 'a', severity: AnnouncementSeverity.critical),
        announcement(id: 'c', severity: AnnouncementSeverity.info),
      ];

      final expected = selectAnnouncementToShow(
        candidates: candidates,
        seenIds: const <String>{},
      )?.id;

      // Départage stable par identifiant : « a » gagne quelle que soit la
      // position des trois critiques dans la charge utile.
      expect(expected, 'a');
      for (var i = 0; i < 8; i++) {
        final shuffled = List<Announcement>.of(candidates)..shuffle();
        expect(
          selectAnnouncementToShow(
            candidates: shuffled,
            seenIds: const <String>{},
          )?.id,
          expected,
        );
      }
    });

    test('liste vide → rien à afficher', () {
      expect(
        selectAnnouncementToShow(
          candidates: const <Announcement>[],
          seenIds: const <String>{},
        ),
        isNull,
      );
    });
  });

  group('mémoire « déjà vue » : une clé par identifiant', () {
    test('la clé porte l\'identifiant, sous un préfixe dédié', () {
      expect(
        AnnouncementSeenStore.keyFor('ann-42'),
        '${AnnouncementSeenStore.keyPrefix}ann-42',
      );
      expect(
        AnnouncementSeenStore.keyFor('a'),
        isNot(AnnouncementSeenStore.keyFor('b')),
      );
    });

    test('les clés relues rendent les identifiants, et rien de plus', () {
      final ids = AnnouncementSeenStore.idsFromKeys(<String>[
        'announcements.seen.alpha',
        'announcements.seen.beta',
        'app_update.last_prompt_key',
        'main_api_last_synced_hashes',
        AnnouncementSeenStore.keyPrefix,
      ]);

      expect(ids, <String>{'alpha', 'beta'});
    });

    test('deux annonces publiées en parallèle restent indépendantes', () {
      final seen = AnnouncementSeenStore.idsFromKeys(
        <String>[AnnouncementSeenStore.keyFor('alpha')],
      );

      expect(seen.contains('alpha'), isTrue);
      expect(seen.contains('beta'), isFalse);
    });

    test('la mémoire est bornée : les plus anciennes sont oubliées', () {
      final seenAt = <String, int>{
        'announcements.seen.vieille': 1,
        'announcements.seen.moyenne': 2,
        'announcements.seen.recente': 3,
      };

      expect(AnnouncementSeenStore.keysToEvict(seenAt, capacity: 3), isEmpty);
      expect(AnnouncementSeenStore.keysToEvict(seenAt, capacity: 2), <String>[
        'announcements.seen.vieille',
      ]);
      expect(AnnouncementSeenStore.keysToEvict(seenAt, capacity: 1), <String>[
        'announcements.seen.vieille',
        'announcements.seen.moyenne',
      ]);
    });
  });
}
