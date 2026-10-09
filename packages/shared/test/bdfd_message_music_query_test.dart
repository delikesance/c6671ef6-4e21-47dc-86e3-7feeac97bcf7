import 'package:bot_creator_shared/engine/bdfd/context_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/music_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/services/bot_music_service.dart';
import 'package:bot_creator_shared/utils/global.dart';
import 'package:bot_creator_shared/utils/message_runtime.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Music implements BotMusicService {
  final requests = <BotMusicRequest>[];
  @override
  Future<void> perform(BotMusicRequest request, {dynamic budget}) async =>
      requests.add(request);
}

Future<String> _run(Map<String, String> variables, _Music music) =>
    BdfdRuntime(
      functions: {...bdfdContextFunctions(), ...bdfdMusicFunctions(music)},
    ).execute(
      r'$playMusic[$message]$message',
      context: BdfdContext(variables: variables),
    );

void main() {
  test(
    r'$playMusic[$message] receives the typed prefix-command query',
    () async {
      final music = _Music();
      final out = await _run({
        'user.id': '9',
        ...buildCommandArgumentRuntimeVariables(['never', 'gonna']),
      }, music);
      expect(out, 'never gonna');
      expect(music.requests.single.query, 'never gonna');
    },
  );

  test(r'slash option values feed $message like prefix arguments', () async {
    final values = collectSlashArgumentValues([
      InteractionOption(
        name: 'query',
        type: CommandOptionType.string,
        value: 'lofi beats',
        options: null,
        isFocused: null,
      ),
    ]);
    expect(values, ['lofi beats']);
    final music = _Music();
    final out = await _run({
      'user.id': '9',
      'interaction.isSlash': 'true',
      'opts.query': 'lofi beats',
      ...buildCommandArgumentRuntimeVariables(values),
    }, music);
    expect(out, 'lofi beats');
    expect(music.requests.single.query, 'lofi beats');
  });

  test('an empty query explains how to provide one', () async {
    final music = _Music();
    await expectLater(
      _run({'user.id': '9', 'interaction.isSlash': 'true'}, music),
      throwsA(
        isA<Object>().having(
          (e) => e.toString(),
          'message',
          contains('Type a song name'),
        ),
      ),
    );
    expect(music.requests, isEmpty);
  });
}
