import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../theme/block_family.dart';
import '../../widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Famille de couleur d'un module de l'éditeur (pastille teintée de la
/// maquette « Modules ») : la teinte ne vit que dans la pastille d'icône.
BlockFamily moduleFamilyFor(String moduleId) => switch (moduleId) {
  'workflows' => BlockFamily.events,
  'globals' => BlockFamily.data,
  'emojis' => BlockFamily.messages,
  'scheduler' => BlockFamily.logic,
  'webhooks' => BlockFamily.http,
  'team' => BlockFamily.moderation,
  'guilds' => BlockFamily.messages,
  _ => BlockFamily.logic,
};

/// Une ligne de module : pastille teintée, titre, description sur une ligne,
/// pastille de compteur optionnelle et chevron.
class ModuleListEntry {
  const ModuleListEntry({
    required this.id,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.family,
  });

  final String id;
  final IconData icon;
  final String title;
  final String? subtitle;

  /// Compteur affiché à côté du titre (ex. nombre de workflows).
  final String? badge;

  /// Par défaut déduite de [id] via [moduleFamilyFor].
  final BlockFamily? family;
  final VoidCallback onTap;
}

/// Groupe de modules sous un titre en overline (Création, Automatisation…).
class ModuleListGroup {
  const ModuleListGroup({required this.title, required this.entries});

  final String title;
  final List<ModuleListEntry> entries;
}

/// Onglet « Modules » mobile : recherche + groupes de lignes de module.
///
/// Widget de présentation pur : le shell de l'éditeur fournit les groupes
/// (registre de pages) et la navigation via [ModuleListEntry.onTap].
class ModulesListView extends StatefulWidget {
  const ModulesListView({
    super.key,
    required this.title,
    required this.groups,
    this.overline,
    this.searchHint,
    this.bottomPadding = 24,
  });

  final String title;

  /// Petit titre au-dessus (nom du bot).
  final String? overline;
  final String? searchHint;
  final List<ModuleListGroup> groups;
  final double bottomPadding;

  @override
  State<ModulesListView> createState() => _ModulesListViewState();
}

class _ModulesListViewState extends State<ModulesListView> {
  String _query = '';

  bool _matches(ModuleListEntry e) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return e.title.toLowerCase().contains(q) ||
        (e.subtitle ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hint = widget.searchHint ?? context.tr.common_search;
    final visible = [
      for (final g in widget.groups)
        (title: g.title, entries: g.entries.where(_matches).toList()),
    ].where((g) => g.entries.isNotEmpty).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 20, 16, widget.bottomPadding),
      children: [
        if (widget.overline != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              widget.overline!.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 14 / 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.84,
                color: tokens.muted,
              ),
            ),
          ),
        Semantics(
          header: true,
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: 28,
              height: 34 / 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.56,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Champ de recherche plat, 48 px, rayon 14.
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: tokens.card,
              prefixIcon: AppIcon.fromMaterial(
                Icons.search,
                size: 18,
                color: tokens.muted,
              ),
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: tokens.clusterBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: tokens.clusterBorder),
              ),
            ),
          ),
        ),
        for (final group in visible) ...[
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                group.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  height: 14 / 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.84,
                  color: tokens.muted,
                ),
              ),
            ),
          ),
          for (var i = 0; i < group.entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _ModuleRow(entry: group.entries[i]),
          ],
        ],
      ],
    );
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.entry});

  final ModuleListEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final family = entry.family ?? moduleFamilyFor(entry.id);
    return Material(
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.clusterBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: entry.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                family.pastille(entry.icon, size: 40, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              entry.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                height: 20 / 15,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          if (entry.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              height: 20,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tokens.clusterBorder.withValues(
                                  alpha: 0.7,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                entry.badge!,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (entry.subtitle != null)
                        Text(
                          entry.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 18 / 12.5,
                            color: tokens.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: AppIcon.fromMaterial(
                    Icons.chevron_right,
                    size: 20,
                    color: tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
