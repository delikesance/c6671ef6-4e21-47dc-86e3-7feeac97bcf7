import 'dart:convert';

import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper: simulate save-then-reload by JSON round-tripping.
Map<String, dynamic> roundTrip(Map<String, dynamic> input) {
  final normalized = normalizeCommandData(input);
  return Map<String, dynamic>.from(
    (jsonDecode(jsonEncode(normalized)) as Map).cast<String, dynamic>(),
  );
}

Map<String, dynamic> _makeCommand({
  Map<String, dynamic>? data,
  String type = 'chatInput',
}) {
  return {'name': 'ticket', 'type': type, 'data': data ?? {}};
}

Map<String, dynamic> _routePayload(String text) {
  return {
    'response': {
      'mode': 'text',
      'text': text,
      'type': 'normal',
      'embed': {'title': '', 'description': '', 'url': ''},
      'embeds': [],
    },
    'actions': [],
  };
}

void main() {
  group('normalizeCommandData – legacy data without subcommandWorkflows', () {
    test('normalizes legacy command without subcommandWorkflows', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': 'Hello World', 'type': 'normal'},
          'actions': [
            {'type': 'reply', 'value': 'Hi'},
          ],
        },
      );

      final result = normalizeCommandData(command);
      final data = result['data'] as Map<String, dynamic>;

      expect(data['response']['text'], 'Hello World');
      expect(data.containsKey('subcommandWorkflows'), isFalse);
      expect((data['actions'] as List).length, 1);
    });

    test('normalizes legacy string response', () {
      final command = _makeCommand(data: {'response': 'plain text response'});

      final result = normalizeCommandData(command);
      expect(result['data']['response']['text'], 'plain text response');
      expect(result['data']['response']['mode'], 'message');
    });

    test('normalizes command with no data at all', () {
      final command = {'name': 'test'};

      final result = normalizeCommandData(command);
      expect(result['data'], isA<Map>());
      expect(result['data']['response']['text'], '');
      expect(result['type'], 'chatInput');
    });
  });

  group('normalizeCommandData – command types', () {
    test('recognizes user command type', () {
      final command = _makeCommand(data: {'commandType': 'user_command'});
      expect(normalizeCommandData(command)['type'], 'user');
    });

    test('recognizes message command type', () {
      final command = _makeCommand(data: {'commandType': 'messageCommand'});
      expect(normalizeCommandData(command)['type'], 'message');
    });

    test('defaults unknown type to chatInput', () {
      final command = _makeCommand(data: {'commandType': 'unknownType'});
      expect(normalizeCommandData(command)['type'], 'chatInput');
    });
  });

  group('normalizeCommandData – legacy command fields', () {
    test('preserves legacy command mode fields', () {
      final command = _makeCommand(
        data: {
          'legacyModeEnabled': true,
          'legacyPrefixOverride': '((guild.bc_prefix | !))',
          'legacyResponseTarget': 'channelSend',
        },
      );

      final result = normalizeCommandData(command);
      final data = Map<String, dynamic>.from(result['data'] as Map);

      expect(data['legacyModeEnabled'], isTrue);
      expect(data['legacyPrefixOverride'], '((guild.bc_prefix | !))');
      expect(data['legacyResponseTarget'], 'channelSend');
    });

    test('defaults legacy response target to reply', () {
      final command = _makeCommand(data: {'legacyModeEnabled': true});

      final result = normalizeCommandData(command);
      final data = Map<String, dynamic>.from(result['data'] as Map);
      expect(data['legacyResponseTarget'], 'reply');
    });
  });

  group('normalizeCommandData – execution mode fields', () {
    test('defaults execution mode to workflow', () {
      final command = _makeCommand();

      final result = normalizeCommandData(command);
      final data = Map<String, dynamic>.from(result['data'] as Map);

      expect(data['executionMode'], 'workflow');
      expect(data['bdfdScriptContent'], '');
    });

    test('preserves bdfd script execution payload', () {
      final command = _makeCommand(
        data: {
          'executionMode': 'bdfd_script',
          'bdfdScriptContent': r'$nomention\n$description[Hello]',
        },
      );

      final result = normalizeCommandData(command);
      final data = Map<String, dynamic>.from(result['data'] as Map);

      expect(data['executionMode'], 'bdfd_script');
      expect(data['bdfdScriptContent'], r'$nomention\n$description[Hello]');
    });
  });

  group('normalizeCommandData – idempotency', () {
    test('double normalization produces identical output', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': 'stable', 'type': 'normal'},
          'subcommandWorkflows': {'config/status': _routePayload('STATUS')},
          'activeSubcommandRoute': 'config/status',
          'actions': [
            {'type': 'reply', 'value': 'done'},
          ],
        },
      );

      final first = normalizeCommandData(command);
      final second = normalizeCommandData(
        Map<String, dynamic>.from(
          (jsonDecode(jsonEncode(first)) as Map).cast<String, dynamic>(),
        ),
      );

      expect(jsonEncode(first), jsonEncode(second));
    });
  });

  group('normalizeCommandData – legacy command preservation', () {
    test('preserves legacy flags through normalization', () {
      final command = _makeCommand(
        data: {
          'legacyModeEnabled': true,
          'legacyLocalOnly': true,
          'legacyPrefixOverride': '!!',
          'legacyResponseTarget': 'channelSend',
          'response': {
            'mode': 'text',
            'text': 'Legacy response',
            'type': 'normal',
          },
          'actions': [
            {
              'type': 'reply',
              'payload': {'content': 'Hi'},
            },
          ],
        },
      );

      final result = normalizeCommandData(command);
      final data = result['data'] as Map<String, dynamic>;
      expect(data['legacyModeEnabled'], isTrue);
      expect(data['legacyLocalOnly'], isTrue);
      expect(data['legacyPrefixOverride'], '!!');
      expect(data['legacyResponseTarget'], 'channelSend');
      expect(data['response']['text'], 'Legacy response');
      expect((data['actions'] as List).length, 1);
    });

    test('preserves legacy flags through JSON round-trip', () {
      final command = _makeCommand(
        data: {
          'legacyModeEnabled': true,
          'legacyLocalOnly': true,
          'legacyPrefixOverride': '?',
          'legacyResponseTarget': 'reply',
          'response': {
            'mode': 'embed',
            'text': '',
            'type': 'normal',
            'embeds': [
              {'title': 'Legacy embed', 'description': 'Desc'},
            ],
          },
        },
      );

      final reloaded = roundTrip(command);
      final data = reloaded['data'] as Map<String, dynamic>;
      expect(data['legacyModeEnabled'], isTrue);
      expect(data['legacyLocalOnly'], isTrue);
      final embeds = data['response']['embeds'] as List;
      expect(embeds.length, 1);
      expect(embeds[0]['title'], 'Legacy embed');
    });

    test('null description does not corrupt existing description', () {
      final command = <String, dynamic>{
        'name': 'test',
        'description': 'My description',
        'type': 'chatInput',
        'data': {
          'response': {'mode': 'text', 'text': 'Hello', 'type': 'normal'},
        },
      };

      // Simulate what sync merge does with null description
      final merged = <String, dynamic>{
        ...normalizeCommandData(command),
        'id': '123',
        'name': 'test',
        // description intentionally omitted (as if null was filtered)
      };

      final result = normalizeCommandData(merged);
      expect(result['data']['response']['text'], 'Hello');
      // description should fall back to whatever was in the spread
      expect(result['description'], 'My description');
    });

    test('auto-healing wraps root fields when data is missing but actions or response are present', () {
      final corrupted = <String, dynamic>{
        'legacyPrefixOverride': 'healed_name',
        'legacyModeEnabled': true,
        'actions': [
          {'type': 'respondWithMessage', 'payload': {'content': 'Hello'}}
        ],
        'response': {
          'mode': 'message',
          'text': 'Healed text',
        }
      };

      final healed = normalizeCommandData(corrupted);

      expect(healed['name'], 'healed_name');
      expect(healed['data'], isNotNull);
      final data = healed['data'] as Map<String, dynamic>;
      expect(data['legacyPrefixOverride'], 'healed_name');
      expect(data['legacyModeEnabled'], isTrue);
      expect(data['actions'], isNotEmpty);
      expect(data['actions'][0]['type'], 'respondWithMessage');
    });
  });
}
