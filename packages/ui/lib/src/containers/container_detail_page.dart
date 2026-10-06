import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tr_extension.dart';
import '../widgets/app_icon.dart';
import 'container_log_console.dart';
import 'container_presentation.dart';
import 'hosted_app_status.dart';
import 'hosted_app_templates.dart';
import 'hosted_app_upsell_widgets.dart';
import 'hosted_containers_host.dart';
import 'hosted_models.dart';
import 'turnkey_bot_invite.dart';

class ContainerDetailPage extends StatefulWidget {
  final String containerId;
  final HostedContainersHost host;

  const ContainerDetailPage({
    super.key,
    required this.containerId,
    required this.host,
  });

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage> {
  HostedContainersHost get _host => widget.host;
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _stopping = false;
  bool _starting = false;
  bool _deleting = false;
  bool _inviting = false;

  /// Service d'invitation unique de la page : réutiliser la même instance est ce
  /// qui rend sa garde de réentrance efficace entre deux taps.
  TurnkeyBotInviteService? _inviteService;
  bool _claimingAd = false;
  bool _loadingEligibility = true;
  HostedAppEligibility? _eligibility;
  Timer? _pollTimer;
  Timer? _metricsTimer;
  StreamSubscription<ContainerLiveUpdate>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _metricsTimer?.cancel();
    unawaited(_eventsSub?.cancel());
    super.dispose();
  }

  /// Le statut du conteneur arrive par le canal temps réel : les minuteries ne sont
  /// plus qu'un filet de sécurité (serveur plus ancien, WebSocket coupée).
  Future<void> _ensureGatewayEvents() async {
    try {
      final updates = await _host.containerUpdates();
      if (updates == null) return;
      await _eventsSub?.cancel();
      _eventsSub = updates.listen(_onGatewayEvent);
    } catch (_) {}
  }

  void _onGatewayEvent(ContainerLiveUpdate container) {
    if (!mounted || container.containerId != widget.containerId) return;
    final current = _status;
    if (current == null) {
      unawaited(_loadStatus());
      return;
    }
    setState(() {
      _status = <String, dynamic>{
        ...current,
        'state': container.state,
        if (container.healthStatus.isNotEmpty)
          'health_status': container.healthStatus,
        'expires_at': container.expiresAt?.toIso8601String(),
      };
      _syncStatusTimers(container.state, healthStatus: container.healthStatus);
    });
  }

  Future<void> _init() async {
    await Future.wait([
      _loadStatus(showFullScreenLoader: true),
      _refreshEligibility(),
    ]);
    unawaited(_ensureGatewayEvents());
  }

