import 'package:bot_creator_shared/actions/cms_action_message.dart';
import 'package:test/test.dart';

void main() {
  group('cms action templates', () {
    test('substituteCmsPlaceholders keeps {{field}} shortcut', () {
      expect(
        substituteCmsPlaceholders('Hi {{name}}!', {'name': 'Ada'}),
        'Hi Ada!',
      );
      expect(substituteCmsPlaceholders('Hi {{missing}}!', {}), 'Hi !');
    });

    test('resolveCmsActionTemplate resolves ((guild.cms…)) after curly', () {
      final resolved = resolveCmsActionTemplate(
        'Welcome {{title}} / ((guild.cms.welcome.enabled))',
        moduleId: 'welcome',
        fieldValues: {'title': 'Server', 'enabled': 'true'},
      );
      expect(resolved, 'Welcome Server / true');
    });

    test('resolveCmsActionTemplate supports bare field id tokens', () {
      final resolved = resolveCmsActionTemplate(
        'On: ((enabled|false))',
        moduleId: 'welcome',
        fieldValues: {'enabled': 'yes'},
      );
      expect(resolved, 'On: yes');
    });
  });
}
