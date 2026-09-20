import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:app_links/app_links.dart';
import 'package:bot_creator/core/analytics/activation_funnel.dart';
import 'package:bot_creator/core/analytics/user_identity.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/auth/presentation/desktop_oauth_webview.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainApiAuthService {
  MainApiAuthService._();

  static const int _desktopOAuthPort = 35641;
  static const String _mobileOAuthDomain = 'bot-creator.fr';
  static const String _mobileOAuthScheme = 'botcreator';
  static const String _mobileOAuthHost = 'oauth';
  static const String _mobileOAuthUniversalLinkPath = '/oauth/main-api/discord';
  static const String _mobileOAuthCustomSchemePath = '/main-api/discord';
  static const String _pendingOAuthKey = 'main_api_pending_oauth';

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
    // The flow starts here: a browser is about to open on Discord.
    unawaited(ActivationFunnel.discordLoginStart());
    final MainApiSession session;
    try {
      if (_supportsLoopbackCallback) {
        _oauthDebug('Using desktop loopback callback flow');
        session = await _connectDesktop(client: client, timeout: timeout);
      } else {
        _oauthDebug('Using mobile app-links callback flow');
        session = await _connectMobile(client: client, timeout: timeout);
      }
    } catch (error) {
      // Classified, never the raw message: a Discord error code or an HTTP
      // body would each become its own parameter value in the console.
      unawaited(ActivationFunnel.discordLoginFailed(error));
      rethrow;
    }

    // Login is where the Discord account becomes known: publish it to the
    // diagnostics and analytics SDKs before anything else can report. Not
    // awaited — the identity fan-out must not delay the login completing.
    unawaited(UserIdentity.apply(session.userId));
    unawaited(ActivationFunnel.discordLoginSuccess());
    return session;
  }

  /// Completes a pending mobile OAuth callback after a cold start or app relaunch.
  static Future<bool> tryCompleteMobileOAuthCallback(Uri callbackUri) async {
    if (!_isExpectedMobileOAuthCallback(callbackUri)) {
      return false;
    }

    final pending = await _loadPendingMobileOAuth();
    if (pending == null) {
      _oauthDebug('No pending mobile OAuth context found');
      unawaited(
        ActivationFunnel.discordLoginFailed('no pending mobile oauth context'),
      );
      return false;
    }

    final error = (callbackUri.queryParameters['error'] ?? '').trim();
    if (error.isNotEmpty) {
      await _clearPendingMobileOAuth();
      _oauthDebug('Pending OAuth callback returned error=$error');
      unawaited(ActivationFunnel.discordLoginFailed('Discord login: $error'));
      return false;
    }

    final code = (callbackUri.queryParameters['code'] ?? '').trim();
    final returnedState = (callbackUri.queryParameters['state'] ?? '').trim();
    if (code.isEmpty) {
      _oauthDebug('Pending OAuth callback missing code');
      unawaited(ActivationFunnel.discordLoginFailed('missing code'));
      return false;
    }
    if (returnedState.isNotEmpty && returnedState != pending.expectedState) {
      _oauthDebug('Pending OAuth callback state mismatch');
      unawaited(ActivationFunnel.discordLoginFailed('state mismatch'));
      return false;
    }

    try {
      final client = MainApiClient(baseUrl: pending.baseUrl);
      final session = await client.completeDiscordAuthorization(
        code: code,
        state: pending.expectedState,
        redirectUri: pending.redirectUri,
      );
      await MainApiSettingsStore.saveSession(
        session.copyWith(authMethod: MainApiAuthMethod.discordOauth),
      );
      await _clearPendingMobileOAuth();
      // This path completes a login without going through connectWithDiscord
      // (cold start on a callback deep link): the identity has to be published
      // here too, or the user's first session after a relaunch is anonymous.
      unawaited(UserIdentity.apply(session.userId));
      unawaited(ActivationFunnel.discordLoginSuccess());
      _oauthDebug('Pending mobile OAuth callback completed successfully');
      return true;
    } catch (error) {
      _oauthDebug('Pending mobile OAuth completion failed: $error');
      unawaited(ActivationFunnel.discordLoginFailed(error));
      return false;
    }
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

      final expectedState = start.state.trim().isEmpty
          ? localState
          : start.state;
      final launchUri = Uri.tryParse(start.authorizeUrl);
      if (launchUri == null) {
        throw const MainApiClientException(
          'Bot Creator Server returned an invalid authorization URL.',
        );
      }

      // LE NAVIGATEUR D'ABORD, la fenetre embarquee ensuite.
      //
      // La fenetre WebKit ne sait pas toujours charger la page d'autorisation :
      // sous Linux (WebKitGTK), discord.com echoue par une erreur interne de
      // WebKit, la fenetre reste blanche, le consentement n'arrive jamais et la
      // connexion meurt au bout du delai — l'utilisateur ne voit qu'une fenetre
      // vide et n'a aucun moyen de continuer. Le navigateur du systeme affiche
      // la page dans tous les cas, et le retour se fait de toute facon sur le
      // serveur local (http://localhost:_desktopOAuthPort) : c'est le chemin
      // prevu, la fenetre embarquee n'en est plus qu'un repli, pour les
      // environnements sans navigateur (xdg-open absent, pas de session
      // graphique).
      final browserOpened = await openExternalUrl(launchUri);
      Webview? webview;
      if (!browserOpened) {
        webview = await DesktopOAuthWebView.open(
          authorizeUri: launchUri,
          redirectUri: redirectUri,
        );
        if (webview == null) {
          throw const MainApiClientException(
            'Unable to open browser or in-app window for Discord login.',
          );
        }
      }

      HttpRequest callback;
      try {
        callback = await callbackServer.first.timeout(timeout);
      } on TimeoutException {
        webview?.close();
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
      webview?.close();

      return await client.completeDiscordAuthorization(
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
          // A mismatched state means this callback belongs to another attempt —
          // a stale deep link, or a second login started in parallel. It must
          // not abort the login in flight: the matching callback is still on
          // its way, so ignore this one and let the timeout own the failure.
          _oauthDebug('Ignored callback with mismatched state (stale/foreign)');
          AppDiagnostics.logBreadcrumb(
            'OAuth callback ignored: state mismatch (stale or foreign callback)',
          );
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

    await _savePendingMobileOAuth(
      PendingMobileOAuth(
        expectedState: expectedState,
        redirectUri: redirectUri,
        baseUrl: client.baseUrl,
      ),
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
      final isFreshInitialLink = !_isSameOAuthCallback(
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

      final session = await client.completeDiscordAuthorization(
        code: code,
        state: expectedState,
        redirectUri: redirectUri,
      );
      await _clearPendingMobileOAuth();
      return session;
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

  static Future<void> _savePendingMobileOAuth(
    PendingMobileOAuth pending,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOAuthKey, jsonEncode(pending.toJson()));
  }

  static Future<PendingMobileOAuth?> _loadPendingMobileOAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingOAuthKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return PendingMobileOAuth.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<void> _clearPendingMobileOAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingOAuthKey);
  }
}

class PendingMobileOAuth {
  const PendingMobileOAuth({
    required this.expectedState,
    required this.redirectUri,
    required this.baseUrl,
  });

  final String expectedState;
  final String redirectUri;
  final String baseUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'expectedState': expectedState,
    'redirectUri': redirectUri,
    'baseUrl': baseUrl,
  };

  factory PendingMobileOAuth.fromJson(Map<String, dynamic> json) {
    return PendingMobileOAuth(
      expectedState: (json['expectedState'] ?? '').toString(),
      redirectUri: (json['redirectUri'] ?? '').toString(),
      baseUrl: (json['baseUrl'] ?? '').toString(),
    );
  }
}
