import 'dart:convert';

import '../../../actions/send_message.dart' show sendMessageToChannel;
import '../../../types/action.dart';
import '../runtime.dart';
import 'action_environment.dart';
import 'control_flow_state.dart';
import 'message_actions.dart' show visualResolvedFallbackChannel;

/// `debugProfile` on the native runner.
///
/// The action starts a profile for the action list it belongs to (the root list
/// or the body of a block: every list has its own, as every list had its own
/// `handleActions` state). The wrapper of every later `bc_*` call of that list
/// adds an entry (type, offsets, result, loop depth/iteration read from the
/// payload, error entries included). The translator ends every list that owns
/// an enabled `debugProfile` with `bc_profileend`, which sends the embed; a
/// list that stops (a `stop`, a failure) ends before it and sends nothing.

/// Hidden end-of-list function appended by the translator.
const String bdfdVisualProfileEndFunction = 'bc_profileend';

final Map<BotCreatorActionType, ActionHandler> debugProfileActionHandlers = {
  BotCreatorActionType.debugProfile: debugProfileAction,
};

final Map<BotCreatorActionType, bool Function(Action)>
debugProfileLeafPredicates = {BotCreatorActionType.debugProfile: (_) => true};

/// A real stopwatch started now, as milliseconds elapsed.
int Function() _stopwatchClock() {
  final stopwatch = Stopwatch()..start();
  return () => stopwatch.elapsedMilliseconds;
}

Future<String?> debugProfileAction(ActionCall call) async {
  final env = call.env;
  // Restarts: a second `debugProfile` of the same list begins a new trace.
  env.flow.profiles[VisualFlowState.profileKey(call.path)] = VisualListProfile(
    elapsedMs: (env.startProfileClock ?? _stopwatchClock)(),
    compilationMs: call.payload['compilationMs'] as int?,
    sourceLength: call.payload['sourceLength'] as int?,
    actionCount: call.payload['actionCount'] as int?,
  );
  return null; // No result, no trace entry of its own.
}

/// The text lines of the embed description (the historical formatting).
List<String> debugTraceLines(List<VisualProfileEntry> trace) {
  final lines = <String>[];
  int? currentLoopIteration;
  for (var t = 0; t < trace.length; t++) {
    final entry = trace[t];
    final durationMs = entry.endMs - entry.startMs;
    final status = entry.result?.startsWith('Error:') == true ? '❌' : '✅';
    // Show loop iteration header when entering a new iteration
    if (entry.loopDepth != null &&
        entry.loopIteration != currentLoopIteration) {
      currentLoopIteration = entry.loopIteration;
      lines.add('─ **\$for** iteration $currentLoopIteration');
    } else if (entry.loopDepth == null && currentLoopIteration != null) {
      currentLoopIteration = null;
    }
    final indent = entry.loopDepth != null ? ' ' : '';
    lines.add(
      '$indent`${t + 1}.` $status **${entry.actionType}** — +${entry.startMs}ms (${durationMs}ms)',
    );
  }
  return lines;
}

/// The `Debug Trace` embed of [profile] ended after [totalMs].
Map<String, dynamic> debugTraceEmbed(VisualListProfile profile, int totalMs) {
  final traceLines = debugTraceLines(profile.entries);
  final compilationField = profile.compilationMs != null
      ? {
          'name': '⚙️ Compilation',
          'value':
              '${profile.compilationMs}ms • ${profile.sourceLength ?? '?'} chars • ${profile.actionCount ?? '?'} actions',
          'inline': false,
        }
      : null;
  final description = traceLines.isEmpty
      ? '_No actions executed after \$debug._'
      : traceLines.join('\n');
  return <String, dynamic>{
    'title': '🔍 Debug Trace',
    'description': description,
    'color': 0xFF9800,
    if (compilationField != null) 'fields': [compilationField],
    'footer': {
      'text': 'Total: ${totalMs}ms • ${profile.entries.length} action(s)',
    },
  };
}

/// `bc_profileend[path]`: the list that owns a profile reached its end.
Map<String, BdfdNativeFunction> bdfdVisualProfileFunctions(
  ActionRunEnvironment env,
) => {
  bdfdVisualProfileEndFunction: BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async {
      final raw = jsonDecode(await call.argument(0));
      final path = env.flow.resolvePath([
        if (raw is List) ...raw.map((e) => e.toString()),
      ]);
      final profile = env.flow.profiles.remove(
        VisualFlowState.profileKey(path),
      );
      final channelId = visualResolvedFallbackChannel(env);
      final client = env.client;
      if (profile == null || channelId == null || client == null) return '';
      try {
        await sendMessageToChannel(
          client,
          channelId,
          content: '',
          payload: <String, dynamic>{
            'embeds': [debugTraceEmbed(profile, profile.elapsedMs())],
          },
        );
      } catch (_) {
        // Best-effort: don't fail the command if the debug embed fails
      }
      return '';
    },
  ),
};
