import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator_shared/types/variable_suggestion.dart' as shared;
import 'package:bot_creator_shared/utils/variable_catalog.dart' show variableDescription;
import 'package:bot_creator/core/i18n/i18n.dart';

/// A text field that shows autocomplete suggestions when the user types `((`
/// for dynamic variables, or `<` for emoji names.
///
/// Suggestions are grouped by category and show descriptions for commonly
/// used variables.
class VariableTextField extends StatefulWidget {
  final String? initialValue;
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final int maxLines;
  final int? maxLength;
  final List<VariableSuggestion> suggestions;
  final ValueChanged<String> onChanged;
  final bool isNumericField;
  final bool required;
  final String? helperText;
  final String? Function(String?)? validator;
  final List<String>? options;
  final List<AppEmoji>? emojiSuggestions;
  final bool useLabelText;
  /// When true, all variable suggestions are always visible (no need to type (( first).
  final bool alwaysShowSuggestions;

  const VariableTextField({
    super.key,
    this.initialValue,
    this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.maxLength,
    required this.suggestions,
    required this.onChanged,
    this.isNumericField = false,
    this.required = false,
    this.helperText,
    this.validator,
    this.options,
    this.emojiSuggestions,
    this.useLabelText = false,
    this.alwaysShowSuggestions = false,
  });

  @override
  State<VariableTextField> createState() => _VariableTextFieldState();
}

