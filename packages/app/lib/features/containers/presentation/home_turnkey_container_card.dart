import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_status.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/presentation/container_detail_page.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';

/// Actions exposées par la carte d'accueil d'un conteneur clé en main.
///
/// Un bot hébergé n'a AUCUNE configuration à éditer : sa carte n'offre donc
/// jamais « Manage »/éditeur, uniquement démarrer/arrêter, voir les logs et
/// ajouter du temps.
class HomeContainerActions {
  const HomeContainerActions({
    required this.onStart,
    required this.onStop,
    required this.onLogs,
    required this.onDetail,
    this.onInvite,
    this.busy = false,
    this.inviteBusy = false,
  });

  /// Démarre le conteneur (état arrêté uniquement).
  final VoidCallback? onStart;

  /// Arrête le conteneur (état démarré uniquement).
  final VoidCallback? onStop;

  /// Ouvre la console de logs du conteneur.
  final VoidCallback? onLogs;

  /// Invite le bot de ce conteneur dans un serveur Discord : l'à-propos ne
  /// dépend PAS de l'état du conteneur (un bot à l'arrêt reste invitable), donc
  /// la carte ne conditionne pas ce bouton à `container.isRunning`.
  final VoidCallback? onInvite;

  /// Ouvre la page de DÉTAIL du conteneur, seul endroit d'où l'on gère vraiment :
  /// ajout de temps, ressources, et SUPPRESSION. Le raccourci « ajouter du temps »
  /// qui ouvrait cette page par effet de bord a été retiré : sur l'accueil, ce qu'on
  /// veut, c'est un chemin lisible vers la gestion, pas une action détournée.
  final VoidCallback? onDetail;

  /// Vrai pendant une action en cours : la carte se verrouille pour éviter un
  /// double clic sur démarrer/arrêter.
  final bool busy;

  /// Vrai pendant une invitation en cours : le bouton « Inviter le bot » est
  /// désactivé et porte l'indicateur d'occupation, donc aucun second envoi.
  final bool inviteBusy;
}

/// Libellé d'un conteneur clé en main : le nom produit (« Easy Music Bot »)
/// quand l'image y correspond, sinon le titre du modèle, sinon l'image brute —
/// même règle de résolution que la liste « Turnkey Bots ».
String turnkeyContainerTitle(ContainerInfo container, AppLocalizations tr) {
  final template = templateForImage(container.image);
  if (template?.id == HostedAppTemplateId.easyMusic ||
      container.image.toLowerCase().contains('beatdock')) {
    return tr.container_deploy_template_easy_music;
  }
  return template?.title ?? container.image;
}

/// Compose la séquence de cartes de la liste d'accueil (« MY PROJECTS ») : les
/// bots classiques — cartes déjà construites par l'appelant, donc rendues par
/// exactement le même chemin qu'avant — puis les conteneurs clé en main, qui
/// s'ajoutent À CÔTÉ d'eux dans la même liste au lieu d'un écran séparé.
///
/// Publique pour être vérifiable en test sans monter toute la page d'accueil.
List<Widget> buildHomeProjectCards({
  required List<Widget> botCards,
  required List<ContainerInfo> containers,
  required HomeContainerActions Function(ContainerInfo container) actionsFor,
}) {
  return <Widget>[
    ...botCards,
    for (final container in containers)
      HomeTurnkeyContainerCard(
        key: ValueKey<String>('home-turnkey-${container.id}'),
        container: container,
        actions: actionsFor(container),
      ),
  ];
}

/// Carte d'accueil d'un conteneur clé en main.
///
/// Elle rend le conteneur identifiable d'un seul coup d'œil — modèle
/// (template), image et état — et signale clairement un conteneur arrêté ou
/// expiré, là où la carte d'un bot classique parle de serveurs et d'édition.
class HomeTurnkeyContainerCard extends StatelessWidget {
  const HomeTurnkeyContainerCard({
    super.key,
    required this.container,
    required this.actions,
  });

  final ContainerInfo container;
  final HomeContainerActions actions;

  /// Libellé affiché : délègue à [turnkeyContainerTitle] pour que la carte et le
  /// titre de la console de logs ne puissent pas diverger.
  String titleLabel(AppLocalizations tr) =>
      turnkeyContainerTitle(container, tr);

  IconData get _icon {
    final template = templateForImage(container.image);
    if (template != null) return template.icon;
    return container.image.toLowerCase().contains('beatdock')
        ? Icons.music_note_rounded
        : Icons.smart_toy_outlined;
  }

  /// Même code couleur que la liste « Turnkey Bots » : vert en marche, orange
  /// pendant la préparation, gris à l'arrêt, rouge en échec.
  Color _stateColor() {
    switch (container.state) {
      case 'RUNNING':
        return AppTheme.online;
      case 'PENDING':
      case 'PROVISIONING':
        return Colors.orange;
      case 'STOPPED':
      case 'STOPPING':
        return Colors.grey;
      case 'FAILED':
        return AppTheme.danger;
      default:
        return Colors.grey;
    }
  }

