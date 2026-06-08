import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:uuid/uuid.dart';

import 'publish_template_page.dart';

/// Detail page for a marketplace template.
class MarketplaceDetailPage extends StatefulWidget {
  final MarketplaceTemplate template;
  final String botId;
  final MainApiClient? apiClient;

  const MarketplaceDetailPage({
    super.key,
    required this.template,
    required this.botId,
    this.apiClient,
  });

  @override
  State<MarketplaceDetailPage> createState() => _MarketplaceDetailPageState();
}

class _MarketplaceDetailPageState extends State<MarketplaceDetailPage> {
  final _variableValues = <String, String>{};
  bool _applying = false;
  bool _editing = false;
  bool _deleting = false;
  bool _fetching = false;
  MarketplaceTemplate? _fetchedTemplate;
  String? _currentUserId;

  MarketplaceTemplate get _template => _fetchedTemplate ?? widget.template;

  bool get _isOwner =>
      _currentUserId != null &&
      _currentUserId!.isNotEmpty &&
      _currentUserId == _template.authorId;

  @override
  void initState() {
    super.initState();
    _fetchTemplate();
  }

  Future<void> _fetchTemplate() async {
    final session = await MainApiSettingsStore.loadSession();
    if (mounted) setState(() => _currentUserId = session?.userId);

    final client = widget.apiClient;
    if (client == null) return;
    setState(() => _fetching = true);
    try {
      final json = await client.getMarketplaceTemplate(widget.template.id);
      if (mounted) {
        setState(() {
          _fetchedTemplate = MarketplaceTemplate.fromJson(json);
          _fetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tr = context.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(_template.name),
      ),
      body: SafeArea(
        child: _fetching
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(cs, tr),
              const SizedBox(height: 24),
              _buildStats(cs),
              const SizedBox(height: 24),

              if (_template.descriptionLong != null) ...[
                Text(
                  tr.marketplace_about,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _template.descriptionLong!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
              ],

              if (_template.requiredVariables.isNotEmpty) ...[
                _buildVariableForm(cs, tr),
                const SizedBox(height: 24),
              ],

              if (_template.commands.isNotEmpty) ...[
                _buildCommandsPreview(cs, tr),
                const SizedBox(height: 24),
              ],

              if (_template.workflows.isNotEmpty) ...[
                _buildWorkflowsPreview(cs, tr),
                const SizedBox(height: 24),
              ],

              if (_template.globalVariables
                  .where((v) => !v.required)
                  .isNotEmpty) ...[
                _buildGlobalVarsPreview(cs, tr),
                const SizedBox(height: 24),
              ],

              if (_template.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _template.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _applying ? null : _apply,
                  icon: _applying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(
                    _applying ? tr.marketplace_applying : tr.marketplace_apply,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Edit / Delete for own templates
              if (_isOwner) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _editing ? null : _editTemplate,
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(tr.marketplace_edit),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleting ? null : _confirmDelete,
                        icon: _deleting
                            ? const SizedBox(
                                width: 14, height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: Text(tr.marketplace_delete, style: const TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Rating
              _buildRating(cs, tr),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs, AppLocalizations tr) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(_template.icon, style: const TextStyle(fontSize: 32)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _template.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                _template.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                tr.marketplace_by_author(_template.authorName, _template.version),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ColorScheme cs) {
    return Row(
      children: [
        _StatChip(icon: Icons.download, value: '${_template.downloads}'),
        const SizedBox(width: 16),
        _StatChip(
          icon: Icons.star,
          value: _template.rating.toStringAsFixed(1),
        ),
        const SizedBox(width: 16),
        _StatChip(
          icon: Icons.playlist_play,
          value: '${_template.commands.length} commands',
        ),
        const SizedBox(width: 16),
        _StatChip(
          icon: Icons.account_tree,
          value: '${_template.workflows.length} workflows',
        ),
      ],
    );
  }

  Widget _buildVariableForm(ColorScheme cs, AppLocalizations tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.marketplace_config_required,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          tr.marketplace_config_hint,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        ..._template.requiredVariables.map((v) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              obscureText: v.sensitive,
              decoration: InputDecoration(
                labelText: v.name,
                hintText: v.defaultValue ?? v.description,
                helperText: v.description,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: v.sensitive
                    ? const Icon(Icons.lock_outline, size: 18)
                    : null,
              ),
              onChanged: (val) => _variableValues[v.name] = val,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCommandsPreview(ColorScheme cs, AppLocalizations tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.marketplace_commands_label(_template.commands.length.toString()),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ..._template.commands.take(5).map((cmd) {
          final actionCount = _countActions(cmd.data);
          final optCount = _countOptions(cmd.data);
          final typeLabel = _commandTypeLabel(
            (cmd.data['commandType'] ?? cmd.data['type'])?.toString(),
            tr,
          );
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.arrow_forward, size: 20),
            title: Text(
              '/${cmd.name}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Text(
              [
                cmd.description,
                typeLabel,
                if (optCount > 0) tr.marketplace_command_preview_options(optCount),
                actionCount > 0
                    ? tr.marketplace_command_preview_actions(actionCount)
                    : tr.marketplace_command_preview_no_actions,
              ].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.visibility_outlined, size: 18),
            onTap: () => _showCommandPreview(cmd),
          );
        }),
        if (_template.commands.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr.marketplace_more(_template.commands.length - 5),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkflowsPreview(ColorScheme cs, AppLocalizations tr) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.marketplace_workflows_label(_template.workflows.length.toString()),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ..._template.workflows.take(5).map((wf) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.account_tree, size: 20),
            title: Text(wf['name']?.toString() ?? 'Unnamed'),
            subtitle: Text(
              wf['workflowType']?.toString() ?? 'event',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
        if (_template.workflows.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr.marketplace_more(_template.workflows.length - 5),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildGlobalVarsPreview(ColorScheme cs, AppLocalizations tr) {
    final nonRequired =
        _template.globalVariables.where((v) => !v.required).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.marketplace_variables_label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ...nonRequired.take(5).map((v) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.data_object, size: 20),
            title: Text(v.name),
            subtitle: Text(
              v.defaultValue ?? '(default)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }),
        if (nonRequired.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr.marketplace_more(nonRequired.length - 5),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Future<void> _editTemplate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishTemplatePage(
          botId: widget.botId,
          apiClient: widget.apiClient,
          authorId: _template.authorId,
          authorName: _template.authorName,
          existingTemplate: _template,
        ),
      ),
    );
    // Refresh template data after edit
    _fetchTemplate();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.marketplace_delete_confirm_title),
        content: Text(context.tr.marketplace_delete_confirm(_template.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final client = widget.apiClient;
      if (client != null) {
        await client.deleteMarketplaceTemplate(_template.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.marketplace_delete_success)),
        );
        Navigator.of(context).pop(true); // go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _buildRating(ColorScheme cs, AppLocalizations tr) {
    return Column(
      children: [
        Text(
          tr.marketplace_rate_title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            final filled = star <= _template.rating.round();
            return IconButton(
              icon: Icon(
                filled ? Icons.star : Icons.star_border,
                color: filled ? Colors.amber : cs.onSurfaceVariant,
                size: 32,
              ),
              onPressed: () => _rate(star.toDouble()),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _rate(double rating) async {
    final client = widget.apiClient;
    if (client == null) return;
    try {
      await client.rateMarketplaceTemplate(_template.id, rating);
      if (mounted) {
        setState(() {
          _fetchedTemplate = MarketplaceTemplate(
            id: _template.id,
            name: _template.name,
            description: _template.description,
            descriptionLong: _template.descriptionLong,
            authorId: _template.authorId,
            authorName: _template.authorName,
            version: _template.version,
            category: _template.category,
            tags: _template.tags,
            icon: _template.icon,
            intents: _template.intents,
            commands: _template.commands,
            workflows: _template.workflows,
            globalVariables: _template.globalVariables,
            createdAt: _template.createdAt,
            updatedAt: _template.updatedAt,
            downloads: _template.downloads,
            rating: rating,
          );
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.marketplace_rate_success)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  dynamic _resolveVariables(dynamic data, Map<String, String> variables) {
    if (data is String) {
      var resolved = data;
      for (final entry in variables.entries) {
        resolved = resolved.replaceAll('{{${entry.key}}}', entry.value);
        resolved = resolved.replaceAll('((${entry.key}))', entry.value);
      }
      return resolved;
    } else if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), _resolveVariables(v, variables)));
    } else if (data is List) {
      return data.map((v) => _resolveVariables(v, variables)).toList();
    }
    return data;
  }

  int _countActions(dynamic data) {
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

  String _commandTypeLabel(String? type, AppLocalizations tr) {
    switch (type) {
      case 'user':
        return tr.marketplace_command_preview_type_user;
      case 'message':
        return tr.marketplace_command_preview_type_message;
      default:
        return tr.marketplace_command_preview_type_slash;
    }
  }

  int _countOptions(dynamic data) {
    if (data is Map) {
      final opts = data['options'];
      if (opts is List) return opts.length;
    }
    return 0;
  }

  void _showCommandPreview(dynamic cmd) {
    final tr = context.tr;
    final cs = Theme.of(context).colorScheme;
    final name = cmd.name?.toString() ?? '';
    final description = cmd.description?.toString() ?? '';
    final data = cmd.data is Map ? Map<String, dynamic>.from(cmd.data) : <String, dynamic>{};
    final actions = (data['actions'] as List?)?.whereType<Map>().toList() ?? [];
    final opts = (data['options'] as List?)?.whereType<Map>().toList() ?? [];

    const actionColors = <String, Color>{
      'sendMessage': Color(0xFF4CAF50),
      'respondWithMessage': Color(0xFF66BB6A),
      'httpRequest': Color(0xFF2196F3),
      'ifBlock': Color(0xFFFF9800),
      'forLoop': Color(0xFF9C27B0),
      'stopUnless': Color(0xFFE91E63),
      'cooldown': Color(0xFF607D8B),
      'wait': Color(0xFF795548),
      'setVariable': Color(0xFF00BCD4),
      'getVariable': Color(0xFF0097A7),
      'calculate': Color(0xFF8BC34A),
      'banUser': Color(0xFFF44336),
      'kickUser': Color(0xFFE53935),
      'addRole': Color(0xFFAB47BC),
      'removeRole': Color(0xFFCE93D8),
      'runWorkflow': Color(0xFF3F51B5),
      'deleteMessages': Color(0xFFFF5722),
    };

    Color actionColor(String? type) =>
        actionColors[type] ?? cs.primary.withAlpha(40);

    String actionLabel(String? type) {
      if (type == null) return 'Unknown';
      return type[0].toUpperCase() + type.substring(1).replaceAllMapped(
        RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}',
      );
    }

    String summarizePayload(Map<String, dynamic> payload) {
      final parts = <String>[];
      final content = payload['content'] ?? payload['text'];
      if (content != null && content.toString().isNotEmpty) {
        parts.add(content.toString().length > 60
            ? '${content.toString().substring(0, 57)}...'
            : content.toString());
      }
      final url = payload['url'];
      if (url != null && url.toString().isNotEmpty) {
        parts.add(url.toString().length > 50
            ? '${url.toString().substring(0, 47)}...'
            : url.toString());
      }
      if (parts.isEmpty) {
        final nonEmpty = payload.entries
            .where((e) => e.key != 'key' && e.value != null && e.value.toString().isNotEmpty)
            .take(2)
            .map((e) => '${e.key}: ${e.value.toString().length > 30 ? '${e.value.toString().substring(0, 27)}...' : e.value}')
            .join(' | ');
        return nonEmpty.isNotEmpty ? nonEmpty : 'No parameters';
      }
      return parts.join(' | ');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('/$name', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, fontFamily: 'monospace',
                  )),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                  if (opts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Options (${opts.length})', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: opts.map((o) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(
                          '${o['name'] ?? ''}${o['required'] == true ? ' *' : ''}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        avatar: Icon(_optionIcon(o['type']?.toString()), size: 14),
                      )).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Actions (${actions.length})',
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: actions.isEmpty
                        ? Center(child: Text(tr.marketplace_command_preview_no_actions))
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: actions.length,
                            separatorBuilder: (_, i2) => const SizedBox(height: 6),
                            itemBuilder: (ctx, i) {
                              final action = actions[i];
                              final type = action['type']?.toString();
                              final key = action['key']?.toString();
                              final payload = action['payload'] is Map
                                  ? Map<String, dynamic>.from(action['payload'])
                                  : <String, dynamic>{};
                              final color = actionColor(type);
                              final enabled = action['enabled'] != false;

                              return Container(
                                decoration: BoxDecoration(
                                  color: color.withAlpha(enabled ? 30 : 10),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: color.withAlpha(80)),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: enabled ? color : cs.onSurfaceVariant.withAlpha(40),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                actionLabel(type),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: enabled ? cs.onSurface : cs.onSurfaceVariant,
                                                  decoration: enabled ? null : TextDecoration.lineThrough,
                                                ),
                                              ),
                                              if (key != null && key.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: cs.primary.withAlpha(20),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    key,
                                                    style: TextStyle(fontSize: 10, color: cs.primary, fontFamily: 'monospace'),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            summarizePayload(payload),
                                            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  IconData _optionIcon(String? type) {
    switch (type) {
      case 'user': return Icons.person;
      case 'channel': return Icons.tag;
      case 'role': return Icons.shield;
      case 'string': return Icons.text_fields;
      case 'integer': case 'number': return Icons.numbers;
      case 'boolean': return Icons.toggle_on;
      case 'attachment': return Icons.attach_file;
      case 'mentionable': return Icons.alternate_email;
      default: return Icons.help_outline;
    }
  }
  Future<Map<String, bool>?> _showConflictDialog(
    List<Map<String, dynamic>> conflicts,
    Map<String, String> variables,
    AppLocalizations tr,
  ) async {
    // Resolve all names first
    for (final c in conflicts) {
      c['resolvedName'] = _resolveVariables(c['templateName'], variables);
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
                                        ? tr.marketplace_conflict_template_info(templateActions)
                                        : tr.marketplace_conflict_local_info(localActions),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
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

  /// Register a command on Discord and return the assigned ID.
  /// Returns null if Discord is unreachable (command saved locally with UUID).
  Future<String?> _registerOnDiscord({
    required String resolvedName,
    required String resolvedDescription,
    required Map<String, dynamic> resolvedData,
    required String botId,
  }) async {
    try {
      final appManager = AppManager();
      final appData = await appManager.getApp(botId);
      final token = (appData['token'] ?? '').toString().trim();
      if (token.isEmpty) return null;

      final rest = await Nyxx.connectRest(token);
      try {
        final commandType = resolvedData['commandType']?.toString() ?? 'chatInput';
        final ApplicationCommandBuilder builder;
        switch (commandType) {
          case 'user':
            builder = ApplicationCommandBuilder.user(name: resolvedName);
          case 'message':
            builder = ApplicationCommandBuilder.message(name: resolvedName);
          default:
            final rawOptions = (resolvedData['options'] as List?)?.whereType<Map>().toList() ?? [];
            final options = rawOptions.isNotEmpty
                ? deserializeCommandOptions(rawOptions)
                : <CommandOptionBuilder>[];
            builder = ApplicationCommandBuilder.chatInput(
              name: resolvedName,
              description: resolvedDescription,
              options: options,
            );
        }

        final permissionRaw = resolvedData['defaultMemberPermissions']?.toString();
        if (permissionRaw != null && permissionRaw.isNotEmpty) {
          final perm = int.tryParse(permissionRaw);
          if (perm != null && perm > 0) {
            builder.defaultMemberPermissions = Permissions(perm);
          }
        }

        // Read integration types and contexts from command data
        final integrationTypesRaw = resolvedData['integrationTypes'];
        if (integrationTypesRaw is List && integrationTypesRaw.isNotEmpty) {
          builder.integrationTypes = integrationTypesRaw
              .map((t) => ApplicationIntegrationType.parse(t as int))
              .toList();
        }
        final contextsRaw = resolvedData['contexts'];
        if (contextsRaw is List && contextsRaw.isNotEmpty) {
          builder.contexts = contextsRaw
              .map((c) => InteractionContextType.parse(c as int))
              .toList();
        }

        final cmd = await rest.commands.create(builder);
        return cmd.id.toString();
      } finally {
        rest.close();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _apply() async {
    final tr = context.tr;
    for (final v in _template.requiredVariables) {
      if ((_variableValues[v.name] ?? '').isEmpty && v.defaultValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr.marketplace_variable_required(v.name),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _applying = true);

    try {
      final variables = <String, String>{};
      for (final v in _template.globalVariables) {
        final val = _variableValues[v.name] ?? v.defaultValue ?? '';
        variables[v.name] = val;
      }

      final client = widget.apiClient;
      if (client != null) {
        await client.applyMarketplaceTemplate(_template.id, widget.botId, variables);
      }

      final appManager = AppManager();

      // Apply global variables
      for (final entry in variables.entries) {
        await appManager.setGlobalVariable(widget.botId, entry.key, entry.value);
      }

      // Detect conflicts before applying commands
      final existingCommands = await appManager.listAppCommands(widget.botId);
      final existingByName = <String, Map<String, dynamic>>{};
      for (final c in existingCommands) {
        final name = (c['name'] ?? '').toString().toLowerCase();
        if (name.isNotEmpty) existingByName[name] = c;
      }

      final conflicts = <Map<String, dynamic>>[];
      final nonConflicting = <Map<String, dynamic>>[];

      for (final cmd in _template.commands) {
        final resolvedName = (_resolveVariables(cmd.name, variables) as String).toLowerCase();
        final existing = existingByName[resolvedName];
        if (existing != null) {
          final localData = existing['data'];
          conflicts.add({
            'templateName': cmd.name,
            'resolvedName': resolvedName,
            'cmd': cmd,
            'localActions': _countActions(localData),
            'templateActions': _countActions(Map<String, dynamic>.from(cmd.data)),
          });
        } else {
          nonConflicting.add({
            'resolvedName': resolvedName,
            'cmd': cmd,
          });
        }
      }

      // Resolve conflicts if any
      Map<String, bool>? conflictChoices;
      if (conflicts.isNotEmpty) {
        conflictChoices = await _showConflictDialog(conflicts, variables, tr);
        if (conflictChoices == null) {
          // User cancelled
          if (mounted) setState(() => _applying = false);
          return;
        }
        // User chose to cancel entirely
        if (conflictChoices.isEmpty) {
          if (mounted) setState(() => _applying = false);
          return;
        }
      }

      final uuid = const Uuid();
      var addedCount = 0;
      var skippedCount = 0;
      var overwrittenCount = 0;

      // Process non-conflicting commands
      for (final entry in nonConflicting) {
        final cmd = entry['cmd'] as dynamic;
        final resolvedName = entry['resolvedName'] as String;
        final resolvedDescription = _resolveVariables(cmd.description, variables) as String;
        final resolvedData = _resolveVariables(cmd.data, variables) as Map<String, dynamic>;

        if (resolvedData['response'] is Map &&
            (resolvedData['response'] as Map).containsKey('_migrated')) {
          resolvedData.remove('response');
        }
        resolvedData.remove('simpleConfig');

        // Register on Discord first
        final discordId = await _registerOnDiscord(
          resolvedName: resolvedName,
          resolvedDescription: resolvedDescription,
          resolvedData: resolvedData,
          botId: widget.botId,
        );
        final newCmdId = discordId ?? uuid.v4();
        final localPayload = <String, dynamic>{
          'name': resolvedName,
          'description': resolvedDescription,
          'type': resolvedData['commandType'] ?? resolvedData['type'] ?? 'chatInput',
          'id': newCmdId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'data': resolvedData,
        };
        await appManager.saveAppCommand(widget.botId, newCmdId, localPayload);
        addedCount++;
      }

      // Process conflicting commands based on user choices
      for (final conflict in conflicts) {
        final cmd = conflict['cmd'] as dynamic;
        final resolvedName = conflict['resolvedName'] as String;
        final useTemplate = conflictChoices?[resolvedName] ?? false;

        if (!useTemplate) {
          skippedCount++;
          continue;
        }

        // Use template version: delete local, save template
        final existing = existingByName[resolvedName];
        final existingId = existing?['id']?.toString();
        if (existingId != null) {
          await appManager.deleteAppCommand(widget.botId, existingId);
        }

        final resolvedDescription = _resolveVariables(cmd.description, variables) as String;
        final resolvedData = _resolveVariables(cmd.data, variables) as Map<String, dynamic>;

        if (resolvedData['response'] is Map &&
            (resolvedData['response'] as Map).containsKey('_migrated')) {
          resolvedData.remove('response');
        }
        resolvedData.remove('simpleConfig');

        // Register on Discord first
        final discordId = await _registerOnDiscord(
          resolvedName: resolvedName,
          resolvedDescription: resolvedDescription,
          resolvedData: resolvedData,
          botId: widget.botId,
        );
        final newCmdId = discordId ?? uuid.v4();
        final localPayload = <String, dynamic>{
          'name': resolvedName,
          'description': resolvedDescription,
          'type': resolvedData['commandType'] ?? resolvedData['type'] ?? 'chatInput',
          'id': newCmdId,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'data': resolvedData,
        };
        await appManager.saveAppCommand(widget.botId, newCmdId, localPayload);
        overwrittenCount++;
      }

      // Add workflows
      for (final workflow in _template.workflows) {
        final resolvedWorkflow = _resolveVariables(workflow, variables) as Map<String, dynamic>;
        final wName = (resolvedWorkflow['name'] ?? '').toString();
        final wActions = (resolvedWorkflow['actions'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final wEntryPoint = resolvedWorkflow['entryPoint']?.toString();
        final wArguments = (resolvedWorkflow['arguments'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        final wType = resolvedWorkflow['workflowType']?.toString();
        final wEventTrigger = resolvedWorkflow['eventTrigger'] != null
            ? Map<String, dynamic>.from(resolvedWorkflow['eventTrigger'] as Map)
            : null;
        final wFolder = resolvedWorkflow['folder']?.toString();

        await appManager.saveWorkflow(
          widget.botId,
          name: wName,
          actions: wActions,
          entryPoint: wEntryPoint,
          arguments: wArguments,
          workflowType: wType,
          eventTrigger: wEventTrigger,
          folder: wFolder,
        );
      }

      if (mounted) {
        final parts = <String>[];
        if (addedCount > 0) parts.add('$addedCount added');
        if (overwrittenCount > 0) parts.add('$overwrittenCount replaced');
        if (skippedCount > 0) parts.add('$skippedCount kept local');
        final msg = parts.isEmpty
            ? tr.marketplace_apply_success
            : 'Template applied: ${parts.join(', ')}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr.marketplace_apply_error(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;

  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ],
    );
  }
}
