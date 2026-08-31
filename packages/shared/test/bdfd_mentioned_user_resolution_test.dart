import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  group(r'Issue #231: $mentioned fallback and associated user variables', () {
    test(
      r'$mentioned[1;yes] transpiles to ((message.mentions[0]|author.id))',
      () {
        final result = BdfdCompiler().compile(r'$mentioned[1;yes]');
        expect(result.hasErrors, isFalse);
        expect(
          result.actions.single.payload['content'],
          '((message.mentions[0]|author.id))',
        );
      },
    );

    test(
      r'$mentioned[yes] transpiles to ((message.mentions[0]|author.id))',
      () {
        final result = BdfdCompiler().compile(r'$mentioned[yes]');
        expect(result.hasErrors, isFalse);
        expect(
          result.actions.single.payload['content'],
          '((message.mentions[0]|author.id))',
        );
      },
    );

    test(
      r'$var[user;$mentioned[1;yes]] with $username[$var[user]] resolves author info when no mention',
      () {
        final result = BdfdCompiler().compile(
          r'$var[user;$mentioned[1;yes]]'
          r"$title[$username[$var[user]]'s Rank]"
          r'$addField[XP;$getUserVar[xp;$var[user]];yes]',
        );

        expect(result.hasErrors, isFalse);

        // Verify actions
        expect(result.actions.length, greaterThanOrEqualTo(2));
        expect(
          result.actions.first.type,
          BotCreatorActionType.setTemporaryVariable,
        );
        expect(result.actions.first.payload['key'], 'user');
        expect(
          result.actions.first.payload['value'],
          '((message.mentions[0]|author.id))',
        );

        // Now test template resolution at runtime with author variables
        final variables = <String, String>{
          'author.id': '123456789',
          'author.username': 'Garder500',
          'user.id': '123456789',
          'user.username': 'Garder500',
          'user.bc_xp': '19',
          'user[123456789].username': 'Garder500',
          'user[123456789].bc_xp': '19',
        };

        // 1. Resolve temp variable write
        final tempVal = resolveTemplatePlaceholders(
          result.actions.first.payload['value'] as String,
          variables,
        );
        expect(tempVal, '123456789');
        variables['temp.user'] = tempVal;

        // 2. Resolve title
        final titleRaw =
            (result.actions[1].payload['embeds'] as List).first['title']
                as String;
        final resolvedTitle = resolveTemplatePlaceholders(titleRaw, variables);
        expect(resolvedTitle, "Garder500's Rank");

        // 3. Resolve field value
        final fieldValueRaw =
            ((result.actions[1].payload['embeds'] as List).first['fields']
                        as List)
                    .first['value']
                as String;
        final resolvedFieldValue = resolveTemplatePlaceholders(
          fieldValueRaw,
          variables,
        );
        expect(resolvedFieldValue, '19');
      },
    );

    test(
      r'$mentioned[1;yes] resolves to mentioned user when mention is present',
      () {
        final variables = <String, String>{
          'author.id': '111111111',
          'author.username': 'AuthorUser',
          'message.mentions[0]': '222222222',
          'user[222222222].username': 'TargetUser',
        };

        final result = BdfdCompiler().compile(
          r'$var[user;$mentioned[1;yes]]'
          r"$title[$username[$var[user]]'s Rank]",
        );

        final tempVal = resolveTemplatePlaceholders(
          result.actions.first.payload['value'] as String,
          variables,
        );
        expect(tempVal, '222222222');
        variables['temp.user'] = tempVal;

        final titleRaw =
            (result.actions[1].payload['embeds'] as List).first['title']
                as String;
        final resolvedTitle = resolveTemplatePlaceholders(titleRaw, variables);
        expect(resolvedTitle, "TargetUser's Rank");
      },
    );
  });
}
