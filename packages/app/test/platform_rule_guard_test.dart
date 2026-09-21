// Garde de SOURCE : « le serveur peut-il piloter un bot depuis cette plateforme ? »
//
// Cette règle a existé en SEPT copies dans l'application. Six répondaient « non » sur un
// poste de travail (elles testaient `TargetPlatform`/`Platform`), si bien qu'un bot
// hébergé restait invisible depuis un poste : la page de logs ne pouvait afficher que
// « Local sur cet appareil », les statistiques et les variables globales ignoraient le
// serveur. Corriger une copie à la fois laissait les autres en place.
//
// La règle vit maintenant dans `core/platform/run_platform.dart` (`supportsManagerRuntime`).
// Ce test échoue si une page la recalcule au lieu de l'importer.

import 'dart:io';

import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('aucune page ne recalcule la règle de plateforme du serveur', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!lines[i].contains('bool get _supportsManagerRuntime')) continue;
        // Une définition correcte délègue au seam en une ligne. Toute autre forme
        // signifie que la règle a été recalculée ici.
        final body = lines.skip(i).take(4).join(' ');
        if (!body.contains('supportsManagerRuntime;')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'la règle doit venir de core/platform/run_platform.dart '
          '(sept copies divergentes ont déjà coûté une page de logs muette)',
    );
  });

  test('le seam partagé dit bien que le serveur pilote depuis un poste', () {
    // Le pendant positif de la garde : si cette valeur redevenait fausse sur un poste,
    // tout ce qui est prouvé au-dessus ne servirait plus à rien.
    expect(
      supportsManagerRuntime,
      isTrue,
      reason: 'en test, la plateforme n’est ni le web ni bloquée : le serveur est joignable',
    );
  });
}
