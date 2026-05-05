import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Utilities for generating stable hashes of data structures.
class HashUtil {
  /// Generates a stable SHA-256 hash of a JSON-encodable object.
  /// 
  /// The object is first encoded to a canonical JSON string (with sorted keys)
  /// to ensure that the same logical data always produces the same hash.
  static String calculateHash(dynamic data) {
    final canonicalJson = _toCanonicalJson(data);
    final bytes = utf8.encode(canonicalJson);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Recursively sorts map keys to produce a canonical JSON representation.
  static String _toCanonicalJson(dynamic data) {
    if (data is Map) {
      final sortedKeys = data.keys.map((k) => k.toString()).toList()..sort();
      final buffer = StringBuffer('{');
      for (var i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        if (i > 0) buffer.write(',');
        buffer.write(jsonEncode(key));
        buffer.write(':');
        buffer.write(_toCanonicalJson(data[key]));
      }
      buffer.write('}');
      return buffer.toString();
    } else if (data is List) {
      final buffer = StringBuffer('[');
      for (var i = 0; i < data.length; i++) {
        if (i > 0) buffer.write(',');
        buffer.write(_toCanonicalJson(data[i]));
      }
      buffer.write(']');
      return buffer.toString();
    } else {
      return jsonEncode(data);
    }
  }
}
