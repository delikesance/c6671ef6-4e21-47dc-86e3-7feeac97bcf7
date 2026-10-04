import '../../../types/action.dart';
import '../../../utils/component_runtime.dart';
import '../replay.dart' show snapshotReplayVariables;
import 'action_environment.dart';
import 'control_flow_state.dart';

/// The payload of an action of the ROOT list as the native runner hands it to
/// its handler. The component definitions get their typed runtime fields
/// resolved (`resolveComponentRuntimeFields`), a `respondWithModal` without a
/// `modal` key has its whole payload resolved: what the historical loop did to
/// each action before its executor ran. Handlers resolve the payload of nested
/// actions themselves (`visualMessagePayload`).
Map<String, dynamic> rootActionPayload(
  BotCreatorActionType type,
  Map<String, dynamic> payload,
  String Function(String) resolve,
) {
  final out = Map<String, dynamic>.from(payload);
  for (final key in const ['components', 'componentV2', 'modal']) {
    final definition = out[key];
    if (definition is Map) {
      out[key] = resolveComponentRuntimeFields(
        Map<String, dynamic>.from(definition),
        resolve,
      );
    }
  }
  if (type == BotCreatorActionType.respondWithModal &&
      !out.containsKey('modal')) {
    return resolveComponentRuntimeFields(out, resolve);
  }
  return out;
}

/// What the runner observes around one `bc_<type>` call: the frame handed to
/// the execution policy and the entry of the enclosing list's `debugProfile`
/// trace. Neither exists unless a policy or a profile is active.
class VisualActionObservation {
  VisualActionObservation._(
    this.env,
    this.type,
    this.path,
    this.payload,
    this.profile,
    this.startMs,
    this.before,
  );

  final ActionRunEnvironment env;
  final BotCreatorActionType type;
  final List<String> path;
  final Map<String, dynamic> payload;
  final VisualListProfile? profile;
  final int? startMs;
  final Map<String, String>? before;

  /// [withPolicy] false when a historical loop owns the action's frame.
  factory VisualActionObservation.begin(
    ActionRunEnvironment env,
    BotCreatorActionType type,
    String key,
    List<String> path,
    Map<String, dynamic> payload, {
    required bool withPolicy,
  }) {
    // `debugProfile` itself is never part of its own trace.
    if (path.isEmpty) env.flow.rootAction = (key: key, type: type.name);
    final profile = type == BotCreatorActionType.debugProfile
        ? null
        : env.flow.profiles[VisualFlowState.profileKey(path)];
    final policy = withPolicy ? env.policy : null;
    if (policy != null && path.isEmpty) {
      env.flow.rootBefore = snapshotReplayVariables(env.variables);
    }
    return VisualActionObservation._(
      env,
      type,
      path,
      payload,
      profile,
      profile?.elapsedMs(),
      policy == null ? null : snapshotReplayVariables(env.variables),
    );
  }

  /// Record the finished action (`result` is what its list holds for it, or
  /// `Error: ...`).
  void finish(String? result) {
    final policy = before == null ? null : env.policy;
    policy?.record({
      'actionType': type.name,
      'result': result,
      'variablesBefore': before,
      'variablesAfter': snapshotReplayVariables(env.variables),
    });
    final profile = this.profile;
    if (profile != null) {
      profile.entries.add(
        VisualProfileEntry(
          actionType: type.name,
          startMs: startMs ?? 0,
          endMs: profile.elapsedMs(),
          result: result,
          loopDepth: payload['_debugLoopDepth'] as int?,
          loopIteration: payload['_debugLoopIteration'] as int?,
        ),
      );
    }
  }

  /// Whether this action records its numeric result as the "last message" even
  /// though its historical counterpart only traced under profiling.
  bool get profiling =>
      profile != null || (path.isEmpty && env.replayCapturing);
}

// ---------------------------------------------------------------------------
// Blocks
// ---------------------------------------------------------------------------

bool _under(List<String> path, List<String> base) {
  if (path.length < base.length) return false;
  for (var i = 0; i < base.length; i++) {
    if (path[i] != base[i]) return false;
  }
  return true;
}

/// A block of the list at [path] starts. Records the blocks that are over.
void beginBlock(
  ActionRunEnvironment env,
  List<String> path,
  String key,
  String type, {
  required bool withPolicy,
}) {
  flushBlocksBefore(env, path);
  if (path.isEmpty) env.flow.rootAction = (key: key, type: type);
  final profile = env.flow.profiles[VisualFlowState.profileKey(path)];
  final policy = withPolicy ? env.policy : null;
  if (policy != null && path.isEmpty) {
    env.flow.rootBefore = snapshotReplayVariables(env.variables);
  }
  if (profile == null && policy == null) return;
  env.flow.pendingBlocks.add(
    VisualPendingBlock(
      path: path,
      key: key,
      type: type,
      startMs: profile?.elapsedMs(),
      before: policy == null ? null : snapshotReplayVariables(env.variables),
    ),
  );
}

/// An action or block of the list at [path] is about to run: every pending
/// block that does not contain it is over.
void flushBlocksBefore(ActionRunEnvironment env, List<String> path) {
  final pending = env.flow.pendingBlocks;
  for (var i = pending.length - 1; i >= 0; i--) {
    final block = pending[i];
    if (!_under(path, [...block.path, block.key])) _record(env, i);
  }
}

/// The list at [path] ends: every pending block of it (or below) is over.
void flushBlocksOf(ActionRunEnvironment env, List<String> path) {
  final pending = env.flow.pendingBlocks;
  for (var i = pending.length - 1; i >= 0; i--) {
    if (_under(pending[i].path, path)) _record(env, i);
  }
}

/// The program ended (or failed with [error]): every pending block is over.
void flushAllBlocks(ActionRunEnvironment env, {Object? error}) {
  final pending = env.flow.pendingBlocks;
  for (var i = pending.length - 1; i >= 0; i--) {
    if (error != null) pending[i].error ??= 'Error: $error';
    _record(env, i);
  }
}

/// The block [key] of the list at [path] failed and its error mode took over.
void failBlock(
  ActionRunEnvironment env,
  List<String> path,
  String key,
  Object error,
) {
  for (final block in env.flow.pendingBlocks) {
    if (block.key == key && _pathEquals(block.path, path)) {
      block.error = 'Error: $error';
    }
  }
}

bool _pathEquals(List<String> a, List<String> b) =>
    a.length == b.length && _under(a, b);

void _record(ActionRunEnvironment env, int index) {
  final block = env.flow.pendingBlocks.removeAt(index);
  final result = block.error ?? env.sink.peek(block.path, block.key);
  if (block.before != null) {
    env.policy?.record({
      'actionType': block.type,
      'result': result,
      'variablesBefore': block.before,
      'variablesAfter': snapshotReplayVariables(env.variables),
    });
  }
  final profile = env.flow.profiles[VisualFlowState.profileKey(block.path)];
  if (profile != null && block.startMs != null) {
    profile.entries.add(
      VisualProfileEntry(
        actionType: block.type,
        startMs: block.startMs!,
        endMs: profile.elapsedMs(),
        result: result,
      ),
    );
  }
}
