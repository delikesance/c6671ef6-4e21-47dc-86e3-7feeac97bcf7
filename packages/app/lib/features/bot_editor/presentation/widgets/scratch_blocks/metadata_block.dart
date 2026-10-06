import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';

import '../nyxx_bridge.dart';

/// Bloc Métadonnées de l'éditeur de commandes (types nyxx) ; le widget vit
/// dans `bot_creator_ui`, partagé avec le Studio.
class MetadataBlock extends StatelessWidget {
  const MetadataBlock({
    super.key,
    required this.commandName,
    required this.commandDescription,
    required this.commandType,
    required this.isLegacyCommand,
    required this.localOnlyCommand,
    required this.canEditCommandType,
    required this.showDescriptionField,
    required this.integrationTypes,
    required this.contexts,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onCommandTypeChanged,
    required this.onLegacyCommandChanged,
    required this.onLocalOnlyCommandChanged,
    required this.onIntegrationTypesChanged,
    required this.onContextsChanged,
    required this.defaultMemberPermissions,
    required this.onDefaultMemberPermissionsChanged,
    required this.nameValidator,
    this.nameMaxLength = 32,
    this.legacyAliases = const <String>[],
    this.onLegacyAliasesChanged,
    this.showOptions = true,
    this.options,
    this.onOptionsChanged,
    this.botIdForConfig,
    this.variableSuggestions = const [],
    this.folderController,
    this.onFolderChanged,
    this.showCommandTypeSelector = false,
  });

  final bool showCommandTypeSelector;
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
  final bool showOptions;
  final List<CommandOptionBuilder>? options;
  final ValueChanged<List<CommandOptionBuilder>>? onOptionsChanged;
  final String? botIdForConfig;
  final List<ui.VariableSuggestion> variableSuggestions;
  final TextEditingController? folderController;
  final ValueChanged<String>? onFolderChanged;

  @override
  Widget build(BuildContext context) => ui.MetadataBlock(
    commandName: commandName,
    commandDescription: commandDescription,
    commandType: toLiteCommandType(commandType),
    isLegacyCommand: isLegacyCommand,
    localOnlyCommand: localOnlyCommand,
    canEditCommandType: canEditCommandType,
    showDescriptionField: showDescriptionField,
    integrationTypes: toLiteIntegrationTypes(integrationTypes),
    contexts: toLiteContexts(contexts),
    onNameChanged: onNameChanged,
    onDescriptionChanged: onDescriptionChanged,
    onCommandTypeChanged: (t) => onCommandTypeChanged(fromLiteCommandType(t)),
    onLegacyCommandChanged: onLegacyCommandChanged,
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
    showOptions: showOptions,
    options: options == null ? null : toLiteOptions(options!),
    onOptionsChanged: onOptionsChanged == null
        ? null
        : (o) => onOptionsChanged!(fromLiteOptions(o)),
    botIdForConfig: botIdForConfig,
    variableSuggestions: variableSuggestions,
    folderController: folderController,
    onFolderChanged: onFolderChanged,
    showCommandTypeSelector: showCommandTypeSelector,
  );
}
