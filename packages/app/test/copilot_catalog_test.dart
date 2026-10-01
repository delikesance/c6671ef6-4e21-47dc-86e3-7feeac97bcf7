import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/features/copilot/logic/copilot_catalog.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tools =
      (jsonDecode(File('assets/copilot/tools.json').readAsStringSync()) as List)
          .map((t) => Map<String, dynamic>.from(t as Map))
          .toList();
  final create = tools.singleWhere((t) => t['name'] == 'local_create_command');
  Map<String, dynamic> copy(Map source) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);
  test('scoped defaults remain available against an older server', () {
    final variable = tools.singleWhere(
      (t) => t['name'] == 'local_set_variable',
    );
    final old = copy(variable);
    (old['inputSchema']['properties']['scope']['enum'] as List).remove(
      'guildMember',
    );
    expect(negotiateCopilotTools([variable], [old]), hasLength(1));
    expect(copilotToolCompatible(old, variable), false);
    final unknown = copy(variable);
    (unknown['inputSchema']['properties']['scope']['enum'] as List).add(
      'unknown',
    );
    expect(copilotToolCompatible(variable, unknown), false);
  });
  test(
    'older manager still exposes command creation without its newer optional options',
    () {
      final old = copy(create);
      (old['inputSchema']['properties'] as Map).remove('options');
      final negotiated = negotiateCopilotTools([create], [old]);
      expect(negotiated.single['name'], 'local_create_command');
      expect(
        negotiated.single['inputSchema']['properties'].containsKey('options'),
        false,
      );
      CopilotMcp.validateArguments(negotiated.single['inputSchema'], {
        'bot_id': '123',
        'name': 'ticket',
        'description': 'Open a ticket',
        'script': 'Hello',
      });
      expect(copilotToolCompatible(old, create), false);
    },
  );
  test(
    'incompatible types, required fields and approval flags stay rejected',
    () {
      final type = copy(create);
      type['inputSchema']['properties']['name']['type'] = 'integer';
      expect(copilotToolCompatible(create, type), false);
      final required = copy(create);
      (required['inputSchema']['required'] as List).remove('name');
      expect(copilotToolCompatible(create, required), false);
      expect(
        copilotToolCompatible(create, {...create, 'mutating': false}),
        false,
      );
      expect(negotiateCopilotTools([create], []), isEmpty);
    },
  );
  test('tools remain compatible when only descriptions differ', () {
    final testTool = tools.singleWhere(
      (t) => t['name'] == 'local_test_command',
    );
    final remoteTool = copy(testTool);
    remoteTool['inputSchema']['properties']['scenario']['description'] =
        'Older server description without entities text';
    expect(copilotToolCompatible(testTool, remoteTool), true);
    final negotiated = negotiateCopilotTools([testTool], [remoteTool]);
    expect(negotiated, hasLength(1));
    expect(negotiated.single['name'], 'local_test_command');
  });
}
