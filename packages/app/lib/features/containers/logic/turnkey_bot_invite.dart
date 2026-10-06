// Le parcours d'invitation du bot d'un conteneur clé en main vit dans
// `bot_creator_ui` (le Studio l'utilise aussi). Ce fichier garde le service
// avec son ancienne signature : un `MainApiClient` du Manager.
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/containers/presentation/app_hosted_containers_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;

export 'package:bot_creator_ui/bot_creator_ui.dart'
    show BotInviteOutcome, botInviteOutcomeMessage;

class TurnkeyBotInviteService extends ui.TurnkeyBotInviteService {
  TurnkeyBotInviteService({required MainApiClient? client, super.openUrl})
    : super(host: AppHostedContainersHost(client: client));
}
