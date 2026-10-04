import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

import 'helpers/sandbox_helpers.dart';

void main() {
  Future<String?> run(String script) async =>
      contentOf(await runScript(script));

  group('C-style for loops', () {
    test('single variable', () async {
      expect(await run(r'$for[i = 0; i < 5; i++]$i,$endfor'), '0,1,2,3,4,');
    });

    test('two variables', () async {
      expect(
        await run(r'$for[i = 0, j = 10; i <= 3; i++, j--]$i-$j,$endfor'),
        '0-10,1-9,2-8,3-7,',
      );
    });

    test('+= update', () async {
      expect(await run(r'$for[x = 0; x < 20; x += 5]$x,$endfor'), '0,5,10,15,');
    });

    test('decrement', () async {
      expect(await run(r'$for[i = 5; i > 0; i--]$i,$endfor'), '5,4,3,2,1,');
    });

    test('condition comparing two variables', () async {
      expect(await run(r'$for[i = 0, j = 3; i < j; i++]$i,$endfor'), '0,1,2,');
    });

    test('inside an embed response', () async {
      final result = await runScript(
        r'$title[Countdown]$for[i = 3; i >= 1; i--]$addField[Step $i;Go;no]$endfor$color[#00FF00]',
      );
      expectOk(result);
      final embed = (payloads(result).single['embeds'] as List).single as Map;
      expect(embed['title'], 'Countdown');
      expect(embed['color'], '#00FF00');
      expect((embed['fields'] as List).map((f) => f['name']), [
        'Step 3',
        'Step 2',
        'Step 1',
      ]);
    });

    test('nested loops keep their own variables', () async {
      expect(
        await run(
          r'$for[i = 0; i < 2; i++]outer=$i,$for[j = 10; j < 12; j++]inner=$j,$endfor$endfor',
        ),
        'outer=0,inner=10,inner=11,outer=1,inner=10,inner=11,',
      );
    });

    test(
      'an invalid initialiser is a diagnostic and a runtime error',
      () async {
        const source = r'$for[badstuff; i < 5; i++]x$endfor';
        final compiled = BdfdCompiler().compile(source);
        expect(compiled.hasErrors, isTrue);
        expect(
          compiled.diagnostics.single.stage,
          BdfdCompileDiagnosticStage.native,
        );
        final result = await runScript(source);
        expect(result['success'], false);
        expect(payloads(result), isEmpty);
      },
    );

    test('an unbounded loop is stopped by the step limit', () async {
      final result = await runScript(r'$for[i = 0; i < 9999999; i++]$i$endfor');
      expect(result['success'], false);
      expect(result['error'], contains('step limit'));
    });
  });
}
