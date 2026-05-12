import 'package:bot_creator/core/models/types/action.dart'
    show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/logic/action_normalization.dart';

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
  final String id;
  final BotCreatorActionType type;
  bool enabled;
  String onErrorMode;
  final Map<String, dynamic> parameters;

  ActionItem({
    required this.id,
    required this.type,
    required this.parameters,
    this.enabled = true,
    this.onErrorMode = 'stop',
  });

  factory ActionItem.fromJson(Map<String, dynamic> json, {String? fallbackId}) {
    final parameters = Map<String, dynamic>.from(
      (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final persistedKey = (json['key'] ?? '').toString().trim();
    if (persistedKey.isNotEmpty) {
      parameters['key'] = persistedKey;
    }

    final rawId = (json['id'] ?? '').toString().trim();

    BotCreatorActionType mappedType = BotCreatorActionType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => BotCreatorActionType.sendMessage,
    );
    if (mappedType == BotCreatorActionType.sendComponentV2) {
      mappedType = BotCreatorActionType.respondWithComponentV2;
    }

    return ActionItem(
      id: rawId.isNotEmpty ? rawId : (fallbackId ?? ''),
      type: mappedType,
      enabled: json['enabled'] as bool? ?? true,
      onErrorMode:
          (Map<String, dynamic>.from(
                    (json['error'] as Map?)?.cast<String, dynamic>() ??
                        const {},
                  )['mode'] ??
                  'stop')
              .toString(),
      parameters: parameters,
    );
  }

  Map<String, dynamic> toJson() {
    final actionKey = (parameters['key'] ?? id).toString();

    // Strict response mode partitioning using centralized utility
    final purgedPayload = purgeActionPayloadStrict(type, parameters);

    return {
      'id': id,
      'type': type.name,
      'enabled': enabled,
      'key': actionKey,
      'depend_on': <String>[],
      'error': {'mode': onErrorMode},
      'payload': purgedPayload,
    };
  }
}
