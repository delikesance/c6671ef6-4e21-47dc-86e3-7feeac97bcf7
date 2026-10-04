import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdBotQueryFunctions() => {
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
  'bottyping': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'botlistdescription': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async =>
        call.context.variables['bot.listDescription'] ?? '',
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
  'registerguildcommands': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'unregisterguildcommands': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'changeusername': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'changeusernamewithid': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 2,
    handler: (call) async => '',
  ),
  'getinviteinfo': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async {
      final prop = call.argumentCount > 1
          ? (await call.argument(1)).trim().toLowerCase()
          : '';
      if (prop.isEmpty) return call.context.variables['invite.info'] ?? '';
      return call.context.variables['invite.info_$prop'] ?? '';
    },
  ),
  'dm': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
};
