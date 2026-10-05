import 'dart:async';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'bot_actions.dart';

/// Onglet « Accueil » d'un bot : état, lancement/arrêt et journaux récents.
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
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final logs = _logs;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: PageContent(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _bot.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                StatusPill(running: _bot.running),
                const SizedBox(width: 12),
                _bot.running
                    ? OutlinedButton(
                        onPressed: _busy ? null : _toggle,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          foregroundColor: StudioColors.errorText,
                          side: BorderSide(
                            color: StudioColors.error.withValues(alpha: 0.4),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Arrêter'),
                      )
                    : FilledButton.icon(
                        onPressed: _busy ? null : _toggle,
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Lancer le bot'),
                      ),
              ],
            ),
            const SizedBox(height: 24),
            const Overline('Journaux'),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(minHeight: 120, maxHeight: 420),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StudioColors.containerLowest,
                border: Border.all(color: StudioColors.cardBorder),
                borderRadius: BorderRadius.circular(16),
              ),
              child: logs == null
                  ? Center(
                      child: _logsError != null
                          ? Text(
                              'Journaux indisponibles : $_logsError',
                              style: const TextStyle(color: StudioColors.muted),
                            )
                          : const CircularProgressIndicator(),
                    )
                  : logs.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucun journal pour le moment.',
                        style: TextStyle(color: StudioColors.muted),
                      ),
                    )
                  : SelectionArea(
                      child: ListView.builder(
                        reverse: true,
                        shrinkWrap: true,
                        itemCount: logs.length,
                        itemBuilder: (context, i) => Text(
                          logs[logs.length - 1 - i],
                          style: const TextStyle(
                            fontFamily: StudioTheme.monoFamily,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
