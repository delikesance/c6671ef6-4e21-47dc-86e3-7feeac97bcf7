import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/poll_cadence.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_hosting_actions.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_status.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/logic/turnkey_bot_invite.dart';
import 'package:bot_creator/features/containers/presentation/hosted_app_upsell_widgets.dart';

class ContainerDetailPage extends StatefulWidget {
  final String containerId;
  final MainApiClient? client;

  const ContainerDetailPage({super.key, required this.containerId, this.client});

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage> {
  MainApiClient? _client;
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
  StreamSubscription<GatewayBotEvent>? _eventsSub;

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
    final client = _client;
    if (client == null) return;
    try {
      final session = client.connectGatewayBotEvents();
      await _eventsSub?.cancel();
      _eventsSub = session.events.listen(_onGatewayEvent);
    } catch (_) {}
  }

  void _onGatewayEvent(GatewayBotEvent event) {
    if (!mounted) return;
    final container = event.container;
    if (container == null || container.containerId != widget.containerId) return;
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
      _syncStatusTimers(
        container.state,
        healthStatus: container.healthStatus,
      );
    });
  }

  Future<void> _init() async {
    if (widget.client != null) {
      _client = widget.client;
    } else {
      try {
        final config = await MainApiSettingsStore.loadConfig();
        final session = await MainApiSettingsStore.loadSession();
        if (session != null && !session.isExpired && config.isConfigured) {
          _client = MainApiClient(baseUrl: config.baseUrl, accessToken: session.accessToken);
        }
      } catch (_) {}
    }
    await Future.wait([
      _loadStatus(showFullScreenLoader: true),
      _refreshEligibility(),
    ]);
    unawaited(_ensureGatewayEvents());
  }

  Future<void> _refreshEligibility() async {
    if (_client == null) {
      if (mounted) setState(() => _loadingEligibility = false);
      return;
    }
    setState(() => _loadingEligibility = true);
    try {
      final elig = await _client!.getHostedAppEligibility();
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
    if (_client == null || _claimingAd) return;
    setState(() => _claimingAd = true);
    try {
      final result = await HostedAppHostingActions.watchAdAndClaim(
        client: _client!,
        placement: 'hosted_app_topup',
        containerId: widget.containerId,
        applyToContainer: true,
      );
      await Future.wait([
        _refreshEligibility(),
        _loadStatus(),
      ]);
      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.appliedToContainer
                  ? context.tr.container_detail_topup_applied(result.grantedMinutes)
                  : context.tr.container_detail_topup_credited(result.grantedMinutes),
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
    if (_client == null || elig == null || elig.premium || elig.hostingMinutesBalance <= 0) {
      return;
    }
    try {
      await _client!.extendContainerTTL(
        widget.containerId,
        elig.hostingMinutesBalance,
      );
      await Future.wait([
        _refreshEligibility(),
        _loadStatus(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.container_detail_minutes_applied(elig.hostingMinutesBalance),
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
    if (_client == null) return;
    if (showFullScreenLoader || _status == null) {
      setState(() => _loading = true);
    }
    try {
      final status = await _client!.getContainerStatus(widget.containerId);
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
    if (_client == null) return;
    final tr = context.tr;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr.container_detail_stop_title),
      content: Text(tr.container_detail_stop_confirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr.container_detail_stop_btn)),
      ],
    ));
    if (confirm != true) return;

    setState(() => _stopping = true);
    try {
      await _client!.stopContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_stopped_ok), backgroundColor: Colors.green));
        _loadStatus();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  Future<void> _startContainer() async {
    if (_client == null) return;
    final tr = context.tr;
    setState(() => _starting = true);
    try {
      await _client!.startContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_started_ok), backgroundColor: Colors.green));
        _loadStatus(showFullScreenLoader: true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
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
      final service = _inviteService ??= TurnkeyBotInviteService(client: _client);
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
          : const Icon(Icons.person_add_alt_1),
      label: Text(
        _inviting ? tr.container_invite_busy : tr.container_invite_btn,
      ),
    );
  }

  Future<void> _deleteContainer() async {
    if (_client == null) return;
    final tr = context.tr;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr.container_detail_delete_title),
      content: Text(tr.container_detail_delete_confirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(tr.container_detail_delete_btn)),
      ],
    ));
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _client!.deleteContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_deleted_ok), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
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

  String _formatTimeRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return '—';
    final remaining = expiresAt.toUtc().difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 'Expired';
    final totalMinutes = remaining.inMinutes;
    if (totalMinutes < 1) return '<1m left';
    if (totalMinutes < 60) return '${totalMinutes}m left';
    final hours = totalMinutes ~/ 60;
    if (hours < 24) return '${hours}h left';
    return '${hours ~/ 24}d left';
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'RUNNING': return Colors.green;
      case 'PENDING': case 'PROVISIONING': return Colors.orange;
      case 'STOPPED': case 'STOPPING': return Colors.grey;
      case 'FAILED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _stateLabel(String state, AppLocalizations tr) {
    switch (state) {
      case 'RUNNING': return tr.container_state_running;
      case 'PENDING': return tr.container_state_pending;
      case 'PROVISIONING': return tr.container_state_provisioning;
      case 'STOPPED': return tr.container_state_stopped;
      case 'STOPPING': return tr.container_state_stopping;
      case 'FAILED': return tr.container_state_failed;
      default: return state;
    }
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
    final botTitle = template?.title ?? (image.toLowerCase().contains('beatdock') ? 'Bot Musique' : (image.isNotEmpty ? image : 'Bot'));
    final botIcon = template?.icon ?? (image.toLowerCase().contains('beatdock') ? Icons.music_note_rounded : Icons.smart_toy_outlined);

    return Scaffold(
      appBar: AppBar(title: Text(botTitle)),
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
              if (!_loadingEligibility && _eligibility != null && !_eligibility!.premium) ...[
                HostedAppFreeHostingBanner(
                  eligibility: _eligibility!,
                  claimingAd: _claimingAd,
                  onWatchAd: (state == 'RUNNING' || state == 'PROVISIONING')
                      ? _watchAdAndTopUp
                      : null,
                  showTopUpHint: state == 'RUNNING' || state == 'PROVISIONING',
                  expiresAt: _expiresAt,
                ),
                if (_eligibility!.hostingMinutesBalance > 0 &&
                    (state == 'RUNNING' || state == 'PROVISIONING'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: _applyStoredMinutes,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        context.tr.container_detail_apply_stored_minutes(
                          _eligibility!.hostingMinutesBalance,
                        ),
                      ),
                    ),
                  ),
                HostedAppPremiumUpsell(compact: true, eligibility: _eligibility),
                const SizedBox(height: 8),
              ],
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(botIcon, color: colorScheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(botTitle, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                          if (template != null)
                            Text(
                              template.description,
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _stateColor(state), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(tr.container_detail_state, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Text(_stateLabel(state, tr), style: TextStyle(fontWeight: FontWeight.bold, color: _stateColor(state))),
                ]),
                if (_expiresAt != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(tr.container_detail_expires, style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    Text(_formatTimeRemaining(_expiresAt), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ],
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.memory_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('RAM', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Text(_formatMemoryUsage(_status), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.speed_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('CPU', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Text(_formatCpuUsage(_status), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ]))),
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
                        Icon(
                          state == 'RUNNING'
                              ? Icons.warning_amber_rounded
                              : Icons.error_outline,
                          color: state == 'RUNNING' ? Colors.orange : Colors.red,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            statusDescription,
                            style: TextStyle(color: colorScheme.onSurfaceVariant),
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
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  onPressed: _stopping ? null : _stopContainer,
                  icon: _stopping
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.power_settings_new),
                  label: Text(_stopping ? tr.container_state_stopping : tr.container_detail_stop_title),
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
                Text(tr.container_detail_console, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  // 360 et non 300 : la console gagne un bandeau d'état d'une
                  // ligne, la hauteur compense pour garder le même nombre de
                  // lignes de log visibles qu'avant.
                  height: 360,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: _client != null
                        ? ContainerLogsViewer(
                            key: ValueKey('logs-${widget.containerId}'),
                            client: _client!,
                            containerId: widget.containerId,
                          )
                        : Center(child: Text(tr.container_detail_not_connected)),
                  ),
                ),
                ],
              ],
              if (state == 'PENDING' || state == 'PROVISIONING')
                Center(child: Column(children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    statusDescription.isNotEmpty
                        ? statusDescription
                        : tr.container_detail_deploying,
                  ),
                ])),
              if (state == 'STOPPED') ...[
                Text(tr.container_detail_stopped_hint, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _starting ? null : _startContainer,
                  icon: _starting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(_starting ? tr.container_detail_starting : tr.container_detail_start_btn),
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
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _deleting ? null : _deleteContainer,
                  icon: _deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline),
                  label: Text(_deleting ? tr.container_detail_delete_btn : tr.container_detail_delete_title),
                ),
              ],
              if (state == 'FAILED')
                Center(child: Text(tr.container_detail_status_stopped(_stateLabel(state, tr)), style: TextStyle(color: colorScheme.onSurfaceVariant))),
            ],
            ),
    );
  }
}

