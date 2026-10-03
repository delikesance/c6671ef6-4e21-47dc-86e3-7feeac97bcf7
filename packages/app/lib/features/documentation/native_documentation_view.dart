import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/features/documentation/documentation_article_page.dart';
import 'package:bot_creator/features/documentation/documentation_repository.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
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
      final query = _search.text
          .toLowerCase()
          .replaceFirst(RegExp(r'^\$'), '')
          .trim();
      final entries = result.value
          .where(
            (entry) =>
                (_category == null ||
                    !categories.contains(_category) ||
                    entry.category == _category) &&
                (_mode == null ||
                    !modes.contains(_mode) ||
                    entry.mode == _mode) &&
                '${entry.name} ${entry.id} ${entry.description} ${entry.category}'
                    .toLowerCase()
                    .contains(query),
          )
          .toList();
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
                      border: const OutlineInputBorder(),
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
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (categories.isNotEmpty)
                    SizedBox(
                      width: 240,
                      child: DropdownButtonFormField<String>(
                        initialValue: categories.contains(_category)
                            ? _category
                            : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr.docs_category,
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(context.tr.common_all),
                          ),
                          for (final category in categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _category = value),
                      ),
                    ),
                  if (modes.length > 1)
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        initialValue: modes.contains(_mode) ? _mode : null,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr.docs_mode,
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: null,
                            child: Text(context.tr.common_all),
                          ),
                          for (final mode in modes)
                            DropdownMenuItem(value: mode, child: Text(mode)),
                        ],
                        onChanged: (value) => setState(() => _mode = value),
                      ),
                    ),
                ],
              ),
            ),
          if (result.offline) const DocumentationOfflineBanner(),
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
