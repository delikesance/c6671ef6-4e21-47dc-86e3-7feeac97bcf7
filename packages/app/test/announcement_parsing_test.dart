// Décodage DÉFENSIF des annonces.
//
// Ce que ces tests protègent : une charge utile mal formée (champ manquant,
// type inattendu, JSON cassé, tableau mixte) ne doit JAMAIS faire tomber le
// décodage, ni produire une demi-annonce à l'écran. Une entrée illisible est
// ignorée en silence ; les autres passent.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/announcements/logic/announcement.dart';

/// Entrée serveur complète, dont chaque test retire ou casse un champ.
Map<String, Object?> entry({
  Object? id = 'a-1',
  Object? title = 'Maintenance planifiée',
  Object? body = 'Le service sera indisponible 10 minutes.',
  Object? severity = 'info',
  Object? linkUrl = 'https://status.example.com/incident',
  Object? dismissible = true,
  bool omitId = false,
  bool omitSeverity = false,
  bool omitBody = false,
}) {
  return <String, Object?>{
    if (!omitId) 'id': id,
    'title': title,
    if (!omitBody) 'body': body,
    if (!omitSeverity) 'severity': severity,
    'link_url': linkUrl,
    'dismissible': dismissible,
  };
}

Set<String> idsOf(List<Announcement> announcements) =>
    announcements.map((announcement) => announcement.id).toSet();

