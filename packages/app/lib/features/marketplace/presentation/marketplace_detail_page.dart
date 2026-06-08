import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:bot_creator_shared/utils/command_migration.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

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
  bool _fetching = false;
  MarketplaceTemplate? _fetchedTemplate;

  MarketplaceTemplate get _template => _fetchedTemplate ?? widget.template;

  @override
  void initState() {
    super.initState();
    _fetchTemplate();
  }

  Future<void> _fetchTemplate() async {
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
              const SizedBox(height: 16),

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
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.arrow_forward, size: 20),
            title: Text(
              '/${cmd.name}',
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Text(
              cmd.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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

      // Add commands — strip legacy response/simpleConfig, skip duplicates
      final uuid = const Uuid();
      final existingCommands = await appManager.listAppCommands(widget.botId);
      final existingNames = existingCommands
          .map((c) => (c['name'] ?? '').toString().toLowerCase())
          .toSet();

      var addedCount = 0;
      var skippedCount = 0;
      for (final cmd in _template.commands) {
        final resolvedName = _resolveVariables(cmd.name, variables) as String;
        final resolvedDescription = _resolveVariables(cmd.description, variables) as String;
        final resolvedData = _resolveVariables(cmd.data, variables) as Map<String, dynamic>;

        // Strip legacy response/simpleConfig if _migrated sentinel is present
        if (resolvedData['response'] is Map &&
            (resolvedData['response'] as Map).containsKey('_migrated')) {
          resolvedData.remove('response');
        }
        resolvedData.remove('simpleConfig');

        // Check for duplicate command names
        if (existingNames.contains(resolvedName.toLowerCase())) {
          skippedCount++;
          continue;
        }

        final newCmdId = uuid.v4();
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
        final msg = skippedCount > 0
            ? tr.marketplace_apply_success_skipped(addedCount, skippedCount)
            : tr.marketplace_apply_success;
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
