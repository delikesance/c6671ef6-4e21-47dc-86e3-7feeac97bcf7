# Smart Sync — Pull with Merge + Safety Push

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Add Pull from Cloud with command-level smart merge (timestamp-based), a confirmation dialog comparing remote vs local dates, and a safety check preventing empty config pushes.

**Architecture:** All changes are in the Flutter app side (no Go Manager changes needed — `getBotConfig` API already exists). New `_pullFromRemote` method compares `updatedAt` per-command, shows a diff dialog, then merges. `_pushToRemote` gains an emptiness safety check. New UI: Pull button next to existing Push in the Tools section.

**Tech Stack:** Dart/Flutter, existing `MainApiClient.getBotConfig()`, existing `database.dart` AppManager methods, existing i18n keys (`bot_home_pull`, `bot_home_pull_success`, `bot_home_push_success`).

---

## Phase 1: Pull + Smart Merge + Safety Push

### Task 1: Add `_isPullingApp` state variable

**Objective:** Add a boolean flag to track pull loading state (mirrors existing `_isPushingApp`)

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.dart:75`

**Step 1: Add the field**

After line 75 (`bool _isPushingApp = false;`), add:
```dart
bool _isPullingApp = false;
```

**Step 2: Verify compilation**

Run: `cd packages/app && flutter analyze lib/features/bot_editor/presentation/screens/bot_sub_pages/home.dart`
Expected: No new errors (just pre-existing ones if any)

---

### Task 2: Add `_pullFromRemote` method in home.sync.part.dart

**Objective:** Implement the pull logic: fetch remote config, compare timestamps, show dialog, merge commands smartly

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart` (append after `_pushToRemote`)

**Step 1: Write the method**

Add after `_pushToRemote` (after line 159):

```dart
Future<void> _pullFromRemote({required bool showSnack}) async {
  if (_isPullingApp) return;

  _setState(() => _isPullingApp = true);
  try {
    appendBotDebugLog('[_pullFromRemote] START');
    final user = await widget.client.user.get().timeout(const Duration(seconds: 10));
    final botId = user.id.toString();
    appendBotDebugLog('[_pullFromRemote] botId=$botId username=${user.username}');

    final mainClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: null, // let helper load token from local storage
      attemptSessionRestore: true,
    );
    if (mainClient == null) {
      throw Exception('Could not connect to Manager');
    }

    // 1. Fetch remote config
    appendBotDebugLog('[_pullFromRemote] Fetching remote config...');
    final remoteConfig = await mainClient.getBotConfig(botId);
    final remoteCommands = _extractCommandList(remoteConfig['commands']);
    appendBotDebugLog('[_pullFromRemote] Remote has ${remoteCommands.length} commands');

    // 2. Get local commands
    final localCommands = await appManager.listAppCommands(botId);
    appendBotDebugLog('[_pullFromRemote] Local has ${localCommands.length} commands');

    // 3. Compute merge diff
    final diff = _computeMergeDiff(localCommands, remoteCommands);
    appendBotDebugLog('[_pullFromRemote] Diff: new=${diff.newCommands.length}, updated=${diff.updatedCommands.length}, unchanged=${diff.unchangedCount}');

    // 4. Show confirmation dialog
    if (!mounted) return;
    final confirmed = await _showPullConfirmDialog(
      diff: diff,
      remoteTimestamp: _extractTimestamp(remoteConfig),
      localTimestamp: await _getLocalMaxTimestamp(botId),
    );
    if (!confirmed || !mounted) {
      appendBotDebugLog('[_pullFromRemote] User cancelled');
      return;
    }

    // 5. Apply merge
    appendBotDebugLog('[_pullFromRemote] Applying merge...');
    await _applyMerge(botId, diff, remoteCommands);

    // 6. Refresh app data
    await appManager.createOrUpdateApp(
      id: user.id,
      username: user.username,
      avatarHash: user.avatarHash,
      discriminator: user.discriminator.toString(),
      token: (await appManager.getApp(botId))['token']?.toString() ?? '',
    );

    appendBotDebugLog('[_pullFromRemote] DONE — success');
    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_home_pull_success)),
      );
    }
  } catch (e) {
    appendBotDebugLog('[_pullFromRemote] FAILED: $e');
    if (showSnack && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  } finally {
    _setState(() => _isPullingApp = false);
  }
}
```

**Step 2: Verify compilation**

Run: `cd packages/app && flutter analyze lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart`
Expected: Errors about missing `_extractCommandList`, `_computeMergeDiff`, `_showPullConfirmDialog`, `_getLocalMaxTimestamp`, `_applyMerge` — these are defined in Task 3.

---

### Task 3: Add helper methods for merge logic

