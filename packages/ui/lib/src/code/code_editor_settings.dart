import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Available syntax-highlighting themes for the code editors.
///
/// The order of the values is also the order in which the settings page shows
/// the themes, with [CodeEditorTheme.rosePine] first because it is the
/// out-of-the-box default of the app.
enum CodeEditorTheme {
  rosePine,
  rosePineDawn,
  vsCodeDark,
  githubDark,
  githubLight,
  oneDark,
  monokai,
}

extension CodeEditorThemeExt on CodeEditorTheme {
  /// Stable identifier persisted in `SharedPreferences`.
  String get id {
    switch (this) {
      case CodeEditorTheme.rosePine:
        return 'rose_pine';
      case CodeEditorTheme.rosePineDawn:
        return 'rose_pine_dawn';
      case CodeEditorTheme.vsCodeDark:
        return 'vscode_dark';
      case CodeEditorTheme.githubDark:
        return 'github_dark';
      case CodeEditorTheme.githubLight:
        return 'github_light';
      case CodeEditorTheme.oneDark:
        return 'one_dark';
      case CodeEditorTheme.monokai:
        return 'monokai';
    }
  }

  /// Display name of the theme.
  ///
  /// These are product names ("Rosé Pine", "GitHub Dark", …) so they are
  /// intentionally kept identical in every locale.
  String get label {
    switch (this) {
      case CodeEditorTheme.rosePine:
        return 'Rosé Pine (Dark)';
      case CodeEditorTheme.rosePineDawn:
        return 'Rosé Pine Dawn (Light)';
      case CodeEditorTheme.vsCodeDark:
        return 'VS Code Dark';
      case CodeEditorTheme.githubDark:
        return 'GitHub Dark';
      case CodeEditorTheme.githubLight:
        return 'GitHub Light';
      case CodeEditorTheme.oneDark:
        return 'One Dark';
      case CodeEditorTheme.monokai:
        return 'Monokai';
    }
  }

  /// Whether the theme is designed for a dark surrounding (only used for the
  /// "dark/light" subtitle shown in the settings page).
  bool get isDark {
    switch (this) {
      case CodeEditorTheme.rosePineDawn:
      case CodeEditorTheme.githubLight:
        return false;
      default:
        return true;
    }
  }

  /// Resolves a persisted [id] back to a theme.
  ///
  /// Unknown or missing identifiers fall back to [CodeEditorTheme.rosePine],
  /// which keeps Rosé Pine as the default theme on a fresh install *and* after
  /// a downgrade/upgrade of the app.
  static CodeEditorTheme fromId(String? id) {
    if (id == null) return CodeEditorTheme.rosePine;
    for (final theme in CodeEditorTheme.values) {
      if (theme.id == id) return theme;
    }
    return CodeEditorTheme.rosePine;
  }
}

/// Monospace font families offered by the code editors.
enum CodeEditorFontFamily { monospace, jetbrainsMono, firaCode, consolas }

extension CodeEditorFontFamilyExt on CodeEditorFontFamily {
  /// Stable identifier persisted in `SharedPreferences`.
  String get id {
    switch (this) {
      case CodeEditorFontFamily.monospace:
        return 'monospace';
      case CodeEditorFontFamily.jetbrainsMono:
        return 'jetbrains_mono';
      case CodeEditorFontFamily.firaCode:
        return 'fira_code';
      case CodeEditorFontFamily.consolas:
        return 'consolas';
    }
  }

  /// CSS-like font stack applied to the editor text.
  String get fontString {
    switch (this) {
      case CodeEditorFontFamily.jetbrainsMono:
        return 'JetBrains Mono, monospace';
      case CodeEditorFontFamily.firaCode:
        return 'Fira Code, monospace';
      case CodeEditorFontFamily.consolas:
        return 'Consolas, Courier New, monospace';
      case CodeEditorFontFamily.monospace:
        return 'monospace';
    }
  }

  /// Resolves a persisted [id] back to a font family.
  static CodeEditorFontFamily fromId(String? id) {
    if (id == null) return CodeEditorFontFamily.monospace;
    for (final font in CodeEditorFontFamily.values) {
      if (font.id == id) return font;
    }
    return CodeEditorFontFamily.monospace;
  }
}

