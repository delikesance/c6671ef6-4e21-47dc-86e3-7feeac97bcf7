import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator/core/bdfd_editor/bdfd_script_language.dart';
import 'package:bot_creator/core/bdfd_editor/bdfd_validation.dart';
import 'package:bot_creator/features/bot_editor/logic/command_editor_notifier.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/command_sandbox_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'native validation accepts opaque unknown calls without inspecting their arguments',
    () {
      expect(
        bdfdDiagnosticsFor(
          r'$unknown[$kickMention;$sendMessage[x;invalid]]',
          backend: 'native-v1',
        ),
        isEmpty,
      );
    },
  );
  test(
    'native validation checks the actual message registry without executing services',
    () {
      expect(
        bdfdDiagnosticsFor(
          r'$findUser[Alice;no]$randomUserID$randomUser$randomMention$membersCount$allMembersCount$isBooster[20;10]$isTimedOut[20]$getMessage[30;123;content]$getAttachments[0]$getEmbedData[30;123;1;title]$authorOfMessage[30;123]$deleteMessage[30;123]$pinMessage$unpinMessage[30;123]$publishMessage[30;123]$addReactions[✅]$addCmdReactions[✅]$addMessageReactions[30;123;✅]$clearReactions[30;123;!all]$getReactions[30;123;,;✅]$userReacted[30;123;20;✅]$byteCount[text]$linesCount[text]$cropText[text;2;...]$sort[3;1;asc;-1;,]$numberSeparator[12345]$isNumber[1]$isBoolean[yes]$isValidHex[#fff]$onlyForIDs[20;denied]$onlyForUsers[Name;denied]$onlyForChannels[30;denied]$onlyForServers[10;denied]$ignoreChannels[40;denied]$blackListIDs[21;denied]$blackListUsers[Other;denied]$blackListServers[11;denied]$onlyIfMessageContains[hello;he;denied]$varExists[x]$resetUserVar[x;20]$resetServerVar[x]$resetChannelVar[x]$author[Name;2]$footer[Footer;2]$authorIcon[https://example.test/a.png;2]$authorURL[https://example.test;2]$footerIcon[https://example.test/f.png;2]$embeddedURL[https://example.test;2]$addTimestamp[2]$userExists[20]$userJoined[20;2006-01-02]$userAvatar[20]$authorAvatar$username[20]$displayName[20]$nickname[20]$discriminator[]$userBanner[20]$userBannerColor[20]$userServerAvatar[20]$guildExists[10]$serverCount$serverNames$serverOwner$serverDescription$serverVerificationLvl$serverIcon$guildBanner[10]$boostCount$boostLevel$afkTimeout[10]$startThread[Thread;30;;60;yes]$editThread[80;Thread;no;60;no;0]$threadAddMember[80;20]$threadRemoveMember[80;20]$threadMessageCount$threadUserCount$sendMessage[hello;yes]$httpGet[https://example.test]$setVar[x;1]$kick[222]$ban[Spam]$banID[;333]$unban$unbanID[222]$timeout[1m;222]$untimeout[222]$kickMention[Spam]',
          backend: 'native-v1',
        ),
        isEmpty,
      );
      final errors = bdfdDiagnosticsFor(
        '\n\$kickMention',
        backend: 'native-v1',
      );
      expect(errors, hasLength(1));
      expect(errors.single.line, 2);
      expect(errors.single.functionName, r'$kickMention');
    },
  );
  test(
    'native language diagnostics reject unsupported known functions in untaken branches',
    () {
      final language = BdfdScriptLanguage(backend: 'native-v1');
      expect(
        language.diagnosticsFor(r'$if[false]$kickMention$endif'),
        isNotEmpty,
      );
      expect(language.diagnosticsFor(r'$unknown[$kickMention]'), isEmpty);
    },
  );
  test(
    'unknown backend produces a diagnostic rather than selecting legacy',
    () {
      expect(
        bdfdDiagnosticsFor('hello', backend: 'unknown-v99').single.message,
        contains('Unknown BDFD backend'),
      );
    },
  );
  for (final backend in ['native-v1', 'legacy-v1', 'future-v99']) {
    test(
      'command normalization preserves backend $backend across repeated loads',
      () {
        final raw = {
          'name': 'native',
          'data': {
            'executionMode': 'bdfd_script',
            'bdfdBackend': backend,
            'bdfdScriptContent': r'$sendMessage[x;yes]',
          },
        };
        final normalized = normalizeCommandData(normalizeCommandData(raw));
        expect(normalized['data']['bdfdBackend'], backend);
        expect(normalized['data']['bdfdScriptContent'], r'$sendMessage[x;yes]');
      },
    );
  }

  test('notifier revalidates the same source when switching engines', () {
    final notifier = CommandEditorNotifier();
    addTearDown(notifier.dispose);
    notifier.updateBdfdScriptContent(r'$kickMention');
    expect(notifier.state.hasBdfdCompileErrors, false);
    notifier.updateBdfdBackend('native-v1');
    expect(notifier.state.bdfdCompileResult, isNull);
    expect(notifier.state.hasBdfdCompileErrors, true);
    notifier.updateBdfdScriptContent(r'$unknown[$kickMention]');
    expect(notifier.state.hasBdfdCompileErrors, false);
    notifier.updateBdfdBackend('legacy-v1');
    expect(notifier.state.bdfdBackend, 'legacy-v1');
    expect(notifier.state.bdfdCompileResult, isNotNull);
  });
  testWidgets(
    'sandbox uses the editor backend and protects it from advanced fixtures',
    (tester) async {
      Map<String, dynamic>? received;
      await tester.pumpWidget(
        MaterialApp(
          home: CommandSandboxPage(
            script: r'$sendMessage[x]',
            bdfdBackend: 'native-v1',
            initialScenario: const {'bdfdBackend': 'legacy-v1'},
            runner: (request) async {
              received = request;
              return {'success': true, 'responses': [], 'trace': []};
            },
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Run test'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Run test'));
      await tester.pumpAndSettle();
      expect(received!['bdfdBackend'], 'native-v1');
      expect(received!['script'], r'$sendMessage[x]');
      expect(tester.takeException(), isNull);
    },
  );
}
