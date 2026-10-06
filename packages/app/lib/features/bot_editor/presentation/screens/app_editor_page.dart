import 'dart:async';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
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
import 'package:bot_creator/core/widgets/flat_nav_bar.dart';
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
import 'package:bot_creator/features/bot_editor/presentation/widgets/modules_list.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/team/presentation/team_chat_page.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

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

  /// Mobile : le pilier « Modules » affiche d'abord la liste groupée ; ouvrir un
  /// module bascule sur sa page (le retour système / le pilier ramène à la liste).
  bool _modulesListOpen = true;
  String _activeSettingsSubTab = 'settings';

  bool _beginnerMode = false;
  bool _beginnerModeLoaded = false;
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

  _AppPageEntry _copilotEntry() => _AppPageEntry(
    id: 'copilot',
    icon: Icons.auto_awesome_outlined,
    label: context.tr.copilot_title,
    compactLabel: context.tr.copilot_compact_label,
    category: 'overview',
    beginnerEssential: true,
    page: CopilotPage(
      botId: _botId,
      botName: widget.appName,
      location: 'local',
    ),
  );
  List<_AppPageEntry> _buildEntries() {
    final eventsOnlyWorkflows =
        _capabilities.supportsEventListeners &&
        !_capabilities.supportsWorkflows;

    if (client == null) {
      return _applyRuntimeGating([
        _copilotEntry(),
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
      _copilotEntry(),
      _AppPageEntry(
        id: 'home',
        icon: Icons.dashboard_rounded,
        label: context.tr.home_tab,
        compactLabel: context.tr.home_tab,
        category: 'overview',
        beginnerEssential: true,
        page: AppHomePage(
          client: client!,
          onExit: widget.onExit,
          // Les cartes de la home desktop ouvrent la section correspondante.
          onOpenSection: (sectionId) => setState(() {
            _activeSectionId = sectionId;
            _modulesListOpen = false;
            _loadedPageIds.add(sectionId);
          }),
        ),
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
        id: 'team',
        icon: Icons.groups_outlined,
        label: context.tr.team_tab,
        compactLabel: context.tr.team_tab_short,
        category: 'modules',
        page: TeamChatPage(botId: _botId),
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

  /// Rail desktop PLAT : Accueil, Copilote IA, Commandes, puis chaque module à
  /// plat, puis Tableau de bord ; « Paramètres » est épinglé en bas du rail.
  /// Les groupes sont séparés par un filet ; les sections vides sont omises
  /// après le filtrage par capacités du runtime.
  List<EditorSidebarSection> _buildRailSections(
    BuildContext context,
    List<_AppPageEntry> entries,
  ) {
    const groups = <List<String>>[
      ['home', 'copilot', 'commands'],
      [
        'workflows',
        'globals',
        'scheduler',
        'webhooks',
        'emojis',
        'team',
        'guilds',
      ],
      ['dashboard', 'offline_token'],
    ];
    // Libellés complets pour les piliers ; libellés courts pour les modules
    // (« Vars », « Planif »…), comme dans le rail de la maquette.
    const fullLabelIds = {
      'home',
      'copilot',
      'commands',
      'workflows',
      'dashboard',
      'offline_token',
      'settings',
    };
    EditorSidebarItem itemOf(_AppPageEntry entry) => EditorSidebarItem(
      id: entry.id,
      icon: entry.icon,
      label: fullLabelIds.contains(entry.id) ? entry.label : entry.compactLabel,
      tooltip: entry.label,
    );
    return [
      for (final ids in groups)
        EditorSidebarSection(
          title: '',
          items: [
            for (final id in ids)
              for (final entry in entries.where((entry) => entry.id == id))
                itemOf(entry),
          ],
        ),
    ];
  }

  /// Entrée « Paramètres » épinglée en bas du rail desktop.
  EditorSidebarItem? _railPinnedItem(List<_AppPageEntry> entries) {
    for (final entry in entries) {
      if (entry.id == 'settings') {
        return EditorSidebarItem(
          id: entry.id,
          icon: entry.icon,
          label: entry.label,
        );
      }
    }
    return null;
  }

  /// Barre de navigation desktop (en haut) : le parent garde l'état (section
  /// active) et reçoit les intentions.
  Widget _buildRail(
    BuildContext context,
    List<_AppPageEntry> entries,
    String activeId,
  ) {
    return EditorTopBar(
      appName: widget.appName,
      botId: _botId,
      avatarUrl: _avatarUrl,
      sections: _buildRailSections(context, entries),
      pinnedItem: _railPinnedItem(entries),
      activeItemId: activeId,
      onSelectItem: (itemId) => _onSidebarItemSelected(entries, itemId),
      onBack: _exitEditor,
      showBackButton: !ResponsiveHelper.isDesktopPlatform(),
      showBeginnerMode: _beginnerModeLoaded && client != null,
      beginnerMode: _beginnerMode,
      onBeginnerModeChanged: _toggleBeginnerMode,
    );
  }

  void _onSidebarItemSelected(List<_AppPageEntry> entries, String itemId) {
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

  /// Liste groupée des modules (maquette « Modules » mobile) : mêmes pages
  /// que le bandeau de pastilles, seuls les modules disponibles apparaissent.
  Widget _buildModulesList(List<_AppPageEntry> moduleEntries) {
    final tr = context.tr;
    final descriptions = <String, String>{
      'workflows': tr.modules_desc_workflows,
      'globals': tr.modules_desc_globals,
      'emojis': tr.modules_desc_emojis,
      'scheduler': tr.modules_desc_scheduler,
      'webhooks': tr.modules_desc_webhooks,
      'team': tr.modules_desc_team,
      'guilds': tr.modules_desc_guilds,
    };
    final layout = <(String, List<String>)>[
      (tr.modules_group_create, ['workflows', 'globals', 'emojis']),
      (tr.modules_group_automation, ['scheduler', 'webhooks']),
      (tr.modules_group_management, ['team', 'guilds']),
    ];
    ModuleListEntry toListEntry(_AppPageEntry e) => ModuleListEntry(
      id: e.id,
      icon: e.icon,
      title: e.label,
      subtitle: descriptions[e.id],
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _activeModuleId = e.id;
          _activeSectionId = e.id;
          _modulesListOpen = false;
          _loadedPageIds.add(e.id);
        });
      },
    );
    final known = layout.expand((g) => g.$2).toSet();
    final groups = [
      for (final (title, ids) in layout)
        ModuleListGroup(
          title: title,
          entries: [
            for (final e in moduleEntries)
              if (ids.contains(e.id)) toListEntry(e),
          ],
        ),
    ];
    // Filet de sécurité : un module futur non classé reste accessible.
    final others = [
      for (final e in moduleEntries)
        if (!known.contains(e.id)) toListEntry(e),
    ];
    if (others.isNotEmpty) {
      groups.add(
        ModuleListGroup(title: tr.bot_home_section_tools, entries: others),
      );
    }
    return ModulesListView(
      title: _sentenceCased(tr.bot_home_section_modules),
      overline: widget.appName,
      searchHint: tr.common_search,
      groups: groups,
      // Réserve la place de la barre plate du bas (84 px) + zone sûre.
      bottomPadding: 84 + MediaQuery.paddingOf(context).bottom + 16,
    );
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

    if (_modulesListOpen) return _buildModulesList(moduleEntries);

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

  /// En-tête plat de sous-navigation (maquette « Modules » mobile) : ligne
  /// retour (« Modules » -> liste) + titre 20/800, puis, si [entries] en
  /// compte plusieurs, une rangée défilante de pastilles plates (36 px, rayon
  /// 12, sélection = fond relevé + anneau violet) pour passer d'un module à
  /// l'autre.
  Widget _buildEntriesNavBar({
    required ColorScheme colorScheme,
    required List<_AppPageEntry> entries,
    required String activeId,
    required bool scrollable,
    required void Function(_AppPageEntry entry) onSelect,
  }) {
    final active = entries.firstWhere(
      (e) => e.id == activeId,
      orElse: () => entries.first,
    );
    final backLabel = _sentenceCased(context.tr.bot_home_section_modules);
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  Semantics(
                    button: true,
                    label: backLabel,
                    child: InkWell(
                      key: const ValueKey('entries-back-to-modules'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _modulesListOpen = true);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 44,
                          minWidth: 44,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppIcon.fromMaterial(
                                Icons.chevron_left,
                                size: 24,
                                color: AppTheme.actionVioletSoft,
                              ),
                              Text(
                                backLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.actionVioletSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                active.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (entries.length > 1)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final entry = entries[i];
                    final selected = entry.id == activeId;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: entry.compactLabel,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelect(entry),
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? colorScheme.surfaceContainerHighest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.actionViolet
                                  : AppTheme.homeCardBorder,
                              width: selected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            entry.compactLabel,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.homeMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
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
        _modulesListOpen = true;
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

    if (_isLoading || entries.isEmpty) {
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
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRail(context, entries, activeId),
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
        // Depuis la page d'un module, le retour ramène à la liste des modules.
        if (activePillarIndex == 2 && !_modulesListOpen) {
          setState(() => _modulesListOpen = true);
          return;
        }
        _exitEditor();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(child: activeMobileBody),
            // Barre PLATE collée en bas (84 px, filet haut) : plus de nav flottante.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: FlatNavBar(items: _buildMobileNavItems(context, activeId)),
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
            const AppIcon.fromMaterial(
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
                  icon: AppIcon.fromMaterial(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Plus de bouton « importer le jeton » : la reprise est automatique, donc
            // l'utilisateur n'a jamais à savoir d'où vient un jeton. La saisie manuelle
            // reste juste en dessous pour ceux qui ont le leur sous la main.
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const AppIcon.fromMaterial(Icons.save_outlined),
              label: Text(context.tr.bot_settings_save_token_only_btn),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _saving ? null : _deleteBot,
              icon: const AppIcon.fromMaterial(
                Icons.delete_outline,
                color: AppTheme.error,
              ),
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
