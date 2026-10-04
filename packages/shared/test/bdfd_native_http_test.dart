import 'dart:async';

import 'package:bot_creator_shared/actions/executors/http_executor.dart';
import 'package:bot_creator_shared/engine/bdfd/http_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/http_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

class _TrackingClient extends http.BaseClient {
  _TrackingClient(this.mock);
  final MockClient mock;
  bool closed = false;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      mock.send(request);
  @override
  void close() {
    closed = true;
    mock.close();
  }
}

void main() {
  late List<http.Request> requests;
  late _TrackingClient client;
  late BdfdRuntime runtime;
  setUp(() {
    requests = [];
    client = _TrackingClient(
      MockClient((request) async {
        requests.add(request);
        return http.Response(
          '{"items":[{"name":"sword"}],"method":"${request.method}"}',
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );
    runtime = BdfdRuntime(
      functions: bdfdHttpFunctions(HttpService(client: client)),
    );
  });
  tearDown(() => client.close());

  test(
    'request, status and nested result paths are native runtime operations',
    () async {
      expect(
        await runtime.execute(
          r'$httpAddHeader[Content-Type;application/json]'
          r'$httpPost[https://unit.test/items;{"name":"shield"}]'
          r'$httpStatus:$httpResult[items;0;name]:$httpResult[method]',
        ),
        '201:sword:POST',
      );
      expect(requests.single.body, '{"name":"shield"}');
      expect(requests.single.headers['content-type'], 'application/json');
      expect(
        client.closed,
        isFalse,
        reason: 'the supplied client stays caller-owned',
      );
    },
  );

  test(
    'headers are consumed by one request and GET ignores the body',
    () async {
      await runtime.execute(
        r'$httpAddHeader[X-Trace;one]$httpGet[https://unit.test/one;ignored]'
        r'$httpGet[https://unit.test/two]',
      );
      expect(requests[0].headers['x-trace'], 'one');
      expect(requests[0].body, '');
      expect(requests[1].headers.containsKey('x-trace'), isFalse);
    },
  );

  test('header names are case insensitive', () async {
    await runtime.execute(
      r'$httpAddHeader[X-Test;old]$httpAddHeader[x-test;new]'
      r'$httpGet[https://unit.test/items]',
    );
    expect(requests.single.headers['x-test'], 'new');
  });

  test(
    'methods use their dedicated transport without producing response text',
    () async {
      for (final method in ['Get', 'Post', 'Put', 'Patch', 'Delete', 'Head']) {
        expect(
          await runtime.execute('\$http$method[https://unit.test/items;data]'),
          '',
        );
        expect(requests.last.method, method.toUpperCase());
        expect(
          requests.last.body,
          ['Get', 'Head'].contains(method) ? '' : 'data',
        );
      }
    },
  );

  test(
    'HTTP context is shared by nested eval and isolated between invocations',
    () async {
      final context = BdfdContext(
        temporaryVariables: {'code': r'$httpGet[https://unit.test/items]'},
      );
      expect(
        await runtime.execute(
          r'$eval[$var[code]]$httpStatus',
          context: context,
        ),
        '200',
      );
      await expectLater(
        runtime.execute(r'$httpStatus'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(requests, hasLength(1));
    },
  );

  test(
    'unknown calls, comments and skipped branches never make requests',
    () async {
      expect(
        await runtime.execute(
          r'$if[false]$httpGet[https://unit.test/items]$endif'
          r'$unknown[$httpGet[https://unit.test/items]]',
        ),
        r'$unknown[$httpGet[https://unit.test/items]]',
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'missing results and unsupported URL schemes produce positioned errors',
    () async {
      await expectLater(
        runtime.execute('\n\$httpResult'),
        throwsA(
          isA<BdfdNativeError>().having((e) => e.location.line, 'line', 2),
        ),
      );
      await expectLater(
        runtime.execute(r'$httpGet[file:///tmp/data]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'JSON path extraction returns empty text for missing or invalid JSON data',
    () async {
      final bad = BdfdRuntime(
        functions: bdfdHttpFunctions(
          HttpService(
            client: MockClient((_) async => http.Response('not JSON', 500)),
          ),
        ),
      );
      expect(
        await bad.execute(
          r'$httpGet[https://unit.test/items]$httpStatus:$httpResult[missing]',
        ),
        '500:',
      );
      expect(
        await runtime.execute(
          r'$httpGet[https://unit.test/items]$httpResult[items;4]',
        ),
        '',
      );
    },
  );

  test(
    'timeout of nested HTTP cancels later effects without updating session results',
    () async {
      final gate = Completer<http.Response>();
      var effects = 0;
      final engine = BdfdRuntime(
        functions: {
          ...bdfdHttpFunctions(
            HttpService(client: MockClient((_) => gate.future)),
          ),
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
      final context = BdfdContext(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 20)),
        temporaryVariables: {
          'code': r'$try$httpGet[https://unit.test/items]$catch$effect$endtry',
        },
      );
      await expectLater(
        engine.execute(r'$eval[$var[code]]$effect', context: context),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      gate.complete(http.Response('late', 200));
      await Future<void>.delayed(Duration.zero);
      expect(effects, 0);
      expect(context.http.latest, isNull);
    },
  );

  test(
    'visual HTTP executor shares the deadline and does not persist late results',
    () async {
      final gate = Completer<http.Response>();
      final results = <String, String>{};
      final variables = <String, String>{};
      final persisted = <String>[];
      await expectLater(
        executeHttpAction(
          type: BotCreatorActionType.httpRequest,
          payload: {
            'url': 'https://unit.test/items',
            'saveBodyToGlobalVar': 'body',
          },
          resultKey: 'request',
          results: results,
          variables: variables,
          resolveValue: (value) => value,
          onLog: null,
          setGlobalVariable: (key, value) async {
            persisted.add(value);
          },
          httpClient: MockClient((_) => gate.future),
          executionBudget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 20),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      gate.complete(http.Response('late', 200));
      await Future<void>.delayed(Duration.zero);
      expect(results, isEmpty);
      expect(variables, isEmpty);
      expect(persisted, isEmpty);
    },
  );

  test(
    'service closes owned clients after success and deadline expiration',
    () async {
      final owned = _TrackingClient(
        MockClient((_) async => http.Response('ok', 200)),
      );
      final service = HttpService(clientFactory: () => owned);
      expect(
        (await service.request(
          method: 'GET',
          url: 'https://unit.test/items',
        )).body,
        'ok',
      );
      expect(owned.closed, isTrue);
      final gate = Completer<http.Response>();
      final timed = _TrackingClient(MockClient((_) => gate.future));
      await expectLater(
        HttpService(clientFactory: () => timed).request(
          method: 'GET',
          url: 'https://unit.test/items',
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 20),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(timed.closed, isTrue);
      gate.complete(http.Response('late', 200));
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'requests and readable responses match the actual visual HTTP executor',
    () async {
      const source =
          r'$httpAddHeader[X-Trace;parity]'
          r'$httpPost[https://unit.test/items;{"name":"shield"}]'
          r'$httpStatus:$httpResult[items;0;name]';
      final compiled = BdfdCompiler().compile(source);
      expect(compiled.hasErrors, isFalse);
      final variables = <String, String>{};
      final results = <String, String>{};
      for (final action in compiled.actions.where(
        (action) => action.type == BotCreatorActionType.httpRequest,
      )) {
        await executeHttpAction(
          type: action.type,
          payload: action.payload,
          resultKey: action.key!,
          results: results,
          variables: variables,
          resolveValue: (value) =>
              resolveTemplatePlaceholders(value, variables),
          onLog: null,
          setGlobalVariable: (_, _) async {},
          httpClient: client,
        );
      }
      final response = compiled.actions.last;
      final legacyText = resolveTemplatePlaceholders(
        response.payload['content'].toString(),
        variables,
      );
      final nativeText = await runtime.execute(source);
      expect(nativeText, legacyText);
      expect(requests, hasLength(2));
      expect(requests[1].method, requests[0].method);
      expect(requests[1].url, requests[0].url);
      expect(requests[1].headers, requests[0].headers);
      expect(requests[1].body, requests[0].body);
    },
  );
}