// ─── Console de logs ────────────────────────────────────────────────────────

/// Sévérité d'une ligne de log.
///
/// Elle ne sert qu'à hiérarchiser la LECTURE : couleur du texte, et pour les
/// alertes un liseré + un fond à peine teinté. Aucun cadre ni badge n'est ajouté
/// par ligne — c'est justement l'empilement de cadres et de sur-titres qui
/// rendait la console illisible.
enum ContainerLogSeverity { debug, info, warn, error }

/// Largeur de la colonne des horodatages : de quoi tenir « 23:59:59 » en 11 px.
const double _logTimeColumnWidth = 58;

/// Interlignage des lignes : confortable (≈ 18 px de ligne) sans diluer.
const double _logLineHeight = 1.45;
const double _logFontSize = 12.5;
const double _logTimeFontSize = 11;

/// Marqueur de niveau, dans les formes les plus répandues : `ERROR`, `[ERROR]`,
/// `error:`, `INFO -`, `SEVERE`, et `12:00:00 - DEBUG message` (séparateur avant
/// le niveau, comme le fait logback).
final RegExp _logLevelToken = RegExp(
  r'^\[?\s*[-–:|]?\s*(TRACE|VERBOSE|DEBUG|DBG|FINE|INFO|NOTICE|LOG|WARN|WARNING|ERROR|ERR|SEVERE|FATAL|CRITICAL|PANIC)\b[\]\:\-\s]*',
  caseSensitive: false,
);

