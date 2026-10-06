import './code_editor_settings.dart';
import './code_editor_settings_provider.dart';
import './code_editor_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Bridge between the persistent code editor settings (owned by
/// `core/code_editor/`) and the editors that actually paint the code
/// (`core/js_editor/` and the BDFD / JavaScript editor pages).
///
/// [CodeEditorSettingsProvider] is wired near the root of the app; the lookups
/// below are deliberately *optional* so an editor still renders correctly when
/// no provider is reachable (unit tests, standalone routes, pushed routes that
/// lost the scope) instead of throwing `ProviderNotFoundException`.
///
/// Rosé Pine is the default of [CodeEditorSettings], so an editor that never
/// sees the provider already renders the default theme rather than the old
/// hard-coded GitHub Dark colours.

/// Palette used when no [CodeEditorSettingsProvider] is reachable.
final CodeEditorThemeColors defaultCodeEditorThemeColors =
    CodeEditorThemeColors.forTheme(CodeEditorTheme.rosePine);

/// Settings of the shared provider, or the persisted defaults (Rosé Pine).
///
/// Subscribes to the provider, so the calling widget rebuilds when the user
/// changes a setting.
CodeEditorSettings codeEditorSettingsOf(BuildContext context) =>
    context.watch<CodeEditorSettingsProvider?>()?.settings ??
    const CodeEditorSettings();

/// Resolves the effective [CodeEditorTheme] given the surrounding brightness.
CodeEditorTheme resolveCodeEditorTheme(
  CodeEditorTheme theme, {
  required bool isLight,
}) {
  if (isLight) {
    if (theme == CodeEditorTheme.rosePine) return CodeEditorTheme.rosePineDawn;
    if (theme == CodeEditorTheme.githubDark) return CodeEditorTheme.githubLight;
  }
  return theme;
}

/// Palette matching the user-selected [CodeEditorTheme], Rosé Pine by default.
///
/// Automatically adapts between light and dark default variants according to
/// the surrounding [Brightness].
/// Subscribes to the provider, so the calling widget rebuilds when the user
/// picks another theme.
CodeEditorThemeColors codeEditorColorsOf(BuildContext context) {
  final provider = context.watch<CodeEditorSettingsProvider?>();
  final isLight = Theme.of(context).brightness == Brightness.light;
  final theme = provider?.settings.theme ?? CodeEditorTheme.rosePine;
  final effectiveTheme = resolveCodeEditorTheme(theme, isLight: isLight);
  return CodeEditorThemeColors.forTheme(effectiveTheme);
}

/// Text style shared by every code editor: the user's monospace font, size and
/// line height, coloured with [colors] so the text always stays legible on the
/// editor background.
TextStyle codeEditorTextStyle(
  CodeEditorSettings settings,
  CodeEditorThemeColors colors,
) {
  return TextStyle(
    fontFamily: settings.fontFamily.fontString,
    fontSize: settings.fontSize,
    height: settings.lineHeight,
    color: colors.text,
  );
}
