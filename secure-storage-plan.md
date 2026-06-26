# Secure Storage Plan

Date: 2026-06-26
Project: /home/jeremy/Code/bc/bot-creator/packages/app

---

## 1. Current State of Plaintext Token Storage

### 1.1 Bot Tokens (Discord)

**File:** `/packages/app/lib/core/storage/database.dart`

Bot tokens are stored as a plaintext field inside per-bot JSON files at:
```
{appStoragePath}/apps/{botId}.json
```

- **Write**: `createOrUpdateApp()` (line 164) writes `data['token'] = token` at line 207, then `_writeAppToDisk()` serializes the entire map to JSON at lines 564-571.
- **Read**: `getApp(id)` (line 502) reads the entire JSON file and returns it as `Map<String, dynamic>`. Callers then access `appData['token']`.
- **Consumers of the token**: `buildBotPayload()` (bot_payload_builder.dart:492), `onAfterCommandDelete` (bot_payload_builder.dart:163), and any code calling `appManager.getApp()` then reading the `token` field.

The `{botId}.json` file contains the full bot configuration: commands, workflows, variables, intents, prefix, etc. — plus the plaintext `token`.

**Storage path resolution** (`app_storage_directory.dart`):
- Android/iOS: `getApplicationDocumentsDirectory()`
- Desktop: `getApplicationSupportDirectory()` or fallback to `~/.local/share/bot_creator` or `XDG_DATA_HOME/bot_creator`

### 1.2 Main API Session (accessToken + refreshToken)

**File:** `/packages/app/lib/core/network/main_api_settings.dart`

The MainApiSession (accessToken, refreshToken, expiresAt, userId, username, scopes) is stored in **SharedPreferences** under the key `main_api_session` (line 114).

- **Write**: `MainApiSettingsStore.saveSession()` (line 155) serializes to JSON and stores in SharedPreferences.
- **Read**: `MainApiSettingsStore.loadSession()` (line 139) reads from SharedPreferences and deserializes.
- **Clear**: `MainApiSettingsStore.clearSession()` (line 160).

Also stored in SharedPreferences (non-sensitive):
- `main_api_config` — the base URL for the Main API
- `main_api_last_synced_hashes` / `main_api_last_saved_snapshots` — hash caches in MainApiClient

### 1.3 Google Drive OAuth Tokens (Desktop only)

**File:** `/packages/app/lib/core/storage/drive.dart`

Desktop Google Drive OAuth tokens are stored in a plaintext JSON file at:
```
{getApplicationSupportDirectory()}/auth/google_drive_desktop_tokens.json
```

Contains `access_token`, `refresh_token`, `expiry` as plaintext JSON.

- **Write**: `_saveDesktopTokens()` (line 349)
- **Read**: `_loadDesktopTokens()` (line 322)
- **Clear**: `_clearDesktopTokens()` (line 359)

On mobile (Android/iOS), Google Sign-In handles token storage natively via the OS credential manager — no custom token file.

---

## 2. Linux / NixOS Compatibility of flutter_secure_storage

### flutter_secure_storage

The `flutter_secure_storage` package (pub.dev) uses platform-native secure storage:

| Platform | Backend |
|----------|---------|
| Android  | EncryptedSharedPreferences (AES/GCM) |
| iOS      | Keychain Services (kSecClassGenericPassword) |
| macOS    | Keychain Services |
| Windows  | CryptProtectData (DPAPI) |
| **Linux**| **libsecret** (via D-Bus Secret Service API, e.g. GNOME Keyring / KWallet) |

**Key findings for Linux:**

1. **libsecret dependency**: The Linux implementation requires `libsecret-1-dev` (or `libsecret-1.so`) and a running D-Bus session with a keyring daemon (gnome-keyring-daemon, kwalletd, etc.).

2. **NixOS challenges**:
   - `libsecret` is available in nixpkgs as `libsecret` but it needs to be in `buildInputs` in the Flutter package's cmake configuration.
   - The D-Bus session must be active. On NixOS, `services.gnome.gnome-keyring.enable = true` or equivalent must be set, OR `security.polkit.enable = true` with appropriate keyring services.
   - In a **nix-shell** development environment, `libsecret` may not be found by cmake unless explicitly included. The flutter_secure_storage Linux plugin has a `CMakeLists.txt` that does `find_package(PkgConfig)`, `pkg_check_modules(libsecret IMPORTED_TARGET libsecret-1)`, which may fail in a nix-shell without `pkg-config` and `libsecret` in the shell's PATH/PKG_CONFIG_PATH.
   - **Headless environments** (CI, SSH without D-Bus forwarding, etc.) will fail because there's no keyring daemon. This is a documented limitation.
   - The flutter_secure_storage Linux plugin is relatively new (added in v6.x) and has had issues with Wayland, snap confinement, and Flatpak.

