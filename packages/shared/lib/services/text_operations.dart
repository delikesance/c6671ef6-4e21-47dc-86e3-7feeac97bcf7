/// Text operations shared by native BDFD and compiler-generated expressions.
String replaceTextOccurrences(
  String text,
  String sample,
  String replacement, {
  int amount = 1,
}) {
  if (sample.isEmpty || amount == 0 || amount < -1) return text;
  final output = StringBuffer();
  var cursor = 0;
  var replaced = 0;
  while (amount == -1 || replaced < amount) {
    final index = text.indexOf(sample, cursor);
    if (index < 0) break;
    output.write(text.substring(cursor, index));
    output.write(replacement);
    cursor = index + sample.length;
    replaced++;
  }
  output.write(text.substring(cursor));
  return output.toString();
}

class TextSplitState {
  TextSplitState([Iterable<String> values = const []])
    : _values = values.toList();
  final List<String> _values;
  List<String> get values => List.unmodifiable(_values);
  int get length => _values.length;

  void split(String text, String separator) {
    _values
      ..clear()
      ..addAll(text.split(separator));
  }

  String at(String selector) {
    final index = switch (selector.trim()) {
      '<' => 1,
      '>' => length,
      final value => int.tryParse(value),
    };
    return index != null && index > 0 && index <= length
        ? _values[index - 1]
        : '';
  }

  int indexOf(String value) {
    final index = _values.indexOf(value);
    return index < 0 ? -1 : index + 1;
  }

  String join(String separator) => _values.join(separator);
  bool edit(int index, String value) {
    if (index < 1 || index > length) return false;
    _values[index - 1] = value;
    return true;
  }

  bool remove(int index) {
    if (index < 1 || index > length) return false;
    _values.removeAt(index - 1);
    return true;
  }
}
