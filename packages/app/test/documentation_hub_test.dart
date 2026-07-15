import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/features/documentation/documentation_hub_page.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/features/documentation/web_documentation_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        isDocumentationHostAllowed(Uri.parse(botTokenTutorialUrl)),
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

    test('botTokenTutorialUrl points at the getting started article', () {
      expect(botTokenTutorialUrl, contains('getting%20started'));
      expect(
        botTokenTutorialUrl,
        contains('how-to-create-a-bot-token-bot-creator'),
      );
      expect(botTokenTutorialUrl, isNot(contains('tutorials/setup/security')));
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

  group('documentationWebViewGestureRecognizers', () {
    test('includes vertical drag and pan recognizers', () {
      final types =
          documentationWebViewGestureRecognizers
              .map((factory) => factory.constructor().runtimeType)
              .toSet();

      expect(types, contains(VerticalDragGestureRecognizer));
      expect(types, contains(PanGestureRecognizer));
    });
  });

  group('DocumentationHubPage', () {
    testWidgets('uses IndexedStack instead of TabBarView', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DocumentationHubPage(),
          ),
        );
        await tester.pump();

        expect(find.byType(IndexedStack), findsOneWidget);
        expect(find.byType(TabBarView), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
