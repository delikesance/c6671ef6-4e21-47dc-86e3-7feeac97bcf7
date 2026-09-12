import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:flutter/material.dart';

/// Holds the current [CodeEditorSettings] and persists every change.
///
/// Wire it once near the root of the widget tree (see `main.dart`) so both the
/// settings page and the code editors share the same instance:
///
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => CodeEditorSettingsProvider(),
///   child: ...,
/// ),
/// ```
///
/// The provider also works standalone: [CodeEditorSettingsPage] creates a
/// temporary instance when none is available in the tree, and [load] refreshes
/// it from `SharedPreferences`.
class CodeEditorSettingsProvider extends ChangeNotifier {
  CodeEditorSettings _settings;

  CodeEditorSettingsProvider([CodeEditorSettings? initialSettings])
    : _settings = initialSettings ?? const CodeEditorSettings();

  CodeEditorSettings get settings => _settings;

  /// Ecritures serialisees.
  ///
  /// Les `save()` sont volontairement fire-and-forget, mais sans chainage deux
  /// enregistrements concurrents peuvent se terminer DANS LE DESORDRE : la
  /// sauvegarde la plus ancienne atterrit en dernier et l'etat persiste reste
  /// obsolete (le dernier reglage change par l'utilisateur est perdu au
  /// redemarrage). On chaine donc les ecritures pour preserver l'ordre.
  Future<void> _saveChain = Future<void>.value();

  void _persist(CodeEditorSettings settings) {
    _saveChain = _saveChain.then((_) => settings.save());
  }

  /// Palette matching [settings] and ready to be handed to the syntax
  /// controllers of the code editors.
  CodeEditorThemeColors get currentColors =>
      CodeEditorThemeColors.forTheme(_settings.theme);

  /// Creates a provider pre-loaded with the persisted settings.
  static Future<CodeEditorSettingsProvider> init() async {
    final loaded = await CodeEditorSettings.load();
    return CodeEditorSettingsProvider(loaded);
  }

  /// Refreshes the in-memory settings from `SharedPreferences`.
  ///
  /// Useful when the provider is not created through [init] (for example the
  /// standalone instance created by the settings page).
  Future<void> load() async {
    final loaded = await CodeEditorSettings.load();
    _settings = loaded;
    notifyListeners();
  }

  void updateTheme(CodeEditorTheme theme) {
    if (_settings.theme == theme) return;
    _settings = _settings.copyWith(theme: theme);
    notifyListeners();
    _persist(_settings);
  }

  void updateFontFamily(CodeEditorFontFamily fontFamily) {
    if (_settings.fontFamily == fontFamily) return;
    _settings = _settings.copyWith(fontFamily: fontFamily);
    notifyListeners();
    _persist(_settings);
  }

  void updateFontSize(double fontSize) {
    if (_settings.fontSize == fontSize) return;
    _settings = _settings.copyWith(fontSize: fontSize);
    notifyListeners();
    _persist(_settings);
  }

  void updateLineHeight(double lineHeight) {
    if (_settings.lineHeight == lineHeight) return;
    _settings = _settings.copyWith(lineHeight: lineHeight);
    notifyListeners();
    _persist(_settings);
  }

  void toggleLineNumbers(bool show) {
    if (_settings.showLineNumbers == show) return;
    _settings = _settings.copyWith(showLineNumbers: show);
    notifyListeners();
    _persist(_settings);
  }

  void toggleIndentGuides(bool show) {
    if (_settings.showIndentGuides == show) return;
    _settings = _settings.copyWith(showIndentGuides: show);
    notifyListeners();
    _persist(_settings);
  }

  void toggleWordWrap(bool wrap) {
    if (_settings.wordWrap == wrap) return;
    _settings = _settings.copyWith(wordWrap: wrap);
    notifyListeners();
    _persist(_settings);
  }

  void toggleAutoCloseBrackets(bool autoClose) {
    if (_settings.autoCloseBrackets == autoClose) return;
    _settings = _settings.copyWith(autoCloseBrackets: autoClose);
    notifyListeners();
    _persist(_settings);
  }

  void updateTabSize(int tabSize) {
    if (_settings.tabSize == tabSize) return;
    _settings = _settings.copyWith(tabSize: tabSize);
    notifyListeners();
    _persist(_settings);
  }

  void toggleQuickCharsBar(bool show) {
    if (_settings.showQuickCharsBar == show) return;
    _settings = _settings.copyWith(showQuickCharsBar: show);
    notifyListeners();
    _persist(_settings);
  }

  /// Restores [CodeEditorSettings] defaults (i.e. Rosé Pine).
  void resetToDefaults() {
    _settings = const CodeEditorSettings();
    notifyListeners();
    _persist(_settings);
  }
}
