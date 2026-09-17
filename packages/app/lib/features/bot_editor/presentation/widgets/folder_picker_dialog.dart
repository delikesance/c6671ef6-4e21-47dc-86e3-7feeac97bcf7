import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/command_folder_tree.dart';
import 'package:flutter/material.dart';

/// A modern, responsive centered dialog for choosing or creating a destination folder.
class FolderPickerDialog extends StatefulWidget {
  final String title;
  final String currentFolder;
  final CommandFolderTreeResult tree;

  const FolderPickerDialog({
    super.key,
    required this.title,
    required this.currentFolder,
    required this.tree,
  });

  /// Helper to show the dialog and return the chosen folder path (or empty string for root).
  static Future<String?> show({
    required BuildContext context,
    required String title,
    required String currentFolder,
    required CommandFolderTreeResult tree,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => FolderPickerDialog(
        title: title,
        currentFolder: currentFolder,
        tree: tree,
      ),
    );
  }

  @override
  State<FolderPickerDialog> createState() => _FolderPickerDialogState();
}

class _FolderPickerDialogState extends State<FolderPickerDialog> {
  final _newFolderController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _newFolderController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _submitNewFolder() {
    final raw = _newFolderController.text.trim();
    if (raw.isEmpty) return;
    final normalized = normalizeFolderPath(raw);
    if (normalized.isNotEmpty) {
      Navigator.of(context).pop(normalized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flattened = widget.tree.flatten();
    final filtered = _searchFilter.isEmpty
        ? flattened
        : flattened.where((f) {
            return f.displayName.toLowerCase().contains(_searchFilter) ||
                f.fullPath.toLowerCase().contains(_searchFilter);
          }).toList();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.drive_file_move_rounded,
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: context.tr.cancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search filter if there are several folders
            if (flattened.length > 4) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: context.tr.common_search,
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchFilter.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchFilter = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                  onChanged: (val) =>
                      setState(() => _searchFilter = val.trim().toLowerCase()),
                ),
              ),
            ],

            // Folder list
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 6),
                children: [
                  // Root / No folder option
                  ListTile(
                    leading: Icon(
                      Icons.folder_off_outlined,
                      color: widget.currentFolder.isEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      context.tr.commands_no_folder,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: widget.currentFolder.isEmpty
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    trailing: widget.currentFolder.isEmpty
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(context).pop(''),
                  ),
                  if (filtered.isNotEmpty) const Divider(height: 1),
                  for (final item in filtered)
                    ListTile(
                      leading: Icon(
                        widget.currentFolder == item.fullPath
                            ? Icons.folder
                            : Icons.folder_outlined,
                        size: 20,
                        color: widget.currentFolder == item.fullPath
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      title: Text(
                        item.indentedLabel,
                        style: TextStyle(
                          fontWeight: widget.currentFolder == item.fullPath
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: item.depth > 0
                          ? Text(
                              item.fullPath,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      trailing: widget.currentFolder == item.fullPath
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => Navigator.of(context).pop(item.fullPath),
                    ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Inline New Folder creator
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newFolderController,
                      decoration: InputDecoration(
                        hintText: context.tr.commands_new_folder_hint,
                        prefixIcon: const Icon(
                          Icons.create_new_folder_outlined,
                          size: 20,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _submitNewFolder(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _submitNewFolder,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(context.tr.commands_create_folder),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
