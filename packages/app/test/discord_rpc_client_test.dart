import 'package:bot_creator/utils/discord_rpc_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildDiscordUnixIpcCandidates', () {
    test('respects the documented environment priority and appends /tmp', () {
      final candidates = buildDiscordUnixIpcCandidates(
        environment: const <String, String>{
          'TMPDIR': '/var/tmp/custom',
          'XDG_RUNTIME_DIR': '/run/user/1000',
        },
      );

      expect(candidates.first, '/run/user/1000/discord-ipc-0');
      expect(candidates[10], '/var/tmp/custom/discord-ipc-0');
      expect(candidates.last, '/tmp/discord-ipc-9');
    });

    test('deduplicates repeated directories', () {
      final candidates = buildDiscordUnixIpcCandidates(
        environment: const <String, String>{
          'XDG_RUNTIME_DIR': '/tmp',
          'TMPDIR': '/tmp',
        },
      );

      expect(
        candidates.where((path) => path.startsWith('/tmp/')),
        hasLength(10),
      );
    });
  });

  group('buildDiscordWindowsIpcCandidates', () {
    test('builds the documented named pipe range', () {
      final candidates = buildDiscordWindowsIpcCandidates();
      expect(candidates, hasLength(10));
      expect(candidates.first, r'\\?\pipe\discord-ipc-0');
      expect(candidates.last, r'\\?\pipe\discord-ipc-9');
    });
  });
}