3. **Workaround status**: Several GitHub issues document the Linux pain points. Some projects have switched to `flutter_secure_storage` v9+ which added fallback mechanisms, but the Linux backend still fundamentally depends on libsecret.

4. **Verdict**: flutter_secure_storage **can** work on NixOS with proper configuration (libsecret in build inputs, D-Bus + gnome-keyring running), but it is fragile in headless/CI/nix-shell environments. **Not a hard blocker, but requires a fallback strategy for Linux desktop.**

### Alternatives

| Option | Pros | Cons |
|--------|------|------|
| **flutter_secure_storage with Linux fallback** | Official package, widely used, works on all target platforms | Linux depends on libsecret/D-Bus; needs fallback for headless |
| **AES-256-GCM encrypt the JSON files** | Zero new dependencies (crypto package already in pubspec.yaml); works everywhere; simple | Manual key management; key must be stored somewhere (keychain or derived from device ID) |
| **SQLite + sqflite with encryption** | SQLite already used for variable store; good query capability | Complex migration; no built-in encryption in sqflite; needs `sqflite_common_ffi` with SQLCipher |
| **sentry/encrypted_shared_preferences** | Drop-in replacement for SharedPreferences | Smaller community; still needs key management |
| **Rust-based crypto via FFI** | Maximum security | Over-engineered for this use case |

**Recommended approach for this project:** Use **flutter_secure_storage as the primary solution** (it works on Android/iOS/macOS/Windows well), with a **Linux fallback** that encrypts individual token values using AES-256-GCM (using the existing `crypto` package plus `encrypt` package for AES), deriving the encryption key from a device-specific seed that itself is stored in `libsecret` when available, or in a file with restricted permissions (`0600` on Linux) as last resort.

---

## 3. Proposed Architecture: SecureStorageService

### 3.1 New Class: `SecureStorageService`

Create `/packages/app/lib/core/storage/secure_storage_service.dart`.

This service wraps both `flutter_secure_storage` (for Android/iOS/macOS/Windows) and a file-based AES-256-GCM encrypted store (for Linux fallback).

**Interface:**

```dart
abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();
}
```

**Implementation:**
- On Android/iOS/macOS/Windows: delegate to `FlutterSecureStorage` from the `flutter_secure_storage` package.
- On Linux: store values in `~/.local/share/bot_creator/.secure_vault` as individual encrypted files. Use `crypto` + `encrypt` packages for AES-256-GCM. Derive the encryption key from a device-specific secret (e.g. `mkdtemp` + machine-id hash, stored in a file with `0600` permissions in a `.keys/` subdirectory).

### 3.2 Migration of Bot Tokens

**Current flow:**
```
createOrUpdateApp() -> data['token'] = token -> _writeAppToDisk() -> JSON file
getApp(botId) -> reads JSON file -> returns map with token
buildBotPayload() -> getApp() -> appData['token']
```

**Proposed flow (dual-write during migration):**
1. When writing a bot token, write to both the JSON file (backward compat) AND `SecureStorageService` under key `bot_token:{botId}`.
2. When reading a bot token, try `SecureStorageService` first; fall back to `data['token']` from JSON (backward compat for existing data).
3. After a grace period (e.g. one app version cycle), remove the token field from the JSON write path and only use secure storage.

**Detailed write changes** (`database.dart`, `createOrUpdateApp()`):
- After setting `data['token'] = token`, also call `SecureStorageService.write('bot_token:$botId', token)`.
- Keep the existing JSON write to not break the read path.

**Detailed read changes:**
- In `getApp()` (database.dart:502), after reading the JSON map, try to get the token from secure storage: `final secureToken = await SecureStorageService.read('bot_token:$botId'); if (secureToken != null) { data['token'] = secureToken; }`.
- This way all existing consumers of `getApp()` get the secure token transparently.

