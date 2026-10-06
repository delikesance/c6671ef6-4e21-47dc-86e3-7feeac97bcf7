// L'ÉCRAN « REJEU DU DÉBOGUEUR » D'UN BOT : les exécutions de commandes
// capturées, rejouées étape par étape (durée, résultat, variables avant/après).
// Partagé entre l'app et le Studio ; tout ce qui parle au runtime passe par
// [DebugReplayHost].
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../utils/poll_cadence.dart';
import '../widgets/app_icon.dart';
import '../widgets/page_layout.dart';
import 'debug_replay_host.dart';
import 'debug_replay_models.dart';

// ─── List page ───────────────────────────────────────────────────────────────

class DebugReplayPage extends StatefulWidget {
  const DebugReplayPage({super.key, this.botId, required this.host});

  final String? botId;
  final DebugReplayHost host;

  @override
  State<DebugReplayPage> createState() => _DebugReplayPageState();
}

class _DebugReplayPageState extends State<DebugReplayPage> {
  StreamSubscription<List<DebugReplayRecord>>? _sub;
  Timer? _runnerPollTimer;

  /// Le serveur fait foi : la page l'interroge (au lieu de la mémoire locale).
  bool _usingRemoteData = false;

  /// Le dernier relevé du serveur a échoué (bot arrêté, serveur injoignable).
  bool _remoteUnavailable = false;

  /// Cadence du sondage des replays : un écran laissé ouvert sur un bot calme ne doit
  /// pas générer 24 requêtes par minute.
  final PollCadence _replaysCadence = PollCadence(
    nominal: const Duration(milliseconds: 2500),
  );

  /// Dernières entrées affichées, comparées en mémoire (aucune requête supplémentaire)
  /// pour savoir si le tick courant apporte du neuf.
  _ReplaysSnapshot? _lastReplaysSnapshot;

  List<DebugReplayRecord> _replays = const [];
  bool _capturing = false;

  DebugReplayHost get _host => widget.host;
  String get _botId => widget.botId?.trim() ?? '';

  @override
  void initState() {
    super.initState();
    _capturing = _host.localCapturing;
    _replays = _filtered(_host.localReplays);
    _sub = _host.localReplaysStream.listen((all) {
      if (!mounted) return;
      if (_usingRemoteData) return;
      setState(() => _replays = _filtered(all));
    });
    unawaited(_initRemotePolling());
  }

  Future<void> _initRemotePolling() async {
    if (_botId.isEmpty) {
      return;
    }

    try {
      final outcome = await _pollRemoteReplays(rethrowErrors: true);
      if (!mounted) return;
      // `null` : aucun serveur à interroger, la mémoire locale reste la source.
      if (outcome == null) return;
      setState(() => _usingRemoteData = true);
      // Le premier tick vient d'être fait : plus de `Timer.periodic` fixe, on n'arme que
      // le suivant, à la cadence courante (adaptative).
      _replaysCadence.consume(outcome);
      _reschedulePolling();
    } catch (_) {
      if (!mounted) return;
      // Avec une mémoire locale, elle prend le relais ; sans elle (Studio), le
      // serveur reste la seule source : on continue d'attendre que le bot démarre.
      if (_host.hasLocalSource) return;
      setState(() {
        _usingRemoteData = true;
        _remoteUnavailable = true;
      });
      _replaysCadence.consume(TickOutcome.unchanged);
      _reschedulePolling();
    }
  }

  /// Exécute un tick puis réarme le suivant : c'est ce réarmement, et non un
  /// `Timer.periodic`, qui permet d'espacer les requêtes quand rien ne change.
  Future<void> _pollAndReschedule() async {
    final outcome = await _pollRemoteReplays();
    _replaysCadence.consume(outcome ?? TickOutcome.unchanged);
    // Réarmer une minuterie alors que la page est démontée laisse « A Timer is still
    // pending even after the widget tree was disposed ».
    if (!mounted) {
      return;
    }
    _reschedulePolling();
  }

  void _reschedulePolling() {
    _runnerPollTimer?.cancel();
    _runnerPollTimer = Timer(_replaysCadence.current, () {
      if (!mounted) {
        return;
      }
      unawaited(_pollAndReschedule());
    });
  }

