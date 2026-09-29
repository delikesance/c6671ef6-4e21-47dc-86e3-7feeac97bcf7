import 'package:bot_creator/features/bot_editor/logic/command_registration_signature.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';

void main() {
  String signature(
    CommandOptionBuilder option, {
    String name = 'search',
    String permissions = '8',
  }) => commandRegistrationSignature(
    name: name,
    description: 'Search',
    type: ApplicationCommandType.chatInput,
    options: [option],
    permissions: Permissions(int.parse(permissions)),
    integrationTypes: [ApplicationIntegrationType.guildInstall],
    contexts: [InteractionContextType.guild],
  );

  CommandOptionBuilder option() => CommandOptionBuilder(
    type: CommandOptionType.string,
    name: 'query',
    description: 'Query',
  );

  test('autocomplete workflow edits preserve the Discord registration', () {
    final value = option();
    setCommandOptionAutocompleteConfig(value, {
      'enabled': true,
      'mode': 'javascript',
      'script': 'old',
    });
    final before = signature(value);
    setCommandOptionAutocompleteConfig(value, {
      'enabled': true,
      'mode': 'javascript',
      'script': 'new',
    });
    expect(signature(value), before);
    setCommandOptionAutocompleteConfig(value, null);
    expect(signature(value), isNot(before));
  });

  test('name, permissions and nested options change the registration', () {
    final value = option();
    final before = signature(value);
    expect(signature(value, name: 'find'), isNot(before));
    expect(signature(value, permissions: '0'), isNot(before));
    value.description = 'New query description';
    expect(signature(value), isNot(before));
  });
}
