import 'package:http/http.dart' as http;

import '../engine/execution_budget.dart';

dynamic extractHttpJsonPath(dynamic data, String rawPath) {
  var path = rawPath.trim();
  if (path.isEmpty) return null;

  if (path.startsWith(r'$.')) {
    path = path.substring(2);
  } else if (path.startsWith(r'$')) {
    path = path.substring(1);
  }

  if (path.isEmpty) return data;

  final segments = <Object>[];
  final token = StringBuffer();

  void flushToken() {
    if (token.isNotEmpty) {
      segments.add(token.toString());
      token.clear();
    }
  }

  for (var i = 0; i < path.length; i++) {
    final char = path[i];
    if (char == '.') {
      flushToken();
      continue;
    }
    if (char == '[') {
      flushToken();
      final closing = path.indexOf(']', i + 1);
      if (closing == -1) return null;
      final indexText = path.substring(i + 1, closing).trim();
      final index = int.tryParse(indexText);
      if (index == null) return null;
      segments.add(index);
      i = closing;
      continue;
    }
    token.write(char);
  }
  flushToken();

  dynamic current = data;
  for (final segment in segments) {
    if (segment is String) {
      if (segment.isEmpty) continue;
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
      continue;
    }
    if (segment is int) {
      if (current is List && segment >= 0 && segment < current.length) {
        current = current[segment];
      } else {
        return null;
      }
    }
  }

  return current;
}

class HttpResponseData {
  HttpResponseData({
    required this.status,
    required this.body,
    Map<String, String> headers = const {},
  }) : headers = Map.unmodifiable(headers);
  final int status;
  final String body;
  final Map<String, String> headers;
}

/// Transport shared by visual HTTP blocks and native BDFD. A supplied client
/// remains owned by its caller; otherwise each request closes its own client.
class HttpService {
  HttpService({this.client, this.clientFactory, this.onLog});
  final http.Client? client;
  final http.Client Function()? clientFactory;
  final void Function(String)? onLog;

  Future<HttpResponseData> request({
    required String method,
    required String url,
    Map<String, String> headers = const {},
    String? body,
    CommandExecutionBudget? budget,
  }) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      throw FormatException('Invalid URL for HTTP request: $url');
    }
    if (!['http', 'https'].contains(uri.scheme)) {
      throw const FormatException('Only http and https schemes are allowed');
    }
    final normalizedMethod = method.trim().toUpperCase();
    if (!{
      'GET',
      'POST',
      'PUT',
      'PATCH',
      'DELETE',
      'HEAD',
    }.contains(normalizedMethod)) {
      throw FormatException('Unsupported HTTP method: $method');
    }
    budget?.check();
    final request = http.Request(normalizedMethod, uri);
    request.headers.addAll(headers);
    if (normalizedMethod != 'GET' &&
        normalizedMethod != 'HEAD' &&
        body != null) {
      request.body = body;
    }
    onLog?.call('HTTP: $normalizedMethod $url');
    if (headers.isNotEmpty) onLog?.call('HTTP Headers: $headers');
    if (request.body.isNotEmpty) {
      onLog?.call('HTTP Payload sent: ${request.body}');
    }
    final transport = client ?? clientFactory?.call() ?? http.Client();
    Future<HttpResponseData> send() async {
      final streamed = await transport.send(request);
      final responseBody = await streamed.stream.bytesToString();
      budget?.check();
      onLog?.call(
        'HTTP Response: ${streamed.statusCode} (${responseBody.length} bytes)',
      );
      if (responseBody.isNotEmpty) {
        onLog?.call('HTTP Payload received: $responseBody');
      }
      return HttpResponseData(
        status: streamed.statusCode,
        body: responseBody,
        headers: streamed.headers,
      );
    }

    try {
      return budget == null ? await send() : await budget.run(send);
    } finally {
      if (client == null) transport.close();
    }
  }
}

/// Per-invocation HTTP state; nested eval shares it, concurrent commands don't.
class HttpSession {
  final Map<String, String> pendingHeaders = {};
  HttpResponseData? latest;
}
