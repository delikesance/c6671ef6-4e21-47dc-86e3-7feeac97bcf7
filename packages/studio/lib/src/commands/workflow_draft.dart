import 'dart:convert';

import 'action_list.dart';
import 'validation_problem.dart';

/// Copie de travail d'un workflow. Comme [CommandDraft], le JSON d'origine est
/// conservé entier : les champs que le Studio ne comprend pas (arguments,
/// alias d'événement, scripts) repartent tels quels.
class WorkflowDraft implements ActionListHost {
  WorkflowDraft(Map<String, dynamic> raw, {this.revision})
    : _raw = jsonDecode(jsonEncode(raw)) as Map<String, dynamic>,
      _original = jsonEncode(raw);

  /// Un workflow vide. [isNew] le marque modifié : le serveur ne le connaît pas encore.
  factory WorkflowDraft.blank({
    required String name,
    String type = 'general',
    String category = 'messages',
    String event = 'messageCreate',
    String executionMode = 'workflow',
  }) {
    final draft = WorkflowDraft({
      'name': name,
      'workflowType': type,
      'executionMode': executionMode,
      'entryPoint': 'main',
      'arguments': <dynamic>[],
      'actions': <dynamic>[],
      if (type == 'event')
        'eventTrigger': {
          'category': category,
          'event': event,
          'customIdFilter': '',
        },
    });
    draft._original = '';
    return draft;
  }

  final Map<String, dynamic> _raw;
  String _original;
  String? revision;

  String get name => '${_raw['name'] ?? ''}';
  set name(String v) => _raw['name'] = v;

  /// `general` | `event`.
  String get type => '${_raw['workflowType'] ?? 'general'}';

  /// `workflow` | `bdfd_script` | `javascript`.
  String get executionMode => '${_raw['executionMode'] ?? 'workflow'}';

  bool get visual => executionMode == 'workflow';

  bool get isJavascript => executionMode == 'javascript';

  /// Les blocs et les scripts JavaScript s'éditent ici ; un script BDFD reste
  /// en lecture seule (il est renvoyé tel quel).
  bool get editable => visual || isJavascript;

  /// Script d'un workflow JavaScript (jamais mêlé aux blocs : `actions` reste vide).
  String get jsScript => '${_raw['jsScriptContent'] ?? ''}';
  set jsScript(String value) => _raw['jsScriptContent'] = value;

  String get entryPoint => '${_raw['entryPoint'] ?? 'main'}';
  set entryPoint(String value) => _raw['entryPoint'] = value;

  List<String> get argumentNames {
    final raw = _raw['arguments'];
    if (raw is! List) return const [];
    return [
      for (final a in raw)
        if (a is Map && '${a['name'] ?? ''}'.isNotEmpty) '${a['name']}',
    ];
  }

  Map<String, dynamic> get eventTrigger {
    final t = _raw['eventTrigger'];
    return t is Map ? Map<String, dynamic>.from(t) : <String, dynamic>{};
  }

  set eventTrigger(Map<String, dynamic> value) => _raw['eventTrigger'] = value;

  List get _list {
    final raw = _raw['actions'];
    if (raw is List) return raw;
    final created = <dynamic>[];
    _raw['actions'] = created;
    return created;
  }

  @override
  List<Map<String, dynamic>> get actions => [
    for (final e in _list.whereType<Map>()) Map<String, dynamic>.from(e),
  ];

  bool get dirty => jsonEncode(_raw) != _original;

  @override
  void addAction(Map<String, dynamic> action) => _list.add(action);

  @override
  void replaceAction(int index, Map<String, dynamic> action) {
    if (index >= 0 && index < _list.length) _list[index] = action;
  }

  @override
  void moveAction(int index, int delta) {
    final target = index + delta;
    if (index < 0 || index >= _list.length) return;
    if (target < 0 || target >= _list.length) return;
    _list.insert(target, _list.removeAt(index));
  }

  @override
  void removeAction(int index) {
    if (index >= 0 && index < _list.length) _list.removeAt(index);
  }

  @override
  void setActions(List<Map<String, dynamic>> actions) {
    _raw['actions'] = [for (final a in actions) Map<String, dynamic>.from(a)];
  }

  @override
  void toggleAction(int index) {
    if (index < 0 || index >= _list.length || _list[index] is! Map) return;
    final map = _list[index] as Map;
    map['enabled'] = !(map['enabled'] != false);
  }

  /// Refus de validation, ou `null` si le workflow peut être enregistré.
  ValidationProblem? validate() {
    final n = name.trim();
    if (n.isEmpty) {
      return const ValidationProblem(ValidationKind.workflowNameRequired);
    }
    if (n.length > 200) {
      return const ValidationProblem(
        ValidationKind.workflowNameTooLong,
        max: 200,
      );
    }
    if (_list.length > 80) {
      return const ValidationProblem(
        ValidationKind.workflowTooManyBlocks,
        max: 80,
      );
    }
    return null;
  }

  Map<String, dynamic> toRaw() {
    final out = jsonDecode(jsonEncode(_raw)) as Map<String, dynamic>;
    out['name'] = name.trim();
    out['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    return out;
  }
}
