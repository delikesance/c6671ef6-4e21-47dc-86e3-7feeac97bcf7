part of 'command.create.dart';

extension _CommandCreateValidation on _CommandCreatePageState {
  String? _validateOptionsForLevel(
    List<CommandOptionBuilder> options, {
    required int level,
    required CommandOptionType? parentType,
  }) => validateOptionsForLevel(
    context,
    options,
    level: level,
    parentType: parentType,
    isPrefixCommand: _legacyModeEnabled,
  );

  String? _validateName(String? value) {
    final normalized = (value ?? '').trim();
    if (normalized.isEmpty) {
      return context.tr.validation_command_name_required;
    }

    if (isCommandNameTaken(normalized, _otherCommandNames)) {
      return context.tr.validation_command_name_duplicate(normalized);
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

    if (_legacyModeEnabled) {
      final issue = validatePrefixCommandNameFormat(
        normalized,
        maxLength: _commandNameMaxLength,
      );
      return discordCommandValidationMessage(
        context,
        issue,
        maxLength: _commandNameMaxLength,
      );
    }

    final issue = validateCommandName(
      _commandType,
      normalized,
      isPrefixCommand: false,
    );
    return discordCommandValidationMessage(
      context,
      issue,
      maxLength: _commandNameMaxLength,
    );
  }

  Future<bool> _validateCommandInputs() async {
    final nameError = _validateName(_commandName);
    if (nameError != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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

    if (!_legacyModeEnabled && _requiresCommandDescription) {
      final descriptionIssue = validateDescriptionValue(
        _commandDescription,
        required: true,
      );
      final descriptionError = discordCommandValidationMessage(
        context,
        descriptionIssue,
      );
      if (descriptionError != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr.error),
            content: Text(descriptionError),
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
    } else if (_supportsCommandDescription && _legacyModeEnabled) {
      final descriptionIssue = validateDescriptionValue(
        _commandDescription,
        required: false,
      );
      final descriptionError = discordCommandValidationMessage(
        context,
        descriptionIssue,
      );
      if (descriptionError != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr.error),
            content: Text(descriptionError),
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

    if (_supportsCommandOptions && !_legacyModeEnabled) {
      final payloadSize = computeSlashCommandPayloadSize(
        name: _commandName.trim(),
        description: _commandDescription.trim(),
        options: _effectiveOptions,
      );
      final payloadIssue = validateSlashCommandPayloadSize(payloadSize);
      final payloadError = discordCommandValidationMessage(
        context,
        payloadIssue,
        payloadSize: payloadSize,
      );
      if (payloadError != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr.error),
            content: Text(payloadError),
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

    if (_supportsCommandOptions) {
      final optionsError = _validateOptionsForLevel(
        _effectiveOptions,
        level: 0,
        parentType: null,
      );
      if (optionsError != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
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
          builder: (context) => AlertDialog(
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
          builder: (context) => AlertDialog(
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
          builder: (context) => AlertDialog(
            title: Text(context.tr.error),
            content: Text(context.tr.validation_legacy_only_requires_legacy),
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
          builder: (context) => AlertDialog(
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

  List<String> _collectWorkflowActionIssues() {
    if (_isBdfdScriptMode || _isJavascriptMode) {
      return const <String>[];
    }

    final issues = <String>[];
    for (var i = 0; i < _actions.length; i++) {
      final action = _actions[i];
      if (action['enabled'] == false) continue;

      final type = (action['type'] ?? '').toString();
      final params = Map<String, dynamic>.from(
        (action['parameters'] as Map?)?.cast<String, dynamic>() ?? const {},
      );

      if (type == 'sendMessage') {
        final content = (params['content'] ?? '').toString().trim();
        final embeds = params['embeds'];
        final hasEmbeds = embeds is List && embeds.isNotEmpty;
        final mode = (params['messageMode'] ?? 'normal').toString();
        final hasComponentV2 =
            mode == 'componentV2' && params['componentV2'] is Map;
        if (content.isEmpty && !hasEmbeds && !hasComponentV2) {
          issues.add(
            '${context.tr.cmd_block_editor_action_label(i + 1)}: ${context.tr.cmd_simple_send_message_required}',
          );
        }
      }

      if (type == 'respondWithMessage') {
        final content = (params['content'] ?? '').toString().trim();
        final embeds = params['embeds'];
        final hasEmbeds = embeds is List && embeds.isNotEmpty;
        final components = params['components'];
        final hasComponents = components is Map && components.isNotEmpty;
        if (content.isEmpty && !hasEmbeds && !hasComponents) {
          issues.add(
            '${context.tr.cmd_block_editor_action_label(i + 1)}: ${context.tr.cmd_simple_send_message_required}',
          );
        }
      }
    }
    return issues;
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
