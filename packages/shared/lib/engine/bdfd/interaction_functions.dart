import 'dart:convert';

import 'program.dart';
import 'runtime.dart';

/// Read-only interaction callbacks. The event adapter supplies the actual
/// Discord interaction type; command text/slash options are never selectors.
Map<String, BdfdNativeFunction> bdfdInteractionFunctions() => {
  ..._selectFunctions(),
  'customid': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) {
      final type = call.context.variables['interaction.type'];
      if (type != '3' && type != '5') {
        throw BdfdNativeError(
          'Custom ID requires a component or modal interaction callback.',
          call.location,
        );
      }
      final id = call.context.variables['interaction.customId'];
      if (id == null || id.isEmpty) {
        throw BdfdNativeError(
          'Interaction custom ID is missing.',
          call.location,
        );
      }
      return id;
    },
  ),
};

Map<String, BdfdNativeFunction> _selectFunctions() {
  final functions = <String, BdfdNativeFunction>{};
  const families = {
    'stringselect': ['value', 'values', 'count', 'stringSelect'],
    'channelselect': [
      'channelid',
      'channelids',
      'channelCount',
      'channelSelect',
    ],
    'userselect': ['userid', 'userids', 'userCount', 'userSelect'],
    'roleselect': ['roleid', 'roleids', 'roleCount', 'roleSelect'],
    'mentionableselect': [
      'userid',
      'userids',
      'userCount',
      'mentionableSelect',
    ],
  };
  for (final entry in families.entries) {
    final family = entry.key, config = entry.value;
    final singular = switch (config[0]) {
      'channelid' => 'channelId',
      'userid' => 'userId',
      'roleid' => 'roleId',
      _ => 'value',
    };
    List<String> values(BdfdInvocation call) {
      if (call.context.variables['interaction.type'] != '3') {
        throw BdfdNativeError(
          'Select values require a component callback.',
          call.location,
        );
      }
      final key = 'interaction.${config[3]}.$singular';
      final encoded = call.context.variables['__collection.$key'];
      if (encoded == null) {
        throw BdfdNativeError(
          'This callback has no ${config[3]} selection.',
          call.location,
        );
      }
      final decoded = jsonDecode(encoded);
      if (decoded is! List || decoded.any((value) => value is! String)) {
        throw BdfdNativeError('Invalid selection data.', call.location);
      }
      return decoded.cast<String>();
    }

    functions['get$family${config[0]}'] = BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final index = int.tryParse(await call.argument(0));
        if (index == null || index < 1) {
          throw BdfdNativeError(
            'Selection index must be a positive integer.',
            call.location,
          );
        }
        final selected = values(call);
        return index <= selected.length ? selected[index - 1] : '';
      },
    );
    functions['get$family${config[1]}'] = BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 2,
      handler: (call) async {
        final separator = await call.argument(0);
        var selected = values(call);
        if (call.argumentCount > 1) {
          final raw = await call.argument(1);
          if (raw.isNotEmpty) {
            final limit = int.tryParse(raw);
            if (limit == null || limit < 1) {
              throw BdfdNativeError(
                'Selection limit must be a positive integer.',
                call.location,
              );
            }
            selected = selected.take(limit).toList();
          }
        }
        return selected.join(separator);
      },
    );
    functions['get$family${config[2].toLowerCase()}'] = BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) => '${values(call).length}',
    );
  }
  return functions;
}
