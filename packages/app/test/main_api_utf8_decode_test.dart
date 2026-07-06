import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('utf8 bodyBytes round-trip preserves unicode config text', () {
    const sample = <String, dynamic>{
      'name': 'Bot café',
      'description': 'émoji 🎮 et accents',
    };
    final bytes = utf8.encode(jsonEncode(sample));
    final response = http.Response.bytes(bytes, 200);

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    expect(decoded['name'], 'Bot café');
    expect(decoded['description'], 'émoji 🎮 et accents');
  });
}
