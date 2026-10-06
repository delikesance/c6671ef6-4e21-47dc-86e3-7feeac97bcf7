import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/home/presentation/guild_avatar.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart'
    show GuildRowData, GuildsBody, confirmLeaveGuild;

/// Page « Serveurs » d'un bot.
///
/// La liste vient de [GuildDirectory] : c'est la *même* entrée de session que
/// la carte bot de la Home. Conséquences :
///
///   * une seule requête REST par bot et par lancement de l'app, quel que soit
///     le nombre de fois où cette page est ouverte dans la session ;
///   * premier chargement : spinner (état `loading`) ; ensuite la liste est
///     peinte immédiatement depuis l'entrée de session ;
///   * le bouton « Actualiser » (et le tirer-pour-rafraîchir) force une
///     nouvelle requête via [GuildDirectory.refresh] ;
///   * après avoir quitté un serveur, l'entrée partagée est rafraîchie : la
///     Home ne peut pas continuer à afficher un serveur quitté.
class GuildsPage extends StatefulWidget {
  const GuildsPage({super.key, required this.botId, this.directory});

  /// Bot dont on liste les serveurs.
  final String botId;

  /// Répertoire injectable (tests) ; par défaut l'instance partagée.
  final GuildDirectory? directory;

  @override
  State<GuildsPage> createState() => _GuildsPageState();
}

class _GuildsPageState extends State<GuildsPage> {
  /// Serveurs en cours de sortie (spinner sur leur ligne).
  final Set<String> _leavingGuilds = <String>{};

  GuildDirectory get _directory => widget.directory ?? GuildDirectory.instance;

  @override
  void initState() {
    super.initState();
    // Idempotent : sert l'entrée de session, ou partage la requête déjà en vol
    // (carte bot de la Home, autre écran).
    unawaited(_directory.load(widget.botId));
  }

  Future<void> _refresh() => _directory.refresh(widget.botId);

  /// Quitte un serveur (action destructive : confirmation puis DELETE), et
  /// rafraîchit l'entrée partagée pour que la session redevienne exacte.
  Future<void> _leaveGuild(GuildAvatarInfo info) async {
    final name = info.name ?? info.id;
    final confirmed = await confirmLeaveGuild(context, name);
    if (!confirmed || !mounted) return;

    setState(() => _leavingGuilds.add(info.id));
    try {
      await _deleteGuild(info.id);
      if (!mounted) return;
      setState(() => _leavingGuilds.remove(info.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.guilds_left_success(name))),
      );
      unawaited(_refresh());
    } catch (e) {
      if (!mounted) return;
      setState(() => _leavingGuilds.remove(info.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.guilds_leave_failed(e.toString()))),
      );
    }
  }

  /// `DELETE /users/@me/guilds/{id}`.
  ///
  /// Client REST éphémère, créé et refermé pour cette seule action : la lecture
  /// de la liste, elle, passe par le répertoire partagé.
  Future<void> _deleteGuild(String guildId) async {
    final appData = await AppManager().getApp(widget.botId);
    final token = (appData['token'] ?? '').toString().trim();
    if (token.isEmpty) throw Exception('missing bot token');

    final rest = await Nyxx.connectRest(token);
    try {
      final route = HttpRoute()
        ..add(HttpRoutePart('users'))
        ..add(HttpRoutePart('@me'))
        ..add(HttpRoutePart('guilds'))
        ..add(HttpRoutePart(guildId));
      await rest.httpHandler.executeSafe(BasicRequest(route, method: 'DELETE'));
    } finally {
      rest.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GuildsLoadState>(
      valueListenable: _directory.watch(widget.botId),
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr.guilds_tab),
            actions: [
              const SizedBox(width: 8),
              IconButton(
                icon: const AppIcon.fromMaterial(Icons.refresh, size: 20),
                tooltip: context.tr.common_refresh,
                onPressed: state.isLoading ? null : () => unawaited(_refresh()),
              ),
            ],
          ),
          // Largeur et marges communes à toutes les pages (contrat AppPageLayout) ;
          // `_buildBody` conserve sa réserve basse (barre de navigation flottante).
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GuildsLoadState state) {
    final guilds = [
      for (final g in state.guilds)
        GuildRowData(
          id: g.id,
          name: g.name,
          iconUrl: g.iconUrl,
          memberCount: g.memberCount,
          isOwner: g.isOwner,
        ),
    ];
    return GuildsBody(
      guilds: guilds,
      loading: state.isLoading,
      errorMessage: state.status == GuildsLoadStatus.error
          ? (state.errorMessage ?? '')
          : null,
      leaving: _leavingGuilds,
      onLeave: (row) {
        final info = state.guilds.firstWhere((g) => g.id == row.id);
        unawaited(_leaveGuild(info));
      },
      onRefresh: _refresh,
    );
  }
}
