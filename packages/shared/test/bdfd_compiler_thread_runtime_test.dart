import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

Map<String, dynamic> _guildStore(Map<String, dynamic> result) =>
    Map<String, dynamic>.from(
      (((result['storage_after'] as Map)['scoped'] as Map)['guild']
                  as Map?)?['10']
              as Map? ??
          {},
    );

void main() {
  test('thread helpers compile without diagnostics', () {
    final result = BdfdCompiler().compile(
      r'$startThread[Cool Thread;123;;1440;yes]'
      r'$editThread[12345;Cool Thread;no;!unchanged;!unchanged;5]'
      r'$threadAddMember[12345;999]'
      r'$threadRemoveMember[12345;999]'
      r'$reply$c[]Thread created: $startThread[Second Thread;123;;60;yes]',
    );
    expect(result.hasErrors, isFalse);
    expect(result.diagnostics, isEmpty);
  });

  // The thread functions themselves are executed against a fake thread
  // service in bdfd_native_threads_test.dart.

  group('JSON stored in a server variable', () {
    const add =
        r'$onlyIf[$argCount>0;usage]'
        r'$jsonParse[$getServerVar[items_db]]'
        r'$jsonArrayAppend[items;$message[1]]'
        r'$setServerVar[items_db;$jsonStringify]'
        r'ok';
    const find =
        r'$onlyIf[$argCount>0;usage]'
        r'$jsonParse[$getServerVar[items_db]]'
        r'$var[idx;$jsonArrayIndex[items;$message[1]]]'
        r'$if[$var[idx]==-1]not found$else '
        r'found at $var[idx]: $json[items;$var[idx]]$endif';

    test(
      'additem stringifies the mutated document into the variable',
      () async {
        final result = await runScript(
          add,
          variables: {'message.content': 'sword'},
        );
        expect(contentOf(result), 'ok');
        expect(_guildStore(result)['items_db'], '{"items":["sword"]}');
      },
    );

    test('additem answers with usage before touching storage', () async {
      final result = await runScript(add);
      expect(contentOf(result), 'usage');
      expect(_guildStore(result), isEmpty);
    });

    test('finditem reads the stored document', () async {
      Future<String?> run(String item) async => (contentOf(
        await runScript(
          find,
          variables: {'message.content': item},
          extra: {
            'scoped': {
              'guild': {
                '10': {'items_db': '{"items":["sword","shield"]}'},
              },
            },
          },
        ),
      ))?.trim();
      expect(await run('shield'), 'found at 1: shield');
      expect(await run('axe'), 'not found');
    });

    test('a literal setServerVar value is stored unchanged', () async {
      final result = await runScript(
        r'$jsonParse[{"items":[]}]$setServerVar[items_db;teststorage]ok',
      );
      expect(contentOf(result), 'ok');
      expect(_guildStore(result)['items_db'], 'teststorage');
    });
  });

  group(r'$try', () {
    test('runs the body after a JSON parse', () async {
      final result = await runScript(
        r'$jsonParse[{"items":["a"]}]'
        r'$try$var[idx;$jsonArrayIndex[items;$message[1]]]idx=$var[idx]'
        r'$catch fallback$endtry',
        variables: {'message.content': 'a'},
      );
      expect(contentOf(result), 'idx=0');
    });

    test('runs the catch branch when the body fails', () async {
      final result = await runScript(
        r'$try$var[n;$sum[a;1]]body$catch fallback$endtry',
      );
      expect(contentOf(result), ' fallback');
    });
  });
}
