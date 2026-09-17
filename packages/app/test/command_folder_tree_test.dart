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
}
