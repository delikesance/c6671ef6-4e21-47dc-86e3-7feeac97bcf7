import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../commands/action_catalog.dart';
import '../commands/action_list.dart';
import '../theme.dart';

/// Éditeur de blocs d'actions, partagé par les commandes et les workflows :
/// ajout depuis une palette, édition des paramètres, ordre, activation,
/// suppression. Il modifie [host] sur place et appelle [onChanged].
class ActionsEditor extends StatefulWidget {
  const ActionsEditor({super.key, required this.host, required this.onChanged});

  final ActionListHost host;
  final VoidCallback onChanged;

  @override
  State<ActionsEditor> createState() => _ActionsEditorState();
}

class _ActionsEditorState extends State<ActionsEditor> {
  final Set<int> _expanded = {};

  void _changed(VoidCallback mutate) {
    setState(mutate);
    widget.onChanged();
  }

  Future<void> _add() async {
    final type = await showActionPalette(context);
    if (type == null || !mounted) return;
    _changed(() => widget.host.addAction(newAction(type)));
    // Les paramètres d'un bloc neuf se remplissent tout de suite.
    final index = widget.host.actions.length - 1;
    await _edit(index);
  }

  Future<void> _edit(int index) async {
    final action = widget.host.actions[index];
    final payload = action['payload'] is Map
        ? Map<String, dynamic>.from(action['payload'] as Map)
        : <String, dynamic>{};
    final result = await showPayloadDialog(
      context,
      title: infoFor('${action['type']}').label,
      payload: payload,
    );
    if (result == null || !mounted) return;
    _changed(() {
      widget.host.replaceAction(index, {...action, 'payload': result});
    });
  }

  @override
  Widget build(BuildContext context) {
    final actions = widget.host.actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (actions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: _EmptyActions(),
          ),
        for (var i = 0; i < actions.length; i++) ...[
          const BlockConnector(),
          _block(i, actions[i], actions.length),
        ],
        const BlockConnector(),
        Center(
          child: OutlinedButton.icon(
            onPressed: _add,
            icon: const AppIcon.fromMaterial(Icons.add_rounded, size: 18),
            label: const Text('Ajouter une action'),
          ),
        ),
      ],
    );
  }

  Widget _block(int index, Map<String, dynamic> action, int count) {
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
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: BlockShell(
        icon: info.category.icon,
        color: info.category.family.color,
        overline: info.category.label.toUpperCase(),
        title: info.label,
        summary: summarizeAction(action),
        trailing: [
          BlockIconAction(
            icon: Icons.edit_outlined,
            tooltip: 'Modifier les paramètres',
            onTap: () => _edit(index),
          ),
          BlockIconAction(
            icon: Icons.arrow_upward,
            tooltip: 'Monter',
            onTap: index > 0
                ? () => _changed(() => widget.host.moveAction(index, -1))
                : null,
          ),
          BlockIconAction(
            icon: Icons.arrow_downward,
            tooltip: 'Descendre',
            onTap: index < count - 1
                ? () => _changed(() => widget.host.moveAction(index, 1))
                : null,
          ),
          BlockIconAction(
            icon: enabled
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            tooltip: enabled ? 'Désactiver le bloc' : 'Activer le bloc',
            onTap: () => _changed(() => widget.host.toggleAction(index)),
          ),
          BlockIconAction(
            icon: Icons.delete_outline,
            tooltip: 'Supprimer le bloc',
            onTap: () => _changed(() {
              widget.host.removeAction(index);
              _expanded.clear();
            }),
          ),
          BlockIconAction(
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

// ── Palette d'ajout ─────────────────────────────────────────────────────────

/// Choisit un type de bloc : recherche par nom, regroupé par catégorie.
Future<String?> showActionPalette(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _PaletteDialog(),
  );
}

class _PaletteDialog extends StatefulWidget {
  const _PaletteDialog();

  @override
  State<_PaletteDialog> createState() => _PaletteDialogState();
}

class _PaletteDialogState extends State<_PaletteDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final byCategory = <ActionCategory, List<MapEntry<String, ActionInfo>>>{};
    for (final entry in actionCatalog.entries) {
      if (q.isNotEmpty &&
          !entry.value.label.toLowerCase().contains(q) &&
          !entry.key.toLowerCase().contains(q)) {
        continue;
      }
      byCategory.putIfAbsent(entry.value.category, () => []).add(entry);
    }
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Ajouter une action'),
      content: SizedBox(
        width: 520,
        height: 480,
        child: Column(
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Rechercher une action…',
                prefixIcon: AppIcon.fromMaterial(Icons.search, size: 18),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: byCategory.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune action.',
                        style: TextStyle(color: StudioColors.muted),
                      ),
                    )
                  : ListView(
                      children: [
                        for (final category in ActionCategory.values)
                          if (byCategory[category] != null) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
                              child: Row(
                                children: [
                                  AppIcon.fromMaterial(
                                    category.icon,
                                    size: 15,
                                    color: category.family.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    category.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: category.family.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            for (final entry in byCategory[category]!)
                              ListTile(
                                dense: true,
                                title: Text(entry.value.label),
                                subtitle: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontFamily: StudioTheme.monoFamily,
                                    fontSize: 11.5,
                                    color: StudioColors.muted,
                                  ),
                                ),
                                onTap: () =>
                                    Navigator.of(context).pop(entry.key),
                              ),
                          ],
                      ],
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
      ],
    );
  }
}