  /// `null` = pas de serveur (mémoire locale).
  Future<TickOutcome?> _pollRemoteReplays({bool rethrowErrors = false}) async {
    if (_botId.isEmpty) {
      return TickOutcome.unchanged;
    }

    DebugReplaySnapshot? snapshot;
    try {
      snapshot = await _host.fetchReplays(_botId, limit: 30);
    } catch (_) {
      if (rethrowErrors) {
        rethrow;
      }
      // Un endpoint en échec ne doit pas être martelé : le compter comme inchangé espace
      // le sondage, ce qui sert de repli progressif jusqu'au rétablissement.
      if (mounted && !_remoteUnavailable) {
        setState(() => _remoteUnavailable = true);
      }
      return TickOutcome.unchanged;
    }

    if (snapshot == null) {
      return null;
    }
    if (!mounted) {
      return TickOutcome.unchanged;
    }

    final replays = _filtered(snapshot.replays);
    // Comparaison faite sur la charge utile déjà en mémoire : l'état de capture, le
    // nombre d'entrées et la plus récente suffisent à détecter du neuf, sans requête
    // supplémentaire ni comparaison de tout le contenu des frames.
    final latest = replays.isEmpty ? null : replays.first;
    final signature = (
      capturing: snapshot.capturing,
      count: replays.length,
      last: latest == null
          ? ''
          : '${latest.triggeredAt.toIso8601String()}|${latest.commandLabel}|${latest.totalMs}',
    );
    final changed = signature != _lastReplaysSnapshot;
    _lastReplaysSnapshot = signature;
    final capturing = snapshot.capturing;
    setState(() {
      _remoteUnavailable = false;
      _capturing = capturing;
      _replays = replays;
    });
    return changed ? TickOutcome.changed : TickOutcome.unchanged;
  }

  List<DebugReplayRecord> _filtered(List<DebugReplayRecord> all) {
    final botId = widget.botId;
    if (botId == null || botId.isEmpty) return List.of(all);
    return all.where((r) => r.botId == botId).toList(growable: false);
  }

