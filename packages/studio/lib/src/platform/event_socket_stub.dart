/// Repli hors navigateur (tests, outils) : aucun temps réel.
class EventSocket {
  EventSocket({
    required this.url,
    required this.token,
    required this.onMessage,
    required this.onClosed,
    this.onData,
  });

  final String url;
  final Future<String?> Function() token;
  final void Function() onMessage;

  /// Le texte de chaque message reçu (le temps réel de l'équipe en lit le type).
  final void Function(String data)? onData;
  final void Function() onClosed;

  Future<void> connect() async => onClosed();

  void close() {}
}
