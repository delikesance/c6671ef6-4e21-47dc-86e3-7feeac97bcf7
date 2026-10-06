import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Langue choisie par l'utilisateur. `null` = suivre la langue du navigateur.
///
/// Mémorisée dans le navigateur ; une valeur absente, illisible ou d'une
/// langue que le Studio ne gère pas retombe sur « suivre le navigateur ».
class LocaleController extends ChangeNotifier {
  static const _key = 'studio_locale_v1';

  Locale? _locale;
  Locale? get locale => _locale;

  /// Langue et nom écrit dans cette langue (jamais traduit : on doit pouvoir
  /// retrouver sa langue même quand on ne lit pas celle affichée).
  static const names = {
    'de': 'Deutsch',
    'en': 'English',
    'fr': 'Français',
    'ja': '日本語',
    'pt': 'Português',
    'tr': 'Türkçe',
  };

  static bool isSupported(String code) =>
      StudioLocalizations.supportedLocales.any((l) => l.languageCode == code);

  Future<void> load() async {
    try {
      final stored = (await SharedPreferences.getInstance()).getString(_key);
      if (stored != null && isSupported(stored)) {
        _locale = Locale(stored);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> set(Locale? value) async {
    if (value?.languageCode == _locale?.languageCode) return;
    _locale = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, value.languageCode);
      }
    } catch (_) {}
  }
}

/// Donne le [LocaleController] aux écrans (réglages) sans le passer partout.
class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope manquant au-dessus de ce widget');
    return scope!.notifier!;
  }
}
