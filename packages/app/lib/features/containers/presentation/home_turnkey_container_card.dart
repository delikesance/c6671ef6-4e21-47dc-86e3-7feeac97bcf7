// La carte d'accueil d'un conteneur clé en main vit dans `bot_creator_ui` (le
// Studio peut afficher la même) ; ce fichier la ré-exporte pour les imports
// existants et garde la console de logs ouverte depuis l'accueil, liée au
// client du Manager de l'app.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

export 'package:bot_creator_ui/bot_creator_ui.dart'
    show
        HomeContainerActions,
        HomeTurnkeyContainerCard,
        buildHomeProjectCards,
        turnkeyContainerTitle;

/// Console de logs d'un conteneur clé en main ouverte depuis l'accueil.
///
/// Elle rend EXACTEMENT la même mise en page que le pavé « console » de la page
/// de détail : un seul `ContainerLogsViewer` pour les deux écrans.
class HomeContainerLogsPage extends StatelessWidget {
  const HomeContainerLogsPage({
    super.key,
    required this.client,
    required this.containerId,
    required this.title,
  });

  final MainApiClient client;
  final String containerId;
  final String title;

  @override
  Widget build(BuildContext context) => ui.HomeContainerLogsPage(
    loadLogs: () => client.getContainerLogs(containerId),
    containerId: containerId,
    title: title,
  );
}
