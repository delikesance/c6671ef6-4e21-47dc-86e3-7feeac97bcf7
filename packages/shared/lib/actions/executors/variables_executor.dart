import 'package:bot_creator_shared/utils/command_autocomplete.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';

import '../../engine/bdfd/visual/variable_logic.dart';
import '../../types/action.dart';
import 'image_executor.dart';

export '../../engine/bdfd/visual/variable_logic.dart'
    show resolveScopeContextId, executeVariableAction;

/// Historical dispatcher. The variable / JSON / array logic lives in
/// `engine/bdfd/visual/variable_logic.dart`; only the few non-family types
/// (attachImage, respondWithAutocomplete, image blocks, log) remain here.
Future<bool> executeVariablesAction({
  required BotCreatorActionType type,
  required BotDataStore store,
  required String botId,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required Snowflake? guildId,
  required Snowflake? fallbackChannelId,
  required Interaction? interaction,
  void Function(String message)? onLog,
}) async {
  switch (type) {
    case BotCreatorActionType.attachImage:
      await executeAttachImage(
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        resolveValue: resolveValue,
      );
      return true;

    case BotCreatorActionType.respondWithAutocomplete:
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
        final label = resolveItemTemplate(
          labelTemplate,
          item,
          variables,
        ).trim();
        final rawValue = resolveItemTemplate(
          valueTemplate,
          item,
          variables,
        ).trim();
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
      return true;

    case BotCreatorActionType.runtimeImageBlock:
      await executeRuntimeImageBlock(
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        resolveValue: resolveValue,
      );
      return true;

    case BotCreatorActionType.canvasCreateBlock:
    case BotCreatorActionType.canvasLoadImageBlock:
    case BotCreatorActionType.canvasDrawTextBlock:
    case BotCreatorActionType.canvasDrawCircleBlock:
    case BotCreatorActionType.canvasDrawRectBlock:
    case BotCreatorActionType.canvasDrawLineBlock:
      // Visual-only types — should be collapsed into runtimeImageBlock
      // before reaching the executor.
      throw StateError(
        'Canvas block type ${type.name} must be nested inside an '
        'Image Manipulation Block (runtimeImageBlock) and cannot be '
        'executed standalone.',
      );

    case BotCreatorActionType.log:
      final message = resolveValue((payload['message'] ?? '').toString());
      if (message.isNotEmpty) {
        onLog?.call(message);
      }
      results[resultKey] = 'LOGGED';
      return true;

    default:
      return executeVariableAction(
        type: type,
        store: store,
        botId: botId,
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        resolveValue: resolveValue,
        guildId: guildId,
        fallbackChannelId: fallbackChannelId,
        interaction: interaction,
        onLog: onLog,
      );
  }
}
