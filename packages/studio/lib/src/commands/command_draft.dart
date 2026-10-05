import 'dart:convert';

import 'action_list.dart';

/// Copie de travail d'une commande. Le JSON d'origine est conservé ENTIER et
/// seuls les champs édités changent : le serveur réécrit ce que nous envoyons,
/// donc jeter un champ que le Studio ne comprend pas le perdrait pour de bon
/// (c'est la raison pour laquelle l'app transporte aussi `raw` tel quel).
class CommandDraft implements ActionListHost {
  CommandDraft(Map<String, dynamic> raw, {this.revision})
    : _raw = _deepCopy(raw),
      _original = jsonEncode(raw);

  /// Une commande slash vide, prête à être enregistrée. Elle est marquée « modifiée »
  /// d'emblée : tant qu'elle n'est pas enregistrée, le serveur ne la connaît pas.
  factory CommandDraft.blank({
    required String name,
    required String description,
    String triggerType = 'slash',
  }) {
    final draft = CommandDraft({
      'id': newStorageId(),
      'name': name,
      'description': description,
      'type': 'chatInput',
      'data': {
        'commandType': 'chatInput',
        'triggerType': triggerType,
        'executionMode': 'workflow',
        'actions': <dynamic>[],
        'options': <dynamic>[],
      },
    });
    draft.markNew();
    return draft;
  }

  final Map<String, dynamic> _raw;
  String _original;
  String? revision;

  void markNew() => _original = '';

  static Map<String, dynamic> _deepCopy(Map<String, dynamic> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

  String get id => '${_raw['id'] ?? ''}';

  String get name => '${_raw['name'] ?? ''}';
  set name(String value) => _raw['name'] = value;

  String get description => '${_raw['description'] ?? ''}';
  set description(String value) => _raw['description'] = value;

  Map<String, dynamic> get _data {
    final d = _raw['data'];
    if (d is Map<String, dynamic>) return d;
    final created = <String, dynamic>{};
    _raw['data'] = created;
    return created;
  }

  /// `chatInput` | `user` | `message`.
  String get commandType =>
      '${_raw['type'] ?? _data['commandType'] ?? 'chatInput'}';

  /// `slash` | `prefix` | `hybrid` | `none`.
  String get triggerType => '${_data['triggerType'] ?? 'slash'}';

  set commandType(String value) {
    _raw['type'] = value;
    _data['commandType'] = value;
  }

  String get jsScript => '${_data['jsScriptContent'] ?? ''}';
  set jsScript(String value) => _data['jsScriptContent'] = value;

  /// `workflow` | `bdfd_script` | `javascript`.
  String get executionMode => '${_data['executionMode'] ?? 'workflow'}';
  set executionMode(String value) => _data['executionMode'] = value;

  /// Commande « Message Texte » (préfixe) plutôt que slash.
  bool get legacyMode =>
      _data['legacyModeEnabled'] == true || triggerType == 'prefix';
  set legacyMode(bool value) {
    _data['legacyModeEnabled'] = value;
    _data['legacyLocalOnly'] = value;
    _data['triggerType'] = value ? 'prefix' : 'slash';
    if (value) commandType = 'chatInput';
  }

  /// `guildInstall` | `userInstall`.
  List<String> get integrationTypes {
    final raw = _raw['integrationTypes'];
    return raw is List ? [for (final e in raw) '$e'] : const ['guildInstall'];
  }

  set integrationTypes(List<String> value) => _raw['integrationTypes'] = value;

  /// `guild` | `botDm` | `privateChannel`.
  List<String> get contexts {
    final raw = _raw['contexts'];
    return raw is List
        ? [for (final e in raw) '$e']
        : const ['guild', 'botDm', 'privateChannel'];
  }

  set contexts(List<String> value) => _raw['contexts'] = value;

  String get defaultMemberPermissions =>
      '${_data['defaultMemberPermissions'] ?? ''}';
  set defaultMemberPermissions(String value) =>
      _data['defaultMemberPermissions'] = value.trim();

  String get folder => '${_raw['folder'] ?? ''}';
  set folder(String value) {
    final v = value.trim();
    if (v.isEmpty) {
      _raw.remove('folder');
    } else {
      _raw['folder'] = v;
    }
  }

  String get legacyPrefixOverride => '${_data['legacyPrefixOverride'] ?? ''}';
  set legacyPrefixOverride(String value) =>
      _data['legacyPrefixOverride'] = value.trim();

  String get legacyResponseTarget =>
      '${_data['legacyResponseTarget'] ?? 'reply'}';
  set legacyResponseTarget(String value) =>
      _data['legacyResponseTarget'] = value;

  List<String> get legacyAliases {
    final raw = _data['legacyAliases'];
    return raw is List ? [for (final a in raw) '$a'] : const [];
  }

  set legacyAliases(List<String> value) => _data['legacyAliases'] = value;

  @override
  List<Map<String, dynamic>> get actions {
    final raw = _data['actions'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (e) => e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e),
        )
        .toList();
  }