**Objective:** Implement the merge diff computation, timestamp extraction, and merge application

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart`

**Step 1: `_extractCommandList` — normalize command list from various formats**

Add after `_pullFromRemote`:

```dart
/// Extracts a normalized command list from the remote config payload.
/// The remote format can be a List of Maps or a Map keyed by command ID.
List<Map<String, dynamic>> _extractCommandList(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
  if (raw is Map) {
    return raw.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}
```

**Step 2: `_MergeDiff` class and `_computeMergeDiff`**

```dart
class _MergeDiff {
  final List<Map<String, dynamic>> newCommands;
  final List<Map<String, dynamic>> updatedCommands;
  final int unchangedCount;
  final int localOnlyCount;

  const _MergeDiff({
    required this.newCommands,
    required this.updatedCommands,
    required this.unchangedCount,
    required this.localOnlyCount,
  });

  bool get hasChanges => newCommands.isNotEmpty || updatedCommands.isNotEmpty;
}
```

```dart
_MergeDiff _computeMergeDiff(
  List<Map<String, dynamic>> localCommands,
  List<Map<String, dynamic>> remoteCommands,
) {
  final localById = <String, Map<String, dynamic>>{};
  for (final cmd in localCommands) {
    final id = (cmd['id'] ?? cmd['name'] ?? '').toString();
    if (id.isNotEmpty) localById[id] = cmd;
  }

  final newCommands = <Map<String, dynamic>>[];
  final updatedCommands = <Map<String, dynamic>>[];
  var unchangedCount = 0;

  for (final remoteCmd in remoteCommands) {
    final id = (remoteCmd['id'] ?? remoteCmd['name'] ?? '').toString();
    if (id.isEmpty) continue;

    final localCmd = localById[id];
    if (localCmd == null) {
      // Command exists remotely but not locally → add
      newCommands.add(remoteCmd);
    } else {
      // Compare timestamps
      final remoteUpdated = _parseTimestamp(remoteCmd['updatedAt']);
      final localUpdated = _parseTimestamp(localCmd['updatedAt']);
      if (remoteUpdated != null && localUpdated != null && remoteUpdated.isAfter(localUpdated)) {
        updatedCommands.add(remoteCmd);
      } else {
        unchangedCount++;
      }
      localById.remove(id); // mark as seen
    }
  }

  // Remaining in localById are local-only commands
  final localOnlyCount = localById.length;

  return _MergeDiff(
    newCommands: newCommands,
    updatedCommands: updatedCommands,
    unchangedCount: unchangedCount,
    localOnlyCount: localOnlyCount,
  );
}
```

**Step 3: `_parseTimestamp` helper**

```dart
DateTime? _parseTimestamp(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;
  return DateTime.tryParse(raw.toString());
}
```

**Step 4: `_extractTimestamp` — get best remote modification timestamp**

```dart
String _extractTimestamp(Map<String, dynamic> config) {
  // Try to find the latest command updatedAt as the config's "last modified"
  final commands = _extractCommandList(config['commands']);
  DateTime? latest;
  for (final cmd in commands) {
    final t = _parseTimestamp(cmd['updatedAt']);
    if (t != null && (latest == null || t.isAfter(latest))) {
      latest = t;
    }
  }
  if (latest != null) {
    return '${latest.toLocal().toString().substring(0, 19)}';
  }
  // Fallback: use config-level timestamp if available
  final configTs = _parseTimestamp(config['updatedAt'] ?? config['savedAt']);
  if (configTs != null) {
    return '${configTs.toLocal().toString().substring(0, 19)}';
  }
  return 'Unknown';
}
```

**Step 5: `_getLocalMaxTimestamp` — get latest local command modification time**

```dart
Future<String> _getLocalMaxTimestamp(String botId) async {
  final commands = await appManager.listAppCommands(botId, forceRefresh: true);
  DateTime? latest;
  for (final cmd in commands) {
    final t = _parseTimestamp(cmd['updatedAt']);
    if (t != null && (latest == null || t.isAfter(latest))) {
      latest = t;
    }
  }
  if (latest != null) {
    return '${latest.toLocal().toString().substring(0, 19)}';
  }
  return 'Unknown';
}
```

**Step 6: `_applyMerge` — save merged commands to local storage**

```dart
Future<void> _applyMerge(
  String botId,
  _MergeDiff diff,
  List<Map<String, dynamic>> remoteCommands,
) async {
  // Save new commands
  for (final cmd in diff.newCommands) {
    final cmdId = (cmd['id'] ?? cmd['name'] ?? '').toString();
    if (cmdId.isEmpty) continue;
    await appManager.saveAppCommand(botId, cmdId, cmd);
  }

  // Update changed commands
  for (final cmd in diff.updatedCommands) {
    final cmdId = (cmd['id'] ?? cmd['name'] ?? '').toString();
    if (cmdId.isEmpty) continue;
    await appManager.saveAppCommand(botId, cmdId, cmd);
  }
}
```

**Step 7: Verify compilation**

Run: `cd packages/app && flutter analyze lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart`
Expected: Only missing `_showPullConfirmDialog` (Task 4).

---

### Task 4: Add `_showPullConfirmDialog` — confirmation dialog with timestamps

**Objective:** Show a dialog before pulling that displays remote vs local modification times and a summary of changes

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart` (or home.ui.part.dart)

**Step 1: Add the dialog method**

Add to `home.sync.part.dart` (or `_AppHomePageUI` extension in home.ui.part.dart):

```dart
Future<bool> _showPullConfirmDialog({
  required _MergeDiff diff,
  required String remoteTimestamp,
  required String localTimestamp,
}) async {
  final colorScheme = Theme.of(context).colorScheme;

  return await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_download, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr.bot_home_pull,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timestamp comparison
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildTimestampRow(
                    icon: Icons.cloud,
                    label: 'Remote (Cloud)',
                    timestamp: remoteTimestamp,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildTimestampRow(
                    icon: Icons.phone_android,
                    label: 'Local (Device)',
                    timestamp: localTimestamp,
                    color: colorScheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Change summary
            if (diff.hasChanges) ...[
              Text(
                'Changes to apply:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (diff.newCommands.isNotEmpty)
                _buildChangeRow(
                  Icons.add_circle_outline,
                  '${diff.newCommands.length} new command(s)',
                  AppTheme.successAccent,
                ),
              if (diff.updatedCommands.isNotEmpty)
                _buildChangeRow(
                  Icons.update,
                  '${diff.updatedCommands.length} updated command(s)',
                  AppTheme.warning,
                ),
              _buildChangeRow(
                Icons.check_circle_outline,
                '${diff.unchangedCount} unchanged',
                AppTheme.grey,
              ),
              _buildChangeRow(
                Icons.phone_android,
                '${diff.localOnlyCount} local-only (kept)',
                colorScheme.secondary,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successAccent),
                    const SizedBox(width: 8),
                    Text(
                      'Already up to date — no changes needed.',
                      style: TextStyle(color: AppTheme.successAccent),
                    ),
                  ],
                ),
              ),

            // Warning about local-only commands
            if (diff.localOnlyCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: colorScheme.secondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${diff.localOnlyCount} local command(s) not on remote will be preserved.',
                        style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.tr.common_cancel),
        ),
        FilledButton.icon(
          onPressed: diff.hasChanges ? () => Navigator.of(ctx).pop(true) : null,
          icon: const Icon(Icons.cloud_download, size: 18),
          label: Text(
            diff.hasChanges
                ? '${context.tr.bot_home_pull} (${diff.newCommands.length + diff.updatedCommands.length} changes)'
                : context.tr.bot_home_pull,
          ),
        ),
      ],
    ),
  ).then((v) => v ?? false);
}
```

**Step 2: Helper widget builders for the dialog**

```dart
Widget _buildTimestampRow({
  required IconData icon,
  required String label,
  required String timestamp,
  required Color color,
}) {
  return Row(
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 12, color: color)),
      const Spacer(),
      Text(timestamp, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    ],
  );
}

Widget _buildChangeRow(IconData icon, String label, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 13)),
      ],
    ),
  );
}
```

**Step 3: Verify compilation**

Run: `cd packages/app && flutter analyze`
Expected: No errors in the home files.

---

### Task 5: Add Pull button UI in home.dart

**Objective:** Add a "Pull from Cloud" button in the Tools section, next to the existing Push button

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.dart:489-514`

**Step 1: Insert Pull button before Push button**

Replace the section starting at line 489 (`_buildActionTile(icon: Icons.cloud_upload, label: context.tr.bot_home_push...`) with BOTH pull and push buttons:

```dart
_buildActionTile(
  icon: Icons.cloud_download,
  label: context.tr.bot_home_pull,
  iconColor: AppTheme.info,
  onTap:
      _isPullingApp
          ? null
          : () async {
            await _pullFromRemote(showSnack: true);
            unawaited(
              refreshBotRuntime(
                widget.client.user.id.toString(),
              ),
            );
          },
  trailing:
      _isPullingApp
          ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
          : null,
),
_buildActionTile(
  icon: Icons.cloud_upload,
  label: context.tr.bot_home_push,
  iconColor: AppTheme.success,
  onTap:
      _isPushingApp
          ? null
          : () async {
            await _pushToRemote(showSnack: true);
            unawaited(
              refreshBotRuntime(
                widget.client.user.id.toString(),
              ),
            );
          },
  trailing:
      _isPushingApp
          ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
          : null,
),
```

**Step 2: Verify UI**

Run: `cd packages/app && flutter analyze lib/features/bot_editor/presentation/screens/bot_sub_pages/home.dart`
Expected: No new errors.

---

### Task 6: Add safety check to `_pushToRemote` — refuse empty configs

**Objective:** Prevent accidentally pushing an empty/corrupted config that would wipe the remote bot

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart:95-159`

**Step 1: Add emptiness check after getting local commands**

Insert after line 131 (`final localCommands = await appManager.listAppCommands(botId);`):

```dart
// Safety: refuse to push if config has zero commands (prevents accidental wipes)
final localConfigEmpty = localCommands.isEmpty;
final localConfigSize = jsonEncode(localConfig).length;
appendBotDebugLog('[_pushToRemote] localCommands=${localCommands.length} configSize=$localConfigSize');

if (localConfigSize < 50) {
  // Config is suspiciously small (< 50 bytes = basically empty)
  appendBotDebugLog('[_pushToRemote] REFUSING PUSH: config is empty or near-empty ($localConfigSize bytes)');
  if (showSnack && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refusing to push: local config is empty or corrupted. Check your commands.'),
        backgroundColor: AppTheme.error,
      ),
    );
  }
  return;
}
```

Note: Need to import `dart:convert` at top of file if not already present (it should be via home.dart).

**Step 2: Verify**

Run: `cd packages/app && flutter analyze`
Expected: No new errors.

---

### Task 7: Add new i18n keys for the dialog (if needed)

**Objective:** Add any missing translation keys used in the pull dialog

**Files (if needed):**
- Modify: `packages/app/lib/core/i18n/l10n/app_en.arb`
- Modify: `packages/app/lib/core/i18n/l10n/app_fr.arb`
- Modify: `packages/app/lib/core/i18n/l10n/app_de.arb`
- Modify: `packages/app/lib/core/i18n/l10n/app_ja.arb`
- Modify: `packages/app/lib/core/i18n/l10n/app_pt.arb`
- Modify: `packages/app/lib/core/i18n/l10n/app_tr.arb`

**Check first:** The dialog uses `context.tr.bot_home_pull`, `context.tr.common_cancel` — these already exist. The hardcoded strings ("Remote (Cloud)", "Local (Device)", "Changes to apply:", etc.) should probably be i18n keys.

**If needed — add these keys:**

```json
"bot_home_pull_dialog_remote": "Remote (Cloud)",
"bot_home_pull_dialog_local": "Local (Device)",
"bot_home_pull_dialog_changes": "Changes to apply:",
"bot_home_pull_dialog_new_commands": "new command(s)",
"bot_home_pull_dialog_updated_commands": "updated command(s)",
"bot_home_pull_dialog_unchanged": "unchanged",
"bot_home_pull_dialog_local_only": "local-only (kept)",
"bot_home_pull_dialog_up_to_date": "Already up to date — no changes needed.",
"bot_home_pull_dialog_local_preserved": "local command(s) not on remote will be preserved.",
"bot_home_push_refused_empty": "Refusing to push: local config is empty or corrupted. Check your commands.",
```

**Step 1: Add to app_en.arb** (values section + @annotations section)
**Step 2: Add to app_fr.arb** with French translations
**Step 3: Run `cd packages/app && flutter gen-l10n`**
**Step 4: Update dialog code to use `context.tr.*` instead of hardcoded strings**

---

### Task 8: End-to-end test

**Objective:** Verify the entire flow works

**Step 1: Build and check for errors**

```bash
cd /home/jeremy/Code/bc/bot-creator
cd packages/app && flutter analyze
```

Expected: No new errors introduced by the changes.

**Step 2: Run existing tests**

```bash
cd /home/jeremy/Code/bc/bot-creator
cd packages/shared && dart test
```

Expected: All existing tests pass (no regression).

**Step 3: Manual test plan**

1. Open bot-creator app on a bot with commands
2. Navigate to Bot Home → Tools section
3. Verify **Pull from Cloud** and **Push to Cloud** buttons are visible
4. Tap **Pull from Cloud** → verify dialog appears with timestamps and change summary
5. Cancel → verify nothing changed
6. Tap Pull again → confirm → verify success snackbar
7. On another device, push some changes → pull on first device → verify merge works
8. Try pushing an empty bot → verify refusal message

---

## Phase 2 (Future): Push with Conflict Detection

This phase requires Go Manager changes and is deferred:

1. **Before push, check remote timestamp** — `GET /gateway/bots/{id}/config` returns a timestamp
2. **If remote is newer, warn user** — "Remote was modified after your last pull. Pushing will overwrite those changes."
3. **Option: push with merge** — send only commands that are newer locally, not the full config
4. **Manager-side merge endpoint** — `POST /gateway/bots/{id}/merge` that accepts partial command updates

---

## Rollback Plan

If anything breaks, revert all changes:
```bash
cd /home/jeremy/Code/bc/bot-creator
git checkout -- packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.dart
git checkout -- packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart
```
