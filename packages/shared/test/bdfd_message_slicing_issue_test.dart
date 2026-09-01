import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('Issue #233: \$message and \$args range slicing', () {
    test(r'$message[2;99] transpiles to join(slice(split(...))) and resolves multi-word reason', () {
      final compilerResult = BdfdCompiler().compile(r'$message[2;99]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((join(slice(split(message.content, " "), 1, 99), " ")))');

      final variables = <String, String>{
        'message.content': '@JeremySoler J\'avais envie',
      };
      final resolved = resolveTemplatePlaceholders(content, variables);
      expect(resolved, "J'avais envie");
    });

    test(r'$message[2;] transpiles to slice from index 1 to end', () {
      final compilerResult = BdfdCompiler().compile(r'$message[2;]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((join(slice(split(message.content, " "), 1), " ")))');

      final variables = <String, String>{
        'message.content': '@JeremySoler J\'avais vraiment très envie',
      };
      final resolved = resolveTemplatePlaceholders(content, variables);
      expect(resolved, "J'avais vraiment très envie");
    });

    test(r'$message[>1] transpiles to slice after word 1', () {
      final compilerResult = BdfdCompiler().compile(r'$message[>1]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((join(slice(split(message.content, " "), 1), " ")))');

      final variables = <String, String>{
        'message.content': '@JeremySoler Message multi mot',
      };
      final resolved = resolveTemplatePlaceholders(content, variables);
      expect(resolved, 'Message multi mot');
    });

    test(r'$message[1;3] transpiles to slice from word 1 to 3', () {
      final compilerResult = BdfdCompiler().compile(r'$message[1;3]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((join(slice(split(message.content, " "), 0, 3), " ")))');

      final variables = <String, String>{
        'message.content': 'un deux trois quatre cinq',
      };
      final resolved = resolveTemplatePlaceholders(content, variables);
      expect(resolved, 'un deux trois');
    });

    test(r'$message[2;99] on single-word message resolves to empty string', () {
      final compilerResult = BdfdCompiler().compile(r'$message[2;99]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      final variables = <String, String>{
        'message.content': '@JeremySoler',
      };
      final resolved = resolveTemplatePlaceholders(content, variables);
      expect(resolved, '');
    });

    test(r'$args[2;99] behaves identically for slicing', () {
      final compilerResult = BdfdCompiler().compile(r'$args[2;99]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((join(slice(split(message.content, " "), 1, 99), " ")))');

      final variables = <String, String>{
        'message.content': '@JeremySoler Spamming channels',
      };
      final resolved = resolveTemplatePlaceholders(content, variables);
      expect(resolved, 'Spamming channels');
    });

    test(r'$message[1;text] preserves slash command option fallback when second arg is string', () {
      final compilerResult = BdfdCompiler().compile(r'$message[1;text]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((message.content[0]|opts.text))');
    });

    test(r'$message[1] single word remains unchanged', () {
      final compilerResult = BdfdCompiler().compile(r'$message[1]');
      expect(compilerResult.hasErrors, isFalse);

      final content = compilerResult.actions.single.payload['content'] as String;
      expect(content, '((message.content[0]))');
    });
  });
}
