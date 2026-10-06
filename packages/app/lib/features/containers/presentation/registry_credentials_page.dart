// L'écran des identifiants de registre vit dans `bot_creator_ui` (le Studio
// affiche le même). Ce fichier n'en garde que le point d'entrée de l'app.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/containers/presentation/app_hosted_containers_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class RegistryCredentialsPage extends StatefulWidget {
  final MainApiClient? client;

  const RegistryCredentialsPage({super.key, this.client});

  @override
  State<RegistryCredentialsPage> createState() =>
      _RegistryCredentialsPageState();
}

class _RegistryCredentialsPageState extends State<RegistryCredentialsPage> {
  late final AppHostedContainersHost _host = AppHostedContainersHost(
    client: widget.client,
  );

  @override
  Widget build(BuildContext context) => ui.RegistryCredentialsPage(host: _host);
}
