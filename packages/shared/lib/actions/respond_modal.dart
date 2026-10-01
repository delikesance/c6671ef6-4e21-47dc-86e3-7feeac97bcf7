import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/types/component.dart' as bc;
import 'package:bot_creator_shared/utils/interaction_ack_state.dart';
import 'send_component_v2.dart';

/// Pure modal construction shared by normal execution and the sandbox.
ModalBuilder buildModalResponse(
  bc.ModalDefinition definition,
  String Function(String) resolve,
) {
  if (definition.title.isEmpty) {
    throw StateError('Modal title is required');
  }
  if (definition.customId.isEmpty) {
    throw StateError('Modal customId is required');
  }

  final resolvedCustomId = resolve(definition.customId);

  // ── Build modal component builders ────────────────────────────
  final modalComponents = <ComponentBuilder>[];

  if (definition.hasComponentsV2) {
    // Inputs use labels; static text displays are direct modal components.
    for (final node in definition.components) {
      if (node is bc.TextDisplayNode) {
        modalComponents.add(buildComponentNode(node, resolve));
        continue;
      }
      if (node is! bc.LabelNode) continue;
      final label = node;
      final child = label.component;
      if (child == null) continue;

      final childBuilder = buildComponentNode(child, resolve, inLabel: true);
      modalComponents.add(
        LabelComponentBuilder(
          label: resolve(label.label),
          description: label.description.isNotEmpty
              ? resolve(label.description)
              : null,
          component: childBuilder,
        ),
      );
    }
  }

  // Legacy format: wrap each ModalTextInputDefinition in an ActionRow
  // (only used when no new-style components were parsed).
  if (modalComponents.isEmpty && definition.inputs.isNotEmpty) {
    for (final input in definition.inputs) {
      modalComponents.add(
        ActionRowBuilder(
          components: [
            TextInputBuilder(
              customId: resolve(input.customId),
              // ignore: deprecated_member_use
              label: resolve(input.label),
              style: input.style == bc.BcTextInputStyle.paragraph
                  ? TextInputStyle.paragraph
                  : TextInputStyle.short,
              placeholder: input.placeholder.isNotEmpty
                  ? resolve(input.placeholder)
                  : null,
              value: input.defaultValue.isNotEmpty
                  ? resolve(input.defaultValue)
                  : null,
              isRequired: input.required,
              minLength: input.minLength,
              maxLength: input.maxLength,
            ),
          ],
        ),
      );
    }
  }

  if (modalComponents.isEmpty) {
    throw StateError(
      'Modal must have at least one component (text input, select, '
      'file upload, radio group, checkbox group, checkbox, or text display).',
    );
  }

  return ModalBuilder(
    title: resolve(definition.title),
    customId: resolvedCustomId,
    components: modalComponents,
  );
}

/// Respond to an interaction with a Modal dialog.
/// NOTE: Modals can only be sent as the FIRST response (not after defer).
///
/// Supports two modal definition formats:
///   1. **New (components):** LabelNode wrappers for inputs and standalone
///      TextDisplayNode content.
///   2. **Legacy (inputs):** A `List<ModalTextInputDefinition>` — plain text
///      inputs wrapped in ActionRows (deprecated by Discord but still
///      functional).
Future<Map<String, dynamic>> respondWithModalAction(
  Interaction interaction, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) async {
  try {
    // Accept both wrapped payload['modal'] (from command_migration) and
    // top-level payload (from the BDFD transpiler).
    final modalJson = payload['modal'] ?? payload;
    if (modalJson == null || modalJson is! Map) {
      return {'error': 'modal definition is required'};
    }

    final definition = bc.ModalDefinition.fromJson(
      Map<String, dynamic>.from(modalJson),
    );

    final modalBuilder = buildModalResponse(definition, resolve);
    final resolvedCustomId = modalBuilder.customId;

    if (interaction is ApplicationCommandInteraction) {
      await interaction.respondModal(modalBuilder);
      markInteractionAcknowledged(interaction);
    } else if (interaction is MessageComponentInteraction) {
      await interaction.respondModal(modalBuilder);
      markInteractionAcknowledged(interaction);
    } else {
      return {'error': 'This interaction type does not support modals'};
    }
    return {
      'status': 'modal_sent',
      'customId': resolvedCustomId,
      'actions': definition.actions,
    };
  } catch (e) {
    return {'error': e.toString()};
  }
}