**Migration of existing data:**
- Add a one-time migration function `migrateExistingBotTokens()` that scans all `{botId}.json` files in the apps directory, reads the token, writes it to secure storage, and optionally strips it from the JSON file (or leaves a placeholder).
- Call this once at app startup after `AppManager._init()`.

### 3.3 Migration of MainApiSession

**Current flow:**
```
MainApiSettingsStore.saveSession(session) -> SharedPreferences -> 'main_api_session'
MainApiSettingsStore.loadSession() -> SharedPreferences -> 'main_api_session'
```

**Proposed flow:**
1. Replace SharedPreferences storage with `SecureStorageService` for the session data.
2. Store session as a single JSON string under key `main_api_session` in secure storage.
3. Add a one-time migration: `migrateExistingMainApiSession()` that reads the session from SharedPreferences, writes it to secure storage, then clears the SharedPreferences entry.

**Detailed changes** (`main_api_settings.dart`):
- `saveSession()`: serialize session to JSON, store via `SecureStorageService.write('main_api_session', jsonString)`.
- `loadSession()`: read via `SecureStorageService.read('main_api_session')`, deserialize.
- `clearSession()`: delete via `SecureStorageService.delete('main_api_session')`.
- `clearAll()`: also clear the session from secure storage.

**The config** (`main_api_config`, base URL only) is not sensitive and can remain in SharedPreferences.

### 3.4 Migration of Google Drive Desktop Tokens

**Current flow:**
```
_saveDesktopTokens(tokens) -> google_drive_desktop_tokens.json (plaintext)
_loadDesktopTokens() -> google_drive_desktop_tokens.json (plaintext)
```

**Proposed flow:**
1. Store the token JSON string under key `google_drive_desktop_tokens` in `SecureStorageService`.
2. Add one-time migration: read existing JSON file, write to secure storage, delete the plaintext file.
3. Update `_saveDesktopTokens()`, `_loadDesktopTokens()`, `_clearDesktopTokens()` to use `SecureStorageService`.

### 3.5 One-Time Migration Runner

Create `/packages/app/lib/core/storage/secure_storage_migration.dart`:

```dart
class SecureStorageMigration {
  static Future<void> runAll() async {
    await _migrateBotTokens();
    await _migrateMainApiSession();
    await _migrateGoogleDriveTokens();
  }
  
  static Future<void> _migrateBotTokens() async { ... }
  static Future<void> _migrateMainApiSession() async { ... }
  static Future<void> _migrateGoogleDriveTokens() async { ... }
}
```

Call `SecureStorageMigration.runAll()` once at app startup (e.g. in `main.dart` or `AppManager._init()`).

Use a flag stored in a simple file or SharedPreferences (`secure_storage_migration_completed`) to only run the migration once.

---

## 4. Implementation Plan (Ordered Steps)

### Phase 1: Setup

