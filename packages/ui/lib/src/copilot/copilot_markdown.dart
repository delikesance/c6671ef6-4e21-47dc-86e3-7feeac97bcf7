import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

import '../l10n/tr_extension.dart';
import '../utils/external_link.dart';
import '../widgets/app_icon.dart';

class CopilotMarkdown extends StatelessWidget {
  const CopilotMarkdown({super.key, required this.content});
  final String content;

  /// Ouvre un lien du message : l'app route les pages de sa documentation vers
  /// l'article intégré, le reste part dans le navigateur.
  static Future<bool> Function(BuildContext context, Uri uri) linkOpener =
      (context, uri) => openExternalUrl(uri);

  @override
  Widget build(BuildContext context) => SelectionArea(
    child: MarkdownBody(
      data: content,
      selectable: false,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        blockSpacing: 7,
        listIndent: 18,
        p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.4),
      ),
      onTapLink: (text, href, title) {
        final uri = Uri.tryParse(href ?? '');
        if (uri != null && ['https', 'http'].contains(uri.scheme)) {
          unawaited(CopilotMarkdown.linkOpener(context, uri));
        }
      },
      builders: {'pre': _CodeBuilder(context.tr.copilot_copy_code)},
    ),
  );
}

class _CodeBuilder extends MarkdownElementBuilder {
  _CodeBuilder(this.copyTooltip);
  final String copyTooltip;

  @override
  Widget? visitElementAfter(element, TextStyle? preferredStyle) {
    final code = element.textContent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code,
            style: preferredStyle?.copyWith(fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          tooltip: copyTooltip,
          icon: AppIcon(Reicon.outline.copy, size: 18),
          onPressed: () => Clipboard.setData(ClipboardData(text: code)),
        ),
      ],
    );
  }
}
