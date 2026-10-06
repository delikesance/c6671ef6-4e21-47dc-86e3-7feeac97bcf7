import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import 'package:bot_creator_shared/types/workflow_event_definition.dart';
import 'package:bot_creator_shared/utils/event_catalog.dart';

import '../commands/workflow_draft.dart';
import '../editor/studio_editor_host.dart';
import '../l10n_ext.dart';
import '../layout.dart';
import '../theme.dart';
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
                  Text(
                    context.tr.workflows_title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (MediaQuery.sizeOf(context).width < 480)
                    IconButton.filled(
                      tooltip: context.l10n.workflowNew,
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
                      label: Text(context.l10n.workflowNew),
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

  Widget _row(StudioWorkflowSummary w) {
    final isEvent = w.type == 'event';
    final eventLabel = EventCatalog.getEvents()
        .where((e) => e.event == w.event)
        .map((e) => e.label)
        .firstWhere((_) => true, orElse: () => w.event);
    final tr = context.tr;
    return ModuleRowCard(
      family: BlockFamily.events,
      icon: isEvent
          ? Icons.notifications_active_outlined
          : Icons.account_tree_outlined,
      title: w.name,
      titleMono: true,
      summary: isEvent
          ? tr.workflows_event_subtitle(w.actionCount, eventLabel)
          : tr.workflows_subtitle(
              w.actionCount,
              w.entryPoint,
              '${w.argumentCount}',
            ),
      chips: [
        ModuleChip(
          isEvent
              ? tr.workflows_type_badge_event
              : tr.workflows_type_badge_general,
        ),
        if (w.executionMode != 'workflow')
          ModuleChip(_modeLabel(tr, w.executionMode)),
        if (w.folder.isNotEmpty) ModuleChip(w.folder),
      ],
      onTap: () => setState(() => _editing = w.name),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.workflowsEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: StudioColors.muted),
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
            for (final w in items) ...[_row(w), const SizedBox(height: 12)],
          ],
        ),
      ),
    );
  }
}

String _modeLabel(AppLocalizations tr, String mode) => switch (mode) {
  'bdfd_script' => tr.scratch_mode_bdfd,
  'javascript' => 'JavaScript',
  _ => tr.scratch_mode_blocks,
};

class _NewWorkflowDialog extends StatefulWidget {
  const _NewWorkflowDialog();

  @override
  State<_NewWorkflowDialog> createState() => _NewWorkflowDialogState();
}

class _NewWorkflowDialogState extends State<_NewWorkflowDialog> {
  final _name = TextEditingController();
  final _events = EventCatalog.getEvents();
  late final _categories = <String>{
    for (final e in _events) e.category,
  }.toList();
  String _category = 'messages';
  String _event = 'messageCreate';
  String _type = 'general';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  List<WorkflowEventDefinition> _eventsIn(String category) => [
    for (final e in _events)
      if (e.category == category) e,
  ];

