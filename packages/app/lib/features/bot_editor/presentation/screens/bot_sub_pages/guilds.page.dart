import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

/// Lightweight guild info fetched via REST API.
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

/// Servers page — 100% REST API, no gateway.
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

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final rest = await _ensureClient();
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
      }).toList()..sort((a, b) => a.name.compareTo(b.name));
      if (mounted) setState(() { _guilds = guilds; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _leaveGuild(_GuildInfo info) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Server'),
        content: Text('Leave "${info.name}"?\nThe bot will be removed from this server. '
            'You can re-invite it later from the Discord developer portal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.tr.delete, style: const TextStyle(color: Colors.red))),
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
      await rest.httpHandler.executeSafe(BasicRequest(route, method: 'DELETE'));
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          if (_guilds != null && _guilds!.isNotEmpty)
            Text('${_guilds!.length} servers',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loading ? null : _fetch),
        ],
      ),
      body: _buildBody(cs),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: cs.error),
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: cs.error)),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: _fetch, child: const Text('Retry')),
      ]));
    }
    final guilds = _guilds ?? [];
    if (guilds.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.dns_outlined, size: 48, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Text('The bot is not in any server.\nInvite it to a server to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant)),
      ]));
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
              backgroundImage: guild.iconUrl != null ? NetworkImage(guild.iconUrl!) : null,
              child: guild.iconUrl == null
                  ? Text(guild.name.substring(0, 1).toUpperCase()) : null,
            ),
            title: Text(guild.name),
            subtitle: Text([
              'ID: ${guild.id}',
              if (guild.approximateMemberCount != null) '~${guild.approximateMemberCount} members',
              if (guild.isOwner) '👑 Owner',
            ].join(' · '), style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            trailing: IconButton(
              icon: isLeaving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.exit_to_app, color: Colors.red),
              tooltip: 'Leave',
              onPressed: isLeaving ? null : () => _leaveGuild(guild),
            ),
          );
        },
      ),
    );
  }
}
