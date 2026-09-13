import 'dart:async';
import 'dart:developer' as developer;

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/discord/portal_intent_feedback.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_dashboard.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/commands.list.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/emojis.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/global.variables.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/guilds.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/home.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/inbound_webhooks.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/scheduler.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/settings.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/editor_sidebar.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repasse un libellé i18n en casse normale (« MODULES » → « Modules »).
///
/// `bot_home_section_modules` est un titre de SECTION : sa valeur localisée est
/// écrite en capitales et convient aux en-têtes de la sidebar, mais pas aux
/// items de la nav du bas, qui doivent rester homogènes avec « Accueil »,
/// « Cmd » et « Paramètres ». Aucune chaîne n'est codée en dur : le texte reste
/// celui de l'i18n, seule la casse est ajustée.
String _sentenceCased(String localizedLabel) {
  final lowered = localizedLabel.toLowerCase();
  final runes = lowered.runes;
  if (runes.isEmpty) {
    return lowered;
  }
  final first = String.fromCharCode(runes.first);
  return first.toUpperCase() + lowered.substring(first.length);
}

class AppEditPage extends StatefulWidget {
  final String appName;
  final int id;

  /// Icône (avatar Discord) du bot, relayée à la sidebar pour l'en-tête du
  /// rail replié. `null` → l'éditeur retombe sur l'avatar de l'enregistrement
  /// local du bot (lecture déjà faite à l'initialisation, aucun réseau).
  final String? avatarUrl;

  final bool embedded;
  final VoidCallback? onExit;

  const AppEditPage({
    super.key,
    required this.appName,
    required this.id,
    this.avatarUrl,
    this.embedded = false,
    this.onExit,
  });

  @override
  State<AppEditPage> createState() => _AppEditPageState();
}

