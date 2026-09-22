import 'package:bot_creator/features/bot_editor/logic/command_folder_tree.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeFolderPath', () {
    test('normalizes leading, trailing, and duplicate slashes', () {
      expect(normalizeFolderPath('/Moderation/Bans/'), 'Moderation/Bans');
      expect(
        normalizeFolderPath('  Admin // Settings / Roles  '),
        'Admin/Settings/Roles',
      );
      expect(normalizeFolderPath(''), '');
      expect(normalizeFolderPath(null), '');
    });

    test('folderDisplayName returns last segment', () {
      expect(folderDisplayName('Moderation/Bans'), 'Bans');
      expect(folderDisplayName('Moderation'), 'Moderation');
      expect(folderDisplayName(''), '');
    });

    test('folderParentPath returns parent path', () {
      expect(folderParentPath('Moderation/Bans/Perm'), 'Moderation/Bans');
      expect(folderParentPath('Moderation/Bans'), 'Moderation');
      expect(folderParentPath('Moderation'), '');
    });
  });

  group('buildCommandFolderTree', () {
    test('builds nested hierarchy and computes command counts', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'ping', 'folder': ''},
        {'id': '2', 'name': 'kick', 'folder': 'Moderation'},
        {'id': '3', 'name': 'ban', 'folder': 'Moderation/Bans'},
        {'id': '4', 'name': 'tempban', 'folder': 'Moderation/Bans'},
        {'id': '5', 'name': 'mute', 'folder': 'Moderation/Mutes'},
        {'id': '6', 'name': 'shop', 'folder': 'Economy'},
      ];
      final emptyFolders = {'Admin/Logs'};

      final tree = buildCommandFolderTree(
        commands: commands,
        emptyFolders: emptyFolders,
      );

      // Root commands
      expect(tree.rootCommands.length, 1);
      expect(tree.rootCommands.first['name'], 'ping');

      // Root folders: Admin, Economy, Moderation (alphabetical)
      expect(tree.rootFolders.map((f) => f.name).toList(), [
        'Admin',
        'Economy',
        'Moderation',
      ]);

      final moderation = tree.rootFolders.firstWhere(
        (f) => f.name == 'Moderation',
      );
      expect(moderation.depth, 0);
      expect(moderation.commands.length, 1); // kick
      expect(moderation.subfolders.length, 2); // Bans, Mutes
      expect(moderation.subfolders.map((s) => s.name).toList(), [
        'Bans',
        'Mutes',
      ]);
      expect(
        moderation.totalCommandCount,
        4,
      ); // kick (1) + ban & tempban (2) + mute (1)

      final bans = moderation.subfolders.firstWhere((s) => s.name == 'Bans');
      expect(bans.depth, 1);
      expect(bans.commands.length, 2);
      expect(bans.totalCommandCount, 2);

      // Admin empty folder generated parent Admin with child Logs
      final admin = tree.rootFolders.firstWhere((f) => f.name == 'Admin');
      expect(admin.depth, 0);
      expect(admin.commands, isEmpty);
      expect(admin.subfolders.length, 1);
      expect(admin.subfolders.first.name, 'Logs');
      expect(admin.subfolders.first.depth, 1);
    });

    test('flatten produces ordered indented items', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'ban', 'folder': 'Moderation/Bans'},
      ];
      final tree = buildCommandFolderTree(
        commands: commands,
        emptyFolders: const {},
      );

      final flat = tree.flatten();
      expect(flat.length, 2);
      expect(flat[0].displayName, 'Moderation');
      expect(flat[0].depth, 0);
      expect(flat[0].indentedLabel, 'Moderation');

      expect(flat[1].displayName, 'Bans');
      expect(flat[1].depth, 1);
      expect(flat[1].indentedLabel, '  ↳ Bans');
    });
  });

  group('cascadeRenameFolder', () {
    test('renames parent and all descendants', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'kick', 'folder': 'Moderation'},
        {'id': '2', 'name': 'ban', 'folder': 'Moderation/Bans'},
        {'id': '3', 'name': 'perm', 'folder': 'Moderation/Bans/Perm'},
        {'id': '4', 'name': 'help', 'folder': 'General'},
      ];
      final empty = {'Moderation/Warnings', 'General/Info'};

      final updatedCommands = <Map<String, dynamic>>[];
      cascadeRenameFolder(
        oldPath: 'Moderation',
        newPath: 'Safety',
        commands: commands,
        emptyFolders: empty,
        onUpdateCommand: updatedCommands.add,
      );

      expect(updatedCommands.length, 3);
      expect(
        updatedCommands.firstWhere((c) => c['id'] == '1')['folder'],
        'Safety',
      );
      expect(
        updatedCommands.firstWhere((c) => c['id'] == '2')['folder'],
        'Safety/Bans',
      );
      expect(
        updatedCommands.firstWhere((c) => c['id'] == '3')['folder'],
        'Safety/Bans/Perm',
      );

      expect(empty, contains('Safety/Warnings'));
      expect(empty, contains('General/Info'));
      expect(empty, isNot(contains('Moderation/Warnings')));
    });
  });

  group('cascadeDeleteFolder', () {
    test(
      'removes folder from target and descendant commands and empty folders',
      () {
        final commands = <Map<String, dynamic>>[
          {'id': '1', 'name': 'kick', 'folder': 'Moderation'},
          {'id': '2', 'name': 'ban', 'folder': 'Moderation/Bans'},
          {'id': '3', 'name': 'help', 'folder': 'General'},
        ];
        final empty = {'Moderation/Warnings', 'General/Info'};

        final updatedCommands = <Map<String, dynamic>>[];
        cascadeDeleteFolder(
          targetPath: 'Moderation',
          commands: commands,
          emptyFolders: empty,
          onUpdateCommand: updatedCommands.add,
        );

        expect(updatedCommands.length, 2);
        expect(updatedCommands.every((c) => c['folder'] == null), isTrue);
        expect(empty, {'General/Info'});
      },
    );
  });

  group('cascadeMoveFolder', () {
    test('moves folder to root when destination is empty', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'kick', 'folder': 'Admin/Moderation'},
        {'id': '2', 'name': 'ban', 'folder': 'Admin/Moderation/Bans'},
        {'id': '3', 'name': 'help', 'folder': 'General'},
      ];
      final empty = {'Admin/Moderation/Mutes', 'General/Info'};

      final updated = <Map<String, dynamic>>[];
      final success = cascadeMoveFolder(
        sourcePath: 'Admin/Moderation',
        destinationParentPath: '',
        commands: commands,
        emptyFolders: empty,
        onUpdateCommand: updated.add,
      );

      expect(success, isTrue);
      expect(updated.length, 2);
      expect(
        updated.firstWhere((c) => c['id'] == '1')['folder'],
        'Moderation',
      );
      expect(
        updated.firstWhere((c) => c['id'] == '2')['folder'],
        'Moderation/Bans',
      );
      expect(empty, contains('Moderation/Mutes'));
      expect(empty, contains('General/Info'));
      expect(empty, isNot(contains('Admin/Moderation/Mutes')));
    });

    test('moves folder into destination parent', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'kick', 'folder': 'Moderation'},
        {'id': '2', 'name': 'ban', 'folder': 'Moderation/Bans'},
      ];
      final empty = {'Moderation/Logs'};

      final updated = <Map<String, dynamic>>[];
      final success = cascadeMoveFolder(
        sourcePath: 'Moderation',
        destinationParentPath: 'Staff/Security',
        commands: commands,
        emptyFolders: empty,
        onUpdateCommand: updated.add,
      );

      expect(success, isTrue);
      expect(
        updated.firstWhere((c) => c['id'] == '1')['folder'],
        'Staff/Security/Moderation',
      );
      expect(
        updated.firstWhere((c) => c['id'] == '2')['folder'],
        'Staff/Security/Moderation/Bans',
      );
      expect(empty, contains('Staff/Security/Moderation/Logs'));
      expect(empty, isNot(contains('Moderation/Logs')));
    });

    test('prevents cycle when moving into self or subfolder', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'kick', 'folder': 'Moderation'},
      ];
      final empty = <String>{};
      final updated = <Map<String, dynamic>>[];

      final selfMove = cascadeMoveFolder(
        sourcePath: 'Moderation',
        destinationParentPath: 'Moderation',
        commands: commands,
        emptyFolders: empty,
        onUpdateCommand: updated.add,
      );
      expect(selfMove, isFalse);

      final childMove = cascadeMoveFolder(
        sourcePath: 'Moderation',
        destinationParentPath: 'Moderation/Sub',
        commands: commands,
        emptyFolders: empty,
        onUpdateCommand: updated.add,
      );
      expect(childMove, isFalse);
      expect(updated, isEmpty);
    });
  });

  group('cascadeDeleteFolderAndCommands', () {
    test('deletes folder and collects all nested command IDs', () {
      final commands = <Map<String, dynamic>>[
        {'id': '1', 'name': 'kick', 'folder': 'Moderation'},
        {'id': '2', 'name': 'ban', 'folder': 'Moderation/Bans'},
        {'id': '3', 'name': 'help', 'folder': 'General'},
      ];
      final empty = {'Moderation/Logs', 'General/Info'};

      final deletedCommandIds = <String>[];
      cascadeDeleteFolderAndCommands(
        targetPath: 'Moderation',
        commands: commands,
        emptyFolders: empty,
        onDeleteCommand: deletedCommandIds.add,
      );

      expect(deletedCommandIds, containsAll(['1', '2']));
      expect(deletedCommandIds, isNot(contains('3')));
      expect(empty, {'General/Info'});
    });
  });
}
