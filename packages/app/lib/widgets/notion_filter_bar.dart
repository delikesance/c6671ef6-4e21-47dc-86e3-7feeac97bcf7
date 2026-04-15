import 'package:bot_creator/utils/app_theme.dart';
import 'package:flutter/material.dart';

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
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;

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
    final activeFilters =
        widget.filters.where((f) => f.isActive).toList(growable: false);
    final activeToggles =
        widget.toggleFilters.where((t) => t.enabled).toList(growable: false);
    final hasActiveFilters =
        activeFilters.isNotEmpty || activeToggles.isNotEmpty;
    final inactiveFilters =
        widget.filters.where((f) => !f.isActive).toList(growable: false);
    final inactiveToggles =
        widget.toggleFilters.where((t) => !t.enabled).toList(growable: false);
    final hasInactiveFilters =
        inactiveFilters.isNotEmpty || inactiveToggles.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Search field ──
          TextField(
            controller: _searchController,
            onChanged: widget.onSearchChanged,
            decoration: InputDecoration(
              hintText: widget.searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              suffixIcon:
                  widget.searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                        visualDensity: VisualDensity.compact,
                      )
                      : null,
            ),
          ),

          // ── Active filter chips + add filter button ──
          if (hasActiveFilters || hasInactiveFilters) ...[
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
                    onTap: () => _showFilterOptions(
                      context,
                      filter,
                    ),
                  ),

                // Active toggle chips
                for (final toggle in activeToggles)
                  InputChip(
                    label: Text(
                      toggle.label,
                      style: const TextStyle(fontSize: 12),
                    ),
                    avatar: Icon(toggle.icon, size: 16),
                    selected: true,
                    selectedColor: colorScheme.primaryContainer,
                    onDeleted: () {
                      widget.onToggleFilterChanged?.call(toggle.id, false);
                    },
                    deleteIcon: const Icon(Icons.close, size: 14),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),

                // "+ Filter" button
                if (hasInactiveFilters)
                  ActionChip(
                    label: Text(
                      '+ ${widget.addFilterLabel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    onPressed: () => _showAddFilterMenu(
                      context,
                      inactiveFilters,
                      inactiveToggles,
                    ),
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
                    Icon(
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
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              ...filter.options.entries.map((entry) {
                final isSelected = entry.key == filter.selectedValue;
                return ListTile(
                  dense: true,
                  title: Text(entry.value),
                  leading:
                      isSelected
                          ? Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                            size: 20,
                          )
                          : const Icon(
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

  void _showAddFilterMenu(
    BuildContext context,
    List<NotionFilter> availableFilters,
    List<NotionToggleFilter> availableToggles,
  ) {
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
                  widget.addFilterLabel,
                  style: Theme.of(sheetContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Divider(height: 1),
              for (final filter in availableFilters)
                ListTile(
                  dense: true,
                  leading: Icon(filter.icon, size: 20),
                  title: Text(filter.label),
                  subtitle: Text(
                    '${filter.options.length} options',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showFilterOptions(context, filter);
                  },
                ),
              for (final toggle in availableToggles)
                ListTile(
                  dense: true,
                  leading: Icon(toggle.icon, size: 20),
                  title: Text(toggle.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    widget.onToggleFilterChanged?.call(toggle.id, true);
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
      avatar: Icon(filter.icon, size: 16),
      selected: true,
      selectedColor: colorScheme.primaryContainer,
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 14),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
