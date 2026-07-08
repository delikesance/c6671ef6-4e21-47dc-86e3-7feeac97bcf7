/// Preset hosted-app images with minimal required configuration.
enum HostedAppTemplateId { easyMusic, custom }

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
    required this.image,
    this.requiresPrivateRegistry = false,
    this.envFields = const [],
  });

  final HostedAppTemplateId id;
  final String image;
  final bool requiresPrivateRegistry;
  final List<HostedAppEnvField> envFields;
}

/// BeatDock: public Lavalink nodes, slash commands, only `TOKEN` required.
/// https://github.com/lazaroagomez/BeatDock
const kEasyMusicBotImage = 'ghcr.io/lazaroagomez/beatdock:latest';

const easyMusicBotTemplate = HostedAppTemplate(
  id: HostedAppTemplateId.easyMusic,
  image: kEasyMusicBotImage,
  envFields: [
    HostedAppEnvField(key: 'TOKEN', secret: true),
  ],
);

const customHostedAppTemplate = HostedAppTemplate(
  id: HostedAppTemplateId.custom,
  image: '',
);

HostedAppTemplate templateFor(HostedAppTemplateId id) {
  switch (id) {
    case HostedAppTemplateId.easyMusic:
      return easyMusicBotTemplate;
    case HostedAppTemplateId.custom:
      return customHostedAppTemplate;
  }
}
