// AFFICHAGE DES VARIABLES SCOPÉES, y compris celles DÉTECTÉES.
//
// POURQUOI ce widget est séparé de la page : la règle « une valeur sans
// définition reste visible » doit être prouvable par un test sans réseau ni
// base. Ici, tout entre par les paramètres : la page fournit les définitions
// déclarées suivies des variables détectées, et ce widget se contente de les
// rendre — les détectées portent un badge explicite, donc ne passent jamais
// pour une déclaration de l'utilisateur.
import 'dart:convert';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/features/bot_editor/logic/scoped_variable_orphans.dart';
import 'package:flutter/material.dart';

/// Icône associée à une portée. Une seule table pour toute l'app : l'écran des
/// variables et ses dialogues doivent montrer la même icône pour la même portée.
IconData scopedVariableScopeIcon(String scope) {
  switch (scope) {
    case 'guild':
      return Icons.dns_outlined;
    case 'user':
      return Icons.person_outline;
    case 'channel':
      return Icons.tag;
    case 'guildMember':
      return Icons.people_outline;
    case 'message':
      return Icons.chat_bubble_outline;
    default:
      return Icons.label_outline;
  }
}

/// État vide partagé (aucune variable) — il ne s'affiche que lorsque la liste
/// est réellement vide, jamais parce que les définitions déclarées manquent.
class VariablesEmptyState extends StatelessWidget {
  const VariablesEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onAdd,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: Text(context.tr.globals_add),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Liste des variables scopées : déclarations puis déductions, groupées par
/// portée. Aucun accès aux données ici : le résultat ne dépend que des entrées.
class ScopedVariablesList extends StatelessWidget {
  const ScopedVariablesList({
    super.key,
    required this.definitions,
    required this.knownScopes,
    required this.searchQuery,
    required this.onAdd,
    required this.onExplore,
    required this.onEdit,
    required this.onDeclare,
    required this.onDelete,
  });

  /// Déclarations de l'utilisateur d'abord, variables détectées ensuite (l'ordre
  /// est garanti par `mergeScopedDefinitions`).
  final List<Map<String, dynamic>> definitions;
  final List<String> knownScopes;
  final String searchQuery;
  final VoidCallback onAdd;
  final void Function(String key, String scope) onExplore;
  final void Function(Map<String, dynamic> definition) onEdit;
  final void Function(Map<String, dynamic> definition) onDeclare;
  final void Function(String key, String scope) onDelete;

  @override
  Widget build(BuildContext context) {
    if (definitions.isEmpty) {
      return VariablesEmptyState(
        icon: Icons.account_tree_outlined,
        title: context.tr.scoped_empty,
        subtitle: context.tr.scoped_empty_subtitle,
        onAdd: onAdd,
      );
    }

    final groups = groupScopedDefinitionsByScope(
      definitions: definitions,
      knownScopes: knownScopes,
      searchQuery: searchQuery,
    );

    if (groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120, child: Center(child: Text('—'))),
        ],
      );
    }

    final rows = <Widget>[];
    for (final group in groups) {
      rows.add(_ScopeHeader(scope: group.key, count: group.value.length));
      for (final definition in group.value) {
        rows.add(
          _ScopedVariableTile(
            definition: definition,
            onExplore: onExplore,
            onEdit: onEdit,
            onDeclare: onDeclare,
            onDelete: onDelete,
          ),
        );
      }
    }

    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (ctx, index) => rows[index],
    );
  }
}

class _ScopeHeader extends StatelessWidget {
  const _ScopeHeader({required this.scope, required this.count});

