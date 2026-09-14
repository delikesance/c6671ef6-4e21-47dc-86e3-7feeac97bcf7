import 'dart:async';

import 'package:bot_creator/core/analytics/analytics.dart';

/// Where a bot creation started from.
///
/// `template` and `import` are values of the taxonomy that no flow emits yet
/// (the app has no bot-from-template creation and no bot import) — they are
/// declared so the console query does not have to change when those flows
/// land, and so the closed list is visible in one place.
enum BotCreateSource {
  scratch('scratch'),
  template('template'),
  import('import');

  const BotCreateSource(this.wire);

  /// The value sent to the console.
  final String wire;
}

/// Why a Discord login did not complete, as a closed list.
///
/// Never the raw error: `access_denied` from Discord, an HTTP body or a socket
/// message would each become a distinct parameter value, and the console
/// becomes unusable past ~100 of them.
enum LoginFailureReason {
  /// The user closed the browser tab, or Discord answered `access_denied`.
  cancelled('cancelled'),

  /// The callback never arrived before the flow's timeout.
  timeout('timeout'),

  /// The callback or the exchange never reached the server.
  network('network'),

  /// The server answered with an error.
  server('server'),

  /// A callback that does not belong to a login in flight.
  invalidCallback('invalid_callback'),

  /// Anything the mapping cannot classify.
  unknown('unknown');

  const LoginFailureReason(this.wire);

  /// The value sent to the console.
  final String wire;
}

/// Why starting a bot failed, as a closed list.
enum BotStartFailureReason {
  /// No Bot Creator session could be restored to start the bot.
  notSignedIn('not_signed_in'),

  /// The bot has no usable Discord token on this device.
  tokenMissing('token_missing'),

  /// The manager refused the start: no free runtime credit left.
  noCredit('no_credit'),

  /// The runner that owns this bot is not deployed or not reachable.
  runnerUnavailable('runner_unavailable'),

  /// The Android/iOS foreground service did not come up.
  foregroundService('foreground_service'),

  /// The start request never reached the runtime.
  network('network'),

  /// The runtime did not answer in time.
  timeout('timeout'),

  /// The Bot Creator servers answered an error, or are not ready.
  serverError('server_error'),

  /// Anything the mapping cannot classify.
  unknown('unknown');

  const BotStartFailureReason(this.wire);

  /// The value sent to the console.
  final String wire;
}

/// The activation funnel's events, in one place.
///
/// Every event goes out through [AppAnalytics.logEvent] — the app's single
/// sending mechanism, which already routes to Firebase Analytics on mobile and
/// iOS and to PostHog on desktop. This class adds no transport of its own: it
/// names the events, bounds their parameters to closed lists, and maps raw
/// errors onto the bounded reasons the console can group by.
///
/// Funnel: `app_open` → onboarding → `discord_login_*` → `bot_create_*` →
/// `command_create_success` → `bot_start` / `bot_start_failed`.
///
/// Every call is placed where the outcome is real — after the session, the
/// save or the runtime confirmation — never on a tap.
class ActivationFunnel {
  ActivationFunnel._();

  /// Closed values of the `action_count_bucket` parameter of
  /// `command_create_success`.
  static const List<String> actionCountBuckets = <String>[
    '0',
    '1-5',
    '6-20',
    '21+',
  ];

  /// The OAuth flow started: a browser is about to open on Discord.
  static Future<void> discordLoginStart() =>
      AppAnalytics.logEvent(name: 'discord_login_start');

  /// A Discord session was returned by the server and is now the app's
  /// identity. Logged where the session exists, not where the button was
  /// pressed.
  static Future<void> discordLoginSuccess() =>
      AppAnalytics.logEvent(name: 'discord_login_success');

  /// The login did not complete. [error] is classified, never sent.
  static Future<void> discordLoginFailed(Object? error) =>
      AppAnalytics.logEvent(
        name: 'discord_login_failed',
        parameters: <String, Object>{'reason': loginFailureReason(error).wire},
      );

  /// The user submitted a bot creation. Logged after the input guards, at the
  /// first step that can actually create the bot.
  static Future<void> botCreateStart({required BotCreateSource source}) =>
      AppAnalytics.logEvent(
        name: 'bot_create_start',
        parameters: <String, Object>{'source': source.wire},
      );

  /// The bot exists on this device: the local write returned.
  static Future<void> botCreateSuccess({required BotCreateSource source}) =>
      AppAnalytics.logEvent(
        name: 'bot_create_success',
        parameters: <String, Object>{'source': source.wire},
      );

