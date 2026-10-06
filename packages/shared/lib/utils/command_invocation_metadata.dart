/// Metadata for the command selected by an entry-point adapter. The stored
/// command name is distinct from the trigger actually used (including aliases).
Map<String, String> buildCommandInvocationMetadata(
  Map<String, dynamic> command, {
  required String trigger,
}) => {
  'command.id': (command['id'] ?? '').toString(),
  'command.name': (command['name'] ?? '').toString(),
  'commandName': (command['name'] ?? '').toString(),
  'command.trigger': trigger,
  'command.folder': (command['folder'] ?? '').toString(),
};
