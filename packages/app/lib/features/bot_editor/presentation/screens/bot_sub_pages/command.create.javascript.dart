part of 'command.create.dart';

extension _CommandCreateJavascript on _CommandCreatePageState {
  Widget _buildJavascriptEditorTile() {
    return _buildJavascriptEditorPreview();
  }

  Widget _buildJavascriptEditorPreview() {
    final code = _jsScriptController.text;
    final isEmpty = code.trim().isEmpty;
    final preview = isEmpty
        ? context.tr.js_editor_hint
        : code.length > 300
        ? '${code.substring(0, 300)}…'
        : code;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _openJavascriptEditor,
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.codeSurfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppTheme.grey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, size: 14, color: AppTheme.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr.bdfd_editor_tap_hint,
                    style: const TextStyle(fontSize: 11, color: AppTheme.grey),
                  ),
                ),
                if (_isDesktop)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x332196F3),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      context.tr.js_editor_segmented_label,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF90CAF9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFFCFD8DC),
              ),
              maxLines: 12,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openJavascriptEditor() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => JsEditorPage(
          initialCode: _jsScriptController.text,
          title: context.tr.js_editor_title,
          appEmojis: _appEmojis,
        ),
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    _applyStateUpdate(() {
      _jsScriptController.text = result;
      _jsScriptContent = result;
      _hasUnsavedChanges = true;
    });
  }
}