class _VariableTextFieldState extends State<VariableTextField> {
  TextEditingController? _internalController;
  late final FocusNode _focusNode;
  String _lastDispatchedValue = '';
  bool _suppressControllerNotifications = false;
  bool _rebuildScheduled = false;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initController();
  }

  void _initController() {
    if (widget.controller == null) {
      _internalController = TextEditingController(
        text: widget.initialValue ?? '',
      );
    }
    _lastDispatchedValue = _effectiveController.text;
    _effectiveController.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(covariant VariableTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)?.removeListener(
        _handleControllerChange,
      );

      if (oldWidget.controller == null && widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      }

      if (widget.controller == null) {
        _internalController ??= TextEditingController(
          text: oldWidget.controller?.text ?? widget.initialValue ?? '',
        );
      }

      _lastDispatchedValue = _effectiveController.text;
      _effectiveController.addListener(_handleControllerChange);
    }

    if (widget.controller == null &&
        widget.initialValue != null &&
        !_focusNode.hasFocus &&
        widget.initialValue != _effectiveController.text) {
      _syncControllerText(widget.initialValue!);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChange);
    _internalController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (_suppressControllerNotifications) return;

    final current = _effectiveController.text;
    if (current != _lastDispatchedValue) {
      _lastDispatchedValue = current;
      widget.onChanged(current);
    }

    _markNeedsRebuild();
  }

  void _syncControllerText(String value) {
    _suppressControllerNotifications = true;
    _lastDispatchedValue = value;
    _effectiveController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    _suppressControllerNotifications = false;
  }

  void _markNeedsRebuild() {
    if (!mounted) return;

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_rebuildScheduled) return;
      _rebuildScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _rebuildScheduled = false;
        if (mounted) setState(() {});
      });
      return;
    }

    setState(() {});
  }

  int _safeCursor(String text, int rawOffset) {
    if (rawOffset < 0 || rawOffset > text.length) return text.length;
    return rawOffset;
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _effectiveController.text;
    final cursor = _safeCursor(
      currentText,
      _effectiveController.selection.baseOffset,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.useLabelText) ...[
          Row(
            children: [
              Text(
                widget.label,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              if (widget.required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: _effectiveController,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          decoration: InputDecoration(
            labelText: widget.useLabelText ? widget.label : null,
            hintText: widget.hint,
            helperText: widget.helperText,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onTap: () => setState(() {}),
          validator: widget.validator,
        ),
        if (widget.alwaysShowSuggestions)
          Expanded(
            child: _buildSuggestionWidget(currentText, cursor) ??
                const SizedBox.shrink(),
          )
        else ...[
          if (_buildSuggestionWidget(currentText, cursor) != null)
            _buildSuggestionWidget(currentText, cursor)!,
        ],
      ],
    );
  }

  // ── Suggestion UI ────────────────────────────────────────────────────────

  Widget? _buildSuggestionWidget(String currentValue, int cursor) {
    // Emoji suggestions — shown when user types `<`
    if (widget.emojiSuggestions != null &&
        widget.emojiSuggestions!.isNotEmpty) {
      final emojiQuery = _extractEmojiQuery(currentValue, cursor);
      if (emojiQuery != null) {
        final q = emojiQuery.toLowerCase();
        final filteredEmojis = widget.emojiSuggestions!
            .where((e) => q.isEmpty || e.name.toLowerCase().contains(q))
            .take(12)
            .toList();
        if (filteredEmojis.isNotEmpty) {
          final emojiList = ListView(
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 8),
              Text(
                'Available emojis — tap to insert',
                style: TextStyle(fontSize: 11, color: AppTheme.grey),
              ),
              const SizedBox(height: 6),
              ...filteredEmojis.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _insertEmoji(e),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        Image.network(
                          e.imageUrl,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.emoji_emotions, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        Text(
                          e.mention,
                          style: TextStyle(fontSize: 11, color: AppTheme.grey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),
              )),
            ],
          );
          if (widget.alwaysShowSuggestions) {
            return emojiList;
          }
          return SizedBox(
            height: 220,
            child: emojiList,
          );
        }
      }
    }

    // Variable suggestions — shown when user types `((`, or always if requested.
    String? query;
    if (widget.alwaysShowSuggestions) {
      query = ''; // empty query = show all
    } else {
      query = _extractPlaceholderQuery(currentValue, cursor);
    }
    if (query == null) return null;

    final normalizedQuery = query.trim().toLowerCase();

    // Filter and deduplicate by name (keep first occurrence)
    final seen = <String>{};
    final filtered = <VariableSuggestion>[];
    for (final item in widget.suggestions) {
      if (widget.isNumericField && !item.isNumeric && !item.isUnknown) {
        continue;
      }
      if (normalizedQuery.isNotEmpty &&
          !item.name.toLowerCase().contains(normalizedQuery)) {
        continue;
      }
      if (seen.add(item.name)) {
        filtered.add(item);
      }
    }

    if (filtered.isEmpty) return null;

    // Group by category
    final grouped = _groupByCategory(filtered);
    final categoryOrder = _orderedCategories(grouped.keys.toList());

    final listView = ListView(
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 8),
        Text(
          widget.isNumericField
              ? 'Dynamic numeric suggestions'
              : 'Available variables — tap to insert',
          style: TextStyle(fontSize: 11, color: AppTheme.grey),
        ),
        const SizedBox(height: 6),
        for (final cat in categoryOrder)
          if (grouped.containsKey(cat)) ...[
            _buildCategoryHeader(cat, grouped[cat]!.length),
            ...grouped[cat]!.map(_buildSuggestionChip),
            const SizedBox(height: 4),
          ],
      ],
    );

    // In picker mode caller wraps in Expanded, return ListView directly.
    // In inline mode, constrain height.
    if (widget.alwaysShowSuggestions) {
      return listView;
    }
    return SizedBox(
      height: 220,
      child: listView,
    );
  }

  Map<shared.VariableCategory, List<VariableSuggestion>> _groupByCategory(
    List<VariableSuggestion> items,
  ) {
    final map = <shared.VariableCategory, List<VariableSuggestion>>{};
    for (final item in items) {
      final cat = item.category;
      map.putIfAbsent(cat, () => []).add(item);
    }
    return map;
  }

  /// Display order: most relevant first.
  List<shared.VariableCategory> _orderedCategories(
    List<shared.VariableCategory> cats,
  ) {
    const order = [
      shared.VariableCategory.context_,
      shared.VariableCategory.interaction,
      shared.VariableCategory.author,
      shared.VariableCategory.member,
      shared.VariableCategory.message,
      shared.VariableCategory.channel,
      shared.VariableCategory.guild,
      shared.VariableCategory.user,
      shared.VariableCategory.bot,
      shared.VariableCategory.temp,
      shared.VariableCategory.function_,
      shared.VariableCategory.other,
    ];
    cats.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return cats;
  }

  Widget _buildCategoryHeader(shared.VariableCategory cat, int count) {
    final label = _categoryLabel(context, cat);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
      child: Row(
        children: [
          Icon(_categoryIcon(cat), size: 14, color: AppTheme.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(width: 6),
          Text('$count', style: TextStyle(fontSize: 10, color: AppTheme.grey)),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(VariableSuggestion item) {
    final desc = variableDescription(item.name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _insertVariable(item.name),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Kind badge
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isNumeric
                      ? Colors.orange
                      : item.isUnknown
                          ? Colors.purple
                          : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '((${item.name}))',
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (desc != null)
                      Text(
                        desc,
                        style: TextStyle(fontSize: 11, color: AppTheme.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: AppTheme.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ── Category icons / labels ──────────────────────────────────────────────

  IconData _categoryIcon(shared.VariableCategory cat) {
    switch (cat) {
      case shared.VariableCategory.context_:
        return Icons.play_circle_outline;
      case shared.VariableCategory.interaction:
        return Icons.alternate_email;
      case shared.VariableCategory.bot:
        return Icons.smart_toy_outlined;
      case shared.VariableCategory.guild:
        return Icons.dns_outlined;
      case shared.VariableCategory.channel:
        return Icons.tag;
      case shared.VariableCategory.member:
        return Icons.person_outline;
      case shared.VariableCategory.message:
        return Icons.message_outlined;
      case shared.VariableCategory.author:
        return Icons.edit_note;
      case shared.VariableCategory.user:
        return Icons.account_circle_outlined;
      case shared.VariableCategory.temp:
        return Icons.schedule;
      case shared.VariableCategory.function_:
        return Icons.functions;
      case shared.VariableCategory.other:
        return Icons.more_horiz;
    }
  }

  // Category labels using i18n
  String _categoryLabel(BuildContext context, shared.VariableCategory cat) {
    final tr = context.tr;
    switch (cat) {
      case shared.VariableCategory.context_:
        return tr.variable_category_context;
      case shared.VariableCategory.interaction:
        return tr.variable_category_interaction;
      case shared.VariableCategory.bot:
        return tr.variable_category_bot;
      case shared.VariableCategory.guild:
        return tr.variable_category_guild;
      case shared.VariableCategory.channel:
        return tr.variable_category_channel;
      case shared.VariableCategory.member:
        return tr.variable_category_member;
      case shared.VariableCategory.message:
        return tr.variable_category_message;
      case shared.VariableCategory.author:
        return tr.variable_category_author;
      case shared.VariableCategory.user:
        return tr.variable_category_user;
      case shared.VariableCategory.temp:
        return tr.variable_category_temp;
      case shared.VariableCategory.function_:
        return tr.variable_category_functions;
      case shared.VariableCategory.other:
        return tr.variable_category_other;
    }
  }

  // ── Emoji extraction ─────────────────────────────────────────────────────

  String? _extractEmojiQuery(String input, int cursor) {
    final safeCursor = _safeCursor(input, cursor);
    if (safeCursor == 0) return null;

    int start = -1;
    bool startsWithLess = false;

    for (int i = safeCursor - 1; i >= 0; i--) {
      final char = input[i];
      if (char == '<') {
        start = i;
        startsWithLess = true;
        break;
      }
      if (char == ':') {
        if (i > 0 && input[i - 1] == '<') {
          start = i - 1;
          startsWithLess = true;
          break;
        }
        if (i > 1 && input[i - 1] == 'a' && input[i - 2] == '<') {
          start = i - 2;
          startsWithLess = true;
          break;
        }
        start = i;
        break;
      }
      if (char == ' ' || char == '\n' || char == '>') {
        break;
      }
    }

    if (start == -1) return null;

    final between = input.substring(start + 1, safeCursor);

    if (startsWithLess) {
      if (between.startsWith('a:')) {
        return between.substring(2);
      } else if (between.startsWith(':')) {
        return between.substring(1);
      }
      return between;
    } else {
      return between;
    }
  }

  // ── Variable placeholder extraction / insertion ──────────────────────────

  String? _extractPlaceholderQuery(String input, int cursor) {
    final safeCursor = _safeCursor(input, cursor);
    final start = input.lastIndexOf('((', safeCursor);
    if (start == -1) return null;
    if (safeCursor < start + 2) return '';

    final closing = input.indexOf('))', start + 2);
    if (closing != -1 && closing < safeCursor) return null;

    final afterStart = input.substring(start + 2, safeCursor);
    final parts = afterStart.split('|');
    return parts.last.trimLeft();
  }

  void _insertVariable(String variableName) {
    final input = _effectiveController.text;
    final cursor = _safeCursor(input, _effectiveController.selection.baseOffset);
    final start = input.lastIndexOf('((', cursor);

    if (start == -1) {
      final replacement = '(($variableName))';
      final nextText = input.replaceRange(cursor, cursor, replacement);
      final nextCursor = cursor + replacement.length;
      _effectiveController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextCursor),
      );
      return;
    }

    final closing = input.indexOf('))', start + 2);
    if (closing != -1 && closing < cursor) {
      final replacement = '(($variableName))';
      final nextText = input.replaceRange(cursor, cursor, replacement);
      final nextCursor = cursor + replacement.length;
      _effectiveController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextCursor),
      );
      return;
    }

    // Guard: cursor may be inside the '(( ' prefix on some IMEs/keyboards
    // (e.g. cursor=7 when (( starts at index 7, so start+2=9 > cursor).
    if (cursor < start + 2) {
      final replacement = '(($variableName))';
      final nextText = input.replaceRange(cursor, cursor, replacement);
      final nextCursor = cursor + replacement.length;
      _effectiveController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextCursor),
      );
      return;
    }

    final rawInner = input.substring(start + 2, cursor);
    final parts = rawInner.split('|');
    final prefixParts =
        parts.length > 1 ? parts.sublist(0, parts.length - 1) : <String>[];
    final previous = prefixParts
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final inner = [...previous, variableName].join(' | ');
    final replacement = '(($inner))';

    final replaceEnd =
        (closing != -1 && closing >= cursor) ? closing + 2 : cursor;
    final nextText = input.replaceRange(start, replaceEnd, replacement);
    final nextCursor = start + replacement.length;

    _effectiveController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
  }

  void _insertEmoji(AppEmoji emoji) {
    final input = _effectiveController.text;
    final cursor = _safeCursor(input, _effectiveController.selection.baseOffset);
    
    int start = -1;
    for (int i = cursor - 1; i >= 0; i--) {
      final char = input[i];
      if (char == '<') {
        start = i;
        break;
      }
      if (char == ':') {
        if (i > 0 && input[i - 1] == '<') {
          start = i - 1;
          break;
        }
        if (i > 1 && input[i - 1] == 'a' && input[i - 2] == '<') {
          start = i - 2;
          break;
        }
        start = i;
        break;
      }
      if (char == ' ' || char == '\n' || char == '>') {
        break;
      }
    }

    if (start == -1) {
      final replacement = emoji.mention;
      final nextText = input.replaceRange(cursor, cursor, replacement);
      final nextCursor = cursor + replacement.length;
      _effectiveController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextCursor),
      );
      return;
    }

    final replacement = emoji.mention;
    final nextText = input.replaceRange(start, cursor, replacement);
    final nextCursor = start + replacement.length;
    _effectiveController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextCursor),
    );
  }
}
