import 'package:http/http.dart' as http;

import '../../engine/bdfd/visual/http_logic.dart';
import '../../engine/execution_budget.dart';
import '../../services/http_service.dart';
import '../../types/action.dart';

/// Historical delegator; the logic lives in
/// `engine/bdfd/visual/http_logic.dart`.
Future<bool> executeHttpAction({
  required BotCreatorActionType type,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  required void Function(String message)? onLog,
  required Future<void> Function(String key, String value) setGlobalVariable,
  http.Client? httpClient,
  HttpService? httpService,
  CommandExecutionBudget? executionBudget,
}) => executeHttp(
  type: type,
  payload: payload,
  resultKey: resultKey,
  results: results,
  variables: variables,
  resolveValue: resolveValue,
  onLog: onLog,
  setGlobalVariable: setGlobalVariable,
  httpClient: httpClient,
  httpService: httpService,
  executionBudget: executionBudget,
);
