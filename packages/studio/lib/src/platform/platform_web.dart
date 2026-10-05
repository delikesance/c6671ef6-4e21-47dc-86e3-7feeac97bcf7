import 'package:web/web.dart' as web;

const _stateKey = 'studio_oauth_state';

Uri currentUri() => Uri.base;
String currentOrigin() => web.window.location.origin;
void redirectTo(String url) => web.window.location.assign(url);
String? readOAuthState() => web.window.sessionStorage.getItem(_stateKey);
void writeOAuthState(String value) =>
    web.window.sessionStorage.setItem(_stateKey, value);
void clearOAuthState() => web.window.sessionStorage.removeItem(_stateKey);

/// Retire `?code=…&state=…` de la barre d'adresse : un code OAuth est à usage
/// unique et ne doit ni rester dans l'historique ni être rejoué au rechargement.
void cleanCallbackUrl() {
  final loc = web.window.location;
  web.window.history.replaceState(null, '', '${loc.origin}${loc.pathname}');
}
