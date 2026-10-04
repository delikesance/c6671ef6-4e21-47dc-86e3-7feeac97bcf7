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
    List<String> path,
    Map<String, dynamic> payload, {
    required bool withPolicy,
  }) {
    // `debugProfile` itself is never part of its own trace.
    final profile = type == BotCreatorActionType.debugProfile
        ? null
        : env.flow.profiles[VisualFlowState.profileKey(path)];
    final policy = withPolicy ? env.policy : null;
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
