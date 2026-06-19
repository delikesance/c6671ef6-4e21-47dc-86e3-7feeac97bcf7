import 'dart:ui' as ui;
import 'package:bot_creator/core/i18n/app_locale.dart'
    show detectSystemLocale;
import 'package:bot_creator/core/i18n/l10n/app_localizations.dart'
    show lookupAppLocalizations;
import 'package:bot_creator_shared/types/component.dart';

/// Shared factory for creating [ComponentNode] instances by their [ComponentV2Type].
///
/// Extracted from both [ComponentV2EditorWidget] and [NormalComponentEditorWidget]
/// to eliminate duplication and ensure consistent default values across editors.
abstract class ComponentNodeFactory {
  /// Returns a locale that is guaranteed to be supported.
  static ui.Locale _supportedLocale() {
    return ui.Locale(detectSystemLocale(ui.PlatformDispatcher.instance.locale).code);
  }

  /// Creates a new [ComponentNode] with sensible defaults for the given [type].
  static ComponentNode create(ComponentV2Type type) {
    final locale = _supportedLocale();
    return switch (type) {
      ComponentV2Type.actionRow => ActionRowNode(),
      ComponentV2Type.button => ButtonNode(),
      ComponentV2Type.stringSelect => SelectMenuNode(
        type: ComponentV2Type.stringSelect,
        options: [
          SelectMenuOption(
            label:
                lookupAppLocalizations(locale).component_default_option_label,
            value: 'option',
          ),
        ],
      ),
      ComponentV2Type.userSelect => SelectMenuNode(
        type: ComponentV2Type.userSelect,
      ),
      ComponentV2Type.roleSelect => SelectMenuNode(
        type: ComponentV2Type.roleSelect,
      ),
      ComponentV2Type.mentionableSelect => SelectMenuNode(
        type: ComponentV2Type.mentionableSelect,
      ),
      ComponentV2Type.channelSelect => SelectMenuNode(
        type: ComponentV2Type.channelSelect,
      ),
      ComponentV2Type.categorySelect => SelectMenuNode(
        type: ComponentV2Type.categorySelect,
        placeholder: 'Select a category...',
      ),
      ComponentV2Type.section => SectionNode(components: [TextDisplayNode()]),
      ComponentV2Type.textDisplay => TextDisplayNode(),
      ComponentV2Type.thumbnail => ThumbnailNode(),
      ComponentV2Type.mediaGallery => MediaGalleryNode(
        items: [MediaGalleryItemNode()],
      ),
      ComponentV2Type.file => FileNode(),
      ComponentV2Type.separator => SeparatorNode(),
      ComponentV2Type.container => ContainerNode(
        components: [TextDisplayNode()],
      ),
      ComponentV2Type.label => LabelNode(
        label: lookupAppLocalizations(locale).common_label,
        component: TextDisplayNode(),
      ),
      ComponentV2Type.fileUpload => FileUploadNode(),
      ComponentV2Type.radioGroup => RadioGroupNode(
        options: [
          RadioGroupOptionNode(
            label:
                lookupAppLocalizations(locale).component_default_choice_label,
            value: 'a',
          ),
        ],
      ),
      ComponentV2Type.checkboxGroup => CheckboxGroupNode(
        options: [
          CheckboxGroupOptionNode(
            label:
                lookupAppLocalizations(locale).component_default_choice_label,
            value: 'a',
          ),
        ],
      ),
      ComponentV2Type.checkbox => CheckboxNode(),
      ComponentV2Type.textInput => ModalTextInputNode(),
    };
  }

  /// Returns a human-readable label for a [ComponentV2Type].
  static String labelFor(ComponentV2Type type) {
    final name = type.name;
    return name[0].toUpperCase() +
        name
            .substring(1)
            .replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m.group(0)}');
  }
}
