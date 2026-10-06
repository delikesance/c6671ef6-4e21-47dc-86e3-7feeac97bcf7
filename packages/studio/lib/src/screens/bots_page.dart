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
import 'create_bot_page.dart';

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
  DateTime _runtimesAt = DateTime.now();
  // Nombre de serveurs par bot : lu une fois par ouverture de la page (un appel
  // Discord par bot, jamais à chaque relecture). Absent = inconnu, ligne masquée.
  final Map<String, List<GuildStackItem>> _guilds = {};
  final Map<String, int> _guildCounts = {};
  final Set<String> _guildRequested = {};
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

  void _loadGuildCounts(List<StudioBot> bots) {
    for (final bot in bots) {
      if (!_guildRequested.add(bot.id)) continue;
      widget.api
          .listDiscordGuilds(bot.id)
          .then((guilds) {
            if (!mounted) return;
            setState(() {
              _guildCounts[bot.id] = guilds.length;
              // Les deux premiers serveurs (par id) font la pile d'avatars.
              final sorted = [...guilds]
                ..sort((a, b) {
                  final x = '${a['id']}', y = '${b['id']}';
                  return x.length != y.length
                      ? x.length.compareTo(y.length)
                      : x.compareTo(y);
                });
              _guilds[bot.id] = [
                for (final g in sorted.take(kMaxGuildStackAvatars))
                  GuildStackItem(
                    id: '${g['id']}',
                    name: g['name'] as String?,
                    iconUrl: (g['icon_url'] as String?)?.isEmpty ?? true
                        ? null
                        : g['icon_url'] as String,
                  ),
              ];
            });
          })
          .catchError((_) {
            // Pas d'accès Discord pour ce bot : la ligne reste masquée.
          });
    }
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
        _runtimesAt = DateTime.now();
        _error = null;
        _loading = false;
      });
      _loadGuildCounts(bots);
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
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CreateBotPage(api: widget.api)),
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
              _EmptyBots(onCreate: _create)
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
                                runtimeAt: _runtimesAt,
                                guildCount: _guildCounts[bot.id],
                                guilds: _guilds[bot.id] ?? const [],
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
///
/// [deadline] : l'instant où le temps tombe à zéro, quand un décompte a un sens
/// (bot en marche). C'est l'échéance du serveur si elle existe, sinon le solde
/// compté à partir de [now] : une durée qui s'écoule, jamais une date affichée.
({String label, String value, String detail, DateTime? deadline})? hostingCopy(
  StudioLocalizations l,
  StudioBot bot,
  StudioBotRuntime? runtime, {
  DateTime? now,
}) {
  if (runtime == null) return null;
  final at = now ?? DateTime.now();
  if (runtime.premiumFunded) {
    return (
      label: l.hostingIncludedTitle,
      value: l.hostingIncludedValue,
      detail: '',
      deadline: null,
    );
  }
  if (bot.running) {
    if (runtime.sessionExpiresAt != null) {
      final left = runtime.sessionExpiresAt!.difference(at);
      return (
        label: l.hostingRemainingTitle,
        value: left.isNegative ? l.hostingExpired : _duration(l, left),
        detail: l.hostingSessionActiveOnline,
        deadline: runtime.sessionExpiresAt,
      );
    }
    final minutes = runtime.freeMinutes;
    return (
      label: l.hostingRemainingTitle,
      value: minutes == null
          ? l.hostingSessionActive
          : _duration(l, Duration(minutes: minutes)),
      detail: l.hostingSessionActiveOnline,
      deadline: minutes == null ? null : at.add(Duration(minutes: minutes)),
    );
  }
  final minutes = runtime.freeMinutes;
  return (
    label: l.hostingPreservedTitle,
    value: minutes != null && minutes > 0
        ? l.hostingReserve(_duration(l, Duration(minutes: minutes)))
        : l.hostingReserveAvailable,
    detail: l.hostingPreservedDetail,
    deadline: null,
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
    this.runtimeAt,
    this.guildCount,
    this.guilds = const [],
    required this.busy,
    required this.onToggle,
    required this.onManage,
  });

  final StudioBot bot;
  final StudioBotRuntime? runtime;

  /// Instant où [runtime] a été lu : le décompte part de là.
  final DateTime? runtimeAt;

  /// Serveurs du bot, quand le Manager a pu les lire (sinon la ligne est masquée).
  final int? guildCount;
  final List<GuildStackItem> guilds;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final hosting = hostingCopy(context.l10n, bot, runtime, now: runtimeAt);
    // La carte de l'app. Le Studio ne connaît pas les serveurs du bot (pas de
    // ligne « actif sur N serveurs ») et calcule lui-même la boîte d'hébergement
    // (session, réserve) ; ni achat ni temps à ajouter ici.
    return HomeBotCard(
      name: bot.name,
      id: bot.id,
      avatar: bot.avatarUrl,
      guildCount: guildCount ?? 0,
      showServers: guildCount != null,
      serverAvatars: guildCount == null
          ? null
          : GuildAvatarStack(guildCount: guildCount!, guilds: guilds),
      isRunning: bot.running,
      canToggle: !busy,
      isTogglingThisBot: busy,
      initiallyExpanded: true,
      onManage: onManage,
      onToggle: onToggle,
      onAddTime: null,
      onLogs: null,
      hostingDeadline: hosting?.deadline,
      showPremiumLabels: false,
      freeMinutes: runtime?.freeMinutes ?? 0,
      hostingOverride: hosting == null
          ? null
          : (
              overline: hosting.label,
              value: hosting.value,
              detail: hosting.detail,
            ),
    );
  }
}

class _EmptyBots extends StatelessWidget {
  const _EmptyBots({required this.onCreate});

  final VoidCallback onCreate;

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
            textAlign: TextAlign.center,
            style: TextStyle(color: StudioColors.muted, fontSize: 13),
          ),
          SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const AppIcon.fromMaterial(Icons.add_rounded, size: 18),
            label: Text(context.l10n.botsCreate),
          ),
        ],
      ),
    ),
  );
}
