import 'dart:convert';

import 'package:bot_creator/features/bot_editor/logic/command_editor_notifier.dart';
import 'package:bot_creator/features/bot_editor/logic/command_editor_state.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Simule un enregistrement puis un rechargement en passant par JSON.
Map<String, dynamic> roundTrip(Map<String, dynamic> input) {
  final normalized = normalizeCommandData(input);
  return Map<String, dynamic>.from(
    (jsonDecode(jsonEncode(normalized)) as Map).cast<String, dynamic>(),
  );
}

Map<String, dynamic> _legacyCommand({Object? aliases, String name = 'ping'}) {
  return <String, dynamic>{
    'name': name,
    'type': 'chatInput',
    'data': <String, dynamic>{
      'legacyModeEnabled': true,
      'legacyPrefixOverride': '',
      'legacyResponseTarget': 'reply',
      'legacyAliases': ?aliases,
    },
  };
}

void main() {
  group('normalizeCommandData – alias de commande Message Texte', () {
    test('conserve les alias valides', () {
      final result = normalizeCommandData(
        _legacyCommand(aliases: ['p', 'ping2']),
      );
      final data = Map<String, dynamic>.from(result['data'] as Map);

      expect(data['legacyAliases'], <String>['p', 'ping2']);
    });

    test('nettoie les alias sales (casse, préfixe !, doublons, vides)', () {
      final result = normalizeCommandData(
        _legacyCommand(aliases: [' P ', '!P', '!', '', '   ', 'x y', 'Ok']),
      );
      final data = Map<String, dynamic>.from(result['data'] as Map);

      expect(data['legacyAliases'], <String>['p', 'ok']);
    });

    test('ignore les entrées non textuelles et les valeurs non-liste', () {
      final withDirtyEntries = normalizeCommandData(
        _legacyCommand(aliases: <dynamic>[1, null, true, 'p']),
      );
      expect((withDirtyEntries['data'] as Map)['legacyAliases'], <String>['p']);

      final withBadType = normalizeCommandData(_legacyCommand(aliases: 'p'));
      expect((withBadType['data'] as Map)['legacyAliases'], isEmpty);
    });

    test('retombe sur une liste vide quand legacyAliases est absent', () {
      final result = normalizeCommandData(_legacyCommand());
      final data = Map<String, dynamic>.from(result['data'] as Map);

      expect(data.containsKey('legacyAliases'), isTrue);
      expect(data['legacyAliases'], isEmpty);
    });

    test('tronque les alias de plus de 32 caractères', () {
      final long = 'x' * 40;
      final result = normalizeCommandData(_legacyCommand(aliases: [long]));
      final aliases = (result['data'] as Map)['legacyAliases'] as List;

      expect(aliases, hasLength(1));
      expect(aliases.single, 'x' * 32);
    });

    test('survit à un aller-retour sauvegarde/rechargement', () {
      final stored = roundTrip(
        _legacyCommand(aliases: ['p', ' PING ', r'c{$t:5s}']),
      );
      final data = Map<String, dynamic>.from(stored['data'] as Map);

      expect(data['legacyAliases'], <String>['p', 'ping', r'c{$t:5s}']);

      // Une réécriture ne doit rien perdre ni re-tronquer.
      final rewritten = roundTrip(stored);
      expect((rewritten['data'] as Map)['legacyAliases'], <String>[
        'p',
        'ping',
        r'c{$t:5s}',
      ]);
    });

    test('soigne un fichier corrompu avec legacyAliases à la racine', () {
      final healed = normalizeCommandData(<String, dynamic>{
        'name': 'clear',
        'legacyModeEnabled': true,
        'legacyAliases': ['c'],
      });

      expect((healed['data'] as Map)['legacyAliases'], <String>['c']);
    });
  });

  group('CommandEditorState / CommandEditorNotifier – legacyAliases', () {
    test('valeur par défaut vide et copyWith préserve la liste', () {
      const state = CommandEditorState();
      expect(state.legacyAliases, isEmpty);

      final withAliases = state.copyWith(legacyAliases: const ['p']);
      expect(withAliases.legacyAliases, <String>['p']);
      expect(withAliases.copyWith().legacyAliases, <String>['p']);
    });

    test('updateLegacyAliases met à jour l\'état du notifier', () {
      final notifier = CommandEditorNotifier();
      addTearDown(notifier.dispose);

      notifier.updateLegacyAliases(const ['p', 'c']);
      expect(notifier.state.legacyAliases, <String>['p', 'c']);
    });
  });
}