  List get _actionList {
    final raw = _data['actions'];
    if (raw is List) return raw;
    final created = <dynamic>[];
    _data['actions'] = created;
    return created;
  }

  /// Options (arguments) de la commande, telles que Discord les attend.
  List<Map<String, dynamic>> get options {
    final o = _data['options'];
    if (o is! List) return const [];
    return [for (final e in o.whereType<Map>()) Map<String, dynamic>.from(e)];
  }

  set options(List<Map<String, dynamic>> value) => _data['options'] = value;

  int get optionCount {
    final o = _data['options'];
    return o is List ? o.length : 0;
  }

  bool get dirty => jsonEncode(_raw) != _original;

  @override
  void addAction(Map<String, dynamic> action) => _actionList.add(action);

  @override
  void replaceAction(int index, Map<String, dynamic> action) {
    final list = _actionList;
    if (index >= 0 && index < list.length) list[index] = action;
  }

  @override
  void moveAction(int index, int delta) {
    final list = _actionList;
    final target = index + delta;
    if (index < 0 || index >= list.length) return;
    if (target < 0 || target >= list.length) return;
    final item = list.removeAt(index);
    list.insert(target, item);
  }

  @override
  void removeAction(int index) {
    final list = _actionList;
    if (index >= 0 && index < list.length) list.removeAt(index);
  }

  @override
  void setActions(List<Map<String, dynamic>> actions) {
    _data['actions'] = [for (final a in actions) Map<String, dynamic>.from(a)];
  }

  /// Active/désactive un bloc (`enabled`, vrai par défaut).
  @override
  void toggleAction(int index) {
    final list = _actionList;
    if (index < 0 || index >= list.length || list[index] is! Map) return;
    final map = list[index] as Map;
    map['enabled'] = !(map['enabled'] != false);
  }

  /// Message d'erreur lisible, ou `null` si la commande peut être enregistrée.
  String? validate() {
    final n = name.trim();
    if (n.isEmpty) return 'Le nom de la commande est requis.';
    if (n.length > 32) return 'Le nom fait 32 caractères au maximum.';
    if (commandType == 'chatInput' && triggerType != 'prefix') {
      if (!RegExp(r'^[-_\p{L}\p{N}]{1,32}$', unicode: true).hasMatch(n) ||
          n != n.toLowerCase()) {
        return 'Nom invalide : minuscules, chiffres, « - » et « _ » uniquement, sans espace.';
      }
      final d = description.trim();
      if (d.isEmpty) return 'La description est requise.';
      if (d.length > 100) {
        return 'La description fait 100 caractères au maximum.';
      }
    }
    return null;
  }

  /// Le JSON complet à envoyer.
  Map<String, dynamic> toRaw() => _deepCopy(_raw);
}
