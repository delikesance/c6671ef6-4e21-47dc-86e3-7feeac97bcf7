import 'package:bot_creator/features/bot_editor/logic/bot_presence_keys.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'un pull remplace les anciennes activités locales (clé lue en premier)',
    () {
      final local = <String, dynamic>{
        'activities': [
          {'type': 'playing', 'name': 'Ancien', 'minIntervalSeconds': 60},
        ],
        'statuses': [
          {'type': 'playing', 'text': 'Ancien'},
        ],
      };
      // Config du Manager : uniquement `statuses` (BotConfig.toJson).
      final remote = <String, dynamic>{
        'statuses': [
          {'type': 'watching', 'name': 'New member', 'text': 'New member'},
        ],
      };

      expect(mirrorPresenceActivities(local, remote), isTrue);

      final shown = (local['activities'] ?? local['statuses']) as List;
      expect(shown, hasLength(1));
      expect((shown.single as Map)['name'], 'New member');
      expect((shown.single as Map)['type'], 'watching');
      expect((local['statuses'] as List).single['name'], 'New member');
    },
  );

  test('un statut distant vide efface les activités locales', () {
    final local = <String, dynamic>{
      'activities': [
        {'type': 'playing', 'name': 'Ancien'},
      ],
    };
    mirrorPresenceActivities(local, {'statuses': <dynamic>[]});
    expect(local['activities'], isEmpty);
    expect(local['statuses'], isEmpty);
  });

  test('sans clé d\'activité dans la source, le local est laissé intact', () {
    final local = <String, dynamic>{
      'activities': [
        {'type': 'playing', 'name': 'Local'},
      ],
    };
    expect(mirrorPresenceActivities(local, {'prefix': '!'}), isFalse);
    expect((local['activities'] as List).single['name'], 'Local');
  });

  test('l\'ancien format (text seul) est complété avec name', () {
    final local = <String, dynamic>{};
    mirrorPresenceActivities(local, {
      'statuses': [
        {'type': 'playing', 'text': 'Vieux'},
      ],
    });
    expect((local['activities'] as List).single['name'], 'Vieux');
  });
}