// ── Édition des paramètres ──────────────────────────────────────────────────

/// Édite la charge utile d'un bloc : champs simples, ou JSON complet pour les
/// structures imbriquées (embeds, conditions, composants). Rend la nouvelle
/// charge, ou `null` si on annule.
Future<Map<String, dynamic>?> showPayloadDialog(
  BuildContext context, {
  required String title,
  required Map<String, dynamic> payload,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _PayloadDialog(title: title, payload: payload),
  );
}

class _Row {
  _Row(this.key, Object? value)
    : isBool = value is bool,
      isNumber = value is num,
      boolValue = value is bool ? value : false,
      key_ = TextEditingController(text: key),
      text = TextEditingController(text: value is bool ? '' : '${value ?? ''}');

  final String key;
  final bool isBool;
  final bool isNumber;
  bool boolValue;
  final TextEditingController key_;
  final TextEditingController text;

  void dispose() {
    key_.dispose();
    text.dispose();
  }
}

/// Valeur saisie pour un paramètre neuf ou modifié : « true » / « false » et les
/// nombres gardent leur type, tout le reste est du texte.
Object? parseParamValue(String raw, {bool? asBool, bool asNumber = false}) {
  if (asBool != null) return asBool;
  final t = raw.trim();
  if (asNumber) return num.tryParse(t) ?? raw;
  if (t == 'true') return true;
  if (t == 'false') return false;
  return raw;
}

class _PayloadDialog extends StatefulWidget {
  const _PayloadDialog({required this.title, required this.payload});

  final String title;
  final Map<String, dynamic> payload;

  @override
  State<_PayloadDialog> createState() => _PayloadDialogState();
}

