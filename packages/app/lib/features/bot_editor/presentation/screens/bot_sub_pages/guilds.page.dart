import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

/// Lightweight guild info fetched via REST when the bot is not running.
class _GuildInfo {
  final String id;
  final String name;
  final String? iconHash;
  final bool isOwner;
  final int? approximateMemberCount;

  const _GuildInfo({
    required this.id,
    required this.name,
    this.iconHash,
    this.isOwner = false,
    this.approximateMemberCount,
  });

  String? get iconUrl => iconHash != null
      ? 'https://cdn.discordapp.com/icons/$id/$iconHash.png'
      : null;
}

/// Shows the list of servers/guilds where the bot is present,
/// with quick actions to leave or explore each guild.
class GuildsPage extends StatefulWidget {
  final String botId;

  const GuildsPage({super.key, required this.botId});

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  final _leavingGuilds = <String>{};
  List<_GuildInfo>? _restGuilds;
  bool _loadingRest = false;

  /// Get a REST client using the stored bot token. Returns null if no token.
  Future<NyxxRest?> _getRestClient() async {
    final appManager = AppManager();
    final appData = await appManager.getApp(widget.botId);
    final token = (appData['token'] ?? '').toString().trim();
    if (token.isEmpty) return null;
    try {
      return await Nyxx.connectRest(token);
    } catch (_) {
      return null;
    }
  }

