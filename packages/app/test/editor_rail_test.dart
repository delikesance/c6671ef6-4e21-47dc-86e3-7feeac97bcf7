import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/editor_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rail desktop plat : navigation, épinglage de « Paramètres » et absence de
/// débordement sur une fenêtre courte (la partie centrale défile).
void main() {
  Widget host(void Function(String) onSelect) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Row(
        children: [
          EditorRail(
            appName: 'Bot-Creator',
            botId: '123',
            sections: [
              const EditorSidebarSection(
                title: '',
                items: [
                  EditorSidebarItem(
                    id: 'home',
                    icon: Icons.home_rounded,
                    label: 'Accueil',
                  ),
                  EditorSidebarItem(
                    id: 'commands',
                    icon: Icons.terminal_rounded,
                    label: 'Commandes',
                  ),
                ],
              ),
              EditorSidebarSection(
                title: '',
                items: [
                  for (var i = 0; i < 10; i++)
                    EditorSidebarItem(
                      id: 'm$i',
                      icon: Icons.widgets_rounded,
                      label: 'Module $i',
                    ),
                ],
              ),
            ],
            pinnedItem: const EditorSidebarItem(
              id: 'settings',
              icon: Icons.settings_outlined,
              label: 'Paramètres',
            ),
            activeItemId: 'home',
            onSelectItem: onSelect,
            onBack: () {},
          ),
          const Expanded(child: SizedBox()),
        ],
      ),
    ),
  );

  testWidgets('rail : fenêtre courte sans débordement, items et Paramètres', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    String? selected;
    await tester.pumpWidget(host((id) => selected = id));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Paramètres'), findsOneWidget);
    await tester.tap(find.text('Paramètres'));
    expect(selected, 'settings');
    await tester.tap(find.text('Commandes'));
    expect(selected, 'commands');
  });
}
