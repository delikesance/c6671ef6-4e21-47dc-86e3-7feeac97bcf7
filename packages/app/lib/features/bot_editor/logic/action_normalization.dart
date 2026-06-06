import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator_shared/utils/permission_flags.dart'
    show computeAllowBitmask, computeDenyBitmask;

/// Mapping from visual canvas block types to their runtime operation names.
const _canvasBlockToOp = <BotCreatorActionType, String>{
  BotCreatorActionType.canvasCreateBlock: 'create',
  BotCreatorActionType.canvasLoadImageBlock: 'loadImage',
  BotCreatorActionType.canvasDrawTextBlock: 'drawText',
  BotCreatorActionType.canvasDrawCircleBlock: 'drawCircle',
  BotCreatorActionType.canvasDrawRectBlock: 'drawRect',
  BotCreatorActionType.canvasDrawLineBlock: 'drawLine',
};

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
      // Only keep componentV2, attachments
      payload.remove('content');
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
      'replyToMessage',
      'key',
    };
    payload.removeWhere((key, value) => !keysToKeep.contains(key));
  } else if (type == BotCreatorActionType.respondWithComponentV2) {
    // Only keep componentV2 related fields
    final keysToKeep = {
      'channelId',
      'components',
      'componentV2',
      'attachments',
      'ephemeral',
      'visibility',
      'key',
      'messageMode',
    };
    payload.removeWhere((key, value) => !keysToKeep.contains(key));
    // Ensure messageMode is set so sendMessageToChannel picks up components.
    payload['messageMode'] = 'componentV2';
  } else if (type == BotCreatorActionType.respondWithModal) {
    // Only keep modal related fields
    final keysToKeep = {'modal', 'key'};
    payload.removeWhere((key, value) => !keysToKeep.contains(key));
  } else if (type == BotCreatorActionType.editInteractionMessage) {
    final mode = (payload['editMode'] ?? 'message').toString();
    if (mode == 'message' || mode == 'normal') {
      payload.remove('componentV2');
    } else if (mode == 'componentV2') {
      payload.remove('content');
      payload.remove('embeds');
    }
  } else if (type == BotCreatorActionType.editMessage) {
    final mode = (payload['editMode'] ?? 'message').toString();
    if (mode == 'message' || mode == 'normal') {
      payload.remove('componentV2');
    } else if (mode == 'componentV2') {
      payload.remove('content');
      payload.remove('embeds');
    }
  }

  // ── Image Manipulation Block: collapse nested canvas actions into runtime operations ──
  if (type == BotCreatorActionType.runtimeImageBlock) {
    final nestedRaw = payload['operations'];
    if (nestedRaw is List && nestedRaw.isNotEmpty) {
      final runtimeOps = <Map<String, dynamic>>[];
      for (final item in nestedRaw) {
        if (item is! Map) continue;
        final itemType = (item['type'] ?? '').toString();
        final itemPayload =
            Map<String, dynamic>.from(
              (item['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
            );

        // Find matching canvas block type
        BotCreatorActionType? canvasType;
        for (final entry in _canvasBlockToOp.entries) {
          if (entry.key.name == itemType) {
            canvasType = entry.key;
            break;
          }
        }
        if (canvasType == null) continue;

        final opName = _canvasBlockToOp[canvasType]!;
        final op = <String, dynamic>{'op': opName};

        // Copy relevant parameters based on operation type
        switch (canvasType) {
          case BotCreatorActionType.canvasCreateBlock:
            op['width'] = (itemPayload['width'] ?? '400').toString();
            op['height'] = (itemPayload['height'] ?? '300').toString();
            op['color'] = (itemPayload['color'] ?? '#ffffff').toString();
            break;
          case BotCreatorActionType.canvasLoadImageBlock:
            op['url'] = (itemPayload['url'] ?? '').toString();
            // targetWidth/targetHeight → compositeImage width/height if positive
            final tw = (itemPayload['targetWidth'] ?? '-1').toString();
            final th = (itemPayload['targetHeight'] ?? '-1').toString();
            if (tw != '-1' || th != '-1') {
              op['width'] = tw;
              op['height'] = th;
            }
            break;
          case BotCreatorActionType.canvasDrawTextBlock:
            op['text'] = (itemPayload['text'] ?? '').toString();
            op['x'] = (itemPayload['x'] ?? '0').toString();
            op['y'] = (itemPayload['y'] ?? '0').toString();
            op['fontSize'] = (itemPayload['fontSize'] ?? '14').toString();
            op['color'] = (itemPayload['color'] ?? '#ffffff').toString();
            break;
          case BotCreatorActionType.canvasDrawCircleBlock:
            op['x'] = (itemPayload['x'] ?? '0').toString();
            op['y'] = (itemPayload['y'] ?? '0').toString();
            op['radius'] = (itemPayload['radius'] ?? '50').toString();
            op['color'] = (itemPayload['color'] ?? '#ffffff').toString();
            op['fill'] = (itemPayload['fill'] ?? true).toString();
            break;
          case BotCreatorActionType.canvasDrawRectBlock:
            op['x'] = (itemPayload['x'] ?? '0').toString();
            op['y'] = (itemPayload['y'] ?? '0').toString();
            op['width'] = (itemPayload['width'] ?? '100').toString();
            op['height'] = (itemPayload['height'] ?? '50').toString();
            op['color'] = (itemPayload['color'] ?? '#ffffff').toString();
            op['fill'] = (itemPayload['fill'] ?? true).toString();
            break;
          case BotCreatorActionType.canvasDrawLineBlock:
            op['x1'] = (itemPayload['x1'] ?? '0').toString();
            op['y1'] = (itemPayload['y1'] ?? '0').toString();
            op['x2'] = (itemPayload['x2'] ?? '100').toString();
            op['y2'] = (itemPayload['y2'] ?? '100').toString();
            op['color'] = (itemPayload['color'] ?? '#ffffff').toString();
            op['thickness'] = (itemPayload['thickness'] ?? '1').toString();
            break;
          default:
            continue;
        }
        runtimeOps.add(op);
      }
      payload['operations'] = runtimeOps;
    } else {
      // No nested actions — keep operations as-is or empty
      payload['operations'] = <Map<String, dynamic>>[];
    }
  }

  // ── Permission Flags → allow/deny bitmask conversion ──
  if (type == BotCreatorActionType.editChannelPermissions) {
    final permStates = payload['permissions'];
    if (permStates is Map) {
      final allowKeys = <String>{};
      final denyKeys = <String>{};
      permStates.forEach((key, value) {
        final state = value.toString();
        if (state == 'allow') {
          allowKeys.add(key.toString());
        } else if (state == 'deny') {
          denyKeys.add(key.toString());
        }
      });
      payload['allow'] = computeAllowBitmask(allowKeys).toString();
      payload['deny'] = computeDenyBitmask(denyKeys).toString();
    } else if (payload['permissions'] == null) {
      // No permissions specified — default to 0
      payload['allow'] ??= '0';
      payload['deny'] ??= '0';
    }
  }

  return payload;
}
