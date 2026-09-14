// The activation funnel is read in the Firebase console: the events have to
// carry the names the console queries expect, and their parameters have to stay
// inside closed lists. A single unbounded value — a bot id, a command id, a
// duration — cannot be removed from the console afterwards, so the tests below
// fix two contracts:
//
//   1. every funnel event leaves through `AppAnalytics` (the app's one sending
//      mechanism), with the exact parameter names the taxonomy declares;
//   2. every parameter value is one of a bounded set, and the tests fail on any
//      parameter the taxonomy does not know — an unnamed id or duration cannot
//      slip in unnoticed.
//
// The error mappings are tested on the messages the app really throws, so a
// reworded exception shows up as a failing test rather than as a new, silent
// `unknown` bucket in the console.

import 'dart:async';

import 'package:bot_creator/core/analytics/activation_funnel.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/analytics/user_properties.dart';
import 'package:flutter_test/flutter_test.dart';

/// One event as it left [AppAnalytics].
class _Event {
  _Event(this.name, this.parameters);

  final String name;
  final Map<String, Object?> parameters;
}

/// One user property as it left [AppAnalytics].
class _Property {
  _Property(this.name, this.value);

  final String name;
  final String value;
}

/// Records what the funnel sends, through the injection point `AppAnalytics`
/// exposes for tests.
class _Recorder {
  final List<_Event> events = <_Event>[];
  final List<_Property> properties = <_Property>[];

  void install() {
    AppAnalytics.debugSetEventObserver(
      (name, parameters) =>
          events.add(_Event(name, parameters ?? const <String, Object?>{})),
    );
    AppAnalytics.debugSetUserPropertyObserver(
      (name, value) => properties.add(_Property(name, value)),
    );
  }

  _Event get single => events.single;

  List<_Event> eventsNamed(String name) =>
      events.where((event) => event.name == name).toList(growable: false);
}

/// Every parameter the taxonomy may send, with the closed list it draws from.
///
/// A parameter absent from this map fails the tests: that is the guard against
/// someone adding `bot_id` or `duration_ms` to a funnel event.
const Map<String, List<String>> _closedValues = <String, List<String>>{
  'source': <String>['scratch', 'template', 'import'],
  'reason': <String>[
    // discord_login_failed
    'cancelled',
    'timeout',
    'network',
    'server',
    'invalid_callback',
    'unknown',
    // bot_start_failed
    'not_signed_in',
    'token_missing',
    'no_credit',
    'runner_unavailable',
    'foreground_service',
    'server_error',
  ],
  'is_new': <String>['true', 'false'],
  'action_count_bucket': ActivationFunnel.actionCountBuckets,
};

/// The event names of this slice, in funnel order.
const List<String> _funnelEvents = <String>[
  'onboarding_step_view',
  'onboarding_completed',
  'discord_login_start',
  'discord_login_success',
  'discord_login_failed',
  'bot_create_start',
  'bot_create_success',
  'bot_start',
  'bot_start_failed',
  'command_create_success',
];

final RegExp _snakeCase = RegExp(r'^[a-z][a-z0-9_]*$');

/// A snowflake, an id or a duration in milliseconds: a bare digit run long
/// enough to be one of them.
final RegExp _looksLikeAnIdOrDuration = RegExp(r'^\d{6,}$');

