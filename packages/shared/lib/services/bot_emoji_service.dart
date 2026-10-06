import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'bot_guild_query_service.dart';
import 'bot_permission_query_service.dart';

class BotEmoji {
  const BotEmoji({
    required this.id,
    required this.name,
    required this.guildId,
    this.animated = false,
    this.creatorId,
  });
  final String id;
  final String name;
  final String guildId;
  final bool animated;
  final String? creatorId;
  String get mention => '<${animated ? 'a' : ''}:$name:$id>';
}

class BotEmojiCreateRequest {
  const BotEmojiCreateRequest({required this.name, required this.imageUrl});
  final String name;
  final String imageUrl;
  void validate() {
    if (name.trim().isEmpty) throw ArgumentError('Emoji name is required.');
    _url(imageUrl);
  }
}

abstract interface class BotEmojiService {
  Future<BotEmoji?> emoji(String id, {required CommandExecutionBudget budget});
  Future<BotEmoji?> emojiByName(
    String name, {
    required CommandExecutionBudget budget,
  });
  Future<List<BotEmoji>> emojis({
    String? guildId,
    required CommandExecutionBudget budget,
  });
  Future<BotEmoji> createEmoji(
    BotEmojiCreateRequest request, {
    required CommandExecutionBudget budget,
  });
  Future<void> deleteEmoji(String id, {required CommandExecutionBudget budget});
}

class BotEmojiImage {
  BotEmojiImage(Iterable<int> bytes, this.format)
    : bytes = Uint8List.fromList(bytes.toList()).asUnmodifiableView();
  final Uint8List bytes;
  final String format;
  ImageBuilder get builder => ImageBuilder(data: bytes, format: format);
}

abstract interface class BotEmojiImageLoader {
  Future<BotEmojiImage> load(
    String url, {
    required CommandExecutionBudget budget,
  });
}

/// Streams one GET, bounded by Discord's maximum image size and the invocation.
class HttpBotEmojiImageLoader implements BotEmojiImageLoader {
  const HttpBotEmojiImageLoader({this.client, this.clientFactory});
  final http.Client? client;
  final http.Client Function()? clientFactory;
  static const maxBytes = 256 * 1024;
  @override
  Future<BotEmojiImage> load(
    String url, {
    required CommandExecutionBudget budget,
  }) async {
    final uri = _url(url);
    budget.check();
    final transport = client ?? clientFactory?.call() ?? http.Client();
    try {
      return await budget.run(() async {
        final response = await transport.send(http.Request('GET', uri));
        budget.check();
        if (response.statusCode < 200 || response.statusCode >= 300) {
          await response.stream.listen((_) {}).cancel();
          throw StateError('Emoji image HTTP status ${response.statusCode}.');
        }
        if ((response.contentLength ?? 0) > maxBytes) {
          await response.stream.listen((_) {}).cancel();
          throw ArgumentError('Emoji image exceeds 256 KiB.');
        }
        final bytes = BytesBuilder(copy: false);
        await for (final chunk in response.stream) {
          budget.check();
          if (bytes.length + chunk.length > maxBytes) {
            throw ArgumentError('Emoji image exceeds 256 KiB.');
          }
          bytes.add(chunk);
        }
        budget.check();
        final data = bytes.takeBytes();
        return BotEmojiImage(data, _imageFormat(data));
      });
    } finally {
      if (client == null) transport.close();
    }
  }
}

class PreparedBotEmojiCreate {
  const PreparedBotEmojiCreate(this.manager, this.name);
  final GuildEmojiManager manager;
  final String name;
}

class PreparedBotEmojiDelete {
  const PreparedBotEmojiDelete(this.manager, this.emojiId);
  final GuildEmojiManager manager;
  final Snowflake emojiId;
}

/// Validation and fresh authorization only: no download or Discord write.
Future<PreparedBotEmojiCreate> prepareBotEmojiCreate(
  NyxxGateway client,
  Snowflake? guildId,
  BotEmojiCreateRequest request, {
  required CommandExecutionBudget budget,
  BotPermissionQueryService? permissions,
}) => budget.run(() async {
  request.validate();
  if (guildId == null) throw StateError('Emoji creation requires a guild.');
  final service =
      permissions ??
      DiscordBotPermissionQueryService(client: client, guildId: guildId);
  final value = await service.memberPermissions(budget: budget);
  budget.check();
  if (!value.hasAll([Permissions.createGuildExpressions.value])) {
    throw StateError('Missing Create Guild Expressions permission.');
  }
  return PreparedBotEmojiCreate(
    client.guilds[guildId].emojis,
    request.name.trim(),
  );
});

Future<PreparedBotEmojiDelete> prepareBotEmojiDelete(
  NyxxGateway client,
  Snowflake? guildId,
  String id, {
  required CommandExecutionBudget budget,
  BotPermissionQueryService? permissions,
}) => budget.run(() async {
  final selected = _id(id);
  if (guildId == null) throw StateError('Emoji deletion requires a guild.');
  final service =
      permissions ??
      DiscordBotPermissionQueryService(client: client, guildId: guildId);
  final value = await service.memberPermissions(budget: budget);
  budget.check();
  final manager = client.guilds[guildId].emojis;
  final emoji = await manager.fetch(selected);
  budget.check();
  final manages = value.hasAll([Permissions.manageGuildExpressions.value]);
  final own =
      value.hasAll([Permissions.createGuildExpressions.value]) &&
      emoji.user?.id == client.user.id;
  if (!manages && !own) {
    throw StateError('Missing permission to delete this guild emoji.');
  }
  return PreparedBotEmojiDelete(manager, selected);
});