class _AppEditPageState extends State<AppEditPage>
    with TickerProviderStateMixin {
  NyxxRest? client;
  bool _isLoading = true;
  String? _degradedReason;

  String _activeSectionId = 'home';
  String _activeModuleId = 'workflows';
  String _activeSettingsSubTab = 'settings';

  bool _beginnerMode = false;
  bool _beginnerModeLoaded = false;
  bool _sidebarCollapsed = false;
  bool _sidebarCollapsedLoaded = false;
  String _runtimeEngine = runtimeEngineDart;

  /// Icône du bot pour l'en-tête du rail : URL fournie par l'appelant, sinon
  /// celle de l'enregistrement local ; `null` → pastille-lettre historique.
  String? _avatarUrl;

  /// Identifiants des pages déjà montées. Permet à [IndexedStack] de charger
  /// les pages paresseusement (lazy) au premier affichage, puis de conserver
  /// leur état pour des transitions d'onglets instantanées (0 ms).
  final Set<String> _loadedPageIds = <String>{};

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    // `_init()` can be re-run from `_OfflineTokenPage` (onTokenSaved), so the
    // REST client and its underlying HttpClient must be released instead of
    // leaked.
    final activeClient = client;
    if (activeClient != null) {
      unawaited(
        activeClient.close().catchError((Object error) {
          developer.log(
            'Failed to close REST client: $error',
            name: 'AppEditPage',
          );
        }),
      );
    }
    super.dispose();
  }

  Future<void> _init() async {
    final previousClient = client;
    if (mounted) {
      setState(() {
        _isLoading = true;
        client = null;
        _degradedReason = null;
        _loadedPageIds.clear();
      });
    }
    if (previousClient != null) {
      try {
        await previousClient.close();
      } catch (e) {
        developer.log(
          'Failed to close previous REST client: $e',
          name: 'AppEditPage',
        );
      }
    }
    await AppAnalytics.logScreenView(
      screenName: "AppEditPage",
      screenClass: "AppEditPage",
      parameters: {"app_name": widget.appName, "app_id": widget.id.toString()},
    );

    // Préférence « sidebar repliée » : chargée avant le premier rendu qui peut
    // afficher la sidebar, pour ne jamais montrer le mauvais état une frame.
    await _loadSidebarCollapsed();
    try {
      final app = await appManager.getApp(widget.id.toString());
      // En-tête du rail : l'URL de l'appelant prime, sinon celle de
      // l'enregistrement local — même lecture qu'au-dessus, donc aucune
      // requête supplémentaire (couvre l'ouverture sans avatar, ex. shell
      // desktop qui ne transmet que l'id et le nom).
      final providedAvatar = widget.avatarUrl?.trim() ?? '';
      _avatarUrl = providedAvatar.isNotEmpty
          ? providedAvatar
          : (app['avatar'] ?? '').toString().trim();
      final runtimeEngine = await getBotRuntimeEngine(widget.id.toString());
      final token = (app["token"] ?? '').toString().replaceAll(
        RegExp(r'[\s\u200B-\u200D\uFEFF]'),
        '',
      );

      if (mounted) {
        setState(() {
          _runtimeEngine = runtimeEngine;
        });
      }

      if (token.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _degradedReason = 'Token missing. Local edit mode enabled.';
          _activeSectionId = 'offline_token';
          _isLoading = false;
        });
        return;
      }

      try {
        client = await Nyxx.connectRest(token);
      } catch (e, stack) {
        client = null;
        _degradedReason = 'Discord connection failed: $e';
        developer.log(
          'Failed to connect to Discord REST',
          error: e,
          stackTrace: stack,
          name: 'AppEditPage',
        );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        if (client == null) {
          _degradedReason ??=
              'Token invalid or network unavailable. Local edit mode enabled.';
          _activeSectionId = 'offline_token';
        } else {
          _activeSectionId = 'home';
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _degradedReason = 'Unable to load bot data. Local edit mode enabled.';
        _activeSectionId = 'offline_token';
        _isLoading = false;
      });
    }

    // Load beginner mode preference
    await _loadBeginnerMode();
  }

  String get _beginnerModeKey => 'beginner_mode_${widget.id}';

  Future<void> _loadBeginnerMode() async {
    final prefs = await SharedPreferences.getInstance();
    final optedOut = prefs.getBool(_beginnerModeKey) == false;

    if (optedOut) {
      if (mounted) {
        setState(() {
          _beginnerMode = false;
          _beginnerModeLoaded = true;
        });
      }
      return;
    }

    try {
      final commands = await appManager.listAppCommands(_botId);
      if (!mounted) return;
      setState(() {
        _beginnerMode = commands.isEmpty;
        _beginnerModeLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _beginnerMode = false;
        _beginnerModeLoaded = true;
      });
    }
  }

  Future<void> _toggleBeginnerMode(bool value) async {
    setState(() {
      _beginnerMode = value;
      _activeSectionId = client == null ? 'offline_token' : 'home';
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_beginnerModeKey, value);
    AppAnalytics.logEvent(
      name: 'beginner_mode_toggled',
      parameters: {'enabled': value.toString(), 'bot_id': _botId},
    );
  }

  static const String _sidebarCollapsedKey = 'editor_sidebar_collapsed';

  Future<void> _loadSidebarCollapsed() async {
    var collapsed = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      collapsed = prefs.getBool(_sidebarCollapsedKey) ?? false;
    } catch (e) {
      developer.log('Failed to load sidebar state: $e', name: 'AppEditPage');
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _sidebarCollapsed = collapsed;
      _sidebarCollapsedLoaded = true;
    });
  }

  Future<void> _toggleSidebarCollapsed() async {
    final value = !_sidebarCollapsed;
    setState(() {
      _sidebarCollapsed = value;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sidebarCollapsedKey, value);
    AppAnalytics.logEvent(
      name: 'sidebar_collapsed_toggled',
      parameters: {'collapsed': value.toString(), 'bot_id': _botId},
    );
  }

  void _exitEditor({bool closeDrawerFirst = false}) {
    if (closeDrawerFirst) {
      Navigator.of(context).pop();
    }
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit();
      return;
    }
    Navigator.of(context).pop();
  }

  String get _botId => widget.id.toString();

  BotRuntimeCapabilities get _capabilities =>
      capabilitiesForEngine(_runtimeEngine);

  Future<void> _onRuntimeEngineChanged() async {
    final engine = await getBotRuntimeEngine(_botId);
    if (!mounted) {
      return;
    }
    setState(() {
      _runtimeEngine = engine;
      _activeSectionId = client == null ? 'offline_token' : 'home';
      _loadedPageIds.clear();
    });
  }

  List<_AppPageEntry> _applyRuntimeGating(List<_AppPageEntry> entries) {
    return entries
        .where((entry) => entry.isAvailable(_capabilities))
        .toList(growable: false);
  }

  List<_AppPageEntry> _buildEntries() {
    final eventsOnlyWorkflows =
        _capabilities.supportsEventListeners &&
        !_capabilities.supportsWorkflows;

    if (client == null) {
      return _applyRuntimeGating([
        _AppPageEntry(
          id: 'offline_token',
          icon: Icons.vpn_key_outlined,
          label: context.tr.settings_tab,
          compactLabel: context.tr.settings_tab,
          category: 'overview',
          beginnerEssential: true,
          page: _OfflineTokenPage(botId: _botId, onTokenSaved: _init),
        ),
        _AppPageEntry(
          id: 'commands',
          icon: Icons.terminal_rounded,
          label: context.tr.commands_tab,
          compactLabel: context.tr.commands_tab_short,
          category: 'commands',
          beginnerEssential: true,
          page: AppCommandsPage(botId: _botId),
        ),
        _AppPageEntry(
          id: 'globals',
          icon: Icons.data_object_rounded,
          label: context.tr.globals_tab,
          compactLabel: context.tr.globals_tab_short,
          category: 'modules',
          page: GlobalVariablesPage(botId: _botId),
        ),
        _AppPageEntry(
          id: 'workflows',
          icon: Icons.account_tree_outlined,
          label: eventsOnlyWorkflows
              ? context.tr.workflows_type_event
              : context.tr.workflows_tab,
          compactLabel: eventsOnlyWorkflows
              ? context.tr.workflows_type_badge_event
              : context.tr.workflows_tab_short,
          category: 'modules',
          page: WorkflowsPage(botId: _botId, eventsOnly: eventsOnlyWorkflows),
          isAvailable: (caps) =>
              caps.supportsWorkflows || caps.supportsEventListeners,
        ),
        _AppPageEntry(
          id: 'scheduler',
          icon: Icons.schedule_rounded,
          label: context.tr.scheduler_tab,
          compactLabel: context.tr.scheduler_tab_short,
          category: 'modules',
          page: SchedulerPage(botId: _botId),
          isAvailable: (caps) => caps.supportsSchedulerUi,
        ),
        _AppPageEntry(
          id: 'webhooks',
          icon: Icons.webhook_rounded,
          label: context.tr.webhooks_page_title,
          compactLabel: context.tr.webhooks_page_title,
          category: 'modules',
          page: InboundWebhooksPage(botId: _botId),
          isAvailable: (caps) => caps.supportsInboundWebhooksUi,
        ),
      ]);
    }

    return _applyRuntimeGating([
      _AppPageEntry(
        id: 'home',
        icon: Icons.dashboard_rounded,
        label: context.tr.home_tab,
        compactLabel: context.tr.home_tab,
        category: 'overview',
        beginnerEssential: true,
        page: AppHomePage(client: client!, onExit: widget.onExit),
      ),
      _AppPageEntry(
        id: 'commands',
        icon: Icons.terminal_rounded,
        label: context.tr.commands_tab,
        compactLabel: context.tr.commands_tab_short,
        category: 'commands',
        beginnerEssential: true,
        page: AppCommandsPage(client: client!, botId: _botId),
      ),
      _AppPageEntry(
        id: 'workflows',
        icon: Icons.account_tree_outlined,
        label: eventsOnlyWorkflows
            ? context.tr.workflows_type_event
            : context.tr.workflows_tab,
        compactLabel: eventsOnlyWorkflows
            ? context.tr.workflows_type_badge_event
            : context.tr.workflows_tab_short,
        category: 'modules',
        page: WorkflowsPage(botId: _botId, eventsOnly: eventsOnlyWorkflows),
        isAvailable: (caps) =>
            caps.supportsWorkflows || caps.supportsEventListeners,
      ),
      _AppPageEntry(
        id: 'globals',
        icon: Icons.data_object_rounded,
        label: context.tr.globals_tab,
        compactLabel: context.tr.globals_tab_short,
        category: 'modules',
        page: GlobalVariablesPage(botId: _botId),
      ),
      _AppPageEntry(
        id: 'scheduler',
        icon: Icons.schedule_rounded,
        label: context.tr.scheduler_tab,
        compactLabel: context.tr.scheduler_tab_short,
        category: 'modules',
        page: SchedulerPage(botId: _botId),
        isAvailable: (caps) => caps.supportsSchedulerUi,
      ),
      _AppPageEntry(
        id: 'webhooks',
        icon: Icons.webhook_rounded,
        label: context.tr.webhooks_page_title,
        compactLabel: context.tr.webhooks_page_title,
        category: 'modules',
        page: InboundWebhooksPage(botId: _botId),
        isAvailable: (caps) => caps.supportsInboundWebhooksUi,
      ),
      _AppPageEntry(
        id: 'emojis',
        icon: Icons.emoji_emotions_outlined,
        label: context.tr.emojis_tab,
        compactLabel: context.tr.emojis_tab_short,
        category: 'modules',
        page: EmojisPage(botId: _botId),
      ),
      _AppPageEntry(
        id: 'guilds',
        icon: Icons.dns_outlined,
        label: context.tr.guilds_tab,
        compactLabel: context.tr.guilds_tab_short,
        category: 'modules',
        page: GuildsPage(botId: _botId),
      ),
      _AppPageEntry(
        id: 'dashboard',
        icon: Icons.bar_chart_rounded,
        label: context.tr.dashboard_title,
        compactLabel: context.tr.dashboard_title,
        category: 'system',
        page: CommandDashboardPage(botId: _botId),
        isAvailable: (caps) => caps.supportsCommandDashboard,
      ),
      _AppPageEntry(
        id: 'settings',
        icon: Icons.settings_outlined,
        label: context.tr.settings_tab,
        compactLabel: context.tr.settings_tab,
        category: 'system',
        beginnerEssential: true,
        page: AppSettingsPage(
          client: client!,
          onRuntimeEngineChanged: _onRuntimeEngineChanged,
        ),
      ),
    ]);
  }

  /// Regroupe les entrées de l'éditeur par catégorie, dans l'ordre historique
  /// (accueil, commandes, modules, système) : la sidebar extraite ne connaît
  /// que des sections prêtes à rendre. Les catégories vides sont omises.
  List<EditorSidebarSection> _buildSidebarSections(
    BuildContext context,
    List<_AppPageEntry> entries,
  ) {
    final titles = <String, String>{
      'overview': context.tr.home_tab.toUpperCase(),
      'commands': context.tr.commands_tab.toUpperCase(),
      'modules': context.tr.bot_home_section_modules,
      'system': context.tr.settings_tab.toUpperCase(),
    };

    return [
      for (final section in titles.entries)
        if (entries.any((e) => e.category == section.key))
          EditorSidebarSection(
            title: section.value,
            items: [
              for (final item in entries.where(
                (e) => e.category == section.key,
              ))
                EditorSidebarItem(
                  id: item.id,
                  icon: item.icon,
                  label: item.label,
                ),
            ],
          ),
    ];
  }

  /// Sidebar partagée desktop/tiroir : le parent garde l'état (préférence
  /// repliée persistée, section active) et reçoit les intentions.
  Widget _buildSidebar(
    BuildContext context,
    List<_AppPageEntry> entries,
    String activeId, {
    required bool isDrawer,
  }) {
    return EditorSidebar(
      appName: widget.appName,
      botId: _botId,
      avatarUrl: _avatarUrl,
      sections: _buildSidebarSections(context, entries),
      activeItemId: activeId,
      collapsed: !isDrawer && _sidebarCollapsed,
      onToggleCollapsed: _toggleSidebarCollapsed,
      onSelectItem: (itemId) =>
          _onSidebarItemSelected(entries, itemId, isDrawer: isDrawer),
      onBack: () => _exitEditor(closeDrawerFirst: isDrawer),
      showBackButton: isDrawer || !ResponsiveHelper.isDesktopPlatform(),
      isDrawer: isDrawer,
      showBeginnerMode: _beginnerModeLoaded && client != null,
      beginnerMode: _beginnerMode,
      onBeginnerModeChanged: _toggleBeginnerMode,
    );
  }

  void _onSidebarItemSelected(
    List<_AppPageEntry> entries,
    String itemId, {
    required bool isDrawer,
  }) {
    if (isDrawer) {
      Navigator.of(context).pop();
    }
    HapticFeedback.selectionClick();
    final entry = entries.firstWhere(
      (e) => e.id == itemId,
      orElse: () => entries.first,
    );
    setState(() {
      _activeSectionId = itemId;
      if (entry.category == 'modules') {
        _activeModuleId = itemId;
      } else if (entry.category == 'system') {
        _activeSettingsSubTab = itemId;
      }
    });
  }

  Widget _buildModulesView(
    ColorScheme colorScheme,
    List<_AppPageEntry> moduleEntries,
  ) {
    if (moduleEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeModuleEntry = moduleEntries.firstWhere(
      (e) => e.id == _activeModuleId,
      orElse: () => moduleEntries.first,
    );
    _loadedPageIds.add(activeModuleEntry.id);

    final activeIndex = moduleEntries.indexWhere(
      (e) => e.id == activeModuleEntry.id,
    );
    final validIndex = activeIndex >= 0 ? activeIndex : 0;

    return Column(
      children: [
        _buildEntriesNavBar(
          colorScheme: colorScheme,
          entries: moduleEntries,
          activeId: activeModuleEntry.id,
          scrollable: true,
          onSelect: (entry) {
            HapticFeedback.selectionClick();
            setState(() {
              _activeModuleId = entry.id;
              _activeSectionId = entry.id;
              _loadedPageIds.add(entry.id);
            });
          },
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: IndexedStack(
              index: validIndex,
              children: [
                for (var i = 0; i < moduleEntries.length; i++)
                  _loadedPageIds.contains(moduleEntries[i].id)
                      ? moduleEntries[i].page
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Bandeau de sous-navigation de l'éditeur (pastilles modules/système) rendu
  /// par le composant partagé [FloatingGlassNavBar] : c'est le même design que
  /// la nav flottante du bas et que la Home, en variante inline.
  ///
  /// [scrollable] est activé quand les entrées sont nombreuses (modules) pour
  /// que les libellés ne soient pas comprimés ; sinon les items se partagent la
  /// largeur disponible.
  Widget _buildEntriesNavBar({
    required ColorScheme colorScheme,
    required List<_AppPageEntry> entries,
    required String activeId,
    required bool scrollable,
    required void Function(_AppPageEntry entry) onSelect,
  }) {
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: FloatingGlassNavBar.inlineHorizontalMargin,
            vertical: FloatingGlassNavBar.inlineVerticalMargin,
          ),
          child: FloatingGlassNavBar.inline(
            scrollable: scrollable,
            items: [
              for (final entry in entries)
                FloatingGlassNavItem(
                  icon: entry.icon,
                  label: entry.compactLabel,
                  selected: entry.id == activeId,
                  onTap: () => onSelect(entry),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Items du bottom menu mobile : les mêmes piliers qu'avant (selon le mode
  /// débutant et l'état hors-ligne), mais rendus par le composant partagé
  /// [FloatingGlassNavBar] pour avoir le même design que la Home.
  List<FloatingGlassNavItem> _buildMobileNavItems(
    BuildContext context,
    String activeSectionId,
  ) {
    final isOffline = client == null;
    final tr = context.tr;

    final pillars =
        <({String id, IconData icon, IconData? selectedIcon, String label})>[
          (
            id: isOffline ? 'offline_token' : 'home',
            icon: isOffline ? Icons.vpn_key_outlined : Icons.dashboard_outlined,
            selectedIcon: isOffline ? null : Icons.dashboard_rounded,
            label: isOffline ? tr.settings_tab : tr.home_tab,
          ),
          (
            id: 'commands',
            icon: Icons.terminal_rounded,
            selectedIcon: null,
            label: tr.commands_tab_short,
          ),
          if (!_beginnerMode || isOffline)
            (
              id: 'modules',
              icon: Icons.widgets_outlined,
              selectedIcon: Icons.widgets_rounded,
              // Le libellé i18n est un titre de section écrit en capitales :
              // on le repasse en casse normale pour la nav du bas, homogène
              // avec « Accueil », « Cmd » et « Paramètres ».
              label: _sentenceCased(tr.bot_home_section_modules),
            ),
          if (!isOffline)
            (
              id: 'settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: tr.settings_tab,
            ),
        ];

    String activePillarId = isOffline ? 'offline_token' : 'home';
    if (activeSectionId == 'commands') {
      activePillarId = 'commands';
    } else if ([
      'workflows',
      'globals',
      'scheduler',
      'webhooks',
      'emojis',
      'guilds',
    ].contains(activeSectionId)) {
      activePillarId = 'modules';
    } else if (['settings', 'dashboard'].contains(activeSectionId)) {
      activePillarId = 'settings';
    }

    return [
      for (var i = 0; i < pillars.length; i++)
        FloatingGlassNavItem(
          icon: pillars[i].icon,
          selectedIcon: pillars[i].selectedIcon,
          label: pillars[i].label,
          selected: pillars[i].id == activePillarId,
          onTap: () => _onPillarTap(pillars[i].id),
        ),
    ];
  }

  void _onPillarTap(String pillarId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (pillarId == 'home' || pillarId == 'offline_token') {
        _activeSectionId = pillarId;
      } else if (pillarId == 'commands') {
        _activeSectionId = 'commands';
      } else if (pillarId == 'modules') {
        _activeSectionId = _activeModuleId;
      } else if (pillarId == 'settings') {
        _activeSectionId = _activeSettingsSubTab;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide =
        MediaQuery.sizeOf(context).width >= AppTheme.desktopBreakpoint;
    var entries = _buildEntries();

    if (_beginnerMode && client != null) {
      entries = entries.where((e) => e.beginnerEssential).toList();
    }

    if (_isLoading || !_sidebarCollapsedLoaded || entries.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // `build()` must stay pure: derive the active section instead of writing to
    // `_activeSectionId`. The field is reset by the callbacks that legitimately
    // change it (`_init`, `_toggleBeginnerMode`, `_onRuntimeEngineChanged`,
    // sidebar/pill/bottom-bar taps).
    final activeId = entries.any((e) => e.id == _activeSectionId)
        ? _activeSectionId
        : entries.first.id;

    if (isWide) {
      final activeIndex = entries.indexWhere((e) => e.id == activeId);
      final validIndex = activeIndex >= 0 ? activeIndex : 0;
      _loadedPageIds.add(entries[validIndex].id);

      return Scaffold(
        body: Row(
          children: [
            _buildSidebar(context, entries, activeId, isDrawer: false),
            Expanded(
              child: IndexedStack(
                index: validIndex,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _loadedPageIds.contains(entries[i].id)
                        ? entries[i].page
                        : const SizedBox.shrink(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final moduleEntries = entries
        .where((e) => e.category == 'modules')
        .toList();
    final systemEntries = entries.where((e) => e.category == 'system').toList();

    final homeEntry = entries.firstWhere(
      (e) => e.id == (client == null ? 'offline_token' : 'home'),
      orElse: () => entries.first,
    );
    final commandsEntry = entries.firstWhere(
      (e) => e.id == 'commands',
      orElse: () => entries.first,
    );
    final settingsEntry = entries.firstWhere(
      (e) => e.id == 'settings',
      orElse: () => entries.first,
    );

    int activePillarIndex = 0;
    if (activeId == 'commands') {
      activePillarIndex = 1;
    } else if (moduleEntries.any((e) => e.id == activeId)) {
      activePillarIndex = 2;
    } else if (systemEntries.any((e) => e.id == activeId)) {
      activePillarIndex = 3;
    } else {
      activePillarIndex = 0;
    }

    _loadedPageIds.add(homeEntry.id);
    if (activePillarIndex == 1) _loadedPageIds.add(commandsEntry.id);
    if (activePillarIndex == 2) _loadedPageIds.add(_activeModuleId);
    if (activePillarIndex == 3) _loadedPageIds.add(settingsEntry.id);

    final activeMobileBody = IndexedStack(
      index: activePillarIndex,
      children: [
        homeEntry.page,
        _loadedPageIds.contains(commandsEntry.id)
            ? commandsEntry.page
            : const SizedBox.shrink(),
        _buildModulesView(colorScheme, moduleEntries),
        _loadedPageIds.contains(settingsEntry.id)
            ? settingsEntry.page
            : const SizedBox.shrink(),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitEditor();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(child: activeMobileBody),
            Positioned(
              left: FloatingGlassNavBar.margin,
              right: FloatingGlassNavBar.margin,
              bottom: FloatingGlassNavBar.bottomOffsetOf(context),
              child: FloatingGlassNavBar(
                items: _buildMobileNavItems(context, activeId),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppPageEntry {
  final String id;
  final IconData icon;
  final String label;
  final String compactLabel;
  final Widget page;
  final String category;
  final bool beginnerEssential;
  final bool Function(BotRuntimeCapabilities caps) isAvailable;

  const _AppPageEntry({
    required this.id,
    required this.icon,
    required this.label,
    required this.compactLabel,
    required this.page,
    required this.category,
    this.beginnerEssential = false,
    this.isAvailable = _alwaysAvailable,
  });

  static bool _alwaysAvailable(BotRuntimeCapabilities caps) => true;
}

class _OfflineTokenPage extends StatefulWidget {
  final String botId;
  final Future<void> Function() onTokenSaved;

  const _OfflineTokenPage({required this.botId, required this.onTokenSaved});

  @override
  State<_OfflineTokenPage> createState() => _OfflineTokenPageState();
}

class _OfflineTokenPageState extends State<_OfflineTokenPage> {
  final _tokenController = TextEditingController();
  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newToken = _tokenController.text.trim();
    if (newToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_settings_token_required)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final discordUser = await getDiscordUser(newToken);

      // ── Bot ID mismatch check ─────────────────────────────────────────────
      final newBotId = discordUser.id.toString();
      if (newBotId != widget.botId) {
        if (!mounted) return;
        final proceed = await AppTheme.showConfirmDialog(
          context,
          title: context.tr.bot_settings_token_mismatch_title,
          content: context.tr.bot_settings_token_mismatch_content(
            newBotId,
            widget.botId,
          ),
          confirmLabel: context.tr.bot_settings_token_mismatch_confirm,
        );
        if (!proceed || !mounted) return;
      }

      final intentOutcome = await fetchPortalIntentsWithOutcome(newToken);
      final computedIntents = intentOutcome.intents;

      await appManager.createOrUpdateApp(
        id: discordUser.id,
        username: discordUser.username,
        avatarHash: discordUser.avatarHash,
        discriminator: discordUser.discriminator.toString(),
        token: newToken,
        intents: computedIntents,
      );
      if (!mounted) return;

      try {
        final apiConfig = await MainApiSettingsStore.loadConfig();
        if (apiConfig.isConfigured) {
          final appData = Map<String, dynamic>.from(
            await appManager.getApp(discordUser.id.toString()),
          );
          final client = MainApiClient(baseUrl: apiConfig.baseUrl);
          final session = await client.exchangeDiscordBotToken(
            botToken: newToken,
          );
          final apiClient = MainApiClient(
            baseUrl: apiConfig.baseUrl,
            accessToken: session.accessToken,
          );
          await apiClient.syncBot(
            discordUser.id.toString(),
            discordUser.username,
            appData,
          );
        }
      } catch (e) {
        developer.log('Failed to sync token to cloud: $e', name: 'AppEditPage');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.bot_settings_token_saved)),
      );
      showPortalIntentOutcomeSnackbars(context, intentOutcome);
      await widget.onTokenSaved();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteBot() async {
    final confirm = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.bot_settings_delete_title,
      content: context.tr.bot_settings_delete_desc(widget.botId),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );
    if (confirm != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await appManager.deleteBotCompletely(widget.botId);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        HomePageState.current?.syncAllBotsFromManager();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.bot_settings_token_title),
        automaticallyImplyLeading: false,
        // Même règle que les autres pages : le burger n'existe que si le shell
        // crée réellement un tiroir (layout compact). Sur desktop la sidebar
        // est permanente, il ne servait à rien.
        leading: editorSubPageLeading(context),
      ),
      // Formulaire court (jeton du bot) : contenu volontairement
      // étroit, la largeur commune étirerait le champ sur toute la
      // fenêtre. Seules les marges suivent le contrat commun.
      body: PageContent(
        maxWidth: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.vpn_key_outlined,
              size: 48,
              color: AppTheme.warning,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr.bot_offline_token_desc,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tokenController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: context.tr.bot_settings_update_token,
                hintText: context.tr.bot_settings_token_hint,
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(context.tr.bot_settings_save_token_only_btn),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : _deleteBot,
              icon: const Icon(Icons.delete_outline, color: AppTheme.error),
              label: Text(
                context.tr.bot_home_delete,
                style: const TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
