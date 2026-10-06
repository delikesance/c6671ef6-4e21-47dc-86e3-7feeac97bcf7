import 'dart:convert';

// ── Runtime JSON helpers ────────────────────────────────────────────────────

dynamic _getPath(dynamic root, List<String> path) {
  dynamic current = root;
  for (final segment in path) {
    final index = int.tryParse(segment);
    if (index != null && current is List) {
      if (index < 0 || index >= current.length) return null;
      current = current[index];
    } else if (current is Map) {
      if (!current.containsKey(segment)) return null;
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

bool _pathExists(dynamic root, List<String> path) {
  dynamic current = root;
  for (final segment in path) {
    final index = int.tryParse(segment);
    if (index != null && current is List) {
      if (index < 0 || index >= current.length) return false;
      current = current[index];
    } else if (current is Map) {
      if (!current.containsKey(segment)) return false;
      current = current[segment];
    } else {
      return false;
    }
  }
  return true;
}

dynamic _setPath(dynamic root, List<String> path, dynamic value) {
  if (path.isEmpty) return value;
  final nextIsNumeric = int.tryParse(path.first) != null;
  root ??= nextIsNumeric ? <dynamic>[] : <String, dynamic>{};
  dynamic current = root;
  for (var i = 0; i < path.length - 1; i++) {
    final segment = path[i];
    final index = int.tryParse(segment);
    final nextSegment = path[i + 1];
    final nextIndex = int.tryParse(nextSegment);
    if (index != null) {
      if (current is! List || index < 0) return root;
      while (current.length <= index) {
        current.add(null);
      }
      current[index] ??= nextIndex != null ? <dynamic>[] : <String, dynamic>{};
      current = current[index];
    } else if (current is Map) {
      if (!current.containsKey(segment) || current[segment] == null) {
        current[segment] = nextIndex != null
            ? <dynamic>[]
            : <String, dynamic>{};
      }
      current = current[segment];
    } else {
      return root;
    }
  }
  final lastSegment = path.last;
  final lastIndex = int.tryParse(lastSegment);
  if (lastIndex != null) {
    if (current is! List || lastIndex < 0) return root;
    while (current.length <= lastIndex) {
      current.add(null);
    }
    current[lastIndex] = value;
  } else if (current is Map) {
    current[lastSegment] = value;
  }
  return root;
}

dynamic _removePath(dynamic root, List<String> path) {
  if (path.isEmpty) return null;
  dynamic current = root;
  for (var i = 0; i < path.length - 1; i++) {
    final segment = path[i];
    final index = int.tryParse(segment);
    if (index != null && current is List) {
      if (index < 0 || index >= current.length) return root;
      current = current[index];
    } else if (current is Map) {
      if (!current.containsKey(segment)) return root;
      current = current[segment];
    } else {
      return root;
    }
  }
  final lastSegment = path.last;
  final lastIndex = int.tryParse(lastSegment);
  if (lastIndex != null && current is List) {
    if (lastIndex >= 0 && lastIndex < current.length) {
      current.removeAt(lastIndex);
    }
  } else if (current is Map) {
    current.remove(lastSegment);
  }
  return root;
}

dynamic coerceJsonValue(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
    try {
      return jsonDecode(trimmed);
    } catch (_) {}
  }
  if (trimmed.toLowerCase() == 'true') return true;
  if (trimmed.toLowerCase() == 'false') return false;
  if (trimmed.toLowerCase() == 'null') return null;
  final asInt = int.tryParse(trimmed);
  if (asInt != null) return asInt;
  final asDouble = double.tryParse(trimmed);
  if (asDouble != null) return asDouble;
  return raw;
}

String stringifyJsonValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is num || value is bool) return value.toString();
  return jsonEncode(value);
}

/// JSON operations shared by native BDFD and visual JSON blocks.
enum JsonOperation {
  get,
  set,
  unset,
  clear,
  exists,
  stringify,
  pretty,
  initArray,
  arrayAppend,
  arrayUnshift,
  arrayPop,
  arrayShift,
  arraySort,
  arrayReverse,
  arrayCount,
  arrayIndex,
  joinArray,
  keys,
}

class JsonDocument {
  JsonDocument([this.value]);

  /// Match the runtime's recovery for empty, corrupt or scalar stored values.
  factory JsonDocument.fromSource(String source) {
    dynamic value;
    try {
      value = jsonDecode(source);
    } catch (_) {}
    return JsonDocument(
      value is Map || value is List ? value : <String, dynamic>{},
    );
  }

