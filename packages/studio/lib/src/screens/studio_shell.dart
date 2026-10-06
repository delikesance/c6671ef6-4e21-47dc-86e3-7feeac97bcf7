import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../auth/auth_controller.dart';
import '../auth/studio_session.dart';
import '../l10n_ext.dart';
import '../layout.dart';
import '../locale_controller.dart';
import '../editor/studio_debug_replay_host.dart';
import '../editor/studio_editor_host.dart';
import '../editor/studio_hosted_containers_host.dart';
import '../editor/studio_subscriptions_host.dart';
import '../editor/studio_team_chat_host.dart';
import '../premium/studio_feature.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'beginner_mode.dart';
import 'bots_page.dart';
import 'commands_page.dart';
import 'dashboard_page.dart';
import 'modules_page.dart';
import 'overview_page.dart';
import 'variables_page.dart';
import 'workflows_page.dart';
import 'copilot_page.dart';
import 'guilds_page.dart';

/// Coque connectée : accueil ou éditeur d'un bot. Jamais montrée sans session
/// valide.
///
/// Grand écran : rail latéral de 84 px. Téléphone (< 720 px) : barre du bas et
/// page « Modules » qui regroupe les onglets secondaires, comme l'app.
class StudioShell extends StatefulWidget {
  const StudioShell({super.key, required this.auth});

  final AuthController auth;

