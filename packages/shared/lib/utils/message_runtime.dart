/// Argument fields shared by prefix command execution and the sandbox.
Map<String, String> buildCommandArgumentRuntimeVariables(List<String> args) => {
  'message.content': args.join(' '),
  'message.cleanContent': args.join(' '),
  'message.word.count': args.length.toString(),
  'message.argCount': args.length.toString(),
  'args.count': args.length.toString(),
  'message.args.last': args.isEmpty ? '' : args.last,
  for (var i = 0; i < args.length; i++) ...{
    'message.content[$i]': args[i],
    'args.${i + 1}': args[i],
    '${i + 1}': args[i],
  },
};
