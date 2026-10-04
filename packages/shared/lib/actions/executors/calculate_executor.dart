import '../../engine/bdfd/visual/calculate_logic.dart';
import '../../types/action.dart';

/// Historical delegator; the logic lives in
/// `engine/bdfd/visual/calculate_logic.dart`.
Future<bool> executeCalculateAction({
  required BotCreatorActionType type,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
}) => executeCalculate(
  type: type,
  payload: payload,
  resultKey: resultKey,
  results: results,
  variables: variables,
  resolveValue: resolveValue,
);
