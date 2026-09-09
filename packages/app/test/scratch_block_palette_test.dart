import 'package:flutter/material.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isInteractionOnlyAction', () {
    test('correctly identifies interaction-only actions', () {
      expect(isInteractionOnlyAction(BotCreatorActionType.respondWithModal), isTrue);
      expect(isInteractionOnlyAction(BotCreatorActionType.deferInteraction), isTrue);
      expect(isInteractionOnlyAction(BotCreatorActionType.editInteractionMessage), isTrue);
      // respondWithMessage is NOT interaction-only: it falls back to a plain
      // channel send when no interaction is present, so it works in all contexts.
      expect(isInteractionOnlyAction(BotCreatorActionType.respondWithMessage), isFalse);
      expect(isInteractionOnlyAction(BotCreatorActionType.sendMessage), isFalse);
      expect(isInteractionOnlyAction(BotCreatorActionType.wait), isFalse);
    });
  });

  group('isListenerAction', () {
    test('correctly identifies listener actions', () {
      expect(isListenerAction(BotCreatorActionType.listenForButtonClick), isTrue);
      expect(isListenerAction(BotCreatorActionType.listenForSelectMenu), isTrue);
      expect(isListenerAction(BotCreatorActionType.listenForModalSubmit), isTrue);
      expect(isListenerAction(BotCreatorActionType.respondWithModal), isFalse);
      expect(isListenerAction(BotCreatorActionType.wait), isFalse);
    });
  });

  group('attachImage action type', () {
    test('is categorized as Messages via getCategoryForAction', () {
      final group = getCategoryForAction(BotCreatorActionType.attachImage);
      expect(group, equals('Messages'));
    });

    test('has correct icon', () {
      expect(
        BotCreatorActionType.attachImage.icon,
        isNotNull,
      );
    });

    test('has 3 parameter definitions with correct types', () {
      final params = BotCreatorActionType.attachImage.parameterDefinitions;

      expect(params.length, equals(3));

      // imageName: required string
      expect(params[0].key, equals('imageName'));
      expect(params[0].required, isTrue);
      expect(params[0].hint, isNotNull);

      // imageSource: required url
      expect(params[1].key, equals('imageSource'));
      expect(params[1].required, isTrue);
      expect(params[1].hint, isNotNull);

      // altText: optional string
      expect(params[2].key, equals('altText'));
      expect(params[2].required, isFalse);
      expect(params[2].hint, isNotNull);
    });

    test('all parameters allow dynamic variable injection', () {
      final params = BotCreatorActionType.attachImage.parameterDefinitions;
      for (final param in params) {
        expect(param.allowDynamic, isTrue,
            reason: '${param.key} should allow variable injection');
      }
    });
  });

  group('Music and Interactions categorization', () {
    test('Interactions actions are categorized under Interactions', () {
      expect(getCategoryForAction(BotCreatorActionType.respondWithMessage), equals('Interactions'));
      expect(getCategoryForAction(BotCreatorActionType.respondWithModal), equals('Interactions'));
      expect(getCategoryForAction(BotCreatorActionType.sendDm), equals('Interactions'));
    });

    test('Music actions are categorized under Music', () {
      expect(getCategoryForAction(BotCreatorActionType.playMusic), equals('Music'));
      expect(getCategoryForAction(BotCreatorActionType.pauseMusic), equals('Music'));
      expect(getCategoryForAction(BotCreatorActionType.joinVoice), equals('Music'));
    });

    test('playMusic has correct parameters and types', () {
      final params = BotCreatorActionType.playMusic.parameterDefinitions;
      expect(params.length, equals(3));
      expect(params[0].key, equals('query'));
      expect(params[0].required, isTrue);
      expect(params[1].key, equals('userId'));
      expect(params[2].key, equals('channelId'));
    });
  });

  group('ScratchBlockPalette Drag & Drop behavior', () {
    testWidgets('disables Draggable when enableDrag is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ScratchBlockPalette(
              onActionSelected: (_) {},
              enableDrag: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<BotCreatorActionType>), findsNothing);
    });

    testWidgets('enables Draggable when enableDrag is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ScratchBlockPalette(
              onActionSelected: (_) {},
              enableDrag: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<BotCreatorActionType>), findsWidgets);
    });

    testWidgets('disables Draggable by default on mobile screen size', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ScratchBlockPalette(
              onActionSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<BotCreatorActionType>), findsNothing);
    });
  });
}
