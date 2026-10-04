import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdAdvancedLanguageFunctions() => {
  'allowrolementions': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1000,
    handler: (call) async => '',
  ),
  'allowusermentions': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1000,
    handler: (call) async => '',
  ),
  'alternativeparsing': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'blacklistroleids': BdfdNativeFunction(
    minArguments: 2,
    maxArguments: 1 << 30,
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
  'awaitfunc': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async =>
        call.argumentCount > 0 ? await call.argument(0) : '',
  ),
  'clear': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 2,
    handler: (call) async => '',
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
  'enabled': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => 'true',
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
