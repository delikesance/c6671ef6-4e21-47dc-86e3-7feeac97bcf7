import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:bot_creator/utils/external_link.dart';
import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:flutter/foundation.dart';

class MainApiAuthService {
  MainApiAuthService._();

  static const String _mobileOAuthDomain = 'bot-creator.fr';
  static const String _mobileOAuthScheme = 'botcreator';
  static const String _mobileOAuthHost = 'oauth';
  static const String _mobileOAuthPath = '/oauth/main-api/discord';

  static Future<MainApiSession> connectWithDiscord({
    required MainApiClient client,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    if (_supportsLoopbackCallback) {
      return _connectDesktop(client: client, timeout: timeout);
    }
    return _connectMobile(client: client, timeout: timeout);
  }

  static Future<MainApiSession> _connectDesktop({
    required MainApiClient client,
    required Duration timeout,
  }) async {
    final callbackServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );

    try {
      final localState = _generateState(24);
      final redirectUri =
          'http://localhost:${callbackServer.port}/oauth/main-api/discord';

      final start = await client.startDiscordAuthorization(
        redirectUri: redirectUri,
        state: localState,
      );

      final expectedState =
          start.state.trim().isEmpty ? localState : start.state;
      final launchUri = Uri.tryParse(start.authorizeUrl);
      if (launchUri == null) {
        throw const MainApiClientException(
          'Main API returned an invalid authorization URL.',
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
    final redirectUri = _mobileRedirectUri.toString();

    final start = await client.startDiscordAuthorization(
      redirectUri: redirectUri,
      state: localState,
    );

    final expectedState = start.state.trim().isEmpty ? localState : start.state;
    final launchUri = Uri.tryParse(start.authorizeUrl);
    if (launchUri == null) {
      throw const MainApiClientException(
        'Main API returned an invalid authorization URL.',
      );
    }

    final appLinks = AppLinks();
    final callbackCompleter = Completer<Uri>();
    late final StreamSubscription<Uri> sub;
    sub = appLinks.uriLinkStream.listen(
      (uri) {
        if (!_isExpectedMobileOAuthCallback(uri)) {
          return;
        }
        final returnedState = (uri.queryParameters['state'] ?? '').trim();
        if (returnedState.isNotEmpty && returnedState != expectedState) {
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
          callbackCompleter.complete(uri);
        }
      },
      onError: (Object error) {
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.completeError(error);
        }
      },
    );

    try {
      final launched = await openExternalUrl(launchUri);
      if (!launched) {
        throw const MainApiClientException(
          'Unable to open the system browser for Discord login.',
        );
      }

      Uri callback;
      try {
        callback = await callbackCompleter.future.timeout(timeout);
      } on TimeoutException {
        throw const MainApiClientException(
          'Discord login timed out before the callback was received.',
        );
      }

      final code = (callback.queryParameters['code'] ?? '').trim();
      final error = (callback.queryParameters['error'] ?? '').trim();
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
      await sub.cancel();
    }
  }

  static bool get _supportsLoopbackCallback {
    if (kIsWeb) {
      return false;
    }
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  static Uri get _mobileRedirectUri {
    return Uri(
      scheme: 'https',
      host: _mobileOAuthDomain,
      path: _mobileOAuthPath,
    );
  }

  static bool _isExpectedMobileOAuthCallback(Uri uri) {
    final pathMatches = uri.path == _mobileOAuthPath;
    if (!pathMatches) {
      return false;
    }
    final isUniversalLink =
        uri.scheme == 'https' && uri.host == _mobileOAuthDomain;
    final isCustomScheme =
        uri.scheme == _mobileOAuthScheme && uri.host == _mobileOAuthHost;
    return isUniversalLink || isCustomScheme;
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
