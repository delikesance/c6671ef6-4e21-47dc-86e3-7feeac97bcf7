import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/embed_normalization.dart';
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Types of mini-blocks available for embed editing.
enum _EmbedMiniBlockType {
  title,
  description,
  url,
  color,
  timestamp,
  footer,
  author,
  media,
  fields,
  dynamicFields,
}

class ResponseEmbedsEditor extends StatefulWidget {
  final List<Map<String, dynamic>> embeds;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;
  final int maxEmbeds;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;

  const ResponseEmbedsEditor({
    super.key,
    required this.embeds,
    required this.onChanged,
    this.maxEmbeds = 10,
    this.variableSuggestions = const [],
    this.emojiSuggestions,
  });

  @override
  State<ResponseEmbedsEditor> createState() => _ResponseEmbedsEditorState();
}

class _ResponseEmbedsEditorState extends State<ResponseEmbedsEditor> {
  List<Map<String, dynamic>> _embeds = [];

  /// Tracks which mini-block types are forced visible per embed index,
  /// even when their content is empty (e.g. just added by user).
  final Map<int, Set<_EmbedMiniBlockType>> _expandedBlocks = {};

  // ---------------------------------------------------------------------------
  // Normalization
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _normalizeEmbedsForState(dynamic rawEmbeds) {
    return normalizeResponseEmbedsPayload(
      rawEmbeds,
      maxEmbeds: widget.maxEmbeds,
    ).map((e) => Map<String, dynamic>.from(e)).toList(growable: true);
  }

  Map<String, dynamic> _normalizeEmbed(Map<String, dynamic> embed) =>
      normalizeResponseEmbed(embed);

  // ---------------------------------------------------------------------------
  // Color utilities
  // ---------------------------------------------------------------------------

