import 'package:flutter/material.dart';

/// Preset turnkey hosted-app images with minimal required configuration.
enum HostedAppTemplateId { easyMusic }

class HostedAppEnvField {
  const HostedAppEnvField({
    required this.key,
    this.required = true,
    this.secret = false,
  });

  final String key;
  final bool required;
  final bool secret;
}

class HostedAppTemplate {
  const HostedAppTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
    this.cpuMillis = 250,
    this.memoryMb = 256,
    this.storageGb = 1,
    this.requiresPrivateRegistry = false,
    this.envFields = const [],
    this.requiredIntents = const ['Message Content Intent'],
    this.tips = const [],
  });

  final HostedAppTemplateId id;
  final String title;
  final String description;
  final String image;
  final IconData icon;
  final int cpuMillis;
  final int memoryMb;
  final int storageGb;
  final bool requiresPrivateRegistry;
  final List<HostedAppEnvField> envFields;
  final List<String> requiredIntents;
  final List<String> tips;
}

/// BeatDock: public Lavalink nodes, slash commands, only `TOKEN` required.
/// Official image: https://github.com/albertgmz/BeatDock
/// Pinned digest for `latest` as of 2026-07 (avoids silent `:latest` drift / pull failures).
const kEasyMusicBotImage =
    'ghcr.io/albertgmz/beatdock:latest@sha256:27dc983a9c9215a4db9be6bbe734fd23b8eb3960cd4c35c440658066e3e93ce4';

const easyMusicBotTemplate = HostedAppTemplate(
  id: HostedAppTemplateId.easyMusic,
  title: 'Bot Musique',
  description:
      'Bot de musique prêt à l\'emploi (BeatDock) avec nœuds Lavalink publics et commandes slash intégrées.',
  image: kEasyMusicBotImage,
  icon: Icons.music_note_rounded,
  cpuMillis: 250,
  memoryMb: 256,
  storageGb: 1,
  envFields: [
    HostedAppEnvField(key: 'TOKEN', secret: true),
  ],
  requiredIntents: [
    'Message Content Intent',
  ],
  tips: [
    'Activez le Message Content Intent dans le Discord Developer Portal.',
    'Assurez-vous que le bot a les permissions de rejoindre et parler dans les salons vocaux.',
  ],
);

const List<HostedAppTemplate> kTurnkeyBotTemplates = [
  easyMusicBotTemplate,
];

HostedAppTemplate templateFor(HostedAppTemplateId id) {
  switch (id) {
    case HostedAppTemplateId.easyMusic:
      return easyMusicBotTemplate;
  }
}

HostedAppTemplate? templateForImage(String image) {
  final clean = image.trim().toLowerCase();
  for (final t in kTurnkeyBotTemplates) {
    if (t.image.toLowerCase() == clean ||
        (clean.contains('beatdock') && t.id == HostedAppTemplateId.easyMusic)) {
      return t;
    }
  }
  return null;
}