void main() {
  late _Recorder recorder;

  setUp(() {
    recorder = _Recorder()..install();
  });

  tearDown(() {
    AppAnalytics.debugResetObservers();
    AppUserProperties.debugResetSources();
  });

  test('every funnel event leaves through AppAnalytics', () async {
    await ActivationFunnel.onboardingStepView(step: 1);
    await ActivationFunnel.onboardingCompleted(finalStep: 5);
    await ActivationFunnel.discordLoginStart();
    await ActivationFunnel.discordLoginSuccess();
    await ActivationFunnel.discordLoginFailed('something went wrong');
    await ActivationFunnel.botCreateStart(source: BotCreateSource.scratch);
    await ActivationFunnel.botCreateSuccess(source: BotCreateSource.scratch);
    await ActivationFunnel.botStart();
    await ActivationFunnel.botStartFailed('something went wrong');
    await ActivationFunnel.commandCreateSuccess(isNew: true, actionCount: 1);

    expect(
      recorder.events.map((event) => event.name),
      _funnelEvents,
      reason: 'the console queries are written against these exact names',
    );
    expect(recorder.properties, isEmpty);
  });

  test('no event parameter is an id, a duration or free text', () async {
    // The worst case for cardinality: the values a caller could hand over.
    await ActivationFunnel.botCreateStart(source: BotCreateSource.template);
    await ActivationFunnel.botCreateSuccess(source: BotCreateSource.import);
    await ActivationFunnel.discordLoginFailed(
      Exception('HTTP 429 for bot 189345600000000000 after 3200 ms'),
    );
    await ActivationFunnel.botStartFailed(
      Exception('Token not found for bot 189345600000000000'),
    );
    await ActivationFunnel.commandCreateSuccess(isNew: false, actionCount: 37);

    for (final event in recorder.events) {
      expect(
        _snakeCase.hasMatch(event.name),
        isTrue,
        reason: '${event.name} is not snake_case',
      );
      expect(event.name.length, lessThanOrEqualTo(40));
      for (final entry in event.parameters.entries) {
        final name = entry.key;
        final value = entry.value.toString();

        expect(
          _snakeCase.hasMatch(name),
          isTrue,
          reason: '$name is not snake_case',
        );
        expect(name.length, lessThanOrEqualTo(40), reason: name);
        expect(value.length, lessThanOrEqualTo(100), reason: name);
        expect(
          _looksLikeAnIdOrDuration.hasMatch(value),
          isFalse,
          reason: '$name carries what looks like an id or a duration: $value',
        );
        expect(
          _closedValues.containsKey(name),
          isTrue,
          reason:
              '$name is not part of the taxonomy: an undeclared parameter is '
              'how an id or a duration reaches the console',
        );
        expect(
          _closedValues[name],
          contains(value),
          reason: '$value is outside the closed list of $name',
        );
      }
    }

    // The bucket replaced the raw count, and the raw count is nowhere.
    final command = recorder.eventsNamed('command_create_success').single;
    expect(command.parameters['action_count_bucket'], '21+');
    expect(command.parameters.values, isNot(contains('37')));
    expect(
      recorder.eventsNamed('bot_start_failed').single.parameters['reason'],
      'token_missing',
    );
    expect(
      recorder
          .eventsNamed('discord_login_failed')
          .single
          .parameters
          .values
          .contains('189345600000000000'),
      isFalse,
    );
  });

  test('a login failure is classified, never sent raw', () async {
    final cases = <Object?, LoginFailureReason>{
      TimeoutException('no callback'): LoginFailureReason.timeout,
      'Discord login failed: access_denied': LoginFailureReason.cancelled,
      'Discord login timed out before the callback was received.':
          LoginFailureReason.timeout,
      Exception('SocketException: Failed host lookup'):
          LoginFailureReason.network,
      'Bot Creator Server returned an invalid authorization URL.':
          LoginFailureReason.server,
      'state mismatch': LoginFailureReason.invalidCallback,
      'missing code': LoginFailureReason.invalidCallback,
      'no pending mobile oauth context': LoginFailureReason.invalidCallback,
      Object(): LoginFailureReason.unknown,
    };

    for (final entry in cases.entries) {
      expect(
        ActivationFunnel.loginFailureReason(entry.key),
        entry.value,
        reason: '${entry.key}',
      );
    }
  });

  test('a failed bot start is classified onto the closed list', () async {
    final cases = <Object?, BotStartFailureReason>{
      'Sign in to Bot Creator in Settings before starting this bot.':
          BotStartFailureReason.notSignedIn,
      'Token not found for MyBot': BotStartFailureReason.tokenMissing,
      Exception('bot_free_time_required: no free runtime credits before start'):
          BotStartFailureReason.noCredit,
      'The embedded JS runner could not start. Fully restart the app.':
          BotStartFailureReason.runnerUnavailable,
      'Foreground service did not start.':
          BotStartFailureReason.foregroundService,
      TimeoutException('start'): BotStartFailureReason.timeout,
      Exception('SocketException: Connection refused'):
          BotStartFailureReason.network,
      'Invalid bot ID for startup on Bot Creator servers.':
          BotStartFailureReason.serverError,
      Object(): BotStartFailureReason.unknown,
    };

    for (final entry in cases.entries) {
      expect(
        ActivationFunnel.botStartFailureReason(entry.key),
        entry.value,
        reason: '${entry.key}',
      );
    }
  });

  test('the counters are reduced to the declared buckets', () {
    expect(ActivationFunnel.actionCountBucket(0), '0');
    expect(ActivationFunnel.actionCountBucket(1), '1-5');
    expect(ActivationFunnel.actionCountBucket(5), '1-5');
    expect(ActivationFunnel.actionCountBucket(6), '6-20');
    expect(ActivationFunnel.actionCountBucket(20), '6-20');
    expect(ActivationFunnel.actionCountBucket(21), '21+');
    expect(ActivationFunnel.actionCountBucket(4000), '21+');

    expect(AppUserProperties.botCountBucket(0), '0');
    expect(AppUserProperties.botCountBucket(1), '1');
    expect(AppUserProperties.botCountBucket(2), '2-5');
    expect(AppUserProperties.botCountBucket(5), '2-5');
    expect(AppUserProperties.botCountBucket(6), '6+');
    expect(AppUserProperties.botCountBucket(120), '6+');
  });

  test('the user properties are the four funnel dimensions', () async {
    AppUserProperties.debugSetSources(
      botCount: () async => 3,
      isPremium: () => false,
      languageCode: () async => 'fr',
    );

    await AppUserProperties.refresh();

    expect(recorder.properties.map((property) => property.name), <String>[
      'platform',
      'premium_tier',
      'bot_count_bucket',
      'locale',
    ]);
    expect(recorder.properties.map((property) => property.value), <String>[
      AppUserProperties.platformName(),
      'free',
      '2-5',
      'fr',
    ]);
    for (final property in recorder.properties) {
      // A user property cannot be purged from the console: same bounded-value
      // rule as an event parameter, and never an id.
      expect(_looksLikeAnIdOrDuration.hasMatch(property.value), isFalse);
      expect(property.value.length, lessThanOrEqualTo(100));
      expect(_snakeCase.hasMatch(property.name), isTrue);
    }
    expect(AppUserProperties.platformName(), isIn(AppUserProperties.platforms));
  });

  test('a subscribed user is bucketed as premium', () async {
    AppUserProperties.debugSetSources(
      botCount: () async => 0,
      isPremium: () => true,
      languageCode: () async => 'en',
    );

    await AppUserProperties.refresh();

    final tiers = recorder.properties
        .where((property) => property.name == 'premium_tier')
        .map((property) => property.value);
    expect(tiers, <String>['premium']);
    expect(AppUserProperties.premiumTiers, contains('premium'));
  });

  test('an unreachable source still publishes a bounded value', () async {
    // The startup warm-up must not fail because the bot store or the
    // preferences are unavailable: a bounded default is better than a missing
    // dimension.
    AppUserProperties.debugSetSources(
      botCount: () async => throw StateError('no store'),
      isPremium: () => throw StateError('no billing'),
      languageCode: () async => throw StateError('no prefs'),
    );

    await expectLater(AppUserProperties.refresh(), completes);

    expect(recorder.properties.map((property) => property.value), <String>[
      AppUserProperties.platformName(),
      'free',
      '0',
      AppUserProperties.fallbackLocale,
    ]);
  });
}
