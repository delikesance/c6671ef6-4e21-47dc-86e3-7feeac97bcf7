import 'dart:io';

import '../tools/hardcoded_string_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('flags hardcoded UI literal', () {
    final findings = findHardcodedStringFindings(
      rootPath: '.',
      filesOverride: <File>[
        _fakeFile('/tmp/sample.dart', "return Text('Hardcoded text');\n"),
      ],
    );

    expect(findings, hasLength(1));
    expect(findings.first.line, 1);
  });

  test('ignores localized and allowlisted patterns', () {
    final findings = findHardcodedStringFindings(
      rootPath: '.',
      filesOverride: <File>[
        _fakeFile(
          '/tmp/sample_ok.dart',
          "return Text(context.tr.common_ok);\ntitle: '/\$path',\nlabel: Text('((\${item.name}))'),\n",
        ),
      ],
    );

    expect(findings, isEmpty);
  });
}

File _fakeFile(String path, String content) {
  final file = File(path);
  file.createSync(recursive: true);
  file.writeAsStringSync(content);
  return file;
}
