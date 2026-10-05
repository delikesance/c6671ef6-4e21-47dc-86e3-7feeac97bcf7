import 'dart:convert';

import '../widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart';
import '../editor/catalog/action_types.dart';
import '../editor/blocks/action_block.dart';
import '../editor/blocks/entry_point_block.dart';
import '../editor/blocks/scratch_block.dart';
import '../editor/blocks/scratch_block_connector.dart';
import '../editor/blocks/scratch_block_palette.dart';

typedef DocumentationMarkdownRenderer = Widget Function(String markdown);

/// Static documentation fixtures, never executable actions or Discord writes.
class DocumentationPreview extends StatefulWidget {
  const DocumentationPreview({
    super.key,
    required this.kind,
    required this.data,
    required this.markdown,
  });
  final String kind;
  final Map<String, dynamic> data;
  final DocumentationMarkdownRenderer markdown;

  static Map<String, dynamic>? decode(String kind, String source) {
    final field = switch (kind) {
      'bc-dual-view' => 'panels',
      'bc-block-flow' => 'blocks',
      'bc-discord-preview' => 'messages',
      _ => null,
    };
    if (field == null) return null;
    try {
      final value = jsonDecode(source);
      if (value is! Map<String, dynamic> ||
          value['version'] != 1 ||
          value[field] is! List) {
        return null;
      }
      final entries = value[field] as List;
      if (entries.isEmpty ||
          entries.length > 50 ||
          entries.any((entry) => entry is! Map)) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }

  @override
  State<DocumentationPreview> createState() => _DocumentationPreviewState();
}

class _DocumentationPreviewState extends State<DocumentationPreview> {
  int _selected = 0;
  List<Map> _items(Map data, String key) =>
      (data[key] is List ? data[key] as List : const [])
          .whereType<Map>()
          .toList();
  String _text(Map data, String key) => (data[key] ?? '').toString();

  @override
  Widget build(BuildContext context) => switch (widget.kind) {
    'bc-dual-view' => _dualView(context),
    'bc-block-flow' => _blockFlow(context),
    _ => _discordPreview(context),
  };

