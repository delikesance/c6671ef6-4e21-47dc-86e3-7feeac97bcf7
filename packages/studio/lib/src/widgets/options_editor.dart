import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

const _optionTypes = {
  'string': 'Texte',
  'integer': 'Nombre entier',
  'number': 'Nombre décimal',
  'boolean': 'Oui / non',
  'user': 'Utilisateur',
  'channel': 'Salon',
  'role': 'Rôle',
  'mentionable': 'Mentionnable',
  'attachment': 'Fichier',
};

/// Erreur lisible sur une liste d'options, ou `null` si Discord l'acceptera.
String? validateOptions(List<Map<String, dynamic>> options) {
  if (options.length > 25) return '25 options au maximum.';
  final seen = <String>{};
  var optionalSeen = false;
  for (final o in options) {
    final name = '${o['name'] ?? ''}'.trim();
    if (!RegExp(r'^[-_\p{L}\p{N}]{1,32}$', unicode: true).hasMatch(name) ||
        name != name.toLowerCase()) {
      return 'Option « $name » : minuscules, chiffres, « - » et « _ », 32 caractères au plus.';
    }
    if (!seen.add(name)) return 'Option « $name » en double.';
    final d = '${o['description'] ?? ''}'.trim();
    if (d.isEmpty || d.length > 100) {
      return 'Option « $name » : description requise (100 caractères au plus).';
    }
    final required = o['required'] == true;
    if (required && optionalSeen) {
      return 'Les options obligatoires doivent précéder les facultatives (« $name »).';
    }
    if (!required) optionalSeen = true;
  }
  return null;
}

/// Édite les options simples d'une commande (texte, nombre, utilisateur, salon…).
/// Les options à structure (sous-commandes, choix, bornes) ne sont pas modifiées
/// ici : elles sont conservées telles quelles. Rend la nouvelle liste, ou `null`.
Future<List<Map<String, dynamic>>?> showOptionsDialog(
  BuildContext context,
  List<Map<String, dynamic>> options,
) {
  return showDialog<List<Map<String, dynamic>>>(
    context: context,
    builder: (context) => _OptionsDialog(options: options),
  );
}

class _OptRow {
  _OptRow(Map<String, dynamic> raw)
    : raw = Map<String, dynamic>.from(raw),
      type = '${raw['type'] ?? 'string'}',
      required = raw['required'] == true,
      name = TextEditingController(text: '${raw['name'] ?? ''}'),
      description = TextEditingController(text: '${raw['description'] ?? ''}');

  final Map<String, dynamic> raw;
  String type;
  bool required;
  final TextEditingController name;
  final TextEditingController description;

  bool get simple => _optionTypes.containsKey(type);

  Map<String, dynamic> toJson() => simple
      ? {
          ...raw,
          'type': type,
          'name': name.text.trim(),
          'description': description.text.trim(),
          'required': required,
        }
      : raw;
}

class _OptionsDialog extends StatefulWidget {
  const _OptionsDialog({required this.options});

  final List<Map<String, dynamic>> options;

  @override
  State<_OptionsDialog> createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<_OptionsDialog> {
  late final List<_OptRow> _rows = [for (final o in widget.options) _OptRow(o)];
  String? _error;

  @override
  void dispose() {
    for (final r in _rows) {
      r.name.dispose();
      r.description.dispose();
    }
    super.dispose();
  }

  void _save() {
    final list = [for (final r in _rows) r.toJson()];
    final problem = validateOptions(list);
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(list);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Options de la commande'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Aucune option : la commande s\'utilise sans argument.',
                    style: TextStyle(color: StudioColors.muted),
                  ),
                ),
              for (final row in _rows)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StudioColors.containerLowest,
                    border: Border.all(color: StudioColors.clusterBorder),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: row.simple
                      ? Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: row.name,
                                    decoration: const InputDecoration(
                                      labelText: 'Nom',
                                      isDense: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 170,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: row.type,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      isDense: true,
                                    ),
                                    items: [
                                      for (final e in _optionTypes.entries)
                                        DropdownMenuItem(
                                          value: e.key,
                                          child: Text(e.value),
                                        ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => row.type = v ?? row.type,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Retirer l\'option',
                                  onPressed: () =>
                                      setState(() => _rows.remove(row)),
                                  icon: const AppIcon.fromMaterial(
                                    Icons.close_rounded,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: row.description,
                              maxLength: 100,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                isDense: true,
                              ),
                            ),
                            SwitchListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Obligatoire'),
                              value: row.required,
                              onChanged: (v) =>
                                  setState(() => row.required = v),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${row.raw['name']} (${row.type}) : structure conservée telle quelle.',
                                style: const TextStyle(
                                  color: StudioColors.muted,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Retirer l\'option',
                              onPressed: () =>
                                  setState(() => _rows.remove(row)),
                              icon: const AppIcon.fromMaterial(
                                Icons.close_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(
                    () => _rows.add(
                      _OptRow({
                        'type': 'string',
                        'name': '',
                        'description': '',
                        'required': false,
                      }),
                    ),
                  ),
                  icon: const AppIcon.fromMaterial(Icons.add_rounded, size: 16),
                  label: const Text('Ajouter une option'),
                ),
              ),
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