  Future<void> _refreshEligibility() async {
    if (mounted) setState(() => _loadingEligibility = true);
    try {
      final elig = await _host.eligibility();
      if (mounted) {
        setState(() {
          _eligibility = elig;
          _loadingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEligibility = false);
    }
  }

  DateTime? get _expiresAt {
    final raw = _status?['expires_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  void _syncStatusTimers(String state, {String? healthStatus}) {
    final health = (healthStatus ?? '').trim().toLowerCase();
    if (state == 'PENDING' || state == 'PROVISIONING' || health == 'starting') {
      _metricsTimer?.cancel();
      _metricsTimer = null;
      // Filet de sécurité seulement : les transitions arrivent par le canal temps réel.
      _pollTimer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => _loadStatus(),
      );
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = null;
    if (state == 'RUNNING') {
      _metricsTimer ??= Timer.periodic(
        const Duration(seconds: 30),
        (_) => _loadStatus(),
      );
    } else {
      _metricsTimer?.cancel();
      _metricsTimer = null;
    }
  }

  Future<void> _watchAdAndTopUp() async {
    if (!_host.canWatchAds || _claimingAd) return;
    setState(() => _claimingAd = true);
    try {
      final result = await _host.watchAdAndClaim(
        placement: 'hosted_app_topup',
        containerId: widget.containerId,
        applyToContainer: true,
      );
      await Future.wait([_refreshEligibility(), _loadStatus()]);
      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.appliedToContainer
                  ? context.tr.container_detail_topup_applied(
                      result.grantedMinutes,
                    )
                  : context.tr.container_detail_topup_credited(
                      result.grantedMinutes,
                    ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingAd = false);
    }
  }

  Future<void> _applyStoredMinutes() async {
    final elig = _eligibility;
    if (elig == null || elig.premium || elig.hostingMinutesBalance <= 0) {
      return;
    }
    try {
      await _host.extendContainerTtl(
        widget.containerId,
        elig.hostingMinutesBalance,
      );
      await Future.wait([_refreshEligibility(), _loadStatus()]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.container_detail_minutes_applied(
                elig.hostingMinutesBalance,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStatus({bool showFullScreenLoader = false}) async {
    if (showFullScreenLoader || _status == null) {
      setState(() => _loading = true);
    }
    try {
      final status = await _host.containerStatus(widget.containerId);
      if (mounted) {
        setState(() {
          _status = status;
          _loading = false;
        });
      }
      _syncStatusTimers(
        status['state']?.toString() ?? '',
        healthStatus: status['health_status']?.toString(),
      );
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _stopContainer() async {
    final tr = context.tr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.container_detail_stop_title),
        content: Text(tr.container_detail_stop_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.container_detail_stop_btn),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _stopping = true);
    try {
      await _host.stopContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.container_detail_stopped_ok),
            backgroundColor: Colors.green,
          ),
        );
        _loadStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  Future<void> _startContainer() async {
    final tr = context.tr;
    setState(() => _starting = true);
    try {
      await _host.startContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.container_detail_started_ok),
            backgroundColor: Colors.green,
          ),
        );
        _loadStatus(showFullScreenLoader: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  /// Conteneur tel que le service d'invitation le lit.
  ///
  /// La page ne tient pas de [ContainerInfo] : elle ne charge qu'un statut
  /// (`GET /containers/{id}`) et son identifiant. On relit donc le statut par le
  /// même modèle que partout ailleurs, en imposant `widget.containerId` — c'est
  /// la seule clé dont l'invitation a besoin, et elle ne doit jamais dépendre de
  /// la façon dont le serveur nomme l'identifiant dans ce statut.
  ///
  /// `null` tant que le statut n'est pas chargé : l'appelant le dit alors
  /// explicitement, plutôt que d'inviter sur un conteneur vide.
  ContainerInfo? _containerForInvite() {
    final status = _status;
    if (status == null) return null;
    return ContainerInfo.fromJson(<String, dynamic>{
      ...status,
      'id': widget.containerId,
    });
  }

  /// Invite le bot de ce conteneur dans un serveur Discord.
  ///
  /// Le parcours (identité déjà connue → lien direct, sinon résolution par le
  /// manager) appartient à [TurnkeyBotInviteService]. Toute issue d'échec a un
  /// texte via [botInviteOutcomeMessage] : devant ce bouton, un tap ne reste
  /// jamais sans réponse.
  Future<void> _inviteBot() async {
    if (_inviting) return;
    final container = _containerForInvite();
    setState(() => _inviting = true);
    try {
      if (container == null) {
        // Statut indisponible : on le DIT, on n'invite pas à l'aveugle.
        _showInviteMessage(BotInviteOutcome.networkError);
        return;
      }
      final service = _inviteService ??= TurnkeyBotInviteService(host: _host);
      final outcome = await service.invite(container);
      if (!mounted) return;
      _showInviteMessage(outcome);
    } catch (error) {
      if (mounted) _showInviteMessage(BotInviteOutcome.networkError);
    } finally {
      if (mounted) {
        setState(() => _inviting = false);
      } else {
        _inviting = false;
      }
    }
  }

  /// Affiche le message de [outcome] : « opened » et « busy » n'ont rien à dire,
  /// et une chaîne vide ne produit donc aucun SnackBar.
  void _showInviteMessage(BotInviteOutcome outcome) {
    final message = botInviteOutcomeMessage(outcome, context.tr);
    if (message.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Bouton d'invitation : même famille visuelle que les boutons voisins
  /// (Démarrer / Arrêter), désactivé avec indicateur pendant l'appel.
  Widget _inviteBotButton(AppLocalizations tr) {
    return OutlinedButton.icon(
      onPressed: _inviting ? null : _inviteBot,
      icon: _inviting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const AppIcon.fromMaterial(Icons.person_add_alt_1),
      label: Text(
        _inviting ? tr.container_invite_busy : tr.container_invite_btn,
      ),
    );
  }

  Future<void> _deleteContainer() async {
    final tr = context.tr;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.container_detail_delete_title),
        content: Text(tr.container_detail_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr.container_detail_delete_btn),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _host.deleteContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.container_detail_deleted_ok),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatMemoryUsage(Map<String, dynamic>? status) {
    if (status == null) return '—';
    final limitMb = ContainerInfo.parseInt(status['memory_mb'], 0);
    final usageBytes = ContainerInfo.parseInt(status['memory_usage_bytes'], 0);
    if (usageBytes > 0) {
      final usedMb = (usageBytes / (1024 * 1024)).ceil();
      return '$usedMb / $limitMb MB';
    }
    return '$limitMb MB';
  }

  String _formatCpuUsage(Map<String, dynamic>? status) {
    if (status == null) return '—';
    final limitMillis = ContainerInfo.parseInt(status['cpu_millis'], 0);
    final usagePercent = (status['cpu_usage_percent'] as num?)?.toDouble() ?? 0;
    if (usagePercent > 0) {
      return '${usagePercent.toStringAsFixed(1)}% (${limitMillis}mCPU)';
    }
    return '${limitMillis}mCPU';
  }

  String _formatTimeRemaining(DateTime? expiresAt, AppLocalizations tr) {
    if (expiresAt == null) return '—';
    return containerExpiryLabel(expiresAt, tr);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = context.tr;
    final state = _status?['state']?.toString() ?? '';
    final image = _status?['image']?.toString() ?? '';
    final healthStatus = _status?['health_status']?.toString();
    final statusCode = _status?['status_code']?.toString();
    final statusMessage = _status?['status_message']?.toString();
    final isUnhealthy = isHostedAppUnhealthy(
      healthStatus: healthStatus,
      statusCode: statusCode,
    );
    final statusDescription = describeHostedAppStatus(
      healthStatus: healthStatus,
      statusCode: statusCode,
      statusMessage: statusMessage,
      state: state,
      tr: tr,
    );
    final template = templateForImage(image);
    final botTitle =
        template?.title ??
        (image.toLowerCase().contains('beatdock')
            ? tr.container_deploy_template_easy_music
            : (image.isNotEmpty ? image : 'Bot'));
    final botIcon =
        template?.icon ??
        (image.toLowerCase().contains('beatdock')
            ? Icons.music_note_rounded
            : Icons.smart_toy_outlined);

    return Scaffold(
      appBar: AppBar(
        title: Text(botTitle),
        actions: [
          if (_host.canOpenCopilot)
            IconButton(
              tooltip: tr.copilot_title,
              icon: const AppIcon.fromMaterial(Icons.auto_awesome_outlined),
              onPressed: () =>
                  _host.openCopilot(context, widget.containerId, botTitle),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          // Le bas de l'écran (dernier bouton d'action, dernière ligne de la
          // console) doit rester au-dessus de la barre de navigation Android.
          // `Scaffold` ne réserve QUE `viewInsets` (le clavier) pour le body :
          // la barre système, elle, n'est portée que par `MediaQuery.padding`,
          // qu'il faut donc ajouter soi-même — même règle que `bot_logs.dart`.
          : ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                16 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                if (!_loadingEligibility &&
                    _eligibility != null &&
                    !_eligibility!.premium) ...[
                  HostedAppFreeHostingBanner(
                    eligibility: _eligibility!,
                    claimingAd: _claimingAd,
                    // Desktop : aucune publicité n'y est diffusée. Le temps
                    // d'hébergement vient du SOLDE SERVEUR (bouton « appliquer les
                    // minutes stockées » ci-dessous), jamais d'une vidéo.
                    canWatchAds: _host.canWatchAds,
                    onWatchAd: !_host.canWatchAds
                        ? null
                        : (state == 'RUNNING' || state == 'PROVISIONING')
                        ? _watchAdAndTopUp
                        : null,
                    showTopUpHint:
                        state == 'RUNNING' || state == 'PROVISIONING',
                    expiresAt: _expiresAt,
                  ),
                  if (_eligibility!.hostingMinutesBalance > 0 &&
                      (state == 'RUNNING' || state == 'PROVISIONING'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: OutlinedButton.icon(
                        onPressed: _applyStoredMinutes,
                        icon: const AppIcon.fromMaterial(Icons.schedule),
                        label: Text(
                          context.tr.container_detail_apply_stored_minutes(
                            _eligibility!.hostingMinutesBalance,
                          ),
                        ),
                      ),
                    ),
                  HostedAppPremiumUpsell(
                    host: _host,
                    compact: true,
                    eligibility: _eligibility,
                  ),
                  const SizedBox(height: 8),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppIcon.fromMaterial(
                                botIcon,
                                color: colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    botTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (template != null)
                                    Text(
                                      template.description,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: containerStateColor(state),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              tr.container_detail_state,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            Text(
                              containerStateLabel(state, tr),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: containerStateColor(state),
                              ),
                            ),
                          ],
                        ),
                        if (_expiresAt != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const AppIcon.fromMaterial(
                                Icons.timer_outlined,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tr.container_detail_expires,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              Text(
                                _formatTimeRemaining(_expiresAt, tr),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const AppIcon.fromMaterial(
                              Icons.memory_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'RAM',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            Text(
                              _formatMemoryUsage(_status),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const AppIcon.fromMaterial(
                              Icons.speed_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CPU',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            Text(
                              _formatCpuUsage(_status),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isUnhealthy && statusDescription.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: (state == 'RUNNING' ? Colors.orange : Colors.red)
                        .withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIcon.fromMaterial(
                            state == 'RUNNING'
                                ? Icons.warning_amber_rounded
                                : Icons.error_outline,
                            color: state == 'RUNNING'
                                ? Colors.orange
                                : Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              statusDescription,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (state == 'RUNNING' || state == 'PROVISIONING') ...[
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange.shade800,
                    ),
                    onPressed: _stopping ? null : _stopContainer,
                    icon: _stopping
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const AppIcon.fromMaterial(Icons.power_settings_new),
                    label: Text(
                      _stopping
                          ? tr.container_state_stopping
                          : tr.container_detail_stop_title,
                    ),
                  ),
                  // Invitation juste sous « Éteindre » : le bot peut tourner sans
                  // être encore dans un serveur, c'est même le cas à la sortie du
                  // déploiement — c'est ici qu'on y remédie.
                  if (state == 'RUNNING') ...[
                    const SizedBox(height: 12),
                    _inviteBotButton(tr),
                  ],
                  if (state == 'RUNNING') ...[
                    const SizedBox(height: 24),
                    Text(
                      tr.container_detail_console,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      // 360 et non 300 : la console gagne un bandeau d'état d'une
                      // ligne, la hauteur compense pour garder le même nombre de
                      // lignes de log visibles qu'avant.
                      height: 360,
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        child: ContainerLogsViewer(
                          key: ValueKey('logs-${widget.containerId}'),
                          loadLogs: () =>
                              _host.containerLogs(widget.containerId),
                          containerId: widget.containerId,
                        ),
                      ),
                    ),
                  ],
                ],
                if (state == 'PENDING' || state == 'PROVISIONING')
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          statusDescription.isNotEmpty
                              ? statusDescription
                              : tr.container_detail_deploying,
                        ),
                      ],
                    ),
                  ),
                if (state == 'STOPPED') ...[
                  Text(
                    tr.container_detail_stopped_hint,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _starting ? null : _startContainer,
                    icon: _starting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const AppIcon.fromMaterial(Icons.play_arrow),
                    label: Text(
                      _starting
                          ? tr.container_detail_starting
                          : tr.container_detail_start_btn,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _inviteBotButton(tr),
                ],
                // Suppression accessible à TOUT moment : un conteneur EN MARCHE doit
                // pouvoir être détruit (le serveur l'arrête d'abord — Deployment et
                // Service Kubernetes, quota, ligne, secret de pull). La placer dans le
                // bloc « arrêté » rendait un bot clé en main indestructible tant qu'il
                // tournait, ce qui est précisément l'inverse de ce qu'on veut. Elle
                // reste séparée de « Éteindre », et sa confirmation dit que c'est
                // définitif : c'est la porte de sortie.
                if (state != 'PENDING' && state != 'PROVISIONING') ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _deleting ? null : _deleteContainer,
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const AppIcon.fromMaterial(Icons.delete_outline),
                    label: Text(
                      _deleting
                          ? tr.container_detail_delete_btn
                          : tr.container_detail_delete_title,
                    ),
                  ),
                ],
                if (state == 'FAILED')
                  Center(
                    child: Text(
                      tr.container_detail_status_stopped(
                        containerStateLabel(state, tr),
                      ),
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
              ],
            ),
    );
  }
}
