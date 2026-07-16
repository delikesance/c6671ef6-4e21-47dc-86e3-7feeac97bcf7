import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_runner/stores/managed_variable_store.dart';
import 'package:test/test.dart';

void main() {
  test('ManagedVariableStore removeAllScopedValuesForKey posts delete-by-key', () async {
    final requests = <Map<String, String>>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() async {
      await server.close(force: true);
    });

    server.listen((request) async {
      final body = await utf8.decoder.bind(request).join();
      requests.add({
        'method': request.method,
        'path': request.uri.path,
        'body': body,
      });
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'ok': true, 'deleted': 2}));
      await request.response.close();
    });

    final store = ManagedVariableStore(
      baseUrl: 'http://${server.address.host}:${server.port}',
      token: 'tok',
    );
    addTearDown(store.dispose);

    await store.removeAllScopedValuesForKey('bot-1', 'user', 'coins');

    expect(requests, hasLength(1));
    expect(requests.single['method'], 'POST');
    expect(requests.single['path'], '/bots/bot-1/variables/scoped/delete-by-key');
    expect(jsonDecode(requests.single['body']!), {
      'scope': 'user',
      'key': 'coins',
    });
  });
}