  Future<List<_GuildInfo>> _fetchGuilds() async {
    // 1. Try running gateway cache (instant)
    final gateway = desktopGatewayForBot(widget.botId);
    if (gateway != null) {
      final guilds = gateway.guilds.cache.values.map((g) => _GuildInfo(
        id: g.id.toString(),
        name: g.name,
        iconHash: g.iconHash,
        isOwner: g.isOwnedByCurrentUser ?? false,
        approximateMemberCount: g.approximateMemberCount,
      )).toList();
      guilds.sort((a, b) => a.name.compareTo(b.name));
      return guilds;
    }

    // 2. Fall back to REST API
    final rest = await _getRestClient();
    if (rest == null) return [];
    try {
      final route = HttpRoute()
        ..add(HttpRoutePart('users'))
        ..add(HttpRoutePart('@me'))
        ..add(HttpRoutePart('guilds'));
      final response = await rest.httpHandler.executeSafe(
        BasicRequest(route, method: 'GET', queryParameters: {'with_counts': 'true'}),
      );
      final rawList = response.jsonBody as List;
      final guilds = rawList.map((raw) {
        final map = raw as Map<String, Object?>;
        return _GuildInfo(
          id: map['id'] as String,
          name: map['name'] as String,
          iconHash: map['icon'] as String?,
          isOwner: map['owner'] as bool? ?? false,
          approximateMemberCount: map['approximate_member_count'] as int?,
        );
      }).toList();
      guilds.sort((a, b) => a.name.compareTo(b.name));
      return guilds;
    } catch (_) {
      return [];
    } finally {
      rest.close();
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
      // Try gateway first, fall back to REST
      final gateway = desktopGatewayForBot(widget.botId);
      if (gateway != null) {
        await gateway.guilds.delete(Snowflake.parse(info.id));
      } else {
        final rest = await _getRestClient();
        if (rest == null) throw Exception('Cannot connect to Discord');
        try {
          final route = HttpRoute()
            ..add(HttpRoutePart('users'))
            ..add(HttpRoutePart('@me'))
            ..add(HttpRoutePart('guilds'))
            ..add(HttpRoutePart(info.id));
          await rest.httpHandler.executeSafe(
            BasicRequest(route, method: 'DELETE'),
          );
        } finally {
          rest.close();
        }
      }
      if (mounted) {
        setState(() {
          _leavingGuilds.remove(info.id);
          _restGuilds?.removeWhere((g) => g.id == info.id);
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
    final gateway = desktopGatewayForBot(widget.botId);
    Guild? fullGuild;
    if (gateway != null) {
      fullGuild = gateway.guilds.cache[Snowflake.parse(info.id)];
    }

    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                // Stats section
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statCard(ctx, Icons.people_alt_outlined, 'Members',
                      info.approximateMemberCount?.toString() ?? '?'),
                if (fullGuild != null) ...[
                  _statCard(ctx, Icons.tag, 'Channels',
                    '${gateway!.channels.cache.values.whereType<GuildChannel>().where((c) => c.guildId == Snowflake.parse(info.id)).length}'),
                  _statCard(ctx, Icons.shield, 'Roles',
                    '${fullGuild.roles.cache.length}'),
                  _statCard(ctx, Icons.emoji_emotions_outlined, 'Emojis',
                    '${fullGuild.emojis.cache.length}'),
                    ],
                    if (info.isOwner)
                      _statCard(ctx, Icons.star, 'Owner', '👑'),
                  ],
                ),
                if (fullGuild != null) ...[
                  const SizedBox(height: 20),
                  Text('Channels',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface),
                  ),
                  const SizedBox(height: 8),
                  ...gateway!.channels.cache.values
                    .whereType<GuildChannel>()
                    .where((c) => c.guildId == Snowflake.parse(info.id))
                    .take(20).map((ch) {
                    final typeIcon = switch (ch.type) {
                      ChannelType.guildText || ChannelType.guildAnnouncement => Icons.chat_outlined,
                      ChannelType.guildVoice || ChannelType.guildStageVoice => Icons.volume_up_outlined,
                      ChannelType.guildCategory => Icons.folder_outlined,
                      _ => Icons.tag,
                    };
                    return ListTile(
                      dense: true,
                      leading: Icon(typeIcon, size: 18, color: cs.onSurfaceVariant),
                      title: Text('#${ch.name}',
                        style: TextStyle(fontSize: 13, fontFamily: 'monospace'),
                      ),
                    );
                  }),
                ],
                if (fullGuild == null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Start the bot to see channels, roles, and more.',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: cs.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.exit_to_app, size: 18, color: Colors.red),
                    label: const Text('Leave Server', style: TextStyle(color: Colors.red)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _leaveGuild(info);
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statCard(BuildContext ctx, IconData icon, String label, String value) {
    final cs = Theme.of(ctx).colorScheme;
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

  @override
  void initState() {
    super.initState();
    _loadGuilds();
  }

  Future<void> _loadGuilds() async {
    final gateway = desktopGatewayForBot(widget.botId);
    if (gateway != null) {
      if (mounted) setState(() {});
      return;
    }

    setState(() => _loadingRest = true);
    final guilds = await _fetchGuilds();
    if (mounted) {
      setState(() {
        _restGuilds = guilds;
        _loadingRest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final gateway = desktopGatewayForBot(widget.botId);
    final isRunning = gateway != null;

    List<_GuildInfo> guilds;
    if (gateway != null) {
      guilds = gateway.guilds.cache.values.map((g) => _GuildInfo(
        id: g.id.toString(),
        name: g.name,
        iconHash: g.iconHash,
        isOwner: g.isOwnedByCurrentUser ?? false,
        approximateMemberCount: g.approximateMemberCount,
      )).toList();
      guilds.sort((a, b) => a.name.compareTo(b.name));
    } else {
      guilds = _restGuilds ?? [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          if (guilds.isNotEmpty || isRunning)
            Text(
              '${guilds.length} servers',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          const SizedBox(width: 8),
          if (!isRunning)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadingRest ? null : () {
                setState(() {
                  _restGuilds = null;
                  _loadingRest = true;
                });
                _fetchGuilds().then((g) {
                  if (mounted) {
                    setState(() {
                      _restGuilds = g;
                      _loadingRest = false;
                    });
                  }
                });
              },
            ),
        ],
      ),
      body: _buildBody(cs, guilds),
    );
  }

  Widget _buildBody(ColorScheme cs, List<_GuildInfo> guilds) {
    if (_loadingRest) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_restGuilds == null && desktopGatewayForBot(widget.botId) == null) {
      return const SizedBox.shrink();
    }

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
      onRefresh: () async {
        final g = await _fetchGuilds();
        if (mounted) setState(() => _restGuilds = g);
      },
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
