import 'dart:developer' as developer;

import 'package:bot_creator/main.dart';
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
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';

import 'package:bot_creator/core/utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:nyxx/nyxx.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppEditPage extends StatefulWidget {
  final String appName;
  final int id;
  const AppEditPage({super.key, required this.appName, required this.id});

  @override
  State<AppEditPage> createState() => _AppEditPageState();
}

class _AppEditPageState extends State<AppEditPage>
    with TickerProviderStateMixin {
  NyxxRest? client;
  bool _isLoading = true;
  String? _degradedReason;
  String? _currentToken;

  late int _selectedIndex = 0;
  bool _beginnerMode = false;
  bool _beginnerModeLoaded = false;
  String _runtimeEngine = runtimeEngineDart;
  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows => true,
      TargetPlatform.linux => true,
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<List<ApplicationCommand>> getCommands() async {
    if (client == null) {
      throw Exception("Client is not initialized");
    }
    final commands = await client!.commands.list();
    return commands;
  }

  Future<void> _init() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        client = null;
        _degradedReason = null;
      });
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
          _currentToken = token;
          _runtimeEngine = runtimeEngine;
        });
      }

      if (token.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _degradedReason = 'Token missing. Local edit mode enabled.';
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
        }
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _degradedReason = 'Unable to load bot data. Local edit mode enabled.';
        _isLoading = false;
      });
    }

    // S7: Load beginner mode preference. Auto-enable for bots with 0 commands
    // unless the user has previously opted out.
    await _loadBeginnerMode();
  }

  String get _beginnerModeKey => 'beginner_mode_${widget.id}';

  Future<void> _loadBeginnerMode() async {
    final prefs = await SharedPreferences.getInstance();
    final optedOut = prefs.getBool(_beginnerModeKey) == false;

    if (optedOut) {
      // User previously disabled beginner mode for this bot.
      if (mounted) setState(() { _beginnerMode = false; _beginnerModeLoaded = true; });
      return;
    }

    // Auto-detect: beginner mode is on when the bot has no commands yet.
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
    setState(() => _beginnerMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_beginnerModeKey, value);
    // Reset to Home tab when switching modes to avoid invalid indices.
    if (mounted) setState(() => _selectedIndex = 0);
    AppAnalytics.logEvent(
      name: 'beginner_mode_toggled',
      parameters: {'enabled': value.toString(), 'bot_id': _botId},
    );
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
      _selectedIndex = 0;
    });
  }

  List<_AppPageEntry> _applyRuntimeGating(List<_AppPageEntry> entries) {
    if (_capabilities.supportsWorkflows) {
      return entries;
    }
    return entries
        .where((entry) => !entry.dartOnly)
        .toList(growable: false);
  }

  List<_AppPageEntry> _buildEntries(bool isSmallPhone) {
    if (client == null) {
      return _applyRuntimeGating([
        _AppPageEntry(
          icon: Icons.vpn_key_outlined,
          label: context.tr.settings_tab,
          compactLabel: context.tr.settings_tab,
          page: _OfflineTokenPage(botId: _botId, onTokenSaved: _init),
        ),
        _AppPageEntry(
          icon: Icons.add_circle,
          label: context.tr.commands_tab,
          compactLabel: context.tr.commands_tab_short,
          page: AppCommandsPage(botId: _botId),
        ),
        _AppPageEntry(
          icon: Icons.key,
          label: context.tr.globals_tab,
          compactLabel: context.tr.globals_tab_short,
          page: GlobalVariablesPage(botId: _botId),
        ),
        _AppPageEntry(
          icon: Icons.account_tree,
          label: context.tr.workflows_tab,
          compactLabel: context.tr.workflows_tab_short,
          page: WorkflowsPage(botId: _botId),
          dartOnly: true,
        ),
        _AppPageEntry(
          icon: Icons.schedule,
          label: context.tr.scheduler_tab,
          compactLabel: context.tr.scheduler_tab_short,
          page: SchedulerPage(botId: _botId),
          dartOnly: true,
        ),
        _AppPageEntry(
          icon: Icons.webhook,
          label: context.tr.webhooks_page_title,
          compactLabel: context.tr.webhooks_page_title,
          page: InboundWebhooksPage(botId: _botId),
          dartOnly: true,
        ),
      ]);
    }

    return _applyRuntimeGating([
      _AppPageEntry(
        icon: Icons.home,
        label: context.tr.home_tab,
        compactLabel: context.tr.home_tab,
        beginnerEssential: true,
        page: AppHomePage(
          client: client!,
          onNavigateToSection: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      _AppPageEntry(
        icon: Icons.add_circle,
        label: context.tr.commands_tab,
        compactLabel: context.tr.commands_tab_short,
        beginnerEssential: true,
        page: AppCommandsPage(client: client!, botId: _botId),
      ),
      _AppPageEntry(
        icon: Icons.key,
        label: context.tr.globals_tab,
        compactLabel: context.tr.globals_tab_short,
        page: GlobalVariablesPage(botId: _botId),
      ),
      _AppPageEntry(
        icon: Icons.account_tree,
        label: context.tr.workflows_tab,
        compactLabel: context.tr.workflows_tab_short,
        page: WorkflowsPage(botId: _botId),
        dartOnly: true,
      ),
      _AppPageEntry(
        icon: Icons.schedule,
        label: context.tr.scheduler_tab,
        compactLabel: context.tr.scheduler_tab_short,
        page: SchedulerPage(botId: _botId),
        mobileSecondary: true,
        dartOnly: true,
      ),
      _AppPageEntry(
        icon: Icons.webhook,
        label: context.tr.webhooks_page_title,
        compactLabel: context.tr.webhooks_page_title,
        page: InboundWebhooksPage(botId: _botId),
        mobileSecondary: true,
        dartOnly: true,
      ),
      _AppPageEntry(
        icon: Icons.emoji_emotions_outlined,
        label: context.tr.emojis_tab,
        compactLabel: context.tr.emojis_tab_short,
        page: EmojisPage(botId: _botId),
        mobileSecondary: true,
      ),
      _AppPageEntry(
        icon: Icons.dns_outlined,
        label: context.tr.guilds_tab,
        compactLabel: context.tr.guilds_tab_short,
        page: GuildsPage(botId: _botId),
        mobileSecondary: true,
      ),
      _AppPageEntry(
        icon: Icons.bar_chart,
        label: context.tr.dashboard_title,
        compactLabel: context.tr.dashboard_title,
        page: CommandDashboardPage(botId: _botId),
        mobileSecondary: true,
        dartOnly: true,
      ),
      _AppPageEntry(
        icon: Icons.settings,
        label: context.tr.settings_tab,
        compactLabel: context.tr.settings_tab,
        page: AppSettingsPage(
          client: client!,
          onRuntimeEngineChanged: _onRuntimeEngineChanged,
        ),
        mobileSecondary: true,
        beginnerEssential: true,
      ),
    ]);
  }

  Widget _buildSidebarContent(
    BuildContext context,
    ColorScheme colorScheme,
    List<_AppNavItem> navItems, {
    bool isDrawer = false,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    tooltip: context.tr.common_back,
                    onPressed: () {
                      if (isDrawer) {
                        Navigator.of(context).pop(); // Close drawer
                      }
                      Navigator.of(context).pop(); // Exit editor
                    },
                  ),
                  Expanded(
                    child: Text(
                      widget.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final selected = _selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      onTap: () {
                        if (isDrawer) {
                          Navigator.of(context).pop(); // Close drawer
                        }
                        setState(() {
                          _selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          color: selected
                              ? colorScheme.primaryContainer
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // S7: Beginner mode toggle at the bottom of the sidebar
            if (_beginnerModeLoaded)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Material(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  color: _beginnerMode
                      ? AppTheme.info.withValues(alpha: 0.08)
                      : Colors.transparent,
                  child: SwitchListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 0,
                    ),
                    title: Text(
                      context.tr.beginner_mode_label,
                      style: TextStyle(
                        fontSize: 13,
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
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _beginnerMode,
                    onChanged: (val) => _toggleBeginnerMode(val),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    ColorScheme colorScheme,
    List<_AppNavItem> navItems,
  ) {
    return Container(
      width: 248,
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
        child: _buildSidebarContent(context, colorScheme, navItems, isDrawer: false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallPhone = ResponsiveHelper.isSmallPhone(context);
    final useDesktopSidebar = _isDesktopPlatform;
    var entries = _buildEntries(isSmallPhone);

    // S7: Beginner mode — show only essential tabs (Home, Commands, Settings).
    // Only filter when online (offline mode already shows a reduced set).
    if (_beginnerMode && client != null) {
      entries = entries.where((e) => e.beginnerEssential).toList();
    }

    final navItems = entries
        .map(
          (entry) => _AppNavItem(
            icon: entry.icon,
            label: entry.label,
            compactLabel: entry.compactLabel,
          ),
        )
        .toList();
    final pages = entries.map((entry) => entry.page).toList();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (pages.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeIndex =
        _selectedIndex < pages.length ? _selectedIndex : pages.length - 1;

    if (useDesktopSidebar) {
      return Scaffold(
        body: Row(
          children: [
            _buildDesktopSidebar(context, colorScheme, navItems),
            Expanded(child: pages[activeIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      drawer: Drawer(
        backgroundColor: colorScheme.surface,
        child: _buildSidebarContent(context, colorScheme, navItems, isDrawer: true),
      ),
      body: pages[activeIndex],
    );
  }
}

class _AppNavItem {
  final IconData icon;
  final String label;
  final String compactLabel;

  const _AppNavItem({
    required this.icon,
    required this.label,
    required this.compactLabel,
  });
}

class _AppPageEntry {
  final IconData icon;
  final String label;
  final String compactLabel;
  final Widget page;
  final bool mobileSecondary;
  final bool beginnerEssential;
  final bool dartOnly;

  const _AppPageEntry({
    required this.icon,
    required this.label,
    required this.compactLabel,
    required this.page,
    this.mobileSecondary = false,
    this.beginnerEssential = false,
    this.dartOnly = false,
  });
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

      final computedIntents = await fetchPortalIntents(newToken);

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
          final session = await client.exchangeDiscordBotToken(botToken: newToken);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.bot_settings_token_title),
        automaticallyImplyLeading: !ResponsiveHelper.isDesktopPlatform(),
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
                  icon:
                      _saving
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.save_outlined),
                  label: Text(context.tr.bot_settings_save_token_only_btn),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineRecoveryPage extends StatefulWidget {
  final String? reason;
  final String? token;
  final Future<void> Function() onRetry;
  final Future<void> Function() onDeleteLocal;

  const _OfflineRecoveryPage({
    required this.reason,
    required this.onRetry,
    required this.onDeleteLocal,
  }) : token = null;

  @override
  State<_OfflineRecoveryPage> createState() => _OfflineRecoveryPageState();
}

class _OfflineRecoveryPageState extends State<_OfflineRecoveryPage> {
  bool _showToken = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.recovery_title),
        automaticallyImplyLeading: !ResponsiveHelper.isDesktopPlatform(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reason ?? 'Discord connection unavailable.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Offline features available: commands, globals, workflows.',
            ),
            const Text(
              'Unavailable while offline: start bot, profile (username/avatar).',
            ),
            const SizedBox(height: 24),
            if (widget.token != null && widget.token!.isNotEmpty) ...[
              Text(
                'Debug: Current Memory Token',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _showToken ? widget.token! : '••••••••••••••••',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _showToken ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                      ),
                      tooltip: _showToken ? 'Hide token' : 'Show token',
                      onPressed: () => setState(() => _showToken = !_showToken),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      tooltip: 'Copy token',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: widget.token!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Token copied to clipboard'),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.bug_report_outlined, size: 20),
                      tooltip: 'Show error details',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Connection Error Details'),
                                content: SingleChildScrollView(
                                  child: Text(
                                    widget.reason ??
                                        'No detailed error captured.',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            FilledButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(context.tr.recovery_retry_discord),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: widget.onDeleteLocal,
              icon: const Icon(Icons.delete),
              label: Text(context.tr.recovery_delete_bot),
            ),
          ],
        ),
      ),
    );
  }
}
