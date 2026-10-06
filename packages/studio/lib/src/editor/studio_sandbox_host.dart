import 'package:bot_creator_ui/bot_creator_ui.dart';

import '../api/studio_api.dart';

/// Le bac à sable de commandes tel que le Studio l'exécute : sur le runner du
/// bot, par le Manager (`/gateway/bots/{id}/sandbox/*`). Les écrans
/// (`CommandSandboxPage`, `SandboxFunctionsPage`) sont ceux de l'app.
///
/// Le Studio n'exécute rien lui-même. Le Manager résout le runner DU BOT : bot
/// arrêté ou non assigné, il répond 404/409/502/503 — ce que l'écran affiche
/// comme « démarrez le bot », pas comme un code HTTP.
class StudioSandboxHost extends SandboxHost {
  const StudioSandboxHost(this.api, {required this.botId});

  final StudioApi api;
  final String botId;

  @override
  bool get isRemote => true;

  @override
  Future<Map<String, dynamic>> runCommand(Map<String, dynamic> request) =>
      _guard(() => api.sandboxCommandWire(botId, request));

  @override
  Future<List<SandboxFunctionCaseInfo>> loadFunctionCases() async {
    final wire = await _guard(() => api.sandboxFunctionsWire(botId));
    final raw = wire['cases'];
    if (raw is! List) return const [];
    return [
      for (final item in raw.whereType<Map>())
        SandboxFunctionCaseInfo.fromWire(Map<String, dynamic>.from(item)),
    ];
  }

  /// Traduit les refus du serveur en ce que l'écran sait dire.
  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on StudioApiException catch (e) {
      if (_isRunnerUnavailable(e)) {
        throw SandboxUnavailableException('${e.statusCode} ${e.code ?? ''}');
      }
      switch (e.code) {
        case 'payload_too_large':
        case 'sandbox_timeout':
        case 'sandbox_busy':
        case 'invalid_request':
          throw SandboxRunException(e.message, code: e.code);
      }
      // Mêmes refus quand un intermédiaire a réécrit le corps d'erreur.
      switch (e.statusCode) {
        case 413:
          throw SandboxRunException(e.message, code: 'payload_too_large');
        case 504:
          throw SandboxRunException(e.message, code: 'sandbox_timeout');
        case 429:
          throw SandboxRunException(e.message, code: 'sandbox_busy');
      }
      rethrow;
    }
  }

  /// Aucun runner joignable pour ce bot : arrêté, non assigné au pool, ou le
  /// nœud ne répond pas. Un 404 `bot_not_found` n'en fait PAS partie (le bot
  /// n'est pas accessible : le message du serveur dit la vérité).
  static bool _isRunnerUnavailable(StudioApiException e) {
    final code = (e.code ?? '').toLowerCase();
    if (code.startsWith('runner_')) return true;
    return e.statusCode == 409 || e.statusCode == 502 || e.statusCode == 503;
  }
}
