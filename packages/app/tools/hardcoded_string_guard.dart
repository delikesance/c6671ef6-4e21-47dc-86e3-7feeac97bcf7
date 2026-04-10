import 'dart:io';

class HardcodedStringFinding {
  const HardcodedStringFinding({
    required this.path,
    required this.line,
    required this.content,
  });

  final String path;
  final int line;
  final String content;
}

final RegExp _textLiteralPattern = RegExp(
  r"""Text\(\s*(?:const\s+)?['"][^'"\\n]*[A-Za-zÀ-ÿ][^'"\\n]*['"]""",
);

final RegExp _namedLiteralPattern = RegExp(
  r"""(?:labelText|hintText|tooltip|title|content|label)\s*:\s*(?:const\s+)?['"][^'"\\n]*[A-Za-zÀ-ÿ][^'"\\n]*['"]""",
);

const Set<String> _skipFiles = <String>{
  'lib/l10n/',
  'lib/utils/trad/',
  'lib/routes/app/workflows.page.dart',
};

const List<String> _skipSnippets = <String>[
  r'((\${',
  r"'/$path'",
  "'• \$line'",
  r'${entry.locale} (${entry.count})',
  r'$optionsCount',
  r'$actionsCount',
  r'$subcommandCount',
  '((\${item.',
  '((\${suggestion.',
  '(({item.',
  '(({suggestion.',
];

bool _shouldSkipFile(String path) {
  return _skipFiles.any((segment) => path.contains(segment));
}

bool _isHardcodedUiLiteralLine(String line) {
  if (_skipSnippets.any(line.contains)) return false;
  return _textLiteralPattern.hasMatch(line) ||
      _namedLiteralPattern.hasMatch(line);
}

List<HardcodedStringFinding> findHardcodedStringFindings({
  required String rootPath,
  List<File>? filesOverride,
}) {
  final findings = <HardcodedStringFinding>[];

  final files =
      filesOverride ??
      Directory(rootPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList(growable: false);

  for (final file in files) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    if (_shouldSkipFile(normalizedPath)) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_isHardcodedUiLiteralLine(line)) continue;
      findings.add(
        HardcodedStringFinding(
          path: normalizedPath,
          line: i + 1,
          content: line.trim(),
        ),
      );
    }
  }

  return findings;
}
