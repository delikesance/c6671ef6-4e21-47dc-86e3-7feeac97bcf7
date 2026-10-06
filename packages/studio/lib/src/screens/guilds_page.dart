import 'dart:async';

import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';

/// Onglet « Serveurs » : la page de l'app, alimentée par le Manager (qui garde
/// le jeton du bot).
class GuildsPage extends StatefulWidget {
  const GuildsPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  List<GuildRowData> _guilds = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _leaving = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await widget.api.listDiscordGuilds(widget.bot.id);
      if (!mounted) return;
      setState(() {
        _guilds = [
          for (final g in raw)
            GuildRowData(
              id: '${g['id']}',
              name: g['name'] as String?,
              iconUrl: g['icon_url'] as String?,
              isOwner: g['owner'] == true,
            ),
        ];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is StudioApiException ? e.message : '$e';
        _loading = false;
      });
    }
  }

  Future<void> _leave(GuildRowData guild) async {
    final name = guild.name ?? guild.id;
    if (!await confirmLeaveGuild(context, name) || !mounted) return;
    setState(() => _leaving.add(guild.id));
    try {
      await widget.api.leaveDiscordGuild(widget.bot.id, guild.id);
      if (!mounted) return;
      setState(() => _leaving.remove(guild.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.guilds_left_success(name))),
      );
      unawaited(_refresh());
    } catch (e) {
      if (!mounted) return;
      setState(() => _leaving.remove(guild.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.guilds_leave_failed('$e'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: Text(context.tr.guilds_tab),
      actions: [
        IconButton(
          icon: const AppIcon.fromMaterial(Icons.refresh, size: 20),
          tooltip: context.tr.common_refresh,
          onPressed: _loading ? null : () => unawaited(_refresh()),
        ),
      ],
    ),
    body: GuildsBody(
      guilds: _guilds,
      loading: _loading,
      errorMessage: _error,
      leaving: _leaving,
      onLeave: (g) => unawaited(_leave(g)),
      onRefresh: _refresh,
    ),
  );
}
