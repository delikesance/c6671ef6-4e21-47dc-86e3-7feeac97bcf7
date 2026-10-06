import '../../discord/nyxx_lite.dart';

const int discordSlashCommandPayloadLimit = 8000;
const int discordCommandNameMaxLength = 32;
const int discordCommandDescriptionMaxLength = 100;
const int discordChoiceNameMaxLength = 100;
const int discordChoiceValueMaxLength = 100;
const int prefixCommandNameMaxLength = 32;
const int internalCallbackCommandNameMaxLength = 256;

/// Official Discord `CHAT_INPUT` / option naming regex (unicode).
final RegExp discordChatInputNamePattern = RegExp(
  r"^[-_'\p{L}\p{N}\p{sc=Deva}\p{sc=Thai}]{1,32}$",
  unicode: true,
);

enum DiscordCommandValidationIssue {
  nameRequired,
  nameTooLong,
  nameInvalidFormat,
  nameMustBeLowercase,
  descriptionRequired,
  descriptionTooLong,
  optionNameInvalidFormat,
  optionNameMustBeLowercase,
  optionRequiredBeforeOptional,
  payloadTooLarge,
}

bool isHierarchyOptionType(CommandOptionType type) {
  return type == CommandOptionType.subCommand ||
      type == CommandOptionType.subCommandGroup;
}

bool hasLowercaseVariant(String character) {
  if (character.isEmpty) {
    return false;
  }
  final lower = character.toLowerCase();
  return lower != character;
}

bool containsUppercaseLetterWithLowercaseVariant(String value) {
  for (final rune in value.runes) {
    final character = String.fromCharCode(rune);
    if (character.length == 1 &&
        hasLowercaseVariant(character) &&
        character == character.toUpperCase()) {
      return true;
    }
  }
  return false;
}

int _longestLocalizedLength(
  String defaultValue,
  Map<Locale, String>? localizations,
) {
  var longest = defaultValue.length;
  if (localizations == null || localizations.isEmpty) {
    return longest;
  }
  for (final value in localizations.values) {
    if (value.length > longest) {
      longest = value.length;
    }
  }
  return longest;
}

String _choiceValueLength(dynamic value) {
  if (value == null) {
    return '';
  }
  return value.toString();
}

int _optionPayloadSize(CommandOptionBuilder option) {
  var size = 0;
  size += _longestLocalizedLength(option.name, option.nameLocalizations);
  size += _longestLocalizedLength(
    option.description,
    option.descriptionLocalizations,
  );

  final choices = option.choices;
  if (choices != null) {
    for (final choice in choices) {
      size += _longestLocalizedLength(choice.name, choice.nameLocalizations);
      size += _choiceValueLength(choice.value).length;
    }
  }

  final nested = option.options;
  if (nested != null) {
    for (final child in nested) {
      size += _optionPayloadSize(child);
    }
  }

  return size;
}

/// Combined Discord payload size for a slash command tree.
int computeSlashCommandPayloadSize({
  required String name,
  required String description,
  Map<Locale, String>? nameLocalizations,
  Map<Locale, String>? descriptionLocalizations,
  List<CommandOptionBuilder> options = const [],
}) {
  var size = 0;
  size += _longestLocalizedLength(name, nameLocalizations);
  size += _longestLocalizedLength(description, descriptionLocalizations);
  for (final option in options) {
    size += _optionPayloadSize(option);
  }
  return size;
}

DiscordCommandValidationIssue? validateChatInputNameFormat(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return DiscordCommandValidationIssue.nameRequired;
  }
  if (trimmed.length > discordCommandNameMaxLength) {
    return DiscordCommandValidationIssue.nameTooLong;
  }
  if (!discordChatInputNamePattern.hasMatch(trimmed)) {
    return DiscordCommandValidationIssue.nameInvalidFormat;
  }
  if (containsUppercaseLetterWithLowercaseVariant(trimmed)) {
    return DiscordCommandValidationIssue.nameMustBeLowercase;
  }
  return null;
}

DiscordCommandValidationIssue? validateUserOrMessageNameFormat(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return DiscordCommandValidationIssue.nameRequired;
  }
  if (trimmed.length > discordCommandNameMaxLength) {
    return DiscordCommandValidationIssue.nameTooLong;
  }
  return null;
}

DiscordCommandValidationIssue? validatePrefixCommandNameFormat(
  String name, {
  int maxLength = prefixCommandNameMaxLength,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return DiscordCommandValidationIssue.nameRequired;
  }
  if (trimmed.length > maxLength) {
    return DiscordCommandValidationIssue.nameTooLong;
  }
  return null;
}

DiscordCommandValidationIssue? validateCommandName(
  ApplicationCommandType type,
  String name, {
  bool isPrefixCommand = false,
}) {
  if (isPrefixCommand) {
    return validatePrefixCommandNameFormat(name);
  }

  switch (type) {
    case ApplicationCommandType.chatInput:
      return validateChatInputNameFormat(name);
    case ApplicationCommandType.user:
    case ApplicationCommandType.message:
      return validateUserOrMessageNameFormat(name);
  }
  return null;
}

DiscordCommandValidationIssue? validateDescriptionValue(
  String description, {
  required bool required,
}) {
  final trimmed = description.trim();
  if (required && trimmed.isEmpty) {
    return DiscordCommandValidationIssue.descriptionRequired;
  }
  if (trimmed.length > discordCommandDescriptionMaxLength) {
    return DiscordCommandValidationIssue.descriptionTooLong;
  }
  return null;
}

DiscordCommandValidationIssue? validateChatInputOptionName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return DiscordCommandValidationIssue.nameRequired;
  }
  if (trimmed.length > discordCommandNameMaxLength) {
    return DiscordCommandValidationIssue.nameTooLong;
  }
  if (!discordChatInputNamePattern.hasMatch(trimmed)) {
    return DiscordCommandValidationIssue.optionNameInvalidFormat;
  }
  if (containsUppercaseLetterWithLowercaseVariant(trimmed)) {
    return DiscordCommandValidationIssue.optionNameMustBeLowercase;
  }
  return null;
}

DiscordCommandValidationIssue? validateRequiredOptionsBeforeOptional(
  List<CommandOptionBuilder> options,
) {
  var sawOptional = false;
  for (final option in options) {
    if (isHierarchyOptionType(option.type)) {
      continue;
    }
    final isRequired = option.isRequired == true;
    if (!isRequired) {
      sawOptional = true;
      continue;
    }
    if (sawOptional) {
      return DiscordCommandValidationIssue.optionRequiredBeforeOptional;
    }
  }
  return null;
}

DiscordCommandValidationIssue? validateSlashCommandPayloadSize(int size) {
  if (size > discordSlashCommandPayloadLimit) {
    return DiscordCommandValidationIssue.payloadTooLarge;
  }
  return null;
}