1. **Add dependencies to pubspec.yaml:**
   - `flutter_secure_storage: ^9.2.4` (or latest)
   - `encrypt: ^5.0.3` (for AES-256-GCM on Linux fallback)
   - `pointycastle: ^3.9.1` (if encrypt needs it, or use dart:crypto's built-in AES)

2. **Create `SecureStorageService`** in `lib/core/storage/secure_storage_service.dart`:
   - Platform-aware factory constructor
   - `FlutterSecureStorage` backed on non-Linux platforms
   - AES-256-GCM file-backed store on Linux

3. **Create `SecureStorageMigration`** in `lib/core/storage/secure_storage_migration.dart`.

### Phase 2: Migration

4. **Add `migrateExistingBotTokens()`** — scans all `{botId}.json` files, extracts token, writes to secure storage.

5. **Add `migrateExistingMainApiSession()`** — reads from SharedPreferences, writes to secure storage, clears SharedPreferences.

6. **Add `migrateExistingGoogleDriveTokens()`** — reads from old JSON file, writes to secure storage, deletes old file.

7. **Wire migration into app startup** — call `SecureStorageMigration.runAll()` after `AppManager._init()`.

### Phase 3: Dual-Write (Backward Compatible)

8. **Modify `createOrUpdateApp()`** — add secure storage write for token alongside existing JSON write.

9. **Modify `getApp()`** — try secure storage first for token, fall back to JSON `data['token']`.

10. **Modify `MainApiSettingsStore`** — switch `loadSession`/`saveSession`/`clearSession` to `SecureStorageService`.

11. **Modify `drive.dart`** — switch `_loadDesktopTokens`/`_saveDesktopTokens`/`_clearDesktopTokens` to `SecureStorageService`.

### Phase 4: Cleanup (Future Release)

12. **Remove token from JSON write path** — stop writing `data['token']` to the JSON file.

13. **Remove old SharedPreferences session key** — after confirming no users remain on older versions.

14. **Remove old Google Drive token file** — after migration completes.

---

## 5. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| flutter_secure_storage fails on Linux in some environments | Users on headless/Wayland/NixOS cannot read tokens | AES-256-GCM fallback using `crypto` package; tokens stay accessible |
| Migration runs but no existing data found | No harm | Skip gracefully |
| Migration interrupted (app crash mid-migration) | Some tokens migrated, some not | Migration is idempotent — scan all files each time; use a completion flag |
| User downgrades to older version that reads from JSON | Token missing from JSON if cleanup already ran | Delay Phase 4 cleanup until after sufficient version adoption (e.g. 2 releases) |
| Encryption key derivation is not portable across app reinstalls | User loses access to securely stored tokens | Keys stored on filesystem; backup/restore flow must include the `.keys/` directory |
| flutter_secure_storage version conflicts with other packages | Build failures | Pin version; test compatibility before merging |

---

## 6. Alternative to flutter_secure_storage: Encrypted JSON File Wrapper

If flutter_secure_storage proves too problematic on Linux, an alternative is to keep the existing JSON file structure but encrypt the token value itself using AES-256-GCM:

- **Key derivation**: `SHA256(device_id + app_secret)` where `device_id` is from `Platform.localHostname` + a generated UUID stored in a file with restricted permissions.
- **Encryption**: Use `dart:convert` + `crypto` (already in pubspec.yaml) with `encrypt` package for AES-256-GCM.
- **Storage**: The encrypted token replaces the plaintext token in the JSON file. The schema would be:
  ```json
  {
    "name": "...",
    "id": "...",
    "token_encrypted": "base64_iv:base64_ciphertext:base64_tag",
    ...
  }
  ```
- **Pros**: No new native dependencies; works on all platforms including Linux/NixOS; minimal code changes.
- **Cons**: The encryption key must be stored somewhere (key management problem); less robust than OS-provided keychain.

This approach is simpler but provides less protection than OS keychain storage. It is recommended only as a **Linux fallback** within the `SecureStorageService`, not as the primary mechanism.

---

## 7. Summary of All Token Storage Locations

| Secret | Location | Format | Secure? | Target |
|--------|----------|--------|---------|--------|
| Discord bot token | `{appStoragePath}/apps/{botId}.json` | JSON, `data['token']` | No | SecureStorageService |
| Main API accessToken | SharedPreferences `main_api_session` | JSON string | No | SecureStorageService |
| Main API refreshToken | SharedPreferences `main_api_session` | JSON string | No | SecureStorageService |
| Google Drive OAuth access_token | `{supportDir}/auth/google_drive_desktop_tokens.json` | JSON | No | SecureStorageService |
| Google Drive OAuth refresh_token | Same file as above | JSON | No | SecureStorageService |
| Main API baseUrl | SharedPreferences `main_api_config` | JSON string | N/A (not sensitive) | Keep in SharedPreferences |
| Sync hash caches | SharedPreferences `main_api_last_synced_hashes` etc. | JSON string | N/A (not sensitive) | Keep in SharedPreferences |

**Total secrets to migrate: 5** (bot token per bot, accessToken, refreshToken, GDrive access_token, GDrive refresh_token)

**Files to touch:**
1. `pubspec.yaml` — add dependencies
2. `lib/core/storage/secure_storage_service.dart` — NEW
3. `lib/core/storage/secure_storage_migration.dart` — NEW
4. `lib/core/storage/database.dart` — modify `createOrUpdateApp()`, `getApp()`
5. `lib/core/network/main_api_settings.dart` — modify `loadSession/saveSession/clearSession`
6. `lib/core/storage/drive.dart` — modify `_loadDesktopTokens/_saveDesktopTokens/_clearDesktopTokens`
7. `lib/main.dart` — wire migration at startup
