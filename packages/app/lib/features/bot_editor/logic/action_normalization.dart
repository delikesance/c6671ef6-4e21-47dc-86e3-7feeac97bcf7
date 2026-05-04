import 'package:bot_creator/core/models/types/action.dart' show BotCreatorActionType;

/// Purges irrelevant parameters from an action payload based on its type and mode.
/// This ensures strict separation between response modes (Message, ComponentV2, Modal).
Map<String, dynamic> purgeActionPayloadStrict(
  BotCreatorActionType type,
  Map<String, dynamic> parameters,
) {
  final payload = Map<String, dynamic>.from(parameters);

  // ALWAYS remove legacy 'embed' field in favor of 'embeds'
  payload.remove('embed');

  if (type == BotCreatorActionType.sendMessage) {
    final mode = (payload['messageMode'] ?? 'message').toString();
    if (mode == 'message' || mode == 'normal') {
      // Keep content, embeds, components (normal), attachments
      payload.remove('componentV2');
    } else if (mode == 'componentV2') {
      // Keep content, componentV2, attachments
      payload.remove('embeds');
      payload.remove('components');
    }
  } else if (type == BotCreatorActionType.respondWithMessage) {
    // Only keep message related fields
    final keysToKeep = {
      'content',
      'text',
      'embeds',
      'components',
      'attachments',
      'ephemeral',
      'visibility',
      'key'
    };
    payload.removeWhere((key, value) => !keysToKeep.contains(key));
  } else if (type == BotCreatorActionType.respondWithComponentV2) {
    // Only keep componentV2 related fields
    final keysToKeep = {
      'content',
      'components',
      'attachments',
      'ephemeral',
      'visibility',
      'key'
    };
    payload.removeWhere((key, value) => !keysToKeep.contains(key));
  } else if (type == BotCreatorActionType.respondWithModal) {
    // Only keep modal related fields
    final keysToKeep = {'modal', 'key'};
    payload.removeWhere((key, value) => !keysToKeep.contains(key));
  } else if (type == BotCreatorActionType.editInteractionMessage) {
    final mode = (payload['editMode'] ?? 'message').toString();
    if (mode == 'message' || mode == 'normal') {
      payload.remove('componentV2');
    } else if (mode == 'componentV2') {
      payload.remove('embeds');
      payload.remove('components');
    }
  }

  return payload;
}
