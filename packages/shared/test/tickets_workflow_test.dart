import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:test/test.dart';

void main() {
  group('Ticket system scripts', () {
    for (final entry in {
      'slash ticket command': r'''
$createChannel[ticket-$username;text;123456789012345678]
$editChannelPerms[123456789012345678;$authorID;+viewchannel;+sendmessages;+readmessagehistory]
$title[Support & Assistance]
$description[Bonjour <@$authorID> ! Un membre du support arrive.]
$color[#5865F2]
$addButton[no;close_ticket;Fermer le ticket;danger]
$ephemeral
Votre ticket a ete cree avec succes !
''',
      'button close ticket': r'''
Fermeture et suppression du ticket...
$wait[3s]
$deleteChannels[$channelID]
''',
    }.entries) {
      test('${entry.key} has no native diagnostics', () {
        final result = BdfdCompiler().compile(entry.value);
        expect(result.diagnostics, isEmpty);
      });
    }
  });
}
