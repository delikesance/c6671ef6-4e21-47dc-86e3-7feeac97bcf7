import 'dart:convert';

import 'package:bot_creator/features/copilot/logic/copilot_sandbox_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compact output retains outcomes and omits duplicate debug data', () {
    final result = copilotSandboxResult({
      'success': false,
      'error': 'Missing role fixture',
      'contract_passed': false,
      'contract_checks': [
        {'passed': false, 'actual': 'Wrong', 'expected': 'Right'},
      ],
      'responses': [],
      'storage_after': {
        'global': {'coins': '7'},
      },
      'results': {'duplicate': 'data'},
      'logs': ['debug'],
    });
    expect(result['success'], false);
    expect(result['error'], 'Missing role fixture');
    expect(result['contract_passed'], false);
    expect(result['contract_checks'][0]['actual'], 'Wrong');
    expect(result['storage_after']['global']['coins'], '7');
    expect(result.containsKey('results'), false);
    expect(result.containsKey('logs'), false);
    expect(result['omitted_details'], contains('results'));
  });

  test('escaped large output remains within Manager envelope limit', () {
    for (final detailed in [false, true]) {
      final original = {
        'success': true,
        'contract_passed': true,
        'responses': List.generate(
          100,
          (_) => {'content': '\u0000"\\' * 10000},
        ),
        'storage_after': {for (var i = 0; i < 100; i++) 'key$i': 'x' * 10000},
        'results': {'huge': 'x' * 100000},
      };
      final output = copilotSandboxResult(original, detailed: detailed);
      final envelope = {
        'content': [
          {'type': 'text', 'text': jsonEncode(output)},
        ],
        'isError': false,
      };
      expect(
        utf8.encode(jsonEncode(envelope)).length,
        lessThanOrEqualTo(22000),
      );
      expect(output['success'], true);
      expect(output['contract_passed'], true);
      expect(output['output_truncated'], true);
      expect(output['truncated_paths'], isNotEmpty);
      expect(original['responses'], hasLength(100));
    }
  });
}
