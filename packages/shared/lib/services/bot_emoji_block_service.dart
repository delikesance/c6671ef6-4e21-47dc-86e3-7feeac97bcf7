import 'dart:convert';
import 'package:nyxx/nyxx.dart';
import '../actions/permission_checks.dart';
import '../utils/global.dart';
import 'package:http/http.dart' as http;

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  return Snowflake(parsed);
}

List<Snowflake> _toSnowflakeList(dynamic value) {
  if (value == null) return [];
  List<String> raw;
  if (value is List) {
    raw = value.map((e) => e.toString().trim()).toList();
  } else {
    final s = value.toString().trim();
    if (s.isEmpty) return [];
    try {
      final decoded = jsonDecode(s);
      if (decoded is List) {
        raw = decoded.map((e) => e.toString().trim()).toList();
      } else {
        raw = s.split(',').map((e) => e.trim()).toList();
      }
    } catch (_) {
      raw = s.split(',').map((e) => e.trim()).toList();
    }
  }
  return raw.map(_toSnowflake).whereType<Snowflake>().toList();
}

/// Downloads image bytes from [url] and encodes as a data URI (base64).
Future<ImageBuilder?> _imageFromUrl(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    final bytes = response.bodyBytes;
    final contentType = response.headers['content-type'] ?? 'image/png';
    return ImageBuilder(data: bytes, format: _extensionForMime(contentType));
  } catch (_) {
    return null;
  }
}

String _extensionForMime(String mime) {
  if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpeg';
  if (mime.contains('gif')) return 'gif';
  if (mime.contains('webp')) return 'webp';
  return 'png';
}

ImageBuilder? _imageFromBase64(String base64Data) {
  try {
    // Accept both raw base64 and data URIs
    String raw = base64Data.trim();
    String mime = 'image/png';
    if (raw.startsWith('data:')) {
      final semiColon = raw.indexOf(';');
      final comma = raw.indexOf(',');
      if (semiColon > 0 && comma > semiColon) {
        mime = raw.substring(5, semiColon);
        raw = raw.substring(comma + 1);
      }
    }
    final bytes = base64Decode(raw);
    return ImageBuilder(data: bytes, format: _extensionForMime(mime));
  } catch (_) {
    return null;
  }
}

/// Creates a new emoji in a guild.
///

/// Guild emoji operations of the visual blocks `createEmoji`, `updateEmoji` and
/// `deleteEmoji` (permission pre-check included). Each returns the block's own
/// result map (`{'error': ...}` on failure). Distinct from [BotEmojiService],
/// which serves the narrower BDFD emoji functions.
abstract interface class BotEmojiBlockService {
  Future<Map<String, String>> create({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> update({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> delete({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
}

class DiscordBotEmojiBlockService implements BotEmojiBlockService {
  const DiscordBotEmojiBlockService(this.client);
  final NyxxGateway client;

  @override
  Future<Map<String, String>> create({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    try {
      if (guildId == null) {
        return {'error': 'createEmoji requires a guild context'};
      }

      final permError = await checkBotGuildPermission(
        client,
        guildId: guildId,
        requiredPermissions: [Permissions.manageGuildExpressions],
        actionLabel: 'manage emojis',
      );
      if (permError != null) {
        return {'error': permError};
      }

      final name = resolve((payload['name'] ?? '').toString()).trim();
      if (name.isEmpty) {
        return {'error': 'name is required for createEmoji'};
      }

      final base64Raw = resolve(
        (payload['imageBase64'] ?? '').toString(),
      ).trim();
      final urlRaw = resolve((payload['imageUrl'] ?? '').toString()).trim();

      ImageBuilder? image;
      if (base64Raw.isNotEmpty) {
        image = _imageFromBase64(base64Raw);
      } else if (urlRaw.isNotEmpty) {
        image = await _imageFromUrl(urlRaw);
      }

      if (image == null) {
        return {
          'error':
              'Either imageBase64 or imageUrl must be provided for createEmoji',
        };
      }

      final roles = _toSnowflakeList(payload['roles']);
      final reason = resolve((payload['reason'] ?? '').toString()).trim();

      final guild = await fetchGuildCached(client, guildId);
      if (guild == null) return {'error': 'Guild not found'};
      final emoji = await guild.emojis.create(
        EmojiBuilder(name: name, image: image, roles: roles),
        auditLogReason: reason.isNotEmpty ? reason : null,
      );

      return {
        'emojiId': emoji.id.toString(),
        'name': emoji.name ?? name,
        'animated': ((emoji as dynamic).isAnimated == true).toString(),
        'status': 'created',
        'tag': ((emoji as dynamic).isAnimated == true)
            ? '<a:${emoji.name ?? name}:${emoji.id}>'
            : '<:${emoji.name ?? name}:${emoji.id}>',
      };
    } catch (e) {
      return {'error': 'Failed to create emoji: $e'};
    }
  }

  ///
  @override
  Future<Map<String, String>> update({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    try {
      if (guildId == null) {
        return {'error': 'updateEmoji requires a guild context'};
      }

      final permError = await checkBotGuildPermission(
        client,
        guildId: guildId,
        requiredPermissions: [Permissions.manageGuildExpressions],
        actionLabel: 'manage emojis',
      );
      if (permError != null) {
        return {'error': permError};
      }

      final emojiId = _toSnowflake(
        resolve((payload['emojiId'] ?? '').toString()),
      );
      if (emojiId == null) {
        return {'error': 'emojiId is required for updateEmoji'};
      }

      final name = resolve((payload['name'] ?? '').toString()).trim();
      final roles = _toSnowflakeList(payload['roles']);
      final reason = resolve((payload['reason'] ?? '').toString()).trim();

      final guild = await fetchGuildCached(client, guildId);
      if (guild == null) return {'error': 'Guild not found'};
      final builder = EmojiUpdateBuilder(
        name: name.isNotEmpty ? name : null,
        roles: roles.isEmpty ? null : roles,
      );
      final emoji = await guild.emojis.update(
        emojiId,
        builder,
        auditLogReason: reason.isNotEmpty ? reason : null,
      );

      return {
        'emojiId': emoji.id.toString(),
        'name': emoji.name ?? '',
        'status': 'updated',
      };
    } catch (e) {
      return {'error': 'Failed to update emoji: $e'};
    }
  }

  ///
  @override
  Future<Map<String, String>> delete({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    try {
      if (guildId == null) {
        return {'error': 'deleteEmoji requires a guild context'};
      }

      final permError = await checkBotGuildPermission(
        client,
        guildId: guildId,
        requiredPermissions: [Permissions.manageGuildExpressions],
        actionLabel: 'manage emojis',
      );
      if (permError != null) {
        return {'error': permError};
      }

      final identifier = resolve((payload['emojiId'] ?? '').toString()).trim();
      if (identifier.isEmpty) {
        return {'error': 'emojiId is required for deleteEmoji'};
      }

      final reason = resolve((payload['reason'] ?? '').toString()).trim();

      final guild = await fetchGuildCached(client, guildId);
      if (guild == null) return {'error': 'Guild not found'};
      final emojiId =
          _toSnowflake(identifier) ??
          guild.emojiList
              .where((emoji) => emoji.name == identifier)
              .map((emoji) => emoji.id)
              .firstOrNull;
      if (emojiId == null) return {'error': 'Emoji not found: $identifier'};
      await guild.emojis.delete(
        emojiId,
        auditLogReason: reason.isNotEmpty ? reason : null,
      );

      return {'emojiId': emojiId.toString(), 'status': 'deleted'};
    } catch (e) {
      return {'error': 'Failed to delete emoji: $e'};
    }
  }
}
