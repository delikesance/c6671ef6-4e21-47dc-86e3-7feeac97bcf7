import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../l10n_ext.dart';
import '../platform/event_socket.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../layout.dart';
import 'bot_actions.dart';
import 'create_bot_dialog.dart';

/// Accueil : « Mes bots » (équivalent de `HomePage` de l'app en mode large).
class BotsPage extends StatefulWidget {
  const BotsPage({super.key, required this.api, required this.onOpenBot});

  final StudioApi api;
  final ValueChanged<StudioBot> onOpenBot;

  @override
  State<BotsPage> createState() => _BotsPageState();
}

class _BotsPageState extends State<BotsPage> {
  List<StudioBot>? _bots;
  Object? _error;
  bool _loading = true;
  final Set<String> _busy = {};
  final Map<String, StudioBotRuntime> _runtimes = {};
  Timer? _poll;
  Timer? _debounce;
  Timer? _reconnect;
  EventSocket? _socket;
  bool _live = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _connect();
    // Filet de sécurité : le temps réel pousse les changements ; la relecture
    // périodique sert seule si le canal est indisponible (serveur sans le
    // sous-protocole, proxy qui coupe la connexion…).
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_live) _load(silent: true);
    });
  }

  void _connect() {
    _socket?.close();
    final socket = EventSocket(
      url: widget.api.eventsUrl,
      token: widget.api.freshToken,
      onMessage: () {
        _live = true;
        _attempt = 0;
        // Les événements arrivent en rafale : une seule relecture par salve.
        _debounce?.cancel();
        _debounce = Timer(
          const Duration(milliseconds: 400),
          () => _load(silent: true),
        );
      },
      onClosed: () {
        _live = false;
        if (!mounted) return;
        final delay = Duration(seconds: (5 * (1 << _attempt)).clamp(5, 60));
        _attempt = (_attempt + 1).clamp(0, 4);
        _reconnect?.cancel();
        _reconnect = Timer(delay, () {
          if (mounted) _connect();
        });
      },
    );
    _socket = socket;
    socket.connect();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _debounce?.cancel();
    _reconnect?.cancel();
    _socket?.close();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      var bots = await widget.api.listBots();
      // Serveur sans état dans la liste : repli sur /status, bot par bot.
      bots = await Future.wait([
        for (final b in bots)
          b.stateKnown
              ? Future.value(b)
              : widget.api.isRunning(b.id).then((r) => b.copyWith(running: r)),
      ]);
      final runtimes = <String, StudioBotRuntime>{};
      await Future.wait([
        for (final b in bots)
          widget.api
              .botRuntime(b.id)
              .then((r) => runtimes[b.id] = r)
              .catchError((_) => const StudioBotRuntime()),
      ]);
      if (!mounted) return;
      setState(() {
        _bots = bots;
        _runtimes
          ..clear()
          ..addAll(runtimes);
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || silent) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(StudioBot bot) async {
    setState(() => _busy.add(bot.id));
    try {
      if (bot.running) {
        await widget.api.stopBot(bot.id);
      } else {
        await widget.api.startBot(bot.id, botName: bot.name);
      }
      await _load(silent: true);
    } catch (e) {
      if (!mounted) return;
      await explainBotError(context, bot, e);
    } finally {
      if (mounted) setState(() => _busy.remove(bot.id));
    }
  }

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CreateBotDialog(api: widget.api),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final bots = _bots;
    return SingleChildScrollView(
      padding: pageInsets(context, top: 24),
      child: PageContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Overline(context.l10n.botsOverline),
                      SizedBox(height: 6),
                      Text(
                        context.l10n.botsTitle,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: context.l10n.commonRefresh,
                  onPressed: _load,
                  style: IconButton.styleFrom(
                    fixedSize: const Size(44, 44),
                    backgroundColor: StudioColors.card,
                    side: const BorderSide(color: StudioColors.clusterBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const AppIcon.fromMaterial(
                    Icons.sync_rounded,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _create,
                  icon: const AppIcon.fromMaterial(Icons.add_rounded, size: 18),
                  label: Text(context.l10n.botsCreate),
                ),
              ],
            ),
            const SizedBox(height: 36),
            if (_loading && bots == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && bots == null)
              ErrorNotice(message: '$_error', onRetry: _load)
            else if (bots == null || bots.isEmpty)
              const _EmptyBots()
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Overline(context.l10n.botsTitle),
                      const SizedBox(width: 8),
                      CountChip(bots.length),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = ((constraints.maxWidth + 20) / 380)
                          .floor()
                          .clamp(1, 3);
                      final width =
                          (constraints.maxWidth - 20 * (columns - 1)) / columns;
                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          for (final bot in bots)
                            SizedBox(
                              width: width,
                              child: BotCard(
                                bot: bot,
                                runtime: _runtimes[bot.id],
                                busy: _busy.contains(bot.id),
                                onToggle: () => _toggle(bot),
                                onManage: () => widget.onOpenBot(bot),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Texte de la case « hébergement » (`HostingCardCopy` de l'app). `null` =
/// pas de case.
({String label, String value, String detail})? hostingCopy(
  StudioLocalizations l,
  StudioBot bot,
  StudioBotRuntime? runtime, {
  DateTime? now,
}) {
  if (runtime == null) return null;
  if (runtime.premiumFunded) {
    return (
      label: l.hostingIncludedTitle,
      value: l.hostingIncludedValue,
      detail: '',
    );
  }
  if (bot.running) {
    if (runtime.sessionExpiresAt != null) {
      final left = runtime.sessionExpiresAt!.difference(now ?? DateTime.now());
      return (
        label: l.hostingRemainingTitle,
        value: left.isNegative ? l.hostingExpired : _duration(l, left),
        detail: l.hostingSessionActiveOnline,
      );
    }
    final minutes = runtime.freeMinutes;
    return (
      label: l.hostingRemainingTitle,
      value: minutes == null
          ? l.hostingSessionActive
          : _duration(l, Duration(minutes: minutes)),
      detail: l.hostingSessionActiveOnline,
    );
  }
  final minutes = runtime.freeMinutes;
  return (
    label: l.hostingPreservedTitle,
    value: minutes != null && minutes > 0
        ? l.hostingReserve(_duration(l, Duration(minutes: minutes)))
        : l.hostingReserveAvailable,
    detail: l.hostingPreservedDetail,
  );
}

String _duration(StudioLocalizations l, Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return l.durationHoursMinutes(h, m.toString().padLeft(2, '0'));
  return l.durationMinutes(d.inMinutes);
}

class BotCard extends StatelessWidget {
  const BotCard({
    super.key,
    required this.bot,
    required this.runtime,
    required this.busy,
    required this.onToggle,
    required this.onManage,
  });

  final StudioBot bot;
  final StudioBotRuntime? runtime;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final hosting = hostingCopy(context.l10n, bot, runtime);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudioColors.rail,
        border: Border.all(color: StudioColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: StudioColors.discord,
                  shape: BoxShape.circle,
                ),
                child: const AppIcon.fromMaterial(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  bot.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              StatusPill(
                variant: bot.running
                    ? StatusPillVariant.online
                    : StatusPillVariant.stopped,
                label: bot.running
                    ? context.l10n.statusOnline
                    : context.l10n.statusStopped,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: StudioColors.cardBorder),
          if (hosting != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: StudioColors.card,
                border: Border.all(color: StudioColors.clusterBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Overline(hosting.label),
                  const SizedBox(height: 4),
                  Text(
                    hosting.value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (hosting.detail.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      hosting.detail,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: StudioColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StartStopButton(bot: bot, busy: busy, onTap: onToggle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onManage,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: StudioColors.card,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: StudioColors.clusterBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  icon: const AppIcon.fromMaterial(
                    Icons.tune_rounded,
                    size: 14,
                  ),
                  label: Text(context.l10n.botsManage),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartStopButton extends StatelessWidget {
  const _StartStopButton({
    required this.bot,
    required this.busy,
    required this.onTap,
  });

  final StudioBot bot;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox(
      width: 14,
      height: 14,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    if (bot.running) {
      return OutlinedButton.icon(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: StudioColors.error.withValues(alpha: 0.08),
          foregroundColor: StudioColors.errorText,
          side: BorderSide(color: StudioColors.error.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        icon: busy
            ? spinner
            : Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: StudioColors.errorText,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
        label: Text(context.l10n.botStop),
      );
    }
    return FilledButton.icon(
      onPressed: busy ? null : onTap,
      icon: busy
          ? spinner
          : const AppIcon.fromMaterial(Icons.play_arrow_rounded, size: 16),
      label: Text(context.l10n.botStart),
    );
  }
}

class _EmptyBots extends StatelessWidget {
  const _EmptyBots();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 40),
    child: Center(
      child: Column(
        children: [
          AppIcon.fromMaterial(
            Icons.smart_toy_outlined,
            size: 64,
            color: Color(0x669AA0AF),
          ),
          SizedBox(height: 16),
          Text(
            context.l10n.botsEmptyTitle,
            style: TextStyle(color: StudioColors.muted, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            context.l10n.botsEmptyHint,
            style: TextStyle(color: StudioColors.muted, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}
