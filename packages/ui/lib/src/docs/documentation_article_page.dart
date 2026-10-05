import 'dart:async';

import '../code/bdfd_syntax_controller.dart';
import '../code/code_editor_settings.dart';
import '../code/code_editor_theme_data.dart';
import '../code/js_syntax_controller.dart';
import '../l10n/tr_extension.dart';
import '../utils/external_link.dart';
import '../widgets/app_icon.dart';
import './documentation_repository.dart';
import './documentation_preview.dart';
import './documentation_hub_page.dart';
import './documentation_urls.dart';
import './native_documentation_view.dart';
import './documentation_web_view_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:markdown/markdown.dart' as md;

class DocumentationArticlePage extends StatefulWidget {
  const DocumentationArticlePage({
    super.key,
    required this.url,
    required this.title,
    this.entry,
    this.repository,
  });
  final String url, title;
  final DocumentationEntry? entry;
  final DocumentationRepository? repository;

  @override
  State<DocumentationArticlePage> createState() =>
      _DocumentationArticlePageState();
}

class _DocumentationArticlePageState extends State<DocumentationArticlePage> {
  late Future<(DocumentationEntry?, DocumentationResult<String>?)> _article;
  DocumentationRepository get _repository =>
      widget.repository ?? DocumentationRepository.instance;
  bool get _native {
    final uri = Uri.parse(widget.url);
    return widget.entry != null ||
        (uri.host == 'bot-creator.fr' &&
            (uri.path.startsWith('/docs/') ||
                RegExp(r'/\d{4}/\d{2}/\d{2}/').hasMatch(uri.path)));
  }

  @override
  void initState() {
    super.initState();
    _article = _load();
  }

  Future<(DocumentationEntry?, DocumentationResult<String>?)> _load({
    bool refresh = false,
  }) async {
    if (!_native) return (null, null);
    return _repository.loadArticle(
      Uri.parse(widget.url),
      entry: widget.entry,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      actions: [
        if (_native)
          IconButton(
            tooltip: context.tr.docs_reload,
            icon: const AppIcon.fromMaterial(Icons.refresh),
            onPressed: () => setState(() {
              _article = _load(refresh: true);
            }),
          ),
        IconButton(
          tooltip: context.tr.docs_open_in_browser,
          icon: const AppIcon.fromMaterial(Icons.open_in_browser),
          onPressed: () => unawaited(openExternalUrl(Uri.parse(widget.url))),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: !_native
          ? DocumentationWebViewHost.builder(widget.url)
          : FutureBuilder(
              future: _article,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return DocumentationLoadError(
                    url: Uri.parse(widget.url),
                    onRetry: () => setState(() {
                      _article = _load(refresh: true);
                    }),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final (entry, result) = snapshot.data!;
                return NativeDocumentationArticle(
                  key: ValueKey('${entry!.id}@${entry.revision}'),
                  entry: entry,
                  content: result!.value,
                  offline: result.offline,
                  initialFragment: Uri.parse(widget.url).fragment,
                  repository: _repository,
                );
              },
            ),
    ),
  );
}

class NativeDocumentationArticle extends StatefulWidget {
  const NativeDocumentationArticle({
    super.key,
    required this.entry,
    required this.content,
    required this.repository,
    this.offline = false,
    this.initialFragment = '',
  });
  final DocumentationEntry entry;
  final String content, initialFragment;
  final DocumentationRepository repository;
  final bool offline;

  @override
  State<NativeDocumentationArticle> createState() =>
      _NativeDocumentationArticleState();
}

class _NativeDocumentationArticleState
    extends State<NativeDocumentationArticle> {
  final List<({String title, String anchor, GlobalKey key})> _headings = [];

  @override
  void initState() {
    super.initState();
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      blockSyntaxes: const [_DocumentationHeadingSyntax()],
    ).parseLines(widget.content.split('\n'));
    final used = <String, int>{};
    void collect(md.Node node) {
      if (node is! md.Element) return;
      if (RegExp(r'^h[1-6]$').hasMatch(node.tag)) {
        final base = node.textContent
            .toLowerCase()
            .replaceAll(RegExp(r'[^\p{L}\p{N}_ -]', unicode: true), '')
            .trim()
            .replaceAll(RegExp(r'\s+'), '-');
        final occurrence = used.update(
          base,
          (count) => count + 1,
          ifAbsent: () => 0,
        );
        _headings.add((
          title: node.textContent,
          anchor:
              node.attributes['id'] ??
              (occurrence == 0 ? base : '$base-$occurrence'),
          key: GlobalKey(),
        ));
      }
      for (final child in node.children ?? <md.Node>[]) {
        collect(child);
      }
    }

    for (final node in nodes) {
      collect(node);
    }
    if (widget.initialFragment.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollTo(widget.initialFragment),
      );
    }
  }

