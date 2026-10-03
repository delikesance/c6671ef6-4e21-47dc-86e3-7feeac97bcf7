import 'dart:convert';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

Future<void> showHistoryVersionPreview(
  BuildContext context, {
  required Future<Map<String, dynamic>> Function() load,
}) => showModalBottomSheet<void>(
  context: context,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _VersionPreview(load: load),
);

class _VersionPreview extends StatefulWidget {
  const _VersionPreview({required this.load});
  final Future<Map<String, dynamic>> Function() load;
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
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(content),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
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
