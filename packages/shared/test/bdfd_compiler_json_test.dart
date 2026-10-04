import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

void main() {
  // JSON function behaviour is covered by bdfd_native_json_test.dart and
  // bdfd_native_json_foreach_test.dart; only diagnostics are checked here.
  test('unclosed jsonForEach is a native diagnostic', () {
    final result = BdfdCompiler().compile(
      r'$jsonParse[{}]$jsonForEach[]$reply$c[]test',
    );
    expect(result.hasErrors, isTrue);
    expect(
      result.diagnostics.any((d) => d.message.contains(r'$endjsonforeach')),
      isTrue,
    );
  });

  test('standalone endJsonForEach is a native diagnostic', () {
    final result = BdfdCompiler().compile(r'$reply$c[]test$endJsonForEach');
    expect(result.hasErrors, isTrue);
    expect(
      result.diagnostics.any((d) => d.message.contains('Unexpected')),
      isTrue,
    );
  });

  test('a valid JSON workflow has no diagnostics', () {
    final result = BdfdCompiler().compile(
      r'$jsonParse[{"a":1}]$jsonForEach[]$jsonKey=$jsonValue$endJsonForEach',
    );
    expect(result.diagnostics, isEmpty);
  });
}
