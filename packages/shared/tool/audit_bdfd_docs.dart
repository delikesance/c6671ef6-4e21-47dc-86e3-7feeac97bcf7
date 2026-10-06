import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';

/// Compile every fenced BDFD example using the production compiler.
/// This checks syntax and known functions, not Discord permissions or behavior.
void main(List<String> args) {
  final root = Directory(args.isEmpty ? '../../../vitrine' : args.first);
  final failures = <Map<String, dynamic>>[];
  var checked = 0;
  final fences = RegExp(r'^```bdfd[^\n]*\n([\s\S]*?)^```\s*$', multiLine: true);
  final compiler = BdfdCompiler();
  for (final collection in ['_docs', '_posts']) {
    final directory = Directory('${root.path}/$collection');
    if (!directory.existsSync()) {
      stderr.writeln('Missing documentation directory: ${directory.path}');
      exitCode = 2;
      return;
    }
    final files =
        directory
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.md'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final markdown = file.readAsStringSync();
      for (final fence in fences.allMatches(markdown)) {
        checked++;
        final source = fence.group(1)!;
        final result = compiler.compile(source);
        final errors = result.diagnostics
            .where((d) => d.severity == BdfdCompileDiagnosticSeverity.error)
            .map((d) => '${d.line ?? "?"}:${d.column ?? "?"} ${d.message}')
            .toList();
        // The compiler permits unknown bare tokens as literal text. In a
        // documentation example they can hide a misspelled function.
        final unknown = BdfdLexer()
            .tokenize(source)
            .tokens
            .where((t) => t.type == BdfdTokenType.function)
            .map((t) => t.lexeme.substring(1).toLowerCase())
            .where((name) => !allBdfdFunctions.contains(name))
            .toSet();
        errors.addAll(unknown.map((name) => 'Unknown function: \$$name'));
        if (errors.isNotEmpty) {
          failures.add({
            'path': file.path,
            'line':
                '\n'.allMatches(markdown.substring(0, fence.start)).length + 1,
            'source': source,
            'errors': errors,
          });
        }
      }
    }
  }
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'checked': checked,
      'failed': failures.length,
      'failures': failures,
    }),
  );
  if (failures.isNotEmpty) exitCode = 1;
}
