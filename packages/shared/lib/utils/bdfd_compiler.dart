import '../engine/bdfd/engine.dart';
import '../engine/bdfd/program.dart';
import 'bdfd_ast.dart';
import 'bdfd_lexer.dart';
import 'bdfd_parser.dart';

enum BdfdCompileDiagnosticSeverity { warning, error }

/// `native` diagnostics come from the native-v1 engine's preparation step,
/// which validates every function call without performing any effect.
enum BdfdCompileDiagnosticStage { lexer, parser, native }

class BdfdCompileDiagnostic {
  const BdfdCompileDiagnostic({
    required this.message,
    required this.severity,
    required this.stage,
    this.start,
    this.end,
    this.line,
    this.column,
    this.functionName,
  });

  final String message;
  final BdfdCompileDiagnosticSeverity severity;
  final BdfdCompileDiagnosticStage stage;
  final int? start;
  final int? end;
  final int? line;
  final int? column;
  final String? functionName;
}

class BdfdCompileResult {
  const BdfdCompileResult({
    required this.source,
    this.lexerResult,
    this.parserResult,
    this.ast,
    required this.diagnostics,
  });

  final String source;
  final BdfdLexerResult? lexerResult;
  final BdfdParserResult? parserResult;
  final BdfdScriptAst? ast;
  final List<BdfdCompileDiagnostic> diagnostics;

  bool get hasErrors => diagnostics.any(
    (diagnostic) => diagnostic.severity == BdfdCompileDiagnosticSeverity.error,
  );

  BdfdCompileResult toLightweight() =>
      BdfdCompileResult(source: source, diagnostics: diagnostics);
}

/// Validates BDFD source for the editor and Copilot. Nothing is executed or
/// converted to visual actions: native-v1 interprets the AST at run time.
class BdfdCompiler {
  BdfdCompiler({this.legacyUserVariables = false});

  /// Selects the historical user-variable semantics (BDFD variables v1).
  final bool legacyUserVariables;
  static final Map<String, BdfdCompileResult> _cache = {};
  static final BdfdEngine _validator = BdfdEngine.validation();

  static void clearCache() => _cache.clear();

  BdfdCompileResult compile(String source) {
    final cacheKey = '${legacyUserVariables ? 1 : 2}:$source';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;
    final lexerResult = BdfdLexer().tokenize(source);
    final parserResult = BdfdParser().parseTokens(lexerResult.tokens);
    final diagnostics = <BdfdCompileDiagnostic>[
      for (final d in lexerResult.diagnostics)
        BdfdCompileDiagnostic(
          message: d.message,
          severity: BdfdCompileDiagnosticSeverity.error,
          stage: BdfdCompileDiagnosticStage.lexer,
          start: d.start,
          end: d.end,
          line: d.line,
          column: d.column,
        ),
      for (final d in parserResult.diagnostics)
        BdfdCompileDiagnostic(
          message: d.message,
          severity: BdfdCompileDiagnosticSeverity.error,
          stage: BdfdCompileDiagnosticStage.parser,
          start: d.start,
          end: d.end,
          line: d.line,
          column: d.column,
        ),
    ];
    if (diagnostics.isEmpty) {
      try {
        _validator.prepare(source);
      } on BdfdNativeError catch (error) {
        diagnostics.add(
          BdfdCompileDiagnostic(
            message: error.message,
            severity: BdfdCompileDiagnosticSeverity.error,
            stage: BdfdCompileDiagnosticStage.native,
            start: error.location.offset,
            line: error.location.line,
            column: error.location.column,
            functionName: error.location.functionName,
          ),
        );
      } on FormatException catch (error) {
        diagnostics.add(
          BdfdCompileDiagnostic(
            message: error.message,
            severity: BdfdCompileDiagnosticSeverity.error,
            stage: BdfdCompileDiagnosticStage.native,
          ),
        );
      }
    }
    final result = BdfdCompileResult(
      source: source,
      lexerResult: lexerResult,
      parserResult: parserResult,
      ast: parserResult.ast,
      diagnostics: List<BdfdCompileDiagnostic>.unmodifiable(diagnostics),
    );
    if (_cache.length > 500) _cache.clear();
    _cache[cacheKey] = result.toLightweight();
    return result;
  }
}
