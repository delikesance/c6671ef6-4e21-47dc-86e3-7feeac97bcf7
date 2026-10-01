/// Invocation mode is independent from the Discord interaction type.
/// Historical flattened JS handlers were exposed to both interactions and
/// messages; nested app commands already carry legacy/local-only flags.
String commandTriggerType(Map<String, dynamic> command) {
  final nested = command['data'];
  final data = nested is Map ? nested : command;
  final declared = (data['triggerType'] ?? command['triggerType'] ?? '')
      .toString()
      .trim()
      .toLowerCase();
  if (const {'prefix', 'slash', 'hybrid', 'none'}.contains(declared)) {
    return declared;
  }
  if ((data['legacyModeEnabled'] ?? command['legacyModeEnabled']) == true) {
    return 'prefix';
  }
  if ((data['legacyLocalOnly'] ?? command['legacyLocalOnly']) == true ||
      data['localOnly'] == true) {
    return 'none';
  }
  if ((data['legacyModeEnabled'] ?? command['legacyModeEnabled']) == false) {
    return 'slash';
  }
  if (command['type'] == 'command') return 'hybrid';
  return 'slash';
}
