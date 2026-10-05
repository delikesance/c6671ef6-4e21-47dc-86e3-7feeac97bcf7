/// Configuration du Studio, surchargeable à la compilation :
/// `flutter build web --dart-define=STUDIO_API_URL=https://api.bot-creator.fr`.
abstract final class StudioConfig {
  /// API principale (celle de l'app). `dev.bot-creator.fr` pour le staging.
  static const String apiBaseUrl = String.fromEnvironment(
    'STUDIO_API_URL',
    defaultValue: 'https://api.bot-creator.fr',
  );

  /// URI de retour OAuth Discord. Vide = racine du site (`<origine>/`).
  /// Elle doit être déclarée côté serveur Bot Creator, comme celles de l'app.
  static const String redirectUriOverride = String.fromEnvironment(
    'STUDIO_REDIRECT_URI',
  );
}
