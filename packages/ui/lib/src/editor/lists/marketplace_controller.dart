import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';

/// Ce que les écrans du marketplace demandent à leur hôte : le catalogue (API
/// du Manager) et l'application d'un modèle à un bot, que chaque hôte fait à
/// sa façon (stockage local + Discord dans l'app, API granulaire dans le
/// Studio) en s'appuyant sur [resolveTemplateVariables] et
/// [showTemplateConflictDialog].
abstract class MarketplaceController {
  const MarketplaceController();

  /// Connecté au catalogue (sinon l'écran propose de se connecter).
  bool get connected => true;

  Future<List<MarketplaceTemplate>> list();
  Future<MarketplaceTemplate?> get(String id);
  Future<void> rate(String id, double rating);
  Future<void> delete(String id);
  Future<String?> currentUserId();

  /// Connexion au catalogue (jette en cas d'échec) ; absent : pas de connexion.
  Future<void> login(BuildContext context) async {}

  /// Applique le modèle au bot ; rend le message de fin, ou `null` si annulé.
  Future<String?> apply(
    BuildContext context,
    MarketplaceTemplate template,
    String botId,
    Map<String, String> variables,
  );

  /// Publier / modifier un modèle est possible sur cet hôte.
  bool get canPublish => false;

  /// Ce que le bot offre à la publication (commandes, workflows, variables).
  Future<TemplatePublishSource> publishSource(String botId) async =>
      const TemplatePublishSource();

  /// Auteur affiché sur un modèle publié ou modifié.
  String get authorId => '';
  String get authorName => '';

  Future<void> createTemplate(Map<String, dynamic> template) async {}
  Future<void> updateTemplate(String id, Map<String, dynamic> template) async {}
}

/// Contenu d'un bot proposé à la publication : `commands` ont `name`,
/// `description` et `data` ; `appData` porte `globalVariables` et `intents`.
class TemplatePublishSource {
  const TemplatePublishSource({
    this.commands = const [],
    this.workflows = const [],
    this.appData = const {},
  });

  final List<Map<String, dynamic>> commands;
  final List<Map<String, dynamic>> workflows;
  final Map<String, dynamic> appData;
}

dynamic resolveTemplateVariables(dynamic data, Map<String, String> variables) {
  if (data is String) {
    var resolved = data;
    for (final entry in variables.entries) {
      resolved = resolved.replaceAll('{{${entry.key}}}', entry.value);
      resolved = resolved.replaceAll('((${entry.key}))', entry.value);
    }
    return resolved;
  } else if (data is Map) {
    return data.map(
      (k, v) => MapEntry(k.toString(), resolveTemplateVariables(v, variables)),
    );
  } else if (data is List) {
    return data.map((v) => resolveTemplateVariables(v, variables)).toList();
  }
  return data;
}

int countTemplateActions(dynamic data) {
  if (data is Map) {
    final actions = data['actions'];
    if (actions is List) return actions.length;
    // Check subcommand workflows too
    final subWfs = data['subcommandWorkflows'];
    if (subWfs is Map) {
      var count = 0;
      for (final entry in subWfs.entries) {
        final wf = entry.value;
        if (wf is Map && wf['actions'] is List) {
          count += (wf['actions'] as List).length;
        }
      }
      return count;
    }
  }
  return 0;
}

Future<Map<String, bool>?> showTemplateConflictDialog(
  BuildContext context,
  List<Map<String, dynamic>> conflicts,
  Map<String, String> variables,
) async {
  final tr = context.tr;
  // Resolve all names first
  for (final c in conflicts) {
    c['resolvedName'] = resolveTemplateVariables(c['templateName'], variables);
  }

  // Default: keep local for all
  final choices = <String, bool>{
    for (final c in conflicts) c['resolvedName'] as String: false,
  };

  return showDialog<Map<String, bool>>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final templateCount = choices.values.where((v) => v).length;
          return AlertDialog(
            title: Text(tr.marketplace_conflict_title),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr.marketplace_conflict_subtitle),
                  const SizedBox(height: 16),
                  ...conflicts.map((c) {
                    final name = c['resolvedName'] as String;
                    final localActions = c['localActions'] as int;
                    final templateActions = c['templateActions'] as int;
                    final useTemplate = choices[name] ?? false;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '/$name',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  useTemplate
                                      ? tr.marketplace_conflict_template_info(
                                          templateActions,
                                        )
                                      : tr.marketplace_conflict_local_info(
                                          localActions,
                                        ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              Switch(
                                value: useTemplate,
                                onChanged: (v) {
                                  setDialogState(() => choices[name] = v);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(tr.marketplace_cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, choices),
                child: Text(
                  tr.marketplace_conflict_apply_choice(templateCount),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
