import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/services/runtime_temporary_variables.dart';
import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Gateway implements NyxxGateway {
  final guild = _Guild();
  @override
  GuildManager get guilds => _GuildManager(guild);
  @override
  PartialUser get user => _User(Snowflake(500));
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected gateway access');
}

class _User implements PartialUser {
  _User(this.id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected user access');
}

class _GuildManager implements GuildManager {
  _GuildManager(this.guild);
  final _Guild guild;
  @override
  Future<Guild> get(Snowflake id) async => guild;
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected guild manager access');
}

class _Guild implements Guild {
  final memberManager = _Members();
  @override
  Snowflake get id => Snowflake(10);
  @override
  Snowflake get ownerId => Snowflake(999);
  @override
  List<Role> get roleList => [_Role(10, 0), _Role(63, 10)];
  @override
  MemberManager get members => memberManager;
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected guild access');
}

class _Role implements Role {
  _Role(int id, this.position) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  final int position;
  @override
  Permissions get permissions => Permissions(Permissions.kickMembers.value);
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected role access');
}

class _Members implements MemberManager {
  Snowflake? deleted;
  String? reason;
  @override
  Future<Member> get(Snowflake id) async => _Member(id, this);
  @override
  PartialMember operator [](Snowflake id) => _Member(id, this);
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected member manager access');
}

class _Member implements Member {
  _Member(this.id, this.manager);
  @override
  final Snowflake id;
  @override
  final _Members manager;
  @override
  List<Snowflake> get roleIds => id == Snowflake(500) ? [Snowflake(63)] : [];
  @override
  Future<void> delete({String? auditLogReason}) async {
    manager.deleted = id;
    manager.reason = auditLogReason;
  }

  @override
  dynamic noSuchMethod(Invocation i) =>
      throw StateError('Unexpected member access');
}

class _Responses implements ActionExecutionPolicy {
  final contents = <String>[];
  @override
  bool get allowDiscordHydration => false;
  @override
  void checkBudget() {}
  @override
  void record(Map<String, dynamic> frame) {}
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async {
    if (action.type != BotCreatorActionType.respondWithMessage) return false;
    contents.add(resolveValue((action.payload['content'] ?? '').toString()));
    return true;
  }
}

class _NativeResponses implements BotMessageService {
  _NativeResponses(this.responses);
  final _Responses responses;
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    responses.contents.add(request.payload['content']?.toString() ?? '');
    return const BotMessageResult(messageId: '123');
  }
}

const script = r'''$nomention
$var[cible;$mentioned[1]]
$onlyIf[$var[cible]!=;❌ Utilisation : `!kick @membre raison`]
$onlyIf[$var[cible]!=$authorID;❌ Tu ne peux pas t'expulser toi-même.]
$textSplit[$message; ]
$var[raison;$replaceText[$message;$splitText[1] ;;1]]
$var[raison;$replaceText[$var[raison];$var[cible];;-1]]
$var[raison;$replaceText[$var[raison];<@;]]
$var[raison;$replaceText[$var[raison];!;]]
$var[raison;$replaceText[$var[raison];>;;-1]]
$var[raison;$trimSpace[$var[raison]]]
$if[$var[raison]==]
$var[raison;Aucune raison fournie]
$endif
$kick[$var[cible];$var[raison]]
$title[👢 Membre expulsé]
$color[#ff9900]
$description[<@$var[cible]> a été expulsé de $serverName.]
$addField[Raison;$var[raison]]
$footer[Expulsé par $username]''';
void main() {
  test(
    'native prefix with explicit no mention fallback reports usage without moderation',
    () async {
      final gateway = _Gateway();
      final responses = _Responses();
      final variables = <String, String>{
        'author.id': '999',
        'message.content': '!kick',
      };
      await BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'test',
        messages: _NativeResponses(responses),
        moderation: DiscordBotModerationService(
          client: gateway,
          guildId: Snowflake(10),
        ),
      ).execute(
        script.replaceFirst(r'$mentioned[1]', r'$mentioned[1;no]'),
        context: BdfdContext(
          variables: variables,
          temporaryVariables: RuntimeTemporaryVariables(variables),
        ),
      );
      expect(variables['temp.cible'], '');
      expect(gateway.guild.memberManager.deleted, isNull);
      expect(responses.contents.join(), contains('Utilisation'));
    },
  );
}
