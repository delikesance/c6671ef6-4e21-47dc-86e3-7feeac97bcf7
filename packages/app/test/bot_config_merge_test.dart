import 'package:bot_creator/features/bot_editor/logic/bot_config_merge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computeBotConfigMergeDiff detects remote updates', () {
    final local = <Map<String, dynamic>>[
      {
        'id': 'cmd1',
        'name': 'ping',
        'updatedAt': '2026-01-01T10:00:00.000Z',
      },
    ];
    final remote = <Map<String, dynamic>>[
      {
        'id': 'cmd1',
        'name': 'ping',
        'updatedAt': '2026-01-02T10:00:00.000Z',
      },
    ];

    final diff = computeBotConfigMergeDiff(local, remote);
    expect(diff.updatedCommands, hasLength(1));
    expect(diff.hasChanges, isTrue);
  });

  test('botConfigLocalHasNewerEdits detects newer local command', () {
    final local = <Map<String, dynamic>>[
      {
        'id': 'cmd1',
        'updatedAt': '2026-01-03T10:00:00.000Z',
      },
    ];
    final remote = <Map<String, dynamic>>[
      {
        'id': 'cmd1',
        'updatedAt': '2026-01-01T10:00:00.000Z',
      },
    ];

    expect(botConfigLocalHasNewerEdits(local, remote), isTrue);
  });
}
