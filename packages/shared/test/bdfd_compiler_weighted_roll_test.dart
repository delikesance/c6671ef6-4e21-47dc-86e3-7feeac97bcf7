import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

const _items =
    '{"items":['
    '{"name":"sword","weight":3,"enabled":true,"rarity":"common","extra":true},'
    '{"name":"shield","weight":3,"enabled":false,"rarity":"common"},'
    '{"name":"crown","weight":4,"enabled":true,"rarity":"legendary"}'
    ']}';

Map<String, dynamic> get _storage => {
  'scoped': {
    'guild': {
      '10': {'items_db': _items},
    },
  },
};

Future<String?> _run(String script, {Map<String, dynamic>? variables}) async =>
    contentOf(await runScript(script, variables: variables, extra: _storage));

void main() {
  group('weighted roll built from nested JSON, loops and ifs', () {
    test(
      'a loop can find an item by name and answer with its weight',
      () async {
        expect(
          await _run(
            r'$jsonParse[$getServerVar[items_db]]'
            r'$var[in;items]'
            r'$var[target;sword]'
            r'$var[looping;$jsonArrayCount[$var[in]]]'
            r'$for[$var[looping]]'
            r'$if[$json[$var[in];$i;name]==$var[target]]'
            r'$json[$var[in];$i;weight]'
            r'$endif'
            r'$endfor',
          ),
          '3',
        );
      },
    );

    // Accumulate the total weight, then choose by a roll in 1..total.
    String roll(String rollSource) =>
        r'$jsonParse[$getServerVar[items_db]]'
        r'$var[in;items]'
        r'$var[looping;$jsonArrayCount[$var[in]]]'
        r'$var[totalWeight;0]'
        r'$for[$var[looping]]'
        r'$var[itemWeight;$json[$var[in];$i;weight]]'
        r'$var[totalWeight;$calculate[$var[totalWeight]+$var[itemWeight]]]'
        r'$endfor'
        '\$var[roll;$rollSource]'
        r'$var[currentWeight;0]'
        r'$var[winner;]'
        r'$for[$var[looping]]'
        r'$var[itemName;$json[$var[in];$i;name]]'
        r'$var[itemWeight;$json[$var[in];$i;weight]]'
        r'$var[currentWeight;$calculate[$var[currentWeight]+$var[itemWeight]]]'
        r'$if[$var[winner]==]'
        r'$if[$var[roll]<=$var[currentWeight]]'
        r'$var[winner;$var[itemName]]'
        r'$endif'
        r'$endif'
        r'$endfor'
        r'$var[totalWeight]:$var[winner]';

    test('the winner follows the accumulated weights', () async {
      // weights: sword 1-3, shield 4-6, crown 7-10
      final expected = {
        1: 'sword',
        3: 'sword',
        4: 'shield',
        6: 'shield',
        7: 'crown',
        10: 'crown',
      };
      for (final entry in expected.entries) {
        expect(
          await _run(roll('${entry.key}')),
          '10:${entry.value}',
          reason: 'roll ${entry.key}',
        );
      }
    });

    test('a random roll always selects one of the items', () async {
      for (var i = 0; i < 5; i++) {
        expect(
          await _run(roll(r'$random[1;10]')),
          matches(RegExp(r'^10:(sword|shield|crown)$')),
        );
      }
    });

    test('an if with a JSON condition and else branch', () async {
      const script =
          r'$jsonParse[{"items":{"a":{"enabled":true},"b":{"enabled":false}}}]'
          r'$var[in;items]'
          r'$if[$json[$var[in];$message[1];enabled]==true]enabled$else disabled$endif';
      expect(
        await _run(script, variables: {'message.content': 'a'}),
        'enabled',
      );
      expect(
        (await _run(script, variables: {'message.content': 'b'}))?.trim(),
        'disabled',
      );
    });

    // Loot flow: tiers, enabled gate, fallback and first-win $stop.
    String loot(String rollValue) =>
        r'$jsonParse[$getServerVar[items_db]]'
        r'$var[in;items]'
        r'$var[looping;$jsonArrayCount[$var[in]]]'
        '\$var[roll;$rollValue]'
        r'$var[currentWeight;0]'
        r'$var[winner;]'
        r'$for[$var[looping]]'
        r'$if[$json[$var[in];$i;enabled]==true]'
        r'$if[$json[$var[in];$i;rarity]==legendary]'
        r'$var[bonus;2]'
        r'$else'
        r'$var[bonus;0]'
        r'$endif'
        r'$var[itemWeight;$json[$var[in];$i;weight]]'
        r'$var[currentWeight;$calculate[$var[currentWeight]+$var[itemWeight]+$var[bonus]]]'
        r'$if[$var[winner]==]'
        r'$if[$var[roll]<=$var[currentWeight]]'
        r'$var[winner;$json[$var[in];$i;name]]'
        r'$var[winner]'
        r'$stop'
        r'$endif'
        r'$endif'
        r'$endif'
        r'$endfor'
        r'$if[$var[winner]==]'
        r'fallback_common'
        r'$endif';

    test(
      'disabled items are skipped and the first win stops the script',
      () async {
        // enabled: sword (cum. 3), crown (3 + 4 + 2 bonus = 9); shield skipped.
        expect(await _run(loot('2')), 'sword');
        expect(await _run(loot('3')), 'sword');
        expect(await _run(loot('4')), 'crown');
        expect(await _run(loot('9')), 'crown');
      },
    );

    test('a roll above every cumulative weight falls back', () async {
      expect(await _run(loot('10')), 'fallback_common');
    });
  });
}
