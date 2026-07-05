import 'package:bot_creator/features/bot_editor/logic/discord_application_command_rules.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';

void main() {
  group('validateChatInputNameFormat', () {
    test('accepts valid slash names', () {
      for (final name in ['blep', 'only_smol', 'test-name', '_private']) {
        expect(
          validateChatInputNameFormat(name),
          isNull,
          reason: name,
        );
      }
    });

    test('rejects uppercase and spaces', () {
      expect(
        validateChatInputNameFormat('Blep'),
        DiscordCommandValidationIssue.nameMustBeLowercase,
      );
      expect(
        validateChatInputNameFormat('my command'),
        DiscordCommandValidationIssue.nameInvalidFormat,
      );
    });

    test('rejects names longer than 32 characters', () {
      expect(
        validateChatInputNameFormat('a' * 33),
        DiscordCommandValidationIssue.nameTooLong,
      );
    });
  });

  group('validateUserOrMessageNameFormat', () {
    test('accepts mixed case and spaces', () {
      expect(validateUserOrMessageNameFormat('High Five'), isNull);
      expect(validateUserOrMessageNameFormat('View Stats'), isNull);
    });
  });

  group('validatePrefixCommandNameFormat', () {
    test('accepts flexible names', () {
      expect(validatePrefixCommandNameFormat('My Command'), isNull);
      expect(validatePrefixCommandNameFormat('PING'), isNull);
    });

    test('accepts empty description bypass via validateDescriptionValue', () {
      expect(
        validateDescriptionValue('', required: false),
        isNull,
      );
    });
  });

  group('validateRequiredOptionsBeforeOptional', () {
    test('flags required option after optional', () {
      final options = [
        CommandOptionBuilder(
          type: CommandOptionType.string,
          name: 'optional',
          description: 'Optional field',
          isRequired: false,
        ),
        CommandOptionBuilder(
          type: CommandOptionType.string,
          name: 'required',
          description: 'Required field',
          isRequired: true,
        ),
      ];

      expect(
        validateRequiredOptionsBeforeOptional(options),
        DiscordCommandValidationIssue.optionRequiredBeforeOptional,
      );
    });
  });

  group('computeSlashCommandPayloadSize', () {
    test('stays under limit for simple command', () {
      final size = computeSlashCommandPayloadSize(
        name: 'ping',
        description: 'Ping command',
        options: const [],
      );
      expect(size, lessThan(discordSlashCommandPayloadLimit));
      expect(validateSlashCommandPayloadSize(size), isNull);
    });

    test('flags payload above 8000 characters', () {
      final hugeDescription = 'x' * 8000;
      final size = computeSlashCommandPayloadSize(
        name: 'big',
        description: hugeDescription,
        options: const [],
      );
      expect(
        validateSlashCommandPayloadSize(size),
        DiscordCommandValidationIssue.payloadTooLarge,
      );
    });
  });
}
