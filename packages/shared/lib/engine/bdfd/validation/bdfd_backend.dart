// Web-safe: no dependency on nyxx, dart:io or the engine registry.

enum BdfdBackend {
  // Must equal `BdfdEngine.backendId`; a shared test pins the two together.
  native('native-v1');

  const BdfdBackend(this.id);
  final String id;

  /// `native-v1` is the only BDFD backend. Absent values select it; any other
  /// version is rejected before effects instead of being guessed.
  static BdfdBackend parse(Object? value) {
    if (value == null || value == '') return native;
    for (final backend in values) {
      if (value == backend.id) return backend;
    }
    throw FormatException('Unknown BDFD backend: $value');
  }
}
