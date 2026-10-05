import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Canal temps réel du Manager (`/gateway/bots/events`).
///
/// Un navigateur ne peut pas poser d'en-tête `Authorization` sur un
/// WebSocket : le jeton voyage dans le sous-protocole
/// `Sec-WebSocket-Protocol: bc.bearer, <jeton>` (jamais dans l'URL, qui finit
/// dans les journaux des proxys). Le serveur répond `bc.bearer`.
class EventSocket {
  EventSocket({
    required this.url,
    required this.token,
    required this.onMessage,
    required this.onClosed,
  });

  final String url;
  final Future<String?> Function() token;
  final void Function() onMessage;
  final void Function() onClosed;

  web.WebSocket? _socket;
  bool _closed = false;

  Future<void> connect() async {
    final jwt = await token();
    if (_closed) return;
    if (jwt == null || jwt.isEmpty) {
      onClosed();
      return;
    }
    final protocols = <JSString>['bc.bearer'.toJS, jwt.toJS].toJS;
    final socket = web.WebSocket(url, protocols);
    _socket = socket;
    socket.onmessage = ((web.MessageEvent _) {
      if (!_closed) onMessage();
    }).toJS;
    socket.onclose = ((web.CloseEvent _) {
      if (!_closed) onClosed();
    }).toJS;
    socket.onerror = ((web.Event _) {
      // `onclose` suit toujours une erreur de connexion : une seule sortie.
    }).toJS;
  }

  void close() {
    _closed = true;
    _socket?.close();
    _socket = null;
  }
}
