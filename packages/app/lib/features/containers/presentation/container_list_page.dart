// L'écran « Applications hébergées » vit dans `bot_creator_ui` (le Studio
// affiche le même). Ce fichier n'en garde que le point d'entrée de l'app : la
// session Manager de l'appareil, les publicités récompensées et l'achat natif
// (voir `AppHostedContainersHost`).
import 'package:bot_creator/features/containers/presentation/app_hosted_containers_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class ContainerListPage extends StatefulWidget {
  const ContainerListPage({super.key});

  @override
  State<ContainerListPage> createState() => _ContainerListPageState();
}

class _ContainerListPageState extends State<ContainerListPage> {
  // Un seul hôte pour la vie de la page : il garde le client du Manager.
  late final AppHostedContainersHost _host = AppHostedContainersHost();

  @override
  Widget build(BuildContext context) => ui.ContainerListPage(host: _host);
}
