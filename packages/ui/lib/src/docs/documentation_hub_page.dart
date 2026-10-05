import '../l10n/tr_extension.dart';
import '../widgets/page_layout.dart';
import './documentation_urls.dart';
import './documentation_repository.dart';
import './native_documentation_view.dart';
import './documentation_web_view_host.dart';
import 'package:flutter/material.dart';

/// Tabbed documentation hub: Guide, Bot Creator Docs, and discord.js.
class DocumentationHubPage extends StatefulWidget {
  const DocumentationHubPage({
    super.key,
    this.initialSection = DocumentationSection.guide,
    this.showDiscordJsTab = false,
    this.embedded = false,
    this.repository,
  });

  final DocumentationSection initialSection;
  final bool showDiscordJsTab;
  final DocumentationRepository? repository;

  /// When true, hide the back button (used inside the compact bottom-nav shell).
  final bool embedded;

  @override
  State<DocumentationHubPage> createState() => _DocumentationHubPageState();
}

class _DocumentationHubPageState extends State<DocumentationHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final List<DocumentationSection> _sections;
  final Set<int> _visited = {};

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
    _visited.add(initialIndex);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() => _visited.add(_tabController.index));
  }

  List<DocumentationSection> _buildSections() {
    return visibleDocumentationSections(
      showDiscordJsTab: widget.showDiscordJsTab,
    );
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
        // Règle de retour unique : sur desktop la barre de titre du shell porte
        // déjà la flèche de retour, la page n'en rend aucune.
        automaticallyImplyLeading:
            !widget.embedded && !windowChromeOwnsBackButton(),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: _sections.length > 2,
          tabs: [
            for (final section in _sections)
              Tab(text: _tabLabel(context, section)),
          ],
        ),
      ),
      // Largeur et marges communes à toutes les pages de l'app (contrat
      // AppPageLayout) : le hub n'est plus en plein-cadre.
      body: SafeArea(
        top: false,
        child: PageContent(
          child: IndexedStack(
            index: _tabController.index,
            children: [
              for (var index = 0; index < _sections.length; index++)
                if (!_visited.contains(index))
                  const SizedBox.shrink()
                else if (_sections[index] == DocumentationSection.discordJs)
                  DocumentationWebViewHost.builder(discordJsBaseUrl)
                else
                  NativeDocumentationView(
                    section: _sections[index],
                    repository: widget.repository,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
