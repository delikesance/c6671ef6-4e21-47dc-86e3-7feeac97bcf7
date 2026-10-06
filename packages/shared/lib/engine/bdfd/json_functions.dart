import '../../services/json_document.dart';
import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdJsonFunctions() {
  final functions = <String, BdfdNativeFunction>{};
  void add(String name, int min, int max, BdfdFunctionHandler handler) {
    functions[name] = BdfdNativeFunction(
      handler: handler,
      minArguments: min,
      maxArguments: max,
    );
  }

  for (final name in ['jsonkey', 'jsonindex']) {
    add(name, 0, 0, (call) => call.context.loopVariable(name) ?? '');
  }
  add('jsonvalue', 0, 100, (call) async {
    final value = call.context.loopVariable('jsonvalue');
    if (value != null) return value;
    return call.context.json.apply(
          JsonOperation.get,
          path: await _path(call),
        ) ??
        '';
  });

  add('jsonparse', 1, 1, (call) async {
    call.context.json = JsonDocument.fromSource(await call.argument(0));
    return '';
  });
  add('json', 0, 100, (call) async {
    if (call.argumentCount == 1) {
      final value = (await call.argument(0)).trim();
      if (value.startsWith('{') || value.startsWith('[')) {
        call.context.json = JsonDocument.fromSource(value);
        return '';
      }
    }
    return call.context.json.apply(
          JsonOperation.get,
          path: await _path(call),
        ) ??
        '';
  });
  for (final entry in <String, JsonOperation>{
    'jsonexists': JsonOperation.exists,
    'jsonarraycount': JsonOperation.arrayCount,
    'jsonarraypop': JsonOperation.arrayPop,
    'jsonarrayshift': JsonOperation.arrayShift,
    'jsonarrayreverse': JsonOperation.arrayReverse,
  }.entries) {
    add(
      entry.key,
      0,
      100,
      (call) async =>
          call.context.json.apply(entry.value, path: await _path(call)) ?? '',
    );
  }
  for (final entry in <String, JsonOperation>{
    'jsonset': JsonOperation.set,
    'jsonsetstring': JsonOperation.set,
    'jsonarrayappend': JsonOperation.arrayAppend,
    'jsonarrayunshift': JsonOperation.arrayUnshift,
    'jsonarrayindex': JsonOperation.arrayIndex,
    'jsonjoinarray': JsonOperation.joinArray,
  }.entries) {
    add(entry.key, 2, 100, (call) async {
      final path = await _path(call, end: call.argumentCount - 1);
      final value = await call.argument(call.argumentCount - 1);
      return call.context.json.apply(
            entry.value,
            path: path,
            value: value,
            forceString: entry.key == 'jsonsetstring',
            separator: value,
          ) ??
          '';
    });
  }
  add(
    'jsonunset',
    0,
    100,
    (call) async =>
        call.context.json.apply(
          call.argumentCount == 0 ? JsonOperation.clear : JsonOperation.unset,
          path: await _path(call),
        ) ??
        '',
  );
  add(
    'jsonclear',
    0,
    0,
    (call) => call.context.json.apply(JsonOperation.clear) ?? '',
  );
  add('jsonstringify', 0, 0, (call) => call.context.json.stringify());
  add(
    'jsonpretty',
    0,
    1,
    (call) async =>
        call.context.json.apply(
          JsonOperation.pretty,
          indent: call.argumentCount == 0
              ? null
              : int.tryParse(await call.argument(0)),
        ) ??
        '',
  );
  for (final entry in <String, JsonOperation>{
    'jsonarray': JsonOperation.initArray,
    'jsonkeys': JsonOperation.keys,
  }.entries) {
    add(entry.key, 0, 100, (call) async {
      final hasSeparator = call.argumentCount >= 2;
      final path = await _path(
        call,
        end: hasSeparator ? call.argumentCount - 1 : call.argumentCount,
      );
      final separator = hasSeparator
          ? await call.argument(call.argumentCount - 1)
          : ',';
      return call.context.json.apply(
            entry.value,
            path: path,
            separator: separator,
          ) ??
          '';
    });
  }
  add('jsonarraysort', 1, 100, (call) async {
    final hasOrder = call.argumentCount >= 2;
    final path = await _path(
      call,
      end: hasOrder ? call.argumentCount - 1 : call.argumentCount,
    );
    final descending =
        hasOrder &&
        (await call.argument(call.argumentCount - 1)).trim().toLowerCase() ==
            'desc';
    return call.context.json.apply(
          JsonOperation.arraySort,
          path: path,
          descending: descending,
        ) ??
        '';
  });
  return functions;
}

Future<List<String>> _path(BdfdInvocation call, {int? end}) async {
  final path = <String>[];
  for (var i = 0; i < (end ?? call.argumentCount); i++) {
    final value = (await call.argument(i)).trim();
    if (value.isNotEmpty) path.add(value);
  }
  return path;
}
