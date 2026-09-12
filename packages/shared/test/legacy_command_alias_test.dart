import 'package:bot_creator_shared/engine/event_dispatcher.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';
import 'package:test/test.dart';

/// Builds a legacy command with optional aliases and a custom data payload.
Map<String, dynamic> _legacyCommand({
  String name = 'ping',
  List<dynamic>? aliases,
  String prefixOverride = '',
  String type = 'chatInput',
}) {
  return <String, dynamic>{
    'name': name,
    'type': type,
    'data': <String, dynamic>{
      'legacyModeEnabled': true,
      'legacyPrefixOverride': prefixOverride,
      'legacyAliases': ?aliases,
    },
  };
}

void main() {
  group('normalizeLegacyCommandAliases', () {
    test('lowercases, trims, strips a leading ! and deduplicates', () {
      expect(
        normalizeLegacyCommandAliases([' P ', 'p', '!PING', 'ping', 'x']),
        <String>['p', 'ping', 'x'],
      );
    });

    test('drops empty values, lone ! and values with inner whitespace', () {
      expect(
        normalizeLegacyCommandAliases(['', '   ', '!', 'p p', 'a\tb', 'ok']),
        <String>['ok'],
      );
    });

    test('ignores non-string entries and keeps input order', () {
      expect(
        normalizeLegacyCommandAliases(<dynamic>[1, null, true, 'b', 'a']),
        <String>['b', 'a'],
      );
    });

    test('tolerates non-list input', () {
      expect(normalizeLegacyCommandAliases(null), isEmpty);
      expect(normalizeLegacyCommandAliases('p'), isEmpty);
      expect(normalizeLegacyCommandAliases(42), isEmpty);
      expect(normalizeLegacyCommandAliases(<String, dynamic>{}), isEmpty);
    });

    test(r'keeps a {$t} modifier and deduplicates on the cleaned trigger', () {
      expect(
        normalizeLegacyCommandAliases([r'p{$t:5s}', 'p', r'purge {$t:5s}']),
        <String>[r'p{$t:5s}', r'purge {$t:5s}'],
      );
    });

    test('caps the number of aliases at 10', () {
      final raw = <String>[for (var i = 0; i < 12; i++) 'alias$i'];
      final result = normalizeLegacyCommandAliases(raw);
      expect(result, hasLength(10));
      expect(result.first, 'alias0');
      expect(result.last, 'alias9');
    });

    test('caps alias length at 32 characters', () {
      final long = 'x' * 40;
      final result = normalizeLegacyCommandAliases([long]);
      expect(result, hasLength(1));
      expect(result.single.length, 32);
      expect(result.single, 'x' * 32);
    });

    test('honors custom maxAliases and maxLength', () {
      expect(normalizeLegacyCommandAliases(['a', 'b', 'c'], maxAliases: 2), [
        'a',
        'b',
      ]);
      expect(normalizeLegacyCommandAliases(['abcdef'], maxLength: 3), <String>[
        'abc',
      ]);
      expect(normalizeLegacyCommandAliases(['a'], maxAliases: 0), isEmpty);
    });
  });

  group('legacyCommandTriggerNames', () {
    test('returns the cleaned name first, then the cleaned aliases', () {
      final command = _legacyCommand(
        name: r'Ping {$t:5s}',
        aliases: [' P ', '!p', '', 'x y'],
      );
      expect(legacyCommandTriggerNames(command), <String>['ping', 'p']);
    });

    test('uses the prefix override as effective name when non-empty', () {
      final command = _legacyCommand(
        name: 'internal_name',
        prefixOverride: 'Clear',
        aliases: ['c'],
      );
      expect(legacyCommandTriggerNames(command), <String>['clear', 'c']);
    });

    test('falls back to the root name when the prefix override is blank', () {
      final command = _legacyCommand(
        name: 'Kick',
        prefixOverride: '   ',
        aliases: ['k'],
      );
      expect(legacyCommandTriggerNames(command), <String>['kick', 'k']);
    });

    test('deduplicates an alias that repeats the command name', () {
      final command = _legacyCommand(name: 'ping', aliases: ['PING', 'p']);
      expect(legacyCommandTriggerNames(command), <String>['ping', 'p']);
    });

    test('returns an empty list when legacy mode is disabled', () {
      final command = _legacyCommand(aliases: ['p']);
      (command['data'] as Map<String, dynamic>)['legacyModeEnabled'] = false;
      expect(legacyCommandTriggerNames(command), isEmpty);
    });

    test('returns an empty list when there is no data block', () {
      expect(
        legacyCommandTriggerNames(<String, dynamic>{'name': 'ping'}),
        isEmpty,
      );
    });
  });

  group('legacyCommandMatchesTrigger', () {
    test('matches the command name case-insensitively', () {
      final command = _legacyCommand(name: 'Ping');
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'ping'),
        isTrue,
      );
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'PING'),
        isTrue,
      );
    });

    test('matches an alias case-insensitively', () {
      final command = _legacyCommand(aliases: ['p']);
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'P'),
        isTrue,
      );
    });

    test(r'ignores the {$t} modifier on both sides', () {
      final command = _legacyCommand(name: r'clear {$t:5s}', aliases: ['p']);
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'clear'),
        isTrue,
      );
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: r'clear{$t}'),
        isTrue,
      );
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: r'p{$t:2s}'),
        isTrue,
      );
    });

    test('does not match a command without aliases on another word', () {
      final command = _legacyCommand();
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'pong'),
        isFalse,
      );
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: ''),
        isFalse,
      );
    });

    test('does not match when legacy mode is disabled', () {
      final command = _legacyCommand(aliases: ['p']);
      (command['data'] as Map<String, dynamic>)['legacyModeEnabled'] = false;
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'ping'),
        isFalse,
      );
      expect(
        legacyCommandMatchesTrigger(command: command, typedName: 'p'),
        isFalse,
      );
    });

    test('collision between two commands: the first one wins', () {
      final commands = <Map<String, dynamic>>[
        _legacyCommand(name: 'other', aliases: ['p']),
        _legacyCommand(name: 'ping', aliases: ['p']),
      ];
      // Mirrors the dispatcher lookup (firstWhere over store order).
      final winner = commands.firstWhere(
        (command) =>
            legacyCommandMatchesTrigger(command: command, typedName: 'p'),
        orElse: () => <String, dynamic>{},
      );
      expect(winner['name'], 'other');
    });
  });

  group('legacyCommandTimedTriggerDelay', () {
    test('extracts the delay from the name', () {
      final command = _legacyCommand(name: r'clear {$t:5s}');
      expect(
        legacyCommandTimedTriggerDelay(command: command, typedName: 'clear'),
        const Duration(seconds: 5),
      );
    });

    test('keeps working when the command is triggered through an alias', () {
      final command = _legacyCommand(
        name: r'clear {$t:5s}',
        aliases: ['purge'],
      );
      expect(
        legacyCommandTimedTriggerDelay(command: command, typedName: 'purge'),
        const Duration(seconds: 5),
      );
    });

    test(r'prefers the alias own {$t} modifier when it has one', () {
      final command = _legacyCommand(
        name: r'clear {$t:5s}',
        aliases: [r'purge{$t:10s}'],
      );
      expect(
        legacyCommandTimedTriggerDelay(command: command, typedName: 'purge'),
        const Duration(seconds: 10),
      );
    });

    test(r'returns zero for an immediate {$t} deletion modifier', () {
      final command = _legacyCommand(name: r'clear {$t}', aliases: ['c']);
      expect(
        legacyCommandTimedTriggerDelay(command: command, typedName: 'c'),
        Duration.zero,
      );
    });

    test('returns null when nothing matches or no modifier is configured', () {
      final command = _legacyCommand(name: 'clear', aliases: ['c']);
      expect(
        legacyCommandTimedTriggerDelay(command: command, typedName: 'clear'),
        isNull,
      );
      expect(
        legacyCommandTimedTriggerDelay(command: command, typedName: 'nope'),
        isNull,
      );
    });
  });

  group('EventDispatcher static entry points stay compatible', () {
    test('cleanCommandTriggerName delegates to the shared helper', () {
      expect(
        EventDispatcher.cleanCommandTriggerName(r'purge {$t:5s}'),
        cleanLegacyCommandTriggerName(r'purge {$t:5s}'),
      );
      expect(EventDispatcher.cleanCommandTriggerName('Ban'), 'ban');
    });

    test('extractTimedTriggerDelay delegates to the shared helper', () {
      expect(
        EventDispatcher.extractTimedTriggerDelay(r'clear {$t:2m}'),
        extractLegacyCommandTimedTriggerDelay(r'clear {$t:2m}'),
      );
      expect(EventDispatcher.extractTimedTriggerDelay('clear'), isNull);
    });
  });
}
