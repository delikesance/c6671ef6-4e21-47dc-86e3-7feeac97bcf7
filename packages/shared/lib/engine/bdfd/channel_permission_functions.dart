import '../../services/bot_channel_permission_service.dart';
import '../../utils/permission_flags.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdChannelPermissionFunctions(
  BotChannelPermissionService service,
) {
  Future<String> edit(BdfdInvocation call, {required bool deprecated}) async {
    final channel = (await call.argument(0)).trim();
    final target = (await call.argument(deprecated ? 2 : 1)).trim();
    final tokens = <String>[];
    if (deprecated) {
      tokens.addAll((await call.argument(1)).trim().split(RegExp(r'[\s,;]+')));
    } else {
      for (var i = 2; i < call.argumentCount; i++) {
        tokens.add((await call.argument(i)).trim());
      }
    }
    var allow = 0;
    var deny = 0;
    var neutral = 0;
    for (final token in tokens) {
      if (token.length < 2 ||
          !const ['+', '-'].contains(token[0]) &&
              !(deprecated && token[0] == '/')) {
        throw BdfdNativeError(
          'Permission requires an explicit +, - or supported / prefix.',
          call.location,
        );
      }
      final name = token.substring(1);
      if (!RegExp(r'^[a-zA-Z][a-zA-Z0-9_]*$').hasMatch(name)) {
        throw BdfdNativeError('Invalid permission.', call.location);
      }
      final key = normalizeBdfdPermissionToken(name);
      final flag = discordPermissionFlags
          .where((f) => f.key == key)
          .firstOrNull;
      if (flag == null) {
        throw BdfdNativeError('Unknown permission: $name.', call.location);
      }
      final bit = flag.bitValue;
      allow &= ~bit;
      deny &= ~bit;
      neutral &= ~bit;
      switch (token[0]) {
        case '+':
          allow |= bit;
        case '-':
          deny |= bit;
        case '/':
          neutral |= bit;
      }
    }
    if (deprecated && target.isEmpty) {
      throw BdfdNativeError('Permission target is required.', call.location);
    }
    final request = ChannelPermissionChange(
      channelId: channel,
      targetId: target.isEmpty ? null : target,
      // The wiki allows an empty target without describing its default.
      // Everyone is a provisional local convention, not verified BDFD parity.
      targetType: target.isEmpty ? 'everyone' : 'auto',
      allow: allow,
      deny: deny,
      neutral: neutral,
    );
    request.validate();
    await service.editPermissions(request, budget: call.context.budget);
    return '';
  }

  return {
    'editchannelperms': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 10000,
      handler: (call) => edit(call, deprecated: false),
    ),
    'modifychannelperms': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) => edit(call, deprecated: true),
    ),
  };
}
