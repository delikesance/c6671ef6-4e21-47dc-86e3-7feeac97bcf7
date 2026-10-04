import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/settings_group_widgets.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/modules_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.darkTheme(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('SettingsToggleRow : 54 px minimum et toute la ligne bascule', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => SettingsSection(
            title: 'Intents',
            children: [
              SettingsToggleRow(
                title: 'Message Content',
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('INTENTS'), findsOneWidget);
    final size = tester.getSize(find.byType(SettingsRow));
    expect(size.height, greaterThanOrEqualTo(kSettingsRowMinHeight));
    await tester.tap(find.text('Message Content'));
    await tester.pump();
    expect(value, isTrue);
  });

  testWidgets('ModulesListView : groupes, recherche et navigation', (
    tester,
  ) async {
    String? opened;
    await tester.pumpWidget(
      _host(
        ModulesListView(
          title: 'Modules',
          searchHint: 'Rechercher un module',
          groups: [
            ModuleListGroup(
              title: 'Création',
              entries: [
                ModuleListEntry(
                  id: 'workflows',
                  icon: Icons.account_tree_outlined,
                  title: 'Workflows',
                  subtitle: 'Automatisez',
                  badge: '1',
                  onTap: () => opened = 'workflows',
                ),
              ],
            ),
            ModuleListGroup(
              title: 'Automatisation',
              entries: [
                ModuleListEntry(
                  id: 'scheduler',
                  icon: Icons.schedule_rounded,
                  title: 'Planificateur',
                  onTap: () => opened = 'scheduler',
                ),
              ],
            ),
          ],
        ),
      ),
    );
    expect(find.text('CRÉATION'), findsOneWidget);
    expect(find.text('AUTOMATISATION'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'plani');
    await tester.pump();
    expect(find.text('CRÉATION'), findsNothing);
    await tester.tap(find.text('Planificateur'));
    expect(opened, 'scheduler');
  });
}
