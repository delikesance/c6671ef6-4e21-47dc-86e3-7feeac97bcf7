import '../../../types/action.dart';
import '../runtime.dart' show BdfdContext;

/// Marks, inside the `path` of a nested action, "the current iteration of loop
/// <id>". The translator cannot know the iteration, so it writes the marker and
/// [VisualFlowState.resolvePath] turns it into `iter<N>` at run time: the
/// results of an iteration live under `<loopKey>.iter<N>.<childKey>`.
const String visualIterationMarker = '\u0001iter:';

/// How many visual programs are executing on a [BdfdContext]. The interpreter
/// counts them in its depth; a script started from one is still the outermost
/// *script* when the depth equals this count.
final Expando<int> visualProgramDepth = Expando<int>('visual program depth');

/// Closures the historical loop owns and that `runWorkflow`, `runBdfdScript`
/// and `ifBlock.suppressErrors` need: the same ones `executeControlFlowAction`
/// receives, so the native path runs the very same workflow/script code.
class VisualControlAdapter {
  VisualControlAdapter({
    required this.activeWorkflowStack,
    required this.getWorkflowByName,
    required this.executeActions,
    required this.executeProtectedActions,
    this.executeNativeBdfdScript,
    this.nestedActionsPreprocessor,
  });

  final Set<String> activeWorkflowStack;
  final Future<Map<String, dynamic>?> Function(String workflowName)
  getWorkflowByName;
  final Future<Map<String, String>> Function(List<Action> actions)
  executeActions;
  final Future<Map<String, String>> Function(List<Action> actions)
  executeProtectedActions;
  final Future<Map<String, String>> Function(String source)?
  executeNativeBdfdScript;
  final List<Action> Function(List<Action>)? nestedActionsPreprocessor;
}

enum VisualLoopKind { simple, list, cstyle, json }

/// Run-time state of one active `forLoop` / `jsonForEachLoop`. The loop is a
/// native `$while` whose condition (`bc_loopnext`) advances this state: it
/// publishes the `_loop.*` variables before each iteration and the loop's own
/// result and variable clean-up when it ends.
class VisualLoopState {
  VisualLoopState({
    required this.id,
    required this.key,
    required this.kind,
    required this.parentPath,
    required this.cleanup,
  });

  final String id;
  final String key;
  final VisualLoopKind kind;

  /// Resolved path of the list that contains the loop action.
  final List<String> parentPath;

  /// Variables removed when the loop ends.
  final List<String> cleanup;

  /// Iterations entered so far.
  int entered = 0;
  int count = 0;
  String varName = '';
  List<String> values = const [];
  List<MapEntry<String, String>> entries = const [];
  Map<String, int> vars = {};
  String conditionTemplate = '';
  String updateTemplate = '';
  List<String> cstyleNames = const [];
  bool finished = false;
}

/// One action recorded by a `debugProfile` list (see `debug_profile_actions.dart`).
class VisualProfileEntry {
  const VisualProfileEntry({
    required this.actionType,
    required this.startMs,
    required this.endMs,
    this.result,
    this.loopDepth,
    this.loopIteration,
  });

  final String actionType;
  final int startMs;
  final int endMs;
  final String? result;
  final int? loopDepth;
  final int? loopIteration;
}

/// The trace of one action list that ran `debugProfile`: a stopwatch started at
/// the action, one entry per later action of THAT list (a nested block's own
/// list has its own profile, as every list had its own state historically) and
/// the compilation metadata of the action. The embed is sent when the list ends.
class VisualListProfile {
  VisualListProfile({
    required this.elapsedMs,
    this.compilationMs,
    this.sourceLength,
    this.actionCount,
  });

  /// Milliseconds since `debugProfile` ran.
  final int Function() elapsedMs;
  final int? compilationMs;
  final int? sourceLength;
  final int? actionCount;
  final List<VisualProfileEntry> entries = [];
}

/// Mutable bookkeeping of the control-flow blocks of one visual execution.
class VisualFlowState {
  VisualControlAdapter? adapter;

  /// Updates `execution.time` like the historical loop does before each action.
  void Function()? refreshExecutionTime;

  /// Real delay of `wait` (the historical executor uses `Future.delayed`).
  Future<void> Function(Duration duration)? delay;

  /// A single top-level action is being run for the historical loop, which
  /// owns what happens next: stop/skip/jump are handed back to it as the
  /// `__stopped__` / `__skipCount__` / `__jumpToTargetKey__` signals of its
  /// results instead of being applied to the (one-statement) program.
  bool routed = false;

  /// Active `debugProfile` lists, by resolved list path ([profileKey]).
  final Map<String, VisualListProfile> profiles = {};

  static String profileKey(List<String> path) => path.join('\u0000');

  /// A root `jumpToAction` to a position that is not after it: the 0-based
  /// index the runner restarts the root list from (consumed by the runner).
  int? restartAt;

  final Map<String, VisualLoopState> loops = {};
  final Map<String, int> iterations = {};
  final Map<String, Map<String, String>> savedErrors = {};

  /// Synthetic source -> line -> (result key, action type), for replay frames.
  final Map<String, Map<int, ({String key, String type})>> replayRefs = {};

  /// Forget the state of a previous program.
  void reset() {
    loops.clear();
    iterations.clear();
    profiles.clear();
    savedErrors.clear();
  }

  /// Replace iteration markers by `iter<N>`.
  List<String> resolvePath(List<String> raw) {
    if (!raw.any((e) => e.startsWith(visualIterationMarker))) return raw;
    return List.unmodifiable([
      for (final element in raw)
        element.startsWith(visualIterationMarker)
            ? 'iter${iterations[element.substring(visualIterationMarker.length)] ?? 0}'
            : element,
    ]);
  }

  /// Forget the loops living at or under [prefix] (a block that failed and was
  /// caught: its loops never ended normally).
  void dropLoopsUnder(List<String> prefix) {
    loops.removeWhere((_, state) {
      if (state.parentPath.length < prefix.length) return false;
      for (var i = 0; i < prefix.length; i++) {
        if (state.parentPath[i] != prefix[i]) return false;
      }
      return true;
    });
  }
}
