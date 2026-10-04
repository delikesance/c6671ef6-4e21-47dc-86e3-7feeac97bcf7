import 'package:bot_creator_shared/engine/bdfd/context_guard_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:test/test.dart';

BdfdRuntime _runtime({Map<String, BdfdNativeFunction> extra = const {}}) =>
    BdfdRuntime(functions: {...bdfdContextGuardFunctions(), ...extra});

const _variables = {
  'author.id': '803569638084313098',
  'user.id': '111',
  'author.username': 'RainbowKey',
  'user.username': 'OtherUser',
  'channel.id': '1050809741137412177',
  'guild.id': '1009018669982031912',
};

void main() {
  final cases = [
    ('onlyForIDs', '803569638084313098', true),
    ('onlyForUsers', 'RainbowKey', true),
    ('onlyForChannels', '1050809741137412177', true),
    ('onlyForServers', '1009018669982031912', true),
    ('blackListIDs', '803569638084313098', false),
    ('blackListUsers', 'RainbowKey', false),
    ('ignoreChannels', '1050809741137412177', false),
    ('blackListServers', '1009018669982031912', false),
  ];
  for (final (name, subject, whitelist) in cases) {
    test('$name checks all list entries and stops on rejection', () async {
      final runtime = _runtime();
      final allowed = whitelist ? subject : 'other';
      final rejected = whitelist ? 'other' : subject;
      final success = BdfdContext(variables: {..._variables});
      expect(
        await runtime.execute(
          '\$$name[another;$allowed;Denied]OK',
          context: success,
        ),
        'OK',
      );
      expect(success.stopped, false);
      final failure = BdfdContext(variables: {..._variables});
      expect(
        await runtime.execute(
          '\$$name[another;$rejected;Denied]Never',
          context: failure,
        ),
        'Denied',
      );
      expect(failure.stopped, true);
    });
    test(
      '$name leaves success error text lazy and evaluates it once on failure',
      () async {
        var errors = 0;
        final runtime = _runtime(
          extra: {
            'guardErrorProbe': BdfdNativeFunction(
              minArguments: 0,
              maxArguments: 0,
              handler: (_) {
                errors++;
                return r'$unexecuted[argument]';
              },
            ),
          },
        );
        final allowed = whitelist ? subject : 'other';
        final rejected = whitelist ? 'other' : subject;
        expect(
          await runtime.execute(
            '\$$name[$allowed;\$guardErrorProbe]OK',
            context: BdfdContext(variables: {..._variables}),
          ),
          'OK',
        );
        expect(errors, 0);
        expect(
          await runtime.execute(
            '\$$name[$rejected;\$guardErrorProbe]Never',
            context: BdfdContext(variables: {..._variables}),
          ),
          r'$unexecuted[argument]',
        );
        expect(errors, 1);
      },
    );
    test('$name requires a list slot and the error slot at preflight', () {
      final runtime = _runtime();
      for (final source in ['\$$name', '\$$name[]', '\$$name[value]']) {
        expect(() => runtime.prepare(source), throwsA(isA<BdfdNativeError>()));
      }
      expect(() => runtime.prepare('\$$name[;]'), returnsNormally);
    });
  }

  test(
    'onlyIfMessageContains requires every word as in official example',
    () async {
      final runtime = _runtime();
      for (final message in ['Bye', 'Hello', 'Hi']) {
        final context = BdfdContext();
        expect(
          await runtime.execute(
            '\$onlyIfMessageContains[$message;Hello;Hi;Denied]Hello world!',
            context: context,
          ),
          'Denied',
        );
        expect(context.stopped, true);
      }
      for (final message in ['Hello Hi', 'Hello MineBartekSA. Hi!']) {
        expect(
          await runtime.execute(
            '\$onlyIfMessageContains[$message;Hello;Hi;Denied]Hello world!',
          ),
          'Hello world!',
        );
      }
    },
  );
  test('message guard accepts substring, phrase and empty word', () async {
    expect(
      await _runtime().execute(
        r'$onlyIfMessageContains[Hello world!;ello;Hello world;;Denied]OK',
      ),
      'OK',
    );
    expect(
      await _runtime().execute(r'$onlyIfMessageContains[;;Denied]OK'),
      'OK',
    );
  });
  test('message guard ignores case while preserving whitespace', () async {
    expect(
      await _runtime().execute(r'$onlyIfMessageContains[Hello;hello;Denied]OK'),
      'OK',
    );
    expect(
      await _runtime().execute(
        r'$onlyIfMessageContains[Hello; Hello;Denied]Never',
      ),
      'Denied',
    );
  });
  test('message guard rejects incomplete signatures before effects', () async {
    var effects = 0;
    final runtime = _runtime(
      extra: {
        'guardProbe': BdfdNativeFunction(
          minArguments: 0,
          maxArguments: 0,
          handler: (_) {
            effects++;
            return '';
          },
        ),
      },
    );
    for (final source in [
      r'$onlyIfMessageContains',
      r'$onlyIfMessageContains[]',
      r'$onlyIfMessageContains[message;word]',
    ]) {
      await expectLater(
        runtime.execute('\$guardProbe$source'),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(effects, 0);
  });
  test(
    'message and all candidates are evaluated once; passing error stays lazy',
    () async {
      final reads = <String>[];
      final runtime = _runtime(
        extra: {
          'guardProbe': BdfdNativeFunction(
            minArguments: 1,
            maxArguments: 1,
            handler: (call) async {
              final text = await call.argument(0);
              reads.add(text);
              return text;
            },
          ),
        },
      );
      expect(
        await runtime.execute(
          r'$onlyIfMessageContains[$guardProbe[Hello Hi];$guardProbe[Hello];$guardProbe[Hi];$guardProbe[Error]]OK',
        ),
        'OK',
      );
      expect(reads, ['Hello Hi', 'Hello', 'Hi']);
      reads.clear();
      expect(
        await runtime.execute(
          r'$onlyIfMessageContains[$guardProbe[Bye];$guardProbe[Hello];$guardProbe[Hi];$guardProbe[Error]]Never',
        ),
        'Error',
      );
      expect(reads, ['Bye', 'Hello', 'Hi', 'Error']);
    },
  );
  test(
    'list candidates all evaluated, including entries after a match',
    () async {
      var reads = 0;
      final runtime = _runtime(
        extra: {
          'guardProbe': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) {
              reads++;
              return 'another';
            },
          ),
        },
      );
      expect(
        await runtime.execute(
          r'$onlyForIDs[803569638084313098;$guardProbe;Denied]OK',
          context: BdfdContext(variables: {..._variables}),
        ),
        'OK',
      );
      expect(reads, 1);
    },
  );
  test(
    'author fallback uses user fields only when author fields absent',
    () async {
      final context = BdfdContext(
        variables: {
          'user.id': '803569638084313098',
          'user.username': 'RainbowKey',
        },
      );
      expect(
        await _runtime().execute(
          r'$onlyForIDs[803569638084313098;Denied]$onlyForUsers[RainbowKey;Denied]OK',
          context: context,
        ),
        'OK',
      );
      expect(
        await _runtime().execute(
          r'$onlyForIDs[803569638084313098;Denied]Never',
          context: BdfdContext(
            variables: {'author.id': '', 'user.id': '803569638084313098'},
          ),
        ),
        'Denied',
      );
    },
  );
  test('empty list slots do not authorize absent identities', () async {
    for (final (name, _, whitelist) in cases) {
      final context = BdfdContext();
      expect(
        await _runtime().execute('\$$name[;;Denied]OK', context: context),
        whitelist ? 'Denied' : 'OK',
      );
    }
  });
  test('IDs trim spaces; usernames ignore case but preserve spaces', () async {
    final runtime = _runtime();
    expect(
      await runtime.execute(
        r'$onlyForIDs[ 803569638084313098 ;Denied]OK',
        context: BdfdContext(variables: {..._variables}),
      ),
      'OK',
    );
    expect(
      await runtime.execute(
        r'$onlyForUsers[rainbowkey;Denied]OK',
        context: BdfdContext(variables: {..._variables}),
      ),
      'OK',
    );
    for (final value in [' RainbowKey ', 'another']) {
      expect(
        await runtime.execute(
          '\$onlyForUsers[$value;Denied]Never',
          context: BdfdContext(variables: {..._variables}),
        ),
        'Denied',
      );
    }
  });
  test(
    'channel guards use actual DM channel ID without requiring guild',
    () async {
      final context = BdfdContext(
        variables: {'channel.id': '123', 'guild.id': '', 'channel.type': 'dm'},
      );
      expect(
        await _runtime().execute(
          r'$onlyForChannels[123;Denied]OK',
          context: context,
        ),
        'OK',
      );
      expect(
        await _runtime().execute(
          r'$onlyForServers[;Denied]Never',
          context: context,
        ),
        'Denied',
      );
    },
  );
  test(
    'empty failure text stops silently and try does not catch stop',
    () async {
      final context = BdfdContext(variables: {..._variables});
      expect(
        await _runtime().execute(
          r'$try'
          '\n'
          r'$onlyForIDs[other;]Never'
          '\n'
          r'$catch'
          '\n'
          'Caught'
          '\n'
          r'$endtry'
          '\n'
          'After',
          context: context,
        ),
        '',
      );
      expect(context.stopped, true);
    },
  );
  test(
    'unknown function remains opaque including nested guard effects',
    () async {
      final context = BdfdContext(variables: {..._variables});
      const source = r'$futureGuard[$onlyForIDs[other;Denied]]OK';
      expect(await _runtime().execute(source, context: context), source);
      expect(context.stopped, false);
    },
  );
  test('known unsupported function still fails before guard execution', () {
    expect(
      () => _runtime().prepare(r'$onlyForIDs[803569638084313098;$botOwnerID]'),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test(
    'guards check the shared budget between dynamically evaluated entries',
    () async {
      final context = BdfdContext(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 20)),
      );
      final runtime = _runtime(
        extra: {
          'guardDelay': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) async {
              await Future<void>.delayed(const Duration(milliseconds: 40));
              return 'word';
            },
          ),
        },
      );
      await expectLater(
        runtime.execute(
          r'$onlyIfMessageContains[word;$guardDelay;word;Denied]Never',
          context: context,
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
    },
  );
}
