import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HostedAppTemplate / Turnkey bots', () {
    test('easyMusicBotTemplate has correct defaults', () {
      expect(easyMusicBotTemplate.id, HostedAppTemplateId.easyMusic);
      expect(easyMusicBotTemplate.title, 'Bot Musique');
      expect(easyMusicBotTemplate.image, contains('beatdock'));
      expect(easyMusicBotTemplate.cpuMillis, 250);
      expect(easyMusicBotTemplate.memoryMb, 256);
      expect(easyMusicBotTemplate.storageGb, 1);
      expect(easyMusicBotTemplate.envFields.length, 1);
      expect(easyMusicBotTemplate.envFields.first.key, 'TOKEN');
    });

    test('templateFor returns easyMusicBotTemplate', () {
      final template = templateFor(HostedAppTemplateId.easyMusic);
      expect(template.id, HostedAppTemplateId.easyMusic);
    });

    test('templateForImage resolves beatdock image correctly', () {
      final template = templateForImage(
        'ghcr.io/albertgmz/beatdock:latest@sha256:27dc983a9c9215a4db9be6bbe734fd23b8eb3960cd4c35c440658066e3e93ce4',
      );
      expect(template, isNotNull);
      expect(template?.id, HostedAppTemplateId.easyMusic);
      expect(template?.title, 'Bot Musique');
    });

    test('templateForImage returns null for unknown image', () {
      final template = templateForImage('custom-docker/unknown:latest');
      expect(template, isNull);
    });
  });
}
