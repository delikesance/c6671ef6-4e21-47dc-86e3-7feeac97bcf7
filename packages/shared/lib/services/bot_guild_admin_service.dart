import 'dart:convert';
import 'package:bot_creator_shared/utils/global.dart';
import 'package:nyxx/nyxx.dart';
import 'permission_checks.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

/// Guild settings and onboarding of the `updateGuild`, `getGuildOnboarding` and `updateGuildOnboarding` blocks (and `leaveGuild`, which is `updateGuild` with `leave`).
abstract interface class BotGuildAdminService {
  Future<Map<String, String>> updateGuild({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    String Function(String)? resolve,
  });

  /// Fetches current guild onboarding configuration.
  ///
  /// Returns `{'onboardingJson': '{...}', 'enabled': 'true|false'}` or `{'error': '...'}`.
  Future<Map<String, String>> getGuildOnboarding({required Snowflake? guildId});

  /// Updates guild onboarding configuration.
  ///
  /// Currently limited by nyxx support in this runtime.
  /// Returns `{'status': 'updated'}` on success or `{'error': '...'}`.
  Future<Map<String, String>> updateGuildOnboarding({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
}

/// Discord adapter of [BotGuildAdminService]: the logic of the historical block
/// functions, which now delegate here.
class DiscordBotGuildAdminService implements BotGuildAdminService {
  const DiscordBotGuildAdminService(this.client);

  final NyxxGateway client;

  @override
  Future<Map<String, String>> updateGuild({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    String Function(String)? resolve,
  }) async {
    resolve ??= (s) => s;
    try {
      if (guildId == null) {
        return {'error': 'Missing guildId', 'guildId': ''};
      }

      if (payload['leave'] == true) {
        final guild = await client.guilds.fetch(guildId);
        await guild.leave();
        return {'guildId': guildId.toString(), 'status': 'left'};
      }

      final permError = await checkBotGuildPermission(
        client,
        guildId: guildId,
        requiredPermissions: [Permissions.manageGuild],
        actionLabel: 'update server settings',
      );
      if (permError != null) {
        return {'error': permError, 'guildId': ''};
      }

      final builder = GuildUpdateBuilder();

      if (payload.containsKey('name')) {
        final name = resolve((payload['name'] ?? '').toString()).trim();
        builder.name = name.isNotEmpty ? name : null;
      }

      if (payload.containsKey('description')) {
        final description = resolve((payload['description'] ?? '').toString());
        builder.description = description.isNotEmpty ? description : null;
      }

      if (payload.containsKey('preferredLocale')) {
        final localeRaw = resolve(
          (payload['preferredLocale'] ?? '').toString(),
        ).trim();
        if (localeRaw.isNotEmpty) {
          builder.preferredLocale = Locale.parse(localeRaw);
        }
      }

      if (payload.containsKey('premiumProgressBarEnabled')) {
        final raw = resolve(
          (payload['premiumProgressBarEnabled'] ?? '').toString(),
        ).toLowerCase();
        builder.premiumProgressBarEnabled = raw == 'true';
      }

      if (payload.containsKey('afkTimeoutSeconds')) {
        final seconds = int.tryParse(
          resolve((payload['afkTimeoutSeconds'] ?? '').toString()),
        );
        if (seconds != null && seconds >= 0) {
          builder.afkTimeout = Duration(seconds: seconds);
        }
      }

      if (payload.containsKey('afkChannelId')) {
        builder.afkChannelId = _toSnowflake(
          resolve((payload['afkChannelId'] ?? '').toString()),
        );
      }
      if (payload.containsKey('systemChannelId')) {
        builder.systemChannelId = _toSnowflake(
          resolve((payload['systemChannelId'] ?? '').toString()),
        );
      }
      if (payload.containsKey('rulesChannelId')) {
        builder.rulesChannelId = _toSnowflake(
          resolve((payload['rulesChannelId'] ?? '').toString()),
        );
      }
      if (payload.containsKey('publicUpdatesChannelId')) {
        builder.publicUpdatesChannelId = _toSnowflake(
          resolve((payload['publicUpdatesChannelId'] ?? '').toString()),
        );
      }
      if (payload.containsKey('safetyAlertsChannelId')) {
        builder.safetyAlertsChannelId = _toSnowflake(
          resolve((payload['safetyAlertsChannelId'] ?? '').toString()),
        );
      }

      if (payload.containsKey('verificationLevel')) {
        final raw = int.tryParse(
          resolve((payload['verificationLevel'] ?? '').toString()),
        );
        if (raw != null) {
          builder.verificationLevel = VerificationLevel(raw);
        }
      }
      if (payload.containsKey('defaultMessageNotificationLevel')) {
        final raw = int.tryParse(
          resolve(
            (payload['defaultMessageNotificationLevel'] ?? '').toString(),
          ),
        );
        if (raw != null) {
          builder.defaultMessageNotificationLevel = MessageNotificationLevel(
            raw,
          );
        }
      }
      if (payload.containsKey('explicitContentFilterLevel')) {
        final raw = int.tryParse(
          resolve((payload['explicitContentFilterLevel'] ?? '').toString()),
        );
        if (raw != null) {
          builder.explicitContentFilterLevel = ExplicitContentFilterLevel(raw);
        }
      }

      final reason = resolve((payload['reason'] ?? '').toString()).trim();
      final updated = await client.guilds.update(
        guildId,
        builder,
        auditLogReason: reason.isNotEmpty ? reason : null,
      );

      return {
        'guildId': updated.id.toString(),
        'name': updated.name,
        'description': updated.description ?? '',
      };
    } catch (error) {
      return {'error': 'Failed to update guild: $error', 'guildId': ''};
    }
  }

  @override
  Future<Map<String, String>> getGuildOnboarding({
    required Snowflake? guildId,
  }) async {
    try {
      if (guildId == null) {
        return {'error': 'getGuildOnboarding requires a guild context'};
      }

      final permError = await checkBotGuildPermission(
        client,
        guildId: guildId,
        requiredPermissions: [Permissions.manageGuild],
        actionLabel: 'view guild onboarding',
      );
      if (permError != null) {
        return {'error': permError};
      }

      final guild = await fetchGuildCached(client, guildId);
      if (guild == null) return {'error': 'Guild not found'};
      final onboarding = await guild.fetchOnboarding();

      final json = jsonEncode({
        'guildId': onboarding.guildId.toString(),
        'enabled': onboarding.isEnabled,
        'defaultChannelIds': onboarding.defaultChannelIds
            .map((id) => id.toString())
            .toList(),
        'mode': onboarding.mode.value,
        'prompts': onboarding.prompts
            .map(
              (p) => {
                'id': p.id.toString(),
                'title': p.title,
                'type': p.type.value,
                'required': p.isRequired,
                'singleSelect': p.isSingleSelect,
                'inOnboarding': p.isInOnboarding,
                'options': p.options
                    .map(
                      (o) => {
                        'id': o.id.toString(),
                        'title': o.title,
                        'description': o.description ?? '',
                        'channelIds': o.channelIds
                            .map((id) => id.toString())
                            .toList(),
                        'roleIds': o.roleIds
                            .map((id) => id.toString())
                            .toList(),
                      },
                    )
                    .toList(),
              },
            )
            .toList(),
      });

      return {
        'onboardingJson': json,
        'enabled': onboarding.isEnabled.toString(),
      };
    } catch (e) {
      return {'error': 'Failed to get guild onboarding: $e'};
    }
  }

  @override
  Future<Map<String, String>> updateGuildOnboarding({
    required Snowflake? guildId,
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    if (guildId == null) {
      return {'error': 'updateGuildOnboarding requires a guild context'};
    }

    final permError = await checkBotGuildPermission(
      client,
      guildId: guildId,
      requiredPermissions: [Permissions.manageGuild],
      actionLabel: 'update guild onboarding',
    );
    if (permError != null) {
      return {'error': permError};
    }

    final _ = resolve((payload['enabled'] ?? '').toString());

    return {
      'error':
          'updateGuildOnboarding is not supported by the current nyxx runtime yet',
    };
  }
}
