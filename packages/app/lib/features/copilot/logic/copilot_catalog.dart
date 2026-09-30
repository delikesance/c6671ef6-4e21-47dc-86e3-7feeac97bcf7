import 'package:bot_creator/core/utils/hash_util.dart';

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
  if (HashUtil.calculateHash(clientSchema) ==
      HashUtil.calculateHash(serverSchema)) {
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
        HashUtil.calculateHash(e.value) ==
            HashUtil.calculateHash(clientProperties[e.key]),
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
