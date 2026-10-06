import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';

import '../l10n_ext.dart';

/// Nature d'un refus de validation d'une commande, d'un workflow ou d'options.
enum ValidationKind {
  commandNameRequired,
  commandNameTooLong,
  commandNameInvalid,
  descriptionRequired,
  descriptionTooLong,
  workflowNameRequired,
  workflowNameTooLong,
  workflowTooManyBlocks,
  optionsTooMany,
  optionNameInvalid,
  optionDuplicate,
  optionDescriptionInvalid,
  optionRequiredOrder,
}

/// Un refus de validation SANS texte : la couche métier (brouillons) ne connaît
/// ni la langue ni le `BuildContext`, l'écran appelle [message] pour l'afficher.
class ValidationProblem {
  const ValidationProblem(this.kind, {this.name = '', this.max = 0});

  final ValidationKind kind;

  /// Nom de l'option concernée, quand il y en a un.
  final String name;

  /// Limite dépassée (caractères, blocs), quand il y en a une.
  final int max;

  /// Le refus dans la langue de l'écran.
  String text(BuildContext context) => message(context.l10n, context.tr);

  /// Le refus dans une langue donnée, sans écran (retours d'outils faits pour
  /// le modèle, tests).
  String inLanguage(String languageCode) {
    final locale = Locale(languageCode);
    return message(
      lookupStudioLocalizations(locale),
      lookupAppLocalizations(locale),
    );
  }

  /// Texte dans la langue des traductions fournies : celles du Studio [l] et
  /// celles de l'app [tr] (les messages identiques à ceux de l'app en viennent).
  String message(StudioLocalizations l, AppLocalizations tr) => switch (kind) {
    ValidationKind.commandNameRequired => tr.validation_command_name_required,
    ValidationKind.commandNameTooLong => tr.validation_command_name_length(max),
    ValidationKind.commandNameInvalid => l.validationCommandNameFormat,
    ValidationKind.descriptionRequired => tr.command_description_required,
    ValidationKind.descriptionTooLong => l.validationDescriptionTooLong(max),
    ValidationKind.workflowNameRequired => l.validationWorkflowNameRequired,
    ValidationKind.workflowNameTooLong => l.validationWorkflowNameTooLong(max),
    ValidationKind.workflowTooManyBlocks => l.validationWorkflowTooManyBlocks(
      max,
    ),
    ValidationKind.optionsTooMany => tr.validation_option_max_entries,
    ValidationKind.optionNameInvalid => l.validationOptionNameInvalid(name),
    ValidationKind.optionDuplicate => tr.validation_option_name_duplicate(name),
    ValidationKind.optionDescriptionInvalid => l.validationOptionDescription(
      name,
    ),
    ValidationKind.optionRequiredOrder => l.validationOptionRequiredOrder(name),
  };
}
