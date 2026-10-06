import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_layout_engine.dart';

void main() {
  testWidgets(
    'BlueprintLayoutEngine builds graph with entry point and actions',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final actions = [
                ActionItem(
                  id: 'act_1',
                  type: BotCreatorActionType.sendMessage,
                  parameters: {'message': 'Hello world!'},
                  actionKey: 'act_1',
                ),
                ActionItem(
                  id: 'act_2',
                  type: BotCreatorActionType.ifBlock,
                  parameters: {
                    'left': 'test',
                    'operator': '==',
                    'right': 'test',
                  },
                  actionKey: 'act_2',
                ),
              ];

              final graph = BlueprintLayoutEngine.buildGraph(
                context: context,
                commandName: 'ping',
                isInteraction: true,
                actions: actions,
              );

              // 1 Entry Point + 2 Actions = 3 nodes
              expect(graph.nodes.length, equals(3));
              expect(graph.nodes[0].isEntryPoint, isTrue);
              expect(graph.nodes[0].title, equals('/ping'));
              expect(graph.nodes[1].id, equals('act_1'));
              expect(graph.nodes[2].id, equals('act_2'));

              // ifBlock should have branches (then_out, else_out, exec_out)
              final ifNode = graph.nodes[2];
              expect(ifNode.outPins.any((p) => p.id == 'then_out'), isTrue);
              expect(ifNode.outPins.any((p) => p.id == 'else_out'), isTrue);

              // Connections should chain Entry -> act_1 -> act_2
              expect(graph.connections.length, equals(2));
              expect(
                graph.connections[0].fromNodeId,
                equals('__entry_point__'),
              );
              expect(graph.connections[0].toNodeId, equals('act_1'));
              expect(graph.connections[1].fromNodeId, equals('act_1'));
              expect(graph.connections[1].toNodeId, equals('act_2'));

              return const SizedBox();
            },
          ),
        ),
      );
    },
  );

  testWidgets(
    'BlueprintLayoutEngine builds nested THEN and ELSE branch nodes and connections',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final actions = [
                ActionItem(
                  id: 'if_1',
                  type: BotCreatorActionType.ifBlock,
                  parameters: {
                    'left': 'x',
                    'operator': '==',
                    'right': 'y',
                    'thenActions': [
                      {
                        'id': 'then_sub_1',
                        'type': BotCreatorActionType.sendMessage.name,
                        'payload': {'message': 'True branch'},
                      },
                    ],
                    'elseActions': [
                      {
                        'id': 'else_sub_1',
                        'type': BotCreatorActionType.sendMessage.name,
                        'payload': {'message': 'False branch'},
                      },
                    ],
                  },
                  actionKey: 'if_1',
                ),
              ];

              final graph = BlueprintLayoutEngine.buildGraph(
                context: context,
                commandName: 'test',
                isInteraction: true,
                actions: actions,
              );

              // 1 Entry + 1 IF + 1 Then child + 1 Else child = 4 nodes
              expect(graph.nodes.length, equals(4));
              expect(graph.nodes.any((n) => n.id == 'then_sub_1'), isTrue);
              expect(graph.nodes.any((n) => n.id == 'else_sub_1'), isTrue);

              // Check branch connections
              expect(
                graph.connections.any(
                  (c) =>
                      c.fromNodeId == 'if_1' &&
                      c.fromPinId == 'then_out' &&
                      c.toNodeId == 'then_sub_1',
                ),
                isTrue,
              );
              expect(
                graph.connections.any(
                  (c) =>
                      c.fromNodeId == 'if_1' &&
                      c.fromPinId == 'else_out' &&
                      c.toNodeId == 'else_sub_1',
                ),
                isTrue,
              );

              return const SizedBox();
            },
          ),
        ),
      );
    },
  );

  testWidgets(
    'BlueprintLayoutEngine builds nested ELSE IF branch nodes and connections',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final actions = [
                ActionItem(
                  id: 'if_complex',
                  type: BotCreatorActionType.ifBlock,
                  parameters: {
                    'left': 'a',
                    'operator': '==',
                    'right': 'b',
                    'thenActions': [
                      {
                        'id': 'then_1',
                        'type': BotCreatorActionType.sendMessage.name,
                        'payload': {'message': 'Then'},
                      },
                    ],
                    'elseIfConditions': [
                      {
                        'left': 'a',
                        'operator': '>',
                        'right': 'b',
                        'actions': [
                          {
                            'id': 'elseif_sub_1',
                            'type': BotCreatorActionType.sendMessage.name,
                            'payload': {'message': 'Else if action'},
                          },
                        ],
                      },
                    ],
                    'elseActions': [
                      {
                        'id': 'else_1',
                        'type': BotCreatorActionType.sendMessage.name,
                        'payload': {'message': 'Else'},
                      },
                    ],
                  },
                  actionKey: 'if_complex',
                ),
              ];

              final graph = BlueprintLayoutEngine.buildGraph(
                context: context,
                commandName: 'complex',
                isInteraction: true,
                actions: actions,
              );

              // 1 Entry + 1 IF + 1 Then + 1 ElseIf + 1 Else = 5 nodes
              expect(graph.nodes.length, equals(5));
              expect(graph.nodes.any((n) => n.id == 'elseif_sub_1'), isTrue);

              final ifNode = graph.nodes.firstWhere(
                (n) => n.id == 'if_complex',
              );
              expect(ifNode.outPins.any((p) => p.id == 'elseif_out_0'), isTrue);

              // Check Else If wire
              expect(
                graph.connections.any(
                  (c) =>
                      c.fromNodeId == 'if_complex' &&
                      c.fromPinId == 'elseif_out_0' &&
                      c.toNodeId == 'elseif_sub_1',
                ),
                isTrue,
              );

              return const SizedBox();
            },
          ),
        ),
      );
    },
  );
}