/// Niveau écrit dans le corps de la ligne : `level=error`, `"level":"error"`.
final RegExp _logInlineLevel = RegExp(
  r'"?level"?\s*[=:]\s*"?([A-Za-z]+)',
  caseSensitive: false,
);

/// Horodatage en tête de ligne : ISO 8601 (`2026-09-19T12:34:56.789Z`),
/// `2026-09-19 12:34:56`, `[12:34:56]`, `12:34:56,789`, et la forme
/// `time=12:34:56` des runtimes qui étiquettent en `clé=valeur`. Le groupe 1 est
/// l'heure seule : c'est elle qu'on affiche, la date alourdirait chaque ligne
/// pour un tampon qui ne couvre que les derniers logs.
final RegExp _logTimestamp = RegExp(
  r'^\[?\s*(?:(?:time|ts|timestamp)\s*[=:]\s*)?(?:\d{4}-\d{2}-\d{2}[T ])?(\d{2}:\d{2}:\d{2})(?:[.,]\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})?\s*\]?\s*',
);

/// Signaux d'alerte cherchés dans le message quand le bot n'étiquette pas ses
/// lignes : c'est ce repli qui fait ressortir une erreur sur une image qui se
/// contente d'écrire sur sa sortie standard.
final RegExp _logErrorSignal = RegExp(
  r'\b(error|erreur|exception|traceback|fatal|panic|crash|err!|refused|eacces|econnrefused)\b',
  caseSensitive: false,
);
final RegExp _logWarnSignal = RegExp(
  r'\b(warn|warning|avertissement|deprecated|timeout|timed out|retry\w*)\b',
  caseSensitive: false,
);

/// Débuts typiques d'une ligne rattachée à la précédente (trace d'exception,
/// message multiligne) : elles sont alors alignées sur la colonne du message,
/// pour ne pas laisser croire à un nouvel événement.
final RegExp _logTracePrefix = RegExp(
  r'^(\s|at |File "|Caused by|During handling|\.{3} \d+ more|Traceback)',
);

/// Séquences ANSI : un tampon de conteneur peut en contenir, et elles se
/// liraient comme des saletés au milieu du message.
final RegExp _logAnsi = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

/// Une ligne de log analysée.
///
/// L'horodatage et le niveau sont sortis du texte pour deux raisons : la colonne
/// des heures reste alignée d'une ligne à l'autre (l'œil peut la sauter), et le
/// niveau devient une couleur au lieu d'un motif répété.
class ContainerLogLine {
  const ContainerLogLine({
    required this.raw,
    required this.time,
    required this.level,
    required this.message,
    required this.severity,
    required this.isContinuation,
  });

