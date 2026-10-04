import '../../services/bot_command_query_service.dart';
import 'program.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdCommandQueryFunctions(
  BotCommandQueryService service,
) {
  BdfdNativeFunction metadata(String key, {String? fallback}) =>
      BdfdNativeFunction(
        minArguments: 0,
        maxArguments: 0,
        handler: (call) async {
          final value =
              call.context.variables[key] ??
              (fallback == null ? null : call.context.variables[fallback]);
          if (value == null) {
            throw BdfdNativeError(
              'Invocation metadata $key is unavailable.',
              call.location,
            );
          }
          return value;
        },
      );
  return {
    'botcommands': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final separator = await call.argument(0);
        if (separator.isEmpty) {
          throw BdfdNativeError('Separator is required.', call.location);
        }
        final rows = await call.context.budget.run(
          () => service.commands(budget: call.context.budget),
        );
        final names = <String>[];
        for (final row in rows) {
          call.context.budget.check();
          names.add(row.name);
        }
        return names.join(separator);
      },
    ),
    'commandscount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          '${(await call.context.budget.run(() => service.commands(budget: call.context.budget))).length}',
    ),
    'commandname': metadata('command.name', fallback: 'commandName'),
    'commandtrigger': metadata('command.trigger'),
    'commandfolder': metadata('command.folder'),
    'slashcommandscount': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          '${(await call.context.budget.run(() => service.globalSlashCommands(budget: call.context.budget))).length}',
    ),
    'slashid': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        if (call.argumentCount == 0) {
          final id = call.context.variables['interaction.command.id'];
          if (id == null || id.isEmpty) {
            throw BdfdNativeError(
              'Executed slash command ID is unavailable.',
              call.location,
            );
          }
          return id;
        }
        final name = await call.argument(0);
        if (name.isEmpty) {
          throw BdfdNativeError(
            'Slash command name is required.',
            call.location,
          );
        }
        final rows = await call.context.budget.run(
          () => service.globalSlashCommands(budget: call.context.budget),
        );
        for (final row in rows) {
          call.context.budget.check();
          if (row.name == name) return row.id;
        }
        throw BdfdNativeError('Global slash command not found.', call.location);
      },
    ),
    'getbotinvite': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => call.context.budget.run(
        () => service.invite(budget: call.context.budget),
      ),
    ),
    'botleave': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        String? id;
        if (call.argumentCount == 1) {
          final raw = (await call.argument(0)).trim();
          final parsed = RegExp(r'^[0-9]+$').hasMatch(raw)
              ? int.tryParse(raw)
              : null;
          if (parsed == null || parsed <= 0) {
            throw BdfdNativeError('Invalid guild ID.', call.location);
          }
          id = '$parsed';
        }
        await call.context.budget.run(
          () => service.leaveGuild(id, budget: call.context.budget),
        );
        return '';
      },
    ),
    'commandtype': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          call.context.variables['commandType'] ??
          call.context.variables['command.type'] ??
          (call.context.variables['interaction.id'] != null ? 'slash' : 'text'),
    ),
  };
}