  void _submit() {
    final draft = WorkflowDraft.blank(
      name: _name.text.trim(),
      type: _type,
      category: _category,
      event: _event,
    );
    final problem = draft.validate();
    if (problem != null) {
      setState(() => _error = problem.text(context));
      return;
    }
    Navigator.of(context).pop(draft);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(context.l10n.workflowNew),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: InputDecoration(
                labelText: context.tr.common_name,
                prefixIcon: const AppIcon.fromMaterial(
                  Icons.account_tree_outlined,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: InputDecoration(labelText: context.tr.common_type),
              items: [
                DropdownMenuItem(
                  value: 'general',
                  child: Text(context.l10n.workflowTypeGeneral),
                ),
                DropdownMenuItem(
                  value: 'event',
                  child: Text(context.tr.scratch_wizard_trigger_event_title),
                ),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'general'),
            ),
            if (_type == 'event') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: context.l10n.workflowCategory,
                ),
                items: [
                  for (final cat in _categories)
                    DropdownMenuItem(
                      value: cat,
                      child: Text(workflowEventCategoryLabel(cat)),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _category = value;
                    _event = _eventsIn(value).first.event;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(_category),
                isExpanded: true,
                initialValue: _event,
                decoration: InputDecoration(
                  labelText: context.tr.workflows_type_badge_event,
                ),
                items: [
                  for (final e in _eventsIn(_category))
                    DropdownMenuItem(
                      value: e.event,
                      child: Text(e.label, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _event = value);
                },
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
          child: Text(context.tr.common_cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(context.tr.create)),
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
  Iterable<String> _globalKeys = const [];
  Iterable<({String scope, String key})> _scoped = const [];

  Future<void> _loadVariables() async {
    try {
      final globals = await widget.api.globalVariables(widget.bot.id);
      final scoped = await widget.api.scopedDefinitions(widget.bot.id);
      if (!mounted) return;
      setState(() {
        _globalKeys = globals.keys;
        _scoped = [for (final d in scoped) (scope: d.scope, key: d.key)];
      });
    } catch (_) {
      // Le catalogue du moteur suffit.
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVariables();
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
      setState(() => _formError = problem.text(context));
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
      ).showSnackBar(SnackBar(content: Text(context.l10n.workflowSaved)));
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
        title: Text(context.l10n.deleteNamedTitle(_draft!.name)),
        content: Text(context.l10n.workflowDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.tr.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              context.tr.common_delete,
              style: const TextStyle(color: StudioColors.errorText),
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
                tooltip: context.tr.common_back,
                onPressed: () => widget.onClose(_changed),
                icon: const AppIcon.fromMaterial(
                  Icons.arrow_back_rounded,
                  size: 20,
                ),
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
                  tooltip: context.tr.workflows_delete_title,
                  onPressed: _saving ? null : _delete,
                  icon: const AppIcon.fromMaterial(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving || !draft.dirty || !draft.visual
                      ? null
                      : _save,
                  icon: AppIcon.fromMaterial(
                    draft.dirty ? Icons.save_outlined : Icons.check_rounded,
                    size: 16,
                  ),
                  label: Text(
                    draft.dirty
                        ? context.tr.common_save
                        : context.l10n.commonSaved,
                  ),
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
    final events = EventCatalog.getEvents();
    final categories = <String>{for (final e in events) e.category}.toList();
    final trigger = draft.eventTrigger;
    final category = '${trigger['category'] ?? categories.first}';
    final eventName = '${trigger['event'] ?? ''}';
    final inCategory = [
      for (final e in events)
        if (e.category == category)
          WorkflowEventItem(
            event: e.event,
            label: e.label,
            description: e.description,
          ),
    ];

    void setTrigger(Map<String, dynamic> next) =>
        setState(() => draft.eventTrigger = {...trigger, ...next});

    final header = WorkflowEntryPointBlock(
      workflowType: draft.type,
      entryPoint: draft.entryPoint,
      onEntryPointChanged: (value) => setState(() => draft.entryPoint = value),
      eventCategories: categories,
      selectedCategory: category,
      onCategoryChanged: (value) {
        final first = [
          for (final e in events)
            if (e.category == value) e.event,
        ];
        setTrigger({
          'category': value,
          'event': first.isEmpty ? '' : first.first,
        });
      },
      eventDefinitions: inCategory,
      selectedEvent: eventName,
      onEventChanged: (value) => setTrigger({'event': value}),
      eventCategoryLabel: workflowEventCategoryLabel,
      customIdFilter: '${trigger['customIdFilter'] ?? ''}',
      onCustomIdFilterChanged: (value) =>
          setTrigger({'customIdFilter': value.trim()}),
      executionMode: draft.executionMode,
    );

    return EditorHostScope(
      host: StudioEditorHost(api: widget.api, bot: widget.bot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_formError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _formError!,
                style: const TextStyle(color: StudioColors.errorText),
              ),
            ),
          Expanded(
            child: draft.visual
                ? ActionSequenceEditor(
                    key: ValueKey('sequence-${draft.name}'),
                    actions: draft.actions,
                    title: draft.name,
                    isWorkflow: true,
                    botId: widget.bot.id,
                    variableSuggestions: _suggestions(draft),
                    onChanged: (list) => setState(() => draft.setActions(list)),
                    leading: [header],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      header,
                      const SizedBox(height: 12),
                      Text(
                        context.l10n.workflowScriptNotice(
                          _modeLabel(context.tr, draft.executionMode),
                        ),
                        style: const TextStyle(color: StudioColors.muted),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<VariableSuggestion> _suggestions(WorkflowDraft draft) =>
      buildVariableSuggestions(
        argumentNames: draft.argumentNames,
        eventName: draft.type == 'event'
            ? '${draft.eventTrigger['event'] ?? ''}'
            : null,
        globalKeys: _globalKeys,
        scoped: _scoped,
      );
}
