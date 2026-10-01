import 'package:bot_creator_shared/actions/ticket_management.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

void main() {
  test('ticket starts private in the first Discord create request', () {
    final payload = buildPrivateTicketChannel(
      name: 'support-alice',
      guildId: Snowflake(10),
      categoryId: Snowflake(40),
      ownerId: Snowflake(20),
    ).build();

    expect(payload['name'], 'support-alice');
    expect(payload['parent_id'], '40');
    final overwrites = payload['permission_overwrites'] as List;
    expect(overwrites[0], {'id': '10', 'type': 0, 'deny': '1024'});
    expect(overwrites[1], {'id': '20', 'type': 1, 'allow': '68608'});
  });

  test('ticket helpers compile to marked creation and guarded deletion', () {
    final create = BdfdCompiler().compile(r'$newTicket[40;support;Welcome]');
    expect(create.hasErrors, isFalse);
    final createAction = create.actions.firstWhere(
      (action) => action.type == BotCreatorActionType.createChannel,
    );
    expect(createAction.payload, containsPair('categoryId', '40'));
    expect(createAction.payload, containsPair('ownerId', '((author.id))'));
    expect(createAction.payload, containsPair('isTicket', true));
    expect(createAction.payload, containsPair('welcomeMessage', 'Welcome'));

    final close = BdfdCompiler().compile(r'$closeTicket[Not a ticket]');
    expect(close.hasErrors, isFalse);
    final closeAction = close.actions.firstWhere(
      (action) => action.type == BotCreatorActionType.removeChannel,
    );
    expect(closeAction.payload, containsPair('ticketClose', true));
  });
}
