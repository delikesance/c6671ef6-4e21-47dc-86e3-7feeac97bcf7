import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_appearance.dart';

/// Apparence de l'application : mode clair/sombre, preset de couleurs et
/// personnalisations (graine + accent), persistés en JSON.
///
/// Deux clés de `SharedPreferences` cohabitent le temps de la migration :
///   * `app_appearance` — configuration complète (JSON), écrite par ce
///     provider ;
///   * `theme_mode` — ANCIENNE clé (mode seul) : lue une dernière fois au
///     démarrage pour initialiser le mode, puis supprimée.
class ThemeProvider extends ChangeNotifier {
  /// Clé de la configuration d'apparence complète.
  static const _key = 'app_appearance';

  /// Ancienne clé, conservée uniquement pour la migration.
  static const _legacyKey = 'theme_mode';

  AppAppearanceConfig _appearance = AppAppearanceConfig.defaults;

  /// Config d'apparence courante (mode + couleurs).
  AppAppearanceConfig get appearance => _appearance;

  /// Mode clair/sombre/système (raccourci consommé par `MaterialApp`).
  ThemeMode get themeMode => _appearance.mode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _appearance = AppAppearanceConfig.decode(saved);
      // Migration déjà faite : l'ancienne clé de mode n'a plus de raison d'être.
      if (prefs.containsKey(_legacyKey)) {
        await prefs.remove(_legacyKey);
      }
    } else {
      // Migration : la seule information disponible est l'ancien mode.
      final legacyMode = _legacyModeFrom(prefs);
      _appearance = _appearance.copyWith(mode: legacyMode);
      if (prefs.containsKey(_legacyKey)) {
        await _persist();
        await prefs.remove(_legacyKey);
      }
    }
    notifyListeners();
  }

  /// Mode lu dans l'ancienne clé `theme_mode` (cette version ne l'écrit plus) ;
  /// toute valeur absente ou inconnue vaut sombre, comme avant.
  ThemeMode _legacyModeFrom(SharedPreferences prefs) =>
      prefs.getString(_legacyKey) == 'light' ? ThemeMode.light : ThemeMode.dark;

  Future<void> setMode(ThemeMode mode) =>
      _update(_appearance.copyWith(mode: mode));

  /// Applique un preset : graine et accent reprennent ses couleurs (les
  /// personnalisations précédentes sont donc remplacées). L'accent persisté
  /// est la variante CLAIRE ([AppAppearancePreset.accentLight]) — référence
  /// stable du preset, indépendante du mode : la variante peinte suit le mode
  /// courant (`AppAppearanceConfig.accentFor`).
  Future<void> setPreset(AppAppearancePreset preset) => _update(
    _appearance.copyWith(
      presetId: preset.id,
      seedColor: preset.seed,
      accentColor: preset.accentLight,
    ),
  );

  /// Personnalisation de l'accent d'action (boutons, focus, états actifs).
  Future<void> setAccent(Color accentColor) =>
      _update(_appearance.copyWith(accentColor: accentColor));

  /// Personnalisation de la graine (teinte des surfaces du thème).
  Future<void> setSeed(Color seedColor) =>
      _update(_appearance.copyWith(seedColor: seedColor));

  Future<void> setTextScale(double factor) =>
      _update(_appearance.copyWith(textScale: factor));

  /// Bascule clair ↔ sombre (bouton de la page Paramètres).
  Future<void> toggleTheme() => setMode(
    _appearance.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
  );

  /// Réinitialise l'apparence aux valeurs d'usine (graphite sombre).
  Future<void> resetToDefaults() async {
    _appearance = AppAppearanceConfig.defaults;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    // Sans cela, l'ancienne clé de mode rejouerait un mode après la
    // réinitialisation, au prochain démarrage.
    await prefs.remove(_legacyKey);
  }

  /// Ancien nom de [resetToDefaults] — `settings_page.dart` l'appelle encore
  /// (la page Apparence le remplacera).
  Future<void> resetToDefault() => resetToDefaults();

  /// Applique [config] en mémoire, notifie puis la persiste.
  Future<void> _update(AppAppearanceConfig config) async {
    _appearance = config;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _appearance.encode());
  }
}