class _PayloadDialogState extends State<_PayloadDialog> {
  late final List<_Row> _rows;
  late final Map<String, dynamic>
  _structured; // listes et objets, conservés tels quels
  late final TextEditingController _json;
  bool _jsonMode = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rows = [];
    _structured = {};
    for (final e in widget.payload.entries) {
      if (e.value is Map || e.value is List) {
        _structured[e.key] = e.value;
      } else {
        _rows.add(_Row(e.key, e.value));
      }
    }
    _json = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(widget.payload),
    );
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.dispose();
    }
    _json.dispose();
    super.dispose();
  }

  Map<String, dynamic> _fromRows() {
    final out = <String, dynamic>{};
    for (final r in _rows) {
      final k = r.key_.text.trim();
      if (k.isEmpty) continue;
      out[k] = r.isBool
          ? r.boolValue
          : parseParamValue(r.text.text, asNumber: r.isNumber);
    }
    out.addAll(_structured);
    return out;
  }

  void _toggleMode() {
    setState(() {
      _error = null;
      if (!_jsonMode) {
        _json.text = const JsonEncoder.withIndent('  ').convert(_fromRows());
      } else {
        final parsed = _parseJson();
        if (parsed == null) return;
        for (final r in _rows) {
          r.dispose();
        }
        _rows.clear();
        _structured.clear();
        for (final e in parsed.entries) {
          if (e.value is Map || e.value is List) {
            _structured[e.key] = e.value;
          } else {
            _rows.add(_Row(e.key, e.value));
          }
        }
      }
      _jsonMode = !_jsonMode;
    });
  }

  Map<String, dynamic>? _parseJson() {
    try {
      final decoded = jsonDecode(_json.text);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      setState(() => _error = 'Les paramètres doivent former un objet JSON.');
    } catch (e) {
      setState(() => _error = 'JSON invalide : $e');
    }
    return null;
  }

  void _save() {
    if (_jsonMode) {
      final parsed = _parseJson();
      if (parsed != null) Navigator.of(context).pop(parsed);
    } else {
      Navigator.of(context).pop(_fromRows());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Expanded(child: Text(widget.title)),
          TextButton.icon(
            onPressed: _toggleMode,
            icon: AppIcon.fromMaterial(
              _jsonMode ? Icons.tune_rounded : Icons.data_object_rounded,
              size: 16,
            ),
            label: Text(_jsonMode ? 'Champs' : 'JSON'),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_jsonMode)
                TextField(
                  controller: _json,
                  maxLines: 16,
                  minLines: 8,
                  style: const TextStyle(
                    fontFamily: StudioTheme.monoFamily,
                    fontSize: 12.5,
                  ),
                  decoration: const InputDecoration(alignLabelWithHint: true),
                )
              else ...[
                for (final row in _rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: row.key_,
                            decoration: const InputDecoration(
                              labelText: 'Paramètre',
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: row.isBool
                              ? Align(
                                  alignment: Alignment.centerLeft,
                                  child: Switch(
                                    value: row.boolValue,
                                    onChanged: (v) =>
                                        setState(() => row.boolValue = v),
                                  ),
                                )
                              : TextField(
                                  controller: row.text,
                                  minLines: 1,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Valeur',
                                    isDense: true,
                                  ),
                                ),
                        ),
                        IconButton(
                          tooltip: 'Retirer le paramètre',
                          onPressed: () => setState(() {
                            _rows.remove(row);
                            row.dispose();
                          }),
                          icon: const AppIcon.fromMaterial(
                            Icons.close_rounded,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_structured.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Structures conservées : ${_structured.keys.join(', ')} (modifiables en JSON).',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: StudioColors.muted,
                      ),
                    ),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _rows.add(_Row('', ''))),
                    icon: const AppIcon.fromMaterial(
                      Icons.add_rounded,
                      size: 16,
                    ),
                    label: const Text('Ajouter un paramètre'),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: StudioColors.errorText),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _save, child: const Text('Valider')),
      ],
    );
  }
}

// ── Briques d'affichage (partagées avec les éditeurs) ───────────────────────

class BlockShell extends StatelessWidget {
  const BlockShell({
    super.key,
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
                  child: AppIcon.fromMaterial(icon, size: 20, color: color),
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

class BlockIconAction extends StatelessWidget {
  const BlockIconAction({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

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
    icon: AppIcon.fromMaterial(icon),
  );
}

class BlockConnector extends StatelessWidget {
  const BlockConnector({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Container(width: 2, height: 20, color: StudioColors.cardBorder),
  );
}

class BlockChip extends StatelessWidget {
  const BlockChip(this.text, {super.key});

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
        AppIcon.fromMaterial(
          Icons.touch_app_outlined,
          size: 32,
          color: StudioColors.muted,
        ),
        SizedBox(height: 8),
        Text(
          "Aucune action pour l'instant",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          "Ajoutez un bloc d'action pour définir ce que fait ce déclencheur.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: StudioColors.muted),
        ),
      ],
    ),
  );
}
