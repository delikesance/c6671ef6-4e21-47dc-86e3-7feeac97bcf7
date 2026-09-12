import 'dart:async';

import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_settings_provider.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/re_highlight.dart';

/// Moteur de colorisation JavaScript partagé avec les éditeurs réels
/// (`JsSyntaxController`) : le même `re_highlight` et surtout la **même source
/// de vérité pour les couleurs**, le `hljsTheme` de
/// [CodeEditorThemeColors.hljsTheme].
final _jsHighlight = Highlight()
  ..registerLanguage('javascript', langJavascript);

/// Rend [code] (une ligne de JavaScript) colorisé avec la palette [colors].
///
/// Mots-clés, chaînes, nombres, commentaires, fonctions et ponctuation
/// reçoivent chacun la couleur que l'éditeur JS afficherait. L'aperçu montre
/// donc le vrai rendu, pour le thème sélectionné.
TextSpan buildJsHighlightedSpan(
  String code, {
  required CodeEditorSettings settings,
  required CodeEditorThemeColors colors,
}) {
  final baseStyle = TextStyle(
    fontFamily: settings.fontFamily.fontString,
    fontSize: settings.fontSize,
    height: settings.lineHeight,
    color: colors.text,
  );
  if (code.isEmpty) {
    return TextSpan(text: '', style: baseStyle);
  }
  try {
    final result = _jsHighlight.highlight(code: code, language: 'javascript');
    final renderer = TextSpanRenderer(baseStyle, colors.hljsTheme);
    result.render(renderer);
    return renderer.span ?? TextSpan(text: code, style: baseStyle);
  } catch (_) {
    // Jamais de preview cassée : repli sur le texte brut colorisé par le thème.
    return TextSpan(text: code, style: baseStyle);
  }
}

/// Full-screen settings page for the BDFD / JavaScript code editors.
///
/// Exposes the syntax theme (Rosé Pine by default), the font, and the display
/// / editing behaviours, with a live preview at the top.
///
/// The page reads [CodeEditorSettingsProvider] from the widget tree when one is
/// available (the instance wired in `main.dart`); otherwise it creates its own
/// self-contained instance so the page always works, even before the provider
/// is registered globally.
class CodeEditorSettingsPage extends StatelessWidget {
  const CodeEditorSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CodeEditorSettingsProvider?>();
    if (provider != null) {
      return const _CodeEditorSettingsView();
    }

    return ChangeNotifierProvider<CodeEditorSettingsProvider>(
      create: (_) {
        final standalone = CodeEditorSettingsProvider();
        unawaited(standalone.load());
        return standalone;
      },
      child: const _CodeEditorSettingsView(),
    );
  }
}

class _CodeEditorSettingsView extends StatefulWidget {
  const _CodeEditorSettingsView();

  @override
  State<_CodeEditorSettingsView> createState() =>
      _CodeEditorSettingsViewState();
}

