# JavaScript Execution Mode Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Add JavaScript as a third execution mode (alongside BDFD and Visual Block) in Bot Creator, using flutter_js (QuickJS) runtime.

**Architecture:** JS scripts execute in a QuickJS runtime via flutter_js. A single message-based bridge (`sendMessage`/`onMessage`) connects JS to Dart. The Dart side dispatches to the existing `handleActions` pipeline. Functions are auto-generated from `allBdfdFunctions` registry.

**Tech Stack:** flutter_js ^0.8.7, QuickJS (Linux/Windows/Android) / JavaScriptCore (iOS/macOS), Dart 3.12+

---

## Phase 1: JS Runtime Bridge (shared + app)

### Task 1.1: Add flutter_js dependency
**Files:**
- Modify: `packages/app/pubspec.yaml`

Add under dependencies:
```yaml
  flutter_js: ^0.8.7
```

Then `cd packages/app && flutter pub get`

### Task 1.2: Create JsRuntimeBridge class
**Files:**
- Create: `packages/app/lib/features/js_engine/js_runtime_bridge.dart`

Complete class that:
1. Wraps `JavascriptRuntime` from flutter_js
2. Has a single `onMessage('bc', handler)` for the action bridge
3. Auto-injects the JS preamble with `_bc()` function and auto-generated wrappers
4. Handles Promise resolution: JS creates Promise, Dart resolves it via evaluate()
5. Injects context (authorId, channelId, etc.) and variables before user script
6. Has timeout protection (30s)
7. Has dispose() for cleanup

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_js/flutter_js.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'js_preamble.dart' as preamble;

class JsExecutionContext {
  final String authorId;
  final String channelId;
  final String? guildId;
  final String authorUsername;
  final bool isAdmin;
  final Map<String, String> args;
  final Map<String, String> variables;
  // ...
}

typedef JsActionHandler = Future<Map<String, dynamic>> Function(
  String actionType,
  Map<String, dynamic> payload,
);

class JsRuntimeBridge {
  JavascriptRuntime? _runtime;
  JsActionHandler? _actionHandler;
  bool _disposed = false;

  bool get isReady => _runtime != null && !_disposed;

  Future<void> init() async {
    _runtime = getJavascriptRuntime(xhr: false);
    _runtime!.onMessage('bc', _handleBcMessage);
    _injectPreamble();
  }

  void _injectPreamble() {
    final functionNames = allBdfdFunctions.toList();
    _runtime!.evaluate(preamble.build(functionNames));
  }

  Future<JsEvalResult> execute(String userScript, JsExecutionContext ctx) async {
    // Inject context
    _runtime!.evaluate('var _bc_ctx = ${jsonEncode(ctx.toJson())};');
    // Execute user script wrapped in async IIFE
    return _runtime!.evaluateAsync('''
      (async () => {
        try {
          ${userScript}
        } catch (e) {
          return { _bc_error: e.message || String(e) };
        }
      })()
    ''');
  }

  void _handleBcMessage(dynamic rawArgs) {
    // Parse, dispatch to _actionHandler, resolve JS promise
  }

  void dispose() {
    _disposed = true;
    _runtime?.dispose();
  }
}
```

### Task 1.3: Create JS preamble
**Files:**
- Create: `packages/app/lib/features/js_engine/js_preamble.dart`

```dart
String build(List<String> functionNames) {
  final namesJson = jsonEncode(functionNames);
  return '''
// Bridge unique
const _bc_pending = {};
let _bc_id = 0;
function _bc(type, payload) {
  return new Promise((resolve, reject) => {
    const id = String(++_bc_id);
    _bc_pending[id] = { resolve, reject };
    sendMessage('bc', JSON.stringify({ id, type, payload }));
  });
}

// Auto-génération des wrappers
const _BC_FUNCTIONS = $namesJson;
for (const fn of _BC_FUNCTIONS) {
  globalThis[fn] = (...args) => _bc(fn, { args });
}

// Helpers synchrones (pas besoin de bridge)
const ctx = _bc_ctx || {};
''';
}
```

### Task 1.4: Create JsActionExecutor in shared
**Files:**
- Create: `packages/shared/lib/engine/js_action_executor.dart`

```dart
import '../types/action.dart';
import '../actions/handler.dart';
import '../utils/template_resolver.dart';

class JsActionExecutor {
  Future<Map<String, dynamic>> execute({
    required NyxxGateway client,
    required Interaction? interaction,
    required String botId,
    required BotDataStore store,
    required Map<String, String> variables,
    required String Function(String) resolveTemplate,
    // ...
  }) async {
    // Reçoit { type: 'sendMessage', payload: {args: ['123', 'hello']} }
    // Convertit en Action et dispatch via handleActions
  }
}
```

---

## Phase 2: Integration (app)

### Task 2.1: Wire JsRuntimeBridge into bot testing flow
**Files:**
- Modify: `packages/app/lib/core/storage/sqlite_variable_store.dart` (or wherever bot test commands run)

Add a path that checks `executionMode == 'javascript'` and uses `JsRuntimeBridge` instead of BDFD compiler.

### Task 2.2: Add 'javascript' to executionMode
**Files:**
- Modify: `packages/app/lib/features/bot_editor/logic/command_editor_state.dart:41`
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart`

```dart
// In the UI, execution mode selector gets third option
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'workflow', label: Text('Visual')),
    ButtonSegment(value: 'bdfd_script', label: Text('BDFD')),
    ButtonSegment(value: 'javascript', label: Text('JavaScript')),
  ],
  selected: {state.executionMode},
  onSelectionChanged: (v) => notifier.setExecutionMode(v.first),
),
```

### Task 2.3: Create JS code editor page
**Files:**
- Create: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.js.dart`

Simple code editor with:
- TextField (multiline, monospace font)
- Validation: basic JS syntax check via flutter_js
- Quick reference panel (list of available functions)

---

## Phase 3: Auto-generation & Polish

### Task 3.1: Generate JS function registry from allBdfdFunctions
Already done via `js_preamble.dart` which consumes `allBdfdFunctions` at runtime.

### Task 3.2: Add error handling
- JS syntax errors → show in editor
- Runtime errors → show in bot logs
- Timeout → cancel execution after 30s

### Task 3.3: Test the full flow
- Create a bot with a JS command
- Test via the app's built-in testing
- Verify variables, context injection, function calls all work
