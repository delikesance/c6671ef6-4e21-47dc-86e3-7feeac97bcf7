import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

/// User-reported BDFD scenarios, run on native-v1.
void main() {
  test(r'$for[item;...] iterates over a static list', () async {
    final result = await runScript(
      r'$nomention'
      r'$for[item;Alpha;Beta;Gamma;Delta]'
      '\$loopCount. \$item (index: \$loopIndex)\n'
      r'$endfor',
    );
    final content = contentOf(result)!;
    expect(content, contains('1. Alpha (index: 0)'));
    expect(content, contains('2. Beta (index: 1)'));
    expect(content, contains('3. Gamma (index: 2)'));
    expect(content, contains('4. Delta (index: 3)'));
  });

  test('a list loop works with embed mutations', () async {
    final result = await runScript(
      r'$title[Colors]'
      r'$for[color;red;green;blue]'
      r'$addField[Color $loopCount;$color;yes]'
      r'$endfor',
    );
    expectOk(result);
    final embed = (payloads(result).single['embeds'] as List).single as Map;
    expect(
      [for (final f in embed['fields'] as List) '${f['name']}=${f['value']}'],
      ['Color 1=red', 'Color 2=green', 'Color 3=blue'],
    );
  });

  test(
    r'$mentioned[1;yes] falls back to the author without a mention',
    () async {
      expect(contentOf(await runScript(r'$mentioned[1;yes]')), '20');
      expect(
        contentOf(
          await runScript(
            r'$mentioned[1;yes]',
            variables: {'message.mentions': '55'},
          ),
        ),
        '55',
      );
    },
  );

  test('textSplit and jsonArray work together', () async {
    final result = await runScript(
      r'$textSplit[a,b,c;,]$jsonArray[list]'
      r'$for[3]$jsonArrayAppend[list;$splitText[$sum[$i;1]]]$endfor'
      r'$jsonArrayCount[list]:$jsonJoinArray[list;-]',
    );
    expect(contentOf(result), '3:a-b-c');
  });
}
