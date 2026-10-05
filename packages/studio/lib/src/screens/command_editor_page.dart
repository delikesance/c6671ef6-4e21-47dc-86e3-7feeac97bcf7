import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../commands/action_catalog.dart';
import '../commands/command_draft.dart';
import '../theme.dart';
import '../widgets/common.dart';

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
  });

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
  bool _changed = false;
  String? _formError;
  final Set<int> _expanded = {};
  final _name = TextEditingController();
  final _description = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
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
      setState(() => _draft = fresh);
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

  Future<void> _delete() async {
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
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
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
                IconButton(
                  tooltip: 'Supprimer la commande',
                  onPressed: _saving ? null : _delete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
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
                      : Icon(
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
    final actions = draft.actions;
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
            _metadataBlock(draft),
            const _Connector(),
            _entryBlock(draft),
            if (actions.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: _EmptyActions(),
              ),
            for (var i = 0; i < actions.length; i++) ...[
              const _Connector(),
              _actionBlock(draft, i, actions[i]),
            ],
            const SizedBox(height: 20),
            const Text(
              "Le contenu des paramètres d'un bloc et l'ajout de blocs se font dans l'app Bot Creator ; le Studio conserve tout le reste de la commande à l'identique.",
              style: TextStyle(
                fontSize: 12,
                color: StudioColors.muted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metadataBlock(CommandDraft draft) {
    const color = Color(0xFF1976D2);
    return _BlockShell(
      icon: Icons.info_outline,
      color: color,
      title: 'Métadonnées',
      badge: 'Requis',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _name,
                onChanged: (v) => setState(() => draft.name = v),
                decoration: const InputDecoration(
                  labelText: 'Nom',
                  prefixIcon: Icon(Icons.tag, size: 18),
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
                  prefixIcon: Icon(Icons.short_text, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _entryBlock(CommandDraft draft) {
    const types = {
      'chatInput': 'Commande slash',
      'user': 'Commande utilisateur',
      'message': 'Commande message',
    };
    final trigger = switch (draft.triggerType) {
      'prefix' => 'Message texte',
      'hybrid' => 'Slash + message texte',
      'none' => 'Aucun',
      _ => types[draft.commandType] ?? 'Commande slash',
    };
    final mode = switch (draft.executionMode) {
      'bdfd_script' => 'Code BDFD',
      'javascript' => 'JavaScript',
      _ => 'Visuel (Blocs)',
    };
    return _BlockShell(
      icon: Icons.play_circle_outline,
      color: BlockFamily.events.color,
      overline: 'ÉVÉNEMENTS',
      title: 'Point de départ (Déclencheur)',
      badge: trigger,
      summary: '/${draft.name}',
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip('Construite en : $mode'),
            if (draft.optionCount > 0)
              _Chip(
                draft.optionCount == 1
                    ? '1 option'
                    : '${draft.optionCount} options',
              ),
          ],
        ),
      ),
    );
  }

  Widget _actionBlock(
    CommandDraft draft,
    int index,
    Map<String, dynamic> action,
  ) {
    final type = '${action['type'] ?? ''}';
    final info = infoFor(type);
    final enabled = action['enabled'] != false;
    final open = _expanded.contains(index);
    final payload = action['payload'] is Map
        ? Map<String, dynamic>.from(action['payload'] as Map)
        : <String, dynamic>{};
    final scalars = payload.entries
        .where(
          (e) => !e.key.startsWith('_') && e.value is! Map && e.value is! List,
        )
        .where((e) => '${e.value}'.trim().isNotEmpty)
        .toList();
    final nested = payload.entries
        .where((e) => e.value is List && (e.value as List).isNotEmpty)
        .map((e) => '${e.key} (${(e.value as List).length})')
        .toList();
    final count = draft.actions.length;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: _BlockShell(
        icon: info.category.icon,
        color: info.category.family.color,
        overline: info.category.label.toUpperCase(),
        title: info.label,
        summary: summarizeAction(action),
        trailing: [
          _IconAction(
            icon: Icons.arrow_upward,
            tooltip: 'Monter',
            onTap: index > 0
                ? () => setState(() => draft.moveAction(index, -1))
                : null,
          ),
          _IconAction(
            icon: Icons.arrow_downward,
            tooltip: 'Descendre',
            onTap: index < count - 1
                ? () => setState(() => draft.moveAction(index, 1))
                : null,
          ),
          _IconAction(
            icon: enabled
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            tooltip: enabled ? 'Désactiver le bloc' : 'Activer le bloc',
            onTap: () => setState(() => draft.toggleAction(index)),
          ),
          _IconAction(
            icon: Icons.delete_outline,
            tooltip: 'Supprimer le bloc',
            onTap: () => setState(() {
              draft.removeAction(index);
              _expanded.clear();
            }),
          ),
          _IconAction(
            icon: open ? Icons.expand_less : Icons.expand_more,
            tooltip: open ? 'Replier' : 'Déplier',
            onTap: () => setState(() {
              open ? _expanded.remove(index) : _expanded.add(index);
            }),
          ),
        ],
        body: open
            ? Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (scalars.isEmpty && nested.isEmpty)
                      const Text(
                        'Aucun paramètre.',
                        style: TextStyle(
                          color: StudioColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    for (final e in scalars)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SelectableText.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${e.key}: ',
                                style: const TextStyle(
                                  color: StudioColors.muted,
                                ),
                              ),
                              TextSpan(text: '${e.value}'),
                            ],
                            style: const TextStyle(
                              fontFamily: StudioTheme.monoFamily,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ),
                    if (nested.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Contient : ${nested.join(', ')}',
                          style: const TextStyle(
                            color: StudioColors.muted,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                  ],
                ),
              )
            : null,
      ),
    );
  }
}

class _BlockShell extends StatelessWidget {
  const _BlockShell({
    required this.icon,
    required this.color,
    required this.title,
    this.overline,
    this.summary,
    this.badge,
    this.trailing = const [],
    this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? overline;
  final String? summary;
  final String? badge;
  final List<Widget> trailing;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    border: Border.all(color: color.withValues(alpha: 0.32)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overline != null)
                        Text(
                          overline!,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: color,
                          ),
                        ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.33,
                            ),
                          ),
                          if (badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.31),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                badge!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (summary != null)
                        Text(
                          summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: StudioTheme.monoFamily,
                            fontSize: 12.5,
                            color: StudioColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                ...trailing,
              ],
            ),
          ),
          ?body,
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onTap,
    iconSize: 18,
    visualDensity: VisualDensity.compact,
    color: StudioColors.muted,
    icon: Icon(icon),
  );
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(width: 2, height: 20, color: StudioColors.cardBorder),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: StudioColors.selected,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: StudioColors.muted,
      ),
    ),
  );
}

class _EmptyActions extends StatelessWidget {
  const _EmptyActions();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: StudioColors.card,
      border: Border.all(color: StudioColors.cardBorder),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Column(
      children: [
        Icon(Icons.touch_app_outlined, size: 32, color: StudioColors.muted),
        SizedBox(height: 8),
        Text(
          "Aucune action pour l'instant",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          "Ajoutez un bloc d'action depuis l'app pour définir ce que fait votre commande.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: StudioColors.muted),
        ),
      ],
    ),
  );
}
