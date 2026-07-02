part of 'command.create.dart';

extension _CommandCreateValidation on _CommandCreatePageState {
  String? _validateOptionsForLevel(
    List<CommandOptionBuilder> options, {
    required int level,
    required CommandOptionType? parentType,
  }) => validateOptionsForLevel(context, options, level: level, parentType: parentType);

  String? _validateName(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return context.tr.validation_command_name_required;
    }

    if (_isAwaitedCallbackTrigger(normalized)) {
      if (!_allowsInternalLegacyCallbackNames) {
        return context.tr.validation_awaited_callback_local_only;
      }
      if (normalized.length > _commandNameMaxLength) {
        return context.tr.validation_awaited_callback_length(
          _commandNameMaxLength,
        );
      }
      return null;
    }

    if (_looksLikeAwaitedCallbackTrigger(normalized)) {
      return context.tr.validation_awaited_callback_format;
    }

    if (normalized.length > _commandNameMaxLength) {
      return context.tr.validation_command_name_length(_commandNameMaxLength);
    }
    if (normalized.contains(' ')) {
      return context.tr.validation_command_name_no_spaces;
    }
    if (normalized.contains(RegExp(r'[^a-zA-Z0-9_]'))) {
      return context.tr.validation_command_name_invalid_chars;
    }
    if (normalized.startsWith('_')) {
      return context.tr.validation_command_name_no_underscore;
    }
    if (normalized.startsWith('!')) {
      return context.tr.validation_command_name_no_exclamation;
    }
    if (normalized.startsWith('/')) {
      return context.tr.validation_command_name_no_slash;
    }
    if (normalized.startsWith('#')) {
      return context.tr.validation_command_name_no_hash;
    }
    if (normalized.startsWith('@')) {
      return context.tr.validation_command_name_no_at;
    }
    if (normalized.startsWith('&')) {
      return context.tr.validation_command_name_no_ampersand;
    }
    if (normalized.startsWith('%')) {
      return context.tr.validation_command_name_no_percent;
    }
    return null;
  }

  Future<bool> _validateCommandInputs() async {
    final nameError = _validateName(_commandName);
    if (nameError != null) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(context.tr.error),
              content: Text(nameError),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.tr.ok),
                ),
              ],
            ),
      );
      return false;
    }

    if (_supportsCommandOptions) {
      final optionsError = _validateOptionsForLevel(
        _effectiveOptions,
        level: 0,
        parentType: null,
      );
      if (optionsError != null) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr.error),
                content: Text(optionsError),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr.ok),
                  ),
                ],
              ),
        );
        return false;
      }
    }

    // In BDFD mode, diagnostics are informational only and must not block save.

    if ((_isJavascriptMode || _isJavascriptOnlyBot) &&
        _jsScriptController.text.trim().isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr.error),
          content: Text(context.tr.cmd_execution_mode_javascript_desc),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.tr.ok),
            ),
          ],
        ),
      );
      return false;
    }

    if (!_isBdfdScriptMode && !_isJavascriptMode && _legacyModeEnabled) {
      if (_commandType != ApplicationCommandType.chatInput) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr.error),
                content: Text(context.tr.validation_legacy_chat_input_only),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr.ok),
                  ),
                ],
              ),
        );
        return false;
      }
    }

    // Interaction commands (chatInput / user) that are not legacy must have
    // at least one respond action after migration.  A missing response will
    // cause a Discord interaction timeout, so we warn the user.
    if (!_isBdfdScriptMode &&
        !_isJavascriptMode &&
        !_legacyModeEnabled &&
        !_localOnlyCommand &&
        _commandType != ApplicationCommandType.message) {
      final hasRespondAction = _actions.any((a) {
        final type = (a['type'] ?? '').toString();
        return type == 'respondWithMessage' ||
            type == 'respondWithComponentV2' ||
            type == 'respondWithModal';
      });
      if (!hasRespondAction) {
        final proceed = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr.validation_interaction_no_response_short),
                content: Text(context.tr.validation_interaction_no_response),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(context.tr.cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(context.tr.save),
                  ),
                ],
              ),
        );
        if (proceed != true) return false;
      }
    }

    if (!_isBdfdScriptMode && !_isJavascriptMode && _localOnlyCommand) {
      if (!_legacyModeEnabled) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr.error),
                content: Text(
                  context.tr.validation_legacy_only_requires_legacy,
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr.ok),
                  ),
                ],
              ),
        );
        return false;
      }

      if (!_canToggleLegacyOnlyLocal) {
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(context.tr.error),
                content: Text(context.tr.validation_legacy_only_new_or_local),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.tr.ok),
                  ),
                ],
              ),
        );
        return false;
      }
    }

    return true;
  }

  Permissions? _parseDefaultMemberPermissions(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = int.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
      throw Exception(context.tr.validation_invalid_permissions);
    }
    return Permissions(parsed);
  }
}
