import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../commands/command_draft.dart';
import '../editor/studio_editor_host.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/options_editor.dart';

/// Éditeur d'une commande : métadonnées, point de départ, blocs d'actions.
///
/// Le Studio modifie le nom, la description, l'ordre, l'activation et la
/// suppression des blocs. Le contenu des paramètres d'un bloc se lit ici et
/// s'édite dans l'app : le reste du JSON est renvoyé tel quel, jamais réécrit.
class CommandEditorPage extends StatefulWidget {
  const CommandEditorPage({
    super.key,
    required this.api,
    required this.bot,
    required this.command,
    required this.onClose,
    this.newDraft,
  });

  /// Commande créée dans le Studio, pas encore connue du serveur.
  final CommandDraft? newDraft;

  final StudioApi api;
  final StudioBot bot;
  final StudioCommand command;

  /// `true` quand la liste doit être rechargée (enregistré ou supprimé).
  final ValueChanged<bool> onClose;

  @override
  State<CommandEditorPage> createState() => _CommandEditorPageState();
}

class _CommandEditorPageState extends State<CommandEditorPage> {
  CommandDraft? _draft;
  Object? _loadError;
  bool _saving = false;
  bool _isNew = false;
  bool _changed = false;
  String? _formError;
  List<VariableSuggestion> _suggestions = buildVariableSuggestions();
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    final fresh = widget.newDraft;
    if (fresh != null) {
      _draft = fresh;
      _name.text = fresh.name;
      _description.text = fresh.description;
      _isNew = true;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final globals = await widget.api.globalVariables(widget.bot.id);
      final scoped = await widget.api.scopedDefinitions(widget.bot.id);
      if (!mounted) return;
      setState(
        () => _suggestions = buildVariableSuggestions(
          globalKeys: globals.keys,
          scoped: [for (final d in scoped) (scope: d.scope, key: d.key)],
        ),
      );
    } catch (_) {
      // Le catalogue intégré suffit : les variables du bot sont un plus.
    }
  }

  Future<void> _load() async {
    setState(() {
      _draft = null;
      _loadError = null;
    });
    try {
      final detail = await widget.api.getCommand(
        widget.bot.id,
        widget.command.id,
      );
      if (!mounted) return;
      final draft = CommandDraft(detail.raw, revision: detail.revision);
      _name.text = draft.name;
      _description.text = draft.description;
      setState(() => _draft = draft);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final draft = _draft!;
    final problem = draft.validate() ?? validateOptions(draft.options);
    if (problem != null) {
      setState(() => _formError = problem);
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      final revision = await widget.api.saveCommand(
        widget.bot.id,
        widget.command.id,
        draft.toRaw(),
        revision: draft.revision,
      );
      if (!mounted) return;
      _changed = true;
      // Repart de l'état enregistré : plus de modification en attente.
      final fresh = CommandDraft(draft.toRaw(), revision: revision);
      setState(() {
        _draft = fresh;
        _isNew = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Commande enregistrée.')));
    } on StudioApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _formError = e.statusCode == 409
            ? 'Ce bot a été modifié ailleurs (app ou autre session). Rechargez la commande avant d\'enregistrer.'
            : e.message,
      );
    } catch (e) {
      if (mounted) setState(() => _formError = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _editOptions(CommandDraft draft) async {
    final result = await showOptionsDialog(context, draft.options);
    if (result != null && mounted) setState(() => draft.options = result);
  }

  Future<void> _history() async {
    final draft = _draft!;
    try {
      final versions = await widget.api.commandHistory(
        widget.bot.id,
        widget.command.id,
      );
      if (!mounted) return;
      final picked = await showDialog<StudioCommandVersion>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Versions précédentes'),
          content: SizedBox(
            width: 420,
            child: versions.isEmpty
                ? const Text(
                    'Aucune version journalisée : l\'historique commence à la prochaine écriture.',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final v in versions)
                        ListTile(
                          dense: true,
                          title: Text(
                            v.createdAt == null
                                ? v.historyId
                                : v.createdAt!
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                          ),
                          subtitle: Text('${v.sizeBytes} octets'),
                          trailing: const AppIcon.fromMaterial(
                            Icons.restore,
                            size: 18,
                          ),
                          onTap: () => Navigator.of(context).pop(v),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      if (picked == null || !mounted) return;
      setState(() => _saving = true);
      await widget.api.restoreCommandVersion(
        widget.bot.id,
        widget.command.id,
        picked.historyId,
        revision: draft.revision,
      );
      if (!mounted) return;
      _changed = true;
      setState(() => _saving = false);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Version restaurée.')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _formError = e is StudioApiException ? e.message : '$e';
        });
      }
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
        title: Text('Supprimer /${_draft!.name} ?'),
        content: const Text('Cette action est définitive.'),
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
      await widget.api.deleteCommand(
        widget.bot.id,
        widget.command.id,
        botName: widget.bot.name,
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
                icon: const AppIcon.fromMaterial(
                  Icons.arrow_back_rounded,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  '/${draft?.name ?? widget.command.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (draft != null) ...[
                if (!_isNew)
                  IconButton(
                    tooltip: 'Historique',
                    onPressed: _saving ? null : _history,
                    icon: const AppIcon.fromMaterial(
                      Icons.history_rounded,
                      size: 20,
                    ),
                  ),
                IconButton(
                  tooltip: 'Supprimer la commande',
                  onPressed: _saving ? null : _delete,
                  icon: const AppIcon.fromMaterial(
                    Icons.delete_outline_rounded,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _saving || !draft.dirty ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : AppIcon.fromMaterial(
                          draft.dirty
                              ? Icons.save_outlined
                              : Icons.check_rounded,
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

  Widget _body(CommandDraft? draft) {
    if (_loadError != null) {
      return ErrorNotice(message: '$_loadError', onRetry: _load);
    }
    if (draft == null) return const Center(child: CircularProgressIndicator());
    final visual = draft.executionMode == 'workflow';
    return EditorHostScope(
      host: StudioEditorHost(api: widget.api, bot: widget.bot),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_formError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudioColors.error.withValues(alpha: 0.08),
                    border: Border.all(
                      color: StudioColors.error.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formError!,
                    style: const TextStyle(color: StudioColors.errorText),
                  ),
                ),
              ),
            ),
          Expanded(
            child: visual
                ? ActionSequenceEditor(
                    key: ValueKey('sequence-${draft.id}'),
                    actions: draft.actions,
                    title: draft.name,
                    isInteraction: !draft.legacyMode,
                    botId: widget.bot.id,
                    variableSuggestions: _suggestions,
                    onChanged: (list) => setState(() => draft.setActions(list)),
                    leading: [_metadataBlock(draft), _entryBlock(draft)],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _metadataBlock(draft),
                      _entryBlock(draft),
                      const SizedBox(height: 12),
                      const Text(
                        "Cette commande est écrite en code (BDFD ou JavaScript) : l'éditeur de code se trouve dans l'app. Le Studio la conserve telle quelle.",
                        style: TextStyle(
                          fontSize: 12.5,
                          color: StudioColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metadataBlock(CommandDraft draft) {
    return ScratchBlock(
      color: AppTheme.info,
      icon: Icons.info_outline,
      title: 'Métadonnées',
      required: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _name,
                onChanged: (v) => setState(() => draft.name = v),
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: AppIcon.fromMaterial(Icons.tag, size: 18),
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 280, maxWidth: 560),
              child: TextField(
                controller: _description,
                maxLength: 100,
                onChanged: (v) => setState(() => draft.description = v),
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: AppIcon.fromMaterial(Icons.short_text, size: 18),
                ),
              ),
            ),
            ActionChip(
              avatar: const AppIcon.fromMaterial(Icons.tune_rounded, size: 14),
              label: Text(
                draft.optionCount == 0
                    ? 'Options'
                    : 'Options (${draft.optionCount})',
              ),
              onPressed: () => _editOptions(draft),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryBlock(CommandDraft draft) {
    return EntryPointBlock(
      commandName: draft.name,
      entryPointType: draft.legacyMode
          ? CommandEntryPointType.message
          : CommandEntryPointType.interaction,
      onEntryPointTypeChanged: (value) => setState(
        () => draft.legacyMode = value == CommandEntryPointType.message,
      ),
      commandType: switch (draft.commandType) {
        'user' => EntryCommandType.user,
        'message' => EntryCommandType.message,
        _ => EntryCommandType.chatInput,
      },
      onCommandTypeChanged: (value) =>
          setState(() => draft.commandType = value.name),
      canEditCommandType: _isNew,
      legacyModeEnabled: draft.legacyMode,
      onLegacyModeChanged: (value) => setState(() => draft.legacyMode = value),
      legacyPrefixOverride: draft.legacyPrefixOverride,
      onLegacyPrefixOverrideChanged: (value) =>
          setState(() => draft.legacyPrefixOverride = value),
      legacyAliases: draft.legacyAliases,
      onLegacyAliasesChanged: (value) =>
          setState(() => draft.legacyAliases = value),
      legacyResponseTarget: draft.legacyResponseTarget,
      onLegacyResponseTargetChanged: (value) =>
          setState(() => draft.legacyResponseTarget = value),
      executionMode: draft.executionMode,
      showBdfdMode: false,
      showJavascriptMode: false,
    );
  }
}
