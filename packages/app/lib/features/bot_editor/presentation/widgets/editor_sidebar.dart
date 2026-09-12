import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Un item de navigation affiché dans l'[EditorSidebar].
///
/// Les libellés sont déjà localisés par l'appelant : la sidebar n'est qu'une
/// vue, elle ne connaît ni la navigation ni le stockage.
class EditorSidebarItem {
  const EditorSidebarItem({
    required this.id,
    required this.icon,
    required this.label,
  });

  /// Identifiant stable de la cible (ex. `workflows`), renvoyé tel quel par
  /// `onSelectItem`.
  final String id;

  /// Icône visible en permanence, y compris en mode rail.
  final IconData icon;

  /// Libellé localisé : affiché déplié, exposé via `Tooltip` replié.
  final String label;
}

/// Un groupe d'items (ex. « ACCUEIL », « MODULES ») avec son titre localisé.
class EditorSidebarSection {
  const EditorSidebarSection({required this.title, required this.items});

  /// Titre localisé, masqué quand la sidebar est repliée (un simple séparateur
  /// prend sa place pour garder la lecture des groupes).
  final String title;

  /// Items de la section ; une section vide n'affiche rien, titre compris.
  final List<EditorSidebarItem> items;
}

/// Sidebar de l'éditeur de bot, partagée par les deux mises en page :
///
/// * desktop large : colonne fixe de [expandedWidth] px, rétractable en rail
///   d'icônes de [collapsedWidth] px (`collapsed` + `onToggleCollapsed`) ;
/// * compact : contenu du `Drawer`, jamais rétracté (`isDrawer`), identique à
///   l'historique, sans bouton de repli.
///
/// Widget purement présentationnel : le parent garde l'état (section active,
/// préférence repliée persistée) et reçoit les intentions via les callbacks.
/// Aucune information n'est perdue en mode rail : chaque item conserve son
/// `Tooltip` (libellé), le bouton de repli reste accessible (en-tête) et le
/// mode débutant devient un `IconButton` avec tooltip et état visuel.
class EditorSidebar extends StatelessWidget {
  const EditorSidebar({
    super.key,
    required this.appName,
    required this.botId,
    this.avatarUrl,
    required this.sections,
    required this.activeItemId,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onSelectItem,
    required this.onBack,
    this.isDrawer = false,
    this.showBeginnerMode = false,
    this.beginnerMode = false,
    this.onBeginnerModeChanged,
  });

  /// Largeur de la colonne dépliée (comportement historique de l'éditeur).
  static const double expandedWidth = 256;

  /// Largeur du rail replié : 48 px de cible tactile + 2 × 12 px de marge.
  static const double collapsedWidth = 72;

  /// Nom affiché du bot (masqué en mode rail, exposé via tooltip).
  final String appName;

  /// Identifiant Discord du bot (masqué en mode rail, exposé via tooltip).
  final String botId;

  /// URL de l'icône (avatar Discord) du bot, affichée dans l'en-tête du rail
  /// replié à la place de l'initiale. Vide ou absente → pastille-lettre
  /// historique, strictement inchangée et sans requête réseau.
  final String? avatarUrl;

  /// Sections et items à rendre, dans l'ordre d'affichage.
  final List<EditorSidebarSection> sections;

  /// Item actuellement sélectionné.
  final String activeItemId;

  /// `true` pour le rail d'icônes (ignoré en mode `isDrawer`).
  final bool collapsed;

  /// Bascule demandée par l'utilisateur (bouton de l'en-tête, toujours
  /// atteignable dans les deux états).
  final VoidCallback onToggleCollapsed;

  /// Sélection d'un item (le parent gère haptique, navigation, fermeture du
  /// tiroir).
  final void Function(String itemId) onSelectItem;

  /// Retour vers la liste des bots (le parent décide de fermer le tiroir).
  final VoidCallback onBack;

  /// `true` quand la sidebar est rendue dans le `Drawer` compact.
  final bool isDrawer;

  /// Affiche le contrôle « mode débutant » (chargement terminé côté parent).
  final bool showBeginnerMode;

  /// État du mode débutant.
  final bool beginnerMode;

  /// Bascule du mode débutant.
  final ValueChanged<bool>? onBeginnerModeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final muted = isDark ? tokens.muted : colorScheme.onSurfaceVariant;

    // Le tiroir compact ne se replie jamais : le rail est réservé au desktop,
    // comme le bouton de repli (absent du tiroir).
    final isCollapsed = collapsed && !isDrawer;
    final width = isCollapsed ? collapsedWidth : expandedWidth;

