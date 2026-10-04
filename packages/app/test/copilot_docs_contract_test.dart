import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Contract with the documentation MCP served by vitrine (/api/mcp) and relayed
// by the manager (internal/services/ai_documentation.go): the Copilot docs_*
// tools declared here must be handled by CopilotMcp and stay identical to the
// manager's copy.
void main() {
  final tools =
      (jsonDecode(File('assets/copilot/tools.json').readAsStringSync()) as List)
          .cast<Map<String, dynamic>>();
  final docs = tools.where((t) => (t['name'] as String).startsWith('docs_'));

  test('every docs_* tool is read-only and handled by CopilotMcp', () {
    final source = File(
      'lib/features/copilot/logic/copilot_mcp.dart',
    ).readAsStringSync();
    expect(
      docs.map((t) => t['name']),
      containsAll([
        'docs_search',
        'docs_get',
        'docs_manifest',
        'docs_actions',
        'docs_validate_actions',
      ]),
    );
    for (final tool in docs) {
      expect(
        tool['mutating'],
        false,
        reason: '${tool['name']} must not mutate',
      );
      expect(source, contains("case '${tool['name']}':"));
    }
  });

  test('tools.json matches the manager copilot_tools.json', () {
    final manager = File(
      '../../../manager/internal/services/copilot_tools.json',
    );
    if (!manager.existsSync()) return;
    Map<String, dynamic> byName(List<dynamic> list) => {
      for (final t in list) (t as Map)['name'] as String: t,
    };
    expect(
      byName(jsonDecode(manager.readAsStringSync()) as List),
      byName(tools),
    );
  });
}
