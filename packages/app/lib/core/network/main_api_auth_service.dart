import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter/foundation.dart';

class MainApiAuthService {
  MainApiAuthService._();

  static const int _desktopOAuthPort = 35641;
  static const String _mobileOAuthDomain = 'bot-creator.fr';
  static const String _mobileOAuthScheme = 'botcreator';
  static const String _mobileOAuthHost = 'oauth';
  static const String _mobileOAuthUniversalLinkPath = '/oauth/main-api/discord';
  static const String _mobileOAuthCustomSchemePath = '/main-api/discord';

  static void _oauthDebug(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[MainApi][OAuth] $message');
  }

  static Future<MainApiSession> connectWithDiscord({
    required MainApiClient client,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    _oauthDebug('connectWithDiscord timeout=${timeout.inSeconds}s');
    if (_supportsLoopbackCallback) {
      _oauthDebug('Using desktop loopback callback flow');
      return _connectDesktop(client: client, timeout: timeout);
    }
    _oauthDebug('Using mobile app-links callback flow');
    return _connectMobile(client: client, timeout: timeout);
  }

  static Future<MainApiSession> _connectDesktop({
    required MainApiClient client,
    required Duration timeout,
  }) async {
    final callbackServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      _desktopOAuthPort,
    );

    try {
      final localState = _generateState(24);
      final redirectUri =
          'http://localhost:$_desktopOAuthPort/oauth/main-api/discord';

      final start = await client.startDiscordAuthorization(
        redirectUri: redirectUri,
        state: localState,
      );

      final expectedState =
          start.state.trim().isEmpty ? localState : start.state;
      final launchUri = Uri.tryParse(start.authorizeUrl);
      if (launchUri == null) {
        throw const MainApiClientException(
          'Bot Creator Server returned an invalid authorization URL.',
        );
      }

      final launched = await openExternalUrl(launchUri);
      if (!launched) {
        throw const MainApiClientException(
          'Unable to open the system browser for Discord login.',
        );
      }

      HttpRequest callback;
      try {
        callback = await callbackServer.first.timeout(timeout);
      } on TimeoutException {
        throw const MainApiClientException(
          'Discord login timed out before the callback was received.',
        );
      }

      final query = callback.uri.queryParameters;
      final returnedState = (query['state'] ?? '').trim();
      final code = (query['code'] ?? '').trim();
      final error = (query['error'] ?? '').trim();

      callback.response.headers.contentType = ContentType.html;

      if (error.isNotEmpty) {
        callback.response.write(
          '<html><body>Discord login failed: $error. You can close this tab.</body></html>',
        );
        await callback.response.close();
        throw MainApiClientException('Discord login failed: $error');
      }

      if (code.isEmpty || returnedState != expectedState) {
        callback.response.write(
          '<html><body>Invalid callback state. You can close this tab and retry.</body></html>',
        );
        await callback.response.close();
        throw const MainApiClientException(
          'Invalid OAuth callback received from Discord login.',
        );
      }

      callback.response.write(
        '<html><body>Discord connected successfully. You can close this tab.</body></html>',
      );
      await callback.response.close();

      return client.completeDiscordAuthorization(
        code: code,
        state: expectedState,
        redirectUri: redirectUri,
      );
    } finally {
      await callbackServer.close(force: true);
    }
  }

  static Future<MainApiSession> _connectMobile({
    required MainApiClient client,
    required Duration timeout,
  }) async {
    final localState = _generateState(24);
    final redirectUri = _mobileHttpsRedirectUri.toString();
    _oauthDebug('Starting mobile OAuth redirectUri=$redirectUri');

    final start = await client.startDiscordAuthorization(
      redirectUri: redirectUri,
      state: localState,
    );

    final expectedState = start.state.trim().isEmpty ? localState : start.state;
    final launchUri = Uri.tryParse(start.authorizeUrl);
    _oauthDebug(
      'OAuth start received authorizeUrlValid=${launchUri != null} expectedStateLen=${expectedState.length}',
    );
    if (launchUri == null) {
      throw const MainApiClientException(
        'Bot Creator Server returned an invalid authorization URL.',
      );
    }

    final appLinks = AppLinks();
    final initialLinkBeforeLaunch = await appLinks.getInitialLink();
    _oauthDebug('Initial link before launch: $initialLinkBeforeLaunch');
    final callbackCompleter = Completer<Uri>();
    late final StreamSubscription<Uri> sub;
    sub = appLinks.uriLinkStream.listen(
      (uri) {
        _oauthDebug('uriLinkStream event uri=$uri');
        if (!_isExpectedMobileOAuthCallback(uri)) {
          _oauthDebug('Ignored uriLinkStream event (not expected callback)');
          return;
        }
        final returnedState = (uri.queryParameters['state'] ?? '').trim();
        if (returnedState.isNotEmpty && returnedState != expectedState) {
          _oauthDebug('Rejected callback due to invalid state');
          if (!callbackCompleter.isCompleted) {
            callbackCompleter.completeError(
              const MainApiClientException(
                'Invalid OAuth callback state received from Discord login.',
              ),
            );
          }
          return;
        }
        if (!callbackCompleter.isCompleted) {
          _oauthDebug('Accepted callback from uriLinkStream');
          callbackCompleter.complete(uri);
        }
      },
      onError: (Object error) {
        _oauthDebug('uriLinkStream error: $error');
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.completeError(error);
        }
      },
    );

