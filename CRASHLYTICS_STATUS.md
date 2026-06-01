# Crashlytics Errors Analysis

## Status (2026-06-01)

### FATAL Errors - FIXED in PR #212
- File picker already active (11 events, 1 user)
- PlatformFile.readAsBytes() unavailable (3 events, 1 user)
- RenderFlex overflow (10 events, 1 user)
- Invalid UTF-16 in TextSpan (4 events, 2 users)

### NON-FATAL Errors - FIXED in PR #211
The following NON-FATAL errors are already addressed by PR #211:

#### 1. TimeoutException: Rewarded ads initialization (788 events, 149 users)
- **Issue ID:** af9d4a909c43c44359aafa74ab87eb63
- **Version range:** 1.7.1 - 1.8.13
- **Root cause:** Timeout was 8 seconds
- **Fix in PR #211:** Increased timeout to 15 seconds
- **File:** `packages/app/lib/main.dart` (line 226)

#### 2. Circuit breaker open (435 events, 2 users)
- **Issue ID:** 60fc8f1ad0e377c28c179f2e3faffaee
- **Version range:** 1.8.9 - 1.8.13
- **Root cause:** Too many API failures triggering circuit breaker
- **Fix in PR #211:** Increased circuit breaker cooldown from 30s to 60s
- **File:** `packages/app/lib/core/network/main_api_client.dart` (line 98)

## Other NON-FATAL Errors (lower priority)

These errors have lower event counts or are expected failures:

3. **UMP consent request failure** (50 events, 21 users)
   - Issue ID: e15de5a538766edd04851496d495bf65
   - Already has graceful error handling
   - Usually network-related timeouts

4. **UMP consent form timeout** (44 events, 18 users)
   - Issue ID: a0ffadc68e964137f9a161015b86434c
   - Timeout increased in PR #211 to 20 seconds
   - Has graceful degradation

5. **Google Play Billing NullPointerException** (174 events, 114 users)
   - Issue ID: a0b58a19c21e10b4b97c91d815bb58ec
   - Marked as SIGNAL_EARLY (100% of crashes in first second)
   - Already fixed on a separate branch

## Recommendations

1. **Merge PR #211** - Fixes high-impact NON-FATAL errors (ad timeouts and circuit breaker)
2. **Merge PR #212** - Fixes high-impact FATAL errors (file picker, layout, UTF-16)
3. Monitor Crashlytics after merges to confirm errors are resolved
4. Consider investigating why only 2 users trigger the circuit breaker error (may be network-related)