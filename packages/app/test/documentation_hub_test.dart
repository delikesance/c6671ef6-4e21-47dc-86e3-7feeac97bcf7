import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('documentation URLs', () {
    test('urlForDocumentationSection returns expected base URLs', () {
      expect(
        urlForDocumentationSection(DocumentationSection.guide),
        guideBaseUrl,
      );
      expect(
        urlForDocumentationSection(DocumentationSection.botCreatorDocs),
        botCreatorDocsBaseUrl,
      );
      expect(
        urlForDocumentationSection(DocumentationSection.discordJs),
        discordJsBaseUrl,
      );
    });

    test('isDocumentationHostAllowed accepts known documentation hosts', () {
      expect(
        isDocumentationHostAllowed(Uri.parse('https://bot-creator.fr/docs')),
        isTrue,
      );
      expect(
        isDocumentationHostAllowed(Uri.parse('https://discord.js.org/')),
        isTrue,
      );
      expect(
        isDocumentationHostAllowed(Uri.parse('https://discordjs.dev/guide')),
        isTrue,
      );
      expect(
        isDocumentationHostAllowed(Uri.parse('http://bot-creator.fr/docs')),
        isFalse,
      );
      expect(
        isDocumentationHostAllowed(Uri.parse('https://example.com/')),
        isFalse,
      );
    });
  });

  group('visibleDocumentationSections', () {
    test('returns two tabs when discord.js is hidden', () {
      expect(
        visibleDocumentationSections(showDiscordJsTab: false),
        [
          DocumentationSection.guide,
          DocumentationSection.botCreatorDocs,
        ],
      );
    });

    test('returns three tabs when discord.js is enabled', () {
      expect(
        visibleDocumentationSections(showDiscordJsTab: true),
        [
          DocumentationSection.guide,
          DocumentationSection.botCreatorDocs,
          DocumentationSection.discordJs,
        ],
      );
    });

    test('selects initial docs tab index', () {
      expect(
        documentationSectionTabIndex(
          DocumentationSection.botCreatorDocs,
          showDiscordJsTab: true,
        ),
        1,
      );
      expect(
        documentationSectionTabIndex(
          DocumentationSection.discordJs,
          showDiscordJsTab: true,
        ),
        2,
      );
      expect(
        documentationSectionTabIndex(
          DocumentationSection.discordJs,
          showDiscordJsTab: false,
        ),
        0,
      );
    });
  });
}
