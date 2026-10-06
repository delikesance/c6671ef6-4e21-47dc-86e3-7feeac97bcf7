import 'dart:async';

import '../l10n/tr_extension.dart';
import '../utils/external_link.dart';
import '../widgets/app_icon.dart';
import './documentation_article_page.dart';
import './documentation_repository.dart';
import './documentation_urls.dart';
import 'package:flutter/material.dart';

class NativeDocumentationView extends StatefulWidget {
  const NativeDocumentationView({
    super.key,
    required this.section,
    this.repository,
  });
  final DocumentationSection section;
  final DocumentationRepository? repository;

  @override
  State<NativeDocumentationView> createState() =>
      _NativeDocumentationViewState();
}

class _NativeDocumentationViewState extends State<NativeDocumentationView> {
  final _search = TextEditingController();
  late Future<DocumentationResult<List<DocumentationEntry>>> _index;
  String? _category;
  String? _mode;
  DocumentationRepository get _repository =>
      widget.repository ?? DocumentationRepository.instance;

  @override
  void initState() {
    super.initState();
    _index = _repository.index(widget.section);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() => setState(() {
    _index = _repository.index(widget.section, refresh: true);
  });

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _index,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return DocumentationLoadError(
          onRetry: _reload,
          url: Uri.parse(urlForDocumentationSection(widget.section)),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final result = snapshot.data!;
      final categories =
          result.value
              .map((e) => e.category)
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final modes = result.value.map((e) => e.mode).toSet().toList()..sort();
      final query = _search.text.toLowerCase().trim().replaceFirst(
        RegExp(r'^\$'),
        '',
      );
      final terms = query
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty)
          .toList();
      final entries = result.value
          .where(
            (entry) =>
                (_category == null ||
                    !categories.contains(_category) ||
                    entry.category == _category) &&
                (_mode == null ||
                    !modes.contains(_mode) ||
                    entry.mode == _mode) &&
                terms.every(
                  (term) =>
                      '${entry.name} ${entry.id} ${entry.description} ${entry.category} ${entry.mode}'
                          .toLowerCase()
                          .contains(term),
                ),
          )
          .toList();
      if (query.isNotEmpty) {
        int rank(DocumentationEntry entry) {
          final name = entry.name.toLowerCase().replaceFirst(
            RegExp(r'^\$'),
            '',
          );
          return name == query
              ? 0
              : name.startsWith(query)
              ? 1
              : name.contains(query)
              ? 2
              : 3;
        }

        entries.sort((a, b) {
          final comparison = rank(a).compareTo(rank(b));
          return comparison != 0 ? comparison : a.name.compareTo(b.name);
        });
      }
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.tr.docs_search,
                      prefixIcon: const AppIcon.fromMaterial(Icons.search),
                      suffixIcon: _search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).deleteButtonTooltip,
                              icon: const AppIcon.fromMaterial(Icons.close),
                              onPressed: () {
                                _search.clear();
                                setState(() {});
                              },
                            ),
                      isDense: true,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr.docs_reload,
                  onPressed: _reload,
                  icon: const AppIcon.fromMaterial(Icons.refresh),
                ),
              ],
            ),
          ),
          if (categories.isNotEmpty || modes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 48,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (categories.isNotEmpty)
                      Expanded(
                        child: _DocumentationFilter(
                          label: context.tr.docs_category,
                          value: _category,
                          options: categories,
                          onChanged: (value) =>
                              setState(() => _category = value),
                        ),
                      ),
                    if (categories.isNotEmpty && modes.length > 1)
                      const SizedBox(width: 8),
                    if (modes.length > 1)
                      Expanded(
                        child: _DocumentationFilter(
                          label: context.tr.docs_mode,
                          value: _mode,
                          options: modes,
                          onChanged: (value) => setState(() => _mode = value),
                        ),
                      ),
                    if (_category != null || _mode != null)
                      IconButton(
                        tooltip: context.tr.docs_reset_filters,
                        icon: const AppIcon.fromMaterial(Icons.restart_alt),
                        onPressed: () => setState(() {
                          _category = null;
                          _mode = null;
                        }),
                      ),
                  ],
                ),
              ),
            ),
          if (result.offline) const DocumentationOfflineBanner(),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                context.tr.docs_result_count(entries.length),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Center(child: Text(context.tr.docs_no_results))
                : ListView.separated(
                    key: PageStorageKey(widget.section),
                    itemCount: entries.length,
                    separatorBuilder: (_, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        leading: AppIcon.fromMaterial(
                          widget.section == DocumentationSection.guide
                              ? Icons.menu_book_outlined
                              : Icons.code,
                        ),
                        title: Text(entry.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (entry.description.isNotEmpty)
                              Text(
                                entry.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (entry.category.isNotEmpty)
                              Text(
                                entry.category,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                          ],
                        ),
                        trailing: const AppIcon.fromMaterial(
                          Icons.chevron_right,
                        ),
                        onTap: () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DocumentationArticlePage(
                              url: entry.url.toString(),
                              title: entry.name,
                              entry: entry,
                              repository: _repository,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      );
    },
  );
}

class _DocumentationFilter extends StatelessWidget {
  const _DocumentationFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: label,
    initialValue: value ?? '',
    onSelected: (selection) => onChanged(selection.isEmpty ? null : selection),
    itemBuilder: (_) => [
      for (final option in ['', ...options])
        CheckedPopupMenuItem(
          value: option,
          checked: (value ?? '') == option,
          child: Text(option.isEmpty ? context.tr.common_all : option),
        ),
    ],
    child: Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
          const SizedBox(width: 4),
          const AppIcon.fromMaterial(Icons.expand_more, size: 18),
        ],
      ),
    ),
  );
}

class DocumentationOfflineBanner extends StatelessWidget {
  const DocumentationOfflineBanner({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        const AppIcon.fromMaterial(Icons.cloud_off_outlined, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            context.tr.docs_cached_offline,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}

class DocumentationLoadError extends StatelessWidget {
  const DocumentationLoadError({
    super.key,
    required this.onRetry,
    required this.url,
  });
  final VoidCallback onRetry;
  final Uri url;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon.fromMaterial(Icons.cloud_off_outlined, size: 36),
          const SizedBox(height: 12),
          Text(context.tr.docs_webview_error, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              IconButton(
                tooltip: context.tr.docs_reload,
                onPressed: onRetry,
                icon: const AppIcon.fromMaterial(Icons.refresh),
              ),
              IconButton(
                tooltip: context.tr.docs_open_in_browser,
                onPressed: () => unawaited(openExternalUrl(url)),
                icon: const AppIcon.fromMaterial(Icons.open_in_browser),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
