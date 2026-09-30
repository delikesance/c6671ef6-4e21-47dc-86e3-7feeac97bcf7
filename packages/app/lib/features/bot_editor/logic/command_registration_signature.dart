import 'dart:convert';

import 'package:nyxx/nyxx.dart';

/// Only fields sent to Discord, excluding execution and autocomplete workflows.
String commandRegistrationSignature({
  required String name,
  required String description,
  required ApplicationCommandType type,
  required List<CommandOptionBuilder> options,
  required Permissions? permissions,
  required List<ApplicationIntegrationType> integrationTypes,
  required List<InteractionContextType> contexts,
}) {
  final integrations = integrationTypes.map((e) => e.value).toList()..sort();
  final contextValues = contexts.map((e) => e.value).toList()..sort();
  return jsonEncode({
    'name': name,
    'type': type.value,
    if (type == ApplicationCommandType.chatInput) ...{
      'description': description,
      'options': options.map((e) => e.build()).toList(),
    },
    'permissions': permissions?.value.toString(),
    'integrations': integrations,
    'contexts': contextValues,
  });
}
