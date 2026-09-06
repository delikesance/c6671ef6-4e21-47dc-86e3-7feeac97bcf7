import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/embed_fields.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('BDFD Fixes Verification', () {
    group(r'$addField Dynamic Freezing & Resolution', () {
      test(r'compiles $addField with dynamic inline raw string', () {
        final result = BdfdCompiler().compile(
          r'$title[Test]$addField[Name;Value;yes]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(1));

        final action = result.actions.single;
        final embeds = action.payload['embeds'] as List;
        expect(embeds, hasLength(1));

        final embed = embeds.first;
        final fields = embed['fields'] as List;
        expect(fields, hasLength(1));
        expect(fields.first['inline'], 'yes');
      });

      test(
        r'resolves $addField inline argument dynamically in buildResolvedEmbedFields',
        () {
          final staticEmbedJson = {
            'fields': [
              {'name': 'Field 1', 'value': 'Val 1', 'inline': 'yes'},
              {'name': 'Field 2', 'value': 'Val 2', 'inline': 'no'},
              {
                'name': 'Field 3',
                'value': 'Val 3',
                'inline': '((dynamicInline))',
              },
            ],
          };

          // Case 1: Dynamic inline resolves to 'yes'
          final resolvedFields1 = buildResolvedEmbedFields(
            embedJson: staticEmbedJson,
            resolve: (input) =>
                resolveTemplatePlaceholders(input, {'dynamicInline': 'yes'}),
          );
          expect(resolvedFields1, hasLength(3));
          expect(resolvedFields1[0].isInline, isTrue);
          expect(resolvedFields1[1].isInline, isFalse);
          expect(resolvedFields1[2].isInline, isTrue);

          // Case 2: Dynamic inline resolves to 'no'
          final resolvedFields2 = buildResolvedEmbedFields(
            embedJson: staticEmbedJson,
            resolve: (input) =>
                resolveTemplatePlaceholders(input, {'dynamicInline': 'no'}),
          );
          expect(resolvedFields2, hasLength(3));
          expect(resolvedFields2[0].isInline, isTrue);
          expect(resolvedFields2[1].isInline, isFalse);
          expect(resolvedFields2[2].isInline, isFalse);
        },
      );
    });

    group(r'$giveRoles & $takeRoles Multi-Role Correctness', () {
      test(
        r'compiles $giveRoles with first arg as userId and loops roles from index 1',
        () {
          final result = BdfdCompiler().compile(
            r'$giveRoles[$authorID;111;222;333]',
          );
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(3));

          expect(result.actions[0].type, BotCreatorActionType.addRole);
          expect(result.actions[0].payload['userId'], '((author.id))');
          expect(result.actions[0].payload['roleId'], '111');

          expect(result.actions[1].type, BotCreatorActionType.addRole);
          expect(result.actions[1].payload['userId'], '((author.id))');
          expect(result.actions[1].payload['roleId'], '222');

          expect(result.actions[2].type, BotCreatorActionType.addRole);
          expect(result.actions[2].payload['userId'], '((author.id))');
          expect(result.actions[2].payload['roleId'], '333');
        },
      );

      test(
        r'compiles $takeRoles with first arg as userId and loops roles from index 1',
        () {
          final result = BdfdCompiler().compile(
            r'$takeRoles[$authorID;444;555]',
          );
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(2));

          expect(result.actions[0].type, BotCreatorActionType.removeRole);
          expect(result.actions[0].payload['userId'], '((author.id))');
          expect(result.actions[0].payload['roleId'], '444');

          expect(result.actions[1].type, BotCreatorActionType.removeRole);
          expect(result.actions[1].payload['userId'], '((author.id))');
          expect(result.actions[1].payload['roleId'], '555');
        },
      );
    });

    group(
      r'$allowMention / $allowUserMentions / $allowRoleMentions AllowedMentions Payloads',
      () {
        test(r'$allowMention enables all mentions', () {
          final result = BdfdCompiler().compile(r'Hello$allowMention');
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(1));

          final action = result.actions.single;
          final allowed = action.payload['allowedMentions'];
          expect(allowed, isNotNull);
          expect(allowed['parse'], containsAll(['users', 'roles']));
        });

        test(
          r'$allowUserMentions restrains to specified user IDs and retains defaults',
          () {
            final result = BdfdCompiler().compile(
              r'Hello$allowUserMentions[123;456]',
            );
            expect(result.hasErrors, isFalse);
            expect(result.actions, hasLength(1));

            final action = result.actions.single;
            final allowed = action.payload['allowedMentions'];
            expect(allowed, isNotNull);
            expect(allowed['users'], ['123', '456']);
            expect(allowed['parse'], contains('roles'));
            expect(allowed['parse'], isNot(contains('users')));
          },
        );

        test(
          r'$allowRoleMentions restrains to specified role IDs and retains defaults',
          () {
            final result = BdfdCompiler().compile(
              r'Hello$allowRoleMentions[789;999]',
            );
            expect(result.hasErrors, isFalse);
            expect(result.actions, hasLength(1));

            final action = result.actions.single;
            final allowed = action.payload['allowedMentions'];
            expect(allowed, isNotNull);
            expect(allowed['roles'], ['789', '999']);
            expect(allowed['parse'], contains('users'));
            expect(allowed['parse'], isNot(contains('roles')));
          },
        );
      },
    );

    group(r'$addReactions & $addMessageReactions Target lastSentMessageId', () {
      test(r'compiles $addReactions targeting ((lastSentMessageId))', () {
        final result = BdfdCompiler().compile(
          r'Send this$addReactions[🔥;✨;🌟]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(2));

        // addReactions is a side-effect action — no longer flushes pending
        // content, so the reaction action appears before the response.
        final reactAction = result.actions.first;
        expect(reactAction.type, BotCreatorActionType.addReaction);
        expect(reactAction.payload['messageId'], '((lastSentMessageId))');
        expect(reactAction.payload['emojis'], ['🔥', '✨', '🌟']);
      });

      test(r'compiles $addCmdReactions targeting triggering message', () {
        final result = BdfdCompiler().compile(
          r'Send this$addCmdReactions[🔥;✨;🌟]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(2));

        final reactAction = result.actions.first;
        expect(reactAction.type, BotCreatorActionType.addReaction);
        expect(reactAction.payload['channelId'], '((channel.id))');
        expect(
          reactAction.payload['messageId'],
          '((trigger.message.id|message.id))',
        );
        expect(reactAction.payload['emojis'], ['🔥', '✨', '🌟']);
      });

      test(
        r'compiles $addMessageReactions targeting specified channel/message',
        () {
          final result = BdfdCompiler().compile(
            r'Send this$addMessageReactions[999999;123456789;👍;👎]',
          );
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(2));

          final reactAction = result.actions.first;
          expect(reactAction.type, BotCreatorActionType.addReaction);
          expect(reactAction.payload['channelId'], '999999');
          expect(reactAction.payload['messageId'], '123456789');
          expect(reactAction.payload['emojis'], ['👍', '👎']);
        },
      );
    });

    group(r'$botLeave Guild Leave Support', () {
      test(r'compiles $botLeave to leaveGuild action', () {
        final result = BdfdCompiler().compile(r'$botLeave');
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(1));

        final action = result.actions.single;
        expect(action.type, BotCreatorActionType.leaveGuild);
      });
    });

    group(r'$addCategorySelect Component', () {
      test(r'compiles $addCategorySelect to category selectMenu', () {
        final result = BdfdCompiler().compile(
          r'$addCategorySelect[cat_id;Choose category;1;1;no]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(1));

        final action = result.actions.single;
        expect(action.type, BotCreatorActionType.respondWithMessage);

        final items = List<Map<String, dynamic>>.from(
          (action.payload['components'] as Map)['items'] as List,
        );
        expect(items, hasLength(1));
        final component = items.first;
        expect(component['type'], 'selectMenu');
        expect(component['menuType'], 'category');
        expect(component['customId'], 'cat_id');
        expect(component['placeholder'], 'Choose category');
        expect(component['minValues'], 1);
        expect(component['maxValues'], 1);
        expect(component['disabled'], isFalse);
      });
    });

    group(r'$addVoiceSelect Component', () {
      test(r'compiles $addVoiceSelect to voice selectMenu', () {
        final result = BdfdCompiler().compile(
          r'$addVoiceSelect[voice_id;Choose voice;1;1;no]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(1));

        final action = result.actions.single;
        expect(action.type, BotCreatorActionType.respondWithMessage);

        final items = List<Map<String, dynamic>>.from(
          (action.payload['components'] as Map)['items'] as List,
        );
        expect(items, hasLength(1));
        final component = items.first;
        expect(component['type'], 'selectMenu');
        expect(component['menuType'], 'voice');
        expect(component['customId'], 'voice_id');
        expect(component['placeholder'], 'Choose voice');
        expect(component['minValues'], 1);
        expect(component['maxValues'], 1);
        expect(component['disabled'], isFalse);
      });
    });

    group('Premium Button Style', () {
      test(r'compiles $addButton with style premium to premium ButtonNode', () {
        final result = BdfdCompiler().compile(
          r'$addButton[no;123456789;Test Label;premium;no;🔥]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(1));

        final action = result.actions.single;
        final items = List<Map<String, dynamic>>.from(
          (action.payload['components'] as Map)['items'] as List,
        );
        expect(items, hasLength(1));
        final component = items.first;
        expect(component['type'], 'button');
        expect(component['style'], 'premium');
        expect(component['skuId'], '123456789');
        expect(component['customId'], '');
        expect(component['url'], '');
        expect(component['label'], '');
        expect(component['emoji'], isNull);
      });

      test(r'compiles $editButton changing to style premium', () {
        final result = BdfdCompiler().compile(
          r'$addButton[no;btn_id;Normal;primary;no]$editButton[btn_id;Normal;premium;no]',
        );
        expect(result.hasErrors, isFalse);
        expect(result.actions, hasLength(1));
        final action = result.actions.single;
        final items = List<Map<String, dynamic>>.from(
          (action.payload['components'] as Map)['items'] as List,
        );
        expect(items, hasLength(1));
        final component = items.first;
        expect(component['type'], 'button');
        expect(component['style'], 'premium');
        expect(component['customId'], '');
        expect(component['label'], '');
      });
    });

    group(r'$randomText resolution & execution', () {
      test(
        r'compiles and resolves user scenario $randomText with multiline and $username',
        () {
          const code = '''\$randomText[
  Welcome \$username to the server! 🎉;
  Hey \$username, glad to see you! 👋;
  \$username just joined us! 🥳;
  A new adventurer, \$username, has arrived! ⚔️
]''';

          final result = BdfdCompiler().compile(code);
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(1));

          final content = result.actions.single.payload['content'] as String;
          expect(content, contains('((randomtext['));

          final expectedOptions = {
            'Welcome Jeremy to the server! 🎉',
            'Hey Jeremy, glad to see you! 👋',
            'Jeremy just joined us! 🥳',
            'A new adventurer, Jeremy, has arrived! ⚔️',
          };

          final picked = <String>{};
          for (var i = 0; i < 200; i++) {
            final resolved = resolveTemplatePlaceholders(content, {
              'user.username': 'Jeremy',
              'author.username': 'Jeremy',
            });
            picked.add(resolved);
          }

          expect(picked, containsAll(expectedOptions));
          expect(picked.difference(expectedOptions), isEmpty);
        },
      );

      test(r'compiles and resolves $randomText inside embed description', () {
        final result = BdfdCompiler().compile(
          r'$title[Coin Flip]$description[Result: $randomText[Heads;Tails]]',
        );
        expect(result.hasErrors, isFalse);
        final embeds = result.actions.single.payload['embeds'] as List;
        final desc = embeds.first['description'] as String;

        final picked = <String>{};
        for (var i = 0; i < 100; i++) {
          picked.add(resolveTemplatePlaceholders(desc, {}));
        }
        expect(picked, containsAll(['Result: Heads', 'Result: Tails']));
      });
    });

    group(
      'Function wiring checks: removeReaction, setNickname, wait, canvasContainer',
      () {
        test(r'compiles $removeReaction with 3 arguments', () {
          final result = BdfdCompiler().compile(r'$removeReaction[123;456;👍]');
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(1));
          final action = result.actions.first;
          expect(action.type, BotCreatorActionType.removeReaction);
          expect(action.payload['channelId'], '123');
          expect(action.payload['messageId'], '456');
          expect(action.payload['emoji'], '👍');
          expect(action.payload['removeOwn'], isTrue);
        });

        test(r'compiles $removeReaction with 1 argument (emoji only)', () {
          final result = BdfdCompiler().compile(r'$removeReaction[🔥]');
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(1));
          final action = result.actions.first;
          expect(action.type, BotCreatorActionType.removeReaction);
          expect(action.payload['channelId'], '((channel.id))');
          expect(action.payload['messageId'], '((message.id))');
          expect(action.payload['emoji'], '🔥');
        });

        test(r'compiles $setNickname', () {
          final result = BdfdCompiler().compile(r'$setNickname[NewNick;987]');
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(1));
          final action = result.actions.first;
          expect(action.type, BotCreatorActionType.setNickname);
          expect(action.payload['nickname'], 'NewNick');
          expect(action.payload['userId'], '987');
        });

        test(r'compiles $wait', () {
          final result = BdfdCompiler().compile(r'$wait[5s]');
          expect(result.hasErrors, isFalse);
          expect(result.actions, hasLength(1));
          final action = result.actions.first;
          expect(action.type, BotCreatorActionType.wait);
          expect(action.payload['duration'], '5s');
        });

        test(
          r'compiles $canvasContainer and $canvasCreate without tokenizer errors',
          () {
            final result = BdfdCompiler().compile(
              r'$canvasCreate[myCanvas;400;300;#FFFFFF]$canvasContainer[box;10;10;100;100]$canvasDrawText[Hello;5;5;#000000;16;box]$attachImage[myCanvas]',
            );
            expect(result.hasErrors, isFalse);
          },
        );

        test(r'compiles and resolves $authorPerms and $memberPerms', () {
          final result = BdfdCompiler().compile(
            r'Perms: $authorPerms | $memberPerms',
          );
          expect(result.hasErrors, isFalse);
          final content = result.actions.first.payload['content'] as String;
          expect(content, contains('((userperms[;-1;, ]))'));

          final resolved = resolveTemplatePlaceholders(content, {
            'author.id': '123',
            'member.permissions': 'administrator,manageMessages',
          });
          expect(
            resolved,
            contains(
              'Perms: ADMINISTRATOR, MANAGE_MESSAGES | ADMINISTRATOR, MANAGE_MESSAGES',
            ),
          );
        });

        test(r'compiles and resolves $getRole', () {
          final result = BdfdCompiler().compile(r'Role: $getRole[$authorID;1]');
          expect(result.hasErrors, isFalse);
          final content = result.actions.first.payload['content'] as String;
          expect(content, contains('((getrole[((author.id));1]))'));

          final resolved = resolveTemplatePlaceholders(content, {
            'author.id': 'user_1',
            'member[user_1].roles': 'role_admin,role_mod,role_member',
          });
          expect(resolved, 'Role: role_admin');

          // Test second role
          final result2 = BdfdCompiler().compile(
            r'Role: $getRole[$authorID;2]',
          );
          final resolved2 = resolveTemplatePlaceholders(
            result2.actions.first.payload['content'] as String,
            {
              'author.id': 'user_1',
              'member[user_1].roles': 'role_admin,role_mod,role_member',
            },
          );
          expect(resolved2, 'Role: role_mod');
        });

        test(r'compiles $hasPerms identical to $checkUserPerms', () {
          final result = BdfdCompiler().compile(
            r'$hasPerms[12345;administrator]',
          );
          expect(result.hasErrors, isFalse);
          expect(result.actions, isNotEmpty);
        });
      },
    );
  });
}