  /// A bot was confirmed running by the runtime that owns it.
  static Future<void> botStart() => AppAnalytics.logEvent(name: 'bot_start');

  /// The start attempt ended without a running bot. [error] is classified,
  /// never sent.
  static Future<void> botStartFailed(Object? error) => AppAnalytics.logEvent(
    name: 'bot_start_failed',
    parameters: <String, Object>{'reason': botStartFailureReason(error).wire},
  );

  /// A command was saved and handed to the runtime. [actionCount] is reduced
  /// to a bucket: the exact count is a value of its own and would only add
  /// cardinality.
  static Future<void> commandCreateSuccess({
    required bool isNew,
    required int actionCount,
  }) => AppAnalytics.logEvent(
    name: 'command_create_success',
    parameters: <String, Object>{
      'is_new': isNew ? 'true' : 'false',
      'action_count_bucket': actionCountBucket(actionCount),
    },
  );

  /// Reduces an action count to one of [actionCountBuckets].
  static String actionCountBucket(int actionCount) {
    if (actionCount <= 0) return actionCountBuckets[0];
    if (actionCount <= 5) return actionCountBuckets[1];
    if (actionCount <= 20) return actionCountBuckets[2];
    return actionCountBuckets[3];
  }

  /// Classifies a login failure onto [LoginFailureReason].
  ///
  /// Order matters: an explicit cancellation wins over what it carries, and a
  /// timeout is a timeout even when its message names the server.
  static LoginFailureReason loginFailureReason(Object? error) {
    if (error is TimeoutException) return LoginFailureReason.timeout;

    final text = error?.toString().toLowerCase() ?? '';

    if (text.contains('access_denied') || text.contains('cancel')) {
      return LoginFailureReason.cancelled;
    }
    if (text.contains('no pending mobile oauth') ||
        text.contains('missing code') ||
        text.contains('invalid oauth callback') ||
        text.contains('state mismatch')) {
      return LoginFailureReason.invalidCallback;
    }
    if (text.contains('timed out') || text.contains('timeout')) {
      return LoginFailureReason.timeout;
    }
    if (text.contains('socketexception') ||
        text.contains('handshakeexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection closed')) {
      return LoginFailureReason.network;
    }
    if (text.contains('bot creator server') ||
        text.contains('401') ||
        text.contains('403') ||
        text.contains('500') ||
        text.contains('502') ||
        text.contains('503') ||
        text.contains('server')) {
      return LoginFailureReason.server;
    }
    return LoginFailureReason.unknown;
  }

  /// Classifies a failed bot start onto [BotStartFailureReason].
  ///
  /// Mirrors the failures the start paths actually raise: the messages of
  /// `home_page.dart` / `home.logic.part.dart`, and the manager diagnostics of
  /// `remote_runtime.dart` (`runner_not_deployed`, `runner is unreachable`,
  /// `free runtime credits before start`, `Bot Creator servers are not
  /// ready`).
  static BotStartFailureReason botStartFailureReason(Object? error) {
    if (error is TimeoutException) return BotStartFailureReason.timeout;

    final text = error?.toString().toLowerCase() ?? '';

    if (text.contains('sign in to bot creator') ||
        text.contains('connectez-vous a bot creator')) {
      return BotStartFailureReason.notSignedIn;
    }
    if (text.contains('credit') || text.contains('free runtime')) {
      return BotStartFailureReason.noCredit;
    }
    if (text.contains('token not found') || text.contains('token missing')) {
      return BotStartFailureReason.tokenMissing;
    }
    if (text.contains('runner')) {
      return BotStartFailureReason.runnerUnavailable;
    }
    if (text.contains('foreground service') ||
        text.contains('notification permission')) {
      return BotStartFailureReason.foregroundService;
    }
    if (text.contains('timed out') || text.contains('timeout')) {
      return BotStartFailureReason.timeout;
    }
    if (text.contains('socketexception') ||
        text.contains('handshakeexception') ||
        text.contains('clientexception') ||
        text.contains('failed host lookup') ||
        text.contains('connection refused') ||
        text.contains('connection closed')) {
      return BotStartFailureReason.network;
    }
    if (text.contains('bot creator server') || text.contains('server')) {
      return BotStartFailureReason.serverError;
    }
    return BotStartFailureReason.unknown;
  }
}
