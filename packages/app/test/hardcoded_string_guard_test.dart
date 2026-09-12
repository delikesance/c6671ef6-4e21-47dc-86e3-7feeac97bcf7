import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tools/hardcoded_string_guard.dart';

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

  test('flags case-insensitive named labels (confirmLabel/cancelLabel)', () {
    final findings = findHardcodedStringFindings(
      rootPath: '.',
      filesOverride: <File>[
        _fakeFile(
          '/tmp/sample_dialog_labels.dart',
          "confirmLabel: 'Discard',\ncancelLabel: 'Cancel',\nConfirmLabel: 'Ok',\n",
        ),
      ],
    );

    expect(findings, hasLength(3));
  });

  test('flags extended named params (subtitle, description, message, '
      'semanticsLabel)', () {
    final findings = findHardcodedStringFindings(
      rootPath: '.',
      filesOverride: <File>[
        _fakeFile(
          '/tmp/sample_extended_params.dart',
          "subtitle: 'Sous-titre',\ndescription: 'Description',\n"
              "message: 'Message',\nsemanticsLabel: 'Étiquette',\n",
        ),
      ],
    );

    expect(findings, hasLength(4));
  });

  test('keeps Text(...) detection case-sensitive', () {
    final findings = findHardcodedStringFindings(
      rootPath: '.',
      filesOverride: <File>[
        _fakeFile(
          '/tmp/sample_text_case.dart',
          "text('not a widget label');\nText('Hardcoded label');\n",
        ),
      ],
    );

    expect(findings, hasLength(1));
    expect(findings.single.content, contains('Hardcoded label'));
  });
}

File _fakeFile(String path, String content) {
  final file = File(path);
  file.createSync(recursive: true);
  file.writeAsStringSync(content);
  return file;
}
