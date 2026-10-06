import 'dart:async';

class CommandExecutionTimeout implements Exception {
  const CommandExecutionTimeout(this.limit);
  final Duration limit;
  @override
  String toString() => 'Command execution exceeded ${limit.inSeconds} seconds';
}

/// One monotonic deadline shared by all nested actions in an invocation.
class CommandExecutionBudget {
  CommandExecutionBudget({this.limit = const Duration(minutes: 15)}) {
    _watch.start();
  }
  final Duration limit;
  final _watch = Stopwatch();
  bool _cancelled = false;
  Duration get elapsed => _watch.elapsed;
  int get elapsedMilliseconds => _watch.elapsedMilliseconds;
  void check() {
    if (_cancelled || _watch.elapsed >= limit) {
      _cancelled = true;
      throw CommandExecutionTimeout(limit);
    }
  }

  Future<T> run<T>(Future<T> Function() operation) async {
    check();
    return operation().timeout(
      limit - _watch.elapsed,
      onTimeout: () {
        _cancelled = true;
        throw CommandExecutionTimeout(limit);
      },
    );
  }
}
