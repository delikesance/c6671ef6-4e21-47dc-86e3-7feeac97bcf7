import 'package:bot_creator/features/bot_editor/logic/js_event_context_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsEventContextCatalog', () {
    test('always includes shared script globals', () {
      final items = JsEventContextCatalog.itemsForEvent('messageCreate');
      for (final name in JsEventContextCatalog.alwaysAvailable) {
        expect(items, contains(name));
      }
    });

    test('messageCreate exposes message host and examples', () {
      final items = JsEventContextCatalog.itemsForEvent('messageCreate');
      expect(items, contains('message'));
      expect(items, contains('message.content'));
      expect(items, contains('guild'));
      expect(items, contains('channel'));
      expect(items, contains('member'));
      expect(JsEventContextCatalog.hasSparseBinding('messageCreate'), isFalse);
    });

    test('interactionCreate exposes interaction host', () {
      final items = JsEventContextCatalog.itemsForEvent('interactionCreate');
      expect(items, contains('interaction'));
      expect(items, contains('interaction.commandName'));
      expect(JsEventContextCatalog.hasSparseBinding('interactionCreate'), isFalse);
    });

    test('guildMemberAdd exposes member host', () {
      final items = JsEventContextCatalog.itemsForEvent('guildMemberAdd');
      expect(items, contains('member'));
      expect(items, contains('member.user.username'));
      expect(items, contains('guild'));
    });

    test('channelCreate exposes channel host', () {
      final items = JsEventContextCatalog.itemsForEvent('channelCreate');
      expect(items, contains('channel'));
      expect(items, contains('channel.id'));
    });

    test('guildCreate exposes guild host', () {
      final items = JsEventContextCatalog.itemsForEvent('guildCreate');
      expect(items, contains('guild'));
      expect(items, contains('guild.name'));
    });

    test('voiceStateUpdate is sparse (first arg is not a host type)', () {
      final items = JsEventContextCatalog.itemsForEvent('voiceStateUpdate');
      expect(items, JsEventContextCatalog.alwaysAvailable);
      expect(JsEventContextCatalog.hasSparseBinding('voiceStateUpdate'), isTrue);
    });

    test('dedupes always + specific', () {
      final items = JsEventContextCatalog.itemsForEvent('messageCreate');
      expect(items.toSet().length, items.length);
    });
  });
}
