import 'dart:convert';

import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

void main() {
  group(r'$jsonSet with array indices', () {
    Future<String?> run(String script, [String? db]) async => contentOf(
      await runScript(
        script,
        extra: {
          if (db != null)
            'scoped': {
              'guild': {
                '10': {'db': db},
              },
            },
        },
      ),
    );

    test('creates an array element from an empty object', () async {
      final out = await run(
        r'$jsonParse[$getServerVar[db]]$jsonSet[currency;0;name;carrot]$jsonStringify',
      );
      final decoded = jsonDecode(out!) as Map<String, dynamic>;
      expect(
        (decoded['currency'] as List).first,
        containsPair('name', 'carrot'),
      );
    });

    test('mutates an existing array element', () async {
      final out = await run(
        r'$jsonParse[$getServerVar[db]]$jsonSet[currency;1;name;carrot]$jsonStringify',
        '{"currency":[{"name":"bunbux"},{"name":"old"}]}',
      );
      final list = (jsonDecode(out!) as Map)['currency'] as List;
      expect(list[0], containsPair('name', 'bunbux'));
      expect(list[1], containsPair('name', 'carrot'));
    });

    test(
      'extends the list with nulls when the index is out of bounds',
      () async {
        final out = await run(
          r'$jsonParse[$getServerVar[db]]$jsonSet[arr;2;x;1]$jsonStringify',
          '{"arr":[]}',
        );
        final arr = (jsonDecode(out!) as Map)['arr'] as List;
        expect(arr.length, 3);
        expect(arr[0], isNull);
        expect(arr[1], isNull);
        expect(arr[2], containsPair('x', 1));
      },
    );

    test(r'a $jsonParse inside an untaken $if does not leak', () async {
      final result = await runScript(
        r'$jsonParse[$getServerVar[outer]]'
        r'$if[$json[flag]==yes]'
        r'$jsonParse[$getServerVar[inner]]'
        r'$endif'
        r'$json[outerKey]|$json[innerKey]',
        extra: {
          'scoped': {
            'guild': {
              '10': {
                'outer': '{"outerKey":"outer_val","flag":"no"}',
                'inner': '{"innerKey":"inner_val"}',
              },
            },
          },
        },
      );
      expect(contentOf(result), 'outer_val|');
    });
  });
}
