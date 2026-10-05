import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../layout.dart';
import 'command_editor_page.dart';

/// Onglet « Commandes » de l'éditeur de bot.
class CommandsPage extends StatefulWidget {
  const CommandsPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<CommandsPage> createState() => _CommandsPageState();
}

class _CommandsPageState extends State<CommandsPage> {
  late Future<List<StudioCommand>> _future = widget.api.listCommands(
    widget.bot.id,
  );
  String _query = '';
  StudioCommand? _editing;

  void _refresh() =>
      setState(() => _future = widget.api.listCommands(widget.bot.id));

  @override
  Widget build(BuildContext context) {
    final editing = _editing;
    if (editing != null) {
      return CommandEditorPage(
        key: ValueKey(editing.id),
        api: widget.api,
        bot: widget.bot,
        command: editing,
        onClose: (reload) {
          setState(() => _editing = null);
          if (reload) _refresh();
        },
      );
    }
    return FutureBuilder<List<StudioCommand>>(
      future: _future,
      builder: (context, snapshot) {
        final commands = snapshot.data ?? const <StudioCommand>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                pagePadding(context),
                12,
                pagePadding(context),
                0,
              ),
              child: Row(
                children: [
                  const Text(
                    'Commandes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  if (snapshot.hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: StudioColors.selected,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${commands.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: StudioColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(child: _body(snapshot, commands)),
          ],
        );
      },
    );
  }

  Widget _body(
    AsyncSnapshot<List<StudioCommand>> snapshot,
    List<StudioCommand> commands,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ErrorNotice(message: '${snapshot.error}', onRetry: _refresh);
    }
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty
        ? commands
        : commands.where((c) => c.name.toLowerCase().contains(q)).toList();
    return SingleChildScrollView(
      padding: pageInsets(context),
      child: PageContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher des commandes...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: StudioColors.inputBorder,
                    ),
                  ),
                ),
              ),
            ),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 48),
                child: Center(
                  child: Text(
                    commands.isEmpty
                        ? "Aucune commande pour l'instant. Créez-en une depuis l'app Bot Creator."
                        : 'Aucune commande ne correspond aux filtres actuels.',
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                ),
              ),
            for (final command in shown) ...[
              _CommandCard(
                command: command,
                onTap: () => setState(() => _editing = command),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommandCard extends StatelessWidget {
  const _CommandCard({required this.command, required this.onTap});

  final StudioCommand command;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const family = StudioColors.actionSoft;
    return Material(
      color: StudioColors.card,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: family.withValues(alpha: 0.14),
                  border: Border.all(color: family.withValues(alpha: 0.32)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  size: 20,
                  color: family,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      command.name,
                      style: const TextStyle(
                        fontFamily: StudioTheme.monoFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (command.trigger.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: StudioColors.selected,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          command.trigger,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: StudioColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