  /// Ligne d'origine, ANSI retiré.
  final String raw;

  /// Heure nue (« 12:34:56 »), vide quand la ligne n'en porte pas.
  final String time;

  /// Niveau nu et en majuscules (« ERROR »), vide quand la ligne n'en porte pas.
  final String level;

  /// Message débarrassé de l'horodatage et du niveau.
  final String message;

  /// Sévérité : niveau explicite s'il existe, contenu sinon.
  final ContainerLogSeverity severity;

  /// Vraie pour une ligne rattachée à la précédente (trace, continuation).
  final bool isContinuation;

  /// Texte à rendre : le message si l'analyse en a extrait un, sinon la ligne
  /// brute — une ligne réduite à un horodatage ne doit pas disparaître.
  String get displayMessage => message.trim().isEmpty ? raw.trim() : message;
}

/// Analyse un tampon de logs : une entrée par ligne non vide, horodatage et
/// niveau sortis du texte.
///
/// La sévérité d'une ligne de continuation suit celle de sa ligne d'en-tête :
/// une trace d'exception hérite donc de la couleur de son `Error:`, ce qui donne
/// un bloc repérable au lieu de lignes indépendantes.
List<ContainerLogLine> parseContainerLogLines(String raw) {
  final parsed = <ContainerLogLine>[];
  for (final rawLine in raw.split('\n')) {
    // Une ligne vide n'apprend rien et gonfle le défilement : on la saute.
    if (rawLine.trim().isEmpty) continue;
    final previous = parsed.isEmpty
        ? ContainerLogSeverity.info
        : parsed.last.severity;
    // Une trace hérite du rouge/orange de son en-tête ; sinon c'est du bruit
    // (trace d'un log normal), donc atténué.
    final inherited =
        previous == ContainerLogSeverity.error ||
            previous == ContainerLogSeverity.warn
        ? previous
        : ContainerLogSeverity.debug;
    parsed.add(_parseContainerLogLine(rawLine, inherited: inherited));
  }
  return parsed;
}

ContainerLogLine _parseContainerLogLine(
  String raw, {
  ContainerLogSeverity inherited = ContainerLogSeverity.info,
}) {
  final cleaned = raw.replaceAll(_logAnsi, '');
  var rest = cleaned;

  final timeMatch = _logTimestamp.firstMatch(rest);
  final time = timeMatch?.group(1) ?? '';
  if (timeMatch != null) {
    rest = rest.substring(timeMatch.end);
  }

  var level = '';
  final levelMatch = _logLevelToken.firstMatch(rest);
  if (levelMatch != null) {
    level = levelMatch.group(1)!.toUpperCase();
    rest = rest.substring(levelMatch.end);
  } else {
    final inlineLevel = _logInlineLevel.firstMatch(rest);
    if (inlineLevel != null) level = inlineLevel.group(1)!.toUpperCase();
  }

  final message = rest.trimLeft();
  final isContinuation =
      time.isEmpty && level.isEmpty && _logTracePrefix.hasMatch(cleaned);
  return ContainerLogLine(
    raw: cleaned,
    time: time,
    level: level,
    message: message,
    severity: isContinuation ? inherited : _logSeverity(level, message),
    isContinuation: isContinuation,
  );
}

/// Sévérité d'une ligne : le niveau explicite prime, sinon le contenu décide.
ContainerLogSeverity _logSeverity(String level, String message) {
  switch (level) {
    case 'TRACE':
    case 'VERBOSE':
    case 'DEBUG':
    case 'DBG':
    case 'FINE':
      return ContainerLogSeverity.debug;
    case 'WARN':
    case 'WARNING':
      return ContainerLogSeverity.warn;
    case 'ERROR':
    case 'ERR':
    case 'SEVERE':
    case 'FATAL':
    case 'CRITICAL':
    case 'PANIC':
      return ContainerLogSeverity.error;
    case 'INFO':
    case 'NOTICE':
    case 'LOG':
      return ContainerLogSeverity.info;
  }
  if (_logErrorSignal.hasMatch(message)) return ContainerLogSeverity.error;
  if (_logWarnSignal.hasMatch(message)) return ContainerLogSeverity.warn;
  return ContainerLogSeverity.info;
}

