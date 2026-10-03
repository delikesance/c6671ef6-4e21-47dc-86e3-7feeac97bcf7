import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator_shared/utils/legacy_user_variable_migration.dart';

final _migratingBots = <String>{};

/// Stages compatible scripts without touching variable storage. The version is
/// activated last; a retry accepts only unchanged originals or staged results.
Future<({int commands, int workflows, int calls, String backupPath})>
migrateLocalLegacyUserVariables({
  required AppManager store,
  required String botId,
  required bool Function() isBotRunning,
}) async {
  if (!RegExp(r'^\d{15,22}$').hasMatch(botId)) {
    throw const FormatException('Invalid bot ID');
  }
  if (!_migratingBots.add(botId)) {
    throw StateError('A variable migration is already running for this bot');
  }
  try {
    if (isBotRunning()) {
      throw StateError('Stop the local bot before migrating its scripts');
    }
    final config = await store.getApp(botId);
    if (config.isEmpty) throw StateError('Bot not found');
    final directory = Directory('${await store.path}/apps/$botId');
    final backup = File(
      '${directory.path}/migrations/bdfd-global-user-scripts-v1.json',
    );
    Map<String, dynamic> snapshot;
    if (await backup.exists()) {
      snapshot = Map<String, dynamic>.from(
        jsonDecode(await backup.readAsString()) as Map,
      );
      if (snapshot['version'] != 1 || snapshot['botId'] != botId) {
        throw const FormatException('Invalid script migration archive');
      }
    } else {
      if (config['bdfdUserVariableSemantics'] == 2) {
        throw StateError('This bot already uses official user variable scopes');
      }
      final commands = <String, dynamic>{};
      var calls = 0;
      if (await directory.exists()) {
        await for (final entity in directory.list()) {
          if (entity is! File || !entity.path.endsWith('.json')) continue;
          final before = Map<String, dynamic>.from(
            jsonDecode(await entity.readAsString()) as Map,
          );
          final result = migrateLegacyUserVariableDocument(before);
          calls += result.changes;
          // Include unchanged commands so concurrent edits cannot escape the audit.
          commands[entity.uri.pathSegments.last] = {
            'before': before,
            'after': result.document,
            'changes': result.changes,
          };
        }
      }
      final workflows = config['workflows'] ?? [];
      final result = migrateLegacyUserVariableDocument({
        'workflows': workflows,
      });
      calls += result.changes;
      snapshot = {
        'version': 1,
        'botId': botId,
        'commands': commands,
        'workflowsBefore': workflows,
        'workflowsAfter': result.document['workflows'],
        'workflowChanges': result.changes,
        'calls': calls,
      };
      await backup.parent.create(recursive: true);
      final temporary = File('${backup.path}.tmp');
      await temporary.writeAsString(jsonEncode(snapshot), flush: true);
      await temporary.rename(backup.path);
    }
    final commands = Map<String, dynamic>.from(snapshot['commands'] as Map);
    bool same(dynamic a, dynamic b) => jsonEncode(a) == jsonEncode(b);
    final writes = <({File file, dynamic after})>[];
    // Verify the whole plan before writing any file, including on retries.
    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.endsWith('.json') &&
          !commands.containsKey(entity.uri.pathSegments.last)) {
        throw StateError(
          'Commands changed after the migration archive was created',
        );
      }
    }
    for (final entry in commands.entries) {
      if (entry.key.contains('/') ||
          entry.key.contains('\\') ||
          !entry.key.endsWith('.json')) {
        throw const FormatException('Invalid archived command filename');
      }
      final file = File('${directory.path}/${entry.key}');
      if (!await file.exists()) {
        throw StateError('An archived command was deleted');
      }
      final current = jsonDecode(await file.readAsString());
      final plan = entry.value as Map;
      if (!same(current, plan['before']) && !same(current, plan['after'])) {
        throw StateError(
          'Command ${entry.key} changed after archiving; migration stopped',
        );
      }
      if (!same(current, plan['after'])) {
        writes.add((file: file, after: plan['after']));
      }
    }
    final latest = await store.getApp(botId);
    final currentWorkflows = latest['workflows'] ?? [];
    if (!same(currentWorkflows, snapshot['workflowsBefore']) &&
        !same(currentWorkflows, snapshot['workflowsAfter'])) {
      throw StateError('Workflows changed after archiving; migration stopped');
    }
    if (isBotRunning()) {
      throw StateError('Stop the local bot before migrating its scripts');
    }
    for (final write in writes) {
      final temporary = File('${write.file.path}.migration-tmp');
      await temporary.writeAsString(jsonEncode(write.after), flush: true);
      await temporary.rename(write.file.path);
    }
    final needsSave =
        latest['bdfdUserVariableSemantics'] != 2 ||
        writes.isNotEmpty ||
        !same(currentWorkflows, snapshot['workflowsAfter']);
    latest['workflows'] = snapshot['workflowsAfter'];
    latest['bdfdUserVariableSemantics'] = 2;
    if (isBotRunning()) {
      throw StateError('Bot started during migration; activation stopped');
    }
    // One complete configuration sync, never one sync per rewritten command.
    if (needsSave) await store.saveApp(botId, latest);
    return (
      commands: commands.values.where((plan) => plan['changes'] > 0).length,
      workflows: snapshot['workflowChanges'] > 0 ? 1 : 0,
      calls: snapshot['calls'] as int,
      backupPath: backup.path,
    );
  } finally {
    try {
      await store.invalidatePayloadCache(botId);
    } finally {
      _migratingBots.remove(botId);
    }
  }
}
