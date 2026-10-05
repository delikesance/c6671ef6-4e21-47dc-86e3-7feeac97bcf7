import './code_editor_theme_data.dart';
import './script_editor_language.dart';
import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';

/// Une bascule d'affichage de l'éditeur, présentée en icône ou en menu.
class _Toggle {
  const _Toggle({
    required this.label,
    required this.icon,
    required this.color,
    required this.checked,
    required this.action,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool checked;
  final VoidCallback action;
}

/// Barre d'application du chrome d'éditeur : titre, bouton « Terminé » et
/// actions de l'éditeur, en icônes au-delà de 700 px et dans un menu « ⋮ » en
/// dessous (les icônes plus l'action principale débordaient de 17 px à 360 dp).
class ScriptEditorAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ScriptEditorAppBar({
    super.key,
    required this.title,
    required this.colors,
    required this.wordWrap,
    required this.showIndentGuides,
    required this.showDiagnostics,
    required this.diagnostics,
    required this.onDone,
    required this.onOpenDocs,
    required this.onOpenSettings,
    required this.onToggleWordWrap,
    required this.onToggleIndentGuides,
    required this.onToggleDiagnostics,
    required this.onShowUxSheet,
  });

  /// Titre déjà localisé par la page.
  final String title;

  final CodeEditorThemeColors colors;

  /// État des trois bascules : habillage, guides, diagnostics.
  final bool wordWrap;
  final bool showIndentGuides;
  final bool showDiagnostics;

  /// Diagnostics courants : ils colorent l'icône (vert / orange / rouge).
  final List<ScriptDiagnostic> diagnostics;

  final VoidCallback onDone;
  final VoidCallback onOpenDocs;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleWordWrap;
  final VoidCallback onToggleIndentGuides;
  final VoidCallback onToggleDiagnostics;
  final VoidCallback onShowUxSheet;

  /// Seuil (px) au-delà duquel les actions tiennent en icônes.
  static const double wideToolbarWidth = 700;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isWideToolbar = MediaQuery.sizeOf(context).width >= wideToolbarWidth;

    return AppBar(
      backgroundColor: colors.surface,
      title: Text(
        title,
        style: TextStyle(color: colors.text, fontSize: 16),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      iconTheme: IconThemeData(color: colors.text),
      actions: [
        if (isWideToolbar)
          ..._toolbarIcons(context)
        else
          _overflowMenu(context),
        TextButton(
          onPressed: onDone,
          child: Text(
            context.tr.done,
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Color get _diagnosticsColor {
    final hasErrors = diagnostics.any(
      (diagnostic) => diagnostic.severity == ScriptDiagnosticSeverity.error,
    );
    return hasErrors
        ? AppTheme.error
        : (diagnostics.isEmpty ? AppTheme.success : AppTheme.warning);
  }

  /// Les trois bascules, partagées par la barre d'icônes et par le menu « ⋮ ».
  List<_Toggle> _toggles(BuildContext context) {
    final muted = colors.text.withValues(alpha: 0.7);
    return [
      _Toggle(
        label: context.tr.bdfd_editor_wrap_toggle,
        icon: wordWrap ? Icons.wrap_text : Icons.format_align_left,
        color: muted,
        checked: wordWrap,
        action: onToggleWordWrap,
      ),
      _Toggle(
        label: context.tr.bdfd_editor_diagnostics_toggle,
        icon: showDiagnostics ? Icons.bug_report : Icons.bug_report_outlined,
        color: _diagnosticsColor,
        checked: showDiagnostics,
        action: onToggleDiagnostics,
      ),
      _Toggle(
        label: context.tr.bdfd_editor_toggle_indent,
        icon: showIndentGuides
            ? Icons.format_indent_increase
            : Icons.format_indent_decrease,
        color: muted,
        checked: showIndentGuides,
        action: onToggleIndentGuides,
      ),
    ];
  }

  List<Widget> _toolbarIcons(BuildContext context) {
    final muted = colors.text.withValues(alpha: 0.7);
    return [
      _icon(
        context.tr.code_editor_settings_title,
        Icons.palette_outlined,
        muted,
        onOpenSettings,
      ),
      _icon(context.tr.bdfd_editor_docs, Icons.menu_book, muted, onOpenDocs),
      for (final toggle in _toggles(context))
        _icon(toggle.label, toggle.icon, toggle.color, toggle.action),
      _icon(
        context.tr.bdfd_editor_ux_title,
        Icons.tips_and_updates_outlined,
        muted,
        onShowUxSheet,
      ),
    ];
  }

  IconButton _icon(
    String tooltip,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return IconButton(
      tooltip: tooltip,
      icon: AppIcon.fromMaterial(icon, color: color),
      onPressed: onPressed,
    );
  }

  Widget _overflowMenu(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      tooltip: context.tr.more_options_title,
      icon: AppIcon.fromMaterial(
        Icons.more_vert,
        color: colors.text.withValues(alpha: 0.7),
      ),
      onSelected: (action) => action(),
      itemBuilder: (menuContext) => [
        for (final toggle in _toggles(menuContext))
          CheckedPopupMenuItem<VoidCallback>(
            value: toggle.action,
            checked: toggle.checked,
            child: Text(toggle.label),
          ),
        PopupMenuItem<VoidCallback>(
          value: onShowUxSheet,
          child: Text(menuContext.tr.bdfd_editor_ux_title),
        ),
        PopupMenuItem<VoidCallback>(
          value: onOpenSettings,
          child: Text(menuContext.tr.code_editor_settings_title),
        ),
        PopupMenuItem<VoidCallback>(
          value: onOpenDocs,
          child: Text(menuContext.tr.bdfd_editor_docs),
        ),
      ],
    );
  }
}
