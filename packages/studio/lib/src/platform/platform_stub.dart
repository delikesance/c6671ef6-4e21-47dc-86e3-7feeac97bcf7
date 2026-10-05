// Repli hors navigateur (tests, outils) : tout reste en mémoire.
String? _state;

Uri currentUri() => Uri.base;
String currentOrigin() => 'http://localhost';
void redirectTo(String url) {}
String? readOAuthState() => _state;
void writeOAuthState(String value) => _state = value;
void clearOAuthState() => _state = null;
void cleanCallbackUrl() {}