    return AnimatedContainer(
      // Largeur `null` dans le tiroir : il impose déjà la sienne, on garde
      // exactement la mise en page mobile historique.
      width: isDrawer ? null : width,
      duration: AppTheme.animFast,
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      // Le contenu est toujours mis en page à SA largeur cible (rail ou
      // colonne) puis rogné par la boîte animée : aucun débordement pendant la
      // transition, les libellés se révèlent/masquent par le bord au lieu de
      // sauter d'un coup.
      child: isDrawer
          ? _buildContent(context, colorScheme, isCollapsed, muted)
          : ClipRect(
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                minWidth: width,
                maxWidth: width,
                child: SizedBox(
                  width: width,
                  child: _buildContent(
                    context,
                    colorScheme,
                    isCollapsed,
                    muted,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme,
    bool isCollapsed,
    Color muted,
  ) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, colorScheme, isCollapsed, muted),
            Divider(
              height: 1,
              thickness: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _buildSections(context, colorScheme, isCollapsed, muted),
            ),
            if (showBeginnerMode)
              _buildBeginnerMode(context, colorScheme, isCollapsed),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme colorScheme,
    bool isCollapsed,
    Color muted,
  ) {
    final tr = context.tr;

    if (isCollapsed) {
      // En-tête compacté : identité du bot (icône ou initiale + tooltip),
      // retour et bouton de dépli. Le nom complet reste accessible au survol.
      return Padding(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
        child: Column(
          children: [
            Tooltip(
              message: '$appName\nID $botId',
              child: _buildBotBadge(colorScheme),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: tr.common_back,
              onPressed: onBack,
            ),
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              tooltip: tr.editor_sidebar_expand,
              onPressed: onToggleCollapsed,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: tr.common_back,
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'ID $botId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
          if (!isDrawer)
            IconButton(
              icon: const Icon(Icons.menu_open_rounded),
              tooltip: tr.editor_sidebar_collapse,
              onPressed: onToggleCollapsed,
            ),
        ],
      ),
    );
  }

  Widget _buildSections(
    BuildContext context,
    ColorScheme colorScheme,
    bool isCollapsed,
    Color muted,
  ) {
    final children = <Widget>[];
    for (final section in sections) {
      if (section.items.isEmpty) {
        continue;
      }
      if (isCollapsed) {
        // Titres masqués en mode rail : un séparateur discret garde les
        // groupes lisibles sans texte tronqué.
        if (children.isNotEmpty) {
          children.add(
            Divider(
              height: 17,
              thickness: 1,
              indent: 20,
              endIndent: 20,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          );
        }
      } else {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
            child: Text(
              section.title,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: muted,
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
      }
      for (final item in section.items) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: _SidebarItemTile(
              icon: item.icon,
              label: item.label,
              selected: activeItemId == item.id,
              collapsed: isCollapsed,
              tooltipMessage: isCollapsed ? item.label : null,
              onTap: () => onSelectItem(item.id),
            ),
          ),
        );
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: children,
    );
  }

  Widget _buildBeginnerMode(
    BuildContext context,
    ColorScheme colorScheme,
    bool isCollapsed,
  ) {
    final tr = context.tr;

    if (isCollapsed) {
      // Le réglage reste accessible en mode rail : icône à état visuel et
      // tooltip, comme les autres items.
      return Padding(
        padding: const EdgeInsets.all(12),
        child: IconButton(
          icon: const Icon(Icons.school_rounded, size: 20),
          tooltip: tr.beginner_mode_label,
          onPressed: () => onBeginnerModeChanged?.call(!beginnerMode),
          style: IconButton.styleFrom(
            backgroundColor: beginnerMode
                ? AppTheme.info.withValues(alpha: 0.08)
                : Colors.transparent,
            foregroundColor: beginnerMode
                ? AppTheme.info
                : colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: beginnerMode
            ? AppTheme.info.withValues(alpha: 0.08)
            : Colors.transparent,
        child: SwitchListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 0,
          ),
          title: Text(
            tr.beginner_mode_label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: beginnerMode
                  ? AppTheme.info
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          subtitle: Text(
            beginnerMode ? tr.beginner_mode_on_hint : tr.beginner_mode_off_hint,
            style: const TextStyle(fontSize: 10),
          ),
          value: beginnerMode,
          onChanged: (val) => onBeginnerModeChanged?.call(val),
        ),
      ),
    );
  }

  /// Pastille d'identité du rail : l'icône (avatar Discord) du bot quand son
  /// URL est connue, sinon la pastille-lettre historique — strictement
  /// inchangée (même carré, même lettre, même couleur) et sans le moindre
  /// accès réseau, puisque `HomeBotAvatar` n'est alors pas construit.
  Widget _buildBotBadge(ColorScheme colorScheme) {
    final url = avatarUrl?.trim() ?? '';
    if (url.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Text(
          _appInitial,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
      );
    }
    // Réutilisation du composant d'avatar standard de l'app (`HomeBotAvatar`,
    // cache disque et repli inclus) plutôt qu'un `Image` recopié ici.
    return HomeBotAvatar(imageUrl: url, size: 36, fallbackLabel: _appInitial);
  }

  /// Première lettre du nom du bot, pour la pastille de l'en-tête compacté.
  String get _appInitial {
    final trimmed = appName.trim();
    if (trimmed.isEmpty) {
      return '?';
    }
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}

class _SidebarItemTile extends StatelessWidget {
  const _SidebarItemTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.collapsed,
    this.tooltipMessage,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool collapsed;
  final String? tooltipMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final tile = InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisAlignment: collapsed
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            if (!collapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final message = tooltipMessage;
    if (message == null) {
      return tile;
    }
    return Tooltip(message: message, child: tile);
  }
}
