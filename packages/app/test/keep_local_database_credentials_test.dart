import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Map<String, dynamic> local = {
    'databaseConfig': {'type': 'postgres', 'host': 'h', 'password': 'p'},
  };

  test('a redacted remote marker does not erase local credentials', () {
    final Map<String, dynamic> remote = {
      'databaseConfig': {'type': 'postgres', 'encrypted': true},
    };
    final merged = <String, dynamic>{...local}..addAll(remote);
    keepLocalDatabaseCredentials(merged, local, remote);
    expect((merged['databaseConfig'] as Map)['password'], 'p');
  });

  test('a different remote database type wins', () {
    final Map<String, dynamic> remote = {
      'databaseConfig': {'type': 'mysql', 'encrypted': true},
    };
    final merged = <String, dynamic>{...local}..addAll(remote);
    keepLocalDatabaseCredentials(merged, local, remote);
    expect((merged['databaseConfig'] as Map)['type'], 'mysql');
  });
}
