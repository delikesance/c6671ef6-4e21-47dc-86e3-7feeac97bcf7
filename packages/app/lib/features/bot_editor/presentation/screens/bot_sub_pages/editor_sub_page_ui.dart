import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Navigation placement of a bot editor sub-page, relative to the editor shell.
enum EditorNavPlacement {
  /// The shell renders its permanent sidebar (wide layouts): the section list
  /// is always on screen, so a burger there is dead weight.
  sidebar,

  /// The shell fell back to a drawer (compact layouts): the page must expose
  /// an affordance to reveal it.
  drawer,

  /// The page was pushed as its own route (e.g. from an action card), so there
  /// is no editor navigation to reveal — only a way back.
  standalone,
}

/// Resolves where the current page sits in the editor navigation.
///
/// Call this from the page's own `build` (the context that *creates* the page
/// `Scaffold`): the closest `Scaffold` ancestor is then the editor shell, and
/// its drawer tells which navigation the shell picked for the current layout.
/// When the page was pushed on its own route there is no such ancestor.
EditorNavPlacement editorNavPlacementOf(BuildContext context) {
  var placement = EditorNavPlacement.standalone;
  context.visitAncestorElements((element) {
    if (element is StatefulElement && element.state is ScaffoldState) {
      final shell = element.state as ScaffoldState;
      placement = shell.hasDrawer
          ? EditorNavPlacement.drawer
          : EditorNavPlacement.sidebar;
      return false;
    }
    return true;
  });
  return placement;
}

/// AppBar `leading` shared by the editor sub-pages.
///
/// - permanent sidebar: `null`, the section list is already visible;
/// - drawer layout: a drawer button (the compact equivalent of the sidebar);
/// - standalone route: a back button so the pushed page stays escapable —
///   sauf sur desktop, où la barre de titre du shell la fournit déjà
///   (`windowChromeOwnsBackButton`).
Widget? editorSubPageLeading(BuildContext context) {
  switch (editorNavPlacementOf(context)) {
    case EditorNavPlacement.drawer:
      return const EditorDrawerButton();
    case EditorNavPlacement.sidebar:
      return null;
    case EditorNavPlacement.standalone:
      // Sur desktop, la barre de titre du shell porte déjà la flèche de
      // retour : en rendre une ici empile deux flèches.
      if (windowChromeOwnsBackButton()) return null;
      return Navigator.of(context).canPop() ? const BackButton() : null;
  }
}

/// Opens the editor shell drawer from a sub-page.
///
/// Only meaningful on compact layouts: the shell builds a drawer there and a
/// permanent sidebar everywhere else.
class EditorDrawerButton extends StatelessWidget {
  const EditorDrawerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const AppIcon.fromMaterial(Icons.menu_rounded),
      // Framework-provided tooltip, already localized in every app locale.
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: () => context.openParentDrawer(),
    );
  }
}

/// Calm, guided empty state shared by the editor sub-pages.
///
/// Mirrors the guided empty state of the commands list: one clear primary
/// action, an optional explanation, and no dead end.
class EditorEmptyState extends StatelessWidget {
  const EditorEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.actionIcon = Icons.add_rounded,
  });

  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAction = actionLabel != null && onAction != null;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingXxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  // Neutral token surface: the empty state carries no brand
                  // accent (the single accent of the screen is the action
                  // button below).
                  color: theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: AppIcon.fromMaterial(
                  icon,
                  size: 44,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: AppTheme.fontWeightBold,
                ),
              ),
              if (description != null) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  description!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (showAction) ...[
                const SizedBox(height: AppTheme.spacingXl),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: AppIcon.fromMaterial(actionIcon),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
