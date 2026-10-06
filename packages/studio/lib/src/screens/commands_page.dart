import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../editor/studio_editor_host.dart';
import '../l10n_ext.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../layout.dart';
import '../commands/command_draft.dart';
import 'command_editor_page.dart';

/// Onglet « Commandes » de l'éditeur de bot.
class CommandsPage extends StatefulWidget {
  const CommandsPage({
    super.key,
    required this.api,
    required this.bot,
    this.userId,
    this.userName,
  });

  /// Compte connecté (filtre « mes modèles » du marketplace).
  final String? userId;
  final String? userName;

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
  CommandDraft? _creating;

  Future<void> _create() async {
    final draft = await showDialog<CommandDraft>(
      context: context,
      builder: (context) => const _NewCommandDialog(),
    );
    if (draft != null && mounted) setState(() => _creating = draft);
  }

  void _refresh() =>
      setState(() => _future = widget.api.listCommands(widget.bot.id));

  @override
  Widget build(BuildContext context) {
    final creating = _creating;
    if (creating != null) {
      return CommandEditorPage(
        key: ValueKey(creating.id),
        api: widget.api,
        bot: widget.bot,
        command: StudioCommand(id: creating.id, name: creating.name),
        newDraft: creating,
        onClose: (reload) {
          setState(() => _creating = null);
          if (reload) _refresh();
        },
      );
    }
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
                  Text(
                    context.l10n.navCommands,
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
                  const Spacer(),
                  IconButton(
                    tooltip: context.tr.marketplace_title,
                    onPressed: _openMarketplace,
                    icon: const AppIcon.fromMaterial(
                      Icons.auto_awesome_outlined,
                    ),
                  ),
                  if (MediaQuery.sizeOf(context).width < 480)
                    IconButton.filled(
                      tooltip: 'Nouvelle commande',
                      onPressed: _create,
                      icon: const AppIcon.fromMaterial(
                        Icons.add_rounded,
                        size: 18,
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _create,
                      icon: const AppIcon.fromMaterial(
                        Icons.add_rounded,
                        size: 18,
                      ),
                      label: const Text('Nouvelle commande'),
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

  Future<void> _openMarketplace() async {
    final applied = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditorHostScope(
          host: StudioEditorHost(api: widget.api, bot: widget.bot),
          child: MarketplaceView(
            botId: widget.bot.id,
            controller: StudioMarketplaceController(
              api: widget.api,
              bot: widget.bot,
              userId: widget.userId,
              userName: widget.userName,
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) _refresh();
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
                  hintText: context.l10n.commandsSearch,
                  prefixIcon: const AppIcon.fromMaterial(
                    Icons.search,
                    size: 18,
                  ),
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
                        ? context.l10n.commandsEmpty
                        : context.l10n.commandsNoMatch,
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                ),
              ),
            for (final command in shown) ...[
              CommandListCard(
                command: command.card.isEmpty
                    ? {'id': command.id, 'name': command.name}
                    : command.card,
                onOpen: () => setState(() => _editing = command),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nom, description et déclencheur d'une nouvelle commande ; les blocs se
/// construisent ensuite dans l'éditeur.
class _NewCommandDialog extends StatefulWidget {
  const _NewCommandDialog();

  @override
  State<_NewCommandDialog> createState() => _NewCommandDialogState();
}

class _NewCommandDialogState extends State<_NewCommandDialog> {
  final _name = TextEditingController();
  final _description = TextEditingController();
  String _trigger = 'slash';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final draft = CommandDraft.blank(
      name: _name.text.trim(),
      description: _description.text.trim(),
      triggerType: _trigger,
    );
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Nouvelle commande'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nom',
                hintText: 'ping',
                prefixIcon: AppIcon.fromMaterial(Icons.tag, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Description',
                prefixIcon: AppIcon.fromMaterial(Icons.short_text, size: 18),
              ),
            ),
            const SizedBox(height: 4),
            DropdownButtonFormField<String>(
              initialValue: _trigger,
              decoration: const InputDecoration(labelText: 'Déclencheur'),
              items: const [
                DropdownMenuItem(value: 'slash', child: Text('Commande slash')),
                DropdownMenuItem(value: 'prefix', child: Text('Message texte')),
                DropdownMenuItem(
                  value: 'hybrid',
                  child: Text('Slash + message texte'),
                ),
              ],
              onChanged: (v) => setState(() => _trigger = v ?? 'slash'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: StudioColors.errorText),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Créer')),
      ],
    );
  }
}
