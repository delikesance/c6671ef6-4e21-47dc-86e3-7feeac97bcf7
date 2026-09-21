// Règles d'affichage des annonces : quelle FORME pour quelle gravité, et un
// dialogue jamais piégé.
//
// Tout est pur : aucune plateforme, aucun réseau, aucun `SharedPreferences`.
// Ce que ces tests verrouillent : la bannière pour `info`/`important`, le
// dialogue modal réservé au critique, et — quelle que soit la publication —
// TOUJOURS un bouton qui ferme.
//
// Découpée par sujet, chaque morceau portant les mêmes noms de tests :
//   * ce fichier — la forme d'affichage et les voies de fermeture ;
//   * `announcement_policy_selection_test.dart` — UNE SEULE annonce à la fois
//     et la mémoire « déjà vue » ;
//   * `announcement_policy_fetch_test.dart` — budget et garde de récupération.
//
// La fixture commune vit dans `announcement_test_support.dart`, et nulle part
// ailleurs.
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/announcements/logic/announcement.dart';
import 'package:bot_creator/features/announcements/logic/announcement_policy.dart';

import 'announcement_test_support.dart';

void main() {
  group('bannière ou dialogue', () {
    test('info et important → bannière', () {
      expect(
        presentationFor(AnnouncementSeverity.info),
        AnnouncementPresentation.banner,
      );
      expect(
        presentationFor(AnnouncementSeverity.important),
        AnnouncementPresentation.banner,
      );
    });

    test('critical → dialogue modal', () {
      expect(
        presentationFor(AnnouncementSeverity.critical),
        AnnouncementPresentation.modal,
      );
    });

    test('seul le critique est modal', () {
      final modalSeverities = AnnouncementSeverity.values
          .where(
            (severity) =>
                presentationFor(severity) == AnnouncementPresentation.modal,
          )
          .toSet();
      expect(modalSeverities, <AnnouncementSeverity>{
        AnnouncementSeverity.critical,
      });
    });
  });

  group('dialogue : refermable, jamais piégé', () {
    test('annonce refermable : acquittement + report, tap extérieur actif', () {
      final refermable = announcement(
        id: 'a',
        severity: AnnouncementSeverity.critical,
      );

      expect(modalCloseRoutes(refermable), <AnnouncementCloseRoute>[
        AnnouncementCloseRoute.acknowledge,
        AnnouncementCloseRoute.defer,
      ]);
      expect(modalBarrierDismissible(refermable), isTrue);
    });

    test('annonce non refermable : report supprimé, bouton de fermeture gardé',
        () {
      final contrainte = announcement(
        id: 'a',
        severity: AnnouncementSeverity.critical,
        dismissible: false,
      );

      expect(modalCloseRoutes(contrainte), <AnnouncementCloseRoute>[
        AnnouncementCloseRoute.acknowledge,
      ]);
      expect(modalBarrierDismissible(contrainte), isFalse);
    });

    test('NON-VACUITÉ : aucun cas de figure ne laisse un dialogue sans issue',
        () {
      for (final severity in AnnouncementSeverity.values) {
        for (final dismissible in <bool>[true, false]) {
          final routes = modalCloseRoutes(
            announcement(id: 'a', severity: severity, dismissible: dismissible),
          );

          // Si le bouton d'acquittement devenait conditionnel, cette liste
          // serait vide pour `dismissible: false` — un dialogue piégé.
          expect(
            routes,
            isNotEmpty,
            reason: 'severity=$severity dismissible=$dismissible',
          );
          expect(routes, contains(AnnouncementCloseRoute.acknowledge));
        }
      }
    });

    test('la bannière n\'a de croix que si l\'annonce est refermable', () {
      expect(bannerShowsCloseButton(announcement(id: 'a')), isTrue);
      expect(
        bannerShowsCloseButton(announcement(id: 'a', dismissible: false)),
        isFalse,
      );
    });
  });
}
