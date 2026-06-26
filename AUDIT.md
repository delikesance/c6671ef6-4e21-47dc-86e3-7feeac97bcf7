# Bot Creator — Codebase Audit (June 2026)

## Scope

Inspected 4 Flutter/Dart packages (app, shared, runner, home) + Go backend (manager) + Vitrine docs site.

---

## 1. Security

### CRITICAL

| # | Issue | Location | Detail |
|---|-------|----------|--------|
| 1 | **Bot tokens in plaintext** | `apps/{botId}.json` | Discord tokens stored on disk as JSON — no encryption, no keychain/keystore |
| 2 | **SharedPreferences = plaintext** | `MainApiSession`, `RunnerSettings`, `_lastSyncedHashes`, subscription state | accessToken, refreshToken, runner tokens, subscription expiry all in unencrypted prefs |
| 3 | **PostHog API key hardcoded in source** | `posthog_service.dart:13` | `phc_CeXy4mW5wmhxGpknMm7cWUTNmKgqb7HZZNnNcjzY53Qp` — write-capable analytics key in public source |
| 4 | **Windows: badCertificateCallback = true** | `main.dart:169-171` | Accepts ALL TLS certificates, enabling MITM on Windows |

### HIGH

| # | Issue | Location | Detail |
|---|-------|----------|--------|
| 5 | **Prometheus /metrics public** | `router.go:31` | Anyone can access system metrics |
| 6 | **Docker runs as root** | `Dockerfile` | No `USER` directive — container runs as root in production |
| 7 | **PostHog session recording unmasked** | `posthog_service.dart:137-138` | `maskAllTexts=false, maskAllImages=false` — session replays capture all on-screen data (tokens, configs) |
| 8 | **Billing bypass: desktop = premium by default** | `subscription_service.dart:140` | `_isDesktop` platforms are always premium — no payment needed, no feature restriction |
| 9 | **Billing bypass: Manager override has 20s TTL** | `subscription_service.dart:93-97` | If Manager revokes premium, app reverts to local state after 20 seconds. Remote revocation is effectively ignored. |

### MEDIUM

| # | Issue | Location | Detail |
|---|-------|----------|--------|
| 10 | **R2 config URLs without auth** | `main_api_client.dart:890` | Config download URLs described as "publicly accessible" |
| 11 | **Debug print leaks** | Throughout app | `debugPrint` logs token operations, bot IDs, API URLs in production |
| 12 | **No CORS middleware** | `router.go` | Go backend has zero CORS configuration — blocks web clients |
| 13 | **No rate limiting** | Entire API | No rate limiting middleware — vulnerable to abuse / DoS |
| 14 | **sqlite3_flutter_libs: ^0.6.0+eol** | `pubspec.yaml` | EOL dependency (End of Life) |
| 15 | **file_picker: ^12.0.0-beta.4** | `pubspec.yaml` | Beta dependency used in production |

### GOOD — What's solid

- JWT HMAC-SHA256 with audience validation and scope-based RBAC on all `/gateway/` endpoints
- Parameterized SQL queries (pgx) — no SQL injection risk confirmed
- Presigned URL upload for bot configs (not through server)
- HttpOnly, Secure, SameSite cookies for admin
- Runner auth: HMAC-SHA256 token derivation with `subtle.ConstantTimeCompare`
- JSON body limited to 1MB, `DisallowUnknownFields`, double-decode for trailing garbage
- Structured error responses (no stack traces leaked)
- Purchase receipt verification sent to backend (server-side validation exists)
- Go deps reasonably recent (go-chi v5, pgx v5, JWT v5, k8s v0.36)

---

## 2. UX & Novice Flow

### 10 barriers for a total Discord novice

| # | Barrier | Where | Impact |
|---|---------|-------|--------|
| 1 | Must leave app to create bot on Discord Developer Portal | Onboarding step 2 | First action requires external website |
| 2 | No "Invite to Server" button anywhere in app | Bot home page | Bot can't be used on any Discord server |
| 3 | Onboarding is purely informational (text + icons) | Steps 2-4 | User reads but can't interact |
| 4 | Two parallel action editors (blocks + list) | Command editor | User doesn't know which to use |
| 5 | "Runner" exposed in settings with text fields | Settings page | Incomprehensible to non-developers |
| 6 | Sync failures are silent | `unawaited(syncTask)` | Bot "doesn't work" with no explanation |
| 7 | Docs buried in BDFD editor | Vitrine link | Users don't know docs exist |
| 8 | No sample/template bot | Anywhere | User must create everything from scratch |
| 9 | No step progress indicator (1/5) in onboarding | `onboarding_page.dart` | No sense of how far along they are |
| 10 | "Skip" resets progress | `onboarding_manager.dart` | Can't resume later |

---

## 3. Efficiency

