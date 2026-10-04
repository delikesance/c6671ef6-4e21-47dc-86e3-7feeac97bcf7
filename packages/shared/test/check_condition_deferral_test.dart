import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

/// Verifies that $checkCondition defers to runtime when its expression
/// references a runtime-resolved placeholder (regression: previously it
/// baked the literal "false" into the action because the numeric comparator
/// saw a non-numeric operand).
void main() {
  group('checkCondition — runtime evaluation', () {
    final now = 1_700_000_000; // fixed epoch seconds

    test('daily cooldown: elapsed >= 86400 -> true', () {
      final value =
          r'((checkCondition[((sub[((getTimestamp));((lastTs))]))>=86400]))';
      final updates = <String, String>{
        'getTimestamp': now.toString(),
        'lastTs': (now - 2 * 86400).toString(), // 2 days ago
      };
      expect(resolveTemplatePlaceholders(value, updates), 'true');
    });

    test('daily cooldown: elapsed < 86400 -> false', () {
      final value =
          r'((checkCondition[((sub[((getTimestamp));((lastTs))]))>=86400]))';
      final updates = <String, String>{
        'getTimestamp': now.toString(),
        'lastTs': (now - 3600).toString(), // 1 hour ago
      };
      expect(resolveTemplatePlaceholders(value, updates), 'false');
    });

    test('>= boundary is inclusive', () {
      final value =
          r'((checkCondition[((sub[((getTimestamp));((lastTs))]))>=86400]))';
      final updates = <String, String>{
        'getTimestamp': now.toString(),
        'lastTs': (now - 86400).toString(), // exactly on the boundary
      };
      expect(resolveTemplatePlaceholders(value, updates), 'true');
    });

    test('other operators (==, !=, <, <=, >) resolve at runtime', () {
      expect(
        resolveTemplatePlaceholders(
          r'((checkCondition[((a))==5]))',
          <String, String>{'a': '5'},
        ),
        'true',
      );
      expect(
        resolveTemplatePlaceholders(
          r'((checkCondition[((a))!=5]))',
          <String, String>{'a': '5'},
        ),
        'false',
      );
      expect(
        resolveTemplatePlaceholders(
          r'((checkCondition[((a))<10]))',
          <String, String>{'a': '3'},
        ),
        'true',
      );
      expect(
        resolveTemplatePlaceholders(
          r'((checkCondition[((a))>10]))',
          <String, String>{'a': '3'},
        ),
        'false',
      );
    });

    test('empty/missing operand resolves to false, not a crash', () {
      expect(
        resolveTemplatePlaceholders(
          r'((checkCondition[((missing))>=86400]))',
          <String, String>{},
        ),
        'false',
      );
    });
  });
}
