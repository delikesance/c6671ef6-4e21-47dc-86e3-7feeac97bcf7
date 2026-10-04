import 'package:bot_creator/features/bot_editor/presentation/screens/command_sandbox_page.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/sandbox_functions_page.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'function laboratory lets users choose the rejected guard scenario',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SandboxFunctionsPage()));
      await tester.enterText(find.byType(TextField), 'onlyadmin');
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'$onlyadmin'));
      await tester.pumpAndSettle();
      expect(find.text('Allowed'), findsOneWidget);
      expect(find.text('Denied'), findsOneWidget);
      await tester.tap(find.text('Denied'));
      await tester.pumpAndSettle();
      expect(find.text('Expected response: Access denied.'), findsOneWidget);
    },
  );
  testWidgets(
    'embed contracts fail on wrong fields and fixtures cannot replace editor source',
    (tester) async {
      Future<Map<String, dynamic>>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: CommandSandboxPage(
            script: r'$title[actual]',
            initialScenario: const {'script': r'$title[expected]'},
            expectedValues: const {
              '/responses/0/payload/embeds/0/title': 'expected',
            },
            runner: (request) => pending = testCommandInSandbox(request),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Run test'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Run test'));
      await tester.runAsync(() async {
        await pending;
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Test failed'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Test failed'), findsOneWidget);
      final value = await pending;
      expect(value!['responses'][0]['payload']['embeds'][0]['title'], 'actual');
      expect(value['contract_checks'][0]['passed'], false);
      await tester.scrollUntilVisible(
        find.textContaining('"title": "actual"'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('"title": "actual"'), findsOneWidget);
    },
  );
  testWidgets(
    'individual function laboratory exposes editable regression cases',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SandboxFunctionsPage()));
      await tester.enterText(find.byType(TextField), 'isnumber');
      await tester.pumpAndSettle();
      expect(find.text(r'$isnumber'), findsOneWidget);
      await tester.tap(find.text(r'$isnumber'));
      await tester.pumpAndSettle();
      expect(find.text('Test script'), findsOneWidget);
      expect(find.text('Expected response: true'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Run test'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Run test'), findsOneWidget);
    },
  );
  testWidgets(
    'function test distinguishes wrong output from a successful execution',
    (tester) async {
      Future<Map<String, dynamic>>? pending;
      await tester.pumpWidget(
        MaterialApp(
          home: CommandSandboxPage(
            script: 'wrong',
            expectedResponse: 'right',
            runner: (request) => pending = testCommandInSandbox(request),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Run test'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Run test'));
      await tester.runAsync(() async {
        await pending;
      });
      await tester.pumpAndSettle();
      expect(find.text('Test failed'), findsOneWidget);
    },
  );
  testWidgets('mobile draft test shows simulated output without saving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<Map<String, dynamic>>? pending;
    await tester.pumpWidget(
      MaterialApp(
        home: CommandSandboxPage(
          runner: (request) => pending = testCommandInSandbox(request),
          script: r'$reply$c[]$sum[$message[amount];2]',
          options: [
            {'name': 'amount', 'type': 4, 'required': true},
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).at(2), '100');
    await tester.ensureVisible(find.text('Run test'));
    await tester.tap(find.text('Run test'));
    await tester.runAsync(() async {
      await pending;
    });
    await tester.pumpAndSettle();
    expect(find.text('102'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Variables after'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Variables after'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('canvas result shows the rendered image in the emulator', (
    tester,
  ) async {
    Future<Map<String, dynamic>>? pending;
    await tester.pumpWidget(
      MaterialApp(
        home: CommandSandboxPage(
          script: r'$canvasCreate[card;2;2;red]',
          runner: (request) => pending = testCommandInSandbox(request),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Run test'));
    await tester.tap(find.text('Run test'));
    await tester.runAsync(() async {
      await pending;
    });
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Generated images'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Generated images'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect((await pending)!['images']['card']['pixels']['0,0'], '#ff0000ff');
  });

  testWidgets(
    'supports block-based commands with string option types without cast error',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CommandSandboxPage(
            script: null,
            actions: const [
              {
                'type': 'sendMessage',
                'payload': {'text': 'Hello from blocks!'},
              },
            ],
            options: const [
              {'name': 'query', 'type': 'string', 'required': true},
              {'name': 'count', 'type': 'integer'},
            ],
            runner: (request) async => {'success': true, 'responses': []},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Block-based command'), findsOneWidget);
      expect(find.text('1 configured action(s)'), findsOneWidget);
      expect(find.text('query'), findsOneWidget);
      expect(find.text('count'), findsOneWidget);
    },
  );
}
