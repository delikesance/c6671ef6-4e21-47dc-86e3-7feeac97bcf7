part of 'bot.dart';

// Les modèles (`DebugActionFrame`, `DebugReplayRecord`) vivent dans `bot_creator_ui` :
// le Studio rejoue les mêmes. `bot.dart` les ré-exporte.

// ─── In-memory store (main isolate) ──────────────────────────────────────────

const String _debugReplayEnabledDataKey = 'debugReplayEnabled';
bool _debugReplayCapturing = false;

final List<DebugReplayRecord> _debugReplays = <DebugReplayRecord>[];
final StreamController<List<DebugReplayRecord>> _debugReplaysController =
    StreamController<List<DebugReplayRecord>>.broadcast();

const int _maxDebugReplays = 30;

bool get isDebugReplayCapturing => _debugReplayCapturing;

Stream<List<DebugReplayRecord>> get debugReplaysStream =>
    _debugReplaysController.stream;

List<DebugReplayRecord> get debugReplays =>
    List<DebugReplayRecord>.unmodifiable(_debugReplays);

void setDebugReplayCapturing(bool enabled) {
  _debugReplayCapturing = enabled;
  unawaited(_persistDebugReplayCapturing(enabled));
  unawaited(syncMobileDebugFlagsWithService());
}

Future<void> _persistDebugReplayCapturing(bool enabled) async {
  try {
    await FlutterForegroundTask.saveData(
      key: _debugReplayEnabledDataKey,
      value: enabled,
    );
  } catch (_) {}
}

Future<void> loadDebugReplayCapturingState() async {
  try {
    final saved = await FlutterForegroundTask.getData<dynamic>(
      key: _debugReplayEnabledDataKey,
    );
    _debugReplayCapturing = saved == true;
  } catch (_) {
    _debugReplayCapturing = false;
  }
}

void appendDebugReplay(DebugReplayRecord record) {
  _debugReplays.insert(0, record);
  if (_debugReplays.length > _maxDebugReplays) {
    _debugReplays.removeRange(_maxDebugReplays, _debugReplays.length);
  }
  if (!_debugReplaysController.isClosed) {
    _debugReplaysController.add(
      List<DebugReplayRecord>.unmodifiable(_debugReplays),
    );
  }
}

void clearDebugReplays() {
  _debugReplays.clear();
  if (!_debugReplaysController.isClosed) {
    _debugReplaysController.add(const <DebugReplayRecord>[]);
  }
}

// ─── Service-isolate → main-isolate bridge ───────────────────────────────────
