import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import '../logic/action_normalization.dart';

// Enum pour les types de paramètres
enum ParameterType {
  string,
  number,
  boolean,
  list,
  elseIfBranches,
  map,
  duration,
  color,
  url,
  userId,
  channelId,
  messageId,
  roleId,
  emoji,
  multiSelect,
  permissionFlags,
  embeds,
  normalComponents,
  componentV2,
  modalDefinition,
  nestedActions,
  bdfdScript,
}

// --- Variable Suggestions ---

// Modèle pour définir un paramètre avec son type
class ParameterDefinition {
  final String key;
  final ParameterType type;
  final dynamic defaultValue;
  final String? hint;
  final List<String>? options; // Pour les select/multiselect
  final Map<String, List<String>>? visibleWhen;
  final int? minValue;
  final int? maxValue;
  final bool required;
  final bool allowDynamic; // Si false, n'accepte que des valeurs littérales

  ParameterDefinition({
    required this.key,
    required this.type,
    required this.defaultValue,
    this.hint,
    this.options,
    this.visibleWhen,
    this.minValue,
    this.maxValue,
    this.required = false,
    this.allowDynamic = true,
  });
}

// Modèle pour représenter une action
class ActionItem {
  static int _globalCounter = 0;
  final String runtimeId;
  final String id;
  final BotCreatorActionType type;
  bool enabled;
  String onErrorMode;
  String actionKey;
  String? jumpToActionId;
  int skipCount;
  final Map<String, dynamic> parameters;

  ActionItem({
    required this.id,
    required this.type,
    required this.parameters,
    required this.actionKey,
    this.enabled = true,
    this.onErrorMode = 'stop',
    this.jumpToActionId,
    this.skipCount = 0,
    String? runtimeId,
  }) : runtimeId =
           runtimeId ??
           'action_${DateTime.now().microsecondsSinceEpoch}_${_globalCounter++}';

  factory ActionItem.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final parameters = Map<String, dynamic>.from(
      (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final persistedKey = (json['key'] ?? '').toString().trim();
    final actionKey = persistedKey.isNotEmpty
        ? persistedKey
        : (fallbackId ?? json['id'] ?? '');

    final rawId = (json['id'] ?? '').toString().trim();
    final id = rawId.isNotEmpty
        ? rawId
        : 'action_${DateTime.now().microsecondsSinceEpoch}_${_globalCounter++}';
    String runtimeId = (json['runtimeId'] ?? '').toString().trim();

    if (runtimeId.isEmpty) {
      if (id.isNotEmpty) {
        runtimeId = id;
      } else {
        runtimeId =
            'action_${DateTime.now().microsecondsSinceEpoch}_${_globalCounter++}';
      }
      try {
        json['runtimeId'] = runtimeId;
      } catch (_) {}
    }

    if (json['id'] == null || json['id'].toString().trim().isEmpty) {
      try {
        json['id'] = id;
      } catch (_) {}
    }

    BotCreatorActionType mappedType = BotCreatorActionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => BotCreatorActionType.sendMessage,
    );
    if (mappedType == BotCreatorActionType.sendComponentV2) {
      mappedType = BotCreatorActionType.respondWithComponentV2;
    }

    return ActionItem(
      id: id,
      type: mappedType,
      enabled: json['enabled'] as bool? ?? true,
      onErrorMode:
          (Map<String, dynamic>.from(
                    (json['error'] as Map?)?.cast<String, dynamic>() ??
                        const {},
                  )['mode'] ??
                  'stop')
              .toString(),
      jumpToActionId:
          (json['error'] as Map?)?.cast<String, dynamic>()['jumpToActionId']
              as String?,
      skipCount:
          int.tryParse(
            (json['error'] as Map?)
                    ?.cast<String, dynamic>()['skipCount']
                    ?.toString() ??
                '',
          ) ??
          0,
      parameters: parameters,
      actionKey: actionKey,
      runtimeId: runtimeId,
    );
  }

  Map<String, dynamic> toJson() {
    // Strict response mode partitioning using centralized utility
    final purgedPayload = purgeActionPayloadStrict(type, parameters);

    return {
      'id': id,
      'type': type.name,
      'enabled': enabled,
      'key': actionKey,
      'depend_on': <String>[],
      'error': {
        'mode': onErrorMode,
        if (jumpToActionId != null) 'jumpToActionId': jumpToActionId,
        if (skipCount > 0) 'skipCount': '$skipCount',
      },
      'payload': {...purgedPayload, '_actionId': runtimeId},
      'runtimeId': runtimeId,
    };
  }
}

class ActionClipboard {
  static Map<String, dynamic>? _copiedAction;

  static Future<void> copyAction(Map<String, dynamic> actionJson) async {
    _copiedAction = actionJson;
    final String jsonStr = jsonEncode({
      '__botCreatorAction__': true,
      'action': actionJson,
    });
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  static Future<Map<String, dynamic>?> getCopiedAction() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text;
      if (text != null) {
        final Map<String, dynamic> parsed = jsonDecode(text);
        if (parsed['__botCreatorAction__'] == true &&
            parsed['action'] != null) {
          return Map<String, dynamic>.from(parsed['action'] as Map);
        }
      }
    } catch (_) {}
    return _copiedAction;
  }

  static Future<bool> hasCopiedAction() async {
    if (_copiedAction != null) return true;
    final action = await getCopiedAction();
    return action != null;
  }
}
