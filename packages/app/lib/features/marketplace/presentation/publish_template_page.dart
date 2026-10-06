import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/marketplace/presentation/app_marketplace_controller.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';

/// Publication (ou modification) d'un modèle : l'assistant vit dans
/// `bot_creator_ui` (partagé avec le Studio).
class PublishTemplatePage extends StatelessWidget {
  final String botId;
  final MainApiClient? apiClient;
  final String authorId;
  final String authorName;
  final MarketplaceTemplate? existingTemplate;

  const PublishTemplatePage({
    super.key,
    required this.botId,
    this.apiClient,
    required this.authorId,
    required this.authorName,
    this.existingTemplate,
  });

  @override
  Widget build(BuildContext context) => PublishTemplateView(
    botId: botId,
    controller: AppMarketplaceController(apiClient),
    authorId: authorId,
    authorName: authorName,
    existingTemplate: existingTemplate,
  );
}
