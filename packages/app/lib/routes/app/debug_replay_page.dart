import 'dart:async';

import 'package:bot_creator/utils/bot.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/utils/premium_capabilities.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/utils/runner_settings.dart';
import 'package:bot_creator/widgets/subscription_page.dart';
import 'package:flutter/material.dart';

// ─── List page ───────────────────────────────────────────────────────────────

class DebugReplayPage extends StatefulWidget {
  const DebugReplayPage({super.key, this.botId});

  final String? botId;

  @override
  State<DebugReplayPage> createState() => _DebugReplayPageState();
}

class _DebugReplayPageState extends State<DebugReplayPage> {
  StreamSubscription<List<DebugReplayRecord>>? _sub;
  Timer? _runnerPollTimer;
  RunnerClient? _runnerClient;
  bool _usingRemoteData = false;

  List<DebugReplayRecord> _replays = const [];
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _capturing = isDebugReplayCapturing;
    _replays = _filtered(debugReplays);
    _sub = debugReplaysStream.listen((all) {
      if (!mounted) return;
      if (_usingRemoteData) return;
      setState(() => _replays = _filtered(all));
    });
    unawaited(_initRunnerPolling());
  }

  Future<void> _initRunnerPolling() async {
    final botId = widget.botId?.trim() ?? '';
    if (botId.isEmpty) {
      return;
    }

    final config = await RunnerSettings.getConfig();
    if (!mounted || config == null) {
      return;
    }

    final client = config.createClient(
      getTimeout: const Duration(seconds: 30),
      postTimeout: const Duration(seconds: 90),
    );
    _runnerClient = client;

    try {
      await _pollRunnerReplays(rethrowErrors: true);
      if (!mounted) return;
      setState(() => _usingRemoteData = true);
      _runnerPollTimer = Timer.periodic(const Duration(milliseconds: 2500), (
        _,
      ) {
        if (mounted) {
          unawaited(_pollRunnerReplays());
        }
      });
    } catch (_) {
      _runnerClient = null;
    }
  }

  Future<void> _pollRunnerReplays({bool rethrowErrors = false}) async {
    final client = _runnerClient;
    final botId = widget.botId?.trim() ?? '';
    if (client == null || botId.isEmpty) {
      return;
    }

    RunnerDebugReplaySnapshot snapshot;
    try {
      snapshot = await client.getDebugReplays(botId, limit: 30);
    } on RunnerClientException {
      if (rethrowErrors) {
        rethrow;
      }
      return;
    } catch (_) {
      if (rethrowErrors) {
        rethrow;
      }
      return;
    }

    if (!mounted) {
      return;
    }

    final remoteReplays = snapshot.replays
        .map(DebugReplayRecord.fromJson)
        .toList(growable: false);
    setState(() {
      _capturing = snapshot.capturing;
      _replays = _filtered(remoteReplays);
    });
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
    final hasCapability = PremiumCapabilities.hasCapability(
      PremiumCapability.visualDebuggerReplay,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.t('debug_replay_title')),
        actions: [
          if (hasCapability) ...[
            IconButton(
              tooltip:
                  _capturing
                      ? AppStrings.t('debug_replay_stop_capture')
                      : AppStrings.t('debug_replay_start_capture'),
              icon: Icon(
                _capturing
                    ? Icons.fiber_manual_record
                    : Icons.fiber_manual_record_outlined,
                color: _capturing ? Colors.red : null,
              ),
              onPressed: () {
                final next = !_capturing;
                setState(() => _capturing = next);
                unawaited(_setCaptureEnabled(next));
              },
            ),
            if (_replays.isNotEmpty)
              IconButton(
                tooltip: AppStrings.t('debug_replay_clear'),
                icon: const Icon(Icons.delete_sweep_outlined),
                onPressed: () async {
                  final confirmed =
                      await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: Text(
                                AppStrings.t('debug_replay_clear_title'),
                              ),
                              content: Text(
                                AppStrings.t('debug_replay_clear_confirm'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: Text(AppStrings.t('cancel')),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: Text(AppStrings.t('delete')),
                                ),
                              ],
                            ),
                      ) ??
                      false;
                  if (!confirmed) return;
                  final client = _runnerClient;
                  final botId = widget.botId?.trim() ?? '';
                  if (_usingRemoteData && client != null && botId.isNotEmpty) {
                    try {
                      await client.clearDebugReplays(botId);
                      if (mounted) {
                        setState(() => _replays = const <DebugReplayRecord>[]);
                      }
                    } catch (_) {}
                    return;
                  }
                  clearDebugReplays();
                },
              ),
          ],
        ],
      ),
      body: SafeArea(
        top: false,
        child:
            hasCapability ? _buildBody(context) : _buildSoftLockedBody(context),
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
                Icon(
                  Icons.play_circle_outline,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStrings.t('debug_replay_premium_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.t('debug_replay_premium_desc'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (PremiumCapabilities.canShowPurchaseUI) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => SubscriptionPage.show(context),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: Text(AppStrings.t('premium_card_button')),
              ),
            ],
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
              Icon(
                Icons.manage_search,
                size: 56,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                _capturing && allowCapture
                    ? AppStrings.t('debug_replay_empty_capturing')
                    : AppStrings.t('debug_replay_empty_idle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              if (!_capturing && allowCapture) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    setState(() => _capturing = true);
                    unawaited(_setCaptureEnabled(true));
                  },
                  icon: const Icon(Icons.fiber_manual_record),
                  label: Text(AppStrings.t('debug_replay_start_capture')),
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
          onTap:
              allowOpenDetail
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
    final client = _runnerClient;
    final botId = widget.botId?.trim() ?? '';
    if (_usingRemoteData && client != null && botId.isNotEmpty) {
      try {
        final remoteState = await client.setDebugReplayCapturing(
          botId,
          enabled,
        );
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

    setDebugReplayCapturing(enabled);
  }
}

class _ReplayListTile extends StatelessWidget {
  const _ReplayListTile({required this.replay, required this.onTap});

  final DebugReplayRecord replay;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = replay.hasError ? colorScheme.error : Colors.green;
    final timeAgo = _formatTimeAgo(replay.triggeredAt);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.15),
        child: Icon(
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
        '${replay.actionCount} action(s) • ${replay.totalMs} ms • $timeAgo',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing:
          onTap != null ? const Icon(Icons.chevron_right, size: 18) : null,
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
            tooltip: AppStrings.t('debug_replay_overview'),
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => _goToStep(-1),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Header summary ──
            _buildHeader(context, replay, colorScheme),
            const Divider(height: 1),
            // ── Timeline bar ──
            if (frames.isNotEmpty) _buildTimeline(context, frames, colorScheme),
            const Divider(height: 1),
            // ── Playback controls ──
            _buildPlaybackControls(context, frames),
            const Divider(height: 1),
            // ── Detail pane ──
            Expanded(
              child:
                  _activeStep < 0
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    DebugReplayRecord replay,
    ColorScheme colorScheme,
  ) {
    final statusColor = replay.hasError ? colorScheme.error : Colors.green;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            replay.hasError ? Icons.error_outline : Icons.check_circle_outline,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${replay.actionCount} action(s) • ${replay.totalMs} ms',
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
          successColor: Colors.green.withValues(alpha: 0.7),
        ),
        child: GestureDetector(
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final width = box.size.width;
            final tapX = details.localPosition.dx;
            final ratio = (tapX / width).clamp(0.0, 1.0);
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
            tooltip: AppStrings.t('debug_replay_step_first'),
            icon: const Icon(Icons.skip_previous),
            onPressed:
                frames.isEmpty
                    ? null
                    : () {
                      _stopPlayback();
                      _goToStep(0);
                    },
          ),
          IconButton(
            tooltip: AppStrings.t('debug_replay_step_back'),
            icon: const Icon(Icons.chevron_left),
            onPressed:
                canBack
                    ? () {
                      _stopPlayback();
                      _goToStep(_activeStep - 1);
                    }
                    : null,
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            onPressed:
                frames.isEmpty
                    ? null
                    : _isPlaying
                    ? _stopPlayback
                    : _startPlayback,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            label: Text(
              _isPlaying
                  ? AppStrings.t('debug_replay_pause')
                  : AppStrings.t('debug_replay_play'),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: AppStrings.t('debug_replay_step_forward'),
            icon: const Icon(Icons.chevron_right),
            onPressed:
                canForward
                    ? () {
                      _stopPlayback();
                      _goToStep(_activeStep + 1);
                    }
                    : null,
          ),
          IconButton(
            tooltip: AppStrings.t('debug_replay_step_last'),
            icon: const Icon(Icons.skip_next),
            onPressed:
                frames.isEmpty
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
          final barWidth =
              _totalMs > 0
                  ? (frame.durationMs / _totalMs).clamp(0.0, 1.0)
                  : 0.0;
          final color = frame.isError ? cs.error : Colors.green;
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
                          _humanizeActionType(frame.actionType),
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
    final statusColor = frame.isError ? cs.error : Colors.green;
    final barWidth =
        _totalMs > 0 ? (frame.durationMs / _totalMs).clamp(0.0, 1.0) : 0.0;

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
                  _humanizeActionType(frame.actionType),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Duration bar ──
          Text(
            AppStrings.t('debug_replay_duration_label'),
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
            AppStrings.tr(
              'debug_replay_start_offset',
              params: {'ms': frame.startMs.toString()},
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          // ── Result ──
          Text(
            AppStrings.t('debug_replay_result_label'),
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
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              frame.result?.isNotEmpty == true
                  ? frame.result!
                  : AppStrings.t('debug_replay_result_empty'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color:
                    frame.isError
                        ? cs.error
                        : cs.onSurface.withValues(alpha: 0.85),
              ),
            ),
          ),
          if (frame.loopIteration != null) ...[
            const SizedBox(height: 20),
            Text(
              AppStrings.tr(
                'debug_replay_loop_info',
                params: {
                  'depth': (frame.loopDepth ?? 0).toString(),
                  'iteration': frame.loopIteration!.toString(),
                },
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

  String _humanizeActionType(String raw) {
    // Insert space before uppercase letters: sendMessage → Send Message
    return raw
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
        .trimLeft()
        .replaceFirstMapped(RegExp(r'^.'), (m) => m.group(0)!.toUpperCase());
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
    final allKeys =
        <String>{...widget.before.keys, ...widget.after.keys}.toList()..sort();

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
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.55),
                ),
                const SizedBox(width: 4),
                Text(
                  AppStrings.t('debug_replay_variables_label'),
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
                      borderRadius: BorderRadius.circular(10),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (highlightedKeys.isNotEmpty) ...[
                  Text(
                    'Persistence debug',
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
                    color: Colors.green,
                    prefix: '+',
                  ),
                for (final key in modified)
                  _varRow(
                    context,
                    key: key,
                    value: '${widget.before[key]} → ${widget.after[key]}',
                    color: Colors.orange,
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
                    AppStrings.t('debug_replay_variables_empty'),
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
    const gapPx = 2.0;
    final totalGaps = (frames.length - 1) * gapPx;
    final availableWidth = size.width - totalGaps;

    double x = 0;
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final frac = frame.durationMs / totalMs;
      final barW = (frac * availableWidth).clamp(4.0, availableWidth);
      final isActive = i == activeIndex;
      final color =
          isActive
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
