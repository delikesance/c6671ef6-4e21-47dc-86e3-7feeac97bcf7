import '../../../types/action.dart' show BotCreatorActionType;
import 'action_type_extension.dart';
import 'action_types.dart';

class ActionSummaryData {
  const ActionSummaryData({
    required this.title,
    required this.summary,
    required this.outputKey,
    required this.isEnabled,
    this.meta = const <String>[],
  });

  final String title;
  final String summary;
  final String outputKey;
  final bool isEnabled;
  final List<String> meta;
}

ActionSummaryData summarizeActionItem(ActionItem action) {
  final params = action.parameters;
  final configuredKey = _valueOrEmpty(params['key']);
  final outputKey = configuredKey.isEmpty ? action.id : configuredKey;

  switch (action.type) {
    case BotCreatorActionType.sendMessage:
      final content = _preview(params['content'] ?? params['text']);
      final channel =
          _valueOrEmpty(params['channelId']).isNotEmpty
              ? _valueOrEmpty(params['channelId'])
              : 'same channel';
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            content.isNotEmpty
                ? 'Send to $channel: $content'
                : 'Send to $channel',
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
    case BotCreatorActionType.runWorkflow:
      final workflow = _valueOrEmpty(params['workflowName']);
      final entryPoint = _valueOrEmpty(params['entryPoint']);
      final arguments = (params['arguments'] as Map?)?.length ?? 0;
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            workflow.isEmpty
                ? 'Run a saved workflow'
                : 'Run $workflow${entryPoint.isNotEmpty ? ' -> $entryPoint' : ''}',
        outputKey: outputKey,
        isEnabled: action.enabled,
        meta: ifList(<String>[if (arguments > 0) '$arguments arg(s)']),
      );
    case BotCreatorActionType.listenForButtonClick:
      final workflow = _valueOrEmpty(params['workflowName']);
      final customId = _valueOrEmpty(params['customId']);
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            workflow.isEmpty
                ? 'Listen for a button click'
                : 'Button ${customId.isEmpty ? '' : customId} -> $workflow'
                    .trim(),
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
    case BotCreatorActionType.listenForSelectMenu:
      final workflow = _valueOrEmpty(params['workflowName']);
      final customId = _valueOrEmpty(params['customId']);
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            workflow.isEmpty
                ? 'Listen for a select menu'
                : 'Select ${customId.isEmpty ? '' : customId} -> $workflow'
                    .trim(),
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
    case BotCreatorActionType.listenForModalSubmit:
      final workflow = _valueOrEmpty(params['workflowName']);
      final customId = _valueOrEmpty(params['customId']);
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            workflow.isEmpty
                ? 'Listen for a modal submit'
                : 'Modal ${customId.isEmpty ? '' : customId} -> $workflow'
                    .trim(),
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
    case BotCreatorActionType.ifBlock:
      final variable = _valueOrEmpty(params['variable']);
      final operator = _valueOrEmpty(params['operator']);
      final compareValue = _valueOrEmpty(params['value']);
      final thenCount = _countNestedActions(params['thenActions']);
      final elseCount = _countNestedActions(params['elseActions']);
      final elseIfCount = (params['elseIfConditions'] as List?)?.length ?? 0;
      final condition = [
        if (variable.isNotEmpty) variable,
        if (operator.isNotEmpty) operator,
        if (compareValue.isNotEmpty) compareValue,
      ].join(' ');
      return ActionSummaryData(
        title: action.type.displayName,
        summary: condition.isEmpty ? 'Conditional branch' : 'If $condition',
        outputKey: outputKey,
        isEnabled: action.enabled,
        meta: ifList(<String>[
          if (thenCount > 0) '$thenCount then',
          if (elseIfCount > 0) '$elseIfCount else-if',
          if (elseCount > 0) '$elseCount else',
        ]),
      );
    case BotCreatorActionType.stopUnless:
      final variable = _valueOrEmpty(params['variable']);
      final operator = _valueOrEmpty(params['operator']);
      final compareValue = _valueOrEmpty(params['value']);
      final condition = [
        if (variable.isNotEmpty) variable,
        if (operator.isNotEmpty) operator,
        if (compareValue.isNotEmpty) compareValue,
      ].join(' ');
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            condition.isEmpty
                ? 'Guard the workflow'
                : 'Continue only if $condition',
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
    case BotCreatorActionType.httpRequest:
      final method =
          _valueOrEmpty(params['method']).isEmpty
              ? 'GET'
              : _valueOrEmpty(params['method']).toUpperCase();
      final url = _preview(params['url'], maxLength: 56);
      return ActionSummaryData(
        title: action.type.displayName,
        summary: url.isEmpty ? '$method request' : '$method $url',
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
    default:
      final nonEmptyFields = <String>[];
      for (final entry in params.entries) {
        if (entry.key == 'key') {
          continue;
        }
        final preview = _preview(entry.value);
        if (preview.isEmpty) {
          continue;
        }
        nonEmptyFields.add('${entry.key}: $preview');
        if (nonEmptyFields.length == 2) {
          break;
        }
      }
      return ActionSummaryData(
        title: action.type.displayName,
        summary:
            nonEmptyFields.isEmpty
                ? 'Configure ${action.type.displayName.toLowerCase()}'
                : nonEmptyFields.join(' | '),
        outputKey: outputKey,
        isEnabled: action.enabled,
      );
  }
}

List<String> ifList(List<String> values) =>
    values.where((value) => value.trim().isNotEmpty).toList(growable: false);

int _countNestedActions(dynamic raw) {
  if (raw is! List) {
    return 0;
  }
  return raw.whereType<Map>().length;
}

String _valueOrEmpty(dynamic value) => (value ?? '').toString().trim();

String _preview(dynamic value, {int maxLength = 48}) {
  final text = (value ?? '').toString().trim();
  if (text.isEmpty) {
    return '';
  }
  final normalized = text.replaceAll('\n', ' ');
  if (normalized.length <= maxLength) {
    return normalized;
  }
  return '${normalized.substring(0, maxLength - 1)}...';
}
