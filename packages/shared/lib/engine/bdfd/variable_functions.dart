import '../../services/variable_service.dart';
import 'program.dart';
import 'runtime.dart';

/// Native bindings use the same storage service as visual variable blocks.
Map<String, BdfdNativeFunction> bdfdVariableFunctions(
  VariableService service, {
  bool legacyUserVariables = false,
}) {
  final functions = <String, BdfdNativeFunction>{};
  functions['listvar'] = BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async {
      final separator = call.argumentCount == 0 ? ', ' : await call.argument(0);
      final names = await service.declaredNames(
        checkBudget: call.context.budget.check,
      );
      return names.join(separator);
    },
  );
  functions['variablescount'] = BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async {
      final type = (await call.argument(0)).trim();
      final scope = {
        'user': legacyUserVariables ? 'user' : 'guildMember',
        'globaluser': 'user',
        'server': 'guild',
        'channel': 'channel',
      }[type];
      if (scope == null) {
        throw BdfdNativeError('Unknown variable type.', call.location);
      }
      final names = await service.declaredNames(
        scope: scope,
        checkBudget: call.context.budget.check,
      );
      return names.length.toString();
    },
  );
  functions['varexisterror'] = BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final name = (await call.argument(0)).trim();
      if (name.isEmpty) {
        throw BdfdNativeError('A variable name is required.', call.location);
      }
      final exists = await service.exists(
        name,
        checkBudget: call.context.budget.check,
      );
      call.context.budget.check();
      if (!exists) call.stop(await call.argument(1));
      return '';
    },
  );
  functions['varexists'] = BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async {
      final key = (await call.argument(0)).trim();
      if (key.isEmpty) {
        throw BdfdNativeError('A variable name is required.', call.location);
      }
      final result = await service.exists(
        key,
        checkBudget: call.context.budget.check,
      );
      call.context.budget.check();
      return result.toString();
    },
  );
  for (final entry in {
    'resetuservar': legacyUserVariables ? 'user' : 'guildMember',
    'resetservervar': 'guild',
    'resetguildvar': 'guild',
    'resetchannelvar': 'channel',
    'resetglobaluservar': 'user',
    'resetmembervar': 'guildMember',
    'resetguildmembervar': 'guildMember',
  }.entries) {
    final forUser = [
      'resetuservar',
      'resetglobaluservar',
      'resetmembervar',
      'resetguildmembervar',
    ].contains(entry.key);
    functions[entry.key] = BdfdNativeFunction(
      minArguments: 1,
      // Member-scoped resets also accept an optional guild ID (extension used
      // by migrated scripts): $resetGuildMemberVar[name;userID;guildID].
      maxArguments: switch (entry.key) {
        'resetmembervar' || 'resetguildmembervar' => 3,
        _ => forUser ? 2 : 1,
      },
      handler: (call) async {
        final key = (await call.argument(0)).trim();
        if (key.isEmpty) {
          throw BdfdNativeError('A variable name is required.', call.location);
        }
        String? userId;
        if (call.argumentCount >= 2) {
          userId = (await call.argument(1)).trim();
          final id = BigInt.tryParse(userId);
          if (!RegExp(r'^[0-9]+$').hasMatch(userId) ||
              id == null ||
              id <= BigInt.zero ||
              id > (BigInt.one << 64) - BigInt.one) {
            throw BdfdNativeError(
              'A valid user ID is required.',
              call.location,
            );
          }
        }
        String? guildId;
        if (call.argumentCount == 3) {
          guildId = (await call.argument(2)).trim();
          if (!RegExp(r'^[0-9]+$').hasMatch(guildId)) {
            throw BdfdNativeError(
              'A valid guild ID is required.',
              call.location,
            );
          }
        }
        try {
          await service.resetScoped(
            scope: entry.value,
            key: key,
            userId: userId,
            guildId: guildId,
            checkBudget: call.context.budget.check,
          );
        } on ArgumentError catch (error) {
          throw BdfdNativeError(error.message.toString(), call.location);
        }
        return '';
      },
    );
  }
  for (final kind in [
    'var',
    'uservar',
    'servervar',
    'guildvar',
    'channelvar',
    'membervar',
    'guildmembervar',
    'messagevar',
  ]) {
    final maxIds = ['uservar', 'membervar', 'guildmembervar'].contains(kind)
        ? 2
        : 1;
    for (final write in [false, true]) {
      functions['${write ? 'set' : 'get'}$kind'] = BdfdNativeFunction(
        minArguments: write ? 2 : 1,
        maxArguments: (write ? 2 : 1) + maxIds,
        handler: (call) async {
          final key = (await call.argument(0)).trim();
          final idOffset = write ? 2 : 1;
          Future<String> id(int index, String fallback) async {
            final explicit = call.argumentCount > index
                ? (await call.argument(index)).trim()
                : '';
            return explicit.isEmpty
                ? call.context.variables[fallback] ?? ''
                : explicit;
          }

          final explicitUser = call.argumentCount > idOffset
              ? (await call.argument(idOffset)).trim()
              : '';
          String? scope;
          var contextId = '';
          switch (kind) {
            case 'var':
              if (explicitUser.isNotEmpty) {
                scope = 'user';
                contextId = explicitUser;
              }
            case 'uservar':
            case 'membervar':
            case 'guildmembervar':
              final explicitGuild = call.argumentCount > idOffset + 1
                  ? (await call.argument(idOffset + 1)).trim()
                  : '';
              if (kind == 'uservar' &&
                  legacyUserVariables &&
                  explicitGuild.isEmpty) {
                scope = 'user';
                contextId = await id(idOffset, 'author.id');
              } else {
                scope = 'guildMember';
                final guild = await id(idOffset + 1, 'guild.id');
                final user = await id(idOffset, 'author.id');
                if ([guild, user].any(
                  (id) =>
                      id.isEmpty ||
                      id.toLowerCase() == 'dm' ||
                      id.toLowerCase() == 'unknown user',
                )) {
                  throw BdfdNativeError(
                    'A server and user are required for guildMember variables.',
                    call.location,
                  );
                }
                contextId = '$guild:$user';
              }
            case 'servervar':
            case 'guildvar':
              scope = 'guild';
              contextId = await id(idOffset, 'guild.id');
            case 'channelvar':
              scope = 'channel';
              contextId = await id(idOffset, 'channel.id');
            case 'messagevar':
              scope = 'message';
              contextId = await id(idOffset, 'message.id');
          }
          if (scope != null && contextId.isEmpty) {
            throw BdfdNativeError(
              'Missing context for $scope variables.',
              call.location,
            );
          }
          if (write) {
            final value = await call.argument(1);
            if (scope == null) {
              await service.writeGlobal(key, value);
            } else {
              await service.writeScoped(
                scope: scope,
                contextId: contextId,
                key: key,
                value: value,
              );
            }
            return '';
          }
          if (scope == null) {
            return stringifyVariableValue(await service.readGlobal(key));
          }
          final read = await service.readScoped(
            scope: scope,
            contextId: contextId,
            key: key,
          );
          return stringifyVariableValue(read.value);
        },
      );
    }
  }
  return functions;
}
