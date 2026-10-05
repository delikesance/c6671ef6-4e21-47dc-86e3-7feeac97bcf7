import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../commands/action_catalog.dart';
import '../commands/workflow_draft.dart';
import '../layout.dart';
import '../theme.dart';
import '../widgets/actions_editor.dart';
import '../widgets/common.dart';

/// Onglet « Workflows » : listes d'actions nommées et réutilisables, générales
/// (appelées par des commandes ou d'autres workflows) ou déclenchées par un
/// événement Discord.
class WorkflowsPage extends StatefulWidget {
  const WorkflowsPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<WorkflowsPage> createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends State<WorkflowsPage> {
  late Future<List<StudioWorkflowSummary>> _future = widget.api.listWorkflows(
    widget.bot.id,
  );
  String? _editing;
  WorkflowDraft? _creating;

  void _refresh() =>
      setState(() => _future = widget.api.listWorkflows(widget.bot.id));

  Future<void> _create() async {
    final draft = await showDialog<WorkflowDraft>(
      context: context,
      builder: (context) => const _NewWorkflowDialog(),
    );
    if (draft != null && mounted) setState(() => _creating = draft);
  }

  @override
  Widget build(BuildContext context) {
    final creating = _creating;
    if (creating != null) {
      return WorkflowEditorPage(
        key: ValueKey('new:${creating.name}'),
        api: widget.api,
        bot: widget.bot,
        name: creating.name,
        newDraft: creating,
        onClose: (reload) {
          setState(() => _creating = null);
          if (reload) _refresh();
        },
      );
    }
    final editing = _editing;
    if (editing != null) {
      return WorkflowEditorPage(
        key: ValueKey(editing),
        api: widget.api,
        bot: widget.bot,
        name: editing,
        onClose: (reload) {
          setState(() => _editing = null);
          if (reload) _refresh();
        },
      );
    }
    return FutureBuilder<List<StudioWorkflowSummary>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <StudioWorkflowSummary>[];
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
                    'Workflows',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width < 480)
                    IconButton.filled(
                      tooltip: 'Nouveau workflow',
                      onPressed: _create,
                      icon: const Icon(Icons.add_rounded, size: 18),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _create,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nouveau workflow'),
                    ),
                ],
              ),
            ),
            Expanded(child: _body(snapshot, items)),
          ],
        );
      },
    );
  }

  Widget _body(
    AsyncSnapshot<List<StudioWorkflowSummary>> snapshot,
    List<StudioWorkflowSummary> items,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (snapshot.hasError) {
      return ErrorNotice(message: '${snapshot.error}', onRetry: _refresh);
    }
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "Aucun workflow. Créez-en un pour réutiliser une suite d'actions ou réagir à un événement.",
            textAlign: TextAlign.center,
            style: TextStyle(color: StudioColors.muted),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: pageInsets(context),
      child: PageContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final w in items) ...[
              Material(
                color: StudioColors.card,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: StudioColors.clusterBorder),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => setState(() => _editing = w.name),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_tree_outlined,
                          color: StudioColors.actionSoft,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                children: [
                                  BlockChip(
                                    w.type == 'event' ? 'Événement' : 'Général',
                                  ),
                                  BlockChip(_modeLabel(w.executionMode)),
                                  BlockChip('${w.actionCount} bloc(s)'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

String _modeLabel(String mode) => switch (mode) {
  'bdfd_script' => 'Code BDFD',
  'javascript' => 'JavaScript',
  _ => 'Visuel (Blocs)',
};

class _NewWorkflowDialog extends StatefulWidget {
  const _NewWorkflowDialog();

  @override
  State<_NewWorkflowDialog> createState() => _NewWorkflowDialogState();
}

class _NewWorkflowDialogState extends State<_NewWorkflowDialog> {
  final _name = TextEditingController();
  final _category = TextEditingController(text: 'messages');
  final _event = TextEditingController(text: 'messageCreate');
  String _type = 'general';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _event.dispose();
    super.dispose();
  }

  void _submit() {
    final draft = WorkflowDraft.blank(
      name: _name.text.trim(),
      type: _type,
      category: _category.text.trim().isEmpty
          ? 'messages'
          : _category.text.trim(),
      event: _event.text.trim().isEmpty ? 'messageCreate' : _event.text.trim(),
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
      title: const Text('Nouveau workflow'),
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
                prefixIcon: Icon(Icons.account_tree_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(
                  value: 'general',
                  child: Text('Général (appelé par une commande)'),
                ),
                DropdownMenuItem(
                  value: 'event',
                  child: Text('Événement Discord'),
                ),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'general'),
            ),
            if (_type == 'event') ...[
              const SizedBox(height: 12),
              TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Catégorie'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _event,
                decoration: const InputDecoration(labelText: 'Événement'),
              ),
            ],
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

/// Éditeur d'un workflow : blocs d'actions (visuel) ou lecture du script.
class WorkflowEditorPage extends StatefulWidget {
  const WorkflowEditorPage({
    super.key,
    required this.api,
    required this.bot,
    required this.name,
    required this.onClose,
    this.newDraft,
  });

  final StudioApi api;
  final StudioBot bot;
  final String name;
  final WorkflowDraft? newDraft;
  final ValueChanged<bool> onClose;

  @override
  State<WorkflowEditorPage> createState() => _WorkflowEditorPageState();
}

class _WorkflowEditorPageState extends State<WorkflowEditorPage> {
  WorkflowDraft? _draft;
  Object? _loadError;
  bool _saving = false;
  bool _changed = false;
  bool _isNew = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final fresh = widget.newDraft;
    if (fresh != null) {
      _draft = fresh;
      _isNew = true;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _draft = null;
      _loadError = null;
    });
    try {
      final detail = await widget.api.getWorkflow(widget.bot.id, widget.name);
      if (mounted) {
        setState(
          () => _draft = WorkflowDraft(detail.raw, revision: detail.revision),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final draft = _draft!;
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _formError = problem);
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final raw = draft.toRaw();
      await widget.api.saveWorkflow(widget.bot.id, widget.bot.name, raw);
      if (!mounted) return;
      _changed = true;
      setState(() {
        _draft = WorkflowDraft(raw, revision: draft.revision);
        _isNew = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Workflow enregistré.')));
    } on StudioApiException catch (e) {
      if (mounted) setState(() => _formError = e.message);
    } catch (e) {
      if (mounted) setState(() => _formError = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_isNew) {
      widget.onClose(_changed);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer « ${_draft!.name} » ?'),
        content: const Text(
          'Les commandes qui appellent ce workflow ne trouveront plus rien à exécuter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: StudioColors.errorText),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await widget.api.deleteWorkflow(
        widget.bot.id,
        widget.bot.name,
        _draft!.name,
      );
      if (mounted) widget.onClose(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _formError = e is StudioApiException ? e.message : '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Retour',
                onPressed: () => widget.onClose(_changed),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              Expanded(
                child: Text(
                  draft?.name ?? widget.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (draft != null) ...[
                IconButton(
                  tooltip: 'Supprimer le workflow',
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving || !draft.dirty || !draft.visual
                      ? null
                      : _save,
                  icon: Icon(
                    draft.dirty ? Icons.save_outlined : Icons.check_rounded,
                    size: 16,
                  ),
                  label: Text(draft.dirty ? 'Enregistrer' : 'Enregistré'),
                ),
              ],
            ],
          ),
        ),
        Expanded(child: _body(draft)),
      ],
    );
  }

  Widget _body(WorkflowDraft? draft) {
    if (_loadError != null) {
      return ErrorNotice(message: '$_loadError', onRetry: _load);
    }
    if (draft == null) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      child: PageContent(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_formError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _formError!,
                  style: const TextStyle(color: StudioColors.errorText),
                ),
              ),
            BlockShell(
              icon: Icons.play_circle_outline,
              color: BlockFamily.events.color,
              overline: 'DÉCLENCHEUR',
              title: draft.type == 'event'
                  ? 'Événement Discord'
                  : 'Appelé par une commande ou un workflow',
              badge: _modeLabel(draft.executionMode),
              summary: draft.type == 'event'
                  ? '${draft.eventTrigger['category'] ?? ''} · ${draft.eventTrigger['event'] ?? ''}'
                  : null,
            ),
            if (draft.visual)
              ActionsEditor(host: draft, onChanged: () => setState(() {}))
            else
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Ce workflow est écrit en ${_modeLabel(draft.executionMode)} : le Studio ne modifie que les workflows visuels. Il reste enregistré tel quel.',
                  style: const TextStyle(color: StudioColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