  @override
  State<StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<StudioShell> {
  final _beginner = BeginnerMode();

  /// Les applications hébergées : un seul hôte pour la vie de la coque (il garde
  /// l'état du serveur lu une fois — hébergement cloud coupé ou non).
  late final StudioSubscriptionsHost _subscriptions = StudioSubscriptionsHost(
    widget.auth.api,
  );
  late final StudioHostedContainersHost _hosted = StudioHostedContainersHost(
    widget.auth.api,
    subscriptions: _subscriptions,
  );
  StudioBot? _bot;
  String _homeSection = 'home';
  String _editorSection = 'overview';

  /// Téléphone : module ouvert depuis la page « Modules » (`null` = la liste).
  String? _module;

  @override
  void initState() {
    super.initState();
    _beginner.addListener(_onBeginnerChanged);
    _beginner.load();
  }

  @override
  void dispose() {
    _beginner.removeListener(_onBeginnerChanged);
    _beginner.dispose();
    super.dispose();
  }

  void _onBeginnerChanged() {
    if (!mounted) return;
    setState(() {
      // Un onglet masqué par le mode débutant ne doit pas rester affiché.
      if (!_beginner.isVisible(_editorSection) && _editorSection != 'modules') {
        _editorSection = 'overview';
      }
      if (_module != null && !_beginner.isVisible(_module!)) _module = null;
    });
  }

  @override
  Widget build(BuildContext context) => StudioSubscriptionsScope(
    host: _subscriptions,
    child: _buildShell(context),
  );

  Widget _buildShell(BuildContext context) {
    final bot = _bot;
    final compact = isCompact(context);
    final body = bot == null ? _homeBody() : _editorBody(bot, compact);
    if (compact) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (bot != null) _CompactHeader(bot: bot, onBack: _leaveBot),
              Expanded(child: body),
            ],
          ),
        ),
        bottomNavigationBar: bot == null
            ? FlatNavBar(
                items: _navItems(
                  _homeItems(context),
                  _homeSection,
                  (id) => setState(() => _homeSection = id),
                ),
              )
            : FlatNavBar(
                items: _navItems(
                  _compactEditorItems(context),
                  _editorSection,
                  (id) => setState(() {
                    _editorSection = id;
                    _module = null;
                  }),
                ),
              ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          if (bot == null) _homeRail() else _editorRail(bot),
          Expanded(child: body),
        ],
      ),
    );
  }

  void _leaveBot() => setState(() {
    _bot = null;
    _module = null;
  });

  // ── Accueil ───────────────────────────────────────────────────────────────

  List<_NavEntry> _homeItems(BuildContext context) => [
    _NavEntry('home', context.l10n.navHome, Icons.home_outlined),
    _NavEntry('hosting', context.l10n.navHosting, Icons.storage_rounded),
    _NavEntry('docs', context.l10n.navDocs, Icons.menu_book_outlined),
    _NavEntry('settings', context.l10n.navSettings, Icons.settings_outlined),
  ];

  Widget _homeRail() => FlatNavRail(
    leading: const Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: StudioLogo(),
    ),
    items: _navItems(
      _homeItems(context),
      _homeSection,
      (id) => setState(() => _homeSection = id),
    ),
  );

  /// Les entrées de navigation sous la forme que `FlatNavBar` / `FlatNavRail`
  /// (les mêmes que l'app) attendent.
  List<FloatingGlassNavItem> _navItems(
    List<_NavEntry> entries,
    String selected,
    ValueChanged<String> onSelect,
  ) => [
    for (final e in entries)
      FloatingGlassNavItem(
        icon: e.icon,
        label: e.label,
        selected: e.id == selected,
        onTap: () => onSelect(e.id),
      ),
  ];

  Widget _homeBody() {
    switch (_homeSection) {
      case 'settings':
        return _SettingsPage(auth: widget.auth);
      case 'docs':
        return const DocumentationHubPage(embedded: true);
      case 'hosting':
        return ContainerListPage(host: _hosted);
      default:
        return BotsPage(
          api: widget.auth.api,
          onOpenBot: (bot) => setState(() {
            _bot = bot;
            _editorSection = 'overview';
            _module = null;
          }),
        );
    }
  }

  // ── Éditeur de bot ────────────────────────────────────────────────────────

  List<_NavEntry?> _editorItems(BuildContext context) {
    final l = context.l10n;
    return [
      _NavEntry('back', l.navBack, Icons.arrow_back_rounded),
      null,
      _NavEntry('overview', l.navHome, Icons.dashboard_rounded),
      _NavEntry('copilot', l.navCopilot, Icons.auto_awesome_outlined),
      _NavEntry('commands', l.navCommands, Icons.terminal_rounded),
      null,
      _NavEntry('flows', l.navFlows, Icons.account_tree_outlined),
      _NavEntry('vars', l.navVars, Icons.data_object_rounded),
      _NavEntry('sched', l.navSched, Icons.schedule_rounded),
      _NavEntry('hooks', l.navHooks, Icons.webhook_rounded),
      _NavEntry('emojis', l.navEmojis, Icons.emoji_emotions_outlined),
      _NavEntry('team', l.navTeam, Icons.groups_outlined),
      _NavEntry('guilds', l.navGuilds, Icons.dns_outlined),
      null,
      _NavEntry('dash', l.navDashboard, Icons.bar_chart_rounded),
      _NavEntry('replay', l.navReplay, Icons.bug_report_outlined),
    ];
  }

  List<_NavEntry> _compactEditorItems(BuildContext context) {
    final l = context.l10n;
    return [
      _NavEntry('overview', l.navHome, Icons.dashboard_outlined),
      _NavEntry('commands', l.navCommandsShort, Icons.terminal_rounded),
      _NavEntry('modules', l.navModules, Icons.widgets_outlined),
      _NavEntry('settings', l.navSettings, Icons.settings_outlined),
    ];
  }

  /// Les entrées du rail, sans celles que le mode débutant masque, et sans
  /// séparateur orphelin (en tête, en queue ou doublé).
  List<_NavEntry?> _visibleRailItems() {
    final out = <_NavEntry?>[];
    for (final e in _editorItems(context)) {
      if (e == null) {
        if (out.isNotEmpty && out.last != null) out.add(null);
      } else if (e.id == 'back' || _beginner.isVisible(e.id)) {
        out.add(e);
      }
    }
    while (out.isNotEmpty && out.last == null) {
      out.removeLast();
    }
    return out;
  }

  Widget _editorRail(StudioBot bot) {
    final l = context.l10n;
    // Sections du rail de l'app : les séparateurs deviennent des sections.
    final sections = <EditorSidebarSection>[];
    var current = <EditorSidebarItem>[];
    for (final e in _visibleRailItems()) {
      if (e == null) {
        if (current.isNotEmpty) {
          sections.add(EditorSidebarSection(title: '', items: current));
        }
        current = [];
      } else if (e.id != 'back') {
        current.add(EditorSidebarItem(id: e.id, icon: e.icon, label: e.label));
      }
    }
    if (current.isNotEmpty) {
      sections.add(EditorSidebarSection(title: '', items: current));
    }
    return EditorRail(
      appName: bot.name,
      botId: bot.id,
      sections: sections,
      activeItemId: _editorSection,
      showBackButton: true,
      showBeginnerMode: true,
      beginnerMode: _beginner.enabled,
      onBeginnerModeChanged: _beginner.set,
      pinnedItem: EditorSidebarItem(
        id: 'settings',
        icon: Icons.settings_outlined,
        label: l.navSettings,
      ),
      onBack: _leaveBot,
      onSelectItem: (id) => setState(() => _editorSection = id),
    );
  }

  Widget _editorBody(StudioBot bot, bool compact) {
    if (compact && _editorSection == 'modules') {
      final open = _module;
      if (open == null) {
        return ModulesPage(
          botName: bot.name,
          beginner: _beginner,
          onOpen: (id) => setState(() => _module = id),
        );
      }
      return Column(
        children: [
          _ModuleBack(onBack: () => setState(() => _module = null)),
          Expanded(child: _sectionBody(bot, open)),
        ],
      );
    }
    return _sectionBody(bot, _editorSection);
  }

  Widget _sectionBody(StudioBot bot, String section) {
    final api = widget.auth.api;
    final plan = widget.auth.plan;
    switch (section) {
      case 'commands':
        return CommandsPage(
          key: ValueKey(bot.id),
          api: api,
          bot: bot,
          userId: widget.auth.session?.userId,
          userName: widget.auth.session?.username,
        );
      case 'overview':
        return OverviewPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'dash':
        return DashboardPage(
          key: ValueKey(bot.id),
          api: api,
          bot: bot,
          plan: plan,
        );
      case 'copilot':
        return CopilotPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'flows':
        return WorkflowsPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'vars':
        return VariablesPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'team':
        return TeamChatPage(
          key: ValueKey(bot.id),
          botId: bot.id,
          host: StudioTeamChatHost(
            api,
            userName: widget.auth.session?.username,
          ),
          // La barre de navigation du Studio est hors de la page.
          reserveNavBarClearance: false,
        );
      case 'replay':
        return DebugReplayPage(
          key: ValueKey('replay-${bot.id}'),
          botId: bot.id,
          host: StudioDebugReplayHost(api, plan: plan),
        );
      case 'guilds':
        return GuildsPage(
          key: ValueKey('guilds-${bot.id}'),
          api: api,
          bot: bot,
        );
      case 'emojis':
        return EmojisView(
          key: ValueKey('emojis-${bot.id}'),
          controller: StudioEmojisController(api: api, botId: bot.id),
        );
      case 'sched':
        return SchedulerView(
          key: ValueKey('sched-${bot.id}'),
          controller: StudioSchedulerController(
            api: api,
            botId: bot.id,
            available: StudioFeature.scheduler.isAvailableFor(plan),
          ),
        );
      case 'hooks':
        return InboundWebhooksView(
          key: ValueKey('hooks-${bot.id}'),
          controller: StudioInboundWebhooksController(
            api: api,
            botId: bot.id,
            available: StudioFeature.inboundWebhooks.isAvailableFor(plan),
          ),
        );
      default:
        return ComingSoon(title: _titleOf(section));
    }
  }

  String _titleOf(String id) {
    for (final e in _editorItems(context)) {
      if (e?.id == id) return e!.label;
    }
    return context.l10n.navSettings;
  }
}