/// Console de logs d'un conteneur (bot clé en main / app hébergée).
///
/// Même rendu pour les DEUX portes d'entrée — le pavé « console » de la page de
/// détail et l'écran de logs ouvert depuis la carte d'accueil : une seule mise
/// en page, donc plus de divergence entre les deux écrans.
///
/// Une ligne = un horodatage discret aligné en colonne + un message monospace.
/// La sévérité passe par la couleur (et un liseré pour les alertes) et non par
/// des cadres empilés. Le bandeau du haut résume le tampon (nombre d'erreurs) et
/// permet de le copier d'un geste.
class ContainerLogsViewer extends StatefulWidget {
  final MainApiClient client;
  final String containerId;

  const ContainerLogsViewer({
    super.key,
    required this.client,
    required this.containerId,
  });

  @override
  State<ContainerLogsViewer> createState() => _ContainerLogsViewerState();
}

class _ContainerLogsViewerState extends State<ContainerLogsViewer> {
  final _scrollCtrl = ScrollController();
  String _logs = '';
  /// Tampon analysé une fois par tick : le défilement ne relance pas l'analyse.
  List<ContainerLogLine> _lines = const <ContainerLogLine>[];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  /// Cadence du sondage des logs d'app hébergée : un panneau laissé ouvert sur une app
  /// calme ne doit pas générer 12 requêtes par minute. Le plafond est plus haut que le
  /// défaut (15 s) : c'est un encart de consultation, pas l'écran principal.
  final PollCadence _logsCadence = PollCadence(
    nominal: const Duration(seconds: 5),
    ceiling: const Duration(seconds: 15),
  );

  @override
  void initState() {
    super.initState();
    // Premier chargement immédiat, puis sondage réarmé selon la cadence adaptative
    // (voir `_refreshLogs`) : plus de `Timer.periodic` fixe de 5 s.
    unawaited(_refreshLogs());
  }

