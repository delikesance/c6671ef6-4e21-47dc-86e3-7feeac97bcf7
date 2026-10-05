import 'dart:convert';

/// Copie de travail d'une commande. Le JSON d'origine est conservé ENTIER et
/// seuls les champs édités changent : le serveur réécrit ce que nous envoyons,
/// donc jeter un champ que le Studio ne comprend pas le perdrait pour de bon
/// (c'est la raison pour laquelle l'app transporte aussi `raw` tel quel).
class CommandDraft {
  CommandDraft(Map<String, dynamic> raw, {this.revision})
    : _raw = _deepCopy(raw),
      _original = jsonEncode(raw);

  final Map<String, dynamic> _raw;
  final String _original;
  String? revision;

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

  /// `workflow` | `bdfd_script` | `javascript`.
  String get executionMode => '${_data['executionMode'] ?? 'workflow'}';

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

  int get optionCount {
    final o = _data['options'];
    return o is List ? o.length : 0;
  }

  bool get dirty => jsonEncode(_raw) != _original;

  void moveAction(int index, int delta) {
    final list = _actionList;
    final target = index + delta;
    if (index < 0 || index >= list.length) return;
    if (target < 0 || target >= list.length) return;
    final item = list.removeAt(index);
    list.insert(target, item);
  }

  void removeAction(int index) {
    final list = _actionList;
    if (index >= 0 && index < list.length) list.removeAt(index);
  }

  /// Active/désactive un bloc (`enabled`, vrai par défaut).
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
