import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'variables_test_helpers.dart';

/// Parity harness of visual actions: the same actions run through the
/// historical executors (`ActionTranslator.none()`) and the native engine over
/// the same simulated Discord, then recorded effects, `results`, final
/// variables and errors are compared.

class SpyTranslator extends ActionTranslator {
  SpyTranslator() : super();
  int native = 0;
  @override
  BdfdActionProgram translate(
    List<Action> actions, {
    int firstIndex = 0,
    bool topLevelErrorModes = true,
  }) {
    native++;
    return super.translate(
      actions,
      firstIndex: firstIndex,
      topLevelErrorModes: topLevelErrorModes,
    );
  }
}

class NoHydrationPolicy implements ActionExecutionPolicy {
  @override
  bool get allowDiscordHydration => false;
  @override
  void checkBudget() {}
  @override
  void record(Map<String, dynamic> frame) {}
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async => false;
}

class Outcome<G extends NyxxGateway> {
  Outcome(
    this.gateway,
    this.results,
    this.variables,
    this.error,
    this.native,
    this.effects,
  );
  final G gateway;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final int native;
  final Object? effects;

  String? get errorText => error == null
      ? null
      : '${error.runtimeType}: ${error is CommandExecutionTimeout ? 'timeout' : error}';
}

Action visualAction(
  BotCreatorActionType type, {
  String? key,
  Map<String, dynamic> payload = const {},
  Map<String, String> error = const {},
  bool enabled = true,
}) =>
    Action(type: type, key: key, enabled: enabled, payload: payload)
      ..error.addAll(error);

Future<Outcome<G>> _execute<G extends NyxxGateway>(
  List<Action> actions, {
  required bool native,
  required G Function() makeGateway,
  required Object? Function(G gateway) effects,
  void Function(G gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  Duration? limit,
  BotDataStore Function()? makeStore,
  Snowflake? fallbackChannelId,
}) async {
  final gateway = makeGateway();
  setup?.call(gateway);
  final values = <String, String>{
    'guild.id': '10',
    'bot.id': '500',
    ...?variables,
  };
  final spy = SpyTranslator();
  Map<String, String>? results;
  Object? error;
  try {
    results = await handleActions(
      gateway,
      null,
      actions: actions,
      store: makeStore?.call() ?? MemoryBotDataStore(),
      botId: 'bot',
      variables: values,
      fallbackGuildId: guild ? Snowflake(10) : null,
      fallbackChannelId: fallbackChannelId,
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      executionPolicy: policy,
      throwOnError: throwOnError,
      executionBudget: limit == null
          ? null
          : CommandExecutionBudget(limit: limit),
      actionTranslator: native ? spy : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  }
  values.remove('execution.time');
  return Outcome<G>(
    gateway,
    results,
    values,
    error,
    spy.native,
    effects(gateway),
  );
}

/// Runs both paths and compares everything observable. Returns the native
/// outcome.
Future<Outcome<G>> visualParity<G extends NyxxGateway>(
  List<Action> actions, {
  required G Function() makeGateway,
  required Object? Function(G gateway) effects,
  void Function(G gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  Duration? limit,
  BotDataStore Function()? makeStore,
  Snowflake? fallbackChannelId,
  bool expectNative = true,
  int? nativePrograms,
}) async {
  Future<Outcome<G>> run(bool native) => _execute<G>(
    // Action objects are rebuilt from JSON: no state shared between the runs.
    actions.map((a) => Action.fromJson(a.toJson())).toList(),
    native: native,
    makeGateway: makeGateway,
    effects: effects,
    setup: setup,
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    policy: policy,
    limit: limit,
    makeStore: makeStore,
    fallbackChannelId: fallbackChannelId,
  );
  final historical = await run(false);
  final native = await run(true);
  expect(historical.native, 0);
  if (nativePrograms != null) {
    expect(native.native, nativePrograms);
  } else if (expectNative) {
    expect(native.native, greaterThan(0), reason: 'must run natively');
  } else {
    expect(native.native, 0, reason: 'must stay historical');
  }
  expect(native.effects, historical.effects, reason: 'effects');
  expect(native.results, historical.results, reason: 'results');
  expect(native.variables, historical.variables, reason: 'variables');
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}
