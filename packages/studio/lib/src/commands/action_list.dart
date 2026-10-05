import 'dart:math';

/// Ce qu'un éditeur de blocs attend d'un brouillon (commande ou workflow) :
/// lire la liste d'actions et la modifier sur place.
abstract class ActionListHost {
  List<Map<String, dynamic>> get actions;
  void addAction(Map<String, dynamic> action);
  void replaceAction(int index, Map<String, dynamic> action);
  void moveAction(int index, int delta);
  void removeAction(int index);
  void toggleAction(int index);

  /// Remplace toute la séquence (l'éditeur partagé renvoie la liste entière).
  void setActions(List<Map<String, dynamic>> actions);
}

/// Charges utiles de départ des blocs les plus courants : les clés que l'app
/// écrit pour ces types (`payload`). Un type absent démarre avec une charge
/// vide, qui se complète dans l'éditeur de paramètres.
const Map<String, Map<String, dynamic>> actionTemplates = {
  'sendMessage': {'content': ''},
  'editMessage': {'content': ''},
  'deleteMessages': {'count': 1},
  'pinMessage': {},
  'addReaction': {'emoji': ''},
  'createChannel': {'name': ''},
  'banUser': {'reason': ''},
  'kickUser': {'reason': ''},
  'muteUser': {'duration': '10m', 'reason': ''},
  'addRole': {'roleId': ''},
  'removeRole': {'roleId': ''},
  'httpRequest': {'method': 'GET', 'url': ''},
  'setGlobalVariable': {'key': '', 'value': ''},
  'getGlobalVariable': {'key': ''},
};

/// Un bloc neuf du type [type], activé, avec sa charge utile de départ.
Map<String, dynamic> newAction(String type) => {
  'type': type,
  'key': 'a_${_token(6)}',
  'enabled': true,
  'payload': Map<String, dynamic>.from(actionTemplates[type] ?? const {}),
};

final _rng = Random();

String _token(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  return List.generate(length, (_) => chars[_rng.nextInt(chars.length)]).join();
}

/// Identifiant de stockage d'une commande créée dans le Studio (UUID v4).
String newStorageId() {
  final bytes = List<int>.generate(16, (_) => _rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int from, int to) => bytes
      .sublist(from, to)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
