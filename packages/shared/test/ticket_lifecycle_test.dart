import 'package:bot_creator_shared/services/bot_block_discord_actions.dart';
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
}
