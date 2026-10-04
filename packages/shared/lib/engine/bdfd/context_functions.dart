import '../../services/command_input.dart';
import 'program.dart';
import 'runtime.dart';

/// Values supplied by the entry-point adapter are read when the function runs.
/// Returned text remains data, including brackets and dollar signs.
Map<String, BdfdNativeFunction> bdfdContextFunctions() {
  const keys = <String, List<String>>{
    'authorid': ['author.id', 'user.id'],
    'userid': ['user.id', 'author.id'],
    'botid': ['bot.id'],
    'guildid': ['guild.id'],
    'serverid': ['guild.id'],
    'messageid': ['message.id'],
    'username': ['user.username', 'author.username'],
    'authorusername': ['author.username', 'user.username'],
    'servername': ['guild.name'],
    'guildname': ['guild.name'],
    'isbot': ['author.isBot', 'user.isBot'],
  };
  final functions = <String, BdfdNativeFunction>{
    for (final entry in keys.entries)
      entry.key: BdfdNativeFunction(
        minArguments: 0,
        maxArguments: 0,
        handler: (call) {
          for (final key in entry.value) {
            final value = call.context.variables[key];
            if (value != null) return value;
          }
          return '';
        },
      ),
    'error': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => call.context.results['error.message'] ?? '',
    ),
  };
  void add(String name, int min, int max, BdfdFunctionHandler handler) {
    functions[name] = BdfdNativeFunction(
      minArguments: min,
      maxArguments: max,
      handler: handler,
    );
  }

  add(
    'channelid',
    0,
    0,
    (call) => bdfdCurrentChannelId(call.context.variables),
  );
  add(
    'isslash',
    0,
    0,
    (call) => '${CommandInput(call.context.variables).isSlash}',
  );
  add('input', 1, 1, (call) async {
    final id = await call.argument(0);
    if (id.isEmpty) {
      throw BdfdNativeError('A modal input ID is required.', call.location);
    }
    final value = call.context.variables['modal.$id'];
    if (value == null) {
      throw BdfdNativeError('Modal input is unavailable: $id.', call.location);
    }
    return value;
  });

  add('message', 0, 2, (call) async {
    final first = call.argumentCount > 0
        ? (await call.argument(0)).trim()
        : null;
    final second = call.argumentCount > 1
        ? (await call.argument(1)).trim()
        : null;
    return CommandInput(call.context.variables).message(first, second: second);
  });
  add(
    'argcount',
    0,
    0,
    (call) => '${CommandInput(call.context.variables).count}',
  );
  for (final entry in {
    'mentioned': 'message.mentions',
    'mentionedchannels': 'message.channelMentions',
    'mentionedroles': 'message.roleMentions',
  }.entries) {
    add(entry.key, 1, entry.key == 'mentionedroles' ? 1 : 2, (call) async {
      final input = CommandInput(call.context.variables);
      if (input.isSlash) {
        throw BdfdNativeError(
          'Use message options for slash commands.',
          call.location,
        );
      }
      final selector = (await call.argument(0)).trim();
      var fallback = entry.key == 'mentioned';
      if (call.argumentCount > 1) {
        final value = (await call.argument(1)).trim().toLowerCase();
        if (!const ['yes', 'no', 'true', 'false'].contains(value)) {
          throw BdfdNativeError(
            'Mention fallback must be yes or no.',
            call.location,
          );
        }
        fallback = value == 'yes' || value == 'true';
      }
      final mentions = _mentions(call.context.variables, entry.value);
      final index = switch (selector) {
        '<' => 1,
        '>' => mentions.length,
        final value => int.tryParse(value),
      };
      if (index == null || index < 1 && selector != '>') {
        throw BdfdNativeError(
          'Mention index must be positive, < or >.',
          call.location,
        );
      }
      final value = index > 0 && index <= mentions.length
          ? mentions[index - 1]
          : '';
      if (value.isNotEmpty || !fallback) return value;
      return call.context.variables[entry.key == 'mentionedchannels'
              ? 'channel.id'
              : 'author.id'] ??
          call.context.variables['user.id'] ??
          '';
    });
  }
  add(
    'ismentioned',
    1,
    1,
    (call) async =>
        '${_mentions(call.context.variables, 'message.mentions').contains(await call.argument(0))}',
  );
  add('argscheck', 2, 3, (call) async {
    var expression = (await call.argument(0)).trim();
    if (call.argumentCount == 3) {
      expression += (await call.argument(1)).trim();
    }
    final match = RegExp(r'^(>=|<=|>|<|=)?(\d+)$').firstMatch(expression);
    if (match == null) {
      throw BdfdNativeError('Invalid argument count condition.', call.location);
    }
    final amount = int.parse(match[2]!);
    final count = CommandInput(call.context.variables).count;
    final valid = switch (match[1]) {
      '>' || '>=' => count >= amount,
      '<' => count < amount,
      '<=' => count <= amount,
      _ => count == amount,
    };
    if (!valid) call.stop(await call.argument(call.argumentCount - 1));
    return '';
  });
  return functions;
}

List<String> _mentions(Map<String, String> variables, String key) {
  final encoded = variables[key];
  if (encoded != null) {
    return encoded.split(',').where((id) => id.isNotEmpty).toList();
  }
  final values = <String>[];
  for (var i = 0; i < variables.length; i++) {
    final value = variables['$key[$i]'];
    if (value == null) break;
    values.add(value);
  }
  return values;
}

/// Entry points identify DMs through channel type and/or an explicitly empty guild.
/// Sparse contexts retain the supplied channel ID when guild metadata is absent.
String bdfdCurrentChannelId(Map<String, String> variables) {
  final type = variables['channel.type'];
  final guild = variables['guild.id'];
  if (type == 'dm' ||
      type == 'group_dm' ||
      variables.containsKey('guild.id') &&
          (guild == null || guild.isEmpty || guild == 'none')) {
    return 'none';
  }
  return variables['channel.id'] ?? '';
}
