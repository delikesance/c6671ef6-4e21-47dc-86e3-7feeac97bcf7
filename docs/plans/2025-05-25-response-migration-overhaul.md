# Response Migration Overhaul — Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Remove the "Response" block from the command editor, make the legacy-to-modern migration permanent and automatic, and add a mass-migration button on the home page.

**Architecture:** The `data.response` block is replaced at save time by equivalent `respondWithMessage`/`respondWithComponentV2`/`respondWithModal` actions in `data.actions`. The `data.response` key is kept but emptied (text='', embeds=[], etc.) for backward compatibility. A new i18n'd button on the home page banner triggers mass migration of all legacy commands across all bots. Validation at save time ensures interaction commands have at least one respond action.

**Tech Stack:** Flutter/Dart, shared package (bot_creator_shared), SharedPreferences, existing i18n pipeline (ARB × 5)

---

## Phase 1: Shared migration utility (permanent migration)

### Task 1: Add `migrateCommandDataResponsePermanently` to shared

**Objective:** Create a permanent migration function that empties `data.response` after converting it to actions, so the stored data is fully migrated.

**Files:**
- Modify: `packages/shared/lib/utils/command_migration.dart`
- Modify: `packages/shared/test/command_migration_test.dart`

**Step 1: Add the permanent migration function**

In `command_migration.dart`, add after `migrateCommandDataResponse`:

```dart
/// Permanently migrates [data] by converting the legacy `data.response`
/// block into inline actions and then **emptying** the response block.
///
/// Unlike [migrateCommandDataResponse] (which is runtime-only and sets an
/// in-memory sentinel), this function clears the response content so the
/// migration is persisted to storage.
///
/// Returns `true` if any content was migrated, `false` if the response was
/// already empty or already migrated.
bool migrateCommandDataResponsePermanently(Map<String, dynamic> data) {
  // First, apply the runtime migration (which sets _migrated sentinel).
  // If the response is already empty/migrated, this is a no-op.
  final rawResponse = data['response'];
  if (rawResponse is! Map) return false;

  final response = Map<String, dynamic>.from(rawResponse.cast<String, dynamic>());

  // Already permanently migrated (empty response with no meaningful content).
  if (response['_migrated'] == true) {
    // Still need to check: if actions already have respond actions, this was
    // migrated before but response might not have been emptied yet.
    // We handle that below.
  }

  // Apply runtime migration (injects actions + sets _migrated).
  migrateCommandDataResponse(data);

  // Now empty the response block permanently.
  // Keep the structural keys but clear all content.
  final wasMigrated = (data['response'] as Map?)?['_migrated'] == true;

  if (!wasMigrated && !_isLegacyResponseMigrable(response)) {
    // Nothing to migrate — response was already empty.
    return false;
  }

  // Clear response content while keeping the key for compatibility.
  (data['response'] as Map).clear();
  (data['response'] as Map)['mode'] = 'message';
  (data['response'] as Map)['type'] = 'normal';
  (data['response'] as Map)['text'] = '';
  (data['response'] as Map)['embeds'] = [];
  (data['response'] as Map)['components'] = {};
  (data['response'] as Map)['modal'] = {};
  (data['response'] as Map)['workflow'] = {
    'autoDeferIfActions': true,
    'visibility': 'public',
    'onError': 'edit_error',
    'conditional': {'enabled': false},
  };

  return true;
}
```

**Step 2: Add tests for permanent migration**

In `command_migration_test.dart`, add:

