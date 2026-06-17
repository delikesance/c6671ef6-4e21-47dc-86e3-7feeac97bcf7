import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/modal_builder.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_node_editor.dart';

void main() {
  testWidgets('ModalBuilderWidget renders legacy inputs', (WidgetTester tester) async {
    final modal = ModalDefinition(
      title: 'Legacy Modal',
      customId: 'legacy_custom_id',
      inputs: [
        ModalTextInputDefinition(
          customId: 'field_1',
          label: 'Field 1',
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModalBuilderWidget(
                modal: modal,
                onChanged: (_) {},
                variableSuggestions: const [],
              ),
            ),
          ),
        ),
      ),
    );

    // Verify Title & Custom ID render
    expect(find.text('Legacy Modal'), findsOneWidget);
    expect(find.text('legacy_custom_id'), findsOneWidget);

    // Verify Field 1 is shown
    expect(find.text('Field 1'), findsOneWidget);
    expect(find.text('field_1'), findsOneWidget);

    // Verify Add Field button is present
    expect(find.text('Add Field'), findsOneWidget);
  });

  testWidgets('ModalBuilderWidget renders V2 components and supports adding V2 components', (WidgetTester tester) async {
    final modal = ModalDefinition(
      title: 'V2 Modal',
      customId: 'v2_custom_id',
      components: [
        LabelNode(
          label: 'V2 Field 1',
          component: ModalTextInputNode(
            customId: 'v2_field_1',
            label: 'V2 Inner 1',
          ),
        ),
      ],
    );

    ModalDefinition? updatedModal;

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: ModalBuilderWidget(
                modal: modal,
                onChanged: (updated) {
                  updatedModal = updated;
                },
                variableSuggestions: const [],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Custom ID
    expect(find.text('V2 Modal'), findsOneWidget);
    expect(find.text('v2_custom_id'), findsOneWidget);

    // Verify ComponentNodeEditor renders for LabelNode
    expect(find.byType(ComponentNodeEditor), findsAtLeast(1));
    expect(find.text('V2 Field 1'), findsOneWidget);

    // Verify "Add Input Field" is NOT shown
    expect(find.text('Add Input Field'), findsNothing);

    // Verify "Add Field" is present
    expect(find.text('Add Field'), findsOneWidget);

    // Ensure the button is visible before tapping
    await tester.ensureVisible(find.text('Add Field'));

    // Click "Add Field" button/dropdown
    await tester.tap(find.text('Add Field'));
    await tester.pumpAndSettle();

    // Should show popup menu items
    expect(find.text('Dropdown Selection'), findsOneWidget);
    expect(find.text('Single Checkbox'), findsOneWidget);

    // Tap on Dropdown Selection option
    await tester.tap(find.text('Dropdown Selection'));
    await tester.pumpAndSettle();

    // Verify onChanged was called with a new String Select component added
    expect(updatedModal, isNotNull);
    expect(updatedModal!.components.length, 2);
    expect(updatedModal!.components.last, isA<LabelNode>());
    final lastLabel = updatedModal!.components.last as LabelNode;
    expect(lastLabel.component, isA<SelectMenuNode>());
  });
}