    try {
      final launched = await openExternalUrl(launchUri);
      _oauthDebug('Browser launch result launched=$launched');
      if (!launched) {
        throw const MainApiClientException(
          'Unable to open the system browser for Discord login.',
        );
      }

      // Some launch modes deliver the callback as an initial link instead of stream event.
      final initialLinkAfterLaunch = await appLinks.getInitialLink();
      _oauthDebug('Initial link after launch: $initialLinkAfterLaunch');
      final isFreshInitialLink =
          !_isSameOAuthCallback(
            initialLinkBeforeLaunch,
            initialLinkAfterLaunch,
          );
      if (initialLinkAfterLaunch != null &&
          _isExpectedMobileOAuthCallback(initialLinkAfterLaunch) &&
          isFreshInitialLink &&
          !callbackCompleter.isCompleted) {
        _oauthDebug('Accepted callback from initial link');
        callbackCompleter.complete(initialLinkAfterLaunch);
      } else if (initialLinkAfterLaunch != null &&
          _isExpectedMobileOAuthCallback(initialLinkAfterLaunch) &&
          !isFreshInitialLink) {
        _oauthDebug('Ignored stale initial link (unchanged from pre-launch)');
      }

      Uri callback;
      try {
        callback = await callbackCompleter.future.timeout(timeout);
        _oauthDebug('Callback received: $callback');
      } on TimeoutException {
        _oauthDebug('Timeout waiting for mobile OAuth callback');
        throw const MainApiClientException(
          'Discord login timed out before the callback was received.',
        );
      }

      final code = (callback.queryParameters['code'] ?? '').trim();
      final error = (callback.queryParameters['error'] ?? '').trim();
      _oauthDebug(
        'Callback parsed hasCode=${code.isNotEmpty} hasError=${error.isNotEmpty}',
      );
      if (error.isNotEmpty) {
        throw MainApiClientException('Discord login failed: $error');
      }
      if (code.isEmpty) {
        throw const MainApiClientException(
          'Invalid OAuth callback received from Discord login.',
        );
      }

      return client.completeDiscordAuthorization(
        code: code,
        state: expectedState,
        redirectUri: redirectUri,
      );
    } finally {
      _oauthDebug('Canceling uriLinkStream subscription');
      await sub.cancel();
    }
  }

  static bool get _supportsLoopbackCallback {
    if (kIsWeb) {
      return false;
    }
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  static Uri get _mobileHttpsRedirectUri {
    return Uri(
      scheme: 'https',
      host: _mobileOAuthDomain,
      path: _mobileOAuthUniversalLinkPath,
    );
  }

  static bool _isExpectedMobileOAuthCallback(Uri uri) {
    final isUniversalLink =
        uri.scheme == 'https' &&
        uri.host == _mobileOAuthDomain &&
        uri.path == _mobileOAuthUniversalLinkPath;
    final isCustomScheme =
        uri.scheme == _mobileOAuthScheme &&
        uri.host == _mobileOAuthHost &&
        uri.path == _mobileOAuthCustomSchemePath;
    return isUniversalLink || isCustomScheme;
  }

  static bool _isSameOAuthCallback(Uri? a, Uri? b) {
    if (a == null || b == null) {
      return false;
    }
    return a.scheme == b.scheme &&
        a.host == b.host &&
        a.path == b.path &&
        (a.queryParameters['code'] ?? '') ==
            (b.queryParameters['code'] ?? '') &&
        (a.queryParameters['state'] ?? '') ==
            (b.queryParameters['state'] ?? '') &&
        (a.queryParameters['error'] ?? '') ==
            (b.queryParameters['error'] ?? '');
  }

  static String _generateState(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
