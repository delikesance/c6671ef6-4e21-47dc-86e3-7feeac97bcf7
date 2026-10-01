import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:reicon_flutter/reicon_flutter.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// A filter definition for the Notion-like filter bar.
///
/// Each filter has an [id], a display [label], and a list of [options].
/// The currently selected option is tracked externally.
class NotionFilter {
  const NotionFilter({
    required this.id,
    required this.label,
    required this.icon,
    required this.options,
    this.selectedValue = '',
  });

  /// Unique identifier for this filter (e.g. 'type', 'folder').
  final String id;

  /// Display label (e.g. 'Type', 'Folder').
  final String label;

  /// Icon shown on the chip.
  final IconData icon;

  /// Available options. Key = internal value, Value = display label.
  /// The first option is usually "All" / reset.
  final Map<String, String> options;

  /// Currently selected value. Empty string means no filter applied.
  final String selectedValue;

  /// Whether a filter is actively applied (non-empty, non-"all").
  bool get isActive => selectedValue.isNotEmpty;

  NotionFilter copyWith({String? selectedValue}) {
    return NotionFilter(
      id: id,
      label: label,
      icon: icon,
      options: options,
      selectedValue: selectedValue ?? this.selectedValue,
    );
  }
}

/// A toggle filter that's either on or off (like "Template only").
class NotionToggleFilter {
  const NotionToggleFilter({
    required this.id,
    required this.label,
    required this.icon,
    this.enabled = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final bool enabled;

  NotionToggleFilter copyWith({bool? enabled}) {
    return NotionToggleFilter(
      id: id,
      label: label,
      icon: icon,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Notion-like filter bar with unified search + inline filter chips.
///
/// Layout:
/// ```
/// ┌─────────────────────────────────────────────┐
/// │ 🔍  Search...                           ✕   │
/// ├─────────────────────────────────────────────┤
/// │ [Type: Slash ✕] [Folder: Admin ✕]  + Filter │
/// └─────────────────────────────────────────────┘
/// │ ── Create "my-command" ──────────────────── │  (if onCreateFromQuery)
/// ```
class NotionFilterBar extends StatefulWidget {
  const NotionFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.searchHint,
    this.filters = const [],
    this.toggleFilters = const [],
    this.onFilterChanged,
    this.onToggleFilterChanged,
    this.onCreateFromQuery,
    this.createFromQueryLabel,
    this.showCreateSuggestion = false,
    this.addFilterLabel = 'Filter',
    this.trailingAction,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;

  /// Optional action widget placed next to the search field (e.g. "+ Create").
  final Widget? trailingAction;

  /// Dropdown-style filters (Type, Folder, etc.).
  final List<NotionFilter> filters;

  /// Toggle-style filters (Template only, Legacy only).
  final List<NotionToggleFilter> toggleFilters;

  /// Called when a dropdown filter value changes.
  final void Function(String filterId, String value)? onFilterChanged;

  /// Called when a toggle filter changes.
  final void Function(String filterId, bool enabled)? onToggleFilterChanged;

  /// Called when user taps the "Create" suggestion.
  final VoidCallback? onCreateFromQuery;

  /// Label for the create suggestion (e.g. "Create command 'ban'").
  final String? createFromQueryLabel;

  /// Whether to show the quick-create suggestion below the bar.
  final bool showCreateSuggestion;

  /// Label for the "+ Filter" button.
  final String addFilterLabel;

  @override
  State<NotionFilterBar> createState() => _NotionFilterBarState();
}

class _NotionFilterBarState extends State<NotionFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void didUpdateWidget(NotionFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeFilters = widget.filters
        .where((f) => f.isActive)
        .toList(growable: false);
    final activeToggles = widget.toggleFilters
        .where((t) => t.enabled)
        .toList(growable: false);
    final hasActiveFilters =
        activeFilters.isNotEmpty || activeToggles.isNotEmpty;
    final hasAnyFilters =
        widget.filters.isNotEmpty || widget.toggleFilters.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Search field + filter icon button + optional trailing action ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: widget.onSearchChanged,
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 10, right: 8),
                      child: AppIcon.fromMaterial(Icons.search, size: 18),
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    suffixIcon: widget.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const AppIcon.fromMaterial(
                              Icons.clear,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              widget.onSearchChanged('');
                            },
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  ),
                ),
              ),
              if (hasAnyFilters) ...[
                const SizedBox(width: 8),
                _buildFilterIconButton(context, hasActive: hasActiveFilters),
              ],
              if (widget.trailingAction != null) ...[
                const SizedBox(width: 8),
                widget.trailingAction!,
              ],
            ],
          ),

          // ── Active filter chips ──
          if (hasActiveFilters) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Active dropdown filter chips
                for (final filter in activeFilters)
                  _ActiveFilterChip(
                    filter: filter,
                    onRemove: () {
                      widget.onFilterChanged?.call(filter.id, '');
                    },
                    onTap: () => _showFilterOptions(context, filter),
                  ),

                // Active toggle chips
                for (final toggle in activeToggles)
                  InputChip(
                    label: Text(
                      toggle.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: AppIcon.fromMaterial(toggle.icon, size: 16),
                    selected: true,
                    selectedColor: colorScheme.primaryContainer,
                    onDeleted: () {
                      widget.onToggleFilterChanged?.call(toggle.id, false);
                    },
                    deleteIcon: const AppIcon.fromMaterial(
                      Icons.close,
                      size: 14,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
          ],

          // ── Quick-create suggestion ──
          if (widget.showCreateSuggestion &&
              widget.onCreateFromQuery != null &&
              widget.createFromQueryLabel != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: widget.onCreateFromQuery,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  color: colorScheme.primary.withValues(alpha: 0.05),
                ),
                child: Row(
                  children: [
                    AppIcon.fromMaterial(
                      Icons.add_circle_outline,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.createFromQueryLabel!,
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context, NotionFilter filter) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  filter.label,
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const Divider(height: 1),
              ...filter.options.entries.map((entry) {
                final isSelected = entry.key == filter.selectedValue;
                return ListTile(
                  dense: true,
                  title: Text(entry.value),
                  leading: isSelected
                      ? AppIcon.fromMaterial(
                          Icons.check_circle,
                          color: colorScheme.primary,
                          size: 20,
                        )
                      : const AppIcon.fromMaterial(
                          Icons.radio_button_unchecked,
                          size: 20,
                        ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onFilterChanged?.call(filter.id, entry.key);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterIconButton(
    BuildContext context, {
    required bool hasActive,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: widget.addFilterLabel,
      child: Material(
        color: hasActive
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        shape: CircleBorder(
          side: BorderSide(
            color: hasActive
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _showFilterMenu(context),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SvgPicture.string(
                  reiconSvg(Reicon.outline.filter),
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    hasActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    BlendMode.srcIn,
                  ),
                ),
                if (hasActive)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasActive =
        widget.filters.any((f) => f.isActive) ||
        widget.toggleFilters.any((t) => t.enabled);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.addFilterLabel,
                        style: Theme.of(sheetContext).textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (hasActive)
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          for (final f in widget.filters) {
                            if (f.isActive) {
                              widget.onFilterChanged?.call(f.id, '');
                            }
                          }
                          for (final t in widget.toggleFilters) {
                            if (t.enabled) {
                              widget.onToggleFilterChanged?.call(t.id, false);
                            }
                          }
                        },
                        child: Text(sheetContext.tr.action_clear_all),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              for (final filter in widget.filters)
                ListTile(
                  dense: true,
                  leading: AppIcon.fromMaterial(filter.icon, size: 20),
                  title: Text(filter.label),
                  subtitle: Text(
                    filter.isActive
                        ? (filter.options[filter.selectedValue] ??
                              filter.selectedValue)
                        : sheetContext.tr.marketplace_command_preview_options(
                            filter.options.length,
                          ),
                    style: TextStyle(
                      fontSize: 11,
                      color: filter.isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: filter.isActive
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  trailing: const AppIcon.fromMaterial(
                    Icons.chevron_right_rounded,
                    size: 18,
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showFilterOptions(context, filter);
                  },
                ),
              for (final toggle in widget.toggleFilters)
                SwitchListTile(
                  dense: true,
                  secondary: AppIcon.fromMaterial(toggle.icon, size: 20),
                  title: Text(toggle.label),
                  value: toggle.enabled,
                  onChanged: (val) {
                    Navigator.pop(sheetContext);
                    widget.onToggleFilterChanged?.call(toggle.id, val);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

/// An active filter chip showing "Label: Value" with a remove button.
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.filter,
    required this.onRemove,
    required this.onTap,
  });

  final NotionFilter filter;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayValue =
        filter.options[filter.selectedValue] ?? filter.selectedValue;

    return InputChip(
      label: Text(
        '${filter.label}: $displayValue',
        style: const TextStyle(fontSize: 12),
      ),
      avatar: AppIcon.fromMaterial(filter.icon, size: 16),
      selected: true,
      selectedColor: colorScheme.primaryContainer,
      onDeleted: onRemove,
      deleteIcon: const AppIcon.fromMaterial(Icons.close, size: 14),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
