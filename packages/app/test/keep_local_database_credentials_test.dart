import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  lavalinkImportTests();
  automationDefinitionsTests();
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

  test('an empty local copy adopts the remote hint that a copy exists', () {
    final Map<String, dynamic> emptyLocal = {
      'databaseConfig': {'type': 'mongo', 'uri': '', 'password': ''},
    };
    final Map<String, dynamic> remote = {
      'databaseConfig': {
        'type': 'mongo',
        'encrypted': true,
        'hasCredentials': true,
      },
    };
    final merged = <String, dynamic>{...emptyLocal}..addAll(remote);
    keepLocalDatabaseCredentials(merged, emptyLocal, remote);
    expect((merged['databaseConfig'] as Map)['hasCredentials'], true);
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

void automationDefinitionsTests() {
  test('local webhook endpoints and local-only globals survive a pull', () {
    final Map<String, dynamic> local = {
      'inboundWebhooks': [
        {'id': 'h1', 'path': '/a'},
      ],
      'globalVariables': {'mine': 1, 'both': 'local'},
    };
    final Map<String, dynamic> remote = {
      'inboundWebhooks': true,
      'globalVariables': {'both': 'remote'},
    };
    final merged = <String, dynamic>{...local}..addAll(remote);
    keepLocalAutomationDefinitions(merged, local, remote);
    expect((merged['inboundWebhooks'] as List).single['id'], 'h1');
    expect(merged['globalVariables'], {'mine': 1, 'both': 'remote'});
  });

  test('a remote endpoint list is adopted only when nothing is local', () {
    final Map<String, dynamic> remote = {
      'inboundWebhooks': false,
      'inboundWebhookEndpoints': [
        {'id': 'r1', 'path': '/r'},
      ],
    };
    final merged = <String, dynamic>{}..addAll(remote);
    keepLocalAutomationDefinitions(merged, <String, dynamic>{}, remote);
    expect((merged['inboundWebhooks'] as List).single['id'], 'r1');
  });
}

void lavalinkImportTests() {
  test(
    'remote lavalink is adopted only when nothing is configured locally',
    () {
      final Map<String, dynamic> remote = {
        'lavalink': {'enabled': true, 'custom_servers': []},
      };
      final merged = <String, dynamic>{}..addAll(remote);
      keepLocalAutomationDefinitions(merged, <String, dynamic>{}, remote);
      expect((merged['lavalinkConfig'] as Map)['enabled'], true);

      final Map<String, dynamic> local = {
        'lavalinkConfig': {'enabled': true, 'host': 'mine'},
      };
      final merged2 = <String, dynamic>{...local}..addAll(remote);
      keepLocalAutomationDefinitions(merged2, local, remote);
      expect((merged2['lavalinkConfig'] as Map)['host'], 'mine');
    },
  );
}
