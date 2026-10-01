import 'package:bot_creator/core/utils/hash_util.dart';

/// Strips all `description` keys recursively from a JSON schema object or map.
dynamic stripSchemaDescriptions(dynamic value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        if (entry.key != 'description')
          entry.key: stripSchemaDescriptions(entry.value),
    };
  }
  if (value is List) {
    return value.map(stripSchemaDescriptions).toList();
  }
  return value;
}

/// The manager supplies the provider's schemas. Use its schema only when every
/// argument it allows is also understood by this application's implementation.
bool copilotToolCompatible(Map local, Map remote) {
  if (local['name'] != remote['name'] ||
      local['mutating'] != remote['mutating']) {
    return false;
  }
  final clientSchema = local['inputSchema'];
  final serverSchema = remote['inputSchema'];
  if (clientSchema is! Map || serverSchema is! Map) return false;
  if (HashUtil.calculateHash(stripSchemaDescriptions(clientSchema)) ==
      HashUtil.calculateHash(stripSchemaDescriptions(serverSchema))) {
    return true;
  }
  if (clientSchema['type'] != 'object' ||
      serverSchema['type'] != 'object' ||
      clientSchema['additionalProperties'] != false ||
      serverSchema['additionalProperties'] != false) {
    return false;
  }
  final clientProperties = clientSchema['properties'];
  final serverProperties = serverSchema['properties'];
  if (clientProperties is! Map || serverProperties is! Map) return false;
  final serverRequired = serverSchema['required'] as List? ?? const [];
  if (!(clientSchema['required'] as List? ?? const []).every(
    serverRequired.contains,
  )) {
    return false;
  }
  // Only an additive set of optional client parameters is compatible.
  return serverProperties.entries.every(
    (e) =>
        clientProperties.containsKey(e.key) &&
        _propertyCompatible(clientProperties[e.key], e.value),
  );
}

bool _propertyCompatible(dynamic local, dynamic remote) {
  final localNormalized = stripSchemaDescriptions(local);
  final remoteNormalized = stripSchemaDescriptions(remote);
  if (HashUtil.calculateHash(localNormalized) ==
      HashUtil.calculateHash(remoteNormalized)) {
    return true;
  }
  if (local is! Map || remote is! Map) return false;
  final localChoices = localNormalized['enum'];
  final remoteChoices = remoteNormalized['enum'];
  if (localChoices is! List || remoteChoices is! List) return false;
  // An older server may offer fewer enum values. Every value it can supply
  // must remain supported by this client; never accept the reverse widening.
  final localRest = Map.of(localNormalized)..remove('enum');
  final remoteRest = Map.of(remoteNormalized)..remove('enum');
  return HashUtil.calculateHash(localRest) ==
          HashUtil.calculateHash(remoteRest) &&
      remoteChoices.every(
        (choice) => localChoices.any(
          (supported) =>
              HashUtil.calculateHash(choice) ==
              HashUtil.calculateHash(supported),
        ),
      );
}

List<Map<String, dynamic>> negotiateCopilotTools(
  List<Map<String, dynamic>> local,
  List remote,
) {
  final server = {for (final t in remote.whereType<Map>()) t['name']: t};
  return [
    for (final tool in local)
      if (server[tool['name']] case final Map candidate)
        if (copilotToolCompatible(tool, candidate))
          {...tool, 'inputSchema': candidate['inputSchema']},
  ];
}
