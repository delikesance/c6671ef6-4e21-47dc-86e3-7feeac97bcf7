import '../../l10n/tr_extension.dart';
import './discord_application_command_rules.dart';
import 'package:flutter/widgets.dart';

String? discordCommandValidationMessage(
  BuildContext context,
  DiscordCommandValidationIssue? issue, {
  int? maxLength,
  int? payloadSize,
}) {
  if (issue == null) {
    return null;
  }

  switch (issue) {
    case DiscordCommandValidationIssue.nameRequired:
      return context.tr.validation_command_name_required;
    case DiscordCommandValidationIssue.nameTooLong:
      return context.tr.validation_command_name_length(
        maxLength ?? discordCommandNameMaxLength,
      );
    case DiscordCommandValidationIssue.nameInvalidFormat:
      return context.tr.validation_command_name_invalid_chars;
    case DiscordCommandValidationIssue.nameMustBeLowercase:
      return context.tr.validation_command_name_must_be_lowercase;
    case DiscordCommandValidationIssue.descriptionRequired:
      return context.tr.command_description_required;
    case DiscordCommandValidationIssue.descriptionTooLong:
      return context.tr.command_description_length;
    case DiscordCommandValidationIssue.optionNameInvalidFormat:
      return context.tr.option_name_invalid_chars;
    case DiscordCommandValidationIssue.optionNameMustBeLowercase:
      return context.tr.validation_option_name_must_be_lowercase;
    case DiscordCommandValidationIssue.optionRequiredBeforeOptional:
      return context.tr.validation_option_required_before_optional;
    case DiscordCommandValidationIssue.payloadTooLarge:
      return context.tr.validation_command_payload_too_large(
        payloadSize ?? discordSlashCommandPayloadLimit + 1,
        discordSlashCommandPayloadLimit,
      );
  }
}

String requiredFieldLabel(String label) => '$label *';
