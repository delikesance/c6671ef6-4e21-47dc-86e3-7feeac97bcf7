import 'dart:collection';

/// A live view shared by visual variables and native BDFD $var. Values remain
/// ordinary strings; writing through either API is visible to the other.
class RuntimeTemporaryVariables extends MapBase<String, String> {
  RuntimeTemporaryVariables(this.variables);
  final Map<String, String> variables;
  @override
  String? operator [](Object? key) => variables['temp.$key'];
  @override
  void operator []=(String key, String value) => variables['temp.$key'] = value;
  @override
  Iterable<String> get keys => variables.keys
      .where((key) => key.startsWith('temp.'))
      .map((key) => key.substring(5));
  @override
  String? remove(Object? key) => variables.remove('temp.$key');
  @override
  void clear() => variables.removeWhere((key, _) => key.startsWith('temp.'));
}
