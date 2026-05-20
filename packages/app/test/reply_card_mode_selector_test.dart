import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/command_create_cards/reply_card.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_v2_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/normal_component_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/modal_builder.dart';
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a [ReplyCard] inside a scrollable [MaterialApp] for widget tests.
Widget _buildReplyCard({
  String responseType = 'normal',
  ValueChanged<String>? onResponseTypeChanged,
  Map<String, dynamic>? responseComponents,
}) {
  final controller = TextEditingController();
  String currentType = responseType;

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          body: SingleChildScrollView(
            child: ReplyCard(
              responseType: currentType,
              onResponseTypeChanged: (t) {
                setState(() => currentType = t);
                onResponseTypeChanged?.call(t);
              },
              responseController: controller,
              variableSuggestionBar: const SizedBox.shrink(),
              responseEmbeds: const [],
              onEmbedsChanged: (_) {},
              responseComponents:
                  responseComponents ?? ComponentV2Definition().toJson(),
              onComponentsChanged: (_) {},
              responseModal: const {},
              onModalChanged: (_) {},
              responseWorkflow: const {},
              normalizeWorkflow: (w) => w,
              variableSuggestions: const [],
              emojiSuggestions: null,
              botIdForConfig: null,
              onWorkflowChanged: (_) {},
              workflowSummary: 'No workflow',
            ),
          ),
        );
      },
    ),
  );
}

void main() {
  group('ReplyCard – mode selector labels', () {
    testWidgets('shows "Standard Message" chip instead of "Normal Reply"', (
      tester,
    ) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(find.text('Standard Message'), findsOneWidget);
      expect(find.text('Normal Reply'), findsNothing);
    });

    testWidgets('shows "Layout Mode" chip instead of "Component V2"', (
      tester,
    ) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(find.text('Layout Mode'), findsOneWidget);
      expect(find.text('Component V2'), findsNothing);
    });

    testWidgets('shows "Modal Form" chip', (tester) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(find.text('Modal Form'), findsOneWidget);
    });

    testWidgets('all three mode chips are visible', (tester) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(find.text('Standard Message'), findsOneWidget);
      expect(find.text('Layout Mode'), findsOneWidget);
      expect(find.text('Modal Form'), findsOneWidget);
    });
  });

  group('ReplyCard – mode descriptions shown inline', () {
    testWidgets('Standard Message chip shows description text', (tester) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(
        find.text('Text, embeds and optional buttons / select menus'),
        findsOneWidget,
      );
    });

    testWidgets('Layout Mode chip shows description text', (tester) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(
        find.text(
          "Discord's rich layout system — containers, media, text & forms",
        ),
        findsOneWidget,
      );
    });

    testWidgets('Modal Form chip shows description text', (tester) async {
      await tester.pumpWidget(_buildReplyCard());
      await tester.pumpAndSettle();

      expect(find.text('Pop-up dialog with text input fields'), findsOneWidget);
    });
  });

  group('ReplyCard – mode switching shows correct editor', () {
    testWidgets('default normal mode shows NormalComponentEditorWidget', (
      tester,
    ) async {
      // Use a large screen so the components section is reachable.
      tester.view.physicalSize = const Size(800, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildReplyCard(responseType: 'normal'));
      await tester.pumpAndSettle();

      expect(find.byType(NormalComponentEditorWidget), findsOneWidget);
      expect(find.byType(ComponentV2EditorWidget), findsNothing);
      expect(find.byType(ModalBuilderWidget), findsNothing);
    });

    testWidgets('componentV2 mode shows ComponentV2EditorWidget', (
      tester,
    ) async {
      await tester.pumpWidget(_buildReplyCard(responseType: 'componentV2'));
      await tester.pumpAndSettle();

      expect(find.byType(ComponentV2EditorWidget), findsOneWidget);
      expect(find.byType(NormalComponentEditorWidget), findsNothing);
      expect(find.byType(ModalBuilderWidget), findsNothing);
    });

    testWidgets('modal mode shows ModalBuilderWidget', (tester) async {
      await tester.pumpWidget(_buildReplyCard(responseType: 'modal'));
      await tester.pumpAndSettle();

      expect(find.byType(ModalBuilderWidget), findsOneWidget);
      expect(find.byType(ComponentV2EditorWidget), findsNothing);
      expect(find.byType(NormalComponentEditorWidget), findsNothing);
    });

    testWidgets(
      'tapping Layout Mode chip switches to ComponentV2EditorWidget',
      (tester) async {
        await tester.pumpWidget(_buildReplyCard(responseType: 'normal'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.text('Layout Mode'));
        await tester.tap(find.text('Layout Mode'));
        await tester.pumpAndSettle();

        expect(find.byType(ComponentV2EditorWidget), findsOneWidget);
      },
    );

    testWidgets('tapping Modal Form chip switches to ModalBuilderWidget', (
      tester,
    ) async {
      await tester.pumpWidget(_buildReplyCard(responseType: 'normal'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Modal Form'));
      await tester.tap(find.text('Modal Form'));
      await tester.pumpAndSettle();

      expect(find.byType(ModalBuilderWidget), findsOneWidget);
    });
  });

  group('ReplyCard – normal mode components label', () {
    testWidgets('components expansion tile uses user-friendly label', (
      tester,
    ) async {
      await tester.pumpWidget(_buildReplyCard(responseType: 'normal'));
      await tester.pumpAndSettle();

      expect(find.text('Buttons & Select Menus (optional)'), findsOneWidget);
      // Old ambiguous label must be gone.
      expect(find.text('Message Components (Buttons/Selects)'), findsNothing);
    });
  });

  group('ReplyCard – Layout Mode header text', () {
    testWidgets(
      'ComponentV2EditorWidget header shows "Layout Mode" not "Full Component V2 Builder"',
      (tester) async {
        await tester.pumpWidget(_buildReplyCard(responseType: 'componentV2'));
        await tester.pumpAndSettle();

        expect(find.text('Layout Mode'), findsAtLeastNWidgets(1));
        expect(find.text('Full Component V2 Builder'), findsNothing);
      },
    );
  });
}