/// Persisted configuration of the BDFD / JavaScript code editors.
///
/// Instances are immutable; use [copyWith] to derive an updated value and
/// [CodeEditorSettingsProvider] to persist it.
class CodeEditorSettings {
  final CodeEditorTheme theme;
  final CodeEditorFontFamily fontFamily;
  final double fontSize;
  final double lineHeight;
  final bool showLineNumbers;
  final bool showIndentGuides;
  final bool wordWrap;
  final bool autoCloseBrackets;
  final int tabSize;
  final bool showQuickCharsBar;

  /// Defaults used for a fresh install: **Rosé Pine** with a 13 px monospace
  /// font, line numbers and indent guides enabled.
  const CodeEditorSettings({
    this.theme = CodeEditorTheme.rosePine,
    this.fontFamily = CodeEditorFontFamily.monospace,
    this.fontSize = 13.0,
    this.lineHeight = 1.54,
    this.showLineNumbers = true,
    this.showIndentGuides = true,
    this.wordWrap = false,
    this.autoCloseBrackets = true,
    this.tabSize = 2,
    this.showQuickCharsBar = true,
  });

  CodeEditorSettings copyWith({
    CodeEditorTheme? theme,
    CodeEditorFontFamily? fontFamily,
    double? fontSize,
    double? lineHeight,
    bool? showLineNumbers,
    bool? showIndentGuides,
    bool? wordWrap,
    bool? autoCloseBrackets,
    int? tabSize,
    bool? showQuickCharsBar,
  }) {
    return CodeEditorSettings(
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      showLineNumbers: showLineNumbers ?? this.showLineNumbers,
      showIndentGuides: showIndentGuides ?? this.showIndentGuides,
      wordWrap: wordWrap ?? this.wordWrap,
      autoCloseBrackets: autoCloseBrackets ?? this.autoCloseBrackets,
      tabSize: tabSize ?? this.tabSize,
      showQuickCharsBar: showQuickCharsBar ?? this.showQuickCharsBar,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.id,
      'fontFamily': fontFamily.id,
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'showLineNumbers': showLineNumbers,
      'showIndentGuides': showIndentGuides,
      'wordWrap': wordWrap,
      'autoCloseBrackets': autoCloseBrackets,
      'tabSize': tabSize,
      'showQuickCharsBar': showQuickCharsBar,
    };
  }

  /// Rebuilds settings from [json].
  ///
  /// Every field is optional: a missing (or corrupt) entry falls back to the
  /// [CodeEditorSettings] default, so the theme ends up as
  /// [CodeEditorTheme.rosePine] when nothing was stored yet.
  factory CodeEditorSettings.fromJson(Map<String, dynamic> json) {
    return CodeEditorSettings(
      theme: CodeEditorThemeExt.fromId(json['theme'] as String?),
      fontFamily: CodeEditorFontFamilyExt.fromId(json['fontFamily'] as String?),
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 13.0,
      lineHeight: (json['lineHeight'] as num?)?.toDouble() ?? 1.54,
      showLineNumbers: json['showLineNumbers'] as bool? ?? true,
      showIndentGuides: json['showIndentGuides'] as bool? ?? true,
      wordWrap: json['wordWrap'] as bool? ?? false,
      autoCloseBrackets: json['autoCloseBrackets'] as bool? ?? true,
      tabSize: json['tabSize'] as int? ?? 2,
      showQuickCharsBar: json['showQuickCharsBar'] as bool? ?? true,
    );
  }

  static const String prefsKey = 'code_editor_settings_v1';

  /// Loads the settings from `SharedPreferences`.
  ///
  /// Never throws: any storage/decoding error (or an absent entry) yields the
  /// defaults, i.e. Rosé Pine.
  static Future<CodeEditorSettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(prefsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        return CodeEditorSettings.fromJson(map);
      }
    } catch (_) {}
    return const CodeEditorSettings();
  }

  Future<void> save() async {
    // Snapshot synchronously so a later mutation cannot leak into this write.
    final payload = jsonEncode(toJson());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, payload);
    } catch (_) {}
  }
}
