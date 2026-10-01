import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  group('random template functions', () {
    test('coin() returns "true" or empty string', () {
      final results = <String>{};
      // Run multiple times to cover both outcomes.
      for (var i = 0; i < 200; i++) {
        results.add(resolveTemplatePlaceholders('((coin()))', {}));
      }
      expect(results, containsAll(['true', '']));
      // No other values should appear.
      expect(results.difference({'true', ''}), isEmpty);
    });

    test('random() returns "true" or empty string (legacy alias)', () {
      final results = <String>{};
      for (var i = 0; i < 200; i++) {
        results.add(resolveTemplatePlaceholders('((random()))', {}));
      }
      expect(results, containsAll(['true', '']));
    });

    test('randomchoice picks from provided arguments', () {
      final results = <String>{};
      for (var i = 0; i < 200; i++) {
        results.add(
          resolveTemplatePlaceholders('((randomchoice("a", "b", "c")))', {}),
        );
      }
      expect(results, containsAll(['a', 'b', 'c']));
      expect(results.difference({'a', 'b', 'c'}), isEmpty);
    });

    test('randomint returns integer in range', () {
      final results = <int>{};
      for (var i = 0; i < 200; i++) {
        final s = resolveTemplatePlaceholders('((randomint(1, 3)))', {});
        results.add(int.parse(s));
      }
      expect(results, containsAll([1, 2, 3]));
      expect(results.every((v) => v >= 1 && v <= 3), isTrue);
    });

    test('randomchoice with no args returns empty', () {
      final resolved = resolveTemplatePlaceholders('((randomchoice()))', {});
      expect(resolved, '');
    });

    test('randomint with invalid range returns empty', () {
      final resolved = resolveTemplatePlaceholders('((randomint(5, 2)))', {});
      expect(resolved, '');
    });

    test('randomtext bracket variant picks from provided options', () {
      final results = <String>{};
      for (var i = 0; i < 200; i++) {
        results.add(
          resolveTemplatePlaceholders('((randomtext[Heads;Tails]))', {}),
        );
      }
      expect(results, containsAll(['Heads', 'Tails']));
      expect(results.difference({'Heads', 'Tails'}), isEmpty);
    });

    test(
      'randomtext bracket variant resolves nested placeholders and trims multiline options',
      () {
        final template = '''((randomtext[
  Welcome ((author.username)) to the server! 🎉;
  Hey ((author.username)), glad to see you! 👋;
  ((author.username)) just joined us! 🥳;
  A new adventurer, ((author.username)), has arrived! ⚔️
]))''';

        final expected = {
          'Welcome Jeremy to the server! 🎉',
          'Hey Jeremy, glad to see you! 👋',
          'Jeremy just joined us! 🥳',
          'A new adventurer, Jeremy, has arrived! ⚔️',
        };

        final results = <String>{};
        for (var i = 0; i < 200; i++) {
          results.add(
            resolveTemplatePlaceholders(template, {
              'author.username': 'Jeremy',
            }),
          );
        }
        expect(results, containsAll(expected));
        expect(results.difference(expected), isEmpty);
      },
    );

    test('randomtext bracket variant with no args returns empty', () {
      expect(resolveTemplatePlaceholders('((randomtext[]))', {}), '');
    });

    test('randomtext function variant picks from provided arguments', () {
      final results = <String>{};
      for (var i = 0; i < 200; i++) {
        results.add(
          resolveTemplatePlaceholders(
            '((randomtext("Yes", "No", "Maybe")))',
            {},
          ),
        );
      }
      expect(results, containsAll(['Yes', 'No', 'Maybe']));
      expect(results.difference({'Yes', 'No', 'Maybe'}), isEmpty);
    });

    test('random entity IDs come from hydrated candidate lists', () {
      final updates = {
        'author.id': '123456789',
        'author.username': 'Jeremy',
        'channel.id': '987654321',
        'guild.id': '555555555',
        'member.roles': '111,222,333',
        'random.channelIds': '["31","32"]',
        'random.categoryIds': '["40"]',
        'random.roleIds': '["80","81"]',
        'random.guildIds': '["555555555","666666666"]',
        'random.userIds': '["444444444"]',
        'random.userNames': '{"444444444":"Visitor"}',
      };

      expect(
        resolveTemplatePlaceholders('((random.userId))', updates),
        '444444444',
      );
      expect(
        resolveTemplatePlaceholders('((random.user))', updates),
        'Visitor',
      );
      expect(
        resolveTemplatePlaceholders('((random.mention))', updates),
        '<@444444444>',
      );
      expect(
        {'31', '32'},
        contains(resolveTemplatePlaceholders('((random.channelId))', updates)),
      );
      expect(
        resolveTemplatePlaceholders('((random.categoryId))', updates),
        '40',
      );
      expect({
        '555555555',
        '666666666',
      }, contains(resolveTemplatePlaceholders('((random.guildId))', updates)));
      final role = resolveTemplatePlaceholders('((random.roleId))', updates);
      expect(['80', '81'], contains(role));
      expect(resolveTemplatePlaceholders('((random.roleId))', {}), '');
    });
  });
}
