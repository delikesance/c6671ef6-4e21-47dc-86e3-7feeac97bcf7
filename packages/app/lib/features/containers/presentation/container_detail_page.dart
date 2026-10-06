// L'écran de détail d'une application hébergée et sa console de logs vivent
// dans `bot_creator_ui` (le Studio affiche les mêmes). Ce fichier n'en garde
// que les points d'entrée de l'app, avec leurs anciennes signatures.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/containers/presentation/app_hosted_containers_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

/// La console (`ContainerLogsViewer`, lue par `loadLogs`) et son analyse de
/// lignes, ré-exportées pour les imports existants.
export 'package:bot_creator_ui/bot_creator_ui.dart'
    show
        ContainerLogLine,
        ContainerLogRow,
        ContainerLogsViewer,
        ContainerLogSeverity,
        parseContainerLogLines;

class ContainerDetailPage extends StatefulWidget {
  final String containerId;
  final MainApiClient? client;

  const ContainerDetailPage({
    super.key,
    required this.containerId,
    this.client,
  });

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage> {
  late final AppHostedContainersHost _host = AppHostedContainersHost(
    client: widget.client,
  );

  @override
  Widget build(BuildContext context) =>
      ui.ContainerDetailPage(containerId: widget.containerId, host: _host);
}