class _CodeEditorSettingsViewState extends State<_CodeEditorSettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Preview snippets are code, not UI copy: they are intentionally not
  /// localized (and must not be, so the preview matches what users type).
  static const _sampleBdfd = r'''$nomention
$description[Bienvenue sur le serveur !]
$color[#eb6f92]
$addField[Règles;Respectez chacun des membres;yes]
$footer[Bot Creator • Rosé Pine Edition]''';

  static const _sampleJs = r'''// Handler de commande Discord.js
client.on('interactionCreate', async (interaction) => {
  if (!interaction.isChatInputCommand()) return;

  if (interaction.commandName === 'ping') {
    const latency = Date.now() - interaction.createdTimestamp;
    const retries = 3; // tentatives restantes
    await interaction.reply({
      content: `Pong! Latence API: ${latency}ms 🏓`,
      ephemeral: true,
    });
  }
});''';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmReset(CodeEditorSettingsProvider provider) async {
    final tr = context.tr;
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: tr.code_editor_settings_reset_title,
      content: tr.code_editor_settings_reset_confirm,
      confirmLabel: tr.code_editor_settings_reset_action,
      isDestructive: true,
    );
    if (!confirmed || !mounted) return;
    provider.resetToDefaults();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.code_editor_settings_reset_done)),
    );
  }

  String _fontFamilyLabel(BuildContext context, CodeEditorFontFamily font) {
    switch (font) {
      case CodeEditorFontFamily.monospace:
        return context.tr.code_editor_settings_font_system;
      case CodeEditorFontFamily.jetbrainsMono:
        return context.tr.code_editor_settings_font_jetbrains_mono;
      case CodeEditorFontFamily.firaCode:
        return context.tr.code_editor_settings_font_fira_code;
      case CodeEditorFontFamily.consolas:
        return context.tr.code_editor_settings_font_consolas;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final provider = context.watch<CodeEditorSettingsProvider>();
    final settings = provider.settings;
    final colors = provider.currentColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.code_editor_settings_title),
        actions: [
          IconButton(
            tooltip: tr.code_editor_settings_reset_tooltip,
            icon: const Icon(Icons.restore),
            onPressed: () => _confirmReset(provider),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            // ── Interactive preview card ────────────────────────────────────
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                side: BorderSide(
                  color: isDark
                      ? AppTheme.homeGhostBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: isDark
                        ? AppTheme.darkSurface
                        : const Color(0xFFF1F5F9),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingLg,
                      vertical: AppTheme.spacingSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.preview_outlined, size: 18),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            tr.code_editor_settings_preview_title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Flexible(
                          child: SizedBox(
                            height: 32,
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: const [
                                Tab(text: 'BDFD'),
                                Tab(text: 'JavaScript'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 180,
                    color: colors.background,
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildBdfdPreview(settings, colors),
                        _buildJsPreview(settings, colors),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // ── Section 1: themes ───────────────────────────────────────────
            _buildSectionHeader(
              icon: Icons.palette_outlined,
              title: tr.code_editor_settings_section_theme_title,
              subtitle: tr.code_editor_settings_section_theme_subtitle,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: RadioGroup<CodeEditorTheme>(
                groupValue: settings.theme,
                onChanged: (value) {
                  if (value != null) provider.updateTheme(value);
                },
                child: Column(
                  children: CodeEditorTheme.values.map((theme) {
                    final themeColors = CodeEditorThemeColors.forTheme(theme);
                    final isSelected = settings.theme == theme;
                    final themeModeLabel = theme.isDark
                        ? tr.code_editor_settings_theme_mode_dark
                        : tr.code_editor_settings_theme_mode_light;

                    return RadioListTile<CodeEditorTheme>(
                      value: theme,
                      secondary: Container(
                        width: 44,
                        height: 28,
                        decoration: BoxDecoration(
                          color: themeColors.background,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSwatch(themeColors.function),
                            const SizedBox(width: 3),
                            _buildSwatch(themeColors.string),
                            const SizedBox(width: 3),
                            _buildSwatch(themeColors.bracket),
                          ],
                        ),
                      ),
                      title: Text(
                        theme.label,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        themeModeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXxl),

            // ── Section 2: font & typography ────────────────────────────────
            _buildSectionHeader(
              icon: Icons.text_fields_rounded,
              title: tr.code_editor_settings_section_font_title,
              subtitle: tr.code_editor_settings_section_font_subtitle,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<CodeEditorFontFamily>(
                      initialValue: settings.fontFamily,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: tr.code_editor_settings_font_family,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: CodeEditorFontFamily.values.map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Text(
                            _fontFamilyLabel(context, font),
                            style: TextStyle(fontFamily: font.fontString),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) provider.updateFontFamily(value);
                      },
                    ),

                    const SizedBox(height: AppTheme.spacingXl),

                    // Font size slider.
                    _buildSliderHeader(
                      label: tr.code_editor_settings_font_size,
                      value: '${settings.fontSize.toInt()} px',
                    ),
                    Slider(
                      value: settings.fontSize,
                      min: 11.0,
                      max: 22.0,
                      divisions: 11,
                      label: '${settings.fontSize.toInt()} px',
                      onChanged: provider.updateFontSize,
                    ),

                    const SizedBox(height: AppTheme.spacingMd),

                    // Line height slider.
                    _buildSliderHeader(
                      label: tr.code_editor_settings_line_height,
                      value: settings.lineHeight.toStringAsFixed(2),
                    ),
                    Slider(
                      value: settings.lineHeight,
                      min: 1.3,
                      max: 2.0,
                      divisions: 7,
                      label: settings.lineHeight.toStringAsFixed(2),
                      onChanged: provider.updateLineHeight,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacingXxl),

            // ── Section 3: display & guides ─────────────────────────────────
            _buildSectionHeader(
              icon: Icons.visibility_outlined,
              title: tr.code_editor_settings_section_display_title,
              subtitle: tr.code_editor_settings_section_display_subtitle,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(tr.code_editor_settings_line_numbers),
                    subtitle: Text(tr.code_editor_settings_line_numbers_desc),
                    secondary: const Icon(Icons.format_list_numbered),
                    value: settings.showLineNumbers,
                    onChanged: provider.toggleLineNumbers,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(tr.code_editor_settings_indent_guides),
                    subtitle: Text(tr.code_editor_settings_indent_guides_desc),
                    secondary: const Icon(Icons.format_indent_increase),
                    value: settings.showIndentGuides,
                    onChanged: provider.toggleIndentGuides,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(tr.code_editor_settings_word_wrap),
                    subtitle: Text(tr.code_editor_settings_word_wrap_desc),
                    secondary: const Icon(Icons.wrap_text),
                    value: settings.wordWrap,
                    onChanged: provider.toggleWordWrap,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: Text(tr.code_editor_settings_quick_chars),
                    subtitle: Text(tr.code_editor_settings_quick_chars_desc),
                    secondary: const Icon(Icons.keyboard_outlined),
                    value: settings.showQuickCharsBar,
                    onChanged: provider.toggleQuickCharsBar,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacingXxl),

            // ── Section 4: editing behaviour ────────────────────────────────
            _buildSectionHeader(
              icon: Icons.tune_rounded,
              title: tr.code_editor_settings_section_editing_title,
              subtitle: tr.code_editor_settings_section_editing_subtitle,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(tr.code_editor_settings_auto_close),
                    subtitle: Text(tr.code_editor_settings_auto_close_desc),
                    secondary: const Icon(Icons.data_object),
                    value: settings.autoCloseBrackets,
                    onChanged: provider.toggleAutoCloseBrackets,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.space_bar),
                    title: Text(tr.code_editor_settings_tab_size),
                    subtitle: Text(tr.code_editor_settings_tab_size_desc),
                    trailing: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 2, label: Text('2')),
                        ButtonSegment(value: 4, label: Text('4')),
                      ],
                      selected: {settings.tabSize},
                      onSelectionChanged: (selection) {
                        if (selection.isNotEmpty) {
                          provider.updateTabSize(selection.first);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatch(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSliderHeader({required String label, required String value}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildBdfdPreview(
    CodeEditorSettings settings,
    CodeEditorThemeColors colors,
  ) {
    final bdfdLines = _sampleBdfd.split('\n');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < bdfdLines.length; i++)
            _buildBdfdLine(bdfdLines[i], settings, colors, i + 1),
        ],
      ),
    );
  }

  Widget _buildBdfdLine(
    String code,
    CodeEditorSettings settings,
    CodeEditorThemeColors colors,
    int lineNum,
  ) {
    // Mini parser preview for BDFD.
    final spans = <TextSpan>[];
    final regex = RegExp(r'(\$[a-zA-Z0-9]+)|(\[|\])|(;)|([^$\[\];]+)');
    for (final match in regex.allMatches(code)) {
      final func = match.group(1);
      final bracket = match.group(2);
      final semi = match.group(3);
      final text = match.group(4);

      if (func != null) {
        spans.add(
          TextSpan(
            text: func,
            style: TextStyle(
              color: colors.function,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (bracket != null) {
        spans.add(
          TextSpan(
            text: bracket,
            style: TextStyle(
              color: colors.bracket,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (semi != null) {
        spans.add(
          TextSpan(
            text: semi,
            style: TextStyle(
              color: colors.semicolon,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      } else if (text != null) {
        spans.add(
          TextSpan(
            text: text,
            style: TextStyle(color: colors.text),
          ),
        );
      }
    }

    final gutter = _buildGutter(settings, colors, lineNum);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?gutter,
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: settings.fontFamily.fontString,
                fontSize: settings.fontSize,
                height: settings.lineHeight,
              ),
              children: spans,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildJsPreview(
    CodeEditorSettings settings,
    CodeEditorThemeColors colors,
  ) {
    final jsLines = _sampleJs.split('\n');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < jsLines.length; i++)
            _buildJsLine(jsLines[i], settings, colors, i + 1),
        ],
      ),
    );
  }

  Widget _buildJsLine(
    String code,
    CodeEditorSettings settings,
    CodeEditorThemeColors colors,
    int lineNum,
  ) {
    final gutter = _buildGutter(settings, colors, lineNum);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ?gutter,
        Expanded(
          // Colorisation par token (même moteur que l'éditeur JS réel) : la
          // ligne n'est plus peinte d'une seule couleur.
          child: RichText(
            text: buildJsHighlightedSpan(
              code,
              settings: settings,
              colors: colors,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildGutter(
    CodeEditorSettings settings,
    CodeEditorThemeColors colors,
    int lineNum,
  ) {
    if (!settings.showLineNumbers) return null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$lineNum',
            style: TextStyle(
              fontFamily: settings.fontFamily.fontString,
              fontSize: settings.fontSize,
              height: settings.lineHeight,
              color: colors.gutterText,
            ),
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMd),
      ],
    );
  }
}
