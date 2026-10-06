import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/utils/embed_fields.dart';
import 'package:test/test.dart';

const boostScript = r'''
$var[boostsNeeded;0]
$if[$boostLevel==0]
$var[boostsNeeded;$sub[2;$serverBoostCount]]
$var[nextLevel;1]
$elseIf[$boostLevel==1]
$var[boostsNeeded;$sub[7;$serverBoostCount]]
$var[nextLevel;2]
$elseIf[$boostLevel==2]
$var[boostsNeeded;$sub[14;$serverBoostCount]]
$var[nextLevel;3]
$else
$var[boostsNeeded;0]
$var[nextLevel;MAX]
$endif
$title[Boost - $serverName]
$addField[Current Level;$boostLevel;yes]
$addField[Boosts;$serverBoostCount;yes]
$if[$boostLevel<3]
$addField[Next Level;$var[boostsNeeded] boosts remaining for level $var[nextLevel];yes]
$endif
$color[#F47FFF]
''';

void main() {
  for (var level = 0; level <= 3; level++) {
    test(
      'boost level $level produces one embed with conditional fields',
      () async {
        final result = await testCommandInSandbox({
          'script': boostScript,
          'variables': {'guild.id': '10'},
          'entities': {
            'guilds': {
              '10': {
                'name': 'Test Server',
                'premium_tier': level,
                'premium_subscription_count': [0, 3, 8, 14][level],
              },
            },
          },
        });
        expect(result['success'], true, reason: '${result['error']}');
        final responses = result['responses'] as List;
        expect(responses, hasLength(1));
        final embeds = responses.single['payload']['embeds'] as List;
        expect(embeds, hasLength(1));
        expect(embeds.single['title'], 'Boost - Test Server');
        expect(embeds.single['color'], '#F47FFF');
        final fields = embeds.single['fields'] as List;
        expect(fields, hasLength(level == 3 ? 2 : 3));
        expect(fields.first['value'], '$level');
        if (level < 3) {
          expect(
            fields.last['value'],
            '${[2, 4, 6][level]} boosts remaining for level ${level + 1}',
          );
        }
      },
    );
  }

  test(
    'conditional field selection is frozen before later variable edits',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$var[x;1]$title[Test]$if[$var[x]==1]$addField[A;Yes]$elseIf[$var[x]==2]$addField[B;No]$else$addField[C;No]$endif$var[x;2]',
      });
      expect(result['success'], true);
      final responses = result['responses'] as List;
      expect(responses, hasLength(1));
      expect(responses.single['payload']['embeds'][0]['fields'], hasLength(1));
      expect(
        responses.single['payload']['embeds'][0]['fields'][0]['name'],
        'A',
      );
    },
  );

  test('production embed builder omits fields from inactive branches', () {
    final fields = buildResolvedEmbedFields(
      embedJson: {
        'fields': [
          {'name': 'Visible', 'value': 'Yes', 'includeIf': 'true'},
          {'name': 'Hidden', 'value': 'No', 'includeIf': 'false'},
          {'name': 'Ordinary', 'value': 'Yes'},
        ],
      },
      resolve: (value) => value,
    );
    expect(fields, hasLength(2));
    expect(fields.first.name, 'Visible');
    expect(fields.last.name, 'Ordinary');
  });

  test(
    'conditional fields retain calculations and deferred inline actions',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$textSplit[a,b;,]$title[Test]$if[1==1]$var[n;7]$addField[Number;$var[n]]$addField[Part;$splitText[2]]$endif',
      });
      expect(result['success'], true, reason: '${result['error']}');
      final responses = result['responses'] as List;
      expect(responses, hasLength(1));
      final fields = responses.single['payload']['embeds'][0]['fields'] as List;
      expect(fields, hasLength(2));
      expect(fields[0]['value'], '7');
      expect(fields[1]['value'], 'b');
    },
  );
}
