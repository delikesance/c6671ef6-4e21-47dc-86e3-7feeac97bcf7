import 'package:bot_creator/core/bdfd_editor/bdfd_validation.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/theme/block_category.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

/// Nature d'une ligne de l'aperçu : inchangée, ajoutée ou retirée.
enum CopilotDiffKind { same, add, del }

class CopilotDiffLine {
  const CopilotDiffLine(this.kind, this.text, this.number);
  final CopilotDiffKind kind;
  final String text;

  /// Numéro de ligne (nouveau script pour same/add, ancien pour del).
  final int number;
}

/// Diff ligne à ligne (plus longue sous-suite commune). Sans [before], toutes
/// les lignes sont affichées comme inchangées : on ne fabrique pas de diff.
List<CopilotDiffLine> copilotDiffLines(String? before, String after) {
  final next = after.split('\n');
  if (before == null || before == after) {
    return [
      for (var i = 0; i < next.length; i++)
        CopilotDiffLine(CopilotDiffKind.same, next[i], i + 1),
    ];
  }
  final prev = before.split('\n');
  if (prev.length > 400 || next.length > 400) {
    return [
      for (var i = 0; i < next.length; i++)
        CopilotDiffLine(CopilotDiffKind.same, next[i], i + 1),
    ];
  }
  final n = prev.length, m = next.length;
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = prev[i] == next[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final out = <CopilotDiffLine>[];
  var i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && prev[i] == next[j]) {
      out.add(CopilotDiffLine(CopilotDiffKind.same, next[j], j + 1));
      i++;
      j++;
    } else if (j < m && (i >= n || lcs[i][j + 1] >= lcs[i + 1][j])) {
      out.add(CopilotDiffLine(CopilotDiffKind.add, next[j], j + 1));
      j++;
    } else {
      out.add(CopilotDiffLine(CopilotDiffKind.del, prev[i], i + 1));
      i++;
    }
  }
  return out;
}

/// Famille de couleur d'une fonction BDFD (`$if`, `$takeRole`…).
BlockFamily copilotFunctionFamily(String name) {
  final n = name.toLowerCase();
  if (RegExp(
    r'^(if|elseif|else|endif|and|or|stop|for|endfor|while|endwhile|'
    r'loop|break|continue|try|catch|endtry|checkcondition)',
  ).hasMatch(n)) {
    return BlockFamily.logic;
  }
  if (RegExp(
    r'role|ban|kick|mute|timeout|clear|channel|slowmode|nick',
  ).hasMatch(n)) {
    return BlockFamily.moderation;
  }
  if (RegExp(
    r'^(send|reply|title|description|footer|color|addbutton|'
    r'addfield|image|thumbnail|author|embed|ephemeral|edit|react|'
    r'addreaction|addselect|addmodal)',
  ).hasMatch(n)) {
    return BlockFamily.messages;
  }
  if (RegExp(r'^(http|json|setvar|getvar|var|set|get)').hasMatch(n)) {
    return BlockFamily.http;
  }
  return BlockFamily.data;
}

/// Aperçu de code en lecture seule dans la carte de validation du Copilote :
/// numéros de ligne, surlignage +/- , couleurs de famille et bandeau de
/// diagnostics alimenté par la vraie validation BDFD.
class CopilotCodePreview extends StatelessWidget {
  const CopilotCodePreview({
    super.key,
    required this.fileName,
    required this.script,
    this.before,
    this.bdfd = true,
    this.onOpen,
    this.openTooltip = 'Ouvrir dans l\'éditeur',
    this.regionLabel = 'Aperçu du code modifié',
    this.validLabel = 'Syntaxe valide',
    this.errorLabel = 'Erreur de syntaxe',
  });

  final String fileName, script, openTooltip, regionLabel, validLabel;
  final String errorLabel;
  final String? before;

  /// `false` pour le JavaScript : pas de coloration BDFD ni de diagnostics.
  final bool bdfd;
  final VoidCallback? onOpen;

  static const _ink = Color(0xFFECEEF3);
  static const _muted = Color(0xFF9AA0AF);
  static const _gutter = Color(0xFF7E8494);
  static const _mono = 'JetBrainsMono';

