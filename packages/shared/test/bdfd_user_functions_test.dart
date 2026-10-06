import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart' as sb;

/// User-defined functions:
/// $func[name;params...]...$funcEnd + $funcArg[] + $funcReturn[] + $funcCall[]
void main() {
  Future<String?> run(String script, {Map<String, dynamic>? variables}) async =>
      sb.contentOf(await sb.runScript(script, variables: variables));

  test(r'$funcCall returns a value', () async {
    expect(
      await run(
        r'$func[greet;name]'
        r'$funcReturn[Hello $funcArg[name]!]'
        r'$funcEnd'
        r'$funcCall[greet;World]',
      ),
      'Hello World!',
    );
  });

  test(r'$funcCall with a runtime value as argument', () async {
    expect(
      await run(
        r'$func[say;msg]'
        r'$funcReturn[Echo: $funcArg[msg]]'
        r'$funcEnd'
        r'$funcCall[say;$username]',
        variables: {'author.username': 'TestUser', 'user.username': 'TestUser'},
      ),
      'Echo: TestUser',
    );
  });

  test('a function can do math with its arguments', () async {
    expect(
      await run(
        r'$func[calculate_total;price;qty]'
        r'$funcReturn[$calculate[$funcArg[price]*$funcArg[qty]]]'
        r'$funcEnd '
        r'Total: $funcCall[calculate_total;15;4]',
      ),
      ' Total: 60',
    );
  });
}
