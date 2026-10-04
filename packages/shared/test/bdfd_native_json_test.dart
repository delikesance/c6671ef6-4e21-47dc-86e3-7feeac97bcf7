import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/json_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/variable_functions.dart';
import 'package:bot_creator_shared/services/variable_service.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';

class _NoDiscord implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('$invocation');
}

void main() {
  BdfdRuntime native([MemoryBotDataStore? store]) => BdfdRuntime(
    functions: {
      ...bdfdJsonFunctions(),
      if (store != null)
        ...bdfdVariableFunctions(VariableService(store, 'bot')),
    },
  );

  test(
    'nested JSON paths preserve numbers, booleans and explicit null existence',
    () async {
      expect(
        await native().execute(
          r'$jsonParse[{"items":[{"name":"sword","count":3}],"active":true,"none":null}]'
          r'$json[items;0;name]|$json[items;0;count]|$json[active]|'
          r'$jsonExists[none]|$json[none]|$jsonExists[missing]',
        ),
        'sword|3|true|true||false',
      );
    },
  );

  test('dynamic paths and mutations are evaluated in order', () async {
    expect(
      await native().execute(
        r'$jsonClear$var[key;loot]$jsonSet[$var[key];coins;10]'
        r'$jsonSetString[$var[key];code;001]'
        r'$json[$var[key];coins]:$json[$var[key];code]:$jsonStringify',
      ),
      '10:001:{"loot":{"coins":10,"code":"001"}}',
    );
  });

  test(
    'array initialization splits strings and preserves existing arrays',
    () async {
      expect(
        await native().execute(
          r'$jsonParse[{"tags":"red|blue"}]$jsonArray[tags;|]'
          r'$jsonArray[tags;|]$jsonArrayAppend[tags;green]'
          r'$jsonArrayCount[tags]:$jsonJoinArray[tags;-]',
        ),
        '3:red-blue-green',
      );
    },
  );

  test(
    'array removal, prepend, index, sort and reverse use runtime data',
    () async {
      expect(
        await native().execute(
          r'$jsonParse[{"n":[10,2]}]$jsonArrayUnshift[n;3]'
          r'$jsonArraySort[n;asc]$jsonArrayReverse[n]'
          r'$jsonArrayIndex[n;3]:$jsonArrayPop[n]:$jsonArrayShift[n]:$jsonStringify',
        ),
        '1:2:10:{"n":[3]}',
      );
    },
  );

  test('a first numeric assignment materializes a root array', () async {
    expect(
      await native().execute(r'$jsonSet[0;first]$json[0]:$jsonStringify'),
      'first:["first"]',
    );
  });

  test('root arrays and numeric nested paths are executable', () async {
    expect(
      await native().execute(
        r'$jsonParse[[]]$jsonSet[0;name;first]'
        r'$json[0;name]:$jsonArrayCount:$jsonStringify',
      ),
      'first:1:[{"name":"first"}]',
    );
  });

  test(
    'JSON parse alias, keys and unset preserve the remaining document',
    () async {
      expect(
        await native().execute(
          r'$json[{"obj":{"a":1,"b":2}}]$jsonUnset[obj;a]'
          r'$jsonKeys[obj;|]:$jsonStringify',
        ),
        'b:{"obj":{"b":2}}',
      );
    },
  );

  test('pretty output preserves spaces inside strings', () async {
    expect(
      await native().execute(r'$jsonParse[{"text":"a  b"}]$jsonPretty[1]'),
      '{\n "text": "a  b"\n}',
    );
  });

  test('empty or corrupted storage bootstraps a writable document', () async {
    for (final value in ['', 'corrupted', '0', 'null']) {
      final context = BdfdContext(temporaryVariables: {'source': value});
      expect(
        await native().execute(
          r'$jsonParse[$var[source]]$jsonArrayAppend[items;sword]$jsonStringify',
          context: context,
        ),
        '{"items":["sword"]}',
      );
    }
  });

  test('skipped branches and unknown functions do not mutate JSON', () async {
    expect(
      await native().execute(
        r'$jsonClear$if[false]$jsonSet[x;wrong]$endif'
        r'$unknown[$jsonSet[x;wrong]]:$jsonStringify',
      ),
      r'$unknown[$jsonSet[x;wrong]]:{}',
    );
  });

  test(
    'eval shares the JSON document; a returned dollar string stays data',
    () async {
      final context = BdfdContext(
        temporaryVariables: {
          'code': r'$jsonSet[x;changed]',
          'text': r'$jsonClear',
        },
      );
      expect(
        await native().execute(
          r'$jsonClear$eval[$var[code]]$jsonSetString[text;$var[text]]$jsonStringify',
          context: context,
        ),
        r'{"x":"changed","text":"$jsonClear"}',
      );
    },
  );

  test('storage and final values match the actual existing handler', () async {
    const source =
        r'$jsonParse[$getServerVar[items_db]]'
        r'$jsonArray[items]$for[3]$jsonArrayAppend[items;$i]$endfor'
        r'$var[count;$jsonArrayCount[items]]'
        r'$var[index;$jsonArrayIndex[items;1]]'
        r'$var[value;$json[items;$var[index]]]'
        r'$var[pretty;$jsonPretty[1]]'
        r'$setServerVar[items_db;$jsonStringify]'
        r'$var[join;$jsonJoinArray[items;-]]';
    final legacyStore = MemoryBotDataStore();
    final nativeStore = MemoryBotDataStore();
    final legacyVariables = <String, String>{
      'guild.id': '10',
      'author.id': '20',
    };
    final compiled = BdfdCompiler().compile(source);
    expect(compiled.hasErrors, isFalse);
    final result = await handleActions(
      _NoDiscord(),
      null,
      actions: compiled.actions,
      store: legacyStore,
      botId: 'bot',
      variables: legacyVariables,
      fallbackGuildId: Snowflake(10),
      resolveTemplate: (text) =>
          resolveTemplatePlaceholders(text, legacyVariables),
    );
    expect(result['error'], isNull, reason: '$result');
    final context = BdfdContext(
      variables: {'guild.id': '10', 'author.id': '20'},
    );
    await native(nativeStore).execute(source, context: context);
    expect(nativeStore.scopedVariables, legacyStore.scopedVariables);
    for (final key in ['count', 'index', 'value', 'pretty', 'join']) {
      expect(
        context.temporaryVariables[key],
        legacyVariables['temp.$key'],
        reason: key,
      );
    }
  });
}
