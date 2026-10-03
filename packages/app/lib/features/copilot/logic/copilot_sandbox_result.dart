import 'dart:convert';

/// Assertions are evaluated before this presentation-only reduction.
Map<String, dynamic> copilotSandboxResult(
  Map<String, dynamic> result, {
  bool detailed = false,
}) {
  final selected = <String, dynamic>{
    for (final key in [
      'success',
      'contract_passed',
      'execution',
      'discord_verified',
      'bot_id',
      'configuration_source',
      'bdfdUserVariableSemantics',
      'error',
      'contract_checks',
      'responses',
      'diagnostics',
      'effects',
      'storage_after',
      'storage_before',
      'stopped',
      'unused_http_fixtures',
      'images',
      'trace_total',
      'trace_truncated',
      'trace',
      if (detailed) ...['results', 'logs', 'variables', 'entity_requests'],
    ])
      if (result.containsKey(key)) key: result[key],
  };
  // The Manager accepts at most 24 KB including the escaped MCP text envelope.
  for (var budget = detailed ? 12000 : 6000; budget >= 750; budget ~/= 2) {
    final limiter = _ResultLimiter(budget);
    final output = <String, dynamic>{};
    for (final entry in selected.entries) {
      if (limiter.remaining <= 0) {
        limiter.omit('/${entry.key}');
      } else {
        output[entry.key] = limiter.reduce(entry.value, '/${entry.key}');
      }
    }
    output['result_view'] = detailed ? 'detailed' : 'compact';
    if (!detailed) {
      output['omitted_details'] = [
        'results',
        'logs',
        'variables',
        'entity_requests',
      ];
    }
    if (limiter.omissions.isNotEmpty) {
      output['output_truncated'] = true;
      output['truncated_paths'] = limiter.omissions;
    }
    final envelope = {
      'content': [
        {'type': 'text', 'text': jsonEncode(output)},
      ],
      'isError':
          result['success'] != true || result['contract_passed'] == false,
    };
    if (utf8.encode(jsonEncode(envelope)).length <= 22000) return output;
  }
  return {
    'success': result['success'],
    'contract_passed': result['contract_passed'],
    'execution': 'sandbox',
    'discord_verified': false,
    'output_truncated': true,
    'truncated_paths': ['/'],
  };
}

class _ResultLimiter {
  _ResultLimiter(this.remaining);
  int remaining;
  final omissions = <String>[];

  void omit(String path) {
    if (omissions.length < 20) omissions.add(path);
  }

  dynamic reduce(dynamic value, String path, [int depth = 0]) {
    if (depth >= 12 || remaining <= 0) {
      omit(path);
      return null;
    }
    if (value is Map) {
      final output = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final keyCost = utf8.encode(jsonEncode(key)).length + 3;
        if (output.length >= 24 || remaining <= keyCost) {
          omit(path);
          break;
        }
        remaining -= keyCost;
        output[key] = reduce(
          entry.value,
          '$path/${key.replaceAll('~', '~0').replaceAll('/', '~1')}',
          depth + 1,
        );
      }
      return output;
    }
    if (value is List) {
      final output = <dynamic>[];
      for (var i = 0; i < value.length; i++) {
        if (i >= 20 || remaining <= 0) {
          omit(path);
          break;
        }
        remaining--;
        output.add(reduce(value[i], '$path/$i', depth + 1));
      }
      return output;
    }
    if (value is String &&
        (value.length > 2000 ||
            utf8.encode(jsonEncode(value)).length > remaining)) {
      omit(path);
      var end = value.length.clamp(0, 2000);
      while (end > 0 &&
          utf8.encode(jsonEncode(value.substring(0, end))).length > remaining) {
        end ~/= 2;
      }
      value = value.substring(0, end);
    }
    remaining -= utf8.encode(jsonEncode(value)).length;
    return value;
  }
}
