import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/command_folder_tree.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/folder_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme(),
      home: Scaffold(body: child),
    );
  }

  group('FolderPickerDialog', () {
    testWidgets(
      'renders root option, existing folders, and create folder input',
      (tester) async {
        String? selected;

        final tree = buildCommandFolderTree(
          commands: [
            {'name': 'c1', 'folder': 'admin'},
            {'name': 'c2', 'folder': 'admin/moderation'},
            {'name': 'c3', 'folder': 'fun'},
          ],
          emptyFolders: {},
        );

        await tester.pumpWidget(
          buildApp(
            Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    selected = await FolderPickerDialog.show(
                      context: context,
                      title: 'Move workflow to folder',
                      currentFolder: 'admin',
                      tree: tree,
                    );
                  },
                  child: const Text('Open Picker'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // Dialog is visible
        expect(find.text('Move workflow to folder'), findsOneWidget);
        expect(find.text('No folder'), findsOneWidget);
        expect(find.text('admin'), findsOneWidget);
        expect(find.textContaining('moderation'), findsWidgets);
        expect(find.text('fun'), findsOneWidget);
        expect(find.byIcon(Icons.create_new_folder_outlined), findsOneWidget);

        // Tap on 'fun'
        await tester.tap(find.text('fun'));
        await tester.pumpAndSettle();

        expect(selected, 'fun');
      },
    );

    testWidgets('selecting root folder returns empty string', (tester) async {
      String? selected;

      final tree = buildCommandFolderTree(
        commands: [
          {'name': 'c1', 'folder': 'admin'},
        ],
        emptyFolders: {},
      );

      await tester.pumpWidget(
        buildApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  selected = await FolderPickerDialog.show(
                    context: context,
                    title: 'Move workflow to folder',
                    currentFolder: 'admin',
                    tree: tree,
                  );
                },
                child: const Text('Open Picker'),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('No folder'));
      await tester.pumpAndSettle();

      expect(selected, '');
    });
  });

  group('Workflow folder tree build', () {
    test('organizes workflows into tree with empty folders', () {
      final workflows = [
        {'name': 'wf1', 'folder': ''},
        {'name': 'wf2', 'folder': 'moderation/kick'},
        {'name': 'wf3', 'folder': 'moderation/ban'},
        {'name': 'wf4', 'folder': 'fun'},
      ];

      final emptyFolders = {'utility/logging'};

      final tree = buildCommandFolderTree(
        commands: workflows,
        emptyFolders: emptyFolders,
      );

      expect(tree.rootCommands.length, 1);
      expect(tree.rootCommands.first['name'], 'wf1');

      // Root folders: 'moderation', 'fun', 'utility'
      expect(tree.rootFolders.map((f) => f.name).toSet(), {
        'moderation',
        'fun',
        'utility',
      });

      final modNode = tree.rootFolders.firstWhere(
        (f) => f.name == 'moderation',
      );
      expect(modNode.totalCommandCount, 2);
      expect(modNode.subfolders.map((f) => f.name).toSet(), {'kick', 'ban'});

      final utilNode = tree.rootFolders.firstWhere((f) => f.name == 'utility');
      expect(utilNode.totalCommandCount, 0);
      expect(utilNode.subfolders.first.name, 'logging');
    });
  });
}
