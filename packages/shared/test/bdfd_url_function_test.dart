import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

void main() {
  test(r'$url encodes and decodes', () async {
    expect(
      contentOf(await runScript(r'$url[encode;Hello world!!]')),
      'Hello+world%21%21',
    );
    expect(
      contentOf(await runScript(r'$url[decode;Hello+world%21%21]')),
      'Hello world!!',
    );
  });

  test(r'$url accepts nested function results and runtime text', () async {
    expect(
      contentOf(await runScript(r'$url[encode;$toUpperCase[Hello World]]')),
      'HELLO+WORLD',
    );
    expect(
      contentOf(
        await runScript(
          r'$url[encode;$message]',
          variables: {'message.content': 'a b&c'},
        ),
      ),
      'a+b%26c',
    );
  });
}
