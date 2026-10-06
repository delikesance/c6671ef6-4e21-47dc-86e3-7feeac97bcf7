import 'dart:async';

import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/tr_extension.dart';
import '../../widgets/app_icon.dart';
import 'marketplace_controller.dart';
import 'publish_template_view.dart';

/// Detail page for a marketplace template.
class MarketplaceDetailView extends StatefulWidget {
  final MarketplaceTemplate template;
  final String botId;
  final MarketplaceController controller;

  const MarketplaceDetailView({
    super.key,
    required this.template,
    required this.botId,
    required this.controller,
  });

  @override
  State<MarketplaceDetailView> createState() => _MarketplaceDetailViewState();
}

class _MarketplaceDetailViewState extends State<MarketplaceDetailView> {
  final _variableValues = <String, String>{};
  bool _applying = false;
  final bool _editing = false;
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
    final userId = await widget.controller.currentUserId();
    if (mounted) setState(() => _currentUserId = userId);

    if (!widget.controller.connected) return;
    setState(() => _fetching = true);
    try {
      final fetched = await widget.controller.get(widget.template.id);
      if (mounted) {
        setState(() {
          _fetchedTemplate = fetched ?? _fetchedTemplate;
          _fetching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tr = context.tr;

    return Scaffold(
      appBar: AppBar(title: Text(_template.name)),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const AppIcon.fromMaterial(Icons.download),
                        label: Text(
                          _applying
                              ? tr.marketplace_applying
                              : tr.marketplace_apply,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Edit / Delete for own templates
                    if (_isOwner && widget.controller.canPublish) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _editing ? null : _editTemplate,
                              icon: const AppIcon.fromMaterial(
                                Icons.edit,
                                size: 18,
                              ),
                              label: Text(tr.marketplace_edit),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _deleting ? null : _confirmDelete,
                              icon: _deleting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const AppIcon.fromMaterial(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                              label: Text(
                                tr.marketplace_delete,
                                style: const TextStyle(color: Colors.red),
                              ),
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

  Future<void> _apply() async {
    final tr = context.tr;
    for (final v in _template.requiredVariables) {
      if ((_variableValues[v.name] ?? '').isEmpty && v.defaultValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(tr.marketplace_variable_required(v.name))),
          );
        }
        return;
      }
    }

    setState(() => _applying = true);
    try {
      final variables = <String, String>{};
      for (final v in _template.globalVariables) {
        variables[v.name] = _variableValues[v.name] ?? v.defaultValue ?? '';
      }
      // L'hôte applique (conflits, enregistrement) et rend le message de fin ;
      // `null` : l'utilisateur a annulé.
      final message = await widget.controller.apply(
        context,
        _template,
        widget.botId,
        variables,
      );
      if (message == null || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.marketplace_apply_error(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
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
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(
                tr.marketplace_by_author(
                  _template.authorName,
                  _template.version,
                ),
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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
        _StatChip(icon: Icons.star, value: _template.rating.toStringAsFixed(1)),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          tr.marketplace_config_hint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                    ? const AppIcon.fromMaterial(Icons.lock_outline, size: 18)
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._template.commands.take(5).map((cmd) {
          final actionCount = countTemplateActions(cmd.data);
          final optCount = _countOptions(cmd.data);
          final typeLabel = _commandTypeLabel(
            (cmd.data['commandType'] ?? cmd.data['type'])?.toString(),
            tr,
          );
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const AppIcon.fromMaterial(Icons.arrow_forward, size: 20),
            title: Text(
              '/${cmd.name}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Text(
              [
                cmd.description,
                typeLabel,
                if (optCount > 0)
                  tr.marketplace_command_preview_options(optCount),
                actionCount > 0
                    ? tr.marketplace_command_preview_actions(actionCount)
                    : tr.marketplace_command_preview_no_actions,
              ].where((s) => s.isNotEmpty).join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const AppIcon.fromMaterial(
              Icons.visibility_outlined,
              size: 18,
            ),
            onTap: () => _showCommandPreview(cmd),
          );
        }),
        if (_template.commands.length > 5)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tr.marketplace_more(_template.commands.length - 5),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
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
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ..._template.workflows.take(5).map((wf) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const AppIcon.fromMaterial(Icons.account_tree, size: 20),
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Widget _buildGlobalVarsPreview(ColorScheme cs, AppLocalizations tr) {
    final nonRequired = _template.globalVariables
        .where((v) => !v.required)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.marketplace_variables_label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...nonRequired.take(5).map((v) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const AppIcon.fromMaterial(Icons.data_object, size: 20),
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
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Future<void> _editTemplate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublishTemplateView(
          botId: widget.botId,
          controller: widget.controller,
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
            child: Text(
              context.tr.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.controller.delete(_template.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.marketplace_delete_success)),
        );
        Navigator.of(context).pop(true); // go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            final star = i + 1;
            final filled = star <= _template.rating.round();
            return IconButton(
              icon: AppIcon.fromMaterial(
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
    if (!widget.controller.connected) return;
    try {
      await widget.controller.rate(_template.id, rating);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
    final data = cmd.data is Map
        ? Map<String, dynamic>.from(cmd.data)
        : <String, dynamic>{};
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
      return type[0].toUpperCase() +
          type
              .substring(1)
              .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}');
    }

    String summarizePayload(Map<String, dynamic> payload) {
      final parts = <String>[];
      final content = payload['content'] ?? payload['text'];
      if (content != null && content.toString().isNotEmpty) {
        parts.add(
          content.toString().length > 60
              ? '${content.toString().substring(0, 57)}...'
              : content.toString(),
        );
      }
      final url = payload['url'];
      if (url != null && url.toString().isNotEmpty) {
        parts.add(
          url.toString().length > 50
              ? '${url.toString().substring(0, 47)}...'
              : url.toString(),
        );
      }
      if (parts.isEmpty) {
        final nonEmpty = payload.entries
            .where(
              (e) =>
                  e.key != 'key' &&
                  e.value != null &&
                  e.value.toString().isNotEmpty,
            )
            .take(2)
            .map(
              (e) =>
                  '${e.key}: ${e.value.toString().length > 30 ? '${e.value.toString().substring(0, 27)}...' : e.value}',
            )
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
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '/$name',
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                  if (opts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      context.tr.marketplace_options_count(opts.length),
                      style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: opts
                          .map(
                            (o) => Chip(
                              visualDensity: VisualDensity.compact,
                              label: Text(
                                '${o['name'] ?? ''}${o['required'] == true ? ' *' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              avatar: AppIcon.fromMaterial(
                                _optionIcon(o['type']?.toString()),
                                size: 14,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    context.tr.marketplace_actions_count(actions.length),
                    style: Theme.of(ctx).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: actions.isEmpty
                        ? Center(
                            child: Text(
                              tr.marketplace_command_preview_no_actions,
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: actions.length,
                            separatorBuilder: (_, i2) =>
                                const SizedBox(height: 6),
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
                                  border: Border.all(
                                    color: color.withAlpha(80),
                                  ),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: enabled
                                            ? color
                                            : cs.onSurfaceVariant.withAlpha(40),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                actionLabel(type),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  color: enabled
                                                      ? cs.onSurface
                                                      : cs.onSurfaceVariant,
                                                  decoration: enabled
                                                      ? null
                                                      : TextDecoration
                                                            .lineThrough,
                                                ),
                                              ),
                                              if (key != null &&
                                                  key.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 1,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: cs.primary.withAlpha(
                                                      20,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    key,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: cs.primary,
                                                      fontFamily: 'monospace',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            summarizePayload(payload),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurfaceVariant,
                                            ),
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
      case 'user':
        return Icons.person;
      case 'channel':
        return Icons.tag;
      case 'role':
        return Icons.shield;
      case 'string':
        return Icons.text_fields;
      case 'integer':
      case 'number':
        return Icons.numbers;
      case 'boolean':
        return Icons.toggle_on;
      case 'attachment':
        return Icons.attach_file;
      case 'mentionable':
        return Icons.alternate_email;
      default:
        return Icons.help_outline;
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
        AppIcon.fromMaterial(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(value, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
