import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';

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

  MarketplaceTemplate get _template => widget.template;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tr = context.tr;

    return Scaffold(
      appBar: AppBar(
        title: Text(_template.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                tr.marketplace_by_author
                    .replaceAll('{author}', _template.authorName)
                    .replaceAll('{version}', _template.version),
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
          tr.marketplace_commands_label.replaceAll(
            '{count}',
            _template.commands.length.toString(),
          ),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ..._template.commands.take(5).map((cmd) {
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.slash_forward, size: 20),
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
              tr.marketplace_more.replaceAll(
                '{count}',
                (_template.commands.length - 5).toString(),
              ),
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
          tr.marketplace_workflows_label.replaceAll(
            '{count}',
            _template.workflows.length.toString(),
          ),
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
              tr.marketplace_more.replaceAll(
                '{count}',
                (_template.workflows.length - 5).toString(),
              ),
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
              tr.marketplace_more.replaceAll(
                '{count}',
                (nonRequired.length - 5).toString(),
              ),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }

  Future<void> _apply() async {
    final tr = context.tr;
    for (final v in _template.requiredVariables) {
      if ((_variableValues[v.name] ?? '').isEmpty && v.defaultValue == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                tr.marketplace_variable_required.replaceAll('{name}', v.name),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _applying = true);

    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.marketplace_apply_success)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr.marketplace_apply_error.replaceAll('{error}', e.toString()),
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
