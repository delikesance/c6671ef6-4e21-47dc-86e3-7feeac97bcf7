import 'package:bot_creator/features/bot_editor/logic/app_emoji_api.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';

/// Émojis d'application d'un bot : l'écran vit dans `bot_creator_ui` (partagé
/// avec le Studio) ; l'app parle à Discord avec le jeton local du bot.
class EmojisPage extends StatelessWidget {
  final String botId;

  const EmojisPage({super.key, required this.botId});

  @override
  Widget build(BuildContext context) =>
      EmojisView(controller: _AppEmojisController(botId));
}

class _AppEmojisController extends EmojisController {
  const _AppEmojisController(this.botId);

  final String botId;

  Future<String> _token() async {
    final app = await appManager.getApp(botId);
    final token = (app['token'] ?? '').toString().trim();
    if (token.isEmpty) throw Exception('No token');
    return token;
  }

  @override
  Future<List<AppEmoji>> list() async =>
      AppEmojiApi.listEmojis(await _token(), botId);

  @override
  Future<AppEmoji> create(String name, String imageDataUri) async =>
      AppEmojiApi.createEmoji(await _token(), botId, name, imageDataUri);

  @override
  Future<AppEmoji> rename(String emojiId, String name) async =>
      AppEmojiApi.renameEmoji(await _token(), botId, emojiId, name);

  @override
  Future<void> delete(String emojiId) async =>
      AppEmojiApi.deleteEmoji(await _token(), botId, emojiId);
}
