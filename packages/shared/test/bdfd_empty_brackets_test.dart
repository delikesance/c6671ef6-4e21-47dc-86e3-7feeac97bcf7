import 'package:bot_creator_shared/engine/bdfd/music_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:test/test.dart';

Future<Object?> _run(String source) async {
  try {
    return await BdfdRuntime(
      functions: bdfdMusicFunctions(),
    ).execute(source, context: BdfdContext(variables: {}));
  } catch (e) {
    return e.toString();
  }
}

void main() {
  // Without a configured music service the call itself is reached and fails
  // with this message: it proves the argument count was accepted.
  const reached = 'Music service is not configured';

  for (final name in ['stopMusic', 'pauseMusic', 'skipMusic', 'resumeMusic']) {
    test('\$$name and \$$name[] are both accepted', () async {
      expect(await _run('\$$name'), contains(reached));
      expect(await _run('\$$name[]'), contains(reached));
    });
    test('\$$name[x] is still rejected', () async {
      expect(
        await _run('\$$name[x]'),
        contains('Invalid argument count for \$$name: 1'),
      );
    });
  }
}
