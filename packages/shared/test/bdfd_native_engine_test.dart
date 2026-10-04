import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/services/http_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';

void main() {
  test(
    'prepared program composes context, HTTP, JSON, loops and persistence',
    () async {
      final store = MemoryBotDataStore();
      var requests = 0;
      final engine = BdfdEngine(
        store: store,
        botId: 'bot',
        http: HttpService(
          client: MockClient((_) async {
            requests++;
            return http.Response('{"items":[2,3,5]}', 200);
          }),
        ),
      );
      final program = engine.prepare(
        r'$httpGet[https://unit.test/items]$jsonParse[$httpResult]'
        r'$var[sum;0]$for[x=0;x<$jsonArrayCount[items];x++]'
        r'$var[sum;$sum[$var[sum];$json[items;$x]]]$endfor'
        r'$setUserVar[score;$var[sum]]$guildID:$getUserVar[score]',
      );
      expect(requests, 0, reason: 'preparing does not execute HTTP');
      expect(
        engine.supportedFunctions,
        containsAll(['for', 'endloop', 'try', 'httpget', 'jsonparse']),
      );
      final context = BdfdContext(
        variables: {'guild.id': '10', 'author.id': '20'},
      );
      expect(await engine.executeProgram(program, context: context), '10:10');
      expect(requests, 1);
      expect(store.scopedVariables['guildMember']!['10:20']!['score'], '10');
    },
  );

  test(
    'engine preserves unknown source and refuses incomplete known capabilities',
    () async {
      var effects = 0;
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        functions: {
          'effect': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) {
              effects++;
              return '';
            },
          ),
        },
      );
      expect(await engine.execute(r'$unknown[$effect]'), r'$unknown[$effect]');
      expect(effects, 0);
      expect(
        () => engine.prepare(r'$effect$title[not migrated]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(effects, 0);
    },
  );

  test(
    'two invocations of one engine keep their JSON and HTTP session state separate',
    () async {
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        http: HttpService(
          client: MockClient(
            (request) async =>
                http.Response('{"url":"${request.url.path}"}', 200),
          ),
        ),
      );
      final results = await Future.wait([
        engine.execute(
          r'$httpGet[https://unit.test/one]$jsonParse[$httpResult]$json[url]',
        ),
        engine.execute(
          r'$httpGet[https://unit.test/two]$jsonParse[$httpResult]$json[url]',
        ),
      ]);
      expect(results, ['/one', '/two']);
    },
  );
}
