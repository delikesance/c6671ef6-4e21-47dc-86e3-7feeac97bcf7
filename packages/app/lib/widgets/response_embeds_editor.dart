import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:bot_creator/types/app_emoji.dart';
import 'package:bot_creator/types/variable_suggestion.dart';
import 'package:bot_creator/utils/embed_normalization.dart';
import 'package:bot_creator/widgets/variable_text_field.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/utils/i18n.dart';

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

  List<Map<String, dynamic>> _normalizeEmbedsForState(dynamic rawEmbeds) {
    return normalizeResponseEmbedsPayload(
      rawEmbeds,
      maxEmbeds: widget.maxEmbeds,
    ).map((embed) => Map<String, dynamic>.from(embed)).toList(growable: true);
  }

  Color? _parseEmbedColor(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    if (value.startsWith('#')) {
      final hex = value.substring(1);
      if (hex.length == 6) {
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed == null) {
          return null;
        }
        return Color(0xFF000000 | parsed);
      }
      if (hex.length == 8) {
        final parsed = int.tryParse(hex, radix: 16);
        if (parsed == null) {
          return null;
        }
        return Color(parsed);
      }
      return null;
    }

    final asInt = int.tryParse(value);
    if (asInt == null) {
      return null;
    }
    return Color(0xFF000000 | (asInt & 0x00FFFFFF));
  }

  String _formatEmbedColorHex(Color color) {
    final rgb = color.toARGB32() & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  Future<void> _pickEmbedColor(int index) async {
    Color selected =
        _parseEmbedColor((_embeds[index]['color'] ?? '').toString()) ??
        const Color(0xFF5865F2);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr.embed_color_picker_title),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: selected,
              onColorChanged: (color) {
                selected = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.tr.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.tr.common_apply),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _setEmbedValue(index, 'color', _formatEmbedColorHex(selected));
    }
  }

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

  Map<String, dynamic> _normalizeEmbed(Map<String, dynamic> embed) {
    return normalizeResponseEmbed(embed);
  }

  void _emit() {
    widget.onChanged(
      normalizeResponseEmbedsPayload(_embeds, maxEmbeds: widget.maxEmbeds),
    );
  }

  void _addEmbed() {
    if (_embeds.length >= widget.maxEmbeds) return;
    setState(() {
      _embeds.add(_normalizeEmbed(const {}));
    });
    _emit();
  }

  Future<void> _removeEmbed(int index) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog.adaptive(
                title: Text(context.tr.embed_delete_title),
                content: Text(context.tr.embed_delete_confirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.tr.common_cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.tr.common_delete,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }

    setState(() {
      _embeds.removeAt(index);
    });
    _emit();
  }

  void _setEmbedValue(int index, String key, dynamic value) {
    setState(() {
      _embeds[index][key] = value;
    });
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
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog.adaptive(
                title: Text(context.tr.embed_field_delete_title),
                content: Text(context.tr.embed_field_delete_confirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.tr.common_cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.tr.common_delete,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.tr.embed_response_header(
                  _embeds.length,
                  widget.maxEmbeds,
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              onPressed: _embeds.length >= widget.maxEmbeds ? null : _addEmbed,
              icon: const Icon(Icons.add, size: 20),
              tooltip: context.tr.embed_add_tooltip,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_embeds.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              context.tr.embed_empty_message(widget.maxEmbeds),
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        else
          ..._embeds.asMap().entries.map((entry) {
            final index = entry.key;
            final embed = _normalizeEmbed(entry.value);
            final footer = Map<String, dynamic>.from(embed['footer'] as Map);
            final image = Map<String, dynamic>.from(embed['image'] as Map);
            final thumbnail = Map<String, dynamic>.from(
              embed['thumbnail'] as Map,
            );
            final author = Map<String, dynamic>.from(embed['author'] as Map);
            final fields = List<Map<String, dynamic>>.from(
              embed['fields'] as List,
            );

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            context.tr.embed_number(index + 1),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _removeEmbed(index),
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    VariableTextField(
                      label: context.tr.embed_label_title,
                      initialValue: embed['title']?.toString() ?? '',
                      maxLength: 256,
                      suggestions: widget.variableSuggestions,
                      emojiSuggestions: widget.emojiSuggestions,
                      onChanged:
                          (value) => _setEmbedValue(index, 'title', value),
                    ),
                    const SizedBox(height: 8),
                    VariableTextField(
                      label: context.tr.common_description,
                      initialValue: embed['description']?.toString() ?? '',
                      maxLength: 2000,
                      maxLines: 4,
                      suggestions: widget.variableSuggestions,
                      emojiSuggestions: widget.emojiSuggestions,
                      onChanged:
                          (value) =>
                              _setEmbedValue(index, 'description', value),
                    ),
                    const SizedBox(height: 8),
                    VariableTextField(
                      label: context.tr.embed_label_url,
                      initialValue: embed['url']?.toString() ?? '',
                      suggestions: widget.variableSuggestions,
                      emojiSuggestions: widget.emojiSuggestions,
                      onChanged: (value) => _setEmbedValue(index, 'url', value),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth =
                            constraints.maxWidth.isFinite
                                ? constraints.maxWidth
                                : MediaQuery.of(context).size.width;
                        final stacked = availableWidth < 560;

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: stacked ? availableWidth : 280,
                              child: VariableTextField(
                                label: context.tr.embed_label_timestamp,
                                initialValue:
                                    embed['timestamp']?.toString() ?? '',
                                suggestions: widget.variableSuggestions,
                                emojiSuggestions: widget.emojiSuggestions,
                                onChanged:
                                    (value) => _setEmbedValue(
                                      index,
                                      'timestamp',
                                      value,
                                    ),
                              ),
                            ),
                            SizedBox(
                              width: stacked ? availableWidth : 220,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  VariableTextField(
                                    label: context.tr.embed_label_color,
                                    initialValue:
                                        embed['color']?.toString() ?? '',
                                    suggestions: widget.variableSuggestions,
                                    emojiSuggestions: widget.emojiSuggestions,
                                    onChanged:
                                        (value) => _setEmbedValue(
                                          index,
                                          'color',
                                          value,
                                        ),
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
                                              _parseEmbedColor(
                                                embed['color']?.toString() ??
                                                    '',
                                              ) ??
                                              Colors.transparent,
                                          border: Border.all(
                                            color: Colors.grey.shade500,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                      label: Text(context.tr.common_pick),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(context.tr.embed_section_footer),
                      children: [
                        VariableTextField(
                          label: context.tr.embed_label_footer_text,
                          initialValue: footer['text']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) => _setNestedValue(
                                index,
                                'footer',
                                'text',
                                value,
                              ),
                        ),
                        const SizedBox(height: 8),
                        VariableTextField(
                          label: context.tr.embed_label_footer_icon,
                          initialValue: footer['icon_url']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) => _setNestedValue(
                                index,
                                'footer',
                                'icon_url',
                                value,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(context.tr.embed_section_author),
                      children: [
                        VariableTextField(
                          label: context.tr.embed_label_author_name,
                          initialValue: author['name']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) => _setNestedValue(
                                index,
                                'author',
                                'name',
                                value,
                              ),
                        ),
                        const SizedBox(height: 8),
                        VariableTextField(
                          label: context.tr.embed_label_author_url,
                          initialValue: author['url']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) => _setNestedValue(
                                index,
                                'author',
                                'url',
                                value,
                              ),
                        ),
                        const SizedBox(height: 8),
                        VariableTextField(
                          label: context.tr.embed_label_author_icon,
                          initialValue: author['icon_url']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) => _setNestedValue(
                                index,
                                'author',
                                'icon_url',
                                value,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(context.tr.embed_section_media),
                      children: [
                        VariableTextField(
                          label: context.tr.embed_label_image_url,
                          initialValue: image['url']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) =>
                                  _setNestedValue(index, 'image', 'url', value),
                        ),
                        const SizedBox(height: 8),
                        VariableTextField(
                          label: context.tr.embed_label_thumbnail_url,
                          initialValue: thumbnail['url']?.toString() ?? '',
                          suggestions: widget.variableSuggestions,
                          emojiSuggestions: widget.emojiSuggestions,
                          onChanged:
                              (value) => _setNestedValue(
                                index,
                                'thumbnail',
                                'url',
                                value,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        context.tr.embed_fields_header(fields.length),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed:
                            fields.length >= 25 ? null : () => _addField(index),
                      ),
                      children: [
                        if (fields.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(context.tr.embed_fields_empty),
                          )
                        else
                          ...fields.asMap().entries.map((fieldEntry) {
                            final fieldIndex = fieldEntry.key;
                            final field = fieldEntry.value;
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            context.tr.embed_field_number(
                                              fieldIndex + 1,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed:
                                              () => _removeField(
                                                index,
                                                fieldIndex,
                                              ),
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                    VariableTextField(
                                      label: context.tr.common_name,
                                      initialValue:
                                          field['name']?.toString() ?? '',
                                      suggestions: widget.variableSuggestions,
                                      emojiSuggestions: widget.emojiSuggestions,
                                      onChanged:
                                          (value) => _setFieldValue(
                                            index,
                                            fieldIndex,
                                            'name',
                                            value,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    VariableTextField(
                                      label: context.tr.common_value,
                                      initialValue:
                                          field['value']?.toString() ?? '',
                                      maxLines: 3,
                                      suggestions: widget.variableSuggestions,
                                      emojiSuggestions: widget.emojiSuggestions,
                                      onChanged:
                                          (value) => _setFieldValue(
                                            index,
                                            fieldIndex,
                                            'value',
                                            value,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    SwitchListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(
                                        context.tr.embed_label_inline,
                                      ),
                                      value: field['inline'] == true,
                                      onChanged:
                                          (value) => _setFieldValue(
                                            index,
                                            fieldIndex,
                                            'inline',
                                            value,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                    const SizedBox(height: 8),
                    VariableTextField(
                      label: context.tr.embed_label_dynamic_fields,
                      initialValue: embed['fieldsTemplate']?.toString() ?? '',
                      maxLines: 3,
                      suggestions: widget.variableSuggestions,
                      emojiSuggestions: widget.emojiSuggestions,
                      hint:
                          'Ex: ((embedFields(myHttp.body.\$.items, "{name}", "{score}", true)))',
                      onChanged:
                          (value) =>
                              _setEmbedValue(index, 'fieldsTemplate', value),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
