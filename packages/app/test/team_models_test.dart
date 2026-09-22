import 'package:bot_creator/features/team/logic/team_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BotPermissions', () {
    test('fromJson without any key grants least privilege', () {
      final permissions = BotPermissions.fromJson(<String, dynamic>{});

      expect(permissions.canEditCommands, false);
      expect(permissions.canStartStop, false);
      expect(permissions.canClaimAds, false);
      expect(permissions.canInvite, false);
      // The chat predates this feature: a server that does not send the block
      // must not lock the user out of the team chat.
      expect(permissions.canViewChat, true);
    });

    test('fromJson parses a full permissions object', () {
      final permissions = BotPermissions.fromJson(<String, dynamic>{
        'can_edit_commands': true,
        'can_start_stop': true,
        'can_claim_ads': true,
        'can_invite': true,
        'can_view_chat': true,
      });

      expect(permissions.canEditCommands, true);
      expect(permissions.canStartStop, true);
      expect(permissions.canClaimAds, true);
      expect(permissions.canInvite, true);
      expect(permissions.canViewChat, true);
    });

    test('fromJson ignores unexpected values instead of throwing', () {
      final permissions = BotPermissions.fromJson(<String, dynamic>{
        'can_edit_commands': 'yes',
        'can_start_stop': 1,
        'can_view_chat': null,
      });

      expect(permissions.canEditCommands, false);
      expect(permissions.canStartStop, false);
      expect(permissions.canViewChat, true);
    });

    test('toJson then fromJson round-trips', () {
      const original = BotPermissions(
        canEditCommands: true,
        canStartStop: false,
        canClaimAds: true,
        canInvite: false,
        canViewChat: false,
      );

      final restored = BotPermissions.fromJson(original.toJson());

      expect(restored.canEditCommands, original.canEditCommands);
      expect(restored.canStartStop, original.canStartStop);
      expect(restored.canClaimAds, original.canClaimAds);
      expect(restored.canInvite, original.canInvite);
      expect(restored.canViewChat, original.canViewChat);
    });

    test('copyWith only changes the requested field', () {
      const original = BotPermissions(
        canEditCommands: true,
        canViewChat: false,
      );

      final updated = original.copyWith(canInvite: true);

      expect(updated.canInvite, true);
      expect(updated.canEditCommands, original.canEditCommands);
      expect(updated.canStartStop, original.canStartStop);
      expect(updated.canClaimAds, original.canClaimAds);
      expect(updated.canViewChat, original.canViewChat);
    });
  });

  group('TeamChatMessage', () {
    test('fromJson parses a full message object', () {
      final message = TeamChatMessage.fromJson(<String, dynamic>{
        'id': 42,
        'author_user_id': 'user-1',
        'author_display_name': 'Ada',
        'content': 'Hello team',
        'created_at': '2026-07-02T12:00:00.000Z',
      });

      expect(message.id, 42);
      expect(message.authorUserId, 'user-1');
      expect(message.authorDisplayName, 'Ada');
      expect(message.content, 'Hello team');
      expect(message.createdAt.toUtc(), DateTime.utc(2026, 7, 2, 12).toUtc());
    });

    test('fromJson without created_at does not throw', () {
      final message = TeamChatMessage.fromJson(<String, dynamic>{
        'id': 7,
        'content': 'No timestamp',
      });

      expect(message.id, 7);
      expect(message.content, 'No timestamp');
      expect(message.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromJson with an unreadable created_at does not throw', () {
      final message = TeamChatMessage.fromJson(<String, dynamic>{
        'id': 8,
        'created_at': 'not-a-date',
      });

      expect(message.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('fromJson tolerates missing fields and odd types', () {
      final message = TeamChatMessage.fromJson(<String, dynamic>{
        'id': '9',
        'content': 123,
      });

      expect(message.id, 9);
      expect(message.authorUserId, '');
      expect(message.authorDisplayName, '');
      expect(message.content, '123');
    });
  });

  group('BotCollaborator', () {
    test('fromJson parses a full collaborator object', () {
      final collaborator = BotCollaborator.fromJson(<String, dynamic>{
        'user_id': 'user-2',
        'role': 'owner',
        'permissions': <String, dynamic>{
          'can_edit_commands': true,
          'can_invite': true,
        },
        'display_name': 'Grace',
        'is_owner': true,
        'in_discord_team': true,
      });

      expect(collaborator.userId, 'user-2');
      expect(collaborator.role, 'owner');
      expect(collaborator.permissions.canEditCommands, true);
      expect(collaborator.permissions.canInvite, true);
      expect(collaborator.permissions.canStartStop, false);
      expect(collaborator.displayName, 'Grace');
      expect(collaborator.isOwner, true);
      expect(collaborator.inDiscordTeam, true);
    });

    test('fromJson without a permissions block gives the default', () {
      final collaborator = BotCollaborator.fromJson(<String, dynamic>{
        'user_id': 'user-3',
      });

      expect(collaborator.userId, 'user-3');
      expect(collaborator.role, 'collaborator');
      expect(collaborator.permissions.canEditCommands, false);
      expect(collaborator.permissions.canViewChat, true);
      expect(collaborator.displayName, '');
      expect(collaborator.isOwner, false);
      expect(collaborator.inDiscordTeam, false);
    });

    test('fromJson with a malformed permissions block does not throw', () {
      final collaborator = BotCollaborator.fromJson(<String, dynamic>{
        'user_id': 'user-4',
        'permissions': 'all',
      });

      expect(collaborator.permissions.canEditCommands, false);
      expect(collaborator.permissions.canViewChat, true);
    });

    test('toJson then fromJson round-trips', () {
      final original = BotCollaborator(
        userId: 'user-5',
        role: 'editor',
        permissions: const BotPermissions(canStartStop: true),
        displayName: 'Alan',
        isOwner: false,
        inDiscordTeam: true,
      );

      final restored = BotCollaborator.fromJson(original.toJson());

      expect(restored.userId, original.userId);
      expect(restored.role, original.role);
      expect(restored.permissions.canStartStop, true);
      expect(restored.permissions.canEditCommands, false);
      expect(restored.displayName, original.displayName);
      expect(restored.isOwner, original.isOwner);
      expect(restored.inDiscordTeam, original.inDiscordTeam);
    });

    test('fromJson without a user_id does not throw', () {
      final collaborator = BotCollaborator.fromJson(<String, dynamic>{});

      expect(collaborator.userId, '');
      expect(collaborator.role, 'collaborator');
    });
  });
}
