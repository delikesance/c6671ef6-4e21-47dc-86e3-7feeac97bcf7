import './script_editor_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Constantes de rendu partagées par le chrome de l'éditeur.
///
/// Les guides et les superpositions sont positionnés hors des widgets de texte
/// (peinture et `Positioned`) : ces valeurs doivent donc rester alignées avec le
/// style du champ d'édition (police 13 px, interligne 1.54, padding 12/8).
abstract final class ScriptEditorMetrics {
  /// Hauteur d'une ligne de code.
  static const double lineHeight = 20;

  /// Largeur d'un caractère en police monospace.
  static const double charWidth = 7.8;

  /// Padding vertical haut du champ d'édition.
  static const double topPadding = 12;

  /// Padding horizontal gauche du champ d'édition.
  static const double leftPadding = 8;
}

/// Guides d'indentation verticaux, peints derrière le code.
///
/// Un niveau vaut deux colonnes. Les colonnes de la ligne active (celle du
/// caret) sont dorées, celles qu'elle couvre sont éclaircies, les autres
/// restent discrètes. En mode défilement horizontal, les guides suivent le
/// défilement du code ([showHorizontalOffset]).
class ScriptIndentGuidesPainter extends CustomPainter {
  const ScriptIndentGuidesPainter({
    required this.source,
    required this.activeLine,
    required this.lineNumberGutterWidth,
    required this.scrollX,
    required this.scrollY,
    required this.showHorizontalOffset,
  });

  /// Document complet, découpé en lignes au moment de la peinture.
  final String source;

  /// Ligne du caret (0-indexée) : ses guides sont mis en évidence.
  final int activeLine;

  /// Largeur de la gouttière des numéros de ligne, à gauche des guides.
  final double lineNumberGutterWidth;

  /// Défilement horizontal, appliqué seulement si [showHorizontalOffset].
  final double scrollX;

  /// Défilement vertical.
  final double scrollY;

  /// `true` en mode défilement horizontal.
  final bool showHorizontalOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1;
    final matchedPaint = Paint()
      ..color = const Color(0x66FFD54F)
      ..strokeWidth = 1.2;
    final activePaint = Paint()
      ..color = const Color(0xCCFFD54F)
      ..strokeWidth = 1.8;

    final lines = source.split('\n');
    final activeColumns = activeLine >= 0 && activeLine < lines.length
        ? _indentColumns(lines[activeLine])
        : 0;

    for (var i = 0; i < lines.length; i++) {
      final top =
          ScriptEditorMetrics.topPadding +
          (i * ScriptEditorMetrics.lineHeight) -
          scrollY;
      if (top + ScriptEditorMetrics.lineHeight < 0 || top > size.height) {
        continue;
      }

      final columns = _indentColumns(lines[i]);
      if (columns < 2) {
        continue;
      }

      for (var column = 2; column <= columns; column += 2) {
        var paint = defaultPaint;
        if (activeColumns >= 2 && column <= activeColumns) {
          paint = matchedPaint;
        }
        if (i == activeLine && column <= activeColumns) {
          paint = activePaint;
        }

        final x = _columnOffset(column);
        if (x < lineNumberGutterWidth + 2 || x > size.width) {
          continue;
        }
        canvas.drawLine(
          Offset(x, top + 2),
          Offset(x, top + ScriptEditorMetrics.lineHeight - 2),
          paint,
        );
      }
    }
  }

  double _columnOffset(int column) =>
      lineNumberGutterWidth +
      ScriptEditorMetrics.leftPadding +
      (column * ScriptEditorMetrics.charWidth) -
      (showHorizontalOffset ? scrollX : 0);

  int _indentColumns(String line) {
    var columns = 0;
    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == ' ') {
        columns += 1;
      } else if (char == '\t') {
        columns += 2;
      } else {
        break;
      }
    }
    return columns;
  }

  @override
  bool shouldRepaint(covariant ScriptIndentGuidesPainter oldDelegate) {
    return source != oldDelegate.source ||
        activeLine != oldDelegate.activeLine ||
        lineNumberGutterWidth != oldDelegate.lineNumberGutterWidth ||
        scrollX != oldDelegate.scrollX ||
        scrollY != oldDelegate.scrollY ||
        showHorizontalOffset != oldDelegate.showHorizontalOffset;
  }
}

/// Auto-indentation de la touche Entrée.
///
/// L'indentation de la ligne précédente est recopiée, puis augmentée de
/// [ScriptEditorLanguage.indentIncreaseFor] espaces : `0` pour BDFD (la
/// recopie suffit), un niveau pour un langage à blocs délimités par `{`.
class ScriptAutoIndentFormatter extends TextInputFormatter {
  const ScriptAutoIndentFormatter(this.language);

  final ScriptEditorLanguage language;

  static final RegExp _leadingIndent = RegExp(r'^[ \t]+');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;
    if (!newValue.selection.isValid || !newValue.selection.isCollapsed) {
      return newValue;
    }
    if (newText.length - oldValue.text.length != 1) {
      return newValue;
    }

    final caret = newValue.selection.baseOffset;
    if (caret <= 0 || caret > newText.length || newText[caret - 1] != '\n') {
      return newValue;
    }

    final previousLineEnd = caret - 1;
    final previousLineStart = previousLineEnd == 0
        ? 0
        : newText.lastIndexOf('\n', previousLineEnd - 1) + 1;
    final previousLine = newText.substring(previousLineStart, previousLineEnd);
    final copied = _leadingIndent.firstMatch(previousLine)?.group(0) ?? '';
    final increase = language.indentIncreaseFor(previousLine);
    final indent = increase > 0 ? '$copied${' ' * increase}' : copied;
    if (indent.isEmpty) {
      return newValue;
    }

    return TextEditingValue(
      text: newText.replaceRange(caret, caret, indent),
      selection: TextSelection.collapsed(offset: caret + indent.length),
    );
  }
}
