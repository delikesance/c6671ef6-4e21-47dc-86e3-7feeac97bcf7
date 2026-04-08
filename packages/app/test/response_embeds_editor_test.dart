import 'package:bot_creator/types/variable_suggestion.dart';
import 'package:bot_creator/widgets/response_embeds_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildEditor(List<Map<String, dynamic>> embeds) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ResponseEmbedsEditor(
          embeds: embeds,
          onChanged: (_) {},
          variableSuggestions: const <VariableSuggestion>[],
        ),
      ),
    ),
  );
}

List<Object> _takeAllExceptions(WidgetTester tester) {
  final exceptions = <Object>[];
  Object? error;
  while ((error = tester.takeException()) != null) {
    exceptions.add(error!);
  }
  return exceptions;
}

class _StatefulEditorHost extends StatefulWidget {
  const _StatefulEditorHost({required this.initialEmbeds});

  final List<Map<String, dynamic>> initialEmbeds;

  @override
  State<_StatefulEditorHost> createState() => _StatefulEditorHostState();
}

class _StatefulEditorHostState extends State<_StatefulEditorHost> {
  late List<Map<String, dynamic>> _embeds;

  @override
  void initState() {
    super.initState();
    _embeds = widget.initialEmbeds
        .map((embed) => Map<String, dynamic>.from(embed))
        .toList(growable: true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ResponseEmbedsEditor(
            embeds: _embeds,
            onChanged: (next) {
              setState(() {
                _embeds = next;
              });
            },
            variableSuggestions: const <VariableSuggestion>[],
          ),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('normalizes legacy embed payloads on narrow screens', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _buildEditor([
        <String, dynamic>{
          'title': 'Legacy embed',
          'description': 'Still editable',
          'image': 'https://cdn.discordapp.com/image.png',
          'thumbnail': 'https://cdn.discordapp.com/thumb.png',
          'author': 'Bot Creator',
          'footer': 'Footer text',
          'fields': <String, dynamic>{
            '0': <String, dynamic>{'name': 'Name', 'value': 'Value'},
          },
        },
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Response Embeds'), findsOneWidget);
    expect(find.text('Timestamp (ISO8601)'), findsOneWidget);
    expect(find.text('Color (int or #hex)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('removes embeds without fixed-length list errors', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    List<Map<String, dynamic>>? latestEmbeds;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ResponseEmbedsEditor(
              embeds: <Map<String, dynamic>>[
                <String, dynamic>{
                  'title': 'Embed to remove',
                  'description': 'Still editable',
                },
              ],
              onChanged: (next) {
                latestEmbeds = next;
              },
              variableSuggestions: const <VariableSuggestion>[],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    final exceptions = _takeAllExceptions(tester);
    expect(latestEmbeds, isEmpty);
    expect(find.textContaining('Response Embeds (0/10)'), findsOneWidget);
    expect(
      exceptions.where(
        (error) =>
            error.toString().contains('Cannot remove from a fixed-length list'),
      ),
      isEmpty,
    );
  });

  testWidgets(
    'typing in parent-controlled editor does not throw during build',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const _StatefulEditorHost(
          initialEmbeds: <Map<String, dynamic>>[
            <String, dynamic>{
              'title': 'Original title',
              'description': 'Original description',
            },
          ],
        ),
      );
      await tester.pumpAndSettle();

      final titleField = find.byType(TextFormField).first;
      await tester.enterText(titleField, 'Updated title');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final exceptions = _takeAllExceptions(tester);
      expect(find.text('Updated title'), findsOneWidget);
      expect(
        exceptions.where(
          (error) => error.toString().contains(
            'setState() or markNeedsBuild() called during build',
          ),
        ),
        isEmpty,
      );
    },
  );
}
