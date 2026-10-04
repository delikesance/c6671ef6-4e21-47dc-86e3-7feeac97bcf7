import 'dart:math' as math;

import '../../../types/action.dart';
import '../program.dart';
import '../runtime.dart';
import 'action_functions.dart';
import 'action_translator.dart';
import 'control_flow_actions.dart' show visualBlockTypes;
import 'control_flow_state.dart' show visualProgramDepth;

/// Default step limit of one translated program.
/// Steps: every statement, function call and argument the interpreter evaluates
/// counts as one. Visual blocks historically had only the 15 minute budget;
/// [maxSteps] adds a guard against runaway loops (a C-style loop whose
/// condition never fails would otherwise spin, and grow the results, until the
/// budget ends). A loop iteration costs a handful of steps plus about five per
/// action in its body, so the default admits roughly 100 000 iterations of a
/// one-action body: far beyond what a command does within its budget (each
/// action is usually a Discord call), yet it stops a runaway loop within
/// seconds. The limit applies to each translated program, on top of the host
/// context's own (a script's 100 000) when that is closer.
const int defaultVisualMaxSteps = 1000000;

/// Runs visual actions on the native interpreter.
///
/// The interpreter is private to the runner: a [BdfdRuntime] holding only the
/// core language and the hidden `bc_*` functions of the execution's
/// [ActionRunEnvironment]. It shares the caller's [BdfdContext], so the budget
/// (one deadline for every nesting level), the step and depth limits, the JSON
/// document, the temporary variables and the response state are the ones the
/// rest of the execution already uses.
class BdfdActionRunner {
  const BdfdActionRunner({
    this.translator = const ActionTranslator(),
    this.maxSteps = defaultVisualMaxSteps,
  });

  final ActionTranslator translator;

  /// Step limit of each program run by this runner ([defaultVisualMaxSteps]).
  final int maxSteps;

  /// Whether the historical loop must hand [action] to [runAction].
  bool supports(Action action) => translator.supports(action);

  /// [supports], except that blocks stay historical under an execution policy:
  /// the policy intercepts actions one by one, which a native block's nested
  /// actions would bypass.
  bool routes(Action action, {bool underPolicy = false}) =>
      supports(action) &&
      !(underPolicy && visualBlockTypes.contains(action.type));

  /// Run one supported action of a list being executed by the historical loop
  /// ([index] is its position there). The loop keeps owning the action's own
  /// error mode, trace and replay frame: a failure is rethrown as the original
  /// exception (never the interpreter's wrapper) after the error bookkeeping,
  /// so the loop's handling is unchanged. Nested actions of an `ifBlock` follow
  /// their own error modes natively.
  Future<void> runAction(
    Action action, {
    required ActionRunEnvironment env,
    required BdfdContext context,
    required int index,
  }) async {
    final program = translator.translate(
      [action],
      firstIndex: index,
      topLevelErrorModes: false,
    );
    // The loop applies what a stop/skip/jump leaves in its results map (the
    // historical signals), because it owns the list this action belongs to.
    env.flow.routed = true;
    try {
      await _execute(program, env, context, nativeTrace: false);
    } on BdfdNativeError catch (error) {
      throw error.cause ?? error;
    } finally {
      env.flow.routed = false;
    }
  }

  /// Run a whole action list natively: one program, error modes included.
  /// [acknowledge] is called first when the list does not acknowledge the
  /// interaction itself (see [BdfdActionProgram.shouldAutoDefer]).
  /// Returns the list's `results`; a failure is rethrown as the original
  /// exception once its results and `error.*` variables are recorded.
  Future<Map<String, String>> run(
    List<Action> actions, {
    required ActionRunEnvironment env,
    required BdfdContext context,
    Future<void> Function({required bool ephemeral})? acknowledge,
  }) async {
    final program = translator.translate(actions);
    env.flow.routed = false;
    if (acknowledge != null && program.shouldAutoDefer) {
      await acknowledge(ephemeral: program.ephemeralHint);
    }
    try {
      await _execute(program, env, context);
    } on BdfdNativeError catch (error) {
      final cause = error.cause ?? error;
      // Like the historical enclosing handlers: the failure ends up on the
      // top-level action that contains the failing one.
      final ref = error.location.source == program.program.source
          ? program.refs[error.location.line]
          : null;
      if (ref != null) {
        final top = ref.topLevel
            ? ref
            : program.topLevel.firstWhere(
                (candidate) => candidate.key == ref.path.first,
                orElse: () => ref,
              );
        env.sink.recordError(top.action.type.name, top.key, const [], cause);
      }
      throw cause;
    }
    return env.sink.results;
  }

  Future<void> _execute(
    BdfdActionProgram program,
    ActionRunEnvironment env,
    BdfdContext context, {
    bool nativeTrace = true,
  }) async {
    final runtime = env.runtime ??= BdfdRuntime(
      functions: bdfdVisualFunctions(env),
    );
    env.flow.reset();
    env.flow.replayRefs[program.program.source] = {
      for (final entry in program.refs.entries)
        entry.key: (key: entry.value.key, type: entry.value.action.type.name),
    };
    // Tighten the step limit around this program only.
    final previousLimit = context.maxSteps;
    context.maxSteps = math.min(previousLimit, context.steps + maxSteps);
    // The program is not a script: keep the host script's draft output, its
    // pending canvas callbacks and (when routed) its replay observer out of it.
    final output = context.output;
    final trace = context.onTrace;
    final pending = List.of(context.beforeFlush);
    context.output = null;
    context.beforeFlush.clear();
    if (!nativeTrace && trace != null) {
      // The loop records a frame for the action it routed here; its nested
      // actions (and the script/workflow events they trigger) are only seen
      // natively.
      context.onTrace = (event) {
        final ref = event.kind == 'function'
            ? program.refs[event.location.line]
            : null;
        if (ref != null &&
            ref.topLevel &&
            event.location.source == program.program.source &&
            event.location.functionName ==
                bdfdVisualFunctionFor(ref.action.type)) {
          return;
        }
        trace(event);
      };
    }
    visualProgramDepth[context] = (visualProgramDepth[context] ?? 0) + 1;
    try {
      await runtime.executeProgram(program.program, context: context);
      env.sink.commit();
    } catch (_) {
      // Whatever the failing blocks had not published is lost, but a top-level
      // loop keeps the iterations it had finished (the historical loop wrote
      // them into the results as it went).
      env.sink.discard(const [], [
        for (final loop in env.flow.loops.values)
          if (loop.parentPath.isEmpty)
            for (var i = 0; i < loop.entered - 1; i++) [loop.key, 'iter$i'],
      ]);
      env.sink.commit();
      rethrow;
    } finally {
      visualProgramDepth[context] = (visualProgramDepth[context] ?? 1) - 1;
      context.maxSteps = previousLimit;
      context.output = output;
      context.onTrace = trace;
      context.beforeFlush
        ..clear()
        ..addAll(pending);
    }
  }
}
