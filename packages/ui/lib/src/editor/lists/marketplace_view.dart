import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';
import '../../widgets/app_icon.dart';
import 'marketplace_controller.dart';
import 'marketplace_detail_view.dart';

/// Browse and search the marketplace for templates.
class MarketplaceView extends StatefulWidget {
  final String botId;
  final MarketplaceController controller;

  const MarketplaceView({
    super.key,
    required this.botId,
    required this.controller,
  });

  @override
  State<MarketplaceView> createState() => _MarketplaceViewState();
}

class _MarketplaceViewState extends State<MarketplaceView> {
  List<MarketplaceTemplate>? _templates;
  bool _loading = true;
  String? _error;
  bool _needsLogin = false;
  String _search = '';
  String? _categoryFilter;
  bool _showMyTemplatesOnly = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!widget.controller.connected) {
        setState(() {
          _templates = [];
          _loading = false;
          _error = null;
          _needsLogin = true;
        });
        return;
      }

      final parsed = await widget.controller.list();

      // Load current user ID for "My Templates" filter
      final userId = await widget.controller.currentUserId();

      if (mounted) {
        setState(() {
          _templates = parsed;
          _currentUserId = userId;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<MarketplaceTemplate> get _filtered {
    var list = _templates ?? [];
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((t) {
        return t.name.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.tags.any((tag) => tag.toLowerCase().contains(q));
      }).toList();
    }
    if (_categoryFilter != null) {
      list = list.where((t) => t.category == _categoryFilter).toList();
    }
    if (_showMyTemplatesOnly && _currentUserId != null) {
      list = list.where((t) => t.authorId == _currentUserId).toList();
    }
    return list;
  }

  Set<String> get _categories {
    return (_templates ?? []).map((t) => t.category).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.marketplace_title),
        actions: [
          if (_currentUserId != null)
            FilterChip(
              label: Text(context.tr.marketplace_my_templates),
              selected: _showMyTemplatesOnly,
              onSelected: (v) => setState(() => _showMyTemplatesOnly = v),
              avatar: AppIcon.fromMaterial(
                _showMyTemplatesOnly ? Icons.person : Icons.person_outline,
                size: 18,
              ),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const AppIcon.fromMaterial(Icons.refresh),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _needsLogin
            ? _buildLoginPrompt(colorScheme)
            : _error != null
            ? _buildError(colorScheme)
            : _buildContent(colorScheme),
      ),
    );
  }

  Widget _buildError(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(Icons.cloud_off, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetch,
              icon: const AppIcon.fromMaterial(Icons.refresh),
              label: Text(context.tr.marketplace_retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.account_circle,
              size: 64,
              color: cs.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.marketplace_login_required,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.marketplace_login_hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startDiscordLogin,
              icon: const AppIcon.fromMaterial(Icons.login),
              label: Text(context.tr.marketplace_connect_discord),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDiscordLogin() async {
    try {
      await widget.controller.login(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.marketplace_login_success)),
        );
        _needsLogin = false;
        _fetch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${context.tr.marketplace_connect_manager}: $e'),
          ),
        );
      }
    }
  }

  Widget _buildContent(ColorScheme cs) {
    final filtered = _filtered;
    final categories = _categories;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr.marketplace_search_hint,
              prefixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 10, right: 8),
                child: AppIcon.fromMaterial(Icons.search, size: 18),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const AppIcon.fromMaterial(Icons.clear, size: 18),
                      onPressed: () => setState(() => _search = ''),
                      visualDensity: VisualDensity.compact,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withAlpha(80),
            ),
            onChanged: (v) => setState(() => _search = v),
          ),
        ),

        // Category chips
        if (categories.length > 1)
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _CategoryChip(
                  label: context.tr.marketplace_publish_select_all,
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                ...categories.map(
                  (cat) => _CategoryChip(
                    label: cat,
                    selected: _categoryFilter == cat,
                    onTap: () => setState(() => _categoryFilter = cat),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),

        // Results count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                context.tr.marketplace_count(filtered.length),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),

        // Template list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _search.isNotEmpty
                        ? context.tr.marketplace_no_results(_search)
                        : context.tr.marketplace_empty,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _TemplateCard(
                        template: filtered[index],
                        onTap: () => _openDetail(filtered[index]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  void _openDetail(MarketplaceTemplate template) async {
    final applied = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => MarketplaceDetailView(
          template: template,
          botId: widget.botId,
          controller: widget.controller,
        ),
      ),
    );
    if (applied == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final MarketplaceTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final requiredVars = template.globalVariables
        .where((v) => v.required)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  template.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Meta row
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _MetaChip(
                          icon: Icons.person,
                          label: template.authorName,
                        ),
                        _MetaChip(
                          icon: Icons.download,
                          label: '${template.downloads}',
                        ),
                        _MetaChip(
                          icon: Icons.star,
                          label: template.rating.toStringAsFixed(1),
                        ),
                        if (requiredVars > 0)
                          _MetaChip(
                            icon: Icons.tune,
                            label: context.tr.marketplace_required_config_count(
                              requiredVars,
                            ),
                          ),
                        _MetaChip(
                          icon: Icons.playlist_play,
                          label:
                              '${template.commands.length} cmd${template.commands.length == 1 ? '' : 's'}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              AppIcon.fromMaterial(
                Icons.chevron_right,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon.fromMaterial(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
