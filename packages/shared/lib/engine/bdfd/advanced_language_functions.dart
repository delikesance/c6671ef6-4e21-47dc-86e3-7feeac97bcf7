import '../../bot/bot_data_store.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdAdvancedLanguageFunctions() => {
  'alternativeparsing': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'args': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async {
      final input = call.context.variables['message.content'] ?? '';
      final parts = input
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) parts.removeAt(0); // skip trigger
      if (call.argumentCount == 0) return parts.join(' ');
      final index = int.tryParse(await call.argument(0)) ?? 1;
      if (index <= 0 || index > parts.length) return '';
      return parts[index - 1];
    },
  ),
  'debug': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'disableinnerspaceremoval': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'disablespecialescaping': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  // Wiki: $enabled[Enabled;Error message] stops the command with the error
  // message when the first argument is a false boolean (yes/no).
  'enabled': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async {
      final value = (await call.argument(0)).trim().toLowerCase();
      if (!const ['yes', 'no', 'true', 'false'].contains(value)) {
        throw BdfdNativeError('Enabled must be yes or no.', call.location);
      }
      if (value == 'no' || value == 'false') {
        call.stop(call.argumentCount > 1 ? await call.argument(1) : '');
      }
      return '';
    },
  ),
  'ignorelinks': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'jumptoaction': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'log': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'logquota': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['log.quota'] ?? '1000',
  ),
  'loopiteration': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['_loop.index'] ?? '1',
  ),
  'optoff': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'removecontains': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async {
      final text = await call.argument(0);
      final sub = await call.argument(1);
      return text.replaceAll(sub, '');
    },
  ),
  'scriptlanguage': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => 'BDFD',
  ),
  'skipactions': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'url': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async {
      if (call.argumentCount == 1) {
        return Uri.encodeQueryComponent(await call.argument(0));
      }
      final mode = (await call.argument(0)).trim().toLowerCase();
      final text = await call.argument(1);
      try {
        if (mode == 'decode') {
          return Uri.decodeQueryComponent(text);
        }
        return Uri.encodeQueryComponent(text);
      } catch (_) {
        return text;
      }
    },
  ),
};

/// `$awaitFunc[name;(userID;channelID)]` registers a pending awaited command
/// for the user (author by default) in the channel (current by default).
Map<String, BdfdNativeFunction> bdfdAwaitFunctions(
  BotDataStore store,
  String botId,
) => {
  'awaitfunc': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 3,
    handler: (call) async {
      final name = (await call.argument(
        0,
      )).trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '_');
      if (name.isEmpty) {
        throw BdfdNativeError(
          'The awaited function name is required.',
          call.location,
        );
      }
      var userId = call.argumentCount > 1
          ? (await call.argument(1)).trim()
          : '';
      var channelId = call.argumentCount > 2
          ? (await call.argument(2)).trim()
          : '';
      if (userId.isEmpty) userId = call.context.variables['author.id'] ?? '';
      if (channelId.isEmpty) {
        channelId = call.context.variables['channel.id'] ?? '';
      }
      if (int.tryParse(userId) == null || int.tryParse(channelId) == null) {
        throw BdfdNativeError('Invalid user or channel ID.', call.location);
      }
      await call.context.budget.run(
        () => store.setScopedVariable(botId, 'user', userId, 'await_$name', {
          'name': name,
          'userId': userId,
          'channelId': channelId,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      return '';
    },
  ),
};
