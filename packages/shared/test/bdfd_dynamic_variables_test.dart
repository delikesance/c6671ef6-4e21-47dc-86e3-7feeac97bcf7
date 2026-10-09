import 'package:bot_creator_shared/engine/bdfd/context_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/music_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/services/bot_music_service.dart';
import 'package:test/test.dart';

class _Music implements BotMusicService {
  final queries = <String>[];
  @override
  Future<void> perform(BotMusicRequest r, {required budget}) async =>
      queries.add(r.query);
}

Future<String> _run(String src, Map<String, String> vars, [_Music? m]) =>
    BdfdRuntime(
      functions: {...bdfdContextFunctions(), ...bdfdMusicFunctions(m)},
    ).executeProgram(
      BdfdProgram.parse(src)..expandDynamicVariables = true,
      context: BdfdContext(variables: vars),
    );

void main() {
  test('programs keep ((name)) as text unless expansion is enabled', () async {
    final out = await BdfdRuntime().executeProgram(
      BdfdProgram.parse('((opts.q))'),
      context: BdfdContext(variables: {'opts.q': 'v'}),
    );
    expect(out, '((opts.q))');
  });

  test('((opts.x)) reaches a function argument and plain text', () async {
    final music = _Music();
    final out = await _run(
      r'$playMusic[((opts.music))]Searching ((opts.music))',
      {'opts.music': 'lofi beats', 'user.id': '9'},
      music,
    );
    expect(out, 'Searching lofi beats');
    expect(music.queries.single, 'lofi beats');
  });

  test('values are data: BDFD inside a value is never executed', () async {
    final out = await _run(r'((opts.q))|$message', {
      'opts.q': r'$stopMusic$kick[1]',
      'message.content': r'$stopMusic',
    });
    expect(out, r'$stopMusic$kick[1]|$stopMusic');
  });

  test('unknown or malformed placeholders stay literal text', () async {
    expect(
      await _run(r'a ((nope.x)) b ((c) (( d', {'user.id': '1'}),
      'a ((nope.x)) b ((c) (( d',
    );
    expect(await _run('XP (((user.id)))', {'user.id': '1'}), 'XP (1)');
  });

  test('mixed script: dynamic variables and BDFD functions together', () async {
    final out = await _run(r'$message[music] / ((user.id)) / $message', {
      'interaction.isSlash': 'true',
      'opts.music': 'x',
      'user.id': '7',
      'message.content': 'x',
    });
    expect(out, 'x / 7 / x');
  });
}
