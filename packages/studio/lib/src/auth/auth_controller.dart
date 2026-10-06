import 'dart:math';

import 'package:flutter/foundation.dart';

import '../api/studio_api.dart';
import '../config.dart';
import '../platform/platform.dart' as platform;
import 'studio_session.dart';

enum AuthStatus { loading, signedOut, signedIn, error }

/// Motif d'un retour à la connexion que le Studio explique lui-même : l'écran
/// de connexion le traduit, le contrôleur ne porte aucun texte.
enum AuthIssue { sessionExpired, discordRefused, invalidResponse }

/// Porte d'entrée du Studio : AUCUN écran de travail n'est montré tant que
/// [status] n'est pas [AuthStatus.signedIn], c'est-à-dire tant que le serveur
/// n'a pas validé la session Discord. Un jeton stocké mais refusé (révoqué,
/// expiré sans refresh possible) renvoie à la connexion.
class AuthController extends ChangeNotifier {
  AuthController({StudioApi? api, SessionStore? store})
    : api = api ?? StudioApi(baseUrl: StudioConfig.apiBaseUrl),
      _store = store ?? SessionStore() {
    this.api.accessToken = _accessToken;
  }

  final StudioApi api;
  final SessionStore _store;

  AuthStatus status = AuthStatus.loading;

  /// Message brut du serveur (ou de l'exception), quand [issue] n'en dit pas plus.
  String? errorMessage;

  /// Motif connu, à traduire à l'affichage ; [issueDetail] le complète
  /// (code d'erreur OAuth renvoyé par Discord).
  AuthIssue? issue;
  String? issueDetail;
  StudioSession? session;
  StudioPlan plan = StudioPlan.free;

  Future<void>? _refreshing;

  String get redirectUri => StudioConfig.redirectUriOverride.isNotEmpty
      ? StudioConfig.redirectUriOverride
      : '${platform.currentOrigin()}/';

  /// À appeler une fois au démarrage : traite un retour OAuth s'il y en a un,
  /// sinon restaure et VALIDE la session stockée.
  Future<void> init() async {
    final query = platform.currentUri().queryParameters;
    final code = (query['code'] ?? '').trim();
    final returnedState = (query['state'] ?? '').trim();
    final oauthError = (query['error'] ?? '').trim();
    final isCallback = code.isNotEmpty || oauthError.isNotEmpty;
    try {
      if (isCallback) {
        final expected = platform.readOAuthState();
        platform.clearOAuthState();
        platform.cleanCallbackUrl();
        if (oauthError.isNotEmpty) {
          return _signedOut(
            issue: AuthIssue.discordRefused,
            detail: oauthError,
          );
        }
        if (expected == null || expected != returnedState) {
          return _signedOut(issue: AuthIssue.invalidResponse);
        }
        session = await api.completeDiscordAuthorization(
          code: code,
          state: returnedState,
          redirectUri: redirectUri,
        );
        await _store.save(session!);
      } else {
        session = await _store.load();
        if (session == null) return _signedOut();
        if (session!.expiresSoon) {
          await _refresh();
          if (session == null) return _signedOut();
        }
      }
      await _validate();
    } on StudioApiException catch (e) {
      if (e.isUnauthorized) return _signedOut(issue: AuthIssue.sessionExpired);
      _fail(e.message);
    } on FormatException catch (e) {
      _signedOut(message: e.message);
    } catch (e) {
      _fail('$e');
    }
  }

  Future<void> _validate() async {
    await api.currentUser();
    plan = await api.fetchPlan();
    status = AuthStatus.signedIn;
    errorMessage = null;
    issue = null;
    issueDetail = null;
    notifyListeners();
  }

  Future<void> signIn() async {
    try {
      final start = await api.startDiscordAuthorization(
        redirectUri: redirectUri,
        state: _randomState(),
      );
      // L'état à retrouver au retour est celui du serveur, pas le nôtre.
      platform.writeOAuthState(start.state);
      platform.redirectTo(start.url);
    } on StudioApiException catch (e) {
      _signedOut(message: e.message);
    } catch (e) {
      _signedOut(message: '$e');
    }
  }

  Future<void> signOut() async {
    session = null;
    plan = StudioPlan.free;
    await _store.clear();
    _signedOut();
  }

  /// Jeton valide pour l'API. [force] ignore l'échéance (après un 401).
  Future<String?> _accessToken({bool force = false}) async {
    if (session == null) return null;
    if (force || session!.expiresSoon) {
      await _refresh();
      if (session == null) {
        _signedOut(issue: AuthIssue.sessionExpired);
        return null;
      }
    }
    return session?.accessToken;
  }

  Future<void> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<void> _doRefresh() async {
    final refreshToken = session?.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) {
      session = null;
      await _store.clear();
      return;
    }
    try {
      final next = await api.refreshSession(refreshToken);
      session = StudioSession(
        accessToken: next.accessToken,
        expiresAt: next.expiresAt,
        refreshToken: next.refreshToken ?? refreshToken,
        userId: next.userId ?? session?.userId,
        username: next.username ?? session?.username,
      );
      await _store.save(session!);
    } on StudioApiException catch (e) {
      if (!e.isUnauthorized) rethrow;
      session = null;
      await _store.clear();
    }
  }

  void _signedOut({String? message, AuthIssue? issue, String? detail}) {
    status = AuthStatus.signedOut;
    errorMessage = message;
    this.issue = issue;
    issueDetail = detail;
    notifyListeners();
  }

  void _fail(String message) {
    status = AuthStatus.error;
    errorMessage = message;
    issue = null;
    issueDetail = null;
    notifyListeners();
  }

  /// Relance la validation après une panne réseau.
  Future<void> retry() async {
    status = AuthStatus.loading;
    errorMessage = null;
    issue = null;
    issueDetail = null;
    notifyListeners();
    await init();
  }

  static String _randomState() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(
      24,
      (_) => alphabet[rnd.nextInt(alphabet.length)],
    ).join();
  }
}
