import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_runner/sandbox_service.dart';
import 'package:bot_creator_runner/web_bootstrap_server.dart';
import 'package:bot_creator_runner/web_log_store.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('sandbox routes', () {
    RunnerWebBootstrapServer? server;
    late Directory tempDir;
    late int port;

    Future<void> boot({String? apiToken, RunnerSandboxService? service}) async {
      port = await _allocatePort();
      server = RunnerWebBootstrapServer(
        host: '127.0.0.1',
        port: port,
        apiToken: apiToken,
        logStore: RunnerLogStore(),
        dataDir: tempDir.path,
        sandboxService: service,
      );
      await server!.start();
    }

    Uri url(String path) => Uri.parse('http://127.0.0.1:$port$path');

    Future<http.Response> post(
      Object body, {
      Map<String, String> headers = const {},
    }) => http.post(
      url('/bots/b1/sandbox/command'),
      headers: {'content-type': 'application/json', ...headers},
      body: body is String ? body : jsonEncode(body),
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('runner-sandbox-');
    });

    tearDown(() async {
      await server?.stop();
      server = null;
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test(
      'valid request: runs the real engine and returns its result',
      () async {
        await boot();
        final response = await post({
          'script': r'Hello $message[name]',
          'bdfdBackend': 'native-v1',
          'options': {'name': 'World'},
          'variables': {'interaction.isSlash': 'true'},
        });

        expect(response.statusCode, HttpStatus.ok);
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        final responses = body['responses'] as List;
        expect(responses, hasLength(1));
        expect(responses.first['payload']['content'], 'Hello World');
      },
    );

    test('an engine failure is a normal 200 result, as on a device', () async {
      await boot();
      final response = await post({'script': 'x', 'actions': <dynamic>[]});

      expect(response.statusCode, HttpStatus.ok);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isFalse);
      expect(body['error'], contains('exactly one of script or actions'));
    });

    test('oversize body: 413 payload_too_large, even when streamed', () async {
      await boot(service: RunnerSandboxService(maxBodyBytes: 1024));

      final declared = await post({'script': 'a' * 4096});
      expect(declared.statusCode, HttpStatus.requestEntityTooLarge);
      expect(jsonDecode(declared.body)['code'], 'payload_too_large');

      // No Content-Length: the cap must hold on the bytes actually received.
      final client = HttpClient();
      addTearDown(() => client.close(force: true));
      final request = await client.postUrl(url('/bots/b1/sandbox/command'));
      request.headers.contentType = ContentType.json;
      request.headers.chunkedTransferEncoding = true;
      for (var i = 0; i < 8; i++) {
        request.add(utf8.encode('{"script":"${'a' * 400}"}'));
      }
      final streamed = await request.close();
      final streamedBody = await streamed.transform(utf8.decoder).join();
      expect(streamed.statusCode, HttpStatus.requestEntityTooLarge);
      expect(jsonDecode(streamedBody)['code'], 'payload_too_large');
    });

    test('malformed body: 400 invalid_request', () async {
      await boot();
      for (final bad in ['{not json', '[1,2]', '"text"', '']) {
        final response = await post(bad);
        expect(response.statusCode, HttpStatus.badRequest, reason: bad);
        expect(jsonDecode(response.body)['code'], 'invalid_request');
      }
    });

    test('timeout: 504 sandbox_timeout and the slot is released', () async {
      final service = RunnerSandboxService(
        timeout: const Duration(milliseconds: 50),
        run: (request, {Duration timeout = const Duration(seconds: 3)}) async {
          expect(timeout, const Duration(milliseconds: 50));
          return {
            'success': false,
            'error': 'Sandbox execution time limit exceeded',
            'terminated': true,
          };
        },
      );
      await boot(service: service);

      final response = await post({'script': 'x'});
      expect(response.statusCode, HttpStatus.gatewayTimeout);
      expect(jsonDecode(response.body)['code'], 'sandbox_timeout');
      expect(service.activeRuns, 0);
    });

    test('the real engine enforces its wall-clock limit', () async {
      // A 1 ms limit cannot be met by an isolate that has to boot first.
      await boot(
        service: RunnerSandboxService(timeout: const Duration(milliseconds: 1)),
      );
      final response = await post({'script': r'$sendMessage[late]'});
      expect(response.statusCode, HttpStatus.gatewayTimeout);
      expect(jsonDecode(response.body)['code'], 'sandbox_timeout');
    });

    test('concurrency cap: 429 sandbox_busy with Retry-After', () async {
      final gate = Completer<void>();
      final service = RunnerSandboxService(
        maxConcurrent: 1,
        run: (request, {Duration timeout = const Duration(seconds: 3)}) async {
          await gate.future;
          return {'success': true, 'responses': <dynamic>[]};
        },
      );
      await boot(service: service);

      final first = post({'script': 'x'});
      while (service.activeRuns == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final second = await post({'script': 'x'});
      expect(second.statusCode, HttpStatus.tooManyRequests);
      expect(jsonDecode(second.body)['code'], 'sandbox_busy');
      expect(second.headers['retry-after'], isNotNull);

      gate.complete();
      expect((await first).statusCode, HttpStatus.ok);
      expect(service.activeRuns, 0);
      expect((await post({'script': 'x'})).statusCode, HttpStatus.ok);
    });

    test(
      'an unexpected failure is a 500 sandbox_failed, slot released',
      () async {
        final service = RunnerSandboxService(
          run: (request, {Duration timeout = const Duration(seconds: 3)}) =>
              throw StateError('boom'),
        );
        await boot(service: service);

        final response = await post({'script': 'x'});
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(jsonDecode(response.body)['code'], 'sandbox_failed');
        expect(service.activeRuns, 0);
      },
    );

    test(
      'requires the bearer token like every other protected route',
      () async {
        await boot(apiToken: 'secret-token');
        final anonymous = await post({'script': 'x'});
        final catalog = await http.get(url('/bots/b1/sandbox/functions'));
        final ok = await post(
          {'script': r'$sendMessage[hi]'},
          headers: {'authorization': 'Bearer secret-token'},
        );
        expect(anonymous.statusCode, HttpStatus.unauthorized);
        expect(catalog.statusCode, HttpStatus.unauthorized);
        expect(ok.statusCode, HttpStatus.ok);
      },
    );

    test('the sandbox never needs the bot to exist or be running', () async {
      await boot();
      final response = await http.post(
        url('/bots/does-not-exist/sandbox/command'),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({'script': r'$sendMessage[ok]'}),
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body)['success'], isTrue);
    });

    test('function catalog: every case in wire form', () async {
      await boot();
      final response = await http.get(url('/bots/b1/sandbox/functions'));
      expect(response.statusCode, HttpStatus.ok);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final cases = (body['cases'] as List).cast<Map<String, dynamic>>();
      expect(body['count'], cases.length);
      expect(cases, isNotEmpty);
      final isNumber = cases.firstWhere((c) => c['function'] == 'isnumber');
      expect(isNumber['script'], isA<String>());
      expect(isNumber['expected'], isA<String>());
      expect(isNumber['options'], isA<Map>());
      expect(isNumber['scenario'], isA<Map>());
      expect(isNumber['expectedValues'], isA<Map>());
      final guard = cases.where((c) => c['function'] == 'onlyadmin');
      expect(guard.map((c) => c['label']), containsAll(['allowed', 'denied']));
    });

    test('a catalog case round-trips through the command route', () async {
      await boot();
      final cases =
          (jsonDecode((await http.get(url('/bots/b1/sandbox/functions'))).body)
                  as Map)['cases']
              as List;
      final sample =
          (cases.firstWhere((c) => c['function'] == 'isnumber')
              as Map<String, dynamic>);
      final response = await post({
        'script': sample['script'],
        'options': sample['options'],
        'variables': {'interaction.isSlash': 'true'},
        ...Map<String, dynamic>.from(sample['scenario'] as Map)
          ..remove('script'),
      });
      expect(response.statusCode, HttpStatus.ok);
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['responses'][0]['payload']['content'], sample['expected']);
    });
  });

  group('no network egress', () {
    // A real loopback server stands in for "the network or an internal address":
    // if anything in the sandbox reached it, the counter would move.
    late HttpServer target;
    var hits = 0;
    late String origin;
    late RunnerSandboxService service;

    setUp(() async {
      hits = 0;
      target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      origin = 'http://127.0.0.1:${target.port}';
      target.listen((request) {
        hits++;
        request.response
          ..statusCode = 200
          ..write('reached')
          ..close();
      });
      service = RunnerSandboxService(timeout: const Duration(seconds: 10));
    });

    tearDown(() async {
      await target.close(force: true);
    });

    Future<Map<String, dynamic>> run(Map<String, dynamic> request) =>
        service.run(request);

    test(
      r'$httpGet to an internal address needs a fixture, goes nowhere',
      () async {
        final result = await run({'script': '\$httpGet[$origin/secret]'});
        expect(result['success'], isFalse);
        expect(result['error'].toString(), contains('requires an explicit'));
        expect(hits, 0);
      },
    );

    test(
      'an httpRequest block goes through the mock, not the socket',
      () async {
        final result = await run({
          'actions': [
            {
              'type': 'httpRequest',
              'payload': {'url': '$origin/secret', 'method': 'GET'},
            },
          ],
        });
        expect(jsonEncode(result), contains('explicit simulation fixture'));
        expect(hits, 0);
      },
    );

    test('a fixture answers instead of the real server', () async {
      final result = await run({
        'script': '\$httpGet[$origin/secret]\$sendMessage[done]',
        'http': [
          {'method': 'GET', 'url': '$origin/secret', 'body': 'mocked'},
        ],
      });
      expect(result['success'], isTrue);
      expect(result['unused_http_fixtures'], 0);
      expect(
        (result['effects'] as List).single,
        containsPair('simulated', true),
      );
      expect(hits, 0);
    });

    test('canvas image URLs and emoji URLs never reach the server', () async {
      final canvas = await run({
        'script': '\$canvasCreate[c;2;2;white]\$canvasLoadImage[$origin/i.png]',
      });
      final emoji = await run({
        'script': '\$addEmoji[Smile;$origin/e.png;yes]',
      });
      expect(canvas['success'], isFalse);
      expect(emoji['success'], isFalse);
      expect(hits, 0);
    });

    test(
      'webhook calls to an internal address never leave the sandbox',
      () async {
        final result = await run({
          'script': '\$webhookSend[$origin/api/webhooks/1/token;hello]',
        });
        expect(result['success'], isFalse);
        expect(hits, 0);
      },
    );
  });
}

Future<int> _allocatePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
