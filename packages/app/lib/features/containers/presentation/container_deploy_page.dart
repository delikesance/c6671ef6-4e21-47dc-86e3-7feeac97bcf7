// L'écran de déploiement d'une application hébergée vit dans `bot_creator_ui`
// (le Studio affiche le même). Ce fichier n'en garde que le point d'entrée de
// l'app, avec son ancienne signature : `client` injectable (tests, écran
// parent), sinon la session Manager de l'appareil.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/containers/presentation/app_hosted_containers_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class ContainerDeployPage extends StatefulWidget {
  final MainApiClient? client;

  const ContainerDeployPage({super.key, this.client});

  @override
  State<ContainerDeployPage> createState() => _ContainerDeployPageState();
}

class _ContainerDeployPageState extends State<ContainerDeployPage> {
  late final AppHostedContainersHost _host = AppHostedContainersHost(
    client: widget.client,
  );

  @override
  Widget build(BuildContext context) => ui.ContainerDeployPage(host: _host);
}
