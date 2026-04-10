part of 'command.create.dart';

extension _CommandCreateWorkflow on _CommandCreatePageState {
  List<Map<String, dynamic>> _normalizeEmbedsPayload(dynamic rawEmbeds) {
    return normalizeResponseEmbedsPayload(rawEmbeds);
  }

  Map<String, dynamic> _normalizeWorkflow(Map<String, dynamic> input) {
    final conditional = Map<String, dynamic>.from(
      (input['conditional'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

    final mode = input['workflowMode']?.toString();

    return {
      'workflowMode': (mode == 'bdfd') ? 'bdfd' : 'visual',
      'bdfdScriptContent': (input['bdfdScriptContent'] ?? '').toString(),
      'autoDeferIfActions': input['autoDeferIfActions'] != false,
      'visibility':
          (input['visibility']?.toString().toLowerCase() == 'ephemeral')
              ? 'ephemeral'
              : 'public',
      'onError': 'edit_error',
      'conditional': {
        'enabled': conditional['enabled'] == true,
        'variable': (conditional['variable'] ?? '').toString(),
        'whenTrueType': (conditional['whenTrueType'] ?? 'normal').toString(),
        'whenFalseType': (conditional['whenFalseType'] ?? 'normal').toString(),
        'whenTrueText': (conditional['whenTrueText'] ?? '').toString(),
        'whenFalseText': (conditional['whenFalseText'] ?? '').toString(),
        'whenTrueEmbeds': _normalizeEmbedsPayload(
          conditional['whenTrueEmbeds'],
        ),
        'whenFalseEmbeds': _normalizeEmbedsPayload(
          conditional['whenFalseEmbeds'],
        ),
        'whenTrueNormalComponents': Map<String, dynamic>.from(
          (conditional['whenTrueNormalComponents'] as Map?)
                  ?.cast<String, dynamic>() ??
              const {},
        ),
        'whenFalseNormalComponents': Map<String, dynamic>.from(
          (conditional['whenFalseNormalComponents'] as Map?)
                  ?.cast<String, dynamic>() ??
              const {},
        ),
        'whenTrueComponents': Map<String, dynamic>.from(
          (conditional['whenTrueComponents'] as Map?)
                  ?.cast<String, dynamic>() ??
              const {},
        ),
        'whenFalseComponents': Map<String, dynamic>.from(
          (conditional['whenFalseComponents'] as Map?)
                  ?.cast<String, dynamic>() ??
              const {},
        ),
        'whenTrueModal': Map<String, dynamic>.from(
          (conditional['whenTrueModal'] as Map?)?.cast<String, dynamic>() ??
              const {},
        ),
        'whenFalseModal': Map<String, dynamic>.from(
          (conditional['whenFalseModal'] as Map?)?.cast<String, dynamic>() ??
              const {},
        ),
      },
    };
  }

  String _workflowSummary() {
    final visibility =
        _responseWorkflow['visibility'] == 'ephemeral'
            ? context.tr.workflow_visibility_ephemeral
            : context.tr.workflow_visibility_public;
    final autoDefer = _responseWorkflow['autoDeferIfActions'] != false;
    final conditional = Map<String, dynamic>.from(
      (_responseWorkflow['conditional'] as Map?)?.cast<String, dynamic>() ??
          const {},
    );
    final conditionEnabled = conditional['enabled'] == true;
    final conditionLabel =
        conditionEnabled
            ? context.tr.workflow_condition_on_upper
            : context.tr.workflow_condition_off_upper;

    final isBdfd = _responseWorkflow['workflowMode'] == 'bdfd';
    final modeLabel =
        isBdfd
            ? context.tr.workflow_mode_bdfd
            : context.tr.workflow_mode_visual;

    return '$modeLabel \u2022 ${autoDefer ? context.tr.workflow_auto_defer_actions : context.tr.workflow_no_auto_defer} \u2022 $visibility \u2022 $conditionLabel';
  }
}
