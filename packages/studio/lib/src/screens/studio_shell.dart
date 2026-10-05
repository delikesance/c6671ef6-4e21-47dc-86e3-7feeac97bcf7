import 'package:flutter/material.dart';

import '../api/studio_api.dart';
import '../auth/auth_controller.dart';
import '../auth/studio_session.dart';
import '../layout.dart';
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
                items: _homeItems,
                selectedId: _homeSection,
                onSelect: (id) => setState(() => _homeSection = id),
              )
            : StudioBottomBar(
                items: _compactEditorItems,
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

  static const _homeItems = [
    RailEntry('home', 'Accueil', Icons.home_outlined),
    RailEntry('docs', 'Documentation', Icons.menu_book_outlined),
    RailEntry('settings', 'Paramètres', Icons.settings_outlined),
  ];

  Widget _homeRail() => StudioRail(
    badge: const RailBadge(text: 'BC', color: StudioColors.action),
    itemHeight: 64,
    selectedId: _homeSection,
    onSelect: (id) => setState(() => _homeSection = id),
    items: _homeItems,
  );

  Widget _homeBody() {
    switch (_homeSection) {
      case 'settings':
        return _SettingsPage(auth: widget.auth);
      case 'docs':
        return const ComingSoon(title: 'Documentation');
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

  static const _editorItems = <RailEntry?>[
    RailEntry('back', 'Retour', Icons.arrow_back_rounded),
    null,
    RailEntry('overview', 'Accueil', Icons.dashboard_rounded),
    RailEntry('copilot', 'Copilote IA', Icons.auto_awesome_outlined),
    RailEntry('commands', 'Commandes', Icons.terminal_rounded),
    null,
    RailEntry('flows', 'Flux', Icons.account_tree_outlined),
    RailEntry('vars', 'Vars', Icons.data_object_rounded),
    RailEntry('sched', 'Planif', Icons.schedule_rounded),
    RailEntry('hooks', 'Webhooks entrants', Icons.webhook_rounded),
    RailEntry('emojis', 'Émojis', Icons.emoji_emotions_outlined),
    RailEntry('team', 'Équipe', Icons.groups_outlined),
    RailEntry('guilds', 'Serveurs', Icons.dns_outlined),
    null,
    RailEntry('dash', 'Tableau de bord', Icons.bar_chart_rounded),
  ];

  static const _compactEditorItems = [
    RailEntry('overview', 'Accueil', Icons.dashboard_outlined),
    RailEntry('commands', 'Cmd', Icons.terminal_rounded),
    RailEntry('modules', 'Modules', Icons.widgets_outlined),
    RailEntry('settings', 'Paramètres', Icons.settings_outlined),
  ];

  /// Les entrées du rail, sans celles que le mode débutant masque, et sans
  /// séparateur orphelin (en tête, en queue ou doublé).
  List<RailEntry?> _visibleRailItems() {
    final out = <RailEntry?>[];
    for (final e in _editorItems) {
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
    return StudioRail(
      badge: RailBadge(
        text: initials.toUpperCase(),
        color: const Color(0xFF38BDF8),
      ),
      selectedId: _editorSection,
      extraSelected: {if (_beginner.enabled) 'beginner'},
      items: _visibleRailItems(),
      bottomItems: const [
        RailEntry('beginner', 'Mode débutant', Icons.school_rounded),
        RailEntry('settings', 'Paramètres', Icons.settings_outlined),
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
      case 'vars':
        return VariablesPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'team':
        return TeamPage(key: ValueKey(bot.id), api: api, bot: bot);
      case 'sched':
        return _premiumSection('Planificateur', StudioFeature.scheduler, plan);
      case 'hooks':
        return _premiumSection(
          'Webhooks entrants',
          StudioFeature.inboundWebhooks,
          plan,
        );
      default:
        return ComingSoon(title: _titleOf(section));
    }
  }

  String _titleOf(String id) {
    for (final e in _editorItems) {
      if (e?.id == id) return e!.label;
    }
    return 'Paramètres';
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
              child: const Text(
                'Disponible bientôt dans le Studio.',
                style: TextStyle(color: StudioColors.muted),
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
          tooltip: 'Retour',
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
      label: const Text(
        'Modules',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final name = auth.session?.username;
    return SingleChildScrollView(
      padding: pageInsets(context, top: 24),
      child: PageContent(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paramètres',
              style: TextStyle(
                fontSize: isCompact(context) ? 24 : 28,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: StudioColors.card,
                border: Border.all(color: StudioColors.cardBorder),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compte',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name == null
                        ? 'Connecté avec Discord'
                        : 'Connecté avec Discord : $name',
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.plan == StudioPlan.premium
                        ? 'Formule Premium'
                        : "Formule gratuite : l'abonnement se gère depuis l'application mobile.",
                    style: const TextStyle(color: StudioColors.muted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: auth.signOut,
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Se déconnecter'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