  @override
  void dispose() {
    _runnerPollTimer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // L'hôte tranche : dans l'app le rejeu s'exécute SUR l'appareil (pas de
    // formule requise tant que le bot y tourne), dans le Studio c'est la formule
    // du compte, que le Manager applique aussi.
    final hasCapability = _host.hasCapability(widget.botId);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.debug_replay_title),
        actions: [
          if (hasCapability) ...[
            IconButton(
              tooltip: _capturing
                  ? context.tr.debug_replay_stop_capture
                  : context.tr.debug_replay_start_capture,
              icon: AppIcon.fromMaterial(
                _capturing
                    ? Icons.fiber_manual_record
                    : Icons.fiber_manual_record_outlined,
                color: _capturing ? AppTheme.error : null,
              ),
              onPressed: () {
                final next = !_capturing;
                setState(() => _capturing = next);
                unawaited(_setCaptureEnabled(next));
              },
            ),
            if (_replays.isNotEmpty)
              IconButton(
                tooltip: context.tr.debug_replay_clear,
                icon: const AppIcon.fromMaterial(Icons.delete_sweep_outlined),
                onPressed: () async {
                  final confirmed = await AppTheme.showConfirmDialog(
                    context,
                    title: context.tr.debug_replay_clear_title,
                    content: context.tr.debug_replay_clear_confirm,
                    confirmLabel: context.tr.delete,
                    isDestructive: true,
                  );
                  if (!confirmed) return;
                  if (_usingRemoteData && _botId.isNotEmpty) {
                    try {
                      await _host.clearReplays(_botId);
                      if (mounted) {
                        setState(() => _replays = const <DebugReplayRecord>[]);
                      }
                    } catch (_) {}
                    return;
                  }
                  _host.clearLocalReplays();
                },
              ),
          ],
        ],
      ),
      // Largeur et marges communes à toutes les pages (contrat AppPageLayout).
      body: SafeArea(
        top: false,
        child: PageContent(
          child: hasCapability
              ? _buildBody(context)
              : _buildSoftLockedBody(context),
        ),
      ),
    );
  }

  Widget _buildSoftLockedBody(BuildContext context) {
    return Column(
      children: [
        _buildPremiumInlineCard(context),
        Expanded(
          child: _buildBody(
            context,
            allowCapture: false,
            allowOpenDetail: false,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumInlineCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIcon.fromMaterial(
                  Icons.play_circle_outline,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.debug_replay_premium_title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.debug_replay_premium_desc,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _host.buildUpgradeAction(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    bool allowCapture = true,
    bool allowOpenDetail = true,
  }) {
    if (_replays.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon.fromMaterial(
                Icons.manage_search,
                size: 56,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _remoteUnavailable
                    ? context.tr.debug_replay_unavailable
                    : _capturing && allowCapture
                    ? context.tr.debug_replay_empty_capturing
                    : context.tr.debug_replay_empty_idle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (!_capturing && allowCapture && !_remoteUnavailable) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _capturing = true);
                    unawaited(_setCaptureEnabled(true));
                  },
                  icon: const AppIcon.fromMaterial(Icons.fiber_manual_record),
                  label: Text(context.tr.debug_replay_start_capture),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _replays.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final replay = _replays[index];
        return _ReplayListTile(
          replay: replay,
          onTap: allowOpenDetail
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DebugReplayDetailPage(replay: replay),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }

  Future<void> _setCaptureEnabled(bool enabled) async {
    if (_usingRemoteData && _botId.isNotEmpty) {
      try {
        final remoteState = await _host.setCapturing(_botId, enabled);
        if (mounted) {
          setState(() => _capturing = remoteState);
        }
      } catch (_) {
        if (mounted) {
          setState(() => _capturing = !enabled);
        }
      }
      return;
    }

    _host.setLocalCapturing(enabled);
  }
}

/// Signature de ce que l'écran affiche, réduite à ce qui change visiblement (état de
/// capture, nombre d'entrées, entrée la plus récente) : l'égalité structurelle du
/// « record » suffit à détecter un changement sans requête supplémentaire.
typedef _ReplaysSnapshot = ({bool capturing, int count, String last});

class _ReplayListTile extends StatelessWidget {
  const _ReplayListTile({required this.replay, required this.onTap});

  final DebugReplayRecord replay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = replay.hasError ? colorScheme.error : AppTheme.success;
    final timeAgo = _formatTimeAgo(context, replay.triggeredAt);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: AppIcon.fromMaterial(
          replay.hasError ? Icons.error_outline : Icons.check_circle_outline,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        '/${replay.commandLabel}',
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
      subtitle: Text(
        '${context.tr.debug_replay_summary(replay.actionCount, replay.totalMs)} • $timeAgo',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: onTap != null
          ? const AppIcon.fromMaterial(Icons.chevron_right, size: 18)
          : null,
    );
  }

  String _formatTimeAgo(BuildContext context, DateTime dt) {
    final tr = context.tr;
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return tr.debug_replay_ago_seconds(diff.inSeconds);
    if (diff.inMinutes < 60) return tr.debug_replay_ago_minutes(diff.inMinutes);
    if (diff.inHours < 24) return tr.debug_replay_ago_hours(diff.inHours);
    return tr.debug_replay_ago_days(diff.inDays);
  }
}

// ─── Detail page ─────────────────────────────────────────────────────────────

class DebugReplayDetailPage extends StatefulWidget {
  const DebugReplayDetailPage({super.key, required this.replay});

  final DebugReplayRecord replay;

  @override
  State<DebugReplayDetailPage> createState() => _DebugReplayDetailPageState();
}

class _DebugReplayDetailPageState extends State<DebugReplayDetailPage>
    with TickerProviderStateMixin {
  int _activeStep = -1; // -1 = overview, 0..n = frame index
  bool _isPlaying = false;
  Timer? _playTimer;

  late AnimationController _stepAnimController;
  late Animation<double> _stepAnim;

  @override
  void initState() {
    super.initState();
    _stepAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _stepAnim = CurvedAnimation(
      parent: _stepAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _stepAnimController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    setState(() => _activeStep = index);
    _stepAnimController.forward(from: 0);
  }

  void _startPlayback() {
    if (_isPlaying) return;
    final start = _activeStep < 0 ? 0 : _activeStep;
    _goToStep(start);
    setState(() => _isPlaying = true);

    void advance() {
      if (!mounted) return;
      final next = _activeStep + 1;
      if (next >= widget.replay.frames.length) {
        setState(() => _isPlaying = false);
        return;
      }
      _goToStep(next);
      final ms = widget.replay.frames[next].durationMs.clamp(80, 800);
      _playTimer = Timer(Duration(milliseconds: ms + 200), advance);
    }

    final firstMs = widget.replay.frames[start].durationMs.clamp(80, 800);
    _playTimer = Timer(Duration(milliseconds: firstMs + 200), advance);
  }

  void _stopPlayback() {
    _playTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  int get _totalMs => widget.replay.totalMs;

  @override
  Widget build(BuildContext context) {
    final replay = widget.replay;
    final colorScheme = Theme.of(context).colorScheme;
    final frames = replay.frames;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '/${replay.commandLabel}',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        actions: [
          IconButton(
            tooltip: context.tr.debug_replay_overview,
            icon: const AppIcon.fromMaterial(Icons.bar_chart_outlined),
            onPressed: () => _goToStep(-1),
          ),
        ],
      ),
      // Largeur et marges communes à toutes les pages (contrat AppPageLayout).
      body: SafeArea(
        top: false,
        child: PageContent(
          child: Column(
            children: [
              // ── Header summary ──
              _buildHeader(context, replay, colorScheme),
              const Divider(height: 1),
              // ── Timeline bar ──
              if (frames.isNotEmpty)
                _buildTimeline(context, frames, colorScheme),
              const Divider(height: 1),
              // ── Playback controls ──
              _buildPlaybackControls(context, frames),
              const Divider(height: 1),
              // ── Detail pane ──
              Expanded(
                child: _activeStep < 0
                    ? _buildOverview(context, replay, colorScheme)
                    : _buildFrameDetail(
                        context,
                        frames[_activeStep],
                        _activeStep,
                        colorScheme,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DebugReplayRecord replay,
    ColorScheme colorScheme,
  ) {
    final statusColor = replay.hasError ? colorScheme.error : AppTheme.success;
    return Padding(
      // La marge horizontale vient de `PageContent` (contrat AppPageLayout).
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          AppIcon.fromMaterial(
            replay.hasError ? Icons.error_outline : Icons.check_circle_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr.debug_replay_summary(
                replay.actionCount,
                replay.totalMs,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            _formatAbsTime(replay.triggeredAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<DebugActionFrame> frames,
    ColorScheme cs,
  ) {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _TimelinePainter(
          frames: frames,
          totalMs: _totalMs > 0 ? _totalMs : 1,
          activeIndex: _activeStep,
          activeColor: cs.primary,
          errorColor: cs.error,
          baseColor: cs.onSurface.withValues(alpha: 0.15),
          successColor: AppTheme.success.withValues(alpha: 0.7),
        ),
        child: GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final width = box.size.width;
            final tapX = details.localPosition.dx;
            final ratio = (tapX / width).clamp(0.0, 1.0);
            if (frames.any((frame) => frame.isNative)) {
              _stopPlayback();
              _goToStep(
                (ratio * frames.length).floor().clamp(0, frames.length - 1),
              );
              return;
            }
            int cumMs = 0;
            for (var i = 0; i < frames.length; i++) {
              cumMs += frames[i].durationMs;
              if (cumMs / (_totalMs > 0 ? _totalMs : 1) >= ratio) {
                _stopPlayback();
                _goToStep(i);
                return;
              }
            }
            _goToStep(frames.length - 1);
          },
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(
    BuildContext context,
    List<DebugActionFrame> frames,
  ) {
    final canBack = _activeStep > 0;
    final canForward = _activeStep < frames.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: context.tr.debug_replay_step_first,
            icon: const AppIcon.fromMaterial(Icons.skip_previous),
            onPressed: frames.isEmpty
                ? null
                : () {
                    _stopPlayback();
                    _goToStep(0);
                  },
          ),
          IconButton(
            tooltip: context.tr.debug_replay_step_back,
            icon: const AppIcon.fromMaterial(Icons.chevron_left),
            onPressed: canBack
                ? () {
                    _stopPlayback();
                    _goToStep(_activeStep - 1);
                  }
                : null,
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed: frames.isEmpty
                ? null
                : _isPlaying
                ? _stopPlayback
                : _startPlayback,
            icon: AppIcon.fromMaterial(
              _isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            label: Text(
              _isPlaying
                  ? context.tr.debug_replay_pause
                  : context.tr.debug_replay_play,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: context.tr.debug_replay_step_forward,
            icon: const AppIcon.fromMaterial(Icons.chevron_right),
            onPressed: canForward
                ? () {
                    _stopPlayback();
                    _goToStep(_activeStep + 1);
                  }
                : null,
          ),
          IconButton(
            tooltip: context.tr.debug_replay_step_last,
            icon: const AppIcon.fromMaterial(Icons.skip_next),
            onPressed: frames.isEmpty
                ? null
                : () {
                    _stopPlayback();
                    _goToStep(frames.length - 1);
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildOverview(
    BuildContext context,
    DebugReplayRecord replay,
    ColorScheme cs,
  ) {
    return FadeTransition(
      opacity: _stepAnim,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: replay.frames.length,
        itemBuilder: (context, i) {
          final frame = replay.frames[i];
          final barWidth = _totalMs > 0
              ? (frame.durationMs / _totalMs).clamp(0.0, 1.0)
              : 0.0;
          final color = frame.isError ? cs.error : AppTheme.success;
          return InkWell(
            onTap: () => _goToStep(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${i + 1}.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          frame.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${frame.durationMs} ms',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 6,
                            width: constraints.maxWidth,
                            decoration: BoxDecoration(
                              color: cs.onSurface.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          Container(
                            height: 6,
                            width: constraints.maxWidth * barWidth,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameDetail(
    BuildContext context,
    DebugActionFrame frame,
    int index,
    ColorScheme cs,
  ) {
    final statusColor = frame.isError ? cs.error : AppTheme.success;
    final barWidth = _totalMs > 0
        ? (frame.durationMs / _totalMs).clamp(0.0, 1.0)
        : 0.0;

    return FadeTransition(
      opacity: _stepAnim,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  frame.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (frame.isNative) ...[
            Text(
              _nativeDetails(frame),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: statusColor,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // ── Duration bar ──
          Text(
            context.tr.debug_replay_duration_label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: cs.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        Container(
                          height: 10,
                          width: constraints.maxWidth * barWidth,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${frame.durationMs} ms',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.tr.debug_replay_start_offset(frame.startMs),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // ── Result ──
          Text(
            context.tr.debug_replay_result_label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.55),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              frame.result?.isNotEmpty == true
                  ? frame.result!
                  : context.tr.debug_replay_result_empty,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: frame.isError
                    ? cs.error
                    : cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          if (frame.loopIteration != null) ...[
            const SizedBox(height: 20),
            Text(
              context.tr.debug_replay_loop_info(
                (frame.loopDepth ?? 0),
                frame.loopIteration!,
              ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
          // ── Variables diff ──
          if (frame.variablesBefore != null ||
              frame.variablesAfter != null) ...[
            const SizedBox(height: 20),
            _VariablesDiffSection(
              before: frame.variablesBefore ?? const {},
              after: frame.variablesAfter ?? const {},
            ),
          ],
        ],
      ),
    );
  }

  String _formatAbsTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _nativeDetails(DebugActionFrame frame) {
    final meta = frame.nativeMetadata!;
    final tr = context.tr;
    final status = switch (meta['nativeStatus']) {
      'start' => tr.debug_replay_native_start,
      'returned' => tr.debug_replay_native_returned,
      'literal' => tr.debug_replay_native_literal,
      'selected' => tr.debug_replay_native_selected,
      'none' => tr.debug_replay_native_none,
      'handled' => tr.debug_replay_native_handled,
      'error' => tr.debug_replay_native_error,
      'timeout' => tr.debug_replay_native_timeout,
      'stop' => tr.debug_replay_native_stop,
      'truncated' => tr.debug_replay_native_truncated,
      _ => meta['nativeStatus']?.toString() ?? '',
    };
    return [
      'BDFD',
      status,
      if (meta['line'] != null) 'L${meta['line']}:${meta['column'] ?? 1}',
      if (meta['branch'] is int)
        tr.debug_replay_native_branch((meta['branch'] as int) + 1),
      if (meta['scriptDepth'] != null)
        tr.debug_replay_native_script_depth('${meta['scriptDepth']}'),
      if (meta['eventsDropped'] != null)
        tr.debug_replay_native_events_omitted('${meta['eventsDropped']}'),
      if (meta['valueTruncated'] == true)
        tr.debug_replay_native_value_truncated,
    ].join(' · ');
  }
}

// ─── Variables diff widget ───────────────────────────────────────────────────

class _VariablesDiffSection extends StatefulWidget {
  const _VariablesDiffSection({required this.before, required this.after});

  final Map<String, String> before;
  final Map<String, String> after;

  @override
  State<_VariablesDiffSection> createState() => _VariablesDiffSectionState();
}

class _VariablesDiffSectionState extends State<_VariablesDiffSection> {
  bool _expanded = false;

  bool _isPersistenceDebugKey(String key) {
    final lower = key.toLowerCase();
    if (!lower.startsWith('action_')) {
      return false;
    }
    return lower.endsWith('.value') ||
        lower.endsWith('.persisted') ||
        lower.endsWith('.scope') ||
        lower.endsWith('.key');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final allKeys = <String>{
      ...widget.before.keys,
      ...widget.after.keys,
    }.toList()..sort();

    final added = <String>[];
    final modified = <String>[];
    final removed = <String>[];
    final unchanged = <String>[];

    for (final key in allKeys) {
      final inBefore = widget.before.containsKey(key);
      final inAfter = widget.after.containsKey(key);
      if (!inBefore && inAfter) {
        added.add(key);
      } else if (inBefore && !inAfter) {
        removed.add(key);
      } else if (widget.before[key] != widget.after[key]) {
        modified.add(key);
      } else {
        unchanged.add(key);
      }
    }

    final changedCount = added.length + modified.length + removed.length;
    final highlightedKeys = <String>[
      ...added.where(_isPersistenceDebugKey),
      ...modified.where(_isPersistenceDebugKey),
      ...removed.where(_isPersistenceDebugKey),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                AppIcon.fromMaterial(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr.debug_replay_variables_label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(width: 8),
                if (changedCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Text(
                      '$changedCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (highlightedKeys.isNotEmpty) ...[
                  Text(
                    context.tr.debug_persistence_title,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final key in highlightedKeys)
                    _varRow(
                      context,
                      key: key,
                      value: widget.after[key] ?? widget.before[key] ?? '',
                      color: cs.primary,
                      prefix: '*',
                    ),
                  const Divider(height: 12),
                ],
                for (final key in added)
                  _varRow(
                    context,
                    key: key,
                    value: widget.after[key] ?? '',
                    color: AppTheme.success,
                    prefix: '+',
                  ),
                for (final key in modified)
                  _varRow(
                    context,
                    key: key,
                    value: '${widget.before[key]} → ${widget.after[key]}',
                    color: AppTheme.warning,
                    prefix: '~',
                  ),
                for (final key in removed)
                  _varRow(
                    context,
                    key: key,
                    value: widget.before[key] ?? '',
                    color: cs.error,
                    prefix: '−',
                  ),
                if (unchanged.isNotEmpty) ...[
                  if (changedCount > 0) const Divider(height: 12),
                  for (final key in unchanged)
                    _varRow(
                      context,
                      key: key,
                      value: widget.after[key] ?? '',
                      color: cs.onSurface.withValues(alpha: 0.4),
                      prefix: ' ',
                    ),
                ],
                if (allKeys.isEmpty)
                  Text(
                    context.tr.debug_replay_variables_empty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _varRow(
    BuildContext context, {
    required String key,
    required String value,
    required Color color,
    required String prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            prefix,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            key,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom painter for timeline bar ─────────────────────────────────────────

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({
    required this.frames,
    required this.totalMs,
    required this.activeIndex,
    required this.activeColor,
    required this.errorColor,
    required this.baseColor,
    required this.successColor,
  });

  final List<DebugActionFrame> frames;
  final int totalMs;
  final int activeIndex;
  final Color activeColor;
  final Color errorColor;
  final Color baseColor;
  final Color successColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (frames.any((frame) => frame.isNative)) {
      // Native observations are events, with nested durations that overlap.
      // Give each event a position rather than adding inclusive call durations.
      final stepWidth = size.width / frames.length;
      final gap = stepWidth > 4 ? 2.0 : 0.0;
      for (var i = 0; i < frames.length; i++) {
        final color = i == activeIndex
            ? activeColor
            : frames[i].isError
            ? errorColor
            : successColor;
        canvas.drawRect(
          Rect.fromLTWH(
            i * stepWidth,
            size.height * 0.2,
            stepWidth - gap,
            size.height * 0.6,
          ),
          Paint()..color = color,
        );
      }
      return;
    }
    const gapPx = 2.0;
    final totalGaps = (frames.length - 1) * gapPx;
    final availableWidth = size.width - totalGaps;

    double x = 0;
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final frac = frame.durationMs / totalMs;
      final barW = (frac * availableWidth).clamp(4.0, availableWidth);
      final isActive = i == activeIndex;
      final color = isActive
          ? activeColor
          : frame.isError
          ? errorColor
          : successColor;

      final paint = Paint()..color = color;
      final rect = Rect.fromLTWH(x, size.height * 0.2, barW, size.height * 0.6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        paint,
      );
      x += barW + gapPx;
    }
  }

  @override
  bool shouldRepaint(_TimelinePainter old) =>
      old.activeIndex != activeIndex || old.frames != frames;
}
