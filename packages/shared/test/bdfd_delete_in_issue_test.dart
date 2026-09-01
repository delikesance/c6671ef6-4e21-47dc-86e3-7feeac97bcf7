import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

void main() {
  group(r'Issue #246: $deleteIn response message deletion', () {
    test(r'$title[Test] $description[Hello] $deleteIn[5s] sets deleteAfter on embed response', () {
      final result = BdfdCompiler().compile(r'$title[Test]$description[Hello]$deleteIn[5s]');
      expect(result.hasErrors, isFalse);

      expect(result.actions, hasLength(1));
      final action = result.actions.single;
      expect(action.type, BotCreatorActionType.respondWithMessage);
      expect(action.payload['deleteAfter'], '5s');
      final embeds = action.payload['embeds'] as List;
      expect(embeds.single['title'], 'Test');
      expect(embeds.single['description'], 'Hello');
    });

    test(r'$deleteIn[3s] Hello World! sets deleteAfter on text response', () {
      final result = BdfdCompiler().compile(r'$deleteIn[3s]Hello World!');
      expect(result.hasErrors, isFalse);

      expect(result.actions, hasLength(1));
      final action = result.actions.single;
      expect(action.type, BotCreatorActionType.respondWithMessage);
      expect(action.payload['content'], 'Hello World!');
      expect(action.payload['deleteAfter'], '3s');
    });

    test(r'$reply $title[Reply] $deleteIn[10s] sets deleteAfter on reply message', () {
      final result = BdfdCompiler().compile(r'$reply$title[Reply]$deleteIn[10s]');
      expect(result.hasErrors, isFalse);

      expect(result.actions, hasLength(1));
      final action = result.actions.single;
      expect(action.type, BotCreatorActionType.sendMessage);
      expect(action.payload['targetType'], 'reply');
      expect(action.payload['deleteAfter'], '10s');
    });

    test(r'$clear[10] $deletecommand $title[Purged] $deleteIn[5s] compiles separate clear, deletecommand and embed with deleteAfter', () {
      final result = BdfdCompiler().compile(
        r'$clear[10]'
        r'$deletecommand'
        r'$title[Purged]'
        r'$deleteIn[5s]',
      );
      expect(result.hasErrors, isFalse);

      expect(result.actions, hasLength(3));
      // 1. Clear messages
      expect(result.actions[0].type, BotCreatorActionType.deleteMessages);
      expect(result.actions[0].payload['count'], '10');

      // 2. Delete command trigger
      expect(result.actions[1].type, BotCreatorActionType.deleteTrigger);

      // 3. Embed response with deleteAfter
      expect(result.actions[2].type, BotCreatorActionType.respondWithMessage);
      expect(result.actions[2].payload['deleteAfter'], '5s');
      final embeds = result.actions[2].payload['embeds'] as List;
      expect(embeds.single['title'], 'Purged');
    });
  });
}
