import '../../services/bot_permission_query_service.dart';
import '../../services/user_permissions.dart';
import '../../utils/global.dart' show bdfdPermissionFlags;
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdPermissionQueryFunctions(
  BotPermissionQueryService service,
) {
  String discordId(String raw, BdfdInvocation call) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) {
      throw BdfdNativeError('Invalid Discord ID.', call.location);
    }
    return '$parsed';
  }

  Future<List<int>> permissions(
    BdfdInvocation call,
    int start,
    int end, {
    bool emptiable = false,
  }) async {
    final names = <String>[];
    for (var index = start; index < end; index++) {
      call.context.budget.check();
      final name = (await call.argument(index)).trim();
      if (name.isEmpty && emptiable) continue;
      if (name.isEmpty) {
        throw BdfdNativeError('Permission is required.', call.location);
      }
      if (!RegExp(r'^[A-Za-z][A-Za-z0-9_]*$').hasMatch(name)) {
        throw BdfdNativeError('Invalid permission.', call.location);
      }
      names.add(name);
    }
    if (names.isEmpty) return const [];
    final flags = bdfdPermissionFlags(names);
    if (flags == null) {
      throw BdfdNativeError('Invalid permission.', call.location);
    }
    return flags.map((flag) => flag.value).toList();
  }

  Future<String> guard(
    BdfdInvocation call, {
    required bool bot,
    bool channel = false,
  }) async {
    String? channelId;
    if (channel) {
      channelId = (await call.argument(0)).trim();
      // The wiki allows an empty channel without defining its default.
      // Use the invocation channel as a provisional local convention.
      if (channelId.isEmpty) {
        channelId = call.context.variables['channel.id'] ?? '';
      }
      channelId = discordId(channelId, call);
    }
    final required = await permissions(
      call,
      channel ? 1 : 0,
      call.argumentCount - 1,
      emptiable: !channel,
    );
    // Empty requirements have no service read, but still validate syntax above.
    if (required.isEmpty) return '';
    final user = bot
        ? null
        : discordId(
            call.context.variables['author.id'] ??
                call.context.variables['user.id'] ??
                '',
            call,
          );
    final value = await call.context.budget.run(
      () => service.memberPermissions(
        userId: user,
        channelId: channelId,
        budget: call.context.budget,
      ),
    );
    call.context.budget.check();
    if (!value.hasAll(required)) {
      call.stop(await call.argument(call.argumentCount - 1));
    }
    return '';
  }

  return {
    'userperms': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 3,
      handler: (call) async {
        final id = int.tryParse((await call.argument(0)).trim());
        final amount = int.tryParse((await call.argument(1)).trim());
        final separator = await call.argument(2);
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        if (amount == null || amount < -1) {
          throw BdfdNativeError(
            'Return amount must be -1 or nonnegative.',
            call.location,
          );
        }
        final mask = await service.storedMemberPermissions(
          '$id',
          budget: call.context.budget,
        );
        return formatUserPermissions(
          mask,
          amount: amount,
          separator: separator,
        );
      },
    ),
    'checkuserperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = (await call.argument(0)).trim();
        final id = int.tryParse(user);
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        final required = await permissions(call, 1, call.argumentCount);
        final value = await service.memberPermissions(
          userId: '$id',
          budget: call.context.budget,
        );
        return value.hasAll(required).toString();
      },
    ),
    'onlyperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) => guard(call, bot: false),
    ),
    'onlybotperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) => guard(call, bot: true),
    ),
    'onlybotchannelperms': BdfdNativeFunction(
      minArguments: 3,
      maxArguments: 10000,
      handler: (call) => guard(call, bot: true, channel: true),
    ),
    'checkusersperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = (await call.argument(0)).trim();
        final id = int.tryParse(user);
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        final required = await permissions(call, 1, call.argumentCount);
        final value = await service.memberPermissions(
          userId: '$id',
          budget: call.context.budget,
        );
        return value.hasAll(required).toString();
      },
    ),
    'hasperms': BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 10000,
      handler: (call) async {
        final user = (await call.argument(0)).trim();
        final id = int.tryParse(user);
        if (id == null || id <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        final required = await permissions(call, 1, call.argumentCount);
        final value = await service.memberPermissions(
          userId: '$id',
          budget: call.context.budget,
        );
        return value.hasAll(required).toString();
      },
    ),
  };
}
