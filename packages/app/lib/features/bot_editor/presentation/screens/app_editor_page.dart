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
import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_dashboard.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/commands.list.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/emojis.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/global.variables.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/guilds.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/home.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/inbound_webhooks.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/scheduler.page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/settings.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyxx/nyxx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppEditPage extends StatefulWidget {
  final String appName;
  final int id;
  final bool embedded;
  final VoidCallback? onExit;

  const AppEditPage({
    super.key,
    required this.appName,
    required this.id,
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
  String _runtimeEngine = runtimeEngineDart;

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

  Widget _buildSidebarContent(
    BuildContext context,
    ColorScheme colorScheme,
    List<_AppPageEntry> entries, {
    required String activeSectionId,
    bool isDrawer = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppTheme.homeMuted : colorScheme.onSurfaceVariant;

    final categories = <String, List<_AppPageEntry>>{
      context.tr.home_tab.toUpperCase(): entries
          .where((e) => e.category == 'overview')
          .toList(),
      context.tr.commands_tab.toUpperCase(): entries
          .where((e) => e.category == 'commands')
          .toList(),
      context.tr.bot_home_section_modules: entries
          .where((e) => e.category == 'modules')
          .toList(),
      context.tr.settings_tab.toUpperCase(): entries
          .where((e) => e.category == 'system')
          .toList(),
    };

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: context.tr.common_back,
                  onPressed: () => _exitEditor(closeDrawerFirst: isDrawer),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'ID $_botId',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              children: [
                for (final cat in categories.entries)
                  if (cat.value.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                      child: Text(
                        cat.key,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: muted,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    for (final item in cat.value)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _SidebarItemTile(
                          icon: item.icon,
                          label: item.label,
                          selected: activeSectionId == item.id,
                          onTap: () {
                            if (isDrawer) {
                              Navigator.of(context).pop();
                            }
                            HapticFeedback.selectionClick();
                            setState(() {
                              _activeSectionId = item.id;
                              if (item.category == 'modules') {
                                _activeModuleId = item.id;
                              } else if (item.category == 'system') {
                                _activeSettingsSubTab = item.id;
                              }
                            });
                          },
                        ),
                      ),
                  ],
              ],
            ),
          ),
          if (_beginnerModeLoaded && client != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                color: _beginnerMode
                    ? AppTheme.info.withValues(alpha: 0.08)
                    : Colors.transparent,
                child: SwitchListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 0,
                  ),
                  title: Text(
                    context.tr.beginner_mode_label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _beginnerMode
                          ? AppTheme.info
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  subtitle: Text(
                    _beginnerMode
                        ? context.tr.beginner_mode_on_hint
                        : context.tr.beginner_mode_off_hint,
                    style: const TextStyle(fontSize: 10),
                  ),
                  value: _beginnerMode,
                  onChanged: (val) => _toggleBeginnerMode(val),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    ColorScheme colorScheme,
    List<_AppPageEntry> entries,
    String activeSectionId,
  ) {
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: _buildSidebarContent(
          context,
          colorScheme,
          entries,
          activeSectionId: activeSectionId,
          isDrawer: false,
        ),
      ),
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

    return Column(
      children: [
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final entry in moduleEntries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ModulePill(
                      icon: entry.icon,
                      label: entry.compactLabel,
                      selected: activeModuleEntry.id == entry.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeModuleId = entry.id;
                          _activeSectionId = entry.id;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        Expanded(child: activeModuleEntry.page),
      ],
    );
  }

  Widget _buildSettingsView(
    ColorScheme colorScheme,
    List<_AppPageEntry> systemEntries,
  ) {
    if (systemEntries.length <= 1) {
      return systemEntries.first.page;
    }

    final activeSystemEntry = systemEntries.firstWhere(
      (e) => e.id == _activeSettingsSubTab,
      orElse: () => systemEntries.first,
    );

    return Column(
      children: [
        Container(
          color: colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                for (final entry in systemEntries)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _ModulePill(
                      icon: entry.icon,
                      label: entry.compactLabel,
                      selected: activeSystemEntry.id == entry.id,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _activeSettingsSubTab = entry.id;
                          _activeSectionId = entry.id;
                        });
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        Expanded(child: activeSystemEntry.page),
      ],
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
              label: tr.bot_home_section_modules,
            ),
          if (!isOffline)
            (
              id: 'settings',
              icon: Icons.settings_outlined,
              selectedIcon: Icons.settings_rounded,
              label: tr.settings_tab,
            ),
        ];

    int activePillarIndex = 0;
    if (activeSectionId == 'commands') {
      activePillarIndex = 1;
    } else if ([
      'workflows',
      'globals',
      'scheduler',
      'webhooks',
      'emojis',
      'guilds',
    ].contains(activeSectionId)) {
      activePillarIndex = (!_beginnerMode || isOffline) ? 2 : 0;
    } else if (['settings', 'dashboard'].contains(activeSectionId)) {
      activePillarIndex = (!_beginnerMode || isOffline) ? 3 : 2;
    } else {
      activePillarIndex = 0;
    }

    return [
      for (var i = 0; i < pillars.length; i++)
        FloatingGlassNavItem(
          icon: pillars[i].icon,
          selectedIcon: pillars[i].selectedIcon,
          label: pillars[i].label,
          selected: activePillarIndex == i,
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
      final activeEntry = entries.firstWhere(
        (e) => e.id == activeId,
        orElse: () => entries.first,
      );

      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(context, colorScheme, entries, activeId),
            Expanded(child: activeEntry.page),
          ],
        ),
      );
    }

    final moduleEntries = entries
        .where((e) => e.category == 'modules')
        .toList();
    final systemEntries = entries.where((e) => e.category == 'system').toList();

    Widget activeMobileBody;
    if (activeId == 'home' || activeId == 'offline_token') {
      activeMobileBody = entries
          .firstWhere((e) => e.id == activeId, orElse: () => entries.first)
          .page;
    } else if (activeId == 'commands') {
      activeMobileBody = entries
          .firstWhere((e) => e.id == 'commands', orElse: () => entries.first)
          .page;
    } else if (moduleEntries.any((e) => e.id == activeId)) {
      activeMobileBody = _buildModulesView(colorScheme, moduleEntries);
    } else if (systemEntries.any((e) => e.id == activeId)) {
      activeMobileBody = _buildSettingsView(colorScheme, systemEntries);
    } else {
      activeMobileBody = entries.first.page;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _exitEditor();
      },
      child: Scaffold(
        // `extendBody` + barre positionnée : le bottom menu du bot est
        // désormais la même barre flottante « verre dépoli » que la Home.
        extendBody: true,
        drawer: Drawer(
          backgroundColor: colorScheme.surface,
          child: _buildSidebarContent(
            context,
            colorScheme,
            entries,
            activeSectionId: activeId,
            isDrawer: true,
          ),
        ),
        body: Stack(
          children: [
            // La barre flotte au-dessus du contenu : on réserve sa hauteur,
            // comme le fait `HomePage`, pour que le bas des pages reste
            // accessible.
            Padding(
              padding: EdgeInsets.only(
                bottom: FloatingGlassNavBar.contentClearanceOf(context),
              ),
              child: activeMobileBody,
            ),
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

class _SidebarItemTile extends StatelessWidget {
  const _SidebarItemTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? colorScheme.primary : colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModulePill extends StatelessWidget {
  const _ModulePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: selected
          ? scheme.primary
          : (isDark ? AppTheme.homeCard : scheme.surfaceContainer),
      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : (isDark ? AppTheme.homeCardBorder : scheme.outlineVariant),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected
                    ? scheme.onPrimary
                    : (isDark ? AppTheme.homeMuted : scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
            ],
          ),
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
        leading: !ResponsiveHelper.isDesktopPlatform()
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.openParentDrawer(),
              )
            : null,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
        ),
      ),
    );
  }
}