  Widget _dualView(BuildContext context) {
    final panels = _items(widget.data, 'panels');
    final index = _selected.clamp(0, panels.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: [
              for (var i = 0; i < panels.length; i++)
                ButtonSegment(
                  value: i,
                  icon: AppIcon.fromMaterial(
                    i == 0 ? Icons.account_tree_outlined : Icons.code,
                    size: 18,
                  ),
                  label: Text(_text(panels[i], 'label')),
                ),
            ],
            selected: {index},
            onSelectionChanged: (selection) =>
                setState(() => _selected = selection.single),
          ),
        ),
        const SizedBox(height: 12),
        widget.markdown(_text(panels[index], 'markdown')),
      ],
    );
  }

  Widget _blockFlow(BuildContext context) {
    final blocks = _items(widget.data, 'blocks');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const ScratchBlockConnector(),
          _editorBlock(context, blocks[i], i, blocks.length),
        ],
      ],
    );
  }

  Widget _editorBlock(BuildContext context, Map block, int index, int count) {
    final action = block['action'];
    if (action is Map &&
        BotCreatorActionType.values.any(
          (type) => type.name == action['type'],
        ) &&
        action['payload'] is Map) {
      return ActionBlock(
        key: ValueKey('docs-action-$index-${action['type']}'),
        action: ActionItem.fromJson(
          Map<String, dynamic>.from(action),
          fallbackId: 'docs-$index',
        ),
        index: index,
        totalCount: count,
        readOnly: true,
        onRemove: () {},
        onParameterChanged: (_, _) {},
        onSuggestionSelected: (_, _) {},
        fieldRefreshVersionOf: (_) => 0,
      );
    }
    final trigger = block['trigger'];
    if (trigger is Map) {
      return ExcludeFocus(
        child: IgnorePointer(
          child: trigger['type'] == 'slash'
              ? EntryPointBlock(
                  entryPointType: CommandEntryPointType.interaction,
                  onEntryPointTypeChanged: (_) {},
                  commandName: _text(trigger, 'name'),
                  canEditCommandType: false,
                )
              : WorkflowEntryPointBlock(
                  workflowType: 'event',
                  selectedEvent: _text(trigger, 'event'),
                  eventDefinitions: [
                    WorkflowEventItem(
                      event: _text(trigger, 'event'),
                      label: _text(trigger, 'event'),
                    ),
                  ],
                  customIdFilter: _text(trigger, 'customId'),
                ),
        ),
      );
    }
    // Older exports still use the shared block shell until their fixtures update.
    final category = switch (_text(block, 'category')) {
      'entrypoint' => 'Entry Point',
      'messages' => 'Messages',
      'channels' => 'Channels',
      'interactions' => 'Interactions',
      'moderation' => 'Moderation',
      _ => 'Logic',
    };
    final color = getCategoryColor(category);
    return ScratchBlock(
      color: color,
      title: _text(block, 'title'),
      icon: Icons.account_tree_outlined,
      badge: _text(block, 'badge').isEmpty
          ? null
          : ScratchBlockBadge(label: _text(block, 'badge'), color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_text(block, 'description').isNotEmpty)
            widget.markdown(_text(block, 'description')),
          for (final field in _items(block, 'fields'))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _text(field, 'label'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  widget.markdown(_text(field, 'value')),
                ],
              ),
            ),
          for (final toggle in _items(block, 'toggles'))
            Row(
              children: [
                Expanded(child: Text(_text(toggle, 'label'))),
                Switch(value: toggle['enabled'] == true, onChanged: null),
              ],
            ),
        ],
      ),
    );
  }

  Color _embedColor(Map embed) {
    final raw = _text(embed, 'color');
    return RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(raw)
        ? Color(0xff000000 | int.parse(raw.substring(1), radix: 16))
        : const Color(0xff5865f2);
  }

  Widget _discordPreview(BuildContext context) {
    const foreground = Color(0xfff2f3f5);
    const muted = Color(0xffb5bac1);
    final textTheme = Theme.of(
      context,
    ).textTheme.apply(bodyColor: foreground, displayColor: foreground);
    return Theme(
      data: Theme.of(context).copyWith(
        brightness: Brightness.dark,
        textTheme: textTheme,
        colorScheme: const ColorScheme.dark(
          surface: Color(0xff313338),
          onSurface: foreground,
          primary: Color(0xffb19df7),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xff313338),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final message in _items(widget.data, 'messages'))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xff5865f2),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _text(message, 'avatar'),
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _text(message, 'username'),
                                style: textTheme.labelLarge,
                              ),
                              if (_text(message, 'botTag').isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff5865f2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    _text(message, 'botTag'),
                                    style: textTheme.labelSmall,
                                  ),
                                ),
                              Text(
                                _text(message, 'timestamp'),
                                style: textTheme.labelSmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                          if (_text(message, 'content').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: widget.markdown(_text(message, 'content')),
                            ),
                          for (final embed in _items(message, 'embeds'))
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xff2b2d31),
                                border: Border(
                                  left: BorderSide(
                                    color: _embedColor(embed),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_text(embed, 'title').isNotEmpty)
                                    Text(
                                      _text(embed, 'title'),
                                      style: textTheme.titleSmall,
                                    ),
                                  if (_text(embed, 'description').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: widget.markdown(
                                        _text(embed, 'description'),
                                      ),
                                    ),
                                  if (_text(embed, 'footer').isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        _text(embed, 'footer'),
                                        style: textTheme.labelSmall?.copyWith(
                                          color: muted,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (_items(message, 'buttons').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final button in _items(
                                    message,
                                    'buttons',
                                  ))
                                    Semantics(
                                      button: true,
                                      enabled: false,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: switch (_text(
                                            button,
                                            'style',
                                          )) {
                                            'danger' => const Color(0xffda373c),
                                            'success' => const Color(
                                              0xff248046,
                                            ),
                                            _ => const Color(0xff5865f2),
                                          },
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _text(button, 'label'),
                                          style: textTheme.labelLarge,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          if (_text(message, 'ephemeral').isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _text(message, 'ephemeral'),
                                style: textTheme.bodySmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ),
                        ],
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
