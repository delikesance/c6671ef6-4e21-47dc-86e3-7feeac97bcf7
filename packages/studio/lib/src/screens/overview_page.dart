import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../editor/studio_bot_config_versions_host.dart';
import '../l10n_ext.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../layout.dart';
import 'bot_actions.dart';

/// Onglet « Accueil » d'un bot : identité et état, lancement/arrêt, repères
/// (commandes, moteur, identifiant) et journaux récents.
class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> {
  late StudioBot _bot = widget.bot;
  List<String>? _logs;
  String? _logsError;
  int? _commandCount;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _loadCommandCount();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadCommandCount() async {
    try {
      final commands = await widget.api.listCommands(_bot.id);
      if (mounted) setState(() => _commandCount = commands.length);
    } catch (_) {
      // Le repère est un plus : sans lui la tuile affiche « – ».
    }
  }

  Future<void> _refresh() async {
    final running = await widget.api.isRunning(_bot.id);
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
      _logs = logs ?? _logs;
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

  /// Même entrée que l'accueil de l'app (« Historique des versions ») : l'écran
  /// est celui de l'app, branché sur l'API du Manager.
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: pageInsets(context, top: 20),
      child: PageContent(
        maxWidth: 960,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              bot: _bot,
              busy: _busy,
              onToggle: _toggle,
              onHistory: _openVersionHistory,
            ),
            const SizedBox(height: 16),
            _Stats(bot: _bot, commandCount: _commandCount),
            const SizedBox(height: 28),
            _LogsPanel(logs: _logs, error: _logsError, live: _bot.running),
          ],
        ),
      ),
    );
  }
}

/// Carte d'identité : avatar, nom, état, moteur ; les actions à droite (sous le
/// nom sur téléphone).
class _Hero extends StatelessWidget {
  const _Hero({
    required this.bot,
    required this.busy,
    required this.onToggle,
    required this.onHistory,
  });

  final StudioBot bot;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final compact = isCompact(context);
    final identity = Row(
      children: [
        HomeBotAvatar(imageUrl: bot.avatarUrl, size: compact ? 52 : 64),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bot.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 20 : 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              StatusPill(
                variant: bot.running
                    ? StatusPillVariant.online
                    : StatusPillVariant.stopped,
                label: bot.running ? l.statusOnline : l.statusStopped,
              ),
            ],
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        bot.running
            ? OutlinedButton.icon(
                onPressed: busy ? null : onToggle,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: StudioColors.errorText,
                  backgroundColor: StudioColors.error.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: StudioColors.error.withValues(alpha: 0.4),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: StudioColors.errorText,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                label: Text(l.botStop),
              )
            : FilledButton.icon(
                onPressed: busy ? null : onToggle,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                icon: busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon.fromMaterial(
                        Icons.play_arrow_rounded,
                        size: 18,
                      ),
                label: Text(l.botStart),
              ),
        OutlinedButton.icon(
          onPressed: onHistory,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 44),
            foregroundColor: Colors.white,
            backgroundColor: StudioColors.card,
            side: const BorderSide(color: StudioColors.clusterBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const AppIcon.fromMaterial(Icons.history_rounded, size: 16),
          label: Text(context.tr.bot_home_version_history),
        ),
      ],
    );

    return Container(
      padding: EdgeInsets.all(compact ? 16 : 24),
      decoration: BoxDecoration(
        color: StudioColors.rail,
        border: Border.all(color: StudioColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [identity, const SizedBox(height: 16), actions],
            )
          : Row(
              children: [
                Expanded(child: identity),
                const SizedBox(width: 24),
                actions,
              ],
            ),
    );
  }
}

/// Trois repères : nombre de commandes, moteur d'exécution, identifiant.
class _Stats extends StatelessWidget {
  const _Stats({required this.bot, required this.commandCount});

