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
}
