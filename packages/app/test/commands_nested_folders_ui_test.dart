import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/commands.list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('CommandFolderHeader Widget', () {
    testWidgets('renders folder header with depth indicator and counts', (
      tester,
    ) async {
      var toggled = false;
      var renamed = false;
      var deleted = false;
      var addSubfolderTapped = false;
      var newCommandTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CommandFolderHeader(
              title: 'Bans',
              count: 3,
              directCount: 2,
              depth: 1,
              isExpanded: true,
              onToggle: () => toggled = true,
              onRename: () => renamed = true,
              onDelete: () => deleted = true,
              onAddSubfolder: () => addSubfolderTapped = true,
              onNewCommand: () => newCommandTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bans'), findsOneWidget);
      expect(find.text('↳ '), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Bans'));
      expect(toggled, isTrue);

      // Open popup menu and select add subfolder
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text(l10n.commands_create_button), findsOneWidget);
      expect(find.text(l10n.commands_create_folder), findsOneWidget);
      expect(find.text(l10n.commands_rename_folder), findsOneWidget);
      expect(find.text(l10n.commands_delete_folder), findsOneWidget);

      await tester.tap(find.text(l10n.commands_create_folder));
      await tester.pumpAndSettle();
      expect(addSubfolderTapped, isTrue);

      // Verify other actions when invoked
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commands_create_button));
      await tester.pumpAndSettle();
      expect(newCommandTapped, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commands_rename_folder));
      await tester.pumpAndSettle();
      expect(renamed, isTrue);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commands_delete_folder));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });
}
