import 'dart:convert';

import 'package:bot_creator/features/bot_editor/logic/embed_normalization.dart';
import 'package:bot_creator_shared/utils/command_migration.dart' as migration;
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';

Map<String, dynamic> normalizeCommandData(Map<String, dynamic> command) {
  var normalized = Map<String, dynamic>.from(command);

  // Auto-heal: If the file was corrupted by a buggy migration (missing the root 'data' sub-map
  // but containing actions or response blocks), we nest the root keys under 'data' and
  // attempt to recover the name and other metadata fields.
  if (normalized['data'] == null &&
      (normalized['actions'] != null ||
          normalized['response'] != null ||
          normalized['legacyPrefixOverride'] != null ||
          normalized['legacyAliases'] != null ||
          normalized['script'] != null ||
          normalized['type']?.toString() == 'command')) {
    final healedData = Map<String, dynamic>.from(normalized);
    normalized.clear();
    normalized['data'] = healedData;

    final prefixOverride = (healedData['legacyPrefixOverride'] ?? '')
        .toString()
        .trim();
    if (prefixOverride.isNotEmpty) {
      normalized['name'] = prefixOverride;
    }
  }

  final rawData = Map<String, dynamic>.from(
    (normalized['data'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
  final rawCommandType =
      (rawData['commandType'] ?? normalized['type'] ?? 'chatInput')
          .toString()
          .trim()
          .toLowerCase();
  final commandType =
      (rawCommandType == 'user' ||
          rawCommandType == 'usercommand' ||
          rawCommandType == 'user_command')
      ? 'user'
      : (rawCommandType == 'message' ||
            rawCommandType == 'messagecommand' ||
            rawCommandType == 'message_command')
      ? 'message'
      : 'chatInput';

  final legacyResponse = rawData['response'];
  final response = Map<String, dynamic>.from(
    (legacyResponse is Map)
        ? legacyResponse.cast<String, dynamic>()
        : {
            'mode': 'message',
            'text': legacyResponse?.toString() ?? '',
            'embeds': <Map<String, dynamic>>[],
          },
  );

  final embeds = normalizeResponseEmbedsPayload(
    response['embeds'],
    legacySingleEmbed: response['embed'],
    deepNormalize: false,
  );

  final actions = (rawData['actions'] is List)
      ? List<Map<String, dynamic>>.from(
          (rawData['actions'] as List).whereType<Map>().map(
            (action) => Map<String, dynamic>.from(action),
          ),
        )
      : <Map<String, dynamic>>[];

  final options = (rawData['options'] is List)
      ? List<Map<String, dynamic>>.from(
          (rawData['options'] as List).whereType<Map>().map(
            (option) => Map<String, dynamic>.from(
              jsonDecode(jsonEncode(option)) as Map,
            ),
          ),
        )
      : <Map<String, dynamic>>[];

  final normalizedSubcommandWorkflows = <String, Map<String, dynamic>>{};
  final rawSubcommandWorkflows = rawData['subcommandWorkflows'];
  if (rawSubcommandWorkflows is Map) {
    rawSubcommandWorkflows.forEach((route, payload) {
      if (payload is! Map) {
        return;
      }
      final routeKey = route.toString().trim();
      if (routeKey.isEmpty) {
        return;
      }
      normalizedSubcommandWorkflows[routeKey] = Map<String, dynamic>.from(
        (jsonDecode(jsonEncode(payload)) as Map).cast<String, dynamic>(),
      );
    });
  }

  final requestedActiveSubcommandRoute =
      (rawData['activeSubcommandRoute'] ?? '').toString().trim();
  final normalizedActiveSubcommandRoute =
      normalizedSubcommandWorkflows.containsKey(requestedActiveSubcommandRoute)
      ? requestedActiveSubcommandRoute
      : (normalizedSubcommandWorkflows.isNotEmpty
            ? normalizedSubcommandWorkflows.keys.first
            : '');

  const editorMode = 'advanced';
  final rawExecutionMode = (rawData['executionMode'] ?? 'workflow')
      .toString()
      .toLowerCase();
  var executionMode = rawExecutionMode == 'bdfd_script'
      ? 'bdfd_script'
      : rawExecutionMode == 'javascript'
      ? 'javascript'
      : 'workflow';
  final bdfdScriptContent = (rawData['bdfdScriptContent'] ?? '').toString();
  final jsScriptContent =
      (rawData['jsScriptContent'] ?? rawData['script'] ?? '').toString();
  if (jsScriptContent.isNotEmpty &&
      executionMode == 'workflow' &&
      (rawData.containsKey('script') || rawData['type'] == 'command')) {
    executionMode = 'javascript';
  }
  final legacyModeEnabled = rawData['legacyModeEnabled'] == true;
  final legacyLocalOnly = rawData['legacyLocalOnly'] == true;
  final legacyPrefixOverride = (rawData['legacyPrefixOverride'] ?? '')
      .toString()
      .trim();
  final rawLegacyResponseTarget = (rawData['legacyResponseTarget'] ?? 'reply')
      .toString()
      .trim();
  final legacyResponseTarget = rawLegacyResponseTarget == 'channelSend'
      ? 'channelSend'
      : 'reply';
  // Plusieurs mots déclencheurs possibles pour une commande message : les alias
  // sont normalisés (casse, préfixe `!`, doublons, limites) côté shared.
  final legacyAliases = normalizeLegacyCommandAliases(rawData['legacyAliases']);

  final simpleConfig = <String, dynamic>{};

  final rawWorkflow = Map<String, dynamic>.from(
    (response['workflow'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
  final rawConditional = Map<String, dynamic>.from(
    (rawWorkflow['conditional'] as Map?)?.cast<String, dynamic>() ?? const {},
  );

  final normalizedWorkflow = <String, dynamic>{
    'autoDeferIfActions': rawWorkflow['autoDeferIfActions'] != false,
    'visibility':
        (rawWorkflow['visibility']?.toString().toLowerCase() == 'ephemeral')
        ? 'ephemeral'
        : 'public',
    'onError': 'edit_error',
    'conditional': {
      'enabled': rawConditional['enabled'] == true,
      'variable': (rawConditional['variable'] ?? '').toString(),
      'whenTrueType': (rawConditional['whenTrueType'] ?? 'message').toString(),
      'whenFalseType': (rawConditional['whenFalseType'] ?? 'message')
          .toString(),
      'whenTrueText': (rawConditional['whenTrueText'] ?? '').toString(),
      'whenFalseText': (rawConditional['whenFalseText'] ?? '').toString(),
      'whenTrueEmbeds': (rawConditional['whenTrueEmbeds'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      'whenFalseEmbeds': (rawConditional['whenFalseEmbeds'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      'whenTrueNormalComponents': Map<String, dynamic>.from(
        (rawConditional['whenTrueNormalComponents'] as Map?)
                ?.cast<String, dynamic>() ??
            const {},
      ),
      'whenFalseNormalComponents': Map<String, dynamic>.from(
        (rawConditional['whenFalseNormalComponents'] as Map?)
                ?.cast<String, dynamic>() ??
            const {},
      ),
      'whenTrueComponents': Map<String, dynamic>.from(
        (rawConditional['whenTrueComponents'] as Map?)
                ?.cast<String, dynamic>() ??
            const {},
      ),
      'whenFalseComponents': Map<String, dynamic>.from(
        (rawConditional['whenFalseComponents'] as Map?)
                ?.cast<String, dynamic>() ??
            const {},
      ),
      'whenTrueModal': Map<String, dynamic>.from(
        (rawConditional['whenTrueModal'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
      'whenFalseModal': Map<String, dynamic>.from(
        (rawConditional['whenFalseModal'] as Map?)?.cast<String, dynamic>() ??
            const {},
      ),
    },
  };

  // Preserve folder at root level (empty string = uncategorized).
  final folder = (normalized['folder'] ?? '').toString().trim();

  normalized['type'] = commandType;
  if (folder.isNotEmpty) normalized['folder'] = folder;
  normalized['data'] = {
    'version': 1,
    'commandType': commandType,
    'editorMode': editorMode,
    'executionMode': executionMode,
    'bdfdScriptContent': bdfdScriptContent,
    'jsScriptContent': jsScriptContent,
    'legacyModeEnabled': legacyModeEnabled,
    'legacyLocalOnly': legacyLocalOnly,
    'legacyPrefixOverride': legacyPrefixOverride,
    'legacyResponseTarget': legacyResponseTarget,
    'legacyAliases': legacyAliases,
    'simpleConfig': simpleConfig,
    'defaultMemberPermissions': (rawData['defaultMemberPermissions'] ?? '')
        .toString()
        .trim(),
    'response': _normalizeResponseStrict({
      'mode':
          ((response['mode'] == 'text' ||
              response['mode'] == 'normal' ||
              response['mode'] == 'embed')
          ? 'message'
          : (response['mode'] ?? 'message')),
      'text': (response['text'] ?? '').toString(),
      'type': 'normal',
      'embeds': embeds.take(10).toList(),
      'components': Map<String, dynamic>.from(
        (response['components'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      'modal': Map<String, dynamic>.from(
        (response['modal'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      'workflow': normalizedWorkflow,
    }),
    'actions': actions,
    if (options.isNotEmpty) 'options': options,
    if (normalizedSubcommandWorkflows.isNotEmpty)
      'subcommandWorkflows': normalizedSubcommandWorkflows,
    if (normalizedSubcommandWorkflows.isNotEmpty)
      'activeSubcommandRoute': normalizedActiveSubcommandRoute,
  };

  // Transparently migrate legacy response blocks into inline actions.
  final normalizedData = normalized['data'];
  if (normalizedData is Map<String, dynamic>) {
    migration.migrateCommandDataResponse(normalizedData);
  }

  return normalized;
}

/// Enforces strict response mode partitioning by purging irrelevant parameters.
/// This ensures that Message, ComponentV2, and Modal payloads are mutually exclusive.
Map<String, dynamic> _normalizeResponseStrict(Map<String, dynamic> response) {
  final mode = (response['mode'] ?? 'message').toString();
  final type = (response['type'] ?? 'normal').toString();
  final result = Map<String, dynamic>.from(response);

  if (mode == 'modal') {
    // Pure Modal: Clear all message/component fields
    result.remove('text');
    result.remove('embeds');
    result.remove('components');
  } else if (mode == 'componentV2' || type == 'componentV2') {
    // ComponentV2 Mode: Clear embeds and modal, keep text (as content) and components
    result.remove('embeds');
    result.remove('modal');
  } else {
    // Normal Message Mode: Clear modal, keep text, embeds, and components
    result.remove('modal');
  }

  return result;
}