  void _scrollTo(String fragment) {
    for (final heading in _headings) {
      if (heading.anchor == Uri.decodeComponent(fragment) &&
          heading.key.currentContext != null) {
        unawaited(
          Scrollable.ensureVisible(
            heading.key.currentContext!,
            duration: const Duration(milliseconds: 200),
          ),
        );
        return;
      }
    }
  }

  Future<void> _link(String href) async {
    final uri = widget.entry.url.resolve(href);
    if (!['https', 'http'].contains(uri.scheme)) return;
    if (uri.replace(fragment: '').toString() ==
        widget.entry.url.replace(fragment: '').toString()) {
      _scrollTo(uri.fragment);
      return;
    }
    if (uri.host == 'bot-creator.fr') {
      final path = uri.path.replaceFirst(RegExp(r'/$'), '');
      if (['/docs', '/blog', '/guides'].contains(path)) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute(
            builder: (_) => DocumentationHubPage(
              repository: widget.repository,
              initialSection: path == '/docs'
                  ? DocumentationSection.botCreatorDocs
                  : DocumentationSection.guide,
            ),
          ),
        );
        return;
      }
      try {
        final entry = await widget.repository.resolve(uri);
        if (!mounted) return;
        if (entry != null) {
          await Navigator.push<void>(
            context,
            MaterialPageRoute(
              builder: (_) => DocumentationArticlePage(
                url: uri.toString(),
                title: entry.name,
                entry: entry,
                repository: widget.repository,
              ),
            ),
          );
          return;
        }
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr.docs_webview_error)));
        return;
      }
    }
    await openExternalUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final headingBuilder = _HeadingBuilder(
      _headings.map((h) => h.key).toList(),
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.offline) const DocumentationOfflineBanner(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        widget.entry.category,
                        widget.entry.mode,
                        if (widget.entry.status != 'documented')
                          widget.entry.status,
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  if (_headings.isNotEmpty)
                    PopupMenuButton<String>(
                      tooltip: context.tr.docs_contents,
                      icon: const AppIcon.fromMaterial(Icons.list),
                      onSelected: _scrollTo,
                      itemBuilder: (_) => [
                        for (final heading in _headings)
                          PopupMenuItem(
                            value: heading.anchor,
                            child: Text(heading.title),
                          ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SelectionArea(
                child: MarkdownBody(
                  data: widget.content,
                  extensionSet: md.ExtensionSet.gitHubFlavored,
                  blockSyntaxes: const [_DocumentationHeadingSyntax()],
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        codeblockPadding: EdgeInsets.zero,
                        codeblockDecoration: const BoxDecoration(),
                        h1: Theme.of(context).textTheme.headlineSmall,
                        h2: Theme.of(context).textTheme.titleLarge,
                        h3: Theme.of(context).textTheme.titleMedium,
                        p: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                  onTapLink: (_, href, _) {
                    if (href != null) unawaited(_link(href));
                  },
                  imageBuilder: (uri, title, alt) {
                    final resolved = widget.entry.url.resolveUri(uri);
                    if (resolved.scheme != 'https') return Text(alt ?? '');
                    return Image.network(
                      resolved.toString(),
                      semanticLabel: alt,
                      fit: BoxFit.contain,
                      errorBuilder: (_, error, stack) => Text(alt ?? ''),
                    );
                  },
                  builders: {
                    'pre': _DocumentationCodeBuilder(
                      context.tr.copilot_copy_code,
                      onLink: _link,
                    ),
                    for (var level = 1; level <= 6; level++)
                      'h$level': headingBuilder,
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeadingBuilder extends MarkdownElementBuilder {
  _HeadingBuilder(this.keys);
  final List<GlobalKey> keys;
  int next = 0;
  @override
  bool isBlockElement() => true;
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) => Padding(
    key: next < keys.length ? keys[next++] : null,
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(element.textContent, style: preferredStyle),
  );
}

// Preserve the original website anchors exported as Markdown heading IDs.
class _DocumentationHeadingSyntax extends md.HeaderSyntax {
  const _DocumentationHeadingSyntax();
  @override
  md.Node parse(md.BlockParser parser) {
    final element = super.parse(parser) as md.Element;
    final children = element.children!;
    if (children.isNotEmpty && children.first is md.UnparsedContent) {
      final text = children.first.textContent;
      final id = RegExp(r'\s+\{#([^}\s]+)\}$').firstMatch(text);
      if (id != null) {
        element.attributes['id'] = id.group(1)!;
        children[0] = md.UnparsedContent(text.substring(0, id.start));
      }
    }
    return element;
  }
}

class _DocumentationCodeBuilder extends MarkdownElementBuilder {
  _DocumentationCodeBuilder(this.tooltip, {this.onLink});
  final String tooltip;
  final Future<void> Function(String)? onLink;
  @override
  bool isBlockElement() => true;
  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final code = element.textContent;
    final codeElement = element.children?.whereType<md.Element>().firstOrNull;
    final language = (codeElement?.attributes['class'] ?? '')
        .replaceFirst('language-', '')
        .toLowerCase();
    final preview = DocumentationPreview.decode(language, code);
    if (preview != null) {
      return DocumentationPreview(
        kind: language,
        data: preview,
        markdown: (content) => Builder(
          builder: (context) => MarkdownBody(
            data: content,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                .copyWith(
                  codeblockPadding: EdgeInsets.zero,
                  codeblockDecoration: const BoxDecoration(),
                ),
            onTapLink: (_, href, _) {
              if (href != null && onLink != null) unawaited(onLink!(href));
            },
            builders: {
              'pre': _DocumentationCodeBuilder(tooltip, onLink: onLink),
            },
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final palette = CodeEditorThemeColors.forTheme(
      dark ? CodeEditorTheme.githubDark : CodeEditorTheme.githubLight,
    );
    final style = theme.textTheme.bodySmall?.copyWith(
      fontFamily: 'JetBrainsMono',
      height: 1.5,
      color: palette.text,
    );
    final isBdfd =
        [
          'bdfd',
          'bdscript',
          'bdscript2',
          'bds',
          'bdfdscript',
        ].contains(language) ||
        (['', 'text', 'plaintext'].contains(language) &&
            RegExp(r'\$\w+').hasMatch(code));
    Widget highlighted;
    if (isBdfd || ['js', 'javascript'].contains(language)) {
      final controller = isBdfd
          ? BdfdSyntaxController(text: code, themeColors: palette)
          : JsSyntaxController(text: code, themeColors: palette);
      highlighted = Text.rich(
        controller.buildTextSpan(
          context: context,
          style: style,
          withComposing: false,
        ),
      );
      controller.dispose();
    } else if ([
      'json',
      'yaml',
      'dart',
      'typescript',
      'bash',
      'shell',
      'html',
      'css',
      'python',
    ].contains(language)) {
      highlighted = HighlightView(
        code,
        language: language == 'shell' ? 'bash' : language,
        theme: palette.hljsTheme,
        textStyle: style,
      );
    } else {
      highlighted = Text(code, style: style);
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(isBdfd ? 'BDFD' : language, style: style)),
              IconButton(
                tooltip: tooltip,
                icon: const AppIcon.fromMaterial(Icons.copy, size: 18),
                onPressed: () =>
                    Clipboard.setData(ClipboardData(text: element.textContent)),
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: highlighted,
          ),
        ],
      ),
    );
  }
}
