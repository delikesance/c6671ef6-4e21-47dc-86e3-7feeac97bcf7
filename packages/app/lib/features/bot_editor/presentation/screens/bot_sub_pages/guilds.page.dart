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
  final _leavingGuilds = <Snowflake>{};
  List<_GuildInfo>? _restGuilds;
  bool _loadingRest = false;

  /// Try to get guilds from the running gateway cache.
  /// Falls back to REST API if the bot is not running.
  Future<List<_GuildInfo>> _fetchGuilds() async {
    // 1. Try running gateway cache (instant)
    final gateway = desktopGatewayForBot(widget.botId);
    if (gateway != null) {
      final guilds = gateway.guilds.cache.values.map((g) => _GuildInfo(
        id: g.id.toString(),
        name: g.name,
        iconHash: g.iconHash,
      )).toList();
      guilds.sort((a, b) => a.name.compareTo(b.name));
      return guilds;
    }

    // 2. Fall back to REST API (temporary connection, no gateway)
    final appManager = AppManager();
    final appData = await appManager.getApp(widget.botId);
    final token = (appData['token'] ?? '').toString().trim();
    if (token.isEmpty) return [];

    NyxxRest? rest;
    try {
      rest = await Nyxx.connectRest(token);
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
      rest?.close();
    }
  }

  /// Only available when gateway is running (real Guild object needed).
  Future<void> _leaveGuild(_GuildInfo info) async {
    final gateway = desktopGatewayForBot(widget.botId);
    if (gateway == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start the bot to leave servers.')),
        );
      }
      return;
    }

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

    final snowflake = Snowflake.parse(info.id);
    setState(() => _leavingGuilds.add(snowflake));
    try {
      await gateway.guilds.delete(snowflake);
      if (mounted) {
        setState(() {
          _leavingGuilds.remove(snowflake);
          _restGuilds?.removeWhere((g) => g.id == info.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left "${info.name}".')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _leavingGuilds.remove(snowflake));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  void _exploreGuild(_GuildInfo info) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(info.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (info.iconUrl != null)
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(info.iconUrl!),
              ),
            const SizedBox(height: 12),
            Text('ID: ${info.id}'),
            if (info.isOwner) const Text('👑 Bot is owner of this server'),
            if (info.approximateMemberCount != null)
              Text('Members: ~${info.approximateMemberCount}'),
          ],
        ),
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
      // Gateway running — instant, no loading state
      if (mounted) setState(() {});
      return;
    }

    // Need REST fallback — show loading
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

    // Check gateway first
    final gateway = desktopGatewayForBot(widget.botId);
    final isRunning = gateway != null;

    // Get guilds from gateway or REST fallback
    List<_GuildInfo> guilds;
    if (gateway != null) {
      guilds = gateway.guilds.cache.values.map((g) => _GuildInfo(
        id: g.id.toString(),
        name: g.name,
        iconHash: g.iconHash,
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
      body: _buildBody(cs, guilds, isRunning),
    );
  }

  Widget _buildBody(ColorScheme cs, List<_GuildInfo> guilds, bool isRunning) {
    if (_loadingRest) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isRunning && _restGuilds == null) {
      // Initial state, no data yet
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
              isRunning
                  ? 'The bot is not in any server yet.\nInvite it to a server to see it here.'
                  : 'The bot is not in any server, or\nit could not be reached.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (!isRunning) {
          final g = await _fetchGuilds();
          if (mounted) setState(() => _restGuilds = g);
        } else {
          setState(() {});
        }
      },
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: guilds.length,
        separatorBuilder: (_, i2) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final guild = guilds[i];
          final isLeaving = _leavingGuilds.contains(Snowflake.parse(guild.id));

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
                if (isRunning)
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
