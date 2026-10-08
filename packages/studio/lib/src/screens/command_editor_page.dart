import 'dart:convert';

import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:bot_creator_ui/discord.dart' as dc;
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../commands/command_draft.dart';
import '../editor/studio_command_history_host.dart';
import '../editor/studio_editor_host.dart';
import '../editor/studio_sandbox_host.dart';
import '../l10n_ext.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/confirm_discard.dart';
import '../widgets/script_card.dart';
import '../commands/options_validation.dart';

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
  final _folder = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    final fresh = widget.newDraft;
    if (fresh != null) {
      _draft = fresh;
      _isNew = true;
      // Un bot JavaScript n'écrit qu'en JavaScript : pas de blocs à vide.
      if (widget.bot.isJavascript && fresh.executionMode == 'workflow') {
        fresh.executionMode = 'javascript';
      }
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    _folder.dispose();
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

  bool _legacyNotice = false;

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
      // Une commande en blocs ou en BDFD sur un bot JavaScript ne tournait pas
      // (le serveur la retire) : on ouvre l'éditeur JavaScript et on le dit.
      final legacy =
          widget.bot.isJavascript && draft.executionMode != 'javascript';
      if (legacy) draft.executionMode = 'javascript';
      setState(() {
        _draft = draft;
        _legacyNotice = legacy;
      });
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  Future<void> _save() async {
    final draft = _draft!;
    final problem = draft.validate() ?? validateOptions(draft.options);
    if (problem != null) {
      setState(() => _formError = problem.text(context));
      return;
    }
    setState(() {
      _saving = true;
      _formError = null;
    });
    try {
      // Un seul instantané : c'est CE contenu qui part, et c'est lui qu'on marque
      // enregistré. Relire `draft.toRaw()` après l'attente déclarait sauvegardées
      // des modifications faites pendant la requête, qui n'étaient pas parties.
      final sent = draft.toRaw();
      final revision = await widget.api.saveCommand(
        widget.bot.id,
        widget.command.id,
        sent,
        revision: draft.revision,
      );
      if (!mounted) return;
      _changed = true;
      draft.markSaved(sent, revision: revision);
      setState(() {
        _isNew = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.commandSaved)));
    } on StudioApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _formError = e.statusCode == 409
            ? context.l10n.commandChangedElsewhere
            : e.message,
      );
    } catch (e) {
      if (mounted) setState(() => _formError = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _history() async {
    final host = StudioCommandHistoryHost(
      widget.api,
      revision: _draft?.revision,
    );
    await showCommandHistorySheet(
      context,
      botId: widget.bot.id,
      commandId: widget.command.id,
      host: host,
    );
    if (!mounted || !host.restored) return;
    _changed = true;
    await _load();
  }

  /// Teste le BROUILLON (enregistré ou non) dans le bac à sable : les écrans sont
  /// ceux de l'app, la simulation tourne sur le runner du bot. Les variables
  /// à portée du bot servent de définitions, comme dans l'app.
  Future<void> _openSandbox() async {
    final draft = _draft!;
    var definitions = const <Map<String, dynamic>>[];
    try {
      definitions = [
        for (final d in await widget.api.scopedDefinitions(widget.bot.id))
          {
            'key': d.key,
            'scope': d.scope,
            'defaultValue': d.defaultValue,
            'value_type': d.valueType,
          },
      ];
    } catch (_) {
      // Sans définitions la simulation reste possible : seules les variables à
      // portée du bot n'auront pas leur valeur par défaut.
    }
    if (!mounted) return;
    final bdfd = draft.executionMode == 'bdfd_script';
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommandSandboxPage(
          host: StudioSandboxHost(widget.api, botId: widget.bot.id),
          script: bdfd ? draft.bdfdScript : null,
          // Copie profonde : la simulation ne doit jamais toucher le brouillon.
          actions: bdfd
              ? null
              : [
                  for (final a in jsonDecode(jsonEncode(draft.actions)) as List)
                    Map<String, dynamic>.from(a as Map),
                ],
          options: draft.options,
          definitions: definitions,
          bdfdBackend: draft.bdfdBackend,
        ),
      ),
    );
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
        title: Text(context.tr.cmd_delete_confirm(_draft!.name)),
        content: Text(context.l10n.deleteIrreversible),
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
        if (_legacyNotice)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(context.tr.legacy_item_js_notice),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: context.tr.common_back,
                onPressed: () async {
                  if (await confirmDiscardChanges(
                    context,
                    dirty: (_draft?.dirty ?? false) && !_saving,
                  )) {
                    widget.onClose(_changed);
                  }
                },
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
                    tooltip: context.tr.copilot_history_tooltip,
                    onPressed: _saving ? null : _history,
                    icon: const AppIcon.fromMaterial(
                      Icons.history_rounded,
                      size: 20,
                    ),
                  ),
                IconButton(
                  tooltip: context.tr.cmd_delete_tooltip,
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
          // Les commandes JavaScript n'ont pas de simulation (comme dans l'app).
          // Une ligne sous l'en-tête plutôt qu'une icône de plus dans celui-ci :
          // avec l'historique, la suppression et « Enregistrer », il déborde sur
          // un téléphone.
          if (visual || draft.executionMode == 'bdfd_script')
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _saving ? null : _openSandbox,
                  icon: const AppIcon.fromMaterial(
                    Icons.science_outlined,
                    size: 18,
                  ),
                  label: Text(context.tr.sandbox_test_tooltip),
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
                      const SizedBox(height: 8),
                      _entryBlock(draft),
                      const SizedBox(height: 12),
                      _scriptCard(draft),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Script JavaScript ou BDFD de la commande.
  Widget _scriptCard(CommandDraft draft) {
    final bdfd = draft.executionMode == 'bdfd_script';
    return ScriptCard(
      api: widget.api,
      bot: widget.bot,
      title: draft.name,
      code: bdfd ? draft.bdfdScript : draft.jsScript,
      bdfd: bdfd,
      onChanged: (code) => setState(
        () => bdfd ? draft.bdfdScript = code : draft.jsScript = code,
      ),
    );
  }

  Widget _metadataBlock(CommandDraft draft) {
    dc.ApplicationCommandType type() => switch (draft.commandType) {
      'user' => dc.ApplicationCommandType.user,
      'message' => dc.ApplicationCommandType.message,
      _ => dc.ApplicationCommandType.chatInput,
    };
    return MetadataBlock(
      commandName: draft.name,
      commandDescription: draft.description,
      commandType: type(),
      isLegacyCommand: draft.legacyMode,
      localOnlyCommand: draft.legacyMode,
      canEditCommandType: _isNew,
      showDescriptionField: !draft.legacyMode,
      integrationTypes: [
        for (final t in draft.integrationTypes)
          t == 'userInstall'
              ? dc.ApplicationIntegrationType.userInstall
              : dc.ApplicationIntegrationType.guildInstall,
      ],
      contexts: [
        for (final c in draft.contexts)
          switch (c) {
            'botDm' => dc.InteractionContextType.botDm,
            'privateChannel' => dc.InteractionContextType.privateChannel,
            _ => dc.InteractionContextType.guild,
          },
      ],
      onNameChanged: (v) => setState(() => draft.name = v),
      onDescriptionChanged: (v) => setState(() => draft.description = v),
      onCommandTypeChanged: (t) => setState(
        () => draft.commandType = switch (t) {
          dc.ApplicationCommandType.user => 'user',
          dc.ApplicationCommandType.message => 'message',
          _ => 'chatInput',
        },
      ),
      onLegacyCommandChanged: (v) => setState(() => draft.legacyMode = v),
      onLocalOnlyCommandChanged: (_) {},
      onIntegrationTypesChanged: (types) => setState(
        () => draft.integrationTypes = [
          for (final t in types)
            t == dc.ApplicationIntegrationType.userInstall
                ? 'userInstall'
                : 'guildInstall',
        ],
      ),
      onContextsChanged: (contexts) => setState(
        () => draft.contexts = [
          for (final c in contexts)
            if (c == dc.InteractionContextType.botDm)
              'botDm'
            else if (c == dc.InteractionContextType.privateChannel)
              'privateChannel'
            else
              'guild',
        ],
      ),
      defaultMemberPermissions: draft.defaultMemberPermissions,
      onDefaultMemberPermissionsChanged: (v) =>
          setState(() => draft.defaultMemberPermissions = v),
      nameValidator: (value) {
        final name = (value ?? '').trim();
        if (name.isEmpty) return context.tr.validation_command_name_required;
        final issue = draft.legacyMode
            ? validatePrefixCommandNameFormat(name)
            : validateCommandName(type(), name);
        return discordCommandValidationMessage(context, issue, maxLength: 32);
      },
      legacyAliases: draft.legacyAliases,
      onLegacyAliasesChanged: (v) => setState(() => draft.legacyAliases = v),
      options: dc.deserializeCommandOptions(draft.options),
      onOptionsChanged: (list) =>
          setState(() => draft.options = dc.serializeCommandOptions(list)),
      botIdForConfig: widget.bot.id,
      variableSuggestions: _suggestions,
      onFolderChanged: (v) => setState(() => draft.folder = v),
      folderController: _folder,
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
      // Bot Dart : blocs ou BDFD. Bot JavaScript : le script seul. Le
      // JavaScript n'est jamais proposé sur un bot Dart (ni l'inverse).
      showWorkflowMode: !widget.bot.isJavascript,
      showBdfdMode: !widget.bot.isJavascript,
      showJavascriptMode: widget.bot.isJavascript,
      onExecutionModeChanged: widget.bot.isJavascript
          ? null
          : (mode) => setState(() => draft.executionMode = mode),
    );
  }
}
