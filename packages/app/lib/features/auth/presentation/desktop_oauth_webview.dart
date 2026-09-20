import 'dart:async';
import 'dart:io';
import 'package:desktop_webview_window/desktop_webview_window.dart';
import 'package:flutter/foundation.dart';

/// Fenetre embarquee (WebKit sous Linux) pour l'autorisation OAuth sur desktop.
///
/// REPLI, pas chemin nominal : `MainApiAuthService._connectDesktop` ouvre
/// D'ABORD le navigateur du systeme. Cette fenetre ne sert que la ou aucun
/// navigateur n'est disponible, parce que le moteur embarque ne sait pas
/// toujours charger la page d'autorisation (sous Linux, WebKitGTK echoue sur
/// discord.com par une erreur interne : fenetre blanche, consentement jamais
/// rendu, connexion perdue au bout du delai).
///
/// Elle ne peut pas non plus se faire passer pour Chrome : le plugin n'expose
/// que `setApplicationNameForUserAgent`, qui AJOUTE un nom d'application a l'UA
/// par defaut au lieu de la remplacer — la constante ci-dessous n'est donc pas
/// l'UA reellement envoyee.
class DesktopOAuthWebView {
  DesktopOAuthWebView._();

  static const String _desktopUserAgent =
      'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';

  /// Opens the OAuth authorization URL in a desktop webview window.
  /// Resolves or cleans up when the webview closes or completion triggers.
  static Future<Webview?> open({
    required Uri authorizeUri,
    required String redirectUri,
    String title = 'Bot Creator - Discord Authorization',
    int width = 720,
    int height = 800,
  }) async {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      return null;
    }

    try {
      final isAvailable = await WebviewWindow.isWebviewAvailable();
      if (!isAvailable) {
        debugPrint(
          '[DesktopOAuthWebView] Webview runtime is not available on this system.',
        );
        return null;
      }

      final webview = await WebviewWindow.create(
        configuration: CreateConfiguration(
          windowWidth: width,
          windowHeight: height,
          title: title,
          titleBarHeight: 38,
          useWindowPositionAndSize: false,
        ),
      );

      // Avoid Google OAuth disallowed_useragent blocks
      await webview.setApplicationNameForUserAgent(_desktopUserAgent);

      webview.launch(authorizeUri.toString());
      return webview;
    } catch (e) {
      debugPrint(
        '[DesktopOAuthWebView] Failed to launch desktop webview window: $e',
      );
      return null;
    }
  }
}
