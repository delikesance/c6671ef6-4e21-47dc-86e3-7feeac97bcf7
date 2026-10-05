import 'dart:convert';

import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../layout.dart';

/// Valeur saisie -> valeur JSON : `12`, `true`, `{"a":1}` gardent leur type,
/// tout le reste est du texte. Le serveur stocke du JSON ; l'app propose un
/// type explicite, ici on déduit pour rester simple.
Object? parseVariableValue(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '';
  try {
    final decoded = jsonDecode(text);
    if (decoded is num ||
        decoded is bool ||
        decoded is Map ||
        decoded is List) {
      return decoded;
    }
  } catch (_) {}
  return raw;
}

String formatVariableValue(Object? value) =>
    value is String ? value : jsonEncode(value);

/// Onglet « Vars » : variables globales du bot et définitions de variables par
/// serveur, salon, utilisateur ou membre (création, modification, suppression).
class VariablesPage extends StatefulWidget {
  const VariablesPage({super.key, required this.api, required this.bot});

  final StudioApi api;
  final StudioBot bot;

  @override
  State<VariablesPage> createState() => _VariablesPageState();
}

class _VariablesPageState extends State<VariablesPage> {
  late Future<(Map<String, dynamic>, List<StudioScopedDefinition>)> _future =
      _load();

  Future<(Map<String, dynamic>, List<StudioScopedDefinition>)> _load() async {
    final globals = await widget.api.globalVariables(widget.bot.id);
    List<StudioScopedDefinition> defs;
    try {
      defs = await widget.api.scopedDefinitions(widget.bot.id);
    } on StudioApiException {
      defs = const [];
    }
    return (globals, defs);
  }

  void _reload() => setState(() => _future = _load());

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is StudioApiException ? e.message : '$e')),
      );
    }
  }

  Future<void> _edit({String? key, Object? value}) async {
    final keyCtl = TextEditingController(text: key ?? '');
    final valueCtl = TextEditingController(
      text: key == null ? '' : formatVariableValue(value),
    );
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(key == null ? 'Nouvelle variable' : 'Modifier la variable'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: keyCtl,
                decoration: const InputDecoration(labelText: 'Nom'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtl,
                minLines: 1,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Valeur',
                  helperText: 'Nombre, true/false et JSON gardent leur type.',
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
          FilledButton(
            onPressed: () {
              if (keyCtl.text.trim().isEmpty) return;
              Navigator.of(context).pop((keyCtl.text.trim(), valueCtl.text));
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final (newKey, newValue) = result;
    await _run(() async {
      if (key != null && key != newKey) {
        await widget.api.renameGlobalVariable(widget.bot.id, key, newKey);
      }
      await widget.api.setGlobalVariable(
        widget.bot.id,
        newKey,
        parseVariableValue(newValue),
      );
    });
  }

  /// Crée ou modifie la VALEUR PAR DÉFAUT d'une variable à portée. Les valeurs
  /// propres à un serveur ou à un membre ne se touchent pas d'ici.
  Future<void> _editScoped({StudioScopedDefinition? existing}) async {
    final keyCtl = TextEditingController(text: existing?.key ?? '');
    final valueCtl = TextEditingController(
      text: existing?.defaultValue == null
          ? ''
          : formatVariableValue(existing!.defaultValue),
    );
    var scope = existing?.scope.isNotEmpty == true ? existing!.scope : 'user';
    const scopes = {
      'user': 'Utilisateur',
      'guild': 'Serveur',
      'channel': 'Salon',
      'guildMember': 'Membre (par serveur)',
    };
    if (!scopes.containsKey(scope)) scope = 'user';
    final result = await showDialog<(String, String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            existing == null
                ? 'Nouvelle variable à portée'
                : 'Modifier la variable à portée',
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: keyCtl,
                  enabled: existing == null,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: scope,
                  decoration: const InputDecoration(labelText: 'Portée'),
                  items: [
                    for (final e in scopes.entries)
                      DropdownMenuItem(value: e.key, child: Text(e.value)),
                  ],
                  onChanged: existing == null
                      ? (v) => setLocal(() => scope = v ?? scope)
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: valueCtl,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Valeur par défaut',
                    helperText: 'Nombre, true/false et JSON gardent leur type.',
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
            FilledButton(
              onPressed: () {
                if (keyCtl.text.trim().isEmpty) return;
                Navigator.of(
                  context,
                ).pop((keyCtl.text.trim(), scope, valueCtl.text));
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    final (key, chosenScope, value) = result;
    await _run(
      () => widget.api.setScopedDefinition(
        widget.bot.id,
        key: key,
        scope: chosenScope,
        defaultValue: parseVariableValue(value),
      ),
    );
  }

  Future<void> _removeScoped(StudioScopedDefinition d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer « ${d.key} » ?'),
        content: const Text(
          'La définition est retirée ; les valeurs déjà mémorisées ne sont pas effacées.',
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
    await _run(
      () => widget.api.removeScopedDefinition(
        widget.bot.id,
        d.key,
        scope: d.scope,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return ErrorNotice(message: '${snapshot.error}', onRetry: _reload);
        }
        final (globals, defs) = snapshot.data!;
        final keys = globals.keys.toList()..sort();
        return SingleChildScrollView(
          padding: pageInsets(context),
          child: PageContent(
            maxWidth: 860,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Variables',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _edit(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Données mémorisées pour tout le bot.',
                  style: TextStyle(color: StudioColors.muted),
                ),
                const SizedBox(height: 16),
                if (keys.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Aucune variable.',
                        style: TextStyle(color: StudioColors.muted),
                      ),
                    ),
                  ),
                for (final k in keys)
                  _VarRow(
                    name: k,
                    value: formatVariableValue(globals[k]),
                    onEdit: () => _edit(key: k, value: globals[k]),
                    onDelete: () => _run(
                      () => widget.api.removeGlobalVariable(widget.bot.id, k),
                    ),
                  ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    const Expanded(child: Overline('Par serveur, membre…')),
                    TextButton.icon(
                      onPressed: () => _editScoped(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Une définition donne la valeur par défaut ; chaque serveur, salon ou membre garde ensuite sa propre valeur.',
                  style: TextStyle(fontSize: 12, color: StudioColors.muted),
                ),
                const SizedBox(height: 12),
                if (defs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Aucune définition.',
                        style: TextStyle(color: StudioColors.muted),
                      ),
                    ),
                  ),
                for (final d in defs)
                  _VarRow(
                    name: d.key,
                    value:
                        '${d.scope} · ${d.valueType}'
                        '${d.defaultValue == null ? '' : ' · défaut : ${formatVariableValue(d.defaultValue)}'}',
                    onEdit: () => _editScoped(existing: d),
                    onDelete: () => _removeScoped(d),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VarRow extends StatelessWidget {
  const _VarRow({
    required this.name,
    required this.value,
    this.onEdit,
    this.onDelete,
  });

  final String name;
  final String value;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.clusterBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: StudioTheme.monoFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: StudioTheme.monoFamily,
                fontSize: 12.5,
                color: StudioColors.muted,
              ),
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Modifier',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 18),
            ),
        ],
      ),
    );
  }
}
