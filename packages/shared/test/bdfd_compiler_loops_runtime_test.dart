import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

void main() {
  Future<String?> run(String script, [String message = '']) async => contentOf(
    await runScript(script, variables: {'message.content': message}),
  );

  group('loops with runtime bounds', () {
    test('the iteration count may come from user input', () async {
      expect(
        await run(r'$for[$message[1]]hello,$endfor', '3'),
        'hello,hello,hello,',
      );
    });

    test(r'$loop/$endloop is an alias of $for/$endfor', () async {
      expect(await run(r'$loop[$message[1]]hi,$endloop', '2'), 'hi,hi,');
    });

    test('the count may be a temporary variable computed from JSON', () async {
      expect(
        await run(
          r'$jsonParse[{"currencies":["a","b","c"]}]'
          r'$var[looping;$jsonArrayCount[currencies]]'
          r'$for[$var[looping]]$i,$endfor',
        ),
        '0,1,2,',
      );
    });

    test('C-style bounds may come from user input', () async {
      expect(
        await run(r'$for[i=0;i<$message[1];i++]$i,$endfor', '3'),
        '0,1,2,',
      );
      expect(
        await run(r'$for[i=$message[1];i<$message[2];i++]$i,$endfor', '1 4'),
        '1,2,3,',
      );
    });

    test(r'the body sees $i and $loopCount of the current iteration', () async {
      expect(
        await run(r'$for[$message[1]]$i is $loopCount,$endfor', '2'),
        '0 is 1,1 is 2,',
      );
    });

    test(
      'temporary variables set in the body are visible in the body',
      () async {
        expect(
          await run(
            r'$for[$message[1]]$var[current;$i]$var[current],$endfor',
            '3',
          ),
          '0,1,2,',
        );
      },
    );

    test('an iteration count that is not a number is an error', () async {
      final result = await runScript(
        r'$for[$message[1]]x$endfor',
        variables: {'message.content': 'abc'},
      );
      expect(result['success'], false);
      expect(payloads(result), isEmpty);
    });

    test('a huge iteration count is stopped by the step limit', () async {
      final result = await runScript(
        r'$for[$message[1]]x$endfor',
        variables: {'message.content': '100000'},
      );
      expect(result['success'], false);
      expect(result['error'], contains('step limit'));
    });

    test('static counts still run exactly that many times', () async {
      expect(await run(r'$for[3]x$endfor'), 'xxx');
    });
  });
}
