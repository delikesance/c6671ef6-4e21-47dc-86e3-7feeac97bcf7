import 'package:bot_creator/features/documentation/web_documentation_view.dart';
import 'package:flutter/material.dart';

/// Single documentation article shown in an in-app WebView (or platform fallback).
class DocumentationArticlePage extends StatelessWidget {
  const DocumentationArticlePage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: WebDocumentationView(
        initialUrl: url,
      ),
    );
  }
}
