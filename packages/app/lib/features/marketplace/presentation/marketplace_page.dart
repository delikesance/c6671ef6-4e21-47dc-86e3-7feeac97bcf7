import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/marketplace/presentation/marketplace_detail_page.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';

/// Browse and search the marketplace for templates.
class MarketplacePage extends StatefulWidget {
  final String botId;
  final MainApiClient? apiClient;

  const MarketplacePage({
    super.key,
    required this.botId,
    this.apiClient,
  });

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<MarketplaceTemplate>? _templates;
  bool _loading = true;
  String? _error;
  bool _needsLogin = false;
  String _search = '';
  String? _categoryFilter;

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
      final client = widget.apiClient;
      if (client == null) {
        setState(() {
          _templates = [];
          _loading = false;
          _error = null;
          _needsLogin = true;
        });
        return;
      }

      final raw = await client.listMarketplaceTemplates();
      final parsed = raw.map((json) {
        return MarketplaceTemplate.fromJson(json);
      }).toList();

      if (mounted) {
        setState(() {
          _templates = parsed;
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
      list = list
          .where((t) => t.category == _categoryFilter)
          .toList();
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
          IconButton(
            icon: const Icon(Icons.refresh),
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
            Icon(Icons.cloud_off, size: 48, color: cs.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.error),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh),
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
            Icon(Icons.account_circle, size: 64, color: cs.primary),
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
              icon: const Icon(Icons.login),
              label: Text(context.tr.marketplace_connect_discord),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startDiscordLogin() async {
    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.marketplace_connect_manager)),
        );
      }
      return;
    }
    // Navigate to Discord auth — the auth flow will redirect back
    // We'll retry after the user returns
    final client = MainApiClient(baseUrl: config.baseUrl);
    try {
      final startResult = await client.startDiscordAuthorization();
      // Open browser for Discord OAuth
      // On mobile, this would use url_launcher
      // For now, just show the URL and let the user handle it
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(context.tr.marketplace_login_title),
            content: Text(context.tr.marketplace_login_instructions),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetch();
                },
                child: Text(context.tr.ok),
              ),
            ],
          ),
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
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _search = ''),
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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
        builder: (_) => MarketplaceDetailPage(
          template: template,
          botId: widget.botId,
          apiClient: widget.apiClient,
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
    final tr = context.tr;
    final requiredVars =
        template.globalVariables.where((v) => v.required).length;

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
                            label: '$requiredVars config',
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
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
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
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
