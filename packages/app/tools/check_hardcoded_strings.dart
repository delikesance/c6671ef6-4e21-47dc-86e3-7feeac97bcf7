import 'dart:io';

import 'hardcoded_string_guard.dart';

void main() {
  final findings = findHardcodedStringFindings(rootPath: 'lib');
  if (findings.isEmpty) {
    stdout.writeln('No hardcoded user-facing literals detected.');
    return;
  }

  stdout.writeln(
    'Found ${findings.length} probable hardcoded user-facing string(s):',
  );
  for (final finding in findings) {
    stdout.writeln('${finding.path}:${finding.line}: ${finding.content}');
  }
  exitCode = 1;
}
