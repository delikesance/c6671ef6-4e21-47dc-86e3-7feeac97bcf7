import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../widgets/page_layout.dart';
import '../models/app_emoji.dart';
import 'editor_sub_page_ui.dart';

/// Ce que l'écran des émojis demande à son hôte : lister, téléverser (image en
/// data URI), renommer, supprimer. L'app parle à Discord avec le jeton local ;
/// le Studio passe par le Manager, qui garde le jeton.
abstract class EmojisController {
  const EmojisController();

  Future<List<AppEmoji>> list();
  Future<AppEmoji> create(String name, String imageDataUri);
  Future<AppEmoji> rename(String emojiId, String name);
  Future<void> delete(String emojiId);
}

class EmojisView extends StatefulWidget {
  final EmojisController controller;

  const EmojisView({super.key, required this.controller});

  @override
  State<EmojisView> createState() => _EmojisViewState();
}

class _EmojisViewState extends State<EmojisView> {
  List<AppEmoji> _emojis = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmojis();
  }

  Future<void> _loadEmojis() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final emojis = await widget.controller.list();
      if (!mounted) return;
      setState(() {
        _emojis = emojis;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = context.tr.emojis_loading_error;
        _loading = false;
      });
    }
  }

  Future<void> _showUploadDialog() async {
    final nameController = TextEditingController();
    Uint8List? pickedBytes;
    String? pickedExt;
    String? pickedFileName;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(context.tr.emojis_upload),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: context.tr.emojis_upload_name_hint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const AppIcon.fromMaterial(Icons.image_outlined),
                    label: Text(
                      pickedFileName ?? context.tr.emojis_upload_pick_image,
                    ),
                    onPressed: () async {
                      // Tapping upload twice opens the native picker twice, and
                      // the platform refuses the second one with a
                      // PlatformException(already_active) that used to escape
                      // as an uncaught FATAL error (issue a6c29f9e).
                      final List<PlatformFile> pickedFiles;
                      try {
                        final result = await FilePicker.pickFiles(
                          type: FileType.image,
                          withData: true,
                        );
                        pickedFiles = result?.files ?? const <PlatformFile>[];
                      } on PlatformException catch (error) {
                        if (error.code != 'already_active') {
                          rethrow;
                        }
                        return;
                      }
                      if (pickedFiles.isEmpty) return;
                      final picked = pickedFiles.first;
                      setDialogState(() {
                        pickedBytes = picked.bytes;
                        pickedExt = picked.extension;
                        pickedFileName = picked.name;
                        // Pre-fill name if empty
                        if (nameController.text.isEmpty) {
                          final baseName = picked.name
                              .replaceAll(RegExp(r'\.[^.]+$'), '')
                              .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
                          nameController.text = baseName;
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(context.tr.cancel),
                ),
                FilledButton(
                  onPressed: pickedBytes == null
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty || pickedBytes == null) return;
                          Navigator.of(ctx).pop();
                          await _uploadEmoji(name, pickedBytes!, pickedExt);
                        },
                  child: Text(context.tr.emojis_upload),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadEmoji(String name, Uint8List bytes, String? ext) async {
    try {
      final mime = _mimeForExt((ext ?? '').toLowerCase());
      final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
      final created = await widget.controller.create(name, dataUri);
      if (!mounted) return;
      setState(() {
        _emojis = [..._emojis, created];
      });
    } catch (e) {
      if (!mounted) return;
      _showError(context.tr.emojis_upload_error(e.toString()));
    }
  }

  Future<void> _showRenameDialog(AppEmoji emoji) async {
    final controller = TextEditingController(text: emoji.name);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.emojis_rename_title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.tr.emojis_rename_hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr.emojis_rename_title),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final newName = controller.text.trim();
    if (newName.isEmpty || newName == emoji.name) return;
    try {
      final updated = await widget.controller.rename(emoji.id, newName);
      if (!mounted) return;
      setState(() {
        _emojis = _emojis.map((e) => e.id == emoji.id ? updated : e).toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showError(context.tr.emojis_rename_error(e.toString()));
    }
  }

  Future<void> _confirmDelete(AppEmoji emoji) async {
    final confirmed = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.emojis_delete_confirm_title,
      content: context.tr.emojis_delete_confirm_body(emoji.name),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.controller.delete(emoji.id);
      if (!mounted) return;
      setState(() {
        _emojis = _emojis.where((e) => e.id != emoji.id).toList();
      });
    } catch (e) {
      if (!mounted) return;
      _showError(context.tr.emojis_delete_error(e.toString()));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  String _mimeForExt(String ext) {
    switch (ext) {
      case 'gif':
        return 'image/gif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'image/png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: editorSubPageLeading(context),
        title: Text(context.tr.emojis_title),
        actions: [
          IconButton(
            icon: const AppIcon.fromMaterial(Icons.add_rounded),
            tooltip: context.tr.emojis_upload,
            onPressed: _showUploadDialog,
          ),
          IconButton(
            icon: const AppIcon.fromMaterial(Icons.refresh),
            tooltip: context.tr.common_refresh,
            onPressed: _loadEmojis,
          ),
        ],
      ),
      // Largeur et marges communes à toutes les pages (contrat AppPageLayout).
      body: SafeArea(top: false, child: PageContent(child: _buildBody())),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon.fromMaterial(
              Icons.error_outline,
              size: 48,
              color: AppTheme.error,
            ),
            const SizedBox(height: 12),
            Text(_errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadEmojis,
              child: Text(context.tr.common_retry),
            ),
          ],
        ),
      );
    }

    if (_emojis.isEmpty) {
      return EditorEmptyState(
        icon: Icons.emoji_emotions_outlined,
        title: context.tr.emojis_empty,
        actionLabel: context.tr.emojis_upload,
        onAction: _showUploadDialog,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 160).floor().clamp(2, 6);
        return GridView.builder(
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            AppTheme.spacingMd,
            FloatingGlassNavBar.contentClearanceOf(context) + 24,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppTheme.spacingMd,
            mainAxisSpacing: AppTheme.spacingMd,
            childAspectRatio: 0.9,
          ),
          itemCount: _emojis.length,
          itemBuilder: (context, index) {
            return _EmojiCard(
              emoji: _emojis[index],
              onRename: () => _showRenameDialog(_emojis[index]),
              onDelete: () => _confirmDelete(_emojis[index]),
            );
          },
        );
      },
    );
  }
}

class _EmojiCard extends StatelessWidget {
  final AppEmoji emoji;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _EmojiCard({
    required this.emoji,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Image.network(
                emoji.imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) =>
                    AppIcon.fromMaterial(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: tokens.muted,
                    ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Text(
              ':${emoji.name}:',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          if (emoji.animated)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                context.tr.emojis_animated_label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: tokens.muted,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const AppIcon.fromMaterial(Icons.edit, size: 18),
                tooltip: context.tr.common_edit,
                onPressed: onRename,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const AppIcon.fromMaterial(
                  Icons.delete_outline,
                  size: 18,
                  color: AppTheme.statusErrorText,
                ),
                tooltip: context.tr.common_delete,
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