/// En-tête du téléphone dans un bot : retour à la liste + nom du bot.
class _CompactHeader extends StatelessWidget {
  const _CompactHeader({required this.bot, required this.onBack});

  final StudioBot bot;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Row(
      children: [
        IconButton(
          tooltip: context.l10n.navBack,
          onPressed: onBack,
          icon: const AppIcon.fromMaterial(Icons.arrow_back_rounded, size: 20),
        ),
        Expanded(
          child: Text(
            bot.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 16),
      ],
    ),
  );
}

class _ModuleBack extends StatelessWidget {
  const _ModuleBack({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: TextButton.icon(
      onPressed: onBack,
      style: TextButton.styleFrom(foregroundColor: StudioColors.actionSoft),
      icon: const AppIcon.fromMaterial(Icons.chevron_left, size: 24),
      label: Text(
        context.l10n.navModules,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = auth.session?.username;
    final subscriptions = StudioSubscriptionsScope.maybeOf(context);
    return SingleChildScrollView(
      padding: pageInsets(context, top: 24),
      child: PageContent(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.settingsTitle,
              style: TextStyle(
                fontSize: isCompact(context) ? 24 : 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            _Card(
              title: l.accountTitle,
              children: [
                Text(
                  name == null ? l.accountSignedIn : l.accountSignedInAs(name),
                  style: const TextStyle(color: StudioColors.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.plan == StudioPlan.premium
                      ? l.accountPlanPremium
                      : l.accountPlanFree,
                  style: const TextStyle(color: StudioColors.muted),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: auth.signOut,
                  icon: const AppIcon.fromMaterial(Icons.logout, size: 16),
                  label: Text(l.accountSignOut),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // L'entrée « Abonnements et facturation » de l'app (même carte, même
            // hub) : formule, plafonds, couverture d'hébergement, crédits IA.
            if (subscriptions != null)
              SubscriptionsSettingsCard(
                host: subscriptions,
                onOpen: (context) =>
                    SubscriptionsHubPage.open(context, subscriptions),
              ),
            if (subscriptions != null) const SizedBox(height: 16),
            _Card(
              title: l.settingsLanguage,
              children: const [_LanguagePicker()],
            ),
            const SizedBox(height: 16),
            // La même carte « Apparence » que l'app (thèmes, couleurs, taille
            // du texte) ; le Studio reste sombre, donc sans choix de mode.
            const AppearanceSettingsSection(showModeSelector: false),
            const SizedBox(height: 16),
            const CodeEditorSettingsCard(),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: StudioColors.card,
      border: Border.all(color: StudioColors.cardBorder),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    ),
  );
}

/// Choix de la langue : « Système » (la langue du navigateur) ou l'une des six
/// langues, chacune écrite dans sa propre langue.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker();

  @override
  Widget build(BuildContext context) {
    final controller = LocaleScope.of(context);
    return DropdownButton<String>(
      value: controller.locale?.languageCode ?? '',
      isExpanded: true,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(value: '', child: Text(context.l10n.languageSystem)),
        for (final e in LocaleController.names.entries)
          DropdownMenuItem(value: e.key, child: Text(e.value)),
      ],
      onChanged: (code) =>
          controller.set(code == null || code.isEmpty ? null : Locale(code)),
    );
  }
}

/// Une entrée de navigation du Studio.
class _NavEntry {
  const _NavEntry(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}