  List<InlineSpan> _spans(String text, Color base) {
    if (!bdfd) {
      return [
        TextSpan(
          text: text,
          style: TextStyle(color: base),
        ),
      ];
    }
    final spans = <InlineSpan>[];
    final re = RegExp(r'\$[A-Za-z_][A-Za-z0-9_]*|[\[\];]');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(
          TextSpan(
            text: text.substring(last, m.start),
            style: TextStyle(color: base),
          ),
        );
      }
      final token = m.group(0)!;
      spans.add(
        TextSpan(
          text: token,
          style: TextStyle(
            color: token.startsWith(r'$')
                ? copilotFunctionFamily(token.substring(1)).color
                : _muted,
          ),
        ),
      );
      last = m.end;
    }
    if (last < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(last),
          style: TextStyle(color: base),
        ),
      );
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final lines = copilotDiffLines(before, script);
    final added = lines.where((l) => l.kind == CopilotDiffKind.add).length;
    final removed = lines.where((l) => l.kind == CopilotDiffKind.del).length;
    final diagnostics = bdfd
        ? bdfdDiagnosticsFor(script)
        : const <BdfdCompileDiagnostic>[];
    final errors = diagnostics
        .where((d) => d.severity == BdfdCompileDiagnosticSeverity.error)
        .toList();
    final lintLines = {
      for (final d in diagnostics)
        if (d.line != null) d.line!,
    };
    const codeStyle = TextStyle(
      fontFamily: _mono,
      fontSize: 11,
      height: 18 / 11,
      color: _ink,
    );
    return Container(
      color: AppTheme.homeContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 44,
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF101217),
              border: Border(
                top: BorderSide(color: AppTheme.homeCardBorder),
                bottom: BorderSide(color: Color(0xFF1C1F27)),
              ),
            ),
            child: Row(
              children: [
                AppIcon(Reicon.outline.documentText, size: 14, color: _muted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 12,
                      color: _ink,
                    ),
                  ),
                ),
                if (added > 0)
                  Text(
                    '+$added',
                    style: const TextStyle(
                      fontFamily: _mono,
                      fontSize: 11.5,
                      color: AppTheme.statusOnline,
                    ),
                  ),
                if (removed > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      '-$removed',
                      style: const TextStyle(
                        fontFamily: _mono,
                        fontSize: 11.5,
                        color: AppTheme.statusErrorText,
                      ),
                    ),
                  ),
                if (onOpen != null)
                  IconButton(
                    tooltip: openTooltip,
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    onPressed: onOpen,
                    icon: AppIcon(
                      Reicon.outline.arrowUpRight,
                      size: 16,
                      color: _muted,
                    ),
                  )
                else
                  const SizedBox(width: 12),
              ],
            ),
          ),
          Semantics(
            container: true,
            label: regionLabel,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: IntrinsicWidth(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final line in lines)
                          _row(line, codeStyle, lintLines),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _diagnosticsStrip(errors),
        ],
      ),
    );
  }

  Widget _row(CopilotDiffLine line, TextStyle style, Set<int> lintLines) {
    final add = line.kind == CopilotDiffKind.add;
    final del = line.kind == CopilotDiffKind.del;
    final gutterColor = add
        ? AppTheme.statusOnline
        : del
        ? AppTheme.statusErrorText
        : _gutter;
    final lint = !del && lintLines.contains(line.number);
    return Container(
      color: add
          ? AppTheme.statusOnline.withValues(alpha: .08)
          : del
          ? AppTheme.statusError.withValues(alpha: .08)
          : null,
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${line.number}',
                textAlign: TextAlign.right,
                style: style.copyWith(color: gutterColor),
              ),
            ),
          ),
          SizedBox(
            width: 14,
            child: Center(
              child: lint
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppTheme.statusWarning,
                        shape: BoxShape.circle,
                      ),
                    )
                  : Text(
                      add
                          ? '+'
                          : del
                          ? '−'
                          : '',
                      style: style.copyWith(color: gutterColor),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text.rich(
              TextSpan(
                children: _spans(line.text, del ? _muted : _ink),
                style: style,
              ),
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _diagnosticsStrip(List<BdfdCompileDiagnostic> errors) {
    if (!bdfd) return const SizedBox.shrink();
    final bad = errors.isNotEmpty;
    final color = bad ? AppTheme.statusErrorText : AppTheme.statusOnline;
    final first = bad ? errors.first : null;
    final text = bad
        ? '$errorLabel${first!.line != null ? ' · L${first.line}' : ''} · ${first.message}'
        : validLabel;
    return Container(
      constraints: const BoxConstraints(minHeight: 34),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        color: Color(0xFF101217),
        border: Border(top: BorderSide(color: Color(0xFF1C1F27))),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
