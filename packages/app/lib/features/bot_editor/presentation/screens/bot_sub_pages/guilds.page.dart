import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/home/presentation/guild_avatar.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.guilds_leave_title),
        content: Text(context.tr.guilds_leave_confirm(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

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
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.tr.guilds_tab),
            actions: [
              if (state.guilds.isNotEmpty)
                Text(
                  context.tr.guilds_server_count_other(state.guilds.length),
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
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
          body: PageContent(child: _buildBody(context, state)),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, GuildsLoadState state) {
    final cs = Theme.of(context).colorScheme;
    final guilds = _sortedByName(state.guilds);

    // Des serveurs sont connus (y compris pendant un rafraîchissement) : on
    // garde la liste affichée plutôt que de repasser par un spinner.
    if (guilds.isNotEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          padding: EdgeInsets.only(
            top: 8,
            bottom: FloatingGlassNavBar.contentClearanceOf(context) + 24,
          ),
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: guilds.length,
          separatorBuilder: (_, i2) => const Divider(height: 1),
          itemBuilder: (ctx, i) {
            final guild = guilds[i];
            final isLeaving = _leavingGuilds.contains(guild.id);
            return ListTile(
              leading: HomeBotAvatar(
                imageUrl: guild.iconUrl,
                size: 40,
                fallbackLabel: guildAvatarInitial(guild.name),
              ),
              title: Text(guild.name ?? guild.id),
              subtitle: Text(
                [
                  'ID: ${guild.id}',
                  if (guild.memberCount != null)
                    context.tr.guilds_members_count_other(guild.memberCount!),
                  if (guild.isOwner) context.tr.guilds_owner_label,
                ].join(' · '),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              trailing: IconButton(
                icon: isLeaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon.fromMaterial(
                        Icons.exit_to_app,
                        color: Colors.red,
                      ),
                tooltip: context.tr.guilds_leave_tooltip,
                onPressed: isLeaving ? null : () => _leaveGuild(guild),
              ),
            );
          },
        ),
      );
    }

    // Aucun serveur affichable : chargement initial, échec (jamais mis en
    // cache, donc « Réessayer » retente réellement), ou liste réellement vide.
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.status == GuildsLoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.error_outline,
              size: 48,
              color: cs.error,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr.error_with_details(state.errorMessage ?? ''),
              style: TextStyle(color: cs.error),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () => unawaited(_refresh()),
              child: Text(context.tr.common_retry),
            ),
          ],
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.fromMaterial(
            Icons.dns_outlined,
            size: 48,
            color: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr.guilds_empty_state,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Ordre d'affichage alphabétique de la page. La carte bot de la Home, elle,
  /// garde l'ordre déterministe par id du répertoire (avatars superposés).
  List<GuildAvatarInfo> _sortedByName(List<GuildAvatarInfo> guilds) {
    final sorted = <GuildAvatarInfo>[...guilds];
    sorted.sort(
      (a, b) => (a.name ?? a.id).toLowerCase().compareTo(
        (b.name ?? b.id).toLowerCase(),
      ),
    );
    return sorted;
  }
}
