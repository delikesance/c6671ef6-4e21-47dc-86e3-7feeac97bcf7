import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

import '../nyxx_bridge.dart';

/// Carte « informations de base » d'une commande (types nyxx) ; le widget
/// vit dans `bot_creator_ui`.
class BasicInfoCard extends StatelessWidget {
  const BasicInfoCard({
    super.key,
    required this.commandName,
    required this.commandDescription,
    required this.commandType,
    required this.isLegacyCommand,
    required this.canEditCommandType,
    required this.showDescriptionField,
    required this.integrationTypes,
    required this.contexts,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onCommandTypeChanged,
    required this.onLegacyCommandChanged,
    required this.localOnlyCommand,
    required this.onLocalOnlyCommandChanged,
    required this.onIntegrationTypesChanged,
    required this.onContextsChanged,
    required this.defaultMemberPermissions,
    required this.onDefaultMemberPermissionsChanged,
    required this.nameValidator,
    this.nameMaxLength = 32,
    this.legacyAliases = const <String>[],
    this.onLegacyAliasesChanged,
  });

  final String commandName;
  final String commandDescription;
  final ApplicationCommandType commandType;
  final bool isLegacyCommand;
  final bool localOnlyCommand;
  final bool canEditCommandType;
  final bool showDescriptionField;
  final List<ApplicationIntegrationType> integrationTypes;
  final List<InteractionContextType> contexts;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<ApplicationCommandType> onCommandTypeChanged;
  final ValueChanged<bool> onLegacyCommandChanged;
  final ValueChanged<bool> onLocalOnlyCommandChanged;
  final ValueChanged<List<ApplicationIntegrationType>>
  onIntegrationTypesChanged;
  final ValueChanged<List<InteractionContextType>> onContextsChanged;
  final String defaultMemberPermissions;
  final ValueChanged<String> onDefaultMemberPermissionsChanged;
  final String? Function(String?) nameValidator;
  final int nameMaxLength;
  final List<String> legacyAliases;
  final ValueChanged<List<String>>? onLegacyAliasesChanged;

  @override
  Widget build(BuildContext context) => ui.BasicInfoCard(
    commandName: commandName,
    commandDescription: commandDescription,
    commandType: toLiteCommandType(commandType),
    isLegacyCommand: isLegacyCommand,
    canEditCommandType: canEditCommandType,
    showDescriptionField: showDescriptionField,
    integrationTypes: toLiteIntegrationTypes(integrationTypes),
    contexts: toLiteContexts(contexts),
    onNameChanged: onNameChanged,
    onDescriptionChanged: onDescriptionChanged,
    onCommandTypeChanged: (t) => onCommandTypeChanged(fromLiteCommandType(t)),
    onLegacyCommandChanged: onLegacyCommandChanged,
    localOnlyCommand: localOnlyCommand,
    onLocalOnlyCommandChanged: onLocalOnlyCommandChanged,
    onIntegrationTypesChanged: (t) =>
        onIntegrationTypesChanged(fromLiteIntegrationTypes(t)),
    onContextsChanged: (c) => onContextsChanged(fromLiteContexts(c)),
    defaultMemberPermissions: defaultMemberPermissions,
    onDefaultMemberPermissionsChanged: onDefaultMemberPermissionsChanged,
    nameValidator: nameValidator,
    nameMaxLength: nameMaxLength,
    legacyAliases: legacyAliases,
    onLegacyAliasesChanged: onLegacyAliasesChanged,
  );
}
