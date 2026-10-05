import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/block_family.dart';
import '../../widgets/app_icon.dart';
import 'scoped_variables_list.dart' show formatScopedVariableValue;
import 'module_list_widgets.dart';

/// Ligne d'une variable globale (clé, valeur sur une ligne, menu
/// modifier / copier / supprimer).
class GlobalVariableRow extends StatelessWidget {
  const GlobalVariableRow({
    super.key,
    required this.name,
    required this.value,
    required this.onEdit,
    required this.onDelete,
  });

  final String name;
  final Object? value;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final valueText = (value?.toString() ?? 'null').replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    return ModuleRowCard(
      key: ValueKey(name),
      family: BlockFamily.data,
      icon: Icons.data_object_rounded,
      title: name,
      titleMono: true,
      summary: valueText,
      onTap: onEdit,
      trailing: [
        moduleMoreButton<String>(
          context: context,
          tooltip: context.tr.more_options_title,
          itemBuilder: (ctx) => [
            moduleMenuItem<String>(
              ctx,
              value: 'edit',
              icon: Icons.edit_outlined,
              label: context.tr.globals_edit,
            ),
            moduleMenuItem<String>(
              ctx,
              value: 'copy',
              icon: Icons.copy,
              label: context.tr.globals_copy_value,
            ),
            const PopupMenuDivider(),
            moduleMenuItem<String>(
              ctx,
              value: 'delete',
              icon: Icons.delete_outline,
              label: context.tr.delete,
              danger: true,
            ),
          ],
          onSelected: (action) {
            switch (action) {
              case 'edit':
                onEdit();
              case 'copy':
                Clipboard.setData(
                  ClipboardData(text: formatScopedVariableValue(value)),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(context.tr.globals_copy_value)),
                );
              case 'delete':
                onDelete();
            }
          },
        ),
      ],
    );
  }
}

/// Titre de section de l'écran des variables (« Tout le bot », « Par
/// serveur »…).
class VariablesSectionHeader extends StatelessWidget {
  const VariablesSectionHeader({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
    child: Row(
      children: [
        AppIcon.fromMaterial(icon, size: 16, color: BlockFamily.data.color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: BlockFamily.data.overlineStyle(),
          ),
        ),
      ],
    ),
  );
}
