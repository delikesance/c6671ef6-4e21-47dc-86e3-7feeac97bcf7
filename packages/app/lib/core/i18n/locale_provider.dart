import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_locale.dart';

/// Provider for managing app locale with ChangeNotifier.
class LocaleProvider extends ChangeNotifier {
  static const String _key = 'app_locale';

  AppLocalePreference _preference = AppLocalePreference.system;
  AppLocale _locale = AppLocale.en;

  AppLocalePreference get preference => _preference;

  AppLocale get locale => _locale;

  LocaleProvider() {
    _locale = detectSystemLocale(ui.PlatformDispatcher.instance.locale);
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    final savedPreference = AppLocalePreference.values.firstWhere(
      (value) => value.code == saved,
      orElse: () => AppLocalePreference.system,
    );

    await _applyPreference(savedPreference, persist: false, notify: true);
  }

  AppLocale _resolveLocale(AppLocalePreference preference) {
    switch (preference) {
      case AppLocalePreference.fr:
        return AppLocale.fr;
      case AppLocalePreference.de:
        return AppLocale.de;
      case AppLocalePreference.pt:
        return AppLocale.pt;
      case AppLocalePreference.tr:
        return AppLocale.tr;
      case AppLocalePreference.ja:
        return AppLocale.ja;
      case AppLocalePreference.en:
        return AppLocale.en;
      case AppLocalePreference.system:
        return detectSystemLocale(ui.PlatformDispatcher.instance.locale);
    }
  }

  Future<void> _applyPreference(
    AppLocalePreference preference, {
    required bool persist,
    required bool notify,
  }) async {
    _preference = preference;
    _locale = _resolveLocale(preference);

    if (persist) {
      final prefs = await SharedPreferences.getInstance();
      if (preference == AppLocalePreference.system) {
        await prefs.remove(_key);
      } else {
        await prefs.setString(_key, preference.code);
      }
    }

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> setPreference(AppLocalePreference preference) async {
    await _applyPreference(preference, persist: true, notify: true);
  }

  Future<void> resetToSystem() async {
    await _applyPreference(
      AppLocalePreference.system,
      persist: true,
      notify: true,
    );
  }
}
