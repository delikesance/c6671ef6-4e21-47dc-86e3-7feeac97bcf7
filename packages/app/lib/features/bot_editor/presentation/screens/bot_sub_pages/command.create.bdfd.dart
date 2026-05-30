part of 'command.create.dart';

extension _CommandCreateBdfd on _CommandCreatePageState {
  Widget _buildExecutionModeCard({bool includeInlineEditor = true}) {
    final isWorkflowMode = !_isBdfdScriptMode;

    Widget buildModeTile({
      required String value,
      required String title,
      required String subtitle,
      required IconData icon,
    }) {
      return RadioListTile<String>(
        value: value,
        contentPadding: EdgeInsets.zero,
        title: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(title)),
          ],
        ),
        subtitle: Text(subtitle),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.cmd_execution_mode_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr.cmd_execution_mode_desc,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 12),
            RadioGroup<String>(
              groupValue: _executionMode,
              onChanged: (next) {
                if (next == null) return;
                _applyStateUpdate(() {
                  _executionMode = next;
                  _bdfdCompileResult = _bdfdCompiler.compile(
                    _bdfdScriptController.text,
                  );
                });
              },
              child: Column(
                children: [
                  buildModeTile(
                    value: _CommandCreatePageState._executionModeWorkflow,
                    title: context.tr.cmd_execution_mode_workflow,
                    subtitle: context.tr.cmd_execution_mode_workflow_desc,
                    icon: Icons.account_tree_outlined,
                  ),
                  buildModeTile(
                    value: _CommandCreatePageState._executionModeBdfdScript,
                    title: context.tr.cmd_execution_mode_bdfd,
                    subtitle: context.tr.cmd_execution_mode_bdfd_desc,
                    icon: Icons.code_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isWorkflowMode ? AppTheme.grey : AppTheme.warning,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isWorkflowMode ? AppTheme.grey : AppTheme.warning,
                ),
              ),
              child: Text(
                isWorkflowMode
                    ? 'cmd_execution_mode_workflow_note'
                    : 'cmd_execution_mode_bdfd_note',
                style: TextStyle(
                  fontSize: 12,
                  color: isWorkflowMode ? AppTheme.grey : AppTheme.warning,
                ),
              ),
            ),
            if (includeInlineEditor && _isBdfdScriptMode) ...[
              const SizedBox(height: 12),
              _buildBdfdEditorTile(),
              const SizedBox(height: 12),
              _buildBdfdDiagnosticsPanel(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBdfdEditorTile() {
    final code = _bdfdScriptController.text;
    final isEmpty = code.trim().isEmpty;
    final preview =
        isEmpty
            ? context.tr.bdfd_editor_tap_hint
            : code.length > 200
            ? '${code.substring(0, 200)}…'
            : code;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final result = await Navigator.push<String>(
          context,
          MaterialPageRoute<String>(
            builder:
                (_) => BdfdEditorPage(
                  initialCode: _bdfdScriptController.text,
                  title: context.tr.workflow_bdfd_editor_title,
                ),
          ),
        );
        if (result != null && mounted) {
          _bdfdScriptController.text = result;
          _refreshBdfdCompileResult();
        }
      },
      child: Container(
        width: double.infinity,
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
                const Icon(Icons.code, size: 16, color: Colors.white70),
                const SizedBox(width: 8),
                Text(
                  context.tr.cmd_bdfd_script_label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(Icons.open_in_new, size: 14, color: AppTheme.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              preview,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: isEmpty ? AppTheme.grey : AppTheme.grey,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBdfdDiagnosticsPanel() {
    final diagnostics = _bdfdDiagnostics;
    if (diagnostics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.success),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.success),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.cmd_bdfd_diagnostics_title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.tr.cmd_bdfd_diagnostics_clean,
                    style: TextStyle(fontSize: 12, color: AppTheme.success),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _hasBdfdCompileErrors ? AppTheme.error : AppTheme.warning,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: _hasBdfdCompileErrors ? AppTheme.error : AppTheme.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.cmd_bdfd_diagnostics_title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...diagnostics.map((diagnostic) {
            final isError =
                diagnostic.severity == BdfdCompileDiagnosticSeverity.error;
            final icon =
                isError ? Icons.error_outline : Icons.warning_amber_rounded;
            final label =
                isError
                    ? 'cmd_bdfd_diagnostics_error'
                    : 'cmd_bdfd_diagnostics_warning';
            final color = isError ? AppTheme.error : AppTheme.warning;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$label: ${_formatBdfdDiagnostic(diagnostic)}',
                      style: TextStyle(fontSize: 12, color: color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
