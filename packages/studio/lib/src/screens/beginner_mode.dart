import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode débutant : n'affiche que les onglets essentiels d'un bot (Accueil,
/// Copilote IA, Commandes, Paramètres), comme dans l'app. Mémorisé dans le
/// navigateur ; une préférence illisible retombe sur « désactivé ».
class BeginnerMode extends ChangeNotifier {
  static const _key = 'studio_beginner_mode_v1';

  bool _enabled = false;
  bool get enabled => _enabled;

  /// Sections visibles en mode débutant.
  static const essentials = {'overview', 'copilot', 'commands', 'settings'};

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_key) ?? false;
      if (stored != _enabled) {
        _enabled = stored;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> set(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }

  bool isVisible(String sectionId) =>
      !_enabled || essentials.contains(sectionId);
}
