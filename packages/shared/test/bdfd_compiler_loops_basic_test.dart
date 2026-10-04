import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

List<Map<String, dynamic>> _embeds(Map<String, dynamic> result) => [
  for (final e in payloads(result).single['embeds'] as List)
    Map<String, dynamic>.from(e as Map),
];

void main() {
  group(r'$for loops', () {
    test(r'expose $i (0-based) and $loopCount (1-based)', () async {
      final result = await runScript(r'$for[3]$i is $loopCount;$endfor');
      expect(contentOf(result), '0 is 1;1 is 2;2 is 3;');
    });

    test(r'$loopIndex is an alias for $i', () async {
      final result = await runScript(r'$for[2]index=$loopIndex;$endfor');
      expect(contentOf(result), 'index=0;index=1;');
    });

    test('restore the loop index after nested loops', () async {
      final result = await runScript(
        r'$for[2]outer=$i;$for[2]inner=$i;$endfor$endfor',
      );
      expect(
        contentOf(result),
        'outer=0;inner=0;inner=1;outer=1;inner=0;inner=1;',
      );
    });

    test(
      'targeted embeds use 1-based indices and fields go to their embed',
      () async {
        final result = await runScript(
          r'$title[First Embed;1]'
          r'$description[This is the first embed;1]'
          r'$title[Second Embed;2]'
          r'$description[This is the second embed;2]'
          r'$addField[A;1;yes;1]'
          r'$addField[B;2;yes;1]'
          r'$addField[C;3;yes;1]'
          r'$addField[D;4;no;2]',
        );
        expectOk(result);
        final embeds = _embeds(result);
        expect(embeds, hasLength(2));
        expect(embeds[0]['title'], 'First Embed');
        expect(embeds[0]['description'], 'This is the first embed');
        expect(embeds[1]['title'], 'Second Embed');
        expect(embeds[1]['description'], 'This is the second embed');
        expect((embeds[0]['fields'] as List).map((f) => f['name']), [
          'A',
          'B',
          'C',
        ]);
        expect((embeds[1]['fields'] as List).map((f) => f['name']), ['D']);
      },
    );

    test('embed index 0 is rejected', () async {
      final result = await runScript(r'$title[First;0]');
      expect(result['success'], false);
    });

    test('a loop body can add fields to the pending embed', () async {
      final result = await runScript(
        r'$title[Test]$for[3]$addField[Item $loopCount;val $i;yes]$endfor$color[#FF0000]$footer[Done]',
      );
      expectOk(result);
      expect(payloads(result), hasLength(1));
      final embed = _embeds(result).single;
      expect(embed['title'], 'Test');
      expect(embed['color'], '#FF0000');
      expect(embed['footer'], containsPair('text', 'Done'));
      final fields = (embed['fields'] as List).cast<Map>();
      expect(fields.map((f) => f['name']), ['Item 1', 'Item 2', 'Item 3']);
      expect(fields.map((f) => f['value']), ['val 0', 'val 1', 'val 2']);
    });

    test('JSON mutations in a loop are readable from the embed', () async {
      final result = await runScript(
        r'$jsonClear$jsonArray[n]$for[5]$jsonArrayAppend[n;$i]$endfor$title[Count: $jsonArrayCount[n]]$description[$jsonJoinArray[n;-]]',
      );
      expectOk(result);
      final embed = _embeds(result).single;
      expect(embed['title'], 'Count: 5');
      expect(embed['description'], '0-1-2-3-4');
    });
  });
}