  /// Un tick : charge les logs, enregistre le résultat dans la cadence et réarme le
  /// prochain tick. C'est ce réarmement, et non un `Timer.periodic`, qui espace les
  /// requêtes tant que le contenu ne change pas.
  Future<void> _refreshLogs({bool silent = false}) async {
    final outcome = await _loadLogs(silent: silent);
    _logsCadence.consume(outcome);
    // Réarmer une minuterie alors que le widget est démonté laisse « A Timer is still
    // pending even after the widget tree was disposed ».
    if (!mounted) {
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = Timer(
      _logsCadence.current,
      () => unawaited(_refreshLogs(silent: true)),
    );
  }

  Future<TickOutcome> _loadLogs({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final logs = await widget.client.getContainerLogs(widget.containerId);
      if (!mounted) return TickOutcome.unchanged;
      // Comparaison faite sur la chaîne déjà en mémoire (le contrat de l'endpoint est un
      // tampon texte) : le changement se détecte sans requête supplémentaire.
      final changed = logs != _logs;
      // Analyse faite ici, une fois par tick : le rendu se contente de lire.
      final lines = parseContainerLogLines(logs);
      setState(() {
        _logs = logs;
        _lines = lines;
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
      return changed ? TickOutcome.changed : TickOutcome.unchanged;
    } catch (e) {
      if (!mounted) return TickOutcome.unchanged;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      // Un endpoint en échec ne doit pas être martelé : le compter comme inchangé espace
      // le sondage, ce qui sert de repli progressif jusqu'au rétablissement.
      return TickOutcome.unchanged;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  /// Copie le tampon BRUT (horodatages et niveaux d'origine compris) : c'est ce
  /// qu'on colle dans un ticket, pas la version mise en page par l'app.
  Future<void> _copyLogs() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.bot_logs_copied)));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _logs.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr.container_detail_failed(_error!),
            style: const TextStyle(fontSize: 12, color: AppTheme.errorLight),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_lines.isEmpty) {
      // Un tampon vide n'est pas une panne : on le dit calmement, sans encadré.
      return Center(
        child: Text(
          context.tr.bot_logs_empty,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Seules les lignes d'en-tête comptent : une trace de dix lignes ne doit pas
    // s'afficher comme dix erreurs.
    final errorCount = _lines
        .where(
          (line) =>
              line.severity == ContainerLogSeverity.error &&
              !line.isContinuation,
        )
        .length;
    // La colonne des horodatages n'est réservée que si le tampon en porte : sur
    // téléphone, 58 px gaspillés par ligne coûteraient un tiers du message.
    final showTime = _lines.any((line) => line.time.isNotEmpty);

    return Column(
      children: [
        _LogConsoleHeaderStrip(errorCount: errorCount, onCopy: _copyLogs),
        Expanded(
          // `SelectionArea` conserve le copier-coller du contenu, comme le
          // `SelectableText` d'avant, mais ligne par ligne.
          child: SelectionArea(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _lines.length,
              itemBuilder: (context, index) => ContainerLogRow(
                key: ValueKey<String>('container-log-$index'),
                line: _lines[index],
                showTime: showTime,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de la console.
///
/// Hiérarchie voulue : l'horodatage est une colonne discrète et alignée, le
/// message est en monospace avec un interlignage confortable, et la sévérité ne
/// coûte AUCUN cadre — seulement une couleur, plus un liseré et un fond à peine
/// teinté pour les alertes.
class ContainerLogRow extends StatelessWidget {
  const ContainerLogRow({super.key, required this.line, this.showTime = true});

  /// Clés stables des deux colonnes, utilisées par les tests de mise en page.
  static const Key timeKey = Key('container-log-time');
  static const Key messageKey = Key('container-log-message');

  final ContainerLogLine line;

  /// Vrai quand le tampon porte des horodatages : sinon la colonne est omise.
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _logAccentColor(line.severity);
    return Container(
      decoration: BoxDecoration(
        color: _logBackgroundTint(line.severity),
        border: accent == null
            ? null
            : Border(left: BorderSide(color: accent, width: 2)),
      ),
      padding: EdgeInsets.only(
        left: line.isContinuation ? 18 : 8,
        right: 10,
        top: 1,
        bottom: 1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTime)
            SizedBox(
              width: _logTimeColumnWidth,
              child: line.time.isEmpty
                  ? null
                  : Text(
                      line.time,
                      key: timeKey,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _logTimeFontSize,
                        height: _logLineHeight,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
            ),
          Expanded(
            child: Text(
              line.displayMessage,
              key: messageKey,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: _logFontSize,
                height: _logLineHeight,
                color: _logTextColor(line.severity, scheme),
                fontWeight: line.severity == ContainerLogSeverity.error
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'état de la console : le nombre d'erreurs du tampon (pour savoir
/// qu'il y en a sans dérouler les 200 lignes) et la copie du tampon brut.
///
/// Volontairement réduit à une ligne, sans titre : l'écran porte déjà son titre,
/// le répéter ici était du chrome en trop.
class _LogConsoleHeaderStrip extends StatelessWidget {
  const _LogConsoleHeaderStrip({required this.errorCount, required this.onCopy});

  final int errorCount;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasErrors = errorCount > 0;
    final color = hasErrors ? AppTheme.errorLight : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasErrors
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.tr.container_logs_errors_count(errorCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: context.tr.copy,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            icon: const Icon(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

/// Couleur du texte : c'est elle qui porte le niveau, sans badge répété.
Color _logTextColor(ContainerLogSeverity severity, ColorScheme scheme) {
  switch (severity) {
    case ContainerLogSeverity.debug:
      return scheme.onSurfaceVariant.withValues(alpha: 0.5);
    case ContainerLogSeverity.warn:
      return AppTheme.warning;
    case ContainerLogSeverity.error:
      return AppTheme.errorLight;
    case ContainerLogSeverity.info:
      return scheme.onSurface.withValues(alpha: 0.92);
  }
}

/// Liseré des alertes et des erreurs : un repère vertical qu'on suit du coin de
/// l'œil en défilant, sans bordure autour de chaque ligne.
Color? _logAccentColor(ContainerLogSeverity severity) {
  switch (severity) {
    case ContainerLogSeverity.warn:
      return AppTheme.warning;
    case ContainerLogSeverity.error:
      return AppTheme.errorLight;
    case ContainerLogSeverity.debug:
    case ContainerLogSeverity.info:
      return null;
  }
}

/// Fond à peine teinté : assez pour détacher un bloc d'erreur, trop peu pour
/// transformer la console en damier.
Color? _logBackgroundTint(ContainerLogSeverity severity) {
  switch (severity) {
    case ContainerLogSeverity.warn:
      return AppTheme.warning.withValues(alpha: 0.07);
    case ContainerLogSeverity.error:
      return AppTheme.error.withValues(alpha: 0.10);
    case ContainerLogSeverity.debug:
    case ContainerLogSeverity.info:
      return null;
  }
}
