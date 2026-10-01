import '../types/action.dart';

/// Optional execution boundary. Applied before every action, including nested
/// scripts/workflows. The production runtime has no policy by default.
abstract class ActionExecutionPolicy {
  bool get allowDiscordHydration;
  void checkBudget();
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  });
  void record(Map<String, dynamic> frame);
}
