import 'package:bot_creator_shared/engine/bdfd/visual/control_flow_logic.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:test/test.dart';

/// runBdfdScript delegates the whole script to the native-v1 engine through
/// `executeNativeBdfdScript`; it never compiles the source into actions. The
/// logic lives in `runBdfdScriptBlock` (the native `bc_runBdfdScript` calls it).
void main() {
  group('runBdfdScriptBlock', () {
    Future<bool> runBdfdScript({
      required Map<String, dynamic> payload,
      required Map<String, String> results,
      Future<Map<String, String>> Function(String source)? native,
      List<Action>? nestedActions,
      String Function(String input)? resolveValue,
    }) {
      return runBdfdScriptBlock(
        payload: payload,
        resultKey: 'bdfd',
        results: results,
        executeNativeBdfdScript: native,
        checkBudget: CommandExecutionBudget().check,
      ).then((_) => true);
    }

    test('hands the stored source to the native engine unchanged', () async {
      final results = <String, String>{};
      final sources = <String>[];
      final nestedActions = <Action>[];

      final handled = await runBdfdScript(
        payload: <String, dynamic>{'scriptContent': r'Hello $username[((x))]!'},
        results: results,
        nestedActions: nestedActions,
        // Interpolating before parsing would corrupt the stored source.
        resolveValue: (input) => 'RESOLVED',
        native: (source) async {
          sources.add(source);
          return <String, String>{};
        },
      );

      expect(handled, isTrue);
      expect(sources, [r'Hello $username[((x))]!']);
      expect(results['bdfd'], 'BDFD_OK');
      expect(nestedActions, isEmpty);
    });

    test('returns BDFD_EMPTY for blank script without running it', () async {
      final results = <String, String>{};
      var called = false;

      final handled = await runBdfdScript(
        payload: <String, dynamic>{'scriptContent': '   '},
        results: results,
        native: (_) async {
          called = true;
          return <String, String>{};
        },
      );

      expect(handled, isTrue);
      expect(results['bdfd'], 'BDFD_EMPTY');
      expect(called, isFalse);
    });

    test('returns BDFD_EMPTY when scriptContent is missing', () async {
      final results = <String, String>{};

      final handled = await runBdfdScript(
        payload: <String, dynamic>{},
        results: results,
      );

      expect(handled, isTrue);
      expect(results['bdfd'], 'BDFD_EMPTY');
    });

    test('fails when no native engine is available', () async {
      expect(
        () => runBdfdScript(
          payload: <String, dynamic>{'scriptContent': 'Hello'},
          results: <String, String>{},
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates native engine errors', () async {
      expect(
        () => runBdfdScript(
          payload: <String, dynamic>{'scriptContent': r'$if['},
          results: <String, String>{},
          native: (_) async => throw StateError(r'BDFD L1:1 $if: bad'),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('BDFD L1:1'),
          ),
        ),
      );
    });

    test('publishes native results under the result key', () async {
      final results = <String, String>{};

      await runBdfdScript(
        payload: <String, dynamic>{'scriptContent': 'Hello world!'},
        results: results,
        native: (_) async => <String, String>{'nested': 'ok'},
      );

      expect(results['bdfd.nested'], 'ok');
      expect(results['bdfd'], 'BDFD_OK');
    });

    test('propagates __stopped__ from native execution', () async {
      final results = <String, String>{};

      await runBdfdScript(
        payload: <String, dynamic>{'scriptContent': r'$stop'},
        results: results,
        native: (_) async => <String, String>{'__stopped__': 'true'},
      );

      expect(results['__stopped__'], 'true');
      expect(results['bdfd'], 'BDFD_OK');
    });
  });
}
