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
  final String? parentId;

  const _ChannelInfo({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
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
        parentId: map['parent_id'] as String?,
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _GuildExplorePage(
          info: info,
          fetchChannels: () => _ensureClient().then((rest) => _fetchChannels(rest, info.id)),
        ),
      ),
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
/// Full-page Discord-style server preview.
/// Shows server header, channel list grouped by categories, and leave action.
class _GuildExplorePage extends StatefulWidget {
  final _GuildInfo info;
  final Future<List<_ChannelInfo>> Function() fetchChannels;

  const _GuildExplorePage({
    required this.info,
    required this.fetchChannels,
  });

  @override
  State<_GuildExplorePage> createState() => _GuildExplorePageState();
}

class _GuildExplorePageState extends State<_GuildExplorePage> {
  List<_ChannelInfo>? _channels;
  bool _loadingChannels = true;

  static const _sidebarBg = Color(0xFF2B2D31);
  static const _channelColor = Color(0xFF949BA4);
  static const _categoryColor = Color(0xFF949BA4);
  static const _headerBg = Color(0xFF1E1F22);

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

    // Group channels
    final categories = <_ChannelInfo>[];
    final orphans = <_ChannelInfo>[];
    if (_channels != null) {
      for (final ch in _channels!) {
        if (ch.type == 4) {
          categories.add(ch);
        } else if (ch.parentId == null) {
          orphans.add(ch);
        }
      }
    }

    IconData channelIcon(int type) => switch (type) {
      0 || 5 => Icons.tag,
      2 => Icons.volume_up,
      13 => Icons.volume_up,
      15 => Icons.forum,
      _ => Icons.tag,
    };

    bool isVoice(int type) => type == 2 || type == 13;

    return Scaffold(
      backgroundColor: _sidebarBg,
      appBar: AppBar(
        backgroundColor: _headerBg,
        title: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: info.iconUrl != null
                  ? NetworkImage(info.iconUrl!)
                  : null,
              child: info.iconUrl == null
                  ? Text(info.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 12, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              info.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          if (info.approximateMemberCount != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.people_alt_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('~${info.approximateMemberCount}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          if (info.isOwner)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Text('👑', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        children: [
          // Uncategorized channels
          if (orphans.isNotEmpty)
            ...orphans.map((ch) => _channelTile(ch, channelIcon, isVoice)),
          // Categories
          if (categories.isNotEmpty)
            ...categories.map((cat) {
              final children = _channels!
                  .where((c) => c.parentId == cat.id && c.type != 4)
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.expand_more, size: 14, color: _categoryColor),
                        const SizedBox(width: 2),
                        Text(
                          cat.name.toUpperCase(),
                          style: const TextStyle(
                            color: _categoryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...children.map((ch) => _channelTile(ch, channelIcon, isVoice)),
                ],
              );
            }),
          if (_loadingChannels)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              )),
            ),
        ],
      ),
      bottomSheet: Container(
        color: _headerBg,
        padding: const EdgeInsets.all(12),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              icon: const Icon(Icons.exit_to_app, size: 16),
              label: const Text('Leave Server'),
              onPressed: () {
                Navigator.pop(context);
                final pageState = context.findAncestorStateOfType<_GuildsPageState>();
                pageState?._leaveGuild(info);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _channelTile(_ChannelInfo ch, IconData Function(int) iconFor, bool Function(int) isVoice) {
    final icon = iconFor(ch.type);
    final voice = isVoice(ch.type);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _channelColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    ch.name,
                    style: const TextStyle(color: _channelColor, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (voice)
                  const Icon(Icons.volume_up, size: 14, color: _channelColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