  String _stateLabel(AppLocalizations tr) {
    switch (container.state) {
      case 'RUNNING':
        return tr.container_state_running;
      case 'PENDING':
        return tr.container_state_pending;
      case 'PROVISIONING':
        return tr.container_state_provisioning;
      case 'STOPPED':
        return tr.container_state_stopped;
      case 'STOPPING':
        return tr.container_state_stopping;
      case 'FAILED':
        return tr.container_state_failed;
      default:
        return container.state;
    }
  }

  /// Vrai quand le TTL est dépassé : le conteneur n'a plus de temps d'hébergement.
  bool get _isExpired {
    if (container.expiresAt.millisecondsSinceEpoch == 0) return false;
    return !container.expiresAt.toUtc().isAfter(DateTime.now().toUtc());
  }

  /// Temps d'hébergement restant, ou le libellé « Expired » ; `null` quand le
  /// conteneur n'a pas d'échéance connue.
  String? _expiryLabel(AppLocalizations tr) {
    if (container.expiresAt.millisecondsSinceEpoch == 0) return null;
    final remaining = container.expiresAt
        .toUtc()
        .difference(DateTime.now().toUtc());
    if (remaining.isNegative) return tr.container_list_expired;
    final totalMinutes = remaining.inMinutes;
    if (totalMinutes < 1) return tr.container_list_expiry_minutes(1);
    if (totalMinutes < 60) return tr.container_list_expiry_minutes(totalMinutes);
    final hours = totalMinutes ~/ 60;
    if (hours < 24) {
      return tr.container_list_expiry_hours(hours, totalMinutes % 60);
    }
    return tr.container_list_expiry_days(hours ~/ 24, hours % 24);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final tr = context.tr;
    final cardColor = isDark ? tokens.card : scheme.surfaceContainer;
    final borderColor = isDark ? tokens.cardBorder : scheme.outlineVariant;
    final stateColor = _stateColor();
    final expiry = _expiryLabel(tr);
    final expired = _isExpired;
    final unhealthy = isHostedAppUnhealthy(
      healthStatus: container.healthStatus,
      statusCode: container.statusCode,
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_icon, color: scheme.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              titleLabel(tr),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: homeDisplayStyle(
                                16,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              tr.app_create_type_hosted,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tr.container_deploy_image_label}: ${container.image}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? tokens.muted : scheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                    border: Border.all(
                      color: stateColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _stateLabel(tr),
                    style: TextStyle(
                      color: stateColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (expiry != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    expired
                        ? Icons.timer_off_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: expired ? AppTheme.danger : scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      expiry,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: expired
                            ? AppTheme.danger
                            : scheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: expired ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (unhealthy) ...[
              const SizedBox(height: 8),
              Text(
                describeHostedAppStatus(
                  healthStatus: container.healthStatus,
                  statusCode: container.statusCode,
                  statusMessage: container.statusMessage,
                  state: container.state,
                  tr: tr,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: container.isRunning
                      ? HomeCardActionButton(
                          icon: Icons.stop_rounded,
                          label: tr.home_stop,
                          accent: AppTheme.danger,
                          stopSquare: true,
                          loading: actions.busy,
                          onTap: actions.busy ? null : actions.onStop,
                        )
                      : HomeCardActionButton(
                          icon: Icons.play_arrow_rounded,
                          label: tr.container_detail_start_btn,
                          loading: actions.busy,
                          onTap: actions.busy ? null : actions.onStart,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeCardActionButton(
                    icon: Icons.article_outlined,
                    label: tr.home_logs_tooltip,
                    onTap: actions.onLogs,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: HomeCardActionButton(
                    icon: Icons.person_add_alt_1_rounded,
                    label: actions.inviteBusy
                        ? tr.container_invite_busy
                        : tr.container_invite_btn,
                    loading: actions.inviteBusy,
                    onTap: actions.inviteBusy ? null : actions.onInvite,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HomeCardActionButton(
                    icon: Icons.tune_rounded,
                    label: tr.container_detail_open,
                    onTap: actions.onDetail,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Console de logs d'un conteneur clé en main ouverte depuis l'accueil.
///
/// Elle rend EXACTEMENT la même mise en page que le pavé « console » de la page
/// de détail : un seul `ContainerLogsViewer` pour les deux écrans, donc plus de
/// divergence de lisibilité entre eux. Seul l'habitacle diffère — ici une page
/// entière, avec le même cadre de carte pour que les deux se lisent pareil.
class HomeContainerLogsPage extends StatelessWidget {
  const HomeContainerLogsPage({
    super.key,
    required this.client,
    required this.containerId,
    required this.title,
  });

  final MainApiClient client;
  final String containerId;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // `SafeArea` protège le bas de l'écran de la barre de navigation Android :
      // `Scaffold` ne réserve au body que `viewInsets` (le clavier), alors que la
      // barre système est portée par `MediaQuery.padding`. Sans cet inset, la
      // dernière ligne de log restait sous la barre.
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: ContainerLogsViewer(
              client: client,
              containerId: containerId,
            ),
          ),
        ),
      ),
    );
  }
}
