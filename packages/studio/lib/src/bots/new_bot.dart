import 'dart:convert';

/// Un jeton de bot Discord commence par l'identifiant du bot en base64.
/// Sert de repli quand le serveur ne rend pas l'identifiant à la validation.
String? botIdFromToken(String token) {
  final first = token.trim().split('.').first;
  if (first.isEmpty) return null;
  try {
    final decoded = utf8.decode(base64.decode(base64.normalize(first)));
    return RegExp(r'^\d{15,25}$').hasMatch(decoded) ? decoded : null;
  } catch (_) {
    return null;
  }
}

/// Commande `/ping` d'exemple, identique à celle que crée l'app.
Map<String, dynamic> samplePingCommand({DateTime? now}) {
  final at = (now ?? DateTime.now()).toUtc();
  final stamp = at.toIso8601String();
  return {
    'name': 'ping',
    'description': 'Check if the bot is responsive',
    'type': 'chatInput',
    'id': 'sample_ping_${at.millisecondsSinceEpoch}',
    'createdAt': stamp,
    'updatedAt': stamp,
    'data': {
      'version': 1,
      'commandType': 'chatInput',
      'editorMode': 'advanced',
      'executionMode': 'workflow',
      'bdfdScriptContent': '',
      'jsScriptContent': '',
      'legacyModeEnabled': false,
      'legacyLocalOnly': false,
      'legacyPrefixOverride': '',
      'legacyResponseTarget': 'reply',
      'simpleConfig': <String, dynamic>{},
      'defaultMemberPermissions': '',
      'actions': [
        {
          'type': 'respondWithMessage',
          'key': 'sample_ping_response',
          'enabled': true,
          'payload': {
            'content': 'Pong!',
            'embeds': <dynamic>[],
            'components': <String, dynamic>{},
            'ephemeral': false,
            'replyToMessage': false,
          },
        },
      ],
    },
  };
}

/// Config minimale d'un nouveau bot (`BotConfig.toJson` de l'app avec ses
/// valeurs par défaut). Le jeton n'y figure PAS : il voyage à part, dans le
/// champ `bot_token` de la requête. Sans aucune famille remplie, la garde de
/// l'app refuserait la charge utile : la commande d'exemple y répond.
Map<String, dynamic> newBotConfig({
  required String username,
  bool withSamplePing = true,
}) => {
  'prefix': '!',
  'builtInLegacyHelpEnabled': true,
  'inboundWebhooks': false,
  'autoSharding': false,
  'autoRestart': false,
  if (username.trim().isNotEmpty) 'username': username.trim(),
  'intents': <String, dynamic>{},
  'globalVariables': <String, dynamic>{},
  'scopedVariables': <String, dynamic>{},
  'scopedVariableDefinitions': <dynamic>[],
  'bdfdUserVariableSemantics': 2,
  'workflows': <dynamic>[],
  'scheduledTriggers': <dynamic>[],
  'inboundWebhookEndpoints': <dynamic>[],
  'statuses': <dynamic>[],
  'presenceStatus': 'online',
  'commands': [if (withSamplePing) samplePingCommand()],
};