  final String scope;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Row(
        children: [
          Text(
            scope.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScopedVariableTile extends StatelessWidget {
  const _ScopedVariableTile({
    required this.definition,
    required this.onExplore,
    required this.onEdit,
    required this.onDeclare,
    required this.onDelete,
  });

  final Map<String, dynamic> definition;
  final void Function(String key, String scope) onExplore;
  final void Function(Map<String, dynamic> definition) onEdit;
  final void Function(Map<String, dynamic> definition) onDeclare;
  final void Function(String key, String scope) onDelete;

  @override
  Widget build(BuildContext context) {
    final key = definition['key']?.toString() ?? '';
    final scope = definition['scope']?.toString() ?? '';
    final defaultValue = definition['defaultValue'];
    final refKey = scopedVariableReferenceKey(key);
    final legacyRefKey = scopedVariableLegacyReferenceKey(key);
    final hasLegacy = refKey != legacyRefKey;

    // Une entrée détectée n'est pas une déclaration : elle se marque, et elle
    // n'affiche AUCUNE valeur par défaut puisqu'il n'en existe aucune.
    if (isDetectedScopedDefinition(definition)) {
      return _DetectedScopedVariableTile(
        variableKey: key,
        scope: scope,
        refKey: refKey,
        legacyRefKey: legacyRefKey,
        hasLegacy: hasLegacy,
        storedValueCount:
            (definition[kScopedVariableStoredCountKey] as num?)?.toInt() ?? 0,
        onExplore: () => onExplore(key, scope),
        onDeclare: () => onDeclare(definition),
      );
    }

    return ListTile(
      title: Text(
        key,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            defaultValue != null && defaultValue.toString().isNotEmpty
                ? '= ${formatScopedVariableValue(defaultValue)}'
                : context.tr.globals_no_default,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr.scoped_ref('$scope.$refKey'),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (hasLegacy)
            Text(
              context.tr.scoped_ref_legacy('$scope.$legacyRefKey'),
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        itemBuilder: (ctx) => [
          PopupMenuItem<String>(
            value: 'explore',
            child: ListTile(
              leading: const Icon(Icons.travel_explore, size: 20),
              title: Text(context.tr.scoped_explore_runtime),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem<String>(
            value: 'edit',
            child: ListTile(
              leading: const Icon(Icons.edit_outlined, size: 20),
              title: Text(context.tr.globals_edit),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: ListTile(
              leading: Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                context.tr.delete,
                style: TextStyle(color: Theme.of(ctx).colorScheme.error),
              ),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        onSelected: (action) {
          switch (action) {
            case 'explore':
              onExplore(key, scope);
            case 'edit':
              onEdit(definition);
            case 'delete':
              onDelete(key, scope);
          }
        },
      ),
    );
  }
}

/// Entrée détectée : nom + badge, jamais de valeur inventée, et AUCUNE action
/// destructive (on ne supprime pas des données réelles depuis une déduction).
class _DetectedScopedVariableTile extends StatelessWidget {
  const _DetectedScopedVariableTile({
    required this.variableKey,
    required this.scope,
    required this.refKey,
    required this.legacyRefKey,
    required this.hasLegacy,
    required this.storedValueCount,
    required this.onExplore,
    required this.onDeclare,
  });

  final String variableKey;
  final String scope;
  final String refKey;
  final String legacyRefKey;
  final bool hasLegacy;
  final int storedValueCount;
  final VoidCallback onExplore;
  final VoidCallback onDeclare;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Row(
        children: [
          Flexible(
            child: Text(
              variableKey,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: context.tr.scoped_detected_tooltip,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(color: colorScheme.tertiary),
              ),
              child: Text(
                context.tr.scoped_detected_badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          // Le compte vient des données stockées : aucune valeur n'est affichée
          // ici, l'explorateur existant montre le contenu réel.
          Text(
            context.tr.scoped_detected_hint(storedValueCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr.scoped_ref('$scope.$refKey'),
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          if (hasLegacy)
            Text(
              context.tr.scoped_ref_legacy('$scope.$legacyRefKey'),
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        itemBuilder: (ctx) => [
          PopupMenuItem<String>(
            value: 'explore',
            child: ListTile(
              leading: const Icon(Icons.travel_explore, size: 20),
              title: Text(context.tr.scoped_explore_runtime),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem<String>(
            value: 'declare',
            child: ListTile(
              leading: const Icon(Icons.playlist_add_check, size: 20),
              title: Text(context.tr.scoped_declare_detected),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
        onSelected: (action) {
          switch (action) {
            case 'explore':
              onExplore();
            case 'declare':
              onDeclare();
          }
        },
      ),
    );
  }
}

/// Rendu d'une valeur scopée/globale : JSON indenté pour les structures, texte
/// brut sinon. Même rendu que l'édition et le presse-papiers, pour que l'écran
/// et les dialogues ne montrent jamais deux formes différentes.
String formatScopedVariableValue(dynamic value) {
  if (value == null) {
    return 'null';
  }
  if (value is List || value is Map) {
    return const JsonEncoder.withIndent('  ').convert(value);
  }
  return value.toString();
}
