import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/utils/i18n.dart';

bool isHierarchyOptionType(CommandOptionType type) {
  return type == CommandOptionType.subCommand ||
      type == CommandOptionType.subCommandGroup;
}

bool isLeafOptionType(CommandOptionType type) {
  return !isHierarchyOptionType(type);
}

/// Validates a list of [CommandOptionBuilder] entries according to Discord's
/// slash-command hierarchy rules.
///
/// Call with [level] = 0 and [parentType] = null for the root option list.
/// Returns a human-readable error message string, or `null` if valid.
String? validateOptionsForLevel(
  List<CommandOptionBuilder> options, {
  required int level,
  required CommandOptionType? parentType,
}) {
  if (options.length > 25) {
    return AppStrings.t('validation_option_max_entries');
  }

  if (level == 0) {
    final hasHierarchy = options.any(
      (option) => isHierarchyOptionType(option.type),
    );
    final hasLeaf = options.any((option) => isLeafOptionType(option.type));
    if (hasHierarchy && hasLeaf) {
      return AppStrings.t('validation_option_no_mix_top_level');
    }
  }

  if (parentType == CommandOptionType.subCommandGroup &&
      options.any((option) => option.type != CommandOptionType.subCommand)) {
    return AppStrings.t('validation_option_group_only_subcommands');
  }

  if (parentType == CommandOptionType.subCommand &&
      options.any((option) => isHierarchyOptionType(option.type))) {
    return AppStrings.t('validation_option_subcommand_no_nested');
  }

  final seenNames = <String>{};
  for (final option in options) {
    final optionName = option.name.trim();
    if (optionName.isEmpty) {
      return AppStrings.t('validation_option_name_required');
    }
    if (!seenNames.add(optionName)) {
      return AppStrings.tr(
        'validation_option_name_duplicate',
        params: {'name': optionName},
      );
    }
    if (option.description.trim().isEmpty) {
      return AppStrings.t('validation_option_description_required');
    }

    final nestedOptions = option.options ?? <CommandOptionBuilder>[];
    if (isLeafOptionType(option.type) && nestedOptions.isNotEmpty) {
      return AppStrings.t('validation_option_leaf_no_nested');
    }

    if (option.type == CommandOptionType.subCommand ||
        option.type == CommandOptionType.subCommandGroup) {
      if (option.isRequired == true) {
        return AppStrings.t('validation_option_hierarchy_not_required');
      }
      if (option.choices?.isNotEmpty == true) {
        return AppStrings.t('validation_option_hierarchy_no_choices');
      }
      if (option.minValue != null || option.maxValue != null) {
        return AppStrings.t('validation_option_hierarchy_no_min_max');
      }
    }

    if (option.type == CommandOptionType.subCommandGroup && level > 0) {
      return AppStrings.t('validation_option_group_top_level_only');
    }

    if (option.type == CommandOptionType.subCommand && level > 1) {
      return AppStrings.t('validation_option_subcommand_depth');
    }

    if (option.type == CommandOptionType.subCommandGroup) {
      final nestedError = validateOptionsForLevel(
        nestedOptions,
        level: level + 1,
        parentType: CommandOptionType.subCommandGroup,
      );
      if (nestedError != null) return nestedError;
    } else if (option.type == CommandOptionType.subCommand) {
      final nestedError = validateOptionsForLevel(
        nestedOptions,
        level: level + 1,
        parentType: CommandOptionType.subCommand,
      );
      if (nestedError != null) return nestedError;
    }
  }

  return null;
}
