import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../auth/auth_controller.dart';
import '../auth/studio_session.dart';
import '../l10n_ext.dart';
import '../layout.dart';
import '../locale_controller.dart';
import '../premium/premium_gate.dart';
import '../premium/studio_feature.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/studio_bottom_bar.dart';
import '../widgets/studio_rail.dart';
import 'beginner_mode.dart';
import 'bots_page.dart';
import 'commands_page.dart';
import 'dashboard_page.dart';
import 'modules_page.dart';
import 'overview_page.dart';
import 'team_page.dart';
import 'variables_page.dart';
import 'workflows_page.dart';
import 'copilot_page.dart';

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
  Widget build(BuildContext context) {
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
            ? StudioBottomBar(
                items: _homeItems(context),
                selectedId: _homeSection,
                onSelect: (id) => setState(() => _homeSection = id),
              )
            : StudioBottomBar(
                items: _compactEditorItems(context),
                selectedId: _editorSection,
                onSelect: (id) => setState(() {
                  _editorSection = id;
                  _module = null;
                }),
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

  List<RailEntry> _homeItems(BuildContext context) => [
    RailEntry('home', context.l10n.navHome, Icons.home_outlined),
    RailEntry('docs', context.l10n.navDocs, Icons.menu_book_outlined),
    RailEntry('settings', context.l10n.navSettings, Icons.settings_outlined),
  ];

  Widget _homeRail() => StudioRail(
    badge: const StudioLogo(),
    itemHeight: 64,
    selectedId: _homeSection,
    onSelect: (id) => setState(() => _homeSection = id),
    items: _homeItems(context),
  );

  Widget _homeBody() {
    switch (_homeSection) {
      case 'settings':
        return _SettingsPage(auth: widget.auth);
      case 'docs':
        return ComingSoon(title: context.l10n.navDocs);
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

  List<RailEntry?> _editorItems(BuildContext context) {
    final l = context.l10n;
    return [
      RailEntry('back', l.navBack, Icons.arrow_back_rounded),
      null,
      RailEntry('overview', l.navHome, Icons.dashboard_rounded),
      RailEntry('copilot', l.navCopilot, Icons.auto_awesome_outlined),
      RailEntry('commands', l.navCommands, Icons.terminal_rounded),
      null,
      RailEntry('flows', l.navFlows, Icons.account_tree_outlined),
      RailEntry('vars', l.navVars, Icons.data_object_rounded),
      RailEntry('sched', l.navSched, Icons.schedule_rounded),
      RailEntry('hooks', l.navHooks, Icons.webhook_rounded),
      RailEntry('emojis', l.navEmojis, Icons.emoji_emotions_outlined),
      RailEntry('team', l.navTeam, Icons.groups_outlined),
      RailEntry('guilds', l.navGuilds, Icons.dns_outlined),
      null,
      RailEntry('dash', l.navDashboard, Icons.bar_chart_rounded),
    ];
  }

  List<RailEntry> _compactEditorItems(BuildContext context) {
    final l = context.l10n;
    return [
      RailEntry('overview', l.navHome, Icons.dashboard_outlined),
      RailEntry('commands', l.navCommandsShort, Icons.terminal_rounded),
      RailEntry('modules', l.navModules, Icons.widgets_outlined),
      RailEntry('settings', l.navSettings, Icons.settings_outlined),
    ];
  }

  /// Les entrées du rail, sans celles que le mode débutant masque, et sans
  /// séparateur orphelin (en tête, en queue ou doublé).
  List<RailEntry?> _visibleRailItems() {
    final out = <RailEntry?>[];
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
    final trimmed = bot.name.trim();
    final initials = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, trimmed.length >= 2 ? 2 : 1);
    final l = context.l10n;
    return StudioRail(
      badge: RailBadge(
        text: initials.toUpperCase(),
        color: const Color(0xFF38BDF8),
      ),
      selectedId: _editorSection,
      extraSelected: {if (_beginner.enabled) 'beginner'},
      items: _visibleRailItems(),
      bottomItems: [
        RailEntry('beginner', l.navBeginner, Icons.school_rounded),
        RailEntry('settings', l.navSettings, Icons.settings_outlined),
      ],
      onSelect: (id) {
        if (id == 'beginner') {
          _beginner.set(!_beginner.enabled);
        } else if (id == 'back') {
          _leaveBot();
        } else {
          setState(() => _editorSection = id);
        }
      },
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
        return CommandsPage(key: ValueKey(bot.id), api: api, bot: bot);
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
        return TeamPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'sched':
        return _premiumSection(
          context.l10n.modulesScheduler,
          StudioFeature.scheduler,
          plan,
        );
      case 'hooks':
        return _premiumSection(
          context.l10n.navHooks,
          StudioFeature.inboundWebhooks,
          plan,
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

  Widget _premiumSection(String title, StudioFeature feature, StudioPlan plan) {
    return Padding(
      padding: pageInsets(context),
      child: PageContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            PremiumGate(
              feature: feature,
              plan: plan,
              child: Text(
                context.l10n.comingSoonShort,
                style: const TextStyle(color: StudioColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
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
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
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
      icon: const Icon(Icons.chevron_left_rounded, size: 24),
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
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(l.accountSignOut),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _Card(
              title: l.settingsLanguage,
              children: const [_LanguagePicker()],
            ),
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
