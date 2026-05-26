import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isInteractionOnlyAction', () {
    test('correctly identifies interaction-only actions', () {
      expect(isInteractionOnlyAction(BotCreatorActionType.respondWithModal), isTrue);
      expect(isInteractionOnlyAction(BotCreatorActionType.deferInteraction), isTrue);
      expect(isInteractionOnlyAction(BotCreatorActionType.respondWithMessage), isTrue);
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
}
