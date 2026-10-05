import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/marketplace/presentation/app_marketplace_controller.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';

/// Détail d'un modèle du marketplace : l'écran vit dans `bot_creator_ui`.
class MarketplaceDetailPage extends StatelessWidget {
  final MarketplaceTemplate template;
  final String botId;
  final MainApiClient? apiClient;

  const MarketplaceDetailPage({
    super.key,
    required this.template,
    required this.botId,
    this.apiClient,
  });

  @override
  Widget build(BuildContext context) => MarketplaceDetailView(
    template: template,
    botId: botId,
    controller: AppMarketplaceController(apiClient),
  );
}
