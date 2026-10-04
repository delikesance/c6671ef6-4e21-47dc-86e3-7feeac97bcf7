import '../../../types/action.dart';
import '../program.dart';
import '../runtime.dart';
import 'action_functions.dart';
import 'action_translator.dart';

/// Runs visual actions on the native interpreter.
///
/// The interpreter is private to the runner: a [BdfdRuntime] holding only the
/// core language and the hidden `bc_*` functions of the execution's
/// [ActionRunEnvironment]. It shares the caller's [BdfdContext], so the budget
/// (one deadline for every nesting level), the step and depth limits, the JSON
/// document, the temporary variables and the response state are the ones the
/// rest of the execution already uses.
class BdfdActionRunner {
  const BdfdActionRunner({this.translator = const ActionTranslator()});

  final ActionTranslator translator;

  /// Whether the historical loop must hand [action] to [runAction].
  bool supports(Action action) => translator.supports(action);

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
    try {
      await _execute(program, env, context, nativeTrace: false);
    } on BdfdNativeError catch (error) {
      throw error.cause ?? error;
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
    // The program is not a script: keep the host script's draft output, its
    // pending canvas callbacks and (when routed) its replay observer out of it.
    final output = context.output;
    final trace = context.onTrace;
    final pending = List.of(context.beforeFlush);
    context.output = null;
    context.beforeFlush.clear();
    if (!nativeTrace) context.onTrace = null;
    try {
      await runtime.executeProgram(program.program, context: context);
      env.sink.commit();
    } catch (_) {
      env.sink.discard();
      rethrow;
    } finally {
      context.output = output;
      context.onTrace = trace;
      context.beforeFlush
        ..clear()
        ..addAll(pending);
    }
  }
}
