import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

class CopilotActivityStep {
  const CopilotActivityStep({
    required this.label,
    required this.icon,
    this.detail,
    this.running = false,
    this.failed = false,
  });
  final String label, icon;
  final String? detail;
  final bool running, failed;
}

/// Public progress and tool activity; provider-private reasoning is never used.
class CopilotActivity extends StatefulWidget {
  const CopilotActivity({super.key, required this.steps, required this.title});
  final List<CopilotActivityStep> steps;
  final String title;

  @override
  State<CopilotActivity> createState() => _CopilotActivityState();
}

class _CopilotActivityState extends State<CopilotActivity>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    final running = widget.steps.any((step) => step.running);
    final failed = widget.steps.any((step) => step.failed);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            expanded: _expanded,
            child: TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              style: TextButton.styleFrom(
                foregroundColor: colors.onSurfaceVariant,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                alignment: Alignment.centerLeft,
              ),
              child: Row(
                children: [
                  if (running)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else
                    AppIcon(
                      failed
                          ? Reicon.outline.infoCircle
                          : Reicon.outline.search,
                      size: 16,
                      color: failed ? colors.error : colors.onSurfaceVariant,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.steps.length}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 8),
                  AppIcon(
                    _expanded
                        ? Reicon.outline.arrowDown2
                        : Reicon.outline.arrowRight2,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(left: 11),
              child: Column(
                children: [
                  for (final step in widget.steps)
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 6, 4, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppIcon(
                            step.failed ? Reicon.outline.infoCircle : step.icon,
                            size: 16,
                            color: step.failed
                                ? colors.error
                                : colors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  step.label,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: step.failed
                                            ? colors.error
                                            : colors.onSurfaceVariant,
                                      ),
                                ),
                                if (step.detail?.isNotEmpty == true) ...[
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    step.detail!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: colors.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (step.running)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
