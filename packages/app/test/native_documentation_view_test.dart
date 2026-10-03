import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/features/documentation/documentation_article_page.dart';
import 'package:bot_creator/features/documentation/documentation_hub_page.dart';
import 'package:bot_creator/features/documentation/documentation_repository.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/features/documentation/native_documentation_view.dart';
import 'package:bot_creator/features/documentation/web_documentation_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'documentation_repository_test.dart' show documentationFixture;

Widget app(Widget home) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: RepaintBoundary(child: home),
);

Future<void> screenshot(WidgetTester tester, String name) async {
  final directory = Platform.environment['DOCS_SCREENSHOT_DIR'];
  if (directory == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byType(RepaintBoundary).first,
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png').writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('cached index remains readable when network is unavailable', (
    tester,
  ) async {
    final warm = DocumentationRepository(
      now: () => DateTime(2026),
      client: MockClient(
        (_) async => http.Response(jsonEncode([documentationFixture()]), 200),
      ),
    );
    await warm.index(DocumentationSection.botCreatorDocs);
    final offline = DocumentationRepository(
      now: () => DateTime(2026, 1, 2),
      client: MockClient((_) async => http.Response('unavailable', 503)),
    );
    await tester.pumpWidget(
      app(
        DocumentationHubPage(
          repository: offline,
          initialSection: DocumentationSection.botCreatorDocs,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DocumentationOfflineBanner), findsOneWidget);
    expect(find.text('\$getVar'), findsOneWidget);
  });

  for (final size in [const Size(320, 780), const Size(1200, 850)]) {
    testWidgets('native hub search, lazy tabs and layout at $size', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final calls = <String>[];
      final repository = DocumentationRepository(
        client: MockClient((request) async {
          calls.add(request.url.path);
          if (request.url.path.contains('guides-index')) {
            return http.Response(
              jsonEncode([documentationFixture(guide: true)]),
              200,
            );
          }
          return http.Response(
            jsonEncode([
              documentationFixture(),
              {
                ...documentationFixture(id: 'blocks'),
                'name': 'Blocks',
                'category': 'Workflows',
                'api_type': 'blocks',
              },
            ]),
            200,
          );
        }),
      );
      await tester.pumpWidget(
        app(
          DocumentationHubPage(repository: repository, showDiscordJsTab: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create a bot token'), findsOneWidget);
      expect(find.byType(WebDocumentationView), findsNothing);
      expect(calls.length, 1);
      await tester.enterText(find.byType(TextField), 'nonexistent');
      await tester.pumpAndSettle();
      expect(find.text('Aucun article correspondant'), findsOneWidget);
      await tester.tap(find.text('Docs Bot Creator'));
      await tester.pumpAndSettle();
      expect(calls.length, 2);
      await tester.enterText(find.byType(TextField).hitTestable(), '\$getVar');
      await tester.pumpAndSettle();
      expect(find.text('\$getVar'), findsNWidgets(2));
      expect(find.text('Blocks'), findsNothing);
      expect(tester.takeException(), isNull);
      await screenshot(tester, 'docs-list-${size.width.toInt()}');
    });
  }

  testWidgets('article has copyable code, contents and native links', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final content =
        '# \$getVar\n\n[Token guide]($botTokenTutorialUrl.html)\n\n'
        '```bdfd\n\$setVar[xp;1]\n```\n\n## Details\n\n'
        '${List.filled(35, 'A paragraph.\n\n').join()}## Details\n\nLast section.';
    final fixture = documentationFixture(content: content);
    final repository = DocumentationRepository(
      client: MockClient((request) async {
        if (request.url.path.contains('index.json')) {
          return http.Response(
            jsonEncode([
              documentationFixture(
                guide: true,
                content: '# Token guide\n\nSteps',
              ),
            ]),
            200,
          );
        }
        return http.Response(
          request.url.path.contains('guides')
              ? '# Token guide\n\nSteps'
              : content,
          200,
        );
      }),
    );
    await tester.pumpWidget(
      app(
        DocumentationArticlePage(
          url: fixture['url'] as String,
          title: '\$getVar',
          entry: DocumentationEntry.fromJson(fixture),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(WebDocumentationView), findsNothing);
    expect(find.byTooltip('Copier le code'), findsOneWidget);
    await tester.tap(find.byTooltip('Copier le code'));
    await tester.pump();
    expect(copied, contains('\$setVar[xp;1]'));
    await screenshot(tester, 'docs-article-390');
    await tester.tap(find.byTooltip('Sommaire'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Details').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text('Token guide'),
      -500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Token guide'));
    await tester.pumpAndSettle();
    expect(find.text('Steps'), findsOneWidget);
    expect(find.byType(WebDocumentationView), findsNothing);
  });

  testWidgets('API failure offers retry and then displays native content', (
    tester,
  ) async {
    var status = 503;
    final repository = DocumentationRepository(
      client: MockClient(
        (_) async =>
            http.Response(jsonEncode([documentationFixture()]), status),
      ),
    );
    await tester.pumpWidget(
      app(
        DocumentationHubPage(
          repository: repository,
          initialSection: DocumentationSection.botCreatorDocs,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DocumentationLoadError), findsOneWidget);
    status = 200;
    await tester.tap(find.byTooltip('Recharger'));
    await tester.pumpAndSettle();
    expect(find.text('\$getVar'), findsOneWidget);
  });
}