```dart
group('migrateCommandDataResponsePermanently', () {
  test('migrates and empties response', () {
    final data = commandData(
      response: {
        'text': 'Pong!',
        'type': 'normal',
        'workflow': {'visibility': 'public'},
      },
    );
    final result = migrateCommandDataResponsePermanently(data);
    expect(result, isTrue);
    // Actions should now contain the respondWithMessage.
    expect((data['actions'] as List).any((a) => a['type'] == 'respondWithMessage'), isTrue);
    // Response should be empty.
    expect((data['response'] as Map)['text'], equals(''));
    expect((data['response'] as Map)['embeds'], isEmpty);
  });

  test('no-op on empty response', () {
    final data = commandData(
      response: {
        'type': 'normal',
        'text': '',
        'embeds': [],
        'workflow': {'visibility': 'public', 'conditional': {'enabled': false}},
      },
    );
    final result = migrateCommandDataResponsePermanently(data);
    expect(result, isFalse);
  });

  test('idempotent — calling twice has no effect second time', () {
    final data = commandData(
      response: {
        'text': 'Hello',
        'type': 'normal',
        'workflow': {'visibility': 'public'},
      },
    );
    final first = migrateCommandDataResponsePermanently(data);
    expect(first, isTrue);
    final second = migrateCommandDataResponsePermanently(data);
    expect(second, isFalse);
    // Only one respondWithMessage action.
    expect((data['actions'] as List).where((a) => a['type'] == 'respondWithMessage').length, equals(1));
  });

  test('migrates subcommand workflows permanently', () {
    final data = {
      'actions': [],
      'response': {
        'type': 'normal',
        'text': '',
        'workflow': {'visibility': 'public', 'conditional': {'enabled': false}},
      },
      'subcommandWorkflows': {
        'ban': {
          'response': {
            'text': 'User banned!',
            'type': 'normal',
            'workflow': {'visibility': 'public'},
          },
          'actions': [],
        },
      },
    };
    final result = migrateCommandDataResponsePermanently(data);
    expect(result, isTrue);
    final sub = (data['subcommandWorkflows'] as Map)['ban'] as Map;
    expect((sub['actions'] as List).any((a) => a['type'] == 'respondWithMessage'), isTrue);
    expect((sub['response'] as Map)['text'], equals(''));
  });
});
```

**Step 3: Run tests**

```bash
cd packages/shared && dart test test/command_migration_test.dart
```

Expected: all tests pass.

---

## Phase 2: Mass-migration button on home page

### Task 2: Add migration logic to banner + home page

**Objective:** Replace the dismiss-only banner with a banner that has a "Migrate" button. Tapping it migrates all legacy commands across all bots permanently.

**Files:**
- Modify: `packages/app/lib/features/home/presentation/home_page.dart`

**Step 1: Add migrate-all function**

Add a method to `_CommandCreatePageState`... No. Add to the `HomePageState`:

```dart
/// Permanently migrates all legacy commands across all bots.
/// Returns the count of commands migrated.
Future<int> _migrateAllLegacyCommands() async {
  int migratedCount = 0;
  try {
    final apps = await appManager.getAllApps();
    for (final rawApp in apps) {
      if (rawApp is! Map) continue;
      final botId = (rawApp['id'] ?? '').toString();
      if (botId.isEmpty) continue;
      final commands = await appManager.getCommands(botId);
      for (final cmd in commands) {
        final data = cmd['data'];
        if (data is! Map) continue;
        final result = migrateCommandDataResponsePermanently(
          Map<String, dynamic>.from(data.cast<String, dynamic>()),
        );
        if (result) {
          migratedCount++;
          // Save the command with the migrated data.
          await appManager.saveAppCommand(
            botId,
            (cmd['id'] ?? '').toString(),
            Map<String, dynamic>.from(cmd.cast<String, dynamic>()),
          );
        }
      }
    }
  } catch (_) {
    // Non-blocking — best effort.
  }
  return migratedCount;
}
```

**Step 2: Update the banner widget to include a "Migrate" button**

Replace `_LegacyCommandsDeprecationBanner` with a version that has both dismiss and migrate buttons. The migrate button triggers `_migrateAllLegacyCommands()`, shows a snackbar with the count, then hides the banner.

**Step 3: After migration, clear the SharedPreferences dismiss flag and reset `_hasLegacyCommands`**

Since all commands have been migrated, `_hasLegacyCommands` becomes false and the banner disappears naturally.

**Step 4: Add i18n keys for the migrate button**

