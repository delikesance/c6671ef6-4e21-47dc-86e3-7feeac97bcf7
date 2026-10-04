import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Section repliable du panneau latéral desktop (« Crédits IA », « Capacités »).
/// Plate : un filet inférieur, pas de fond.
class CopilotSection extends StatefulWidget {
  const CopilotSection({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
  });
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  State<CopilotSection> createState() => _CopilotSectionState();
}

class _CopilotSectionState extends State<CopilotSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.homeCardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.title.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .8,
                              ),
                        ),
                      ),
                      AppIcon.fromMaterial(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}
