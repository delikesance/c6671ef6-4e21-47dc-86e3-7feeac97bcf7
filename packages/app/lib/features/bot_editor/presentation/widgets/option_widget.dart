import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart' show CommandOptionBuilder;

import 'nyxx_bridge.dart';

/// Éditeur des options (arguments) d'une commande. L'interface est celle d'avant
/// l'extraction (types nyxx) ; le widget lui-même vit dans `bot_creator_ui`,
/// partagé avec le Studio.
class OptionWidget extends StatelessWidget {
  const OptionWidget({
    super.key,
    required this.onChange,
    this.initialOptions,
    this.botIdForConfig,
    this.variableSuggestions = const <ui.VariableSuggestion>[],
    this.isPrefixCommand = false,
    this.commandName = '',
  });

  final void Function(List<CommandOptionBuilder>) onChange;
  final List<CommandOptionBuilder>? initialOptions;
  final String? botIdForConfig;
  final List<ui.VariableSuggestion> variableSuggestions;
  final bool isPrefixCommand;
  final String commandName;

  @override
  Widget build(BuildContext context) => ui.OptionWidget(
    onChange: (options) => onChange(fromLiteOptions(options)),
    initialOptions: initialOptions == null
        ? null
        : toLiteOptions(initialOptions!),
    botIdForConfig: botIdForConfig,
    variableSuggestions: variableSuggestions,
    isPrefixCommand: isPrefixCommand,
    commandName: commandName,
  );
}
