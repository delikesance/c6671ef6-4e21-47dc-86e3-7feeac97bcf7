import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/marketplace/presentation/app_marketplace_controller.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';

/// Marketplace de l'app : l'écran vit dans `bot_creator_ui` (partagé avec le
/// Studio) ; l'app lui donne son catalogue authentifié et sa façon d'appliquer
/// un modèle (stockage local + enregistrement Discord).
class MarketplacePage extends StatelessWidget {
  final String botId;
  final MainApiClient? apiClient;

  const MarketplacePage({super.key, required this.botId, this.apiClient});

  @override
  Widget build(BuildContext context) => MarketplaceView(
    botId: botId,
    controller: AppMarketplaceController(apiClient),
  );
}
