import 'dart:ui' show Locale;

/// Supported application locales.
enum AppLocale {
  en('English', 'en'),
  fr('Français', 'fr');

  final String label;
  final String code;

  const AppLocale(this.label, this.code);
}

enum AppLocalePreference {
  system('Automatic', 'system'),
  en('English', 'en'),
  fr('Français', 'fr');

  final String label;
  final String code;

  const AppLocalePreference(this.label, this.code);
}

/// Detect a best-fit [AppLocale] from a platform [Locale].
AppLocale detectSystemLocale(Locale? systemLocale) {
  if (systemLocale == null) return AppLocale.en;

  final langCode = systemLocale.languageCode.toLowerCase();
  switch (langCode) {
    case 'fr':
      return AppLocale.fr;
    case 'en':
    default:
      return AppLocale.en;
  }
}
