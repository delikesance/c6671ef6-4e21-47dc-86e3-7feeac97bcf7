import 'package:nyxx/nyxx.dart';

import '../../../utils/command_autocomplete.dart';
import '../../../utils/template_resolver.dart';
import 'variable_logic.dart'
    show extractArrayFromJsonInput, normalizeVariableJsonPath;

/// `respondWithAutocomplete`: answers the autocomplete interaction with up to
/// 25 choices built from a JSON array and stops the list
/// (`results['__stopped__'] = 'AUTOCOMPLETE'`).
Future<void> runAutocompleteBlock({
  required Interaction? interaction,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
}) async {
  if (interaction is! ApplicationCommandAutocompleteInteraction) {
    throw Exception(
      'respondWithAutocomplete requires an autocomplete interaction context',
    );
  }

  final itemsInput = resolveValue((payload['items'] ?? '').toString());
  final path = normalizeVariableJsonPath(
    resolveValue((payload['path'] ?? r'$').toString()),
  );
  final items = extractArrayFromJsonInput(itemsInput, path);
  final labelTemplate = (payload['labelTemplate'] ?? '{value}').toString();
  final valueTemplate = (payload['valueTemplate'] ?? '{value}').toString();

  final focused =
      variables['autocomplete.optionType']?.trim().toLowerCase() ??
      commandOptionTypeToText(
        findFocusedInteractionOption(interaction.data.options)?.type ??
            CommandOptionType.string,
      ).toLowerCase();

  final builders = <CommandOptionChoiceBuilder<dynamic>>[];
  for (final item in items) {
    if (builders.length >= 25) {
      break;
    }
    final label = resolveItemTemplate(labelTemplate, item, variables).trim();
    final rawValue = resolveItemTemplate(valueTemplate, item, variables).trim();
    if (label.isEmpty || rawValue.isEmpty) {
      continue;
    }

    dynamic typedValue;
    switch (focused) {
      case 'integer':
        typedValue = int.tryParse(rawValue);
        break;
      case 'number':
        typedValue = double.tryParse(rawValue);
        break;
      default:
        typedValue = rawValue;
        break;
    }

    if (typedValue == null) {
      continue;
    }

    builders.add(
      CommandOptionChoiceBuilder<dynamic>(name: label, value: typedValue),
    );
  }

  await interaction.respond(builders);
  results[resultKey] = 'RESPONDED';
  results['__stopped__'] = 'AUTOCOMPLETE';
}