| # | Problem | Detail |
|---|---------|--------|
| 1 | **Polling every 15s** | `_initRunningState` checks ALL bot statuses + `setState` → full rebuild of bot list |
| 2 | **Stream push every 2s** | `_startStreamUpdateLoop` pushes `_apps` even when nothing changed |
| 3 | **Eager sync on startup** | `syncAllBotsFromManager` in `initState` + on every resume — before any user interaction |
| 4 | **Hash persist on every save** | `_lastSyncedHashes` written to SharedPreferences on every config save |
| 5 | **No config cache** | `getBotConfig()` downloads full R2 JSON every call |
| 6 | **logAppOpen() in build()** | Every frame triggers an analytics event |
| 7 | **No connection pool** | New `http.Client()` created/disposed per request |
| 8 | **No offline mode** | Manager unreachable → local bots can't start even if configured |

---

## 4. What's Missing

### Gaps

- ~~Bot invite OAuth URL generation~~ (added post-audit)
- ~~Bot config serialization through BotConfig canonical pipeline~~ (fixed post-audit)
- Version naming/tagging (timestamps only)
- Command search/filter (for 50+ commands)
- Command duplication
- Offline mode for local bots
- Sample/template bot for new users
- In-app documentation (vitrine hidden in BDFD editor)
- Flutter web: no `web/index.html` — web platform not set up despite `kIsWeb` checks in code
- Purchase receipt server-side validation result has no effect on local entitlement (best-effort only)

### Dead code / cruft

- `packages/home/` — completely empty directory, not in workspace config
- `debugPremiumBypass` flag in production builds
- Mobile local hosting toggle with known Android foreground service bugs
- Drive backup with no clear restore flow

---

## 5. Test Coverage

| Layer | Files | LOC | Verdict |
|-------|-------|-----|---------|
| Go backend (Manager) | 43 test files | ~9,144 | ✅ Solid |
| Flutter app | 34 test files | ~5,895 | ⚠️ Adequate |
| Shared package | 91 test files | ~18,173 | ✅ Excellent |
| Runner | 8 test files | ~1,500 | ⚠️ Adequate |

**Correction from initial analysis:** The Flutter app actually has 34 test files (not 2), and shared has 91 test files (not "multiple"). Test coverage is better than first reported.

---

## 6. Docs (Vitrine)

- **528** markdown files in `_docs/`
- Categories: Entity Info (154), Moderation (87), Embed & Message (60), Math & Text (53), HTTP & JSON (32), Variables (29), etc.
- All user-facing BDFD function docs only — no backend/internal docs
- English only (correct per project conventions)

---

## 7. i18n coverage

| Lang | ARB keys | Missing vs EN |
|------|----------|---------------|
| en | 1,772 | — |
| fr | 1,779 | 4 keys |
| de | 1,780 | 4 keys |
| pt | 1,780 | 4 keys |
| ja | 1,780 | 4 keys |
| tr | 1,782 | 4 keys |

Coverage is excellent — only 4 keys missing per language.

---

## 8. Prioritized Roadmap

### Phase 1 — Critical (Security + Revenue) — ✅ COMPLETE (7/7)

1. ✅ Remove hardcoded PostHog API key → `String.fromEnvironment('POSTHOG_API_KEY')`
2. ✅ Mask PostHog session recording → `maskAllTexts=true, maskAllImages=true`
3. ✅ Add sample `/ping` command on first bot creation (all 6 languages)
4. ✅ Fix billing bypass: removed `_isDesktop` blanket premium from all 4 locations, increased Manager override TTL 20s→1h, server state now authoritative
5. ✅ Fix Windows `badCertificateCallback = true` — removed entire `_WindowsHttpOverrides` class
6. ✅ Create SecureStorageService — AES-256-GCM file-based fallback, flutter_secure_storage on supported platforms
7. ✅ Wire secure storage into database.dart (tokens) + main_api_settings.dart (sessions)

### Phase 2 — Security + Novice

6. ~~Fix `_pushToRemote` to use `buildBotPayload` (workflows)~~ ✅ DONE
7. ~~Add "Invite to Server" OAuth button on bot home~~ (added post-audit)
8. Add sample template bot (`/ping`) for instant start
9. Add CORS middleware to Manager API
10. Add rate limiting to Manager API
11. Add `USER` directive to Dockerfile (non-root container)
12. Replace EOL/beta deps (`sqlite3_flutter_libs`, `file_picker`)

### Phase 3 — UX + Quality of Life

13. Replace 15s polling with event-driven / WebSocket updates
14. Add skeleton loading on home page
15. Show step progress (1/5) in onboarding
16. Add command search/filter
17. Surface docs link on bot home page

### Phase 4 — Performance + Architecture

18. Local cache for R2 configs
19. HTTP connection pool
20. Remove `debugPremiumBypass` flag
21. Delete `packages/home/` empty dir
22. Increase Flutter app test coverage
