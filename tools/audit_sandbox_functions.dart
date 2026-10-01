import 'dart:convert';
import 'dart:io';
import 'package:bot_creator_shared/sandbox/function_suite.dart';

/// Run all known contracts individually and expose the uncovered registry.
/// Usage: dart run tools/audit_sandbox_functions.dart [--function=isnumber]
///        [--output=/absolute/path/report.json]
Future<void> main(List<String> args) async {
  String? argument(String prefix) {
    for (final arg in args) {
      if (arg.startsWith(prefix)) return arg.substring(prefix.length);
    }
    return null;
  }

  final selected = argument('--function=');
  final results = <Map<String, dynamic>>[];
  for (final sample in sandboxFunctionCases) {
    if (selected == null || selected == sample.function) {
      final result = await sample.run();
      results.add({
        'function': sample.function,
        'case': sample.label,
        'script': sample.script,
        'passed': result['passed'],
        'expected': result['expected'],
        'actual': result['actual'],
        if (sample.expectedValues.isNotEmpty) 'checks': result['checks'],
        'error': result['error'],
      });
    }
  }
  final catalog = sandboxFunctionCatalog();
  final report = {
    'registered': catalog.length,
    'tested': results.length,
    'passed': results.where((r) => r['passed'] == true).length,
    'tested_functions': results
        .map((result) => result['function'])
        .toSet()
        .length,
    'results': results,
    'uncovered': catalog
        .where((c) => c['covered'] != true)
        .map((c) => c['function'])
        .toList(),
    'complete':
        catalog.every((c) => c['covered'] == true) &&
        selected == null &&
        results.every((r) => r['passed'] == true),
  };
  final json = const JsonEncoder.withIndent('  ').convert(report);
  final destination = argument('--output=');
  if (destination == null) {
    stdout.writeln(json);
  } else {
    await File(destination).writeAsString('$json\n');
    stdout.writeln(
      '${report['passed']}/${report['tested']} cases passed; ${report['tested_functions']}/${report['registered']} functions tested; ${(report['uncovered'] as List).length} uncovered. Report: $destination',
    );
  }
  if (results.isEmpty ||
      results.any((r) => r['passed'] != true) ||
      (selected == null && report['complete'] != true)) {
    exitCode = 1;
  }
}
