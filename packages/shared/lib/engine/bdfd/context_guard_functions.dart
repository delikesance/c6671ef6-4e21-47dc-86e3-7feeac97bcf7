import 'runtime.dart';

/// Guards read the invoking context; they never fetch Discord entities.
Map<String, BdfdNativeFunction> bdfdContextGuardFunctions() {
  final functions = <String, BdfdNativeFunction>{};
  void listGuard(
    String name,
    List<String> contextKeys, {
    required bool whitelist,
    bool trimIds = true,
  }) {
    functions[name] = BdfdNativeFunction(
      minArguments: 2,
      maxArguments: 1 << 30,
      handler: (call) async {
        String? subject;
        for (final key in contextKeys) {
          final value = call.context.variables[key];
          if (value != null) {
            subject = value;
            break;
          }
        }
        final candidate = trimIds ? subject : subject?.toLowerCase();
        var matches = false;
        for (var i = 0; i < call.argumentCount - 1; i++) {
          call.context.budget.check();
          final raw = await call.argument(i);
          final entry = trimIds ? raw.trim() : raw.toLowerCase();
          // Empty slots do not designate a user, channel or server.
          if (candidate != null && candidate.isNotEmpty && entry == candidate) {
            matches = true;
          }
        }
        if (matches != whitelist) {
          call.stop(await call.argument(call.argumentCount - 1));
        }
        return '';
      },
    );
  }

  for (final entry in {
    'onlyforids': const ['author.id', 'user.id'],
    'onlyforusers': const ['author.username', 'user.username'],
    'onlyforchannels': const ['channel.id'],
    'onlyforservers': const ['guild.id'],
    'blacklistids': const ['author.id', 'user.id'],
    'blacklistusers': const ['author.username', 'user.username'],
    'ignorechannels': const ['channel.id'],
    'blacklistservers': const ['guild.id'],
  }.entries) {
    listGuard(
      entry.key,
      entry.value,
      whitelist: entry.key.startsWith('onlyfor'),
      trimIds: !entry.key.endsWith('users'),
    );
  }
  functions['onlyifmessagecontains'] = BdfdNativeFunction(
    minArguments: 3,
    maxArguments: 1 << 30,
    handler: (call) async {
      final message = (await call.argument(0)).toLowerCase();
      var containsAll = true;
      for (var i = 1; i < call.argumentCount - 1; i++) {
        call.context.budget.check();
        final word = (await call.argument(i)).toLowerCase();
        if (!message.contains(word)) containsAll = false;
      }
      if (!containsAll) {
        call.stop(await call.argument(call.argumentCount - 1));
      }
      return '';
    },
  );
  return functions;
}
