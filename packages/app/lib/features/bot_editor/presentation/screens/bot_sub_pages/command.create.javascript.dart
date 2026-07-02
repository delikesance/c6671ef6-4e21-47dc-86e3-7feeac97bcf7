part of 'command.create.dart';

extension _CommandCreateJavascript on _CommandCreatePageState {
  Widget _buildJavascriptEditorTile() {
    return TextField(
      controller: _jsScriptController,
      maxLines: 14,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      decoration: InputDecoration(
        labelText: context.tr.cmd_execution_mode_javascript,
        hintText: 'await interaction.reply("Pong!");',
        alignLabelWithHint: true,
        border: const OutlineInputBorder(),
      ),
      onChanged: (_) {
        _jsScriptContent = _jsScriptController.text;
        _hasUnsavedChanges = true;
      },
    );
  }
}
