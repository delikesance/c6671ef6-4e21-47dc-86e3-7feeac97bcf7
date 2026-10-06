import 'dart:convert';

import '../../services/http_service.dart';
import '../../services/json_document.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdHttpFunctions(HttpService service) {
  final functions = <String, BdfdNativeFunction>{};
  functions['httpaddheader'] = BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final name = (await call.argument(0)).trim();
      if (name.isEmpty) {
        throw BdfdNativeError(
          'HTTP header name cannot be empty.',
          call.location,
        );
      }
      final value = await call.argument(1);
      final headers = call.context.http.pendingHeaders;
      headers.removeWhere((key, _) => key.toLowerCase() == name.toLowerCase());
      headers[name] = value;
      return '';
    },
  );
  for (final method in ['get', 'post', 'put', 'patch', 'delete', 'head']) {
    functions['http$method'] = BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final url = (await call.argument(0)).trim();
        if (url.isEmpty) {
          throw BdfdNativeError(
            'HTTP request URL cannot be empty.',
            call.location,
          );
        }
        final body = call.argumentCount == 2 ? await call.argument(1) : '';
        final session = call.context.http;
        final headers = Map<String, String>.of(session.pendingHeaders);
        session.pendingHeaders.clear();
        final response = await service.request(
          method: method,
          url: url,
          body: body,
          headers: headers,
          budget: call.context.budget,
        );
        session.latest = response;
        call.context.results['http.status'] = '${response.status}';
        call.context.results['http.body'] = response.body;
        return '';
      },
    );
  }
  HttpResponseData latest(BdfdInvocation call) =>
      call.context.http.latest ??
      (throw BdfdNativeError(
        'A preceding HTTP request is required.',
        call.location,
      ));
  functions['httpstatus'] = BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) => '${latest(call).status}',
  );
  functions['httpresult'] = BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 100,
    handler: (call) async {
      final body = latest(call).body;
      if (call.argumentCount == 0) return body;
      final segments = <String>[];
      for (var i = 0; i < call.argumentCount; i++) {
        final segment = (await call.argument(i)).trim();
        if (segment.isEmpty) continue;
        final index = int.tryParse(segment);
        if (i > 0 && index != null && segments.isNotEmpty) {
          segments[segments.length - 1] += '[$index]';
        } else {
          segments.add(segment);
        }
      }
      if (segments.isEmpty) return body;
      try {
        return stringifyJsonValue(
          extractHttpJsonPath(jsonDecode(body), segments.join('.')),
        );
      } on FormatException {
        return '';
      }
    },
  );
  return functions;
}
