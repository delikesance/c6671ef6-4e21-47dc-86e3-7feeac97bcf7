import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/features/documentation/web_documentation_view.dart';
import 'package:flutter/material.dart';

/// Tabbed documentation hub: Guide, Bot Creator Docs, and discord.js.
class DocumentationHubPage extends StatefulWidget {
  const DocumentationHubPage({
    super.key,
    this.initialSection = DocumentationSection.guide,
    this.showDiscordJsTab = false,
  });

  final DocumentationSection initialSection;
  final bool showDiscordJsTab;

  @override
  State<DocumentationHubPage> createState() => _DocumentationHubPageState();
}

class _DocumentationHubPageState extends State<DocumentationHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<DocumentationSection> _sections;

  @override
  void initState() {
    super.initState();
    _sections = _buildSections();
    final initialIndex = documentationSectionTabIndex(
      widget.initialSection,
      showDiscordJsTab: widget.showDiscordJsTab,
    );
    _tabController = TabController(
      length: _sections.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  List<DocumentationSection> _buildSections() {
    return visibleDocumentationSections(showDiscordJsTab: widget.showDiscordJsTab);
  }

  String _tabLabel(BuildContext context, DocumentationSection section) {
    return switch (section) {
      DocumentationSection.guide => context.tr.docs_tab_guide,
      DocumentationSection.botCreatorDocs => context.tr.docs_tab_bot_creator,
      DocumentationSection.discordJs => context.tr.docs_tab_discordjs,
    };
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.docs_hub_title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: _sections.length > 2,
          tabs: [
            for (final section in _sections)
              Tab(text: _tabLabel(context, section)),
          ],
        ),
      ),
      body: IndexedStack(
        index: _tabController.index,
        children: [
          for (final section in _sections)
            WebDocumentationView(
              initialUrl: urlForDocumentationSection(section),
            ),
        ],
      ),
    );
  }
}
