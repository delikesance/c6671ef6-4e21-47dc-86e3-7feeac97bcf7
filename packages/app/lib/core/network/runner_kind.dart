enum RunnerKind {
  dart,
  javascript,
  auto;

  static RunnerKind fromJson(String? raw) {
    switch ((raw ?? 'auto').trim().toLowerCase()) {
      case 'dart':
        return RunnerKind.dart;
      case 'javascript':
      case 'js':
        return RunnerKind.javascript;
      default:
        return RunnerKind.auto;
    }
  }

  String toJson() {
    switch (this) {
      case RunnerKind.dart:
        return 'dart';
      case RunnerKind.javascript:
        return 'javascript';
      case RunnerKind.auto:
        return 'auto';
    }
  }
}

RunnerKind resolveRunnerKind({
  required RunnerKind configured,
  String? detectedEngine,
}) {
  if (configured != RunnerKind.auto) {
    return configured;
  }
  switch ((detectedEngine ?? '').trim().toLowerCase()) {
    case 'javascript':
    case 'js':
      return RunnerKind.javascript;
    case 'dart':
      return RunnerKind.dart;
    default:
      return RunnerKind.dart;
  }
}
