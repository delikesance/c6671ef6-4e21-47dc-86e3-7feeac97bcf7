/// Result bookkeeping for visual actions executed on the native engine.
///
/// The historical handler gives every action list its own `results` map: an
/// action only reads the results of its own list, and a nested block (`ifBlock`)
/// hands its children's results to the parent as `<blockKey>.<childKey>` once
/// the branch finished successfully. Actions also mirror some results into the
/// shared `variables` map. [ResultSink] reproduces exactly those keys.
class ResultSink {
  ResultSink({required this.results, required this.variables});

  /// Results of the list being executed (what `handleActions` returns).
  final Map<String, String> results;

  /// Variables shared by every nesting level.
  final Map<String, String> variables;

  // Nested lists, keyed by the chain of enclosing block keys. A nested list is
  // created on first write and merged into its parent by [commit]; a failed
  // block drops its lists ([discard]) like the historical code never copies the
  // results of a branch that threw.
  final Map<String, List<String>> _paths = {};
  final Map<String, Map<String, String>> _scopes = {};

  /// The last error recorded by [recordError], as the original exception.
  Object? lastError;

  static String _id(List<String> path) => path.join('\u0000');

  /// Results visible to an action living at [path] (empty for the root list).
  /// Reading the root list first publishes the finished nested lists, so a
  /// later top-level action sees `<blockKey>.<childKey>` like it does today.
  Map<String, String> scope(List<String> path) {
    if (path.isEmpty) {
      commit();
      return results;
    }
    final id = _id(path);
    _paths[id] = List.unmodifiable(path);
    return _scopes.putIfAbsent(id, () => <String, String>{});
  }

  /// `results[key] = value` in the list at [path].
  void set(List<String> path, String key, String value) {
    scope(path)[key] = value;
  }

  /// Result sub-field plus its variable mirrors: `results['key.sub']`,
  /// `variables['key.sub']` and, with [actionPrefix], `variables['action.key.sub']`.
  void field(
    List<String> path,
    String key,
    String sub,
    String value, {
    bool actionPrefix = false,
  }) {
    scope(path)['$key.$sub'] = value;
    variables['$key.$sub'] = value;
    if (actionPrefix) variables['action.$key.$sub'] = value;
  }

  /// The historical `recordTrace` quirk: a purely numeric result (a message id,
  /// but also the user id returned by moderation actions) becomes the "last
  /// sent message".
  void noteNumeric(List<String> path, String key) {
    final value = scope(path)[key];
    if (value != null &&
        RegExp(r'^\d+$').hasMatch(value) &&
        !value.startsWith('Error:')) {
      variables['lastSentMessageId'] = value;
      variables['lastMessageId'] = value;
    }
  }

  /// What a failing action leaves behind: the `error.*` variables read by
  /// `((error.message))` and `results[key] = 'Error: ...'`.
  void recordError(
    String command,
    String key,
    List<String> path,
    Object error,
  ) {
    variables['error.message'] = error.toString();
    variables['error.command'] = command;
    variables['error.source'] = '';
    variables['error.row'] = '';
    variables['error.column'] = '';
    scope(path)[key] = 'Error: $error';
    lastError = error;
  }

  /// Publish every finished nested list into its parent, deepest first.
  void commit() {
    if (_scopes.isEmpty) return;
    final ids = _scopes.keys.toList()
      ..sort((a, b) => _paths[b]!.length.compareTo(_paths[a]!.length));
    for (final id in ids) {
      final path = _paths[id]!;
      final child = _scopes.remove(id)!;
      _paths.remove(id);
      final parentPath = path.sublist(0, path.length - 1);
      final parent = parentPath.isEmpty
          ? results
          : _scopes.putIfAbsent(_id(parentPath), () {
              _paths[_id(parentPath)] = List.unmodifiable(parentPath);
              return <String, String>{};
            });
      for (final entry in child.entries) {
        parent['${path.last}.${entry.key}'] = entry.value;
      }
    }
  }

  /// Forget the nested lists of an aborted block (everything at or below
  /// [prefix]), or all of them when omitted.
  void discard([List<String> prefix = const []]) {
    final doomed = [
      for (final entry in _paths.entries)
        if (entry.value.length >= prefix.length &&
            [
              for (var i = 0; i < prefix.length; i++)
                entry.value[i] == prefix[i],
            ].every((same) => same))
          entry.key,
    ];
    for (final id in doomed) {
      _scopes.remove(id);
      _paths.remove(id);
    }
  }
}
