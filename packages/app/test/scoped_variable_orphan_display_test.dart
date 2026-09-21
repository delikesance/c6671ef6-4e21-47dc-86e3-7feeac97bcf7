// VALEURS ORPHELINES : la preuve que les données du propriétaire redeviennent
// VISIBLES dans l'app.
//
// Défaut confirmé par le propriétaire : la charge utile de son bot contient des
// VALEURS de variables scopées alors que la liste des DÉFINITIONS est vide
// (`"scopedVariableDefinitions": []`). L'écran n'itérait que sur les
// définitions : ses propres données n'apparaissaient donc nulle part dans
// l'app alors qu'elles partaient bien au bot.
//
// Les quatre exigences sont verrouillées ici :
//   1. une valeur sans définition est LISTÉE et marquée « détectée » ;
//   2. une définition déclarée garde son affichage d'origine, sans marque ;
//   3. une portée sans valeur ne produit RIEN (aucune valeur inventée) ;
//   4. une déduction n'écrase jamais une définition déclarée du même nom.
//
// Aucun transport réel : les données sont de simples cartes (ce que la base
// locale rend), et le widget est monté seul, sans page ni réseau.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/scoped_variable_orphans.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scoped_variables_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les données exactes du rapport : une portée `guild` avec 3 clés et une clé
/// `xp` sur deux utilisateurs, sans la moindre définition déclarée.
Map<String, Map<String, Map<String, dynamic>>> _valeursDuRapport() {
  return <String, Map<String, Map<String, dynamic>>>{
    'guild': <String, Map<String, dynamic>>{
      '1453848265786396794': <String, dynamic>{
        'prefix': '!',
        'items_db': '[{"id":1}]',
        'test': ' ',
      },
    },
    'user': <String, Map<String, dynamic>>{
      '1141339907009286186': <String, dynamic>{'xp': '9'},
      '243117191774470146': <String, dynamic>{'xp': '90.5'},
    },
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations tr;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  Widget hostApp(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: child),
    );
  }

  /// Monte la liste exactement comme la page le fait : déclarations puis
  /// déductions, le reste (recherche, portées connues) inchangé.
  Future<void> monterLaListe(
    WidgetTester tester, {
    required List<Map<String, dynamic>> declarations,
    required Map<String, Map<String, Map<String, dynamic>>> valeurs,
  }) async {
    final detectees = detectScopedOrphanDefinitions(
      declaredDefinitions: declarations,
      scopedValues: valeurs,
    );
    await tester.pumpWidget(
      hostApp(
        ScopedVariablesList(
          definitions: mergeScopedDefinitions(
            declaredDefinitions: declarations,
            detectedDefinitions: detectees,
          ),
          knownScopes: const <String>[
            'guild',
            'user',
            'channel',
            'guildMember',
            'message',
          ],
          searchQuery: '',
          onAdd: () {},
          onExplore: (_, _) {},
          onEdit: (_) {},
          onDeclare: (_) {},
          onDelete: (_, _) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Détection : valeurs sans définition', () {
    test('les valeurs orphelines sont visibles et marquées détectées', () {
      final detectees = detectScopedOrphanDefinitions(
        declaredDefinitions: const <Map<String, dynamic>>[],
        scopedValues: _valeursDuRapport(),
      );

      final cles = detectees
          .map((entree) => '${entree['scope']}.${entree['key']}')
          .toList();
      expect(
        cles,
        <String>['guild.items_db', 'guild.prefix', 'guild.test', 'user.xp'],
        reason: 'chaque clé stockée doit apparaitre, triée',
      );

      final affichees = mergeScopedDefinitions(
        declaredDefinitions: const <Map<String, dynamic>>[],
        detectedDefinitions: detectees,
      );
      expect(
        affichees,
        isNotEmpty,
        reason: 'la liste affichée ne doit JAMAIS rester vide face à des données',
      );

      for (final entree in detectees) {
        expect(
          isDetectedScopedDefinition(entree),
          isTrue,
          reason: 'une déduction doit se distinguer d\'une déclaration',
        );
        expect(
          entree.containsKey('defaultValue'),
          isFalse,
          reason: 'aucune valeur par défaut ne peut être inventée',
        );
      }

      final xp = detectees.firstWhere((entree) => entree['key'] == 'xp');
      expect(xp['storedValueCount'], 2, reason: 'deux utilisateurs portent xp');
    });

    test('une définition déclarée reste inchangée et sans marque', () {
      final declarations = <Map<String, dynamic>>[
        <String, dynamic>{'key': 'xp', 'scope': 'user', 'defaultValue': 0},
      ];
      final detectees = detectScopedOrphanDefinitions(
        declaredDefinitions: declarations,
        scopedValues: _valeursDuRapport(),
      );

      expect(
        detectees.any((entree) => entree['key'] == 'xp'),
        isFalse,
        reason: 'xp est déclarée : elle ne doit pas être déduite en plus',
      );

      final affichees = mergeScopedDefinitions(
        declaredDefinitions: declarations,
        detectedDefinitions: detectees,
      );
      final xp = affichees.firstWhere((entree) => entree['key'] == 'xp');
      expect(isDetectedScopedDefinition(xp), isFalse);
      expect(xp['defaultValue'], 0);
    });

    test('une portée sans valeur ne produit rien', () {
      final detectees = detectScopedOrphanDefinitions(
        declaredDefinitions: const <Map<String, dynamic>>[],
        scopedValues: const <String, Map<String, Map<String, dynamic>>>{
          'guild': <String, Map<String, dynamic>>{},
          'channel': <String, Map<String, dynamic>>{
            '123': <String, dynamic>{},
          },
        },
      );

      expect(detectees, isEmpty);
      expect(
        mergeScopedDefinitions(
          declaredDefinitions: const <Map<String, dynamic>>[],
          detectedDefinitions: detectees,
        ),
        isEmpty,
      );
    });

    test('la déduction n\'écrase jamais une déclaration du même nom', () {
      // Définition écrite sous son ancienne forme (`bc_`) : elle doit primer.
      final declarations = <Map<String, dynamic>>[
        <String, dynamic>{
          'key': 'bc_prefix',
          'scope': 'guild',
          'defaultValue': '?',
        },
      ];
      final detectees = detectScopedOrphanDefinitions(
        declaredDefinitions: declarations,
        scopedValues: _valeursDuRapport(),
      );

      expect(
        detectees.any((entree) => entree['key'] == 'prefix'),
        isFalse,
        reason: 'bc_prefix et prefix désignent la même variable',
      );

      final affichees = mergeScopedDefinitions(
        declaredDefinitions: declarations,
        detectedDefinitions: detectees,
      );
      // La déclaration reste, et une SEULE entrée « prefix » est affichée :
      // la déduction n'a pas ajouté de doublon à côté.
      final entreesPrefix = affichees
          .where(
            (entree) =>
                normalizeScopedVariableLookupKey(entree['key'].toString()) ==
                'prefix',
          )
          .toList();
      expect(entreesPrefix, hasLength(1));
      expect(entreesPrefix.single['key'], 'bc_prefix');
      expect(entreesPrefix.single['defaultValue'], '?');
      expect(isDetectedScopedDefinition(entreesPrefix.single), isFalse);
    });
  });

  group('Affichage : la liste montrée à l\'utilisateur', () {
    testWidgets('des valeurs sans définition sont VISIBLES et marquées', (
      tester,
    ) async {
      await monterLaListe(
        tester,
        declarations: const <Map<String, dynamic>>[],
        valeurs: _valeursDuRapport(),
      );

      expect(
        find.text('prefix'),
        findsOneWidget,
        reason: 'la variable du rapport doit apparaitre dans la liste',
      );
      expect(find.text('items_db'), findsOneWidget);
      expect(find.text('xp'), findsOneWidget);
      expect(
        find.text(tr.scoped_detected_badge),
        findsNWidgets(4),
        reason: 'les quatre variables détectées portent le badge',
      );
      expect(
        find.text(tr.scoped_empty),
        findsNothing,
        reason: 'des données existent : l\'état vide serait un mensonge',
      );
      expect(find.text(tr.globals_no_default), findsNothing);
      // Le compte vient des données : aucune valeur n'est affichée à ce niveau.
      expect(find.text(tr.scoped_detected_hint(2)), findsOneWidget);
    });

    testWidgets('définitions déclarées : affichage d\'origine, sans marque', (
      tester,
    ) async {
      await monterLaListe(
        tester,
        declarations: <Map<String, dynamic>>[
          <String, dynamic>{
            'key': 'prefix',
            'scope': 'guild',
            'defaultValue': '!',
          },
        ],
        valeurs: <String, Map<String, Map<String, dynamic>>>{
          'guild': <String, Map<String, dynamic>>{
            '1453848265786396794': <String, dynamic>{'prefix': '!'},
          },
        },
      );

      expect(find.text('prefix'), findsOneWidget);
      expect(find.text('= !'), findsOneWidget);
      expect(
        find.text(tr.scoped_detected_badge),
        findsNothing,
        reason: 'une déclaration ne doit jamais porter la marque « détectée »',
      );
      expect(find.text(tr.scoped_empty), findsNothing);
    });

    testWidgets('aucune donnée : état vide, rien d\'inventé', (tester) async {
      await monterLaListe(
        tester,
        declarations: const <Map<String, dynamic>>[],
        valeurs: const <String, Map<String, Map<String, dynamic>>>{},
      );

      expect(find.text(tr.scoped_empty), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(find.text(tr.scoped_detected_badge), findsNothing);
    });
  });
}