class DiscordBotEmojiService implements BotEmojiService {
  const DiscordBotEmojiService({
    required this.client,
    this.guildId,
    this.images = const HttpBotEmojiImageLoader(),
  });
  final NyxxGateway client;
  final Snowflake? guildId;
  final BotEmojiImageLoader images;

  @override
  Future<List<BotEmoji>> emojis({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final selected = guildId == null ? this.guildId : _id(guildId);
    if (selected == null) throw StateError('Emoji listing requires a guild.');
    final values = await client.guilds[selected].emojis.list();
    budget.check();
    final result = <BotEmoji>[];
    for (final emoji in values) {
      budget.check();
      result.add(_snapshot(emoji, selected));
    }
    return List.unmodifiable(result);
  });

  Future<BotEmoji?> _find(
    bool Function(BotEmoji) matches,
    CommandExecutionBudget budget,
  ) => budget.run(() async {
    final seen = <String>{};
    if (guildId != null) {
      seen.add('$guildId');
      for (final emoji in await emojis(budget: budget)) {
        budget.check();
        if (matches(emoji)) return emoji;
      }
    }
    final guilds = await DiscordBotGuildQueryService(
      client: client,
    ).guilds(budget: budget);
    for (final guild in guilds) {
      budget.check();
      if (!seen.add(guild.id)) continue;
      for (final emoji in await emojis(guildId: guild.id, budget: budget)) {
        budget.check();
        if (matches(emoji)) return emoji;
      }
    }
    return null;
  });

  @override
  Future<BotEmoji?> emoji(String id, {required CommandExecutionBudget budget}) {
    final selected = '${_id(id)}';
    return _find((emoji) => emoji.id == selected, budget);
  }

  @override
  Future<BotEmoji?> emojiByName(
    String name, {
    required CommandExecutionBudget budget,
  }) => _find((emoji) => emoji.name == name, budget);
  @override
  Future<BotEmoji> createEmoji(
    BotEmojiCreateRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final prepared = await prepareBotEmojiCreate(
      client,
      guildId,
      request,
      budget: budget,
    );
    final image = await images.load(request.imageUrl, budget: budget);
    budget.check();
    if (image.bytes.isEmpty ||
        image.bytes.length > HttpBotEmojiImageLoader.maxBytes) {
      throw ArgumentError('Emoji image must contain at most 256 KiB.');
    }
    final result = await prepared.manager.create(
      EmojiBuilder(name: prepared.name, image: image.builder, roles: const []),
    );
    budget.check();
    return _snapshot(result, prepared.manager.guildId);
  });
  @override
  Future<void> deleteEmoji(
    String id, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final prepared = await prepareBotEmojiDelete(
      client,
      guildId,
      id,
      budget: budget,
    );
    budget.check();
    await prepared.manager.delete(prepared.emojiId);
    budget.check();
  });
}

BotEmoji _snapshot(GuildEmoji emoji, Snowflake guild) => BotEmoji(
  id: '${emoji.id}',
  name: emoji.name ?? '',
  guildId: '$guild',
  animated: emoji.isAnimated == true,
  creatorId: emoji.user?.id.toString(),
);

Snowflake _id(String raw) {
  final value = raw.trim();
  final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
      ? int.tryParse(value)
      : null;
  if (parsed == null || parsed <= 0) throw ArgumentError('Invalid Discord ID.');
  return Snowflake(parsed);
}

Uri _url(String raw) {
  final value = Uri.tryParse(raw.trim());
  if (value == null ||
      !['http', 'https'].contains(value.scheme) ||
      value.host.isEmpty) {
    throw ArgumentError('Emoji image requires an HTTP(S) URL.');
  }
  return value;
}

String _imageFormat(Uint8List bytes) {
  bool prefix(List<int> expected, [int offset = 0]) =>
      bytes.length >= expected.length + offset &&
      List.generate(
        expected.length,
        (i) => bytes[i + offset] == expected[i],
      ).every((same) => same);
  if (prefix([137, 80, 78, 71, 13, 10, 26, 10])) return 'png';
  if (prefix([255, 216, 255])) return 'jpeg';
  if (prefix('GIF87a'.codeUnits) || prefix('GIF89a'.codeUnits)) return 'gif';
  if (prefix('RIFF'.codeUnits) && prefix('WEBP'.codeUnits, 8)) return 'webp';
  if (prefix('ftyp'.codeUnits, 4)) {
    final size = bytes.length >= 4
        ? ByteData.sublistView(bytes).getUint32(0)
        : 0;
    final end = size < bytes.length ? size : bytes.length;
    for (var offset = 8; offset + 4 <= end; offset += 4) {
      if (offset == 12) continue; // Minor version is not a compatible brand.
      if (prefix('avif'.codeUnits, offset) ||
          prefix('avis'.codeUnits, offset)) {
        return 'avif';
      }
    }
  }
  throw ArgumentError('Unsupported emoji image format.');
}
