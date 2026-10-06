import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bot_creator/core/i18n/l10n/app_localizations.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/action_block.dart';
import 'package:bot_creator/features/documentation/documentation_article_page.dart';
import 'package:bot_creator/features/documentation/documentation_hub_page.dart';
import 'package:bot_creator/features/documentation/documentation_repository.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/documentation/documentation_preview.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_connector.dart';
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
  theme: AppTheme.lightTheme().copyWith(
    textTheme: AppTheme.lightTheme().textTheme.apply(fontFamily: 'Inter'),
  ),
  darkTheme: AppTheme.darkTheme().copyWith(
    textTheme: AppTheme.darkTheme().textTheme.apply(fontFamily: 'Inter'),
  ),
  themeMode: Platform.environment['DOCS_SCREENSHOT_DARK'] == '1'
      ? ThemeMode.dark
      : ThemeMode.light,
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
  setUpAll(() async {
    if (Platform.environment['DOCS_SCREENSHOT_DIR'] == null) return;
    for (final font in {
      'Inter': 'inter/Inter-Regular.ttf',
      'JetBrainsMono': 'jetbrainsmono/JetBrainsMono-Regular.ttf',
    }.entries) {
      final loader = FontLoader(font.key)
        ..addFont(rootBundle.load('assets/fonts/${font.value}'));
      await loader.load();
    }
  });
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

  testWidgets('opening an outdated entry recovers without pressing reload', (
    tester,
  ) async {
    final fixture = documentationFixture(content: '# Before update');
    final repository = DocumentationRepository(
      client: MockClient(
        (request) async => http.Response(
          request.url.path.contains('index.json')
              ? jsonEncode([documentationFixture(content: '# After update')])
              : '# After update',
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      app(
        DocumentationArticlePage(
          url: fixture['url'] as String,
          title: 'Article',
          entry: DocumentationEntry.fromJson(fixture),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('After update'), findsOneWidget);
    expect(find.byType(DocumentationLoadError), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article reload refreshes its index revision before its body', (
    tester,
  ) async {
    var content = '# Before update';
    final fixture = documentationFixture(content: content);
    final repository = DocumentationRepository(
      client: MockClient(
        (request) async => http.Response(
          request.url.path.contains('index.json')
              ? jsonEncode([documentationFixture(content: content)])
              : content,
          200,
        ),
      ),
    );
    await tester.pumpWidget(
      app(
        DocumentationArticlePage(
          url: fixture['url'] as String,
          title: 'Article',
          entry: DocumentationEntry.fromJson(fixture),
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Before update'), findsOneWidget);
    content = '# After update';
    await tester.tap(find.byTooltip('Recharger'));
    await tester.pumpAndSettle();
    expect(find.text('After update'), findsOneWidget);
    expect(find.byType(DocumentationLoadError), findsNothing);
  });

  testWidgets('filters align, apply and reset without erasing the query', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = DocumentationRepository(
      client: MockClient(
        (_) async => http.Response(
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
        ),
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
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    final category = find.byTooltip('Catégorie');
    final mode = find.byTooltip('Mode');
    expect(tester.getTopLeft(category).dy, tester.getTopLeft(mode).dy);
    await tester.tap(category);
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'Workflows'),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Blocks'), findsOneWidget);
    expect(find.text('\$getVar'), findsNothing);
    await tester.tap(find.byIcon(Icons.restart_alt));
    await tester.pumpAndSettle();
    expect(find.text('\$getVar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, 'docs-filters-320');
  });

  testWidgets(
    'website anchors scroll and code has syntax colors inside safe area',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final content =
          '# Example {#example}\n\n[Jump](#original-id)\n\n```bdfd\n\$setVar[xp;1]\n```\n\n'
          '${List.filled(35, 'A paragraph.\n\n').join()}## Different title {#original-id}\n\nTarget.';
      final fixture = documentationFixture(content: content);
      final repository = DocumentationRepository(
        client: MockClient((_) async => http.Response(content, 200)),
      );
      await tester.pumpWidget(
        app(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              padding: EdgeInsets.only(bottom: 34),
              viewPadding: EdgeInsets.only(bottom: 34),
            ),
            child: DocumentationArticlePage(
              url: fixture['url'] as String,
              title: 'Example',
              entry: DocumentationEntry.fromJson(fixture),
              repository: repository,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Example {#example}'), findsNothing);
      expect(
        tester.getBottomLeft(find.byType(SingleChildScrollView).first).dy,
        lessThanOrEqualTo(810),
      );
      final code = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere(
            (text) => text.text.toPlainText().contains('\$setVar[xp;1]'),
          );
      final colors = <Color>{};
      void collect(InlineSpan span) {
        if (span.style?.color != null) colors.add(span.style!.color!);
        if (span is TextSpan) {
          for (final child in span.children ?? <InlineSpan>[]) {
            collect(child);
          }
        }
      }

      collect(code.text);
      expect(colors.length, greaterThan(1));
      await screenshot(tester, 'docs-safe-area-code-390');
      await tester.tap(find.text('Jump'));
      await tester.pumpAndSettle();
      expect(find.text('Target.').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('app link routing keeps docs native, not privacy or other hosts', () {
    expect(
      isDocumentationArticleUrl(
        Uri.parse('$botCreatorDocsBaseUrl/getvar/#usage'),
      ),
      isTrue,
    );
    expect(
      isDocumentationArticleUrl(Uri.parse('$botTokenTutorialUrl.html')),
      isTrue,
    );
    expect(isDocumentationArticleUrl(Uri.parse(privacyPolicyUrl)), isFalse);
    expect(
      isDocumentationArticleUrl(Uri.parse('https://discord.com/developers')),
      isFalse,
    );
  });

  test(
    'structured preview decoder rejects malformed and unsupported payloads',
    () {
      expect(DocumentationPreview.decode('bc-dual-view', '{'), isNull);
      expect(
        DocumentationPreview.decode(
          'bc-dual-view',
          '{"version":2,"panels":[]}',
        ),
        isNull,
      );
      expect(
        DocumentationPreview.decode(
          'bc-block-flow',
          '{"version":1,"blocks":["bad"]}',
        ),
        isNull,
      );
      expect(
        DocumentationPreview.decode(
          'javascript',
          '{"version":1,"panels":[{}]}',
        ),
        isNull,
      );
    },
  );

  testWidgets(
    'ticket permissions use the editor field without mobile overflow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DocumentationPreview(
                  kind: 'bc-block-flow',
                  data: {
                    'version': 1,
                    'blocks': [
                      {
                        'action': {
                          'type': 'editChannelPermissions',
                          'payload': {
                            'channelId': '((action.ticket_chan))',
                            'targetType': 'member',
                            'targetId': '((user.id))',
                            'allow': '68608',
                            'deny': '0',
                          },
                        },
                      },
                    ],
                  },
                  markdown: (text) => Text(text),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ActionBlock), findsOneWidget);
      expect(find.text('Allow'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [const Size(320, 780), const Size(1200, 850)]) {
    testWidgets(
      'block script switch and Discord embeds render natively at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final flow = jsonEncode({
          'version': 1,
          'blocks': [
            {
              'trigger': {'type': 'slash', 'name': 'ping'},
              'title': 'SLASH COMMAND: /ping',
              'badge': 'Trigger',
              'category': 'entrypoint',
              'description': 'Measures bot latency.',
              'fields': [],
              'toggles': [],
            },
            {
              'action': {
                'type': 'respondWithMessage',
                'payload': {'content': 'Pong!', 'ephemeral': true},
              },
              'title': 'RESPOND TO INTERACTION',
              'badge': 'Terminal',
              'category': 'interactions',
              'description': '',
              'fields': [
                {'label': 'Embed Title', 'value': 'Pong!'},
              ],
              'toggles': [
                {'label': 'Ephemeral Reply', 'enabled': true},
              ],
            },
          ],
        });
        final dual = jsonEncode({
          'version': 1,
          'panels': [
            {'label': 'Blocks', 'markdown': '```bc-block-flow\n$flow\n```'},
            {'label': 'Script', 'markdown': '```bdfd\n\$title[Pong!]\n```'},
          ],
        });
        final discord = jsonEncode({
          'version': 1,
          'messages': [
            {
              'avatar': 'B',
              'username': 'Bot Creator Assistant',
              'botTag': 'BOT',
              'timestamp': 'Today at 3:00 PM',
              'content': 'Welcome **Jeremy**!',
              'embeds': [
                {
                  'color': '#5865F2',
                  'title': 'Pong!',
                  'description': 'Latency: **24 ms**',
                  'footer': 'Example',
                },
              ],
              'buttons': [
                {'label': 'Close Ticket', 'style': 'danger'},
              ],
              'ephemeral': 'Only you can see this',
            },
          ],
        });
        final content =
            '# Example\n\n```bc-dual-view\n$dual\n```\n\n```bc-discord-preview\n$discord\n```';
        final fixture = documentationFixture(content: content);
        final repository = DocumentationRepository(
          client: MockClient((_) async => http.Response(content, 200)),
        );
        await tester.pumpWidget(
          app(
            DocumentationArticlePage(
              url: fixture['url'] as String,
              title: 'Example',
              entry: DocumentationEntry.fromJson(fixture),
              repository: repository,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(EntryPointBlock), findsOneWidget);
        expect(find.byType(ActionBlock), findsOneWidget);
        expect(find.byType(ScratchBlockConnector), findsOneWidget);
        final actionBlock = tester.widget<ActionBlock>(
          find.byType(ActionBlock),
        );
        expect(actionBlock.readOnly, isTrue);
        expect(actionBlock.action.parameters['ephemeral'], isTrue);
        expect(
          find.descendant(
            of: find.byType(ActionBlock),
            matching: find.byType(PopupMenuButton<String>),
          ),
          findsNothing,
        );
        final fields = find.descendant(
          of: find.byType(ActionBlock),
          matching: find.byType(TextField),
        );
        expect(fields, findsWidgets);
        await tester.tap(fields.first, warnIfMissed: false);
        await tester.pump();
        expect(
          tester.widget<TextField>(fields.first).focusNode?.hasFocus ?? false,
          isFalse,
        );
        expect(tester.takeException(), isNull);
        await screenshot(tester, 'docs-previews-blocks-${size.width.toInt()}');
        await tester.tap(find.text('Script'));
        await tester.pumpAndSettle();
        expect(find.byType(EntryPointBlock), findsNothing);
        expect(find.byType(ActionBlock), findsNothing);
        expect(find.byTooltip('Copier le code'), findsOneWidget);
        await tester.tap(find.byTooltip('Copier le code'));
        await tester.pump();
        await tester.scrollUntilVisible(
          find.text('Close Ticket'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Bot Creator Assistant'), findsOneWidget);
        expect(find.text('Pong!'), findsOneWidget);
        expect(find.text('Only you can see this'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await screenshot(tester, 'docs-previews-discord-${size.width.toInt()}');
      },
    );
  }
}
