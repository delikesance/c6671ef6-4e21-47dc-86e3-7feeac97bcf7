import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

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

  List<Guild> _getGuilds() {
    final gateway = desktopGatewayForBot(widget.botId);
    final guilds = gateway?.guilds.cache.values.toList() ?? [];
    guilds.sort((a, b) => a.name.compareTo(b.name));
    return guilds;
  }

  Future<void> _leaveGuild(Guild guild) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Server'),
        content: Text(
          'Leave "${guild.name}"?\nThe bot will be removed from this server. '
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

    setState(() => _leavingGuilds.add(guild.id));
    try {
      final gateway = desktopGatewayForBot(widget.botId);
      if (gateway == null) throw Exception('Bot is not running');
      await gateway.guilds.delete(guild.id);
      if (mounted) {
        setState(() => _leavingGuilds.remove(guild.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Left "${guild.name}".')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _leavingGuilds.remove(guild.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    }
  }

  void _exploreGuild(Guild guild) {
    final iconUrl = guild.icon?.url.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(guild.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconUrl != null)
              CircleAvatar(
                radius: 32,
                backgroundImage: NetworkImage(iconUrl),
              ),
            const SizedBox(height: 12),
            Text('ID: ${guild.id}'),
            if (guild.approximateMemberCount != null)
              Text('Members: ${guild.approximateMemberCount}'),
            if (guild.ownerId != null)
              Text('Owner: ${guild.ownerId}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tr = context.tr;
    final guilds = _getGuilds();
    final gateway = desktopGatewayForBot(widget.botId);
    final isRunning = gateway != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Servers'),
        actions: [
          if (isRunning)
            Text(
              '${guilds.length} servers',
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(cs, tr, guilds, isRunning),
    );
  }

  Widget _buildBody(ColorScheme cs, AppLocalizations tr, List<Guild> guilds, bool isRunning) {
    if (!isRunning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.power_off, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Start the bot to see its servers.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    if (guilds.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.dns_outlined, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'The bot is not in any server yet.\nInvite it to a server to see it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: guilds.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final guild = guilds[i];
          final isLeaving = _leavingGuilds.contains(guild.id);

          final iconUrl = guild.icon?.url.toString();

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: iconUrl != null
                  ? NetworkImage(iconUrl)
                  : null,
              child: iconUrl == null
                  ? Text(guild.name.substring(0, 1).toUpperCase())
                  : null,
            ),
            title: Text(guild.name),
            subtitle: Text(
              'ID: ${guild.id}',
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
