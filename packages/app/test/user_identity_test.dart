// A user report has to be traceable back to a Discord account: Crashlytics,
// Firebase Analytics and PostHog are all fed from the same place, and signing
// out has to erase the identity from all three. The tests below fix that
// contract, including the "no SDK is initialised" case that every unit test
// runs in.
//
// The face of the contract that matters most is the value itself: the Discord
// snowflake is published as-is, so a support engineer can go from a report to
// the account on Discord. A test asserts the exact id reaches each sink,
// because a hash, a salt or a truncation would silently break that.

import 'package:bot_creator/core/analytics/user_identity.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Discord snowflake, in the form `session.userId` carries it.
const String _discordId = '189345600000000000';

/// One call a fake sink received.
class _Call {
  _Call(this.sdk, this.userId);

  final String sdk;
  final String? userId;
}

/// Sinks that record what they were handed, and can be made to fail.
class _RecordingSinks {
  _RecordingSinks({this.failingSdks = const <String>{}});

  /// SDK names whose sink throws, as an uninitialised SDK does.
  final Set<String> failingSdks;

  final List<_Call> calls = <_Call>[];

  UserIdentitySinks get sinks => UserIdentitySinks(
    setAnalyticsUserId: (userId) => _record('firebase_analytics', userId),
    setCrashlyticsUserIdentifier: (identifier) =>
        _record('crashlytics', identifier),
    setPosthogUser: (userId) => _record('posthog', userId),
  );

  List<_Call> callsFor(String sdk) =>
      calls.where((call) => call.sdk == sdk).toList();

  Future<void> _record(String sdk, String? userId) async {
    calls.add(_Call(sdk, userId));
    if (failingSdks.contains(sdk)) {
      throw StateError('$sdk is unavailable');
    }
  }
}

void main() {
  setUp(UserIdentity.debugResetForTests);
  tearDown(UserIdentity.debugResetForTests);

  test(
    'a login publishes the untouched Discord id to the three SDKs',
    () async {
      final recorder = _RecordingSinks();
      UserIdentity.debugSetSinks(recorder.sinks);

      await UserIdentity.apply(_discordId);

      expect(recorder.calls.map((call) => call.sdk), <String>[
        'firebase_analytics',
        'crashlytics',
        'posthog',
      ]);
      for (final call in recorder.calls) {
        // Exact value: no hashing, no salt, no truncation.
        expect(call.userId, _discordId, reason: call.sdk);
        expect(RegExp(r'^\d{17,20}$').hasMatch(call.userId!), isTrue);
      }
    },
  );

  test('a sign-out clears the identity on the three SDKs', () async {
    final recorder = _RecordingSinks();
    UserIdentity.debugSetSinks(recorder.sinks);
    await UserIdentity.apply(_discordId);
    recorder.calls.clear();

    await UserIdentity.apply(null);

    // PostHog and Analytics are told "nobody"; Crashlytics clears with an
    // empty identifier, which is its documented sign-out value.
    expect(recorder.callsFor('firebase_analytics').single.userId, isNull);
    expect(recorder.callsFor('crashlytics').single.userId, '');
    expect(recorder.callsFor('posthog').single.userId, isNull);
  });

  test('a blank id is treated as a sign-out', () async {
    final recorder = _RecordingSinks();
    UserIdentity.debugSetSinks(recorder.sinks);
    await UserIdentity.apply(_discordId);
    recorder.calls.clear();

    await UserIdentity.apply('   ');

    expect(recorder.callsFor('crashlytics').single.userId, '');
  });

  test('an id is trimmed before it is published', () async {
    final recorder = _RecordingSinks();
    UserIdentity.debugSetSinks(recorder.sinks);

    await UserIdentity.apply('  $_discordId  ');

    for (final call in recorder.calls) {
      expect(call.userId, _discordId);
    }
  });

  test('the same id is not published twice', () async {
    final recorder = _RecordingSinks();
    UserIdentity.debugSetSinks(recorder.sinks);

    // Session restore runs before every authenticated request: republishing a
    // known user on each of them would hit the SDKs hundreds of times a session.
    await UserIdentity.apply(_discordId);
    await UserIdentity.apply(_discordId);

    expect(recorder.calls, hasLength(3));
  });

  test('a sign-out clears, and the next login publishes again', () async {
    final recorder = _RecordingSinks();
    UserIdentity.debugSetSinks(recorder.sinks);

    await UserIdentity.apply(_discordId);
    await UserIdentity.apply(null);
    await UserIdentity.apply(_discordId);

    expect(
      recorder.callsFor('crashlytics').map((call) => call.userId),
      <String>[_discordId, '', _discordId],
    );
  });

  test('a failing SDK does not throw, and does not stop the others', () async {
    final recorder = _RecordingSinks(failingSdks: <String>{'crashlytics'});
    UserIdentity.debugSetSinks(recorder.sinks);

    // An uninitialised or absent SDK throws synchronously or rejects: either
    // way the login, the restore or the logout that triggered this must not
    // fail because of diagnostics.
    await expectLater(UserIdentity.apply(_discordId), completes);

    expect(recorder.callsFor('firebase_analytics').single.userId, _discordId);
    expect(recorder.callsFor('posthog').single.userId, _discordId);
  });

  test('the live sinks are inert while no SDK is initialised', () async {
    // No Firebase app, no PostHog key and no Crashlytics collection in a unit
    // test: this is the worst case, and it has to be a no-op. The setUp above
    // restored the live sinks, so this exercises the real wiring.
    await expectLater(UserIdentity.apply(_discordId), completes);
    await expectLater(UserIdentity.apply(null), completes);
  });
}