Add to all 5 ARB files:
- `legacy_response_banner_migrate` ("Migrer" / "Migrate" / "Migrieren" / "Migrar" / "Geçir")
- `legacy_response_banner_migrating` ("Migration en cours..." / etc.)
- `legacy_response_banner_migrated` ("X commandes migrées" / etc.)
- `legacy_response_banner_migrate_all` ("Tout migrer" / etc.)

Then `flutter gen-l10n`.

---

## Phase 3: Auto-migrate on command save

### Task 3: Migrate response to actions when saving a command

**Objective:** When the user saves a command, if the editor state has legacy response content, convert it to a `respondWith*` action in the saved data and empty the response.

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart`
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.serialization.dart`

**Step 1: In `_buildCommandDataPayload()`, after building the response payload, check if it has legacy content. If so, convert it to a `respondWith*` action.**

The serialization function in `command.create.serialization.dart` builds `data.response` from editor state (`_responseController.text`, `_responseEmbeds`, etc). We need to also check: if the response has meaningful content, inject the corresponding action into `actions[]` and empty the response in the persisted data.

**Note:** This is tricky because the editor state (`_responseController`, etc.) still exists — we're not removing the editor UI yet (that's Phase 4). For now, at save time, we "bake" the response into actions and empty the persisted response.

Add after the payload is built:

```dart
// Permanent migration: bake response into actions, empty response.
import 'package:bot_creator_shared/utils/command_migration.dart' as migration;

// ... inside _buildCommandDataPayload, after building the data map:

final data = { /* ... existing payload ... */ };

// If the response has content, permanently migrate it.
final didMigrate = migration.migrateCommandDataResponsePermanently(data);
// If didMigrate is true, data['response'] is now empty and data['actions']
// has the respondWith* action prepended/added. No further action needed.
```

**Step 2: After save, refresh the editor state to reflect the migrated data**

When `_updateOrCreate()` returns after saving, reload the command data from storage so the editor state reflects the now-empty response and the new actions. This prevents the "ghost response" issue where the user saves, reopens, and still sees the old response block.

---

## Phase 4: Validation — at least one respond action for interactions

### Task 4: Add save-time validation for interaction commands

**Objective:** When saving an interaction command (chatInput, user, message), verify that `actions[]` contains at least one respond action (respondWithMessage, respondWithComponentV2, respondWithModal).

**Files:**
- Modify: `packages/app/lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.validation.dart`

**Step 1: Add validation rule**

In `_validateCommandInputs()`, after existing validations, add:

```dart
// Interaction commands must have at least one respond action.
if (!_legacyModeEnabled && effectiveActions.isNotEmpty) {
  final hasResponseAction = effectiveActions.any((a) {
    final type = (a['type'] ?? '').toString();
    return type == 'respondWithMessage' ||
           type == 'respondWithComponentV2' ||
           type == 'respondWithModal';
  });
  if (!hasResponseAction) {
    // Show error: command needs at least one response action
    // ...
  }
}
```

**Note:** This validation should NOT block save if the user has a legacy response block that hasn't been migrated yet — because the migration happens at save time. So the check should run AFTER migration, or we should check `effectiveActions` which includes the injected respond action.

---

## Phase 5: Remove the Response block UI (later phase — not in this iteration)

This is a major UI change that requires careful design:
- The "Response" scratch block disappears from the canvas
- Users add response via the action palette (respondWithMessage, etc.)
- The `CommandReplyEditorPage` is no longer needed as a standalone screen; its capabilities merge into the action editor

This phase is **not included** in the current iteration. It's noted here for future planning.

---

## Execution Order

1. **Task 1** → shared package (permanent migration function + tests)
2. **Task 2** → home page (mass-migration button + i18n)
3. **Task 3** → command save (auto-migrate on save)
4. **Task 4** → validation (respond action required)

Each task depends on the previous one. Task 1 is standalone in the shared package. Tasks 2-4 are in the app package and depend on Task 1 being complete.