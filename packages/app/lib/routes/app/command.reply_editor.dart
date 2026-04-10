import 'package:bot_creator/types/app_emoji.dart';
import 'package:bot_creator/types/variable_suggestion.dart';
import 'package:bot_creator/widgets/command_create_cards/reply_card.dart';
import 'package:flutter/material.dart';
import '../../utils/i18n.dart';

class CommandReplyEditorPage extends StatefulWidget {
  const CommandReplyEditorPage({
    super.key,
    required this.initialResponseType,
    required this.initialResponseText,
    required this.initialEmbeds,
    required this.initialComponents,
    required this.initialModal,
    required this.initialWorkflow,
    required this.normalizeWorkflow,
    required this.variableSuggestions,
    this.emojiSuggestions,
    this.botIdForConfig,
    this.allowModal = true,
  });

  final String initialResponseType;
  final String initialResponseText;
  final List<Map<String, dynamic>> initialEmbeds;
  final Map<String, dynamic> initialComponents;
  final Map<String, dynamic> initialModal;
  final Map<String, dynamic> initialWorkflow;
  final Map<String, dynamic> Function(Map<String, dynamic>) normalizeWorkflow;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;
  final String? botIdForConfig;
  final bool allowModal;

  @override
  State<CommandReplyEditorPage> createState() => _CommandReplyEditorPageState();
}

class _CommandReplyEditorPageState extends State<CommandReplyEditorPage> {
  late final TextEditingController _responseController;
  late String _responseType;
  late List<Map<String, dynamic>> _responseEmbeds;
  late Map<String, dynamic> _responseComponents;
  late Map<String, dynamic> _responseModal;
  late Map<String, dynamic> _responseWorkflow;

  @override
  void initState() {
    super.initState();
    _responseType = widget.initialResponseType;
    _responseController = TextEditingController(
      text: widget.initialResponseText,
    );
    _responseEmbeds = widget.initialEmbeds
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    _responseComponents = Map<String, dynamic>.from(widget.initialComponents);
    _responseModal = Map<String, dynamic>.from(widget.initialModal);
    _responseWorkflow = widget.normalizeWorkflow(
      Map<String, dynamic>.from(widget.initialWorkflow),
    );
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(context, <String, dynamic>{
      'responseType': _responseType,
      'responseText': _responseController.text,
      'responseEmbeds': _responseEmbeds,
      'responseComponents': _responseComponents,
      'responseModal': _responseModal,
      'responseWorkflow': _responseWorkflow,
    });
  }

  Widget _buildSuggestionBar() {
    if (widget.variableSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    final suggestions = widget.variableSuggestions
        .take(10)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions
            .map(
              (suggestion) => ActionChip(
                label: Text('((${suggestion.name}))'),
                onPressed: () {
                  final current = _responseController.text;
                  final next =
                      current.isEmpty
                          ? '((${suggestion.name}))'
                          : '$current ((${suggestion.name}))';
                  _responseController.text = next;
                  _responseController.selection = TextSelection.collapsed(
                    offset: _responseController.text.length,
                  );
                  setState(() {});
                },
              ),
            )
            .toList(growable: false),
      ),
    );
  }

  String _workflowSummary() {
    final visibility =
        _responseWorkflow['visibility'] == 'ephemeral'
            ? context.tr.workflow_visibility_ephemeral
            : context.tr.workflow_visibility_public;
    final autoDefer = _responseWorkflow['autoDeferIfActions'] != false;
    final conditional = Map<String, dynamic>.from(
      (_responseWorkflow['conditional'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final conditionEnabled = conditional['enabled'] == true;
    final modeLabel =
        _responseWorkflow['workflowMode'] == 'bdfd'
            ? context.tr.workflow_mode_bdfd
            : context.tr.workflow_mode_visual;
    return '$modeLabel | ${autoDefer ? context.tr.workflow_auto_defer : context.tr.workflow_manual} | $visibility | ${conditionEnabled ? context.tr.workflow_condition_on : context.tr.workflow_condition_off}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.reply_editor_title),
        actions: [
          TextButton(onPressed: _save, child: Text(context.tr.common_save)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ReplyCard(
              responseType: _responseType,
              onResponseTypeChanged: (type) {
                setState(() {
                  _responseType = type;
                });
              },
              responseController: _responseController,
              variableSuggestionBar: _buildSuggestionBar(),
              responseEmbeds: _responseEmbeds,
              onEmbedsChanged: (embeds) {
                setState(() {
                  _responseEmbeds = embeds;
                });
              },
              responseComponents: _responseComponents,
              onComponentsChanged: (components) {
                setState(() {
                  _responseComponents = components;
                });
              },
              responseModal: _responseModal,
              onModalChanged: (modal) {
                setState(() {
                  _responseModal = modal;
                });
              },
              responseWorkflow: _responseWorkflow,
              normalizeWorkflow: widget.normalizeWorkflow,
              variableSuggestions: widget.variableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              botIdForConfig: widget.botIdForConfig,
              onWorkflowChanged: (workflow) {
                setState(() {
                  _responseWorkflow = widget.normalizeWorkflow(workflow);
                });
              },
              workflowSummary: _workflowSummary(),
              allowModal: widget.allowModal,
            ),
          ],
        ),
      ),
    );
  }
}
