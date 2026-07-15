/// Which documentation tab to show in the hub.
enum DocumentationSection {
  guide,
  botCreatorDocs,
  discordJs,
}

const guideBaseUrl = 'https://bot-creator.fr/blog';
const botCreatorDocsBaseUrl = 'https://bot-creator.fr/docs';
const discordJsBaseUrl = 'https://discord.js.org';

/// Step-by-step guide for creating a Discord bot token.
const botTokenTutorialUrl =
    'https://bot-creator.fr/getting%20started/2025/05/18/how-to-create-a-bot-token-bot-creator';

/// Host suffixes allowed for in-app WebView navigation.
const documentationAllowedHostSuffixes = <String>[
  'bot-creator.fr',
  'discord.js.org',
  'discordjs.dev',
];

String urlForDocumentationSection(DocumentationSection section) {
  return switch (section) {
    DocumentationSection.guide => guideBaseUrl,
    DocumentationSection.botCreatorDocs => botCreatorDocsBaseUrl,
    DocumentationSection.discordJs => discordJsBaseUrl,
  };
}

bool isDocumentationHostAllowed(Uri uri) {
  if (uri.scheme != 'https') {
    return false;
  }
  final host = uri.host.toLowerCase();
  for (final suffix in documentationAllowedHostSuffixes) {
    if (host == suffix || host.endsWith('.$suffix')) {
      return true;
    }
  }
  return false;
}

/// Visible tabs in the documentation hub.
List<DocumentationSection> visibleDocumentationSections({
  required bool showDiscordJsTab,
}) {
  final sections = <DocumentationSection>[
    DocumentationSection.guide,
    DocumentationSection.botCreatorDocs,
  ];
  if (showDiscordJsTab) {
    sections.add(DocumentationSection.discordJs);
  }
  return sections;
}

int documentationSectionTabIndex(
  DocumentationSection section, {
  required bool showDiscordJsTab,
}) {
  final sections = visibleDocumentationSections(showDiscordJsTab: showDiscordJsTab);
  final index = sections.indexOf(section);
  return index >= 0 ? index : 0;
}
