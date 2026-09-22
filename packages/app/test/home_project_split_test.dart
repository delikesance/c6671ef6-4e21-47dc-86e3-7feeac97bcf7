// Séparation de l'accueil : ce que je POSSÈDE et ce qu'on m'a PARTAGÉ.
//
// Le partage d'un bot est décidé par le SERVEUR (`is_collaborative` sur
// `GET /gateway/bots`). Aucune heuristique locale n'est acceptée ici : un bot
// qui apparaîtrait à la fois dans « My bots » et dans « Shared with me » serait
// un doublon visible par l'utilisateur, donc un bug.
import 'package:bot_creator/features/home/logic/home_project_split.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _bot(String id, {String? name}) => <String, dynamic>{
  'id': id,
  'name': name ?? 'Bot $id',
};

List<String> _ids(List<Map<String, dynamic>> bots) => bots
    .map((bot) => (bot['id'] ?? '<sans id>').toString())
    .toList(growable: false);

void main() {
  test('ensemble vide : rien à moi, rien de partagé', () {
    final split = splitHomeProjects(
      const <Map<String, dynamic>>[],
      const <String>{},
    );

    expect(split.owned, isEmpty);
    expect(split.shared, isEmpty);
  });

  test('aucun id collaboratif : tout reste dans « My bots »', () {
    final apps = <Map<String, dynamic>>[_bot('1'), _bot('2'), _bot('3')];

    final split = splitHomeProjects(apps, const <String>{});

    expect(_ids(split.owned), <String>['1', '2', '3']);
    expect(split.shared, isEmpty);
  });

  test('mélange : l\'ordre d\'entrée est préservé dans chaque section', () {
    final apps = <Map<String, dynamic>>[
      _bot('1'),
      _bot('2'),
      _bot('3'),
      _bot('4'),
      _bot('5'),
    ];

    final split = splitHomeProjects(apps, <String>{'2', '4'});

    expect(_ids(split.owned), <String>['1', '3', '5']);
    expect(_ids(split.shared), <String>['2', '4']);
  });

  test('un id collaboratif absent des apps est ignoré, sans jeter', () {
    final apps = <Map<String, dynamic>>[_bot('1')];

    final split = splitHomeProjects(apps, <String>{'1', 'absent'});

    expect(_ids(split.shared), <String>['1']);
    expect(split.owned, isEmpty);
  });

  test('un app sans clé id ne jette pas et reste dans « My bots »', () {
    final apps = <Map<String, dynamic>>[
      <String, dynamic>{'name': 'Sans identifiant'},
      _bot('7'),
    ];

    final split = splitHomeProjects(apps, <String>{'7'});

    expect(split.owned.length, 1);
    expect(split.owned.single['name'], 'Sans identifiant');
    expect(_ids(split.shared), <String>['7']);
  });

  test('un bot collaboratif n\'apparaît JAMAIS dans les deux sections', () {
    final apps = <Map<String, dynamic>>[_bot('1'), _bot('2'), _bot('3')];

    final split = splitHomeProjects(apps, <String>{'2'});

    final ownedIds = _ids(split.owned);
    final sharedIds = _ids(split.shared);
    expect(ownedIds.toSet().intersection(sharedIds.toSet()), isEmpty);
    expect(ownedIds, <String>['1', '3']);
    expect(sharedIds, <String>['2']);
  });

  test('les maps d\'origine sont rendues telles quelles (aucune copie)', () {
    final original = _bot('1');
    final apps = <Map<String, dynamic>>[original];

    final split = splitHomeProjects(apps, const <String>{});

    expect(identical(split.owned.single, original), isTrue);
  });
}
