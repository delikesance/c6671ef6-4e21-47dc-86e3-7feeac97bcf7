import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

/// Guild info fetched via REST API — never touches the gateway.
class _GuildInfo {
  final String id;
  final String name;
  final String? iconHash;
  final bool isOwner;
  final int? approximateMemberCount;
  final List<String> features;

  const _GuildInfo({
    required this.id,
    required this.name,
    this.iconHash,
    this.isOwner = false,
    this.approximateMemberCount,
    this.features = const [],
  });

  String? get iconUrl => iconHash != null
      ? 'https://cdn.discordapp.com/icons/$id/$iconHash.png'
      : null;
}

/// Channel info fetched via REST.
class _ChannelInfo {
  final String id;
  final String name;
  final int type; // 0=text, 2=voice, 4=category, 5=news, 13=stage, 15=forum

  const _ChannelInfo({
    required this.id,
    required this.name,
    required this.type,
  });
}

/// Shows the list of servers/guilds where the bot is present.
/// Everything goes through the REST API — never touches the gateway.
class GuildsPage extends StatefulWidget {
  final String botId;

  const GuildsPage({super.key, required this.botId});

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  final _leavingGuilds = <String>{};
  List<_GuildInfo>? _guilds;
  bool _loading = true;
  String? _error;
  NyxxRest? _restClient;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _restClient?.close();
    super.dispose();
  }

  Future<NyxxRest> _ensureClient() async {
    if (_restClient != null) return _restClient!;
    final appManager = AppManager();
    final appData = await appManager.getApp(widget.botId);
    final token = (appData['token'] ?? '').toString().trim();
    if (token.isEmpty) throw Exception('No bot token configured');
    _restClient = await Nyxx.connectRest(token);
    return _restClient!;
  }

  Future<List<_GuildInfo>> _fetchGuilds(NyxxRest rest) async {
    final route = HttpRoute()
      ..add(HttpRoutePart('users'))
      ..add(HttpRoutePart('@me'))
      ..add(HttpRoutePart('guilds'));
    final response = await rest.httpHandler.executeSafe(
      BasicRequest(route, method: 'GET', queryParameters: {'with_counts': 'true'}),
    );
    final rawList = response.jsonBody as List;
    return rawList.map((raw) {
      final map = raw as Map<String, Object?>;
      return _GuildInfo(
        id: map['id'] as String,
        name: map['name'] as String,
        iconHash: map['icon'] as String?,
        isOwner: map['owner'] as bool? ?? false,
        approximateMemberCount: map['approximate_member_count'] as int?,
        features: (map['features'] as List?)?.cast<String>() ?? [],
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<_ChannelInfo>> _fetchChannels(NyxxRest rest, String guildId) async {
    final route = HttpRoute()
      ..add(HttpRoutePart('guilds'))
      ..add(HttpRoutePart(guildId))
      ..add(HttpRoutePart('channels'));
    final response = await rest.httpHandler.executeSafe(
      BasicRequest(route, method: 'GET'),
    );
    final rawList = response.jsonBody as List;
    return rawList.map((raw) {
      final map = raw as Map<String, Object?>;
      return _ChannelInfo(
        id: map['id'] as String,
        name: map['name'] as String,
        type: map['type'] as int,
      );
    }).toList();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rest = await _ensureClient();
      final guilds = await _fetchGuilds(rest);
      if (mounted) setState(() {
        _guilds = guilds;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _leaveGuild(_GuildInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Server'),
        content: Text(
          'Leave "${info.name}"?\nThe bot will be removed from this server. '
          'You can re-invite it later from the Discord developer portal.',
        ),
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

    setState(() => _leavingGuilds.add(info.id));
    try {
      final rest = await _ensureClient();
      final route = HttpRoute()
        ..add(HttpRoutePart('users'))
        ..add(HttpRoutePart('@me'))
        ..add(HttpRoutePart('guilds'))
        ..add(HttpRoutePart(info.id));
      await rest.httpHandler.executeSafe(
        BasicRequest(route, method: 'DELETE'),
      );
      if (mounted) {
        setState(() {
          _leavingGuilds.remove(info.id);
          _guilds?.removeWhere((g) => g.id == info.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left "${info.name}".')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _leavingGuilds.remove(info.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  void _exploreGuild(_GuildInfo info) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return _ExploreSheet(info: info, cs: cs, fetchChannels: () => _ensureClient().then((rest) => _fetchChannels(rest, info.id)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          if (_guilds != null && _guilds!.isNotEmpty)
            Text(
              '${_guilds!.length} servers',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loading ? null : _fetch,
          ),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _fetch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final guilds = _guilds ?? [];

    if (guilds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'The bot is not in any server.\nInvite it to a server to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: guilds.length,
        separatorBuilder: (_, i2) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final guild = guilds[i];
          final isLeaving = _leavingGuilds.contains(guild.id);

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: guild.iconUrl != null
                  ? NetworkImage(guild.iconUrl!)
                  : null,
              child: guild.iconUrl == null
                  ? Text(guild.name.substring(0, 1).toUpperCase())
                  : null,
            ),
            title: Text(guild.name),
            subtitle: Text(
              [
                'ID: ${guild.id}',
                if (guild.approximateMemberCount != null)
                  '~${guild.approximateMemberCount} members',
                if (guild.isOwner) '👑 Owner',
              ].join(' · '),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20),
                  tooltip: 'Explore',
                  onPressed: () => _exploreGuild(guild),
                ),
                IconButton(
                  icon: isLeaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.exit_to_app, size: 20, color: Colors.red),
                  tooltip: 'Leave',
                  onPressed: isLeaving ? null : () => _leaveGuild(guild),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The explore bottom sheet — fetches channels via REST on open.
class _ExploreSheet extends StatefulWidget {
  final _GuildInfo info;
  final ColorScheme cs;
  final Future<List<_ChannelInfo>> Function() fetchChannels;

  const _ExploreSheet({
    required this.info,
    required this.cs,
    required this.fetchChannels,
  });

  @override
  State<_ExploreSheet> createState() => _ExploreSheetState();
}

class _ExploreSheetState extends State<_ExploreSheet> {
  List<_ChannelInfo>? _channels;
  bool _loadingChannels = true;

  @override
  void initState() {
    super.initState();
    widget.fetchChannels().then((ch) {
      if (mounted) setState(() {
        _channels = ch;
        _loadingChannels = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loadingChannels = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    final cs = widget.cs;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.85,
      expand: false,
      builder: (ctx, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: info.iconUrl != null
                      ? NetworkImage(info.iconUrl!)
                      : null,
                  child: info.iconUrl == null
                      ? Text(info.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontSize: 20))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(info.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      Text('ID: ${info.id}',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Stats cards
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatCard(ctx: ctx, cs: cs, icon: Icons.people_alt_outlined, label: 'Members',
                  value: info.approximateMemberCount?.toString() ?? '?'),
                _StatCard(ctx: ctx, cs: cs, icon: Icons.tag, label: 'Channels',
                  value: _channels != null ? '${_channels!.length}' : '...'),
                if (info.isOwner)
                  _StatCard(ctx: ctx, cs: cs, icon: Icons.star, label: 'Owner', value: '👑'),
                if (info.features.isNotEmpty)
                  _StatCard(ctx: ctx, cs: cs, icon: Icons.auto_awesome, label: 'Features',
                    value: '${info.features.length}'),
              ],
            ),
            // Features chips
            if (info.features.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6, runSpacing: 4,
                children: info.features.map((f) => Chip(
                  visualDensity: VisualDensity.compact,
                  label: Text(_formatFeature(f), style: const TextStyle(fontSize: 11)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
            // Channels list
            if (_channels != null && _channels!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Channels',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              ..._channels!.take(30).map((ch) {
                final typeIcon = switch (ch.type) {
                  0 || 5 => Icons.chat_outlined,     // text / news
                  2 || 13 => Icons.volume_up_outlined, // voice / stage
                  4 => Icons.folder_outlined,         // category
                  15 => Icons.forum_outlined,         // forum
                  _ => Icons.tag,
                };
                return ListTile(
                  dense: true,
                  leading: Icon(typeIcon, size: 18, color: cs.onSurfaceVariant),
                  title: Text(
                    ch.type == 4 ? ch.name.toUpperCase() : '#${ch.name}',
                    style: TextStyle(fontSize: 13, fontFamily: 'monospace',
                      color: ch.type == 4 ? cs.onSurfaceVariant : cs.onSurface,
                    ),
                  ),
                );
              }),
            ],
            if (_loadingChannels) ...[
              const SizedBox(height: 16),
              const Center(child: LinearProgressIndicator()),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.exit_to_app, size: 18, color: Colors.red),
                label: const Text('Leave Server', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.pop(ctx);
                  // Call leave via the parent page
                  final pageState = context.findAncestorStateOfType<_GuildsPageState>();
                  pageState?._leaveGuild(info);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatFeature(String feature) {
    return feature
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _StatCard extends StatelessWidget {
  final BuildContext ctx;
  final ColorScheme cs;
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.ctx,
    required this.cs,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(height: 4),
          Text(value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          Text(label,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