void main() {
  group('lecture d\'une entrée complète', () {
    test('tous les champs sont repris, lien https conservé', () {
      final announcement = Announcement.tryParse(entry())!;

      expect(announcement.id, 'a-1');
      expect(announcement.title, 'Maintenance planifiée');
      expect(announcement.body, 'Le service sera indisponible 10 minutes.');
      expect(announcement.severity, AnnouncementSeverity.info);
      expect(announcement.linkUrl.toString(), 'https://status.example.com/incident');
      expect(announcement.dismissible, isTrue);
      expect(announcement.hasLink, isTrue);
      expect(announcement.isCritical, isFalse);
    });

    test('identifiant numérique accepté (jsonDecode rend un int)', () {
      expect(Announcement.tryParse(entry(id: 42))?.id, '42');
    });

    test('gravité normalisée (casse et espaces)', () {
      expect(
        Announcement.tryParse(entry(severity: '  CRITICAL '))?.severity,
        AnnouncementSeverity.critical,
      );
    });
  });

  group('entrée illisible : IGNORÉE, jamais affichée à moitié', () {
    test('identifiant absent → aucune annonce', () {
      expect(Announcement.tryParse(entry(omitId: true)), isNull);
    });

    test('identifiant vide ou d\'un type inattendu → aucune annonce', () {
      expect(Announcement.tryParse(entry(id: '   ')), isNull);
      expect(Announcement.tryParse(entry(id: null)), isNull);
      expect(Announcement.tryParse(entry(id: <String>['a-1'])), isNull);
      expect(Announcement.tryParse(entry(id: 1.5)), isNull);
      expect(Announcement.tryParse(entry(id: <String, Object?>{'x': 1})), isNull);
    });

    test('titre absent ou vide → aucune annonce', () {
      expect(Announcement.tryParse(entry(title: '')), isNull);
      expect(Announcement.tryParse(entry(title: '   ')), isNull);
      expect(Announcement.tryParse(entry(title: 42)), isNull);
      expect(Announcement.tryParse(entry(title: null)), isNull);
    });

    test('gravité absente ou inconnue → aucune annonce (jamais devinée)', () {
      expect(Announcement.tryParse(entry(omitSeverity: true)), isNull);
      expect(Announcement.tryParse(entry(severity: 'severe')), isNull);
      expect(Announcement.tryParse(entry(severity: 'INFO_URGENT')), isNull);
      expect(Announcement.tryParse(entry(severity: '')), isNull);
    });

    test('gravité d\'un type inattendu → aucune annonce', () {
      expect(Announcement.tryParse(entry(severity: 2)), isNull);
      expect(Announcement.tryParse(entry(severity: true)), isNull);
      expect(Announcement.tryParse(entry(severity: null)), isNull);
      expect(
        Announcement.tryParse(entry(severity: <String>['critical'])),
        isNull,
      );
    });

    test('entrée qui n\'est pas un objet → aucune annonce', () {
      expect(Announcement.tryParse('je ne suis pas une annonce'), isNull);
      expect(Announcement.tryParse(null), isNull);
      expect(Announcement.tryParse(7), isNull);
      expect(Announcement.tryParse(<Object?>[]), isNull);
    });
  });

  group('champ optionnel mal formé : l\'annonce survit, le champ est écarté', () {
    test('corps d\'un type inattendu → corps vide, titre conservé', () {
      final announcement = Announcement.tryParse(entry(body: 12))!;

      expect(announcement.title, 'Maintenance planifiée');
      expect(announcement.body, isEmpty);
    });

    test('dismissible d\'un type inattendu → reste refermable', () {
      for (final broken in <Object?>['false', 0, null, <Object?>[]]) {
        final announcement = Announcement.tryParse(entry(dismissible: broken))!;
        expect(
          announcement.dismissible,
          isTrue,
          reason: 'Un champ illisible ne doit jamais transformer une annonce '
              'refermable en dialogue dont on ne sort pas.',
        );
      }
    });

    test('lien non https, relatif ou d\'un autre type → écarté, annonce gardée',
        () {
      for (final unsafe in <Object?>[
        'http://example.com/x',
        'file:///etc/passwd',
        'javascript:alert(1)',
        'example.com/x',
        '',
        42,
        null,
      ]) {
        final announcement = Announcement.tryParse(entry(linkUrl: unsafe))!;
        expect(announcement.hasLink, isFalse, reason: 'lien refusé : $unsafe');
        expect(announcement.title, 'Maintenance planifiée');
      }
    });
  });

  group('décodage d\'un lot', () {
    test('tableau mixte : les entrées illisibles n\'entrent pas dans la liste',
        () {
      final decoded = <Object?>[
        'texte au milieu',
        null,
        42,
        <String, Object?>{'title': 'sans identifiant'},
        entry(id: 'ok', severity: 'info'),
        <String, Object?>{'id': 'sans-gravite', 'title': 'X'},
      ];

      final announcements = Announcement.parseEntries(decoded);

      expect(idsOf(announcements), <String>{'ok'});
      expect(announcements.single.title, 'Maintenance planifiée');
    });

    test('les deux formes d\'enveloppe du client sont acceptées', () {
      final entries = <Object?>[entry(id: 'a'), entry(id: 'b')];

      expect(
        idsOf(Announcement.parseEntries(<String, Object?>{'data': entries})),
        <String>{'a', 'b'},
      );
      expect(
        idsOf(
          Announcement.parseEntries(<String, Object?>{
            'announcements': entries,
          }),
        ),
        <String>{'a', 'b'},
      );
    });

    test('tableau vide ou forme inattendue → liste vide, sans exception', () {
      expect(Announcement.parseEntries(<Object?>[]), isEmpty);
      expect(Announcement.parseEntries(<String, Object?>{}), isEmpty);
      expect(Announcement.parseEntries('texte'), isEmpty);
      expect(Announcement.parseEntries(null), isEmpty);
    });

    test('JSON illisible → liste vide, aucune exception', () {
      expect(Announcement.parseList('{ceci nest pas du json'), isEmpty);
      expect(Announcement.parseList(''), isEmpty);
      expect(Announcement.parseList('"[1,2,3]"'), isEmpty);
    });

    test('JSON valide décodé par le vrai chemin', () {
      final body = jsonEncode(<Object?>[
        entry(id: 'a', severity: 'critical'),
        'bruit',
        entry(id: 'b', severity: 'info'),
      ]);

      expect(idsOf(Announcement.parseList(body)), <String>{'a', 'b'});
    });

    test('doublon d\'identifiant : la PLUS GRAVE est conservée', () {
      final announcements = Announcement.parseEntries(<Object?>[
        entry(id: 'a', severity: 'info'),
        entry(id: 'a', severity: 'critical'),
      ]);

      expect(announcements, hasLength(1));
      expect(announcements.single.severity, AnnouncementSeverity.critical);
    });

    test('tri du plus grave au moins grave, puis par identifiant', () {
      final announcements = Announcement.parseEntries(<Object?>[
        entry(id: 'z-info', severity: 'info'),
        entry(id: 'a-important', severity: 'important'),
        entry(id: 'b-critical', severity: 'critical'),
        entry(id: 'a-critical', severity: 'critical'),
      ]);

      expect(
        announcements.map((announcement) => announcement.id).toList(),
        <String>['a-critical', 'b-critical', 'a-important', 'z-info'],
      );
    });
  });

  group('NON-VACUITÉ du décodage défensif', () {
    test('une charge utile dont UNE SEULE entrée est lisible ne rend que celle-là',
        () {
      final decoded = <Object?>[
        <String, Object?>{'id': 'casse', 'severity': 'critical'}, // pas de titre
        <String, Object?>{'id': 'casse', 'title': 'T', 'severity': 'alerte'},
        'bruit',
        entry(id: 'lisible', severity: 'important'),
      ];

      final announcements = Announcement.parseEntries(decoded);

      // Si une entrée illisible était affichée au lieu d'être ignorée, cette
      // liste contiendrait 3 ou 4 éléments (et deux fois l'id « casse »).
      expect(announcements, hasLength(1));
      expect(announcements.single.id, 'lisible');
      expect(
        announcements.any((announcement) => announcement.id == 'casse'),
        isFalse,
      );
    });
  });
}
