import '../../services/bot_moderation_service.dart';
import '../../services/bot_user_query_service.dart';
import '../../services/command_input.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdBotQueryFunctions({
  BotModerationService? moderation,
}) => {
  'botname': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async =>
        call.context.variables['bot.username'] ??
        call.context.variables['bot.name'] ??
        'Bot',
  ),
  'botownerid': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['bot.ownerId'] ?? '',
  ),
  'botnode': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['bot.node'] ?? '1',
  ),
  // Wiki: sets the command description for the bot list; no runtime effect.
  'botlistdescription': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async {
      await call.argument(0);
      return '';
    },
  ),
  'botlisthide': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'nodeversion': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async =>
        call.context.variables['bot.nodeVersion'] ?? 'v20.0.0',
  ),
  'ping': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['bot.ping'] ?? '0',
  ),
  'shardid': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['bot.shardId'] ?? '0',
  ),
  // Wiki: $getInviteInfo[Invite code;Invite property]. No invite service
  // exists, so values come from the host-supplied `invite[code].property`
  // context variables; an invite the host did not describe yields no text.
  'getinviteinfo': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final code = (await call.argument(0)).trim();
      final property = (await call.argument(1)).trim();
      if (code.isEmpty) {
        throw BdfdNativeError('Invite code is required.', call.location);
      }
      if (!const [
        'channel',
        'creationDate',
        'inviter',
        'isTemporary',
        'uses',
      ].contains(property)) {
        throw BdfdNativeError('Unknown invite property.', call.location);
      }
      return call.context.variables['invite[$code].$property'] ?? '';
    },
  ),

  if (moderation != null) ...{
    // Wiki: $changeUsername[New nickname] changes the mentioned user's
    // nickname (the author when nobody is mentioned); the ID form is explicit.
    'changeusername': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final mentions = CommandInput(call.context.variables).userMentions;
        final target = mentions.isNotEmpty
            ? mentions.first
            : call.context.variables['author.id'] ??
                  call.context.variables['user.id'] ??
                  '';
        return _changeNickname(
          call,
          moderation,
          target,
          await call.argument(0),
        );
      },
    ),
    'changeusernamewithid': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 2,
      handler: (call) async => _changeNickname(
        call,
        moderation,
        await call.argument(0),
        await call.argument(1),
      ),
    ),
  },
};

Future<String> _changeNickname(
  BdfdInvocation call,
  BotModerationService moderation,
  String rawTarget,
  String nickname,
) async {
  final target = rawTarget.trim();
  final id = RegExp(r'^[0-9]+$').hasMatch(target) ? int.tryParse(target) : null;
  if (id == null || id <= 0) {
    throw BdfdNativeError('Missing or invalid user ID.', call.location);
  }
  var value = nickname;
  if (value.contains('%username%')) {
    if (moderation is! BotUserQueryService) {
      throw BdfdNativeError('User lookup is not available.', call.location);
    }
    final user = await call.context.budget.run(
      () => (moderation as BotUserQueryService).user(
        '$id',
        budget: call.context.budget,
      ),
    );
    if (user == null) {
      throw BdfdNativeError('User not found: $id.', call.location);
    }
    value = value.replaceAll('%username%', user.username);
  }
  if (value.isEmpty || value.length > 32) {
    throw BdfdNativeError(
      'Nickname must contain 1 to 32 characters.',
      call.location,
    );
  }
  await call.context.budget.run(
    () => moderation.moderate(
      BotModerationRequest(
        operation: BotModerationOperation.setNickname,
        userId: '$id',
        nickname: value,
        useDefaultReason: false,
      ),
      budget: call.context.budget,
    ),
  );
  return '';
}