  Color? _parseEmbedColor(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 6) {
        final parsed = int.tryParse(hex, radix: 16);
        return parsed != null ? Color(0xFF000000 | parsed) : null;
      }
      if (hex.length == 8) {
        final parsed = int.tryParse(hex, radix: 16);
        return parsed != null ? Color(parsed) : null;
      }
      return null;
    }
    final asInt = int.tryParse(value);
    return asInt != null ? Color(0xFF000000 | (asInt & 0x00FFFFFF)) : null;
  }

  String _formatEmbedColorHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _pickEmbedColor(int index) async {
    Color selected =
        _parseEmbedColor((_embeds[index]['color'] ?? '').toString()) ??
        AppTheme.discord;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.embed_color_picker_title),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: selected,
            onColorChanged: (c) => selected = c,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.tr.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(context.tr.common_apply),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      _setEmbedValue(index, 'color', _formatEmbedColorHex(selected));
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _embeds = _normalizeEmbedsForState(widget.embeds);
  }

  @override
  void didUpdateWidget(covariant ResponseEmbedsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embeds != widget.embeds) {
      _embeds = _normalizeEmbedsForState(widget.embeds);
    }
  }

  // ---------------------------------------------------------------------------
  // Embed CRUD
  // ---------------------------------------------------------------------------

  void _emit() {
    widget.onChanged(
      normalizeResponseEmbedsPayload(_embeds, maxEmbeds: widget.maxEmbeds),
    );
  }

  void _addEmbed() {
    if (_embeds.length >= widget.maxEmbeds) return;
    final newIndex = _embeds.length;
    setState(() {
      _embeds.add(_normalizeEmbed(const {}));
      _expandedBlocks[newIndex] = {
        _EmbedMiniBlockType.title,
        _EmbedMiniBlockType.description,
      };
    });
    _emit();
  }

  Future<void> _removeEmbed(int index) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.embed_delete_title,
      content: context.tr.embed_delete_confirm,
      confirmLabel: context.tr.common_delete,
      isDestructive: true,
    );
    if (!shouldDelete) return;
    setState(() {
      _embeds.removeAt(index);
      _expandedBlocks.remove(index);
      final updated = <int, Set<_EmbedMiniBlockType>>{};
      for (final e in _expandedBlocks.entries) {
        updated[e.key > index ? e.key - 1 : e.key] = e.value;
      }
      _expandedBlocks
        ..clear()
        ..addAll(updated);
    });
    _emit();
  }

  void _setEmbedValue(int index, String key, dynamic value) {
    setState(() => _embeds[index][key] = value);
    _emit();
  }

  void _setNestedValue(int index, String key, String nestedKey, dynamic value) {
    setState(() {
      final nested = Map<String, dynamic>.from(_embeds[index][key] ?? {});
      nested[nestedKey] = value;
      _embeds[index][key] = nested;
    });
    _emit();
  }

  void _addField(int index) {
    final fields = List<Map<String, dynamic>>.from(
      _embeds[index]['fields'] ?? [],
    );
    if (fields.length >= 25) return;
    setState(() {
      fields.add({'name': '', 'value': '', 'inline': false});
      _embeds[index]['fields'] = fields;
    });
    _emit();
  }

  Future<void> _removeField(int embedIndex, int fieldIndex) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.embed_field_delete_title,
      content: context.tr.embed_field_delete_confirm,
      confirmLabel: context.tr.common_delete,
      isDestructive: true,
    );
    if (!shouldDelete) return;
    final fields = List<Map<String, dynamic>>.from(
      _embeds[embedIndex]['fields'] ?? [],
    );
    setState(() {
      fields.removeAt(fieldIndex);
      _embeds[embedIndex]['fields'] = fields;
    });
    _emit();
  }

  void _setFieldValue(
    int embedIndex,
    int fieldIndex,
    String key,
    dynamic value,
  ) {
    final fields = List<Map<String, dynamic>>.from(
      _embeds[embedIndex]['fields'] ?? [],
    );
    setState(() {
      fields[fieldIndex][key] = value;
      _embeds[embedIndex]['fields'] = fields;
    });
    _emit();
  }

  // ---------------------------------------------------------------------------
  // Mini-block helpers
  // ---------------------------------------------------------------------------

  bool _blockHasContent(Map<String, dynamic> embed, _EmbedMiniBlockType type) {
    return switch (type) {
      _EmbedMiniBlockType.title =>
        (embed['title']?.toString() ?? '').isNotEmpty,
      _EmbedMiniBlockType.description =>
        (embed['description']?.toString() ?? '').isNotEmpty,
      _EmbedMiniBlockType.url => (embed['url']?.toString() ?? '').isNotEmpty,
      _EmbedMiniBlockType.color =>
        (embed['color']?.toString() ?? '').isNotEmpty,
      _EmbedMiniBlockType.timestamp =>
        (embed['timestamp']?.toString() ?? '').isNotEmpty,
      _EmbedMiniBlockType.footer => _nestedHasContent(embed['footer'], [
        'text',
        'icon_url',
      ]),
      _EmbedMiniBlockType.author => _nestedHasContent(embed['author'], [
        'name',
        'url',
        'icon_url',
      ]),
      _EmbedMiniBlockType.media =>
        _nestedHasContent(embed['image'], ['url']) ||
            _nestedHasContent(embed['thumbnail'], ['url']),
      _EmbedMiniBlockType.fields =>
        (embed['fields'] as List?)?.isNotEmpty == true,
      _EmbedMiniBlockType.dynamicFields =>
        (embed['fieldsTemplate']?.toString() ?? '').isNotEmpty,
    };
  }

  bool _nestedHasContent(dynamic nested, List<String> keys) {
    if (nested is! Map) return false;
    return keys.any((k) => (nested[k]?.toString() ?? '').isNotEmpty);
  }

  bool _isCurrentTimestamp(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'now' || normalized == 'current';
  }

  List<_EmbedMiniBlockType> _visibleBlocks(int index) {
    final embed = _normalizeEmbed(_embeds[index]);
    final forced = _expandedBlocks[index] ?? {};
    return _EmbedMiniBlockType.values
        .where((t) => _blockHasContent(embed, t) || forced.contains(t))
        .toList();
  }

  List<_EmbedMiniBlockType> _availableBlocks(int index) {
    final visible = _visibleBlocks(index).toSet();
    return _EmbedMiniBlockType.values
        .where((t) => !visible.contains(t))
        .toList();
  }

  void _addMiniBlock(int embedIndex, _EmbedMiniBlockType type) {
    setState(() {
      _expandedBlocks.putIfAbsent(embedIndex, () => {}).add(type);
      if (type == _EmbedMiniBlockType.fields) {
        final fields = List<Map<String, dynamic>>.from(
          _embeds[embedIndex]['fields'] ?? [],
        );
        if (fields.isEmpty) {
          fields.add({'name': '', 'value': '', 'inline': false});
          _embeds[embedIndex]['fields'] = fields;
        }
      }
    });
    if (type == _EmbedMiniBlockType.fields) _emit();
  }

  void _removeMiniBlock(int embedIndex, _EmbedMiniBlockType type) {
    setState(() {
      switch (type) {
        case _EmbedMiniBlockType.title:
          _embeds[embedIndex]['title'] = '';
        case _EmbedMiniBlockType.description:
          _embeds[embedIndex]['description'] = '';
        case _EmbedMiniBlockType.url:
          _embeds[embedIndex]['url'] = '';
        case _EmbedMiniBlockType.color:
          _embeds[embedIndex]['color'] = '';
        case _EmbedMiniBlockType.timestamp:
          _embeds[embedIndex]['timestamp'] = '';
        case _EmbedMiniBlockType.footer:
          _embeds[embedIndex]['footer'] = {'text': '', 'icon_url': ''};
        case _EmbedMiniBlockType.author:
          _embeds[embedIndex]['author'] = {
            'name': '',
            'url': '',
            'icon_url': '',
          };
        case _EmbedMiniBlockType.media:
          _embeds[embedIndex]['image'] = {'url': ''};
          _embeds[embedIndex]['thumbnail'] = {'url': ''};
        case _EmbedMiniBlockType.fields:
          _embeds[embedIndex]['fields'] = <Map<String, dynamic>>[];
        case _EmbedMiniBlockType.dynamicFields:
          _embeds[embedIndex]['fieldsTemplate'] = '';
      }
      _expandedBlocks[embedIndex]?.remove(type);
    });
    _emit();
  }

  // ---------------------------------------------------------------------------
  // UI helpers
  // ---------------------------------------------------------------------------

  IconData _iconForType(_EmbedMiniBlockType type) => switch (type) {
    _EmbedMiniBlockType.title => Icons.title,
    _EmbedMiniBlockType.description => Icons.notes,
    _EmbedMiniBlockType.url => Icons.link,
    _EmbedMiniBlockType.color => Icons.palette,
    _EmbedMiniBlockType.timestamp => Icons.schedule,
    _EmbedMiniBlockType.footer => Icons.call_to_action,
    _EmbedMiniBlockType.author => Icons.person,
    _EmbedMiniBlockType.media => Icons.image,
    _EmbedMiniBlockType.fields => Icons.view_list,
    _EmbedMiniBlockType.dynamicFields => Icons.dynamic_feed,
  };

  String _labelForType(_EmbedMiniBlockType type, {int? embedIndex}) {
    return switch (type) {
      _EmbedMiniBlockType.title => context.tr.embed_label_title,
      _EmbedMiniBlockType.description => context.tr.common_description,
      _EmbedMiniBlockType.url => context.tr.embed_label_url,
      _EmbedMiniBlockType.color => context.tr.embed_section_color,
      _EmbedMiniBlockType.timestamp => context.tr.embed_section_timestamp,
      _EmbedMiniBlockType.footer => context.tr.embed_section_footer,
      _EmbedMiniBlockType.author => context.tr.embed_section_author,
      _EmbedMiniBlockType.media => context.tr.embed_section_media,
      _EmbedMiniBlockType.fields when embedIndex != null =>
        context.tr.embed_fields_header(
          List.from(_embeds[embedIndex]['fields'] ?? []).length,
        ),
      _EmbedMiniBlockType.fields => context.tr.embed_section_fields,
      _EmbedMiniBlockType.dynamicFields =>
        context.tr.embed_section_dynamic_fields,
    };
  }

  // ---------------------------------------------------------------------------
  // Build: mini-block container
  // ---------------------------------------------------------------------------

  Widget _buildMiniBlock({
    required _EmbedMiniBlockType type,
    required int embedIndex,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: Row(
              children: [
                AppIcon.fromMaterial(
                  _iconForType(type),
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _labelForType(type, embedIndex: embedIndex),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  onTap: () => _removeMiniBlock(embedIndex, type),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: AppIcon.fromMaterial(
                      Icons.close,
                      size: 16,
                      color: AppTheme.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(10), child: child),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build: mini-block content per type
  // ---------------------------------------------------------------------------

  Widget _buildMiniBlockContent(
    _EmbedMiniBlockType type,
    int index,
    Map<String, dynamic> embed,
  ) {
    switch (type) {
      case _EmbedMiniBlockType.title:
        return VariableTextField(
          label: context.tr.embed_label_title,
          initialValue: embed['title']?.toString() ?? '',
          maxLength: 256,
          suggestions: widget.variableSuggestions,
          emojiSuggestions: widget.emojiSuggestions,
          onChanged: (v) => _setEmbedValue(index, 'title', v),
        );

      case _EmbedMiniBlockType.description:
        return VariableTextField(
          label: context.tr.common_description,
          initialValue: embed['description']?.toString() ?? '',
          maxLength: 2000,
          maxLines: 4,
          suggestions: widget.variableSuggestions,
          emojiSuggestions: widget.emojiSuggestions,
          onChanged: (v) => _setEmbedValue(index, 'description', v),
        );

      case _EmbedMiniBlockType.url:
        return VariableTextField(
          label: context.tr.embed_label_url,
          initialValue: embed['url']?.toString() ?? '',
          suggestions: widget.variableSuggestions,
          emojiSuggestions: widget.emojiSuggestions,
          onChanged: (v) => _setEmbedValue(index, 'url', v),
        );

      case _EmbedMiniBlockType.color:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            VariableTextField(
              label: context.tr.embed_label_color,
              initialValue: embed['color']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setEmbedValue(index, 'color', v),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _pickEmbedColor(index),
                icon: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color:
                        _parseEmbedColor(embed['color']?.toString() ?? '') ??
                        Colors.transparent,
                    border: Border.all(color: AppTheme.grey),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                ),
                label: Text(context.tr.common_pick),
              ),
            ),
          ],
        );

      case _EmbedMiniBlockType.timestamp:
        final timestampValue = embed['timestamp']?.toString() ?? '';
        final useCurrentTimestamp = _isCurrentTimestamp(timestampValue);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(context.tr.embed_checkbox_current_timestamp),
              subtitle: Text(context.tr.embed_hint_timestamp),
              value: useCurrentTimestamp,
              onChanged: (checked) {
                if (checked == true) {
                  _setEmbedValue(index, 'timestamp', 'now');
                } else {
                  _setEmbedValue(index, 'timestamp', '');
                }
              },
            ),
            const SizedBox(height: 8),
            IgnorePointer(
              ignoring: useCurrentTimestamp,
              child: Opacity(
                opacity: useCurrentTimestamp ? 0.5 : 1,
                child: VariableTextField(
                  label: context.tr.embed_label_timestamp,
                  initialValue: useCurrentTimestamp ? '' : timestampValue,
                  suggestions: widget.variableSuggestions,
                  emojiSuggestions: widget.emojiSuggestions,
                  onChanged: (v) => _setEmbedValue(index, 'timestamp', v),
                ),
              ),
            ),
          ],
        );

      case _EmbedMiniBlockType.footer:
        final footer = Map<String, dynamic>.from(embed['footer'] as Map);
        return Column(
          children: [
            VariableTextField(
              label: context.tr.embed_label_footer_text,
              initialValue: footer['text']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'footer', 'text', v),
            ),
            const SizedBox(height: 8),
            VariableTextField(
              label: context.tr.embed_label_footer_icon,
              initialValue: footer['icon_url']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'footer', 'icon_url', v),
            ),
          ],
        );

      case _EmbedMiniBlockType.author:
        final author = Map<String, dynamic>.from(embed['author'] as Map);
        return Column(
          children: [
            VariableTextField(
              label: context.tr.embed_label_author_name,
              initialValue: author['name']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'author', 'name', v),
            ),
            const SizedBox(height: 8),
            VariableTextField(
              label: context.tr.embed_label_author_url,
              initialValue: author['url']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'author', 'url', v),
            ),
            const SizedBox(height: 8),
            VariableTextField(
              label: context.tr.embed_label_author_icon,
              initialValue: author['icon_url']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'author', 'icon_url', v),
            ),
          ],
        );

      case _EmbedMiniBlockType.media:
        final image = Map<String, dynamic>.from(embed['image'] as Map);
        final thumbnail = Map<String, dynamic>.from(embed['thumbnail'] as Map);
        return Column(
          children: [
            VariableTextField(
              label: context.tr.embed_label_image_url,
              initialValue: image['url']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'image', 'url', v),
            ),
            const SizedBox(height: 8),
            VariableTextField(
              label: context.tr.embed_label_thumbnail_url,
              initialValue: thumbnail['url']?.toString() ?? '',
              suggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              onChanged: (v) => _setNestedValue(index, 'thumbnail', 'url', v),
            ),
          ],
        );

      case _EmbedMiniBlockType.fields:
        final fields = List<Map<String, dynamic>>.from(embed['fields'] as List);
        return Column(
          children: [
            ...fields.asMap().entries.map((fieldEntry) {
              final fi = fieldEntry.key;
              final field = fieldEntry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              context.tr.embed_field_number(fi + 1),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => _removeField(index, fi),
                            icon: const AppIcon.fromMaterial(
                              Icons.delete,
                              color: AppTheme.error,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      VariableTextField(
                        label: context.tr.common_name,
                        initialValue: field['name']?.toString() ?? '',
                        suggestions: widget.variableSuggestions,
                        emojiSuggestions: widget.emojiSuggestions,
                        onChanged: (v) => _setFieldValue(index, fi, 'name', v),
                      ),
                      const SizedBox(height: 8),
                      VariableTextField(
                        label: context.tr.common_value,
                        initialValue: field['value']?.toString() ?? '',
                        maxLines: 3,
                        suggestions: widget.variableSuggestions,
                        emojiSuggestions: widget.emojiSuggestions,
                        onChanged: (v) => _setFieldValue(index, fi, 'value', v),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr.embed_label_inline),
                        value: field['inline'] == true,
                        onChanged: (v) =>
                            _setFieldValue(index, fi, 'inline', v),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (fields.length < 25)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _addField(index),
                  icon: const AppIcon.fromMaterial(Icons.add, size: 18),
                  label: Text(context.tr.embed_add_field),
                ),
              ),
          ],
        );

      case _EmbedMiniBlockType.dynamicFields:
        return VariableTextField(
          label: context.tr.embed_label_dynamic_fields,
          initialValue: embed['fieldsTemplate']?.toString() ?? '',
          maxLines: 3,
          suggestions: widget.variableSuggestions,
          emojiSuggestions: widget.emojiSuggestions,
          hint:
              'Ex: ((embedFields(myHttp.body.\$.items, "{name}", "{score}", true)))',
          onChanged: (v) => _setEmbedValue(index, 'fieldsTemplate', v),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build: "Add section" popup menu
  // ---------------------------------------------------------------------------

  Widget _buildAddBlockMenu(int embedIndex) {
    final available = _availableBlocks(embedIndex);
    if (available.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<_EmbedMiniBlockType>(
      onSelected: (type) => _addMiniBlock(embedIndex, type),
      itemBuilder: (_) => available
          .map(
            (type) => PopupMenuItem(
              value: type,
              child: Row(
                children: [
                  AppIcon.fromMaterial(_iconForType(type), size: 18),
                  const SizedBox(width: 8),
                  Text(_labelForType(type)),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.add,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              context.tr.embed_add_section,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    context.tr.embed_response_header(
                      _embeds.length,
                      widget.maxEmbeds,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _embeds.length >= widget.maxEmbeds
                      ? null
                      : _addEmbed,
                  icon: const AppIcon.fromMaterial(Icons.add, size: 18),
                  label: Text(context.tr.embed_add_tooltip),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_embeds.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  AppIcon.fromMaterial(
                    Icons.dashboard_customize_outlined,
                    size: 32,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr.embed_empty_message(widget.maxEmbeds),
                    style: const TextStyle(color: AppTheme.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._embeds.asMap().entries.map((entry) {
              final index = entry.key;
              final embed = _normalizeEmbed(entry.value);
              final visible = _visibleBlocks(index);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gradient header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.discord,
                            AppTheme.discord.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              context.tr.embed_number(index + 1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusSm,
                            ),
                            onTap: () => _removeEmbed(index),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: AppIcon.fromMaterial(
                                Icons.delete_outline,
                                color: Colors.white70,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ...visible.map(
                            (type) => _buildMiniBlock(
                              type: type,
                              embedIndex: index,
                              child: _buildMiniBlockContent(type, index, embed),
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildAddBlockMenu(index),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
