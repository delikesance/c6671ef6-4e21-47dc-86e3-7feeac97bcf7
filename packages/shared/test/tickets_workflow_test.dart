import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

void main() {
  group('Ticket System Workflow Transpilation', () {
    test('transpiles slash ticket command correctly', () {
      const script = r'''
$createChannel[ticket-$username;text;123456789012345678]
$editChannelPerms[123456789012345678;$authorID;+viewchannel;+sendmessages;+readmessagehistory]
$title[Support & Assistance]
$description[Bonjour <@$authorID> ! Un membre du support arrive.]
$color[#5865F2]
$addButton[close_ticket;Fermer le ticket;danger]
$ephemeral
✅ Votre ticket a été créé avec succès !
''';
      final result = BdfdCompiler().compile(script);
      expect(result.hasErrors, isFalse);
      expect(
        result.actions.any((a) => a.type == BotCreatorActionType.createChannel),
        isTrue,
      );
      expect(
        result.actions.any(
          (a) => a.type == BotCreatorActionType.editChannelPermissions,
        ),
        isTrue,
      );
      expect(
        result.actions.any(
          (a) => a.type == BotCreatorActionType.respondWithMessage,
        ),
        isTrue,
      );
    });

    test('transpiles clean tickets script correctly', () {
      const script = r'''
$var[ticketChan;$createChannel[ticket-$username;text;123456789012345678]]
$editChannelPerms[$var[ticketChan];$authorID;+viewchannel;+sendmessages;+readmessagehistory]
$useChannel[$var[ticketChan]]
$title[Support & Assistance]
$description[Bonjour <@$authorID> ! Veuillez détailler votre demande ici.\nUn membre de l'équipe va vous assister incessamment sous peu.\n\nPour clore ce ticket, cliquez sur le bouton rouge ci-dessous.]
$color[#5865F2]
$addButton[no;close_ticket;Fermer le ticket;danger]
$useChannel[]
$ephemeral
✅ Votre ticket d'assistance a été ouvert : <#$var[ticketChan]>
''';
      final result = BdfdCompiler().compile(script);
      print(
        'Clean Diagnostics: ${result.diagnostics.map((d) => d.message).toList()}',
      );
      for (final a in result.actions) {
        print('Clean Action: ${a.type} -> ${a.payload}');
      }
      expect(result.hasErrors, isFalse);
      expect(
        result.actions.any((a) => a.type == BotCreatorActionType.createChannel),
        isTrue,
      );
      expect(
        result.actions.any(
          (a) => a.type == BotCreatorActionType.editChannelPermissions,
        ),
        isTrue,
      );
      expect(
        result.actions
            .where((a) => a.type == BotCreatorActionType.respondWithMessage)
            .length,
        2,
      );
    });

    test('transpiles button close ticket interaction correctly', () {
      const script = r'''
🔒 Fermeture et suppression du ticket...
$wait[3s]
$deleteChannels[$channelID]
''';
      final result = BdfdCompiler().compile(script);

      expect(result.hasErrors, isFalse);
      expect(
        result.actions.any(
          (a) => a.type == BotCreatorActionType.respondWithMessage,
        ),
        isTrue,
      );
      expect(
        result.actions.any((a) => a.type == BotCreatorActionType.wait),
        isTrue,
      );
      expect(
        result.actions.any((a) => a.type == BotCreatorActionType.removeChannel),
        isTrue,
      );
      final removeAction = result.actions.firstWhere(
        (a) => a.type == BotCreatorActionType.removeChannel,
      );
      expect(removeAction.payload['channelIds'], ['((channel.id))']);
    });
  });
}
