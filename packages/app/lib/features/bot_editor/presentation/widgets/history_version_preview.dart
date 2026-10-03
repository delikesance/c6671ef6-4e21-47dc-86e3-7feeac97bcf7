import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

Future<void> showHistoryVersionPreview(
  BuildContext context, {
  required Future<Map<String, dynamic>> Function() load,
  bool singleCommand = false,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _VersionPreview(load: load, singleCommand: singleCommand),
);

class _VersionPreview extends StatefulWidget {
  const _VersionPreview({required this.load, required this.singleCommand});
  final Future<Map<String, dynamic>> Function() load;
  final bool singleCommand;
  @override
  State<_VersionPreview> createState() => _VersionPreviewState();
}

class _VersionPreviewState extends State<_VersionPreview> {
  late Future<Map<String, dynamic>> _content;
  @override
  void initState() {
    super.initState();
    _content = widget.load();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.history_preview,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: context.tr.common_close,
                  onPressed: () => Navigator.pop(context),
                  icon: const AppIcon.fromMaterial(Icons.close_rounded),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _content,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr.history_action_failed,
                            textAlign: TextAlign.center,
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _content = widget.load()),
                            child: Text(context.tr.common_retry),
                          ),
                        ],
                      ),
                    );
                  }
                  final content = snapshot.data!;
                  final commands = widget.singleCommand
                      ? [_entityName(content)]
                      : _entityNames(content['commands']);
                  final workflows = _entityNames(content['workflows']);
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _section(context, context.tr.commands_title, commands),
                      if (!widget.singleCommand) ...[
                        const SizedBox(height: 24),
                        _section(
                          context,
                          context.tr.workflows_title,
                          workflows,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

String _entityName(Map<dynamic, dynamic> entity, [String? key]) {
  for (final value in [entity['name'], entity['id'], key]) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
  }
  return '—';
}

List<String> _entityNames(dynamic entities) {
  if (entities is List) {
    return entities.whereType<Map>().map(_entityName).toList();
  }
  if (entities is Map) {
    return [
      for (final entry in entities.entries)
        if (entry.value is Map)
          _entityName(entry.value as Map, entry.key.toString()),
    ];
  }
  return [];
}

Widget _section(BuildContext context, String title, List<String> names) {
  final theme = Theme.of(context);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$title (${names.length})', style: theme.textTheme.titleSmall),
      if (names.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card(
          margin: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < names.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(names[index], style: theme.textTheme.bodyMedium),
                ),
              ],
            ],
          ),
        ),
      ],
    ],
  );
}
