import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdLeaderboardFunctions() => {
  'getleaderboardposition': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 3,
    handler: (call) async =>
        call.context.variables['leaderboard.position'] ?? '1',
  ),
  'getleaderboardvalue': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 3,
    handler: (call) async => call.context.variables['leaderboard.value'] ?? '0',
  ),
  'globaluserleaderboard': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 4,
    handler: (call) async =>
        call.context.variables['leaderboard.globalUser'] ?? '',
  ),
  'serverleaderboard': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 4,
    handler: (call) async => call.context.variables['leaderboard.server'] ?? '',
  ),
  'userleaderboard': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 4,
    handler: (call) async => call.context.variables['leaderboard.user'] ?? '',
  ),
};
