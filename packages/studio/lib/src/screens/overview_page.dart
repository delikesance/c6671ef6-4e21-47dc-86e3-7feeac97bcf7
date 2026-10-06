import 'dart:async';

import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/studio_api.dart';
import '../editor/studio_bot_config_versions_host.dart';
import '../layout.dart';
import 'bot_actions.dart';

/// Onglet « Accueil » d'un bot : la même page que l'app (identité et actions,
/// hébergement, aperçus des commandes et des workflows, journaux filtrables),
/// composée avec les briques partagées de `bot_creator_ui`.
class OverviewPage extends StatefulWidget {
  const OverviewPage({
    super.key,
    required this.api,
    required this.bot,
    this.onOpenSection,
  });

  final StudioApi api;
  final StudioBot bot;

  /// Ouvre un onglet du bot (`commands`, `flows`) : « Voir tout », « Créer un
  /// workflow ».
  final ValueChanged<String>? onOpenSection;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late StudioBot _bot = widget.bot;
  StudioBotRuntime? _runtime;
  DateTime _runtimeAt = DateTime.now();
  List<StudioCommand> _commands = const [];
  List<StudioWorkflowSummary> _workflows = const [];
  final _logs = ValueNotifier<List<String>>(const []);
  bool _logsLoaded = false;
  String? _logsError;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadLists();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logs.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    // Les aperçus sont un plus : une liste qui ne vient pas laisse l'état vide.
    try {
      final commands = await widget.api.listCommands(_bot.id);
      if (mounted) setState(() => _commands = commands);
    } catch (_) {}
    try {
      final workflows = await widget.api.listWorkflows(_bot.id);
      if (mounted) setState(() => _workflows = workflows);
    } catch (_) {}
  }

  Future<void> _refresh() async {
    final running = await widget.api.isRunning(_bot.id);
    StudioBotRuntime? runtime;
    try {
      runtime = await widget.api.botRuntime(_bot.id);
    } catch (_) {}
    List<String>? logs;
    String? logsError;
    try {
      logs = await widget.api.botLogs(_bot.id);
    } on StudioApiException catch (e) {
      logsError = e.message;
    }
    if (!mounted) return;
    setState(() {
      _bot = _bot.copyWith(running: running);
      if (runtime != null) {
        _runtime = runtime;
        _runtimeAt = DateTime.now();
      }
      if (logs != null) {
        _logs.value = logs;
        _logsLoaded = true;
      }
      _logsError = logsError;
    });
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    try {
      if (_bot.running) {
        await widget.api.stopBot(_bot.id);
      } else {
        await widget.api.startBot(_bot.id, botName: _bot.name);
      }
      await _refresh();
    } catch (e) {
      if (mounted) await explainBotError(context, _bot, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restart() async {
    setState(() => _busy = true);
    try {
      await widget.api.stopBot(_bot.id);
      await widget.api.startBot(_bot.id, botName: _bot.name);
      await _refresh();
    } catch (e) {
      if (mounted) await explainBotError(context, _bot, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _invite() async {
    final url = Uri.parse(
      'https://discord.com/api/oauth2/authorize?client_id=${_bot.id}&scope=bot&permissions=8',
    );
    final opened = await openExternalUrl(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.bot_home_invite_error)));
    }
  }

  Future<void> _copyId() async {
    await Clipboard.setData(ClipboardData(text: _bot.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ID ${_bot.id}'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Même entrée que l'accueil de l'app (« Historique des versions »).
  void _openVersionHistory() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BotConfigVersionsPage(
          botId: _bot.id,
          host: StudioBotConfigVersionsHost(widget.api),
        ),
      ),
    );
  }

  /// Les journaux en pleine page : console étirée, avec le filtre de niveau.
  void _openLogs() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(context.tr.bot_logs_title)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<List<String>>(
              valueListenable: _logs,
              builder: (context, lines, _) => BotHomeConsolePanel(
                lines: lines,
                fillHeight: true,
                showLevelFilter: true,
                emptyHint: _emptyLogsHint(context),
                onOpenLogs: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _emptyLogsHint(BuildContext context) {
    if (_logsError != null) return context.tr.bot_logs_server_read_failed;
    if (_logsLoaded) return context.tr.bot_logs_server_empty;
    return context.tr.bot_logs_empty;
  }

  // ── Hébergement ───────────────────────────────────────────────────────────

  /// Santé de la réserve → variante de pastille (vert / orange / rouge).
  StatusPillVariant _hostingPill(int minutes) {
    const day = 60 * 24;
    if (minutes < day) return StatusPillVariant.error;
    if (minutes < day * 3) return StatusPillVariant.warning;
    return StatusPillVariant.online;
  }

  /// Carte « Hébergement » ; `null` quand le serveur n'a rien dit.
  Widget? _hostingCard(BuildContext context, {required bool wide}) {
    final runtime = _runtime;
    if (runtime == null) return null;
    final tr = context.tr;
    final p = BotHomePalette.of(context);
    final running = _bot.running;
    final unlimited = runtime.premiumFunded;
    final minutes = runtime.freeMinutes ?? 0;
    final expiresAt = runtime.sessionExpiresAt;
    // Échéance du serveur si elle existe ; sinon le solde compté depuis la
    // lecture (une durée qui s'écoule, jamais une date inventée).
    final deadline = running
        ? (expiresAt ??
              (runtime.freeMinutes == null
                  ? null
                  : _runtimeAt.add(Duration(minutes: minutes))))
        : null;

    final overline = unlimited
        ? tr.home_hosting_unlimited_overline
        : running
        ? tr.home_hosting_remaining_overline
        : tr.home_hosting_time_preserved_overline;

    Widget? countdown;
    if (unlimited) {
      countdown = Text(
        tr.home_hosting_unlimited_headline,
        style: TextStyle(
          fontSize: 20,
          height: 26 / 20,
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
      );
    } else if (deadline != null) {
      countdown = BotHomeLiveCountdown(
        deadline: deadline,
        expiredLabel: tr.home_hosting_expired,
        wide: wide,
      );
    } else if (runtime.freeMinutes != null) {
      // Bot arrêté : la réserve attend, rien ne s'écoule.
      final parts = splitHostingDuration(minutes);
      String two(int v) => v.toString().padLeft(2, '0');
      countdown = BotHomeCountdown(
        wide: wide,
        segments: [
          (value: two(parts.months), label: tr.unit_short_month),
          (value: two(parts.days), label: tr.unit_short_day),
          (value: two(parts.hours), label: tr.unit_short_hour),
          (value: two(parts.minutes), label: tr.unit_short_minute),
        ],
      );
    }

    final pill = unlimited
        ? (running ? StatusPillVariant.online : StatusPillVariant.warning)
        : (running ? _hostingPill(minutes) : StatusPillVariant.warning);

    return BotHomePanel(
      title: tr.bot_home_hosting_title,
      wide: wide,
      emphasize: !unlimited && minutes < 120 && running,
      trailing: StatusPill(
        variant: pill,
        label: running
            ? tr.home_hosting_status_active_short
            : tr.home_hosting_status_paused_short,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            overline.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              height: 13 / 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.84,
              color: p.muted,
            ),
          ),
          const SizedBox(height: 12),
          ?countdown,
          if (running && !unlimited && expiresAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                AppIcon.fromMaterial(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: p.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatSessionExpiration(context, expiresAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: wide ? 14 : 13.5,
                      height: 20 / 14,
                      color: p.softText,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!unlimited) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AppIcon.fromMaterial(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: p.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.home_add_time_mobile_only,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: p.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: BotHomeButton(
              variant: BotHomeButtonVariant.ghost,
              icon: Icons.history_rounded,
              label: tr.bot_home_version_history,
              expand: !wide,
              onTap: _openVersionHistory,
            ),
          ),
        ],
      ),
    );
  }

  // ── Commandes et workflows ────────────────────────────────────────────────

  Widget _commandsCard(BuildContext context, {required bool wide}) {
    final tr = context.tr;
    final p = BotHomePalette.of(context);
    final open = widget.onOpenSection;
    return BotHomePanel(
      title: tr.commands_tab,
      wide: wide,
      trailing: _commands.isEmpty || open == null
          ? null
          : BotHomeLinkButton(
              label: tr.bot_home_commands_see_all(_commands.length),
              trailingIcon: Icons.chevron_right_rounded,
              onTap: () => open('commands'),
            ),
      child: _commands.isEmpty
          ? BotHomeEmptyHint(text: tr.commands_empty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final command in _commands.take(4)) ...[
                  BotHomeRow(
                    leading: BlockFamily.messages.pastille(
                      Icons.terminal_rounded,
                      size: 36,
                      iconSize: 18,
                    ),
                    onTap: open == null ? null : () => open('commands'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '/${command.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: botHomeMono(14.5, p.text).copyWith(
                            fontWeight: FontWeight.w700,
                            height: 20 / 14.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        BotHomeChip(
                          label: tr.bot_home_actions_count(
                            _actionCount(command),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  int _actionCount(StudioCommand command) {
    final data = command.card['data'];
    final actions = data is Map ? data['actions'] : null;
    return actions is List ? actions.length : 0;
  }

  Widget _workflowsCard(BuildContext context, {required bool wide}) {
    final tr = context.tr;
    final p = BotHomePalette.of(context);
    final open = widget.onOpenSection;
    return BotHomePanel(
      title: tr.workflows_tab,
      wide: wide,
      footer: open == null
          ? null
          : BotHomeButton(
              variant: BotHomeButtonVariant.secondary,
              icon: Icons.add_rounded,
              label: tr.workflows_create,
              onTap: () => open('flows'),
            ),
      child: _workflows.isEmpty
          ? BotHomeEmptyHint(text: tr.workflows_empty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final workflow in _workflows.take(3)) ...[
                  _workflowRow(context, p, workflow, open),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  Widget _workflowRow(
    BuildContext context,
    BotHomePalette p,
    StudioWorkflowSummary workflow,
    ValueChanged<String>? open,
  ) {
    final tr = context.tr;
    final isEvent = workflow.type == workflowTypeEvent;
    final family = isEvent ? BlockFamily.events : BlockFamily.logic;
    final details = [
      if (isEvent && workflow.event.isNotEmpty) workflow.event,
      tr.bot_home_actions_count(workflow.actionCount),
    ].join(' · ');
    return BotHomeRow(
      leading: family.pastille(
        isEvent ? Icons.bolt_rounded : Icons.account_tree_outlined,
        size: 36,
        iconSize: 18,
      ),
      onTap: open == null ? null : () => open('flows'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (isEvent
                    ? tr.workflows_type_badge_event
                    : tr.workflows_type_badge_general)
                .toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: family.overlineStyle(),
          ),
          Text(
            workflow.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: p.muted),
          ),
        ],
      ),
    );
  }

  // ── Page ──────────────────────────────────────────────────────────────────

  Widget _header(BuildContext context, {required bool wide}) {
    final tr = context.tr;
    final running = _bot.running;
    final starting = _busy;
    final pill = starting
        ? StatusPill.warning(label: tr.bot_home_starting)
        : (running
              ? StatusPill.online(label: tr.home_status_online)
              : StatusPill.stopped(label: tr.home_status_offline));
    final h = wide ? 44.0 : 48.0;
    Widget sized(double width, Widget child) =>
        wide ? SizedBox(width: width, child: child) : child;
    final invite = BotHomeButton(
      variant: wide && running
          ? BotHomeButtonVariant.primary
          : BotHomeButtonVariant.secondary,
      icon: Icons.person_add_alt_1_rounded,
      label: tr.bot_home_invite,
      compact: !wide,
      onTap: _invite,
    );
    final restart = BotHomeButton(
      variant: BotHomeButtonVariant.secondary,
      icon: Icons.restart_alt_rounded,
      label: tr.bot_home_restart,
      height: h,
      onTap: (!running || starting) ? null : _restart,
    );
    final toggle = BotHomeButton(
      variant: running
          ? BotHomeButtonVariant.danger
          : BotHomeButtonVariant.online,
      icon: running ? Icons.stop_rounded : Icons.play_arrow_rounded,
      stopSquare: running,
      label: starting
          ? tr.bot_home_starting
          : (running ? tr.home_stop : tr.home_start),
      loading: starting,
      height: h,
      onTap: starting ? null : _toggle,
    );
    return BotHomeIdentityHeader(
      name: _bot.name,
      botId: _bot.id,
      imageUrl: _bot.avatarUrl,
      statusPill: pill,
      sourceLabel: running ? tr.runner_source_manager : null,
      onCopyId: _copyId,
      wide: wide,
      actions: wide
          ? [sized(168, invite), sized(152, restart), sized(132, toggle)]
          : [
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(child: toggle),
                    const SizedBox(width: 8),
                    Expanded(child: restart),
                  ],
                ),
              ),
              SizedBox(width: double.infinity, child: invite),
            ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = !isCompact(context);
    final hosting = _hostingCard(context, wide: wide);
    final commands = _commandsCard(context, wide: wide);
    final workflows = _workflowsCard(context, wide: wide);
    final console = ValueListenableBuilder<List<String>>(
      valueListenable: _logs,
      builder: (context, lines, _) => BotHomeConsolePanel(
        lines: lines,
        showLevelFilter: wide,
        compactLineCount: wide ? 8 : 3,
        emptyHint: _emptyLogsHint(context),
        onOpenLogs: _openLogs,
      ),
    );
    return PageContent(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(top: wide ? 24 : 12, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context, wide: wide),
            SizedBox(height: wide ? 24 : 18),
            if (wide)
              BotHomeCardGrid(children: [?hosting, commands, workflows])
            else ...[
              if (hosting != null) ...[hosting, const SizedBox(height: 14)],
              commands,
              const SizedBox(height: 14),
              workflows,
            ],
            SizedBox(height: wide ? 20 : 14),
            console,
          ],
        ),
      ),
    );
  }
}
