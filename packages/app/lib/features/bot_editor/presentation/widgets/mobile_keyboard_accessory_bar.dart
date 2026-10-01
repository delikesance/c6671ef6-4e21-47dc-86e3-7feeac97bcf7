import 'package:flutter/material.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// A sleek accessory bar rendered above the mobile virtual keyboard.
/// Provides instant access to Discord/BDFD syntax characters (`$`, `[`, `]`, `{`, `}`)
/// and common dynamic variable chips.
class MobileKeyboardAccessoryBar extends StatelessWidget {
  const MobileKeyboardAccessoryBar({
    super.key,
    this.variableSuggestions = const [],
  });

  final List<VariableSuggestion> variableSuggestions;

  static const List<String> _quickSyntax = [
    r'$',
    '[',
    ']',
    '{',
    '}',
    '((',
    '))',
    '<@',
    '>',
    ':',
  ];

  void _insertText(String text) {
    final focusScope = FocusManager.instance.primaryFocus;
    if (focusScope == null) return;

    final context = focusScope.context;
    if (context == null) return;

    // Locate the nearest EditableTextState in the focused element tree
    final editableTextState = context
        .findAncestorStateOfType<EditableTextState>();

    if (editableTextState != null) {
      final value = editableTextState.textEditingValue;
      final start = value.selection.start;
      final end = value.selection.end;

      if (start >= 0 && end >= 0) {
        final newText = value.text.replaceRange(start, end, text);
        final newSelection = TextSelection.collapsed(
          offset: start + text.length,
        );
        editableTextState.userUpdateTextEditingValue(
          value.copyWith(
            text: newText,
            selection: newSelection,
            composing: TextRange.empty,
          ),
          SelectionChangedCause.keyboard,
        );
      } else {
        final newText = value.text + text;
        editableTextState.userUpdateTextEditingValue(
          value.copyWith(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
            composing: TextRange.empty,
          ),
          SelectionChangedCause.keyboard,
        );
      }
    }
  }

  void _showVariablesSheet(BuildContext context) {
    if (variableSuggestions.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.6,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(sheetContext).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const AppIcon.fromMaterial(Icons.data_object, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      context.tr.image_editor_insert_variable,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const AppIcon.fromMaterial(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: variableSuggestions.length,
                  itemBuilder: (_, index) {
                    final suggestion = variableSuggestions[index];
                    return ListTile(
                      dense: true,
                      leading: const AppIcon.fromMaterial(Icons.code, size: 18),
                      title: Text(
                        suggestion.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle:
                          (suggestion.description != null &&
                              suggestion.description!.isNotEmpty)
                          ? Text(
                              suggestion.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            )
                          : null,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _insertText(suggestion.name);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerHighest;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        children: [
          // Variable insertion button
          if (variableSuggestions.isNotEmpty) ...[
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _showVariablesSheet(context),
              icon: const AppIcon.fromMaterial(Icons.data_object, size: 16),
              label: Text(
                context.tr.globals_tab_short,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            VerticalDivider(
              width: 1,
              indent: 4,
              endIndent: 4,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: 8),
          ],

          // Quick syntax buttons
          for (final syntax in _quickSyntax) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                elevation: 0.5,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  onTap: () => _insertText(syntax),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 34),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    child: Text(
                      syntax,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