  dynamic value;

  dynamic get(List<String> path) => _getPath(value, path);

  /// Freeze keys and text values before a loop starts. Mutating the document
  /// cannot extend an active iteration or reinterpret values as source.
  List<MapEntry<String, String>> iterationSnapshot(List<String> path) {
    final collection = get(path);
    if (collection is Map) {
      return List.unmodifiable(
        collection.entries.map(
          (entry) =>
              MapEntry(entry.key.toString(), stringifyJsonValue(entry.value)),
        ),
      );
    }
    if (collection is List) {
      return List.unmodifiable([
        for (var index = 0; index < collection.length; index++)
          MapEntry('$index', stringifyJsonValue(collection[index])),
      ]);
    }
    return const [];
  }

  bool exists(List<String> path) => _pathExists(value, path);
  String stringify() => value == null ? '' : jsonEncode(value);

  void set(List<String> path, dynamic next) {
    value = _setPath(value, path, next);
  }

  List<dynamic> _array(List<String> path) {
    final current = get(path);
    if (current is List<dynamic>) return current;
    set(path, <dynamic>[]);
    final resolved = get(path);
    return resolved is List<dynamic> ? resolved : <dynamic>[];
  }

  /// Mutations return null; reads return text ready for the calling language.
  String? apply(
    JsonOperation operation, {
    List<String> path = const [],
    String value = '',
    bool forceString = false,
    String separator = ',',
    bool descending = false,
    int? indent,
  }) {
    switch (operation) {
      case JsonOperation.get:
        return stringifyJsonValue(get(path));
      case JsonOperation.set:
        set(path, forceString ? value : coerceJsonValue(value));
      case JsonOperation.unset:
        this.value = _removePath(this.value, path);
      case JsonOperation.clear:
        this.value = <String, dynamic>{};
      case JsonOperation.exists:
        return '${exists(path)}';
      case JsonOperation.stringify:
        return stringify();
      case JsonOperation.pretty:
        final spaces = indent == null || indent < 0 ? 2 : indent;
        // Preserve two-space occurrences within string values.
        return this.value == null
            ? ''
            : JsonEncoder.withIndent(' ' * spaces).convert(this.value);
      case JsonOperation.initArray:
        final current = get(path);
        if (current is String && current.isNotEmpty) {
          set(
            path,
            separator.isEmpty ? <dynamic>[current] : current.split(separator),
          );
        } else if (current is! List) {
          set(path, <dynamic>[]);
        }
      case JsonOperation.arrayAppend:
        _array(path).add(coerceJsonValue(value));
      case JsonOperation.arrayUnshift:
        _array(path).insert(0, coerceJsonValue(value));
      case JsonOperation.arrayPop:
        final list = _array(path);
        return list.isEmpty ? '' : stringifyJsonValue(list.removeLast());
      case JsonOperation.arrayShift:
        final list = _array(path);
        return list.isEmpty ? '' : stringifyJsonValue(list.removeAt(0));
      case JsonOperation.arraySort:
        _array(path).sort((a, b) {
          final aNum = a is num ? a : num.tryParse(a.toString());
          final bNum = b is num ? b : num.tryParse(b.toString());
          if (aNum != null && bNum != null) {
            return descending ? bNum.compareTo(aNum) : aNum.compareTo(bNum);
          }
          if (aNum != null) return descending ? 1 : -1;
          if (bNum != null) return descending ? -1 : 1;
          return descending
              ? b.toString().compareTo(a.toString())
              : a.toString().compareTo(b.toString());
        });
      case JsonOperation.arrayReverse:
        final list = _array(path);
        final reversed = list.reversed.toList(growable: false);
        list
          ..clear()
          ..addAll(reversed);
      case JsonOperation.arrayCount:
        final list = get(path);
        return list is List ? '${list.length}' : '0';
      case JsonOperation.arrayIndex:
        final list = get(path);
        return list is List
            ? '${list.indexWhere((item) => item == coerceJsonValue(value))}'
            : '-1';
      case JsonOperation.joinArray:
        final list = get(path);
        return list is List ? list.map(stringifyJsonValue).join(separator) : '';
      case JsonOperation.keys:
        final map = get(path);
        return map is Map
            ? map.keys.map((key) => key.toString()).join(separator)
            : '';
    }
    return null;
  }
}
