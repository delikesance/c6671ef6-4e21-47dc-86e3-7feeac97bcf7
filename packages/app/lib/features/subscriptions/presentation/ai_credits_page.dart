// Moved to package:bot_creator_ui (shared with Studio) : l'écran « Crédits IA »
// est `AICreditsPage` du paquet, monté sur `AppAiCreditsHost` (client Manager,
// publicités récompensées, roulette, packs de boutique). Ce fichier garde
// l'ancienne signature (`AICreditsPage(api: …)`).
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/subscriptions/presentation/app_subscriptions_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class AICreditsPage extends StatefulWidget {
  const AICreditsPage({super.key, this.api});
  final MainApiClient? api;

  @override
  State<AICreditsPage> createState() => _AICreditsPageState();
}

class _AICreditsPageState extends State<AICreditsPage> {
  // Un hôte par écran : il garde le client résolu et les packs affichés.
  late final AppAiCreditsHost _host = AppAiCreditsHost(api: widget.api);

  @override
  Widget build(BuildContext context) => ui.AICreditsPage(host: _host);
}
