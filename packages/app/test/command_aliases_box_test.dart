import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/command_create_cards/basic_info_card.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/metadata_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart' hide Locale;

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Finder aliasField() => find.byWidgetPredicate(
    (widget) =>
        widget is TextField &&
        widget.decoration?.labelText == l10n.command_alias_label,
  );

  group('BasicInfoCard Aliases Box', () {
    testWidgets('Aliases box is hidden when isLegacyCommand is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: BasicInfoCard(
                commandName: 'ping',
                commandDescription: 'Ping command',
                commandType: ApplicationCommandType.chatInput,
                isLegacyCommand: false,
                canEditCommandType: true,
                showDescriptionField: true,
                integrationTypes: const [
                  ApplicationIntegrationType.guildInstall,
                ],
                contexts: const [InteractionContextType.guild],
                onNameChanged: (_) {},
                onDescriptionChanged: (_) {},
                onCommandTypeChanged: (_) {},
                onLegacyCommandChanged: (_) {},
                localOnlyCommand: false,
                onLocalOnlyCommandChanged: (_) {},
                onIntegrationTypesChanged: (_) {},
                onContextsChanged: (_) {},
                defaultMemberPermissions: '',
                onDefaultMemberPermissionsChanged: (_) {},
                nameValidator: (_) => null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(aliasField(), findsNothing);
    });

    testWidgets(
      'Aliases box appears when isLegacyCommand is true and notifies on change',
      (tester) async {
        List<String>? received;

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: BasicInfoCard(
                  commandName: 'ping',
                  commandDescription: 'Ping command',
                  commandType: ApplicationCommandType.chatInput,
                  isLegacyCommand: true,
                  canEditCommandType: true,
                  showDescriptionField: true,
                  integrationTypes: const [
                    ApplicationIntegrationType.guildInstall,
                  ],
                  contexts: const [InteractionContextType.guild],
                  onNameChanged: (_) {},
                  onDescriptionChanged: (_) {},
                  onCommandTypeChanged: (_) {},
                  onLegacyCommandChanged: (_) {},
                  localOnlyCommand: true,
                  onLocalOnlyCommandChanged: (_) {},
                  onIntegrationTypesChanged: (_) {},
                  onContextsChanged: (_) {},
                  defaultMemberPermissions: '',
                  onDefaultMemberPermissionsChanged: (_) {},
                  nameValidator: (_) => null,
                  legacyAliases: const ['p'],
                  onLegacyAliasesChanged: (val) => received = val,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(aliasField(), findsOneWidget);
        expect(tester.widget<TextField>(aliasField()).controller?.text, 'p');

        // Enter up to 2 aliases separated by a comma
        await tester.enterText(aliasField(), 'p, ping2');
        await tester.pumpAndSettle();

        expect(received, ['p', 'ping2']);

        // Extra third comma is disallowed / truncated to 2 parts
        await tester.enterText(aliasField(), 'p, ping2, extra');
        await tester.pumpAndSettle();

        expect(received, ['p', 'ping2']);
      },
    );
  });

  group('MetadataBlock Aliases Box', () {
    testWidgets('Aliases box appears only when isLegacyCommand is true', (
      tester,
    ) async {
      List<String>? received;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MetadataBlock(
                commandName: 'clear',
                commandDescription: 'Clear messages',
                commandType: ApplicationCommandType.chatInput,
                isLegacyCommand: true,
                localOnlyCommand: true,
                canEditCommandType: true,
                showDescriptionField: true,
                integrationTypes: const [
                  ApplicationIntegrationType.guildInstall,
                ],
                contexts: const [InteractionContextType.guild],
                onNameChanged: (_) {},
                onDescriptionChanged: (_) {},
                onCommandTypeChanged: (_) {},
                onLegacyCommandChanged: (_) {},
                onLocalOnlyCommandChanged: (_) {},
                onIntegrationTypesChanged: (_) {},
                onContextsChanged: (_) {},
                defaultMemberPermissions: '',
                onDefaultMemberPermissionsChanged: (_) {},
                nameValidator: (_) => null,
                legacyAliases: const ['c', 'clean'],
                onLegacyAliasesChanged: (val) => received = val,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(aliasField(), findsOneWidget);
      expect(
        tester.widget<TextField>(aliasField()).controller?.text,
        'c, clean',
      );

      await tester.enterText(aliasField(), '!c, !cls');
      await tester.pumpAndSettle();

      expect(received, ['c', 'cls']);
    });
  });
}
