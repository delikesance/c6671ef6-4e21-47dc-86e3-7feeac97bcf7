import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../types/action.dart';
import '../../services/http_service.dart';
import '../../engine/execution_budget.dart';

// ─── Private helpers ─────────────────────────────────────────────────────────

String _normalizeMethod(
  dynamic rawMethod,
  String Function(String) resolveValue,
) {
  final method = resolveValue(
    rawMethod?.toString() ?? 'GET',
  ).trim().toUpperCase();
  const supported = {'GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD'};
  if (!supported.contains(method)) return 'GET';
  return method;
}

bool _supportsBody(String method) => method != 'GET' && method != 'HEAD';

dynamic _resolveJsonLike(dynamic value, String Function(String) resolveValue) {
  if (value is String) return resolveValue(value);
  if (value is List) {
    return value.map((e) => _resolveJsonLike(e, resolveValue)).toList();
  }
  if (value is Map) {
    return Map<String, dynamic>.fromEntries(
      value.entries.map(
        (e) =>
            MapEntry(e.key.toString(), _resolveJsonLike(e.value, resolveValue)),
      ),
    );
  }
  return value;
}

// ─── Main executor ───────────────────────────────────────────────────────────

/// Handles [BotCreatorActionType.httpRequest].
///
/// Returns `true` when the action was handled, `false` otherwise.
///
/// The [setGlobalVariable] callback is used to persist results to global
/// variables, decoupling this executor from any concrete store implementation.
///
/// Note: `saveJsonPathToGlobalVar` has been intentionally removed — the
/// extracted value is exposed as a runtime variable (`{{resultKey.jsonPath}}`)
/// which is sufficient for the vast majority of use cases.
Future<bool> executeHttpAction({
  required BotCreatorActionType type,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required void Function(String message)? onLog,
  required Future<void> Function(String key, String value) setGlobalVariable,
  http.Client? httpClient,
  CommandExecutionBudget? executionBudget,
}) async {
  if (type != BotCreatorActionType.httpRequest) return false;

  final resolvedUrl = resolveValue((payload['url'] ?? '').toString()).trim();
  if (resolvedUrl.isEmpty) {
    throw Exception('url is required for httpRequest');
  }

  final method = _normalizeMethod(payload['method'], resolveValue);
  final bodyMode = resolveValue(
    (payload['bodyMode'] ?? 'json').toString(),
  ).toLowerCase();

  // Safely extract raw headers as Map<String, String> (before resolving)
  final rawHeadersMap = <String, String>{};
  if (payload['headers'] is Map) {
    (payload['headers'] as Map).forEach((key, value) {
      rawHeadersMap[key.toString()] = value?.toString() ?? '';
    });
  }
  onLog?.call(
    'HTTP raw headers count: ${rawHeadersMap.length}, keys: ${rawHeadersMap.keys.toList()}',
  );
  final headers = <String, String>{};
  for (final entry in rawHeadersMap.entries) {
    final key = resolveValue(entry.key).trim();
    if (key.isEmpty) continue;
    headers[key] = resolveValue(entry.value);
  }
  onLog?.call(
    'HTTP resolved headers count: ${headers.length}, keys: ${headers.keys.toList()}',
  );

  Object? requestBody;
  if (_supportsBody(method)) {
    if (bodyMode == 'text') {
      requestBody = resolveValue((payload['bodyText'] ?? '').toString());
    } else {
      // Safely extract body JSON map (keys to String, values unresolved)
      final bodyJsonRaw = <String, dynamic>{};
      if (payload['bodyJson'] is Map) {
        (payload['bodyJson'] as Map).forEach((key, value) {
          bodyJsonRaw[key.toString()] = value;
        });
      }
      final resolvedJson = _resolveJsonLike(bodyJsonRaw, resolveValue);
      requestBody = jsonEncode(resolvedJson);
      headers.putIfAbsent('Content-Type', () => 'application/json');
    }
  }

  final response = await HttpService(client: httpClient, onLog: onLog).request(
    method: method,
    url: resolvedUrl,
    headers: headers,
    body: requestBody?.toString(),
    budget: executionBudget,
  );
  final responseBody = response.body;
  final status = response.status;

  final extractionResult = responseBody;
  results[resultKey] = extractionResult;
  variables['http.status'] = '$status';
  variables['http.body'] = responseBody;
  variables['action.$resultKey'] = extractionResult;
  variables['action.$resultKey.status'] = '$status';
  variables['action.$resultKey.body'] = responseBody;
  variables[resultKey] = extractionResult;
  variables['$resultKey.status'] = '$status';
  variables['$resultKey.body'] = responseBody;

  final saveBodyTo = resolveValue(
    (payload['saveBodyToGlobalVar'] ?? '').toString(),
  ).trim();
  if (saveBodyTo.isNotEmpty) {
    executionBudget?.check();
    await setGlobalVariable(saveBodyTo, responseBody);
  }

  final saveStatusTo = resolveValue(
    (payload['saveStatusToGlobalVar'] ?? '').toString(),
  ).trim();
  if (saveStatusTo.isNotEmpty) {
    executionBudget?.check();
    await setGlobalVariable(saveStatusTo, '$status');
  }

  final extractPath = resolveValue(
    (payload['extractJsonPath'] ?? '').toString(),
  ).trim();
  if (extractPath.isNotEmpty) {
    dynamic decoded;
    try {
      decoded = jsonDecode(responseBody);
    } catch (_) {
      decoded = null;
    }

    if (decoded != null) {
      final extracted = extractHttpJsonPath(decoded, extractPath);
      onLog?.call(
        'HTTP extractJsonPath: $extractPath → ${extracted != null ? "found (${extracted.toString().length} chars)" : "null"}',
      );
      if (extracted != null) {
        final extractedAsString = extracted is String
            ? extracted
            : (extracted is num || extracted is bool)
            ? extracted.toString()
            : jsonEncode(extracted);
        // Update the primary result to the extracted value so
        // ((action.<key>)) resolves to the useful text, not the raw body.
        results[resultKey] = extractedAsString;
        variables['action.$resultKey'] = extractedAsString;
        variables[resultKey] = extractedAsString;
        variables['http.jsonPath'] = extractedAsString;
        variables['action.$resultKey.jsonPath'] = extractedAsString;
        variables['$resultKey.jsonPath'] = extractedAsString;
        onLog?.call(
          'HTTP jsonPath stored as action.$resultKey.jsonPath = $extractedAsString',
        );
        // Note: saveJsonPathToGlobalVar removed — use {{resultKey.jsonPath}}
      }
    }
  }

  return true;
}
