import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/code_editor/script_editor_indent_guides.dart';
import 'package:bot_creator/core/code_editor/script_editor_language.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Panneau d'autocomplete ancré au caret.
///
/// La position est calculée comme dans l'éditeur BDFD (une ligne = 20 px, un
/// caractère = 7,8 px, padding 12/8) puis clampée aux bords du [LayoutBuilder]
/// parent, donc le panneau ne sort jamais de la zone d'édition.
class ScriptAutocompleteOverlay extends StatelessWidget {
  const ScriptAutocompleteOverlay({
    super.key,
    required this.entries,
    required this.selectedIndex,
    required this.gutterWidth,
    required this.caretLine,
    required this.caretColumn,
    required this.scrollX,
    required this.scrollY,
    required this.showHorizontalOffset,
    required this.constraints,
    required this.colors,
    required this.onSelected,
    required this.onHover,
  });

  final List<ScriptCompletionEntry> entries;
  final int selectedIndex;

  /// Largeur de la gouttière des numéros de ligne.
  final double gutterWidth;

  /// Ligne (0-indexée) du caret.
  final int caretLine;

  /// Colonne (0-indexée) du caret.
  final int caretColumn;

  final double scrollX;
  final double scrollY;
  final bool showHorizontalOffset;
  final BoxConstraints constraints;
  final CodeEditorThemeColors colors;
  final ValueChanged<ScriptCompletionEntry> onSelected;
  final ValueChanged<int> onHover;

  static const double _itemHeight = 30;
  static const double _panelWidth = 220;
  static const double _panelMaxHeight = 168;
  static const double _panelVerticalPadding = 8;

  @override
  Widget build(BuildContext context) {
    final panelHeight = (entries.length * _itemHeight + _panelVerticalPadding)
        .clamp(80.0, _panelMaxHeight);
    final desiredLeft = _desiredLeft;
    final desiredTop =
        ScriptEditorMetrics.topPadding +
        ((caretLine + 1) * ScriptEditorMetrics.lineHeight) -
        scrollY +
        4;

    final minLeft = gutterWidth + 4;
    final maxLeft = (constraints.maxWidth - _panelWidth).clamp(
      minLeft,
      double.infinity,
    );
    final minTop =
        ScriptEditorMetrics.topPadding + ScriptEditorMetrics.lineHeight;
    final maxTop = (constraints.maxHeight - panelHeight).clamp(
      minTop,
      double.infinity,
    );

    return Positioned(
      left: desiredLeft.clamp(minLeft, maxLeft),
      top: desiredTop.clamp(minTop, maxTop),
      width: _panelWidth,
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: colors.surface,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: _panelMaxHeight),
          // `shrinkWrap` est indispensable : sans lui la liste s'étire jusqu'à
          // `_panelMaxHeight` et le panneau déborde de `panelHeight` px sous la
          // zone d'édition, alors que le clamp vertical a réservé cette hauteur.
          child: ListView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: entries.length,
            itemBuilder: (_, index) => _entryTile(entries[index], index),
          ),
        ),
      ),
    );
  }

  double get _desiredLeft =>
      gutterWidth +
      ScriptEditorMetrics.leftPadding +
      (caretColumn * ScriptEditorMetrics.charWidth) -
      (showHorizontalOffset ? scrollX : 0);

  Widget _entryTile(ScriptCompletionEntry entry, int index) {
    final isSelected = index == selectedIndex;
    return InkWell(
      onHover: (hovering) {
        if (hovering) {
          onHover(index);
        }
      },
      onTap: () => onSelected(entry),
      child: Container(
        height: _itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? colors.selection : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        child: Row(
          children: [
            Icon(
              _iconFor(entry.kind),
              size: 14,
              color: isSelected ? colors.text : colors.bracket,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: isSelected ? colors.text : colors.gutterText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              entry.insert.replaceAll('\n', ' ↵ '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? colors.text.withValues(alpha: 0.7)
                    : colors.gutterText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(ScriptCompletionKind kind) {
    switch (kind) {
      case ScriptCompletionKind.emoji:
        return Icons.emoji_emotions_outlined;
      case ScriptCompletionKind.snippet:
        return Icons.segment;
      case ScriptCompletionKind.symbol:
      case ScriptCompletionKind.callable:
        return Icons.functions;
    }
  }
}

/// Bulle de signature du call dans lequel se trouve le caret.
///
/// Positionnée au-dessus de la ligne du caret, clampée aux bords du
/// [LayoutBuilder] parent ; le paramètre actif est souligné.
class ScriptSignatureHintOverlay extends StatelessWidget {
  const ScriptSignatureHintOverlay({
    super.key,
    required this.hint,
    required this.gutterWidth,
    required this.caretLine,
    required this.caretColumn,
    required this.scrollX,
    required this.scrollY,
    required this.showHorizontalOffset,
    required this.constraints,
    required this.colors,
  });

  final ScriptSignatureHint hint;
  final double gutterWidth;
  final int caretLine;
  final int caretColumn;
  final double scrollX;
  final double scrollY;
  final bool showHorizontalOffset;
  final BoxConstraints constraints;
  final CodeEditorThemeColors colors;

  /// Largeur maximale de la bulle, réservée lors du clamp horizontal.
  static const double _maxWidth = 320;

  /// Hauteur maximale de la bulle, réservée lors du clamp vertical.
  static const double _maxHeight = 40;

  @override
  Widget build(BuildContext context) {
    final desiredLeft =
        gutterWidth +
        ScriptEditorMetrics.leftPadding +
        (caretColumn * ScriptEditorMetrics.charWidth) -
        (showHorizontalOffset ? scrollX : 0);
    final desiredTop =
        ScriptEditorMetrics.topPadding +
        (caretLine * ScriptEditorMetrics.lineHeight) -
        scrollY -
        32;

    final minLeft = gutterWidth + 4;
    final maxLeft = constraints.maxWidth <= minLeft
        ? minLeft
        : (constraints.maxWidth - _maxWidth).clamp(
            minLeft,
            constraints.maxWidth,
          );
    final maxTop = constraints.maxHeight <= 0
        ? 0.0
        : (constraints.maxHeight - _maxHeight).clamp(
            0.0,
            constraints.maxHeight,
          );

    return Positioned(
      left: desiredLeft.clamp(minLeft, maxLeft),
      top: desiredTop.clamp(0.0, maxTop),
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: colors.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: RichText(
            text: TextSpan(children: _spans()),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _spans() {
    final nameStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: colors.function,
      fontWeight: FontWeight.w600,
    );
    final separatorStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: colors.semicolon,
    );
    final bracketStyle = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      color: colors.bracket,
    );

    final spans = <InlineSpan>[
      TextSpan(text: '${hint.name}[ ', style: nameStyle),
    ];
    for (var i = 0; i < hint.parameters.length; i++) {
      if (i > 0) {
        spans.add(TextSpan(text: ' ; ', style: separatorStyle));
      }
      final isActive = i == hint.activeIndex;
      spans.add(
        TextSpan(
          text: hint.parameters[i],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: isActive ? colors.text : colors.gutterText,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            decoration: isActive ? TextDecoration.underline : null,
            decorationColor: isActive ? colors.cursor : null,
          ),
        ),
      );
    }
    spans.add(TextSpan(text: ' ]', style: bracketStyle));
    return spans;
  }
}
