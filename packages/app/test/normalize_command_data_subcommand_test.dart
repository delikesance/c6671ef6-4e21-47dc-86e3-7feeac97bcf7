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
  group('normalizeCommandData – subcommandWorkflows preservation', () {
    test('preserves subcommandWorkflows through normalization', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': 'global', 'type': 'normal'},
          'subcommandWorkflows': {
            'config/status': _routePayload('STATUS CHANNEL'),
            'config/logchannel': _routePayload('LOG CHANNEL'),
          },
          'activeSubcommandRoute': 'config/status',
        },
      );

      final result = normalizeCommandData(command);
      final data = result['data'] as Map<String, dynamic>;

      expect(data.containsKey('subcommandWorkflows'), isTrue);
      final workflows = data['subcommandWorkflows'] as Map<String, dynamic>;
      expect(
        workflows.keys,
        containsAll(['config/status', 'config/logchannel']),
      );
    });

    test('preserves subcommandWorkflows through JSON round-trip', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': 'global', 'type': 'normal'},
          'subcommandWorkflows': {
            'config/status': _routePayload('STATUS CHANNEL'),
            'config/logchannel': _routePayload('LOG CHANNEL !'),
          },
          'activeSubcommandRoute': 'config/logchannel',
        },
      );

      final reloaded = roundTrip(command);
      final data = reloaded['data'] as Map<String, dynamic>;
      final workflows = data['subcommandWorkflows'] as Map<String, dynamic>;

      expect(workflows.length, 2);
      final statusPayload = workflows['config/status'] as Map<String, dynamic>;
      final logPayload = workflows['config/logchannel'] as Map<String, dynamic>;

      expect((statusPayload['response'] as Map)['text'], 'STATUS CHANNEL');
      expect((logPayload['response'] as Map)['text'], 'LOG CHANNEL !');
    });

    test('per-route payloads are independent – no cross-contamination', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': 'fallback', 'type': 'normal'},
          'subcommandWorkflows': {
            'route/a': _routePayload('AAA'),
            'route/b': _routePayload('BBB'),
          },
          'activeSubcommandRoute': 'route/a',
        },
      );

      final result = normalizeCommandData(command);
      final workflows =
          result['data']['subcommandWorkflows'] as Map<String, dynamic>;

      // Mutate route/a payload in the result
      (workflows['route/a'] as Map)['response']['text'] = 'MUTATED';

      // route/b must be unaffected
      expect((workflows['route/b'] as Map)['response']['text'], 'BBB');
    });
  });

  group('normalizeCommandData – activeSubcommandRoute', () {
    test('keeps activeSubcommandRoute when it exists in workflows', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {
            'config/status': _routePayload('S'),
            'config/logchannel': _routePayload('L'),
          },
          'activeSubcommandRoute': 'config/logchannel',
        },
      );

      final result = normalizeCommandData(command);
      expect(result['data']['activeSubcommandRoute'], 'config/logchannel');
    });

    test('falls back to first route when activeSubcommandRoute is invalid', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {
            'config/status': _routePayload('S'),
            'config/logchannel': _routePayload('L'),
          },
          'activeSubcommandRoute': 'config/nonexistent',
        },
      );

      final result = normalizeCommandData(command);
      // Should fall back to first key
      expect(result['data']['activeSubcommandRoute'], 'config/status');
    });

    test('falls back to first route when activeSubcommandRoute is missing', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {'help': _routePayload('HELP')},
        },
      );

      final result = normalizeCommandData(command);
      expect(result['data']['activeSubcommandRoute'], 'help');
    });

    test('empty string when no subcommandWorkflows exist', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
        },
      );

      final result = normalizeCommandData(command);
      expect(result['data'].containsKey('activeSubcommandRoute'), isFalse);
    });
  });

  group('normalizeCommandData – edge cases for subcommandWorkflows', () {
    test('filters out empty route keys', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {
            '': _routePayload('EMPTY'),
            '  ': _routePayload('WHITESPACE'),
            'valid/route': _routePayload('OK'),
          },
          'activeSubcommandRoute': 'valid/route',
        },
      );

      final result = normalizeCommandData(command);
      final workflows =
          result['data']['subcommandWorkflows'] as Map<String, dynamic>;
      expect(workflows.length, 1);
      expect(workflows.containsKey('valid/route'), isTrue);
    });

    test('skips non-Map payloads in subcommandWorkflows', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {
            'good': _routePayload('OK'),
            'bad_string': 'not a map',
            'bad_number': 42,
            'bad_null': null,
          },
          'activeSubcommandRoute': 'good',
        },
      );

      final result = normalizeCommandData(command);
      final workflows =
          result['data']['subcommandWorkflows'] as Map<String, dynamic>;
      expect(workflows.length, 1);
      expect(workflows.containsKey('good'), isTrue);
    });

    test('deep cloning – mutation of original does not affect normalized', () {
      final originalPayload = _routePayload('ORIGINAL');
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {'route': originalPayload},
          'activeSubcommandRoute': 'route',
        },
      );

      final result = normalizeCommandData(command);

      // Mutate original input
      (originalPayload['response'] as Map)['text'] = 'MUTATED';

      // Normalized result must be unaffected
      final workflows =
          result['data']['subcommandWorkflows'] as Map<String, dynamic>;
      final routePayload = workflows['route'] as Map<String, dynamic>;
      expect((routePayload['response'] as Map)['text'], 'ORIGINAL');
    });

    test('no subcommandWorkflows key when map is empty after filtering', () {
      final command = _makeCommand(
        data: {
          'response': {'mode': 'text', 'text': '', 'type': 'normal'},
          'subcommandWorkflows': {'': _routePayload('EMPTY')},
        },
      );

      final result = normalizeCommandData(command);
      expect(result['data'].containsKey('subcommandWorkflows'), isFalse);
      expect(result['data'].containsKey('activeSubcommandRoute'), isFalse);
    });
  });
}
