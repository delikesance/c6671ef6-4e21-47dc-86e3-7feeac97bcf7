/// Repli hors navigateur (tests, outils) : aucun temps réel.
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

  Future<void> connect() async => onClosed();

  void close() {}
}
