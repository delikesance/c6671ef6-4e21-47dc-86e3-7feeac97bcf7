import './bdfd_script_language.dart';
import './bdfd_syntax_controller.dart';
import './script_editor_scaffold.dart';
import '../l10n/tr_extension.dart';
import './editor_theme_scope.dart';
import '../editor/models/app_emoji.dart';
import '../docs/documentation_hub_page.dart';
import '../docs/documentation_urls.dart';
import 'package:flutter/material.dart';

/// Éditeur de script BDFD.
///
/// Coquille mince sur le chrome d'éditeur partagé : elle ne porte que ce qui
/// est propre à BDFD — les libellés, la couche langage
/// ([BdfdScriptLanguage]) et le contrôleur de coloration
/// ([BdfdSyntaxController]). Le `Scaffold`, la barre d'application, le corps
/// d'édition, la barre de caractères rapides et la barre de diagnostics
/// appartiennent au chrome.
///
/// Le texte édité est renvoyé par `Navigator.pop(context, texte)`, comme
/// avant la migration : les trois sites d'appel poussent cette page en route.
class BdfdEditorPage extends StatefulWidget {
  const BdfdEditorPage({
    super.key,
    required this.initialCode,
    this.title,
    this.bdfdBackend = 'native-v1',
    this.appEmojis = const [],
  });

  final String initialCode;
  final String? title;
  final String bdfdBackend;
  final List<AppEmoji> appEmojis;

  @override
  State<BdfdEditorPage> createState() => _BdfdEditorPageState();
}

class _BdfdEditorPageState extends State<BdfdEditorPage> {
  late final BdfdSyntaxController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BdfdSyntaxController(text: widget.initialCode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La palette résolue par les réglages est poussée dans le contrôleur sans
    // jamais le recréer : sélection, défilement et undo sont préservés.
    _controller.themeColors = codeEditorColorsOf(context);
  }

  @override
  void dispose() {
    // Le contrôleur appartient à la page (le chrome ne libère que le sien).
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = BdfdScriptLanguage(
      appEmojis: widget.appEmojis,
      backend: widget.bdfdBackend,
    );

    return ScriptEditorScaffold(
      title: widget.title ?? context.tr.bdfd_editor_title,
      initialCode: widget.initialCode,
      controller: _controller,
      language: language,
      hintText: context.tr.cmd_bdfd_script_hint,
      uxSheetTitle: context.tr.bdfd_editor_ux_title,
      uxSheetBullets: <String>[
        context.tr.bdfd_editor_includes,
        context.tr.bdfd_editor_auto_indent,
        context.tr.bdfd_editor_indent_guides,
        context.tr.bdfd_editor_quick_keys,
      ],
      onOpenDocs: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const DocumentationHubPage(
            initialSection: DocumentationSection.botCreatorDocs,
          ),
        ),
      ),
      messageBuilder: language.describe,
      emptyLabel: context.tr.bdfd_editor_empty,
      cleanLabel: context.tr.cmd_bdfd_diagnostics_clean,
    );
  }
}