  final StudioBot bot;
  final int? commandCount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final tiles = [
      _StatTile(
        icon: Icons.terminal_rounded,
        label: l.navCommands,
        value: commandCount == null ? '–' : '$commandCount',
      ),
      _StatTile(
        icon: Icons.memory,
        label: l.overviewEngine,
        value: bot.isJavascript ? 'JavaScript' : 'Dart',
      ),
      _StatTile(
        icon: Icons.tag,
        label: 'ID',
        value: bot.id,
        mono: true,
        selectable: true,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        // Trois colonnes quand ça tient ; sinon une par ligne.
        final columns = constraints.maxWidth >= 640 ? 3 : 1;
        const gap = 12.0;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: width, child: t)],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
    this.selectable = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool mono;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: mono ? 14 : 18,
      fontWeight: FontWeight.w700,
      fontFamily: mono ? StudioTheme.monoFamily : null,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: StudioColors.action.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AppIcon.fromMaterial(
              icon,
              size: 20,
              color: StudioColors.actionSoft,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Overline(label),
                const SizedBox(height: 4),
                selectable
                    ? SelectableText(value, maxLines: 1, style: style)
                    : Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Journaux façon terminal : heure, niveau coloré, message ; les plus récents
/// en bas.
class _LogsPanel extends StatelessWidget {
  const _LogsPanel({
    required this.logs,
    required this.error,
    required this.live,
  });

  final List<String>? logs;
  final String? error;

  /// Le bot tourne : les journaux se rafraîchissent (pastille « En direct »).
  final bool live;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lines = logs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Overline(l.overviewLogs),
            const Spacer(),
            if (live) ...[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: StudioColors.online,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l.overviewLive,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: StudioColors.muted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(minHeight: 120, maxHeight: 460),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: StudioColors.containerLowest,
            border: Border.all(color: StudioColors.cardBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: lines == null
              ? Center(
                  child: error != null
                      ? Text(
                          l.overviewLogsUnavailable(error!),
                          style: const TextStyle(color: StudioColors.muted),
                        )
                      : const CircularProgressIndicator(),
                )
              : lines.isEmpty
              ? Center(
                  child: Text(
                    l.overviewNoLogs,
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                )
              : SelectionArea(
                  child: ListView.builder(
                    reverse: true,
                    shrinkWrap: true,
                    itemCount: lines.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: _LogLine(lines[lines.length - 1 - i]),
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

/// `[2026-10-06T09:14:41.828Z] [INFO] bot:1: message` → heure, niveau, message.
/// Une ligne qui n'a pas ce format est montrée telle quelle.
final _logPattern = RegExp(r'^\[([^\]]+)\]\s+\[(\w+)\]\s+(.*)$', dotAll: true);

class _LogLine extends StatelessWidget {
  const _LogLine(this.raw);

  final String raw;

  static const _base = TextStyle(
    fontFamily: StudioTheme.monoFamily,
    fontSize: 12,
    height: 1.5,
  );

  static Color _levelColor(String level) => switch (level.toUpperCase()) {
    'ERROR' || 'FATAL' || 'SEVERE' => StudioColors.errorText,
    'WARN' || 'WARNING' => StudioColors.premiumGold,
    'DEBUG' || 'TRACE' => StudioColors.muted,
    _ => StudioColors.actionSoft,
  };

  static String _clock(String stamp) {
    final parsed = DateTime.tryParse(stamp)?.toLocal();
    if (parsed == null) return stamp;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(parsed.hour)}:${two(parsed.minute)}:${two(parsed.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final match = _logPattern.firstMatch(raw);
    if (match == null) return Text(raw, style: _base);
    final level = match.group(2)!;
    return Text.rich(
      TextSpan(
        style: _base,
        children: [
          TextSpan(
            text: '${_clock(match.group(1)!)}  ',
            style: const TextStyle(color: StudioColors.muted),
          ),
          TextSpan(
            text: '${level.toUpperCase().padRight(5)}  ',
            style: TextStyle(
              color: _levelColor(level),
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(text: match.group(3)),
        ],
      ),
    );
  }
}
