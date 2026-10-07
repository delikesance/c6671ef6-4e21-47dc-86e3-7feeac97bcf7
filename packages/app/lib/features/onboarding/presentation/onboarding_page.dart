import 'dart:async';

import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/core/analytics/activation_funnel.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/app_editor_page.dart';
import 'package:bot_creator/main.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

const double _onboardingContentMaxWidth = 560;
const double _onboardingWideBreakpoint = 900;
const int _onboardingVisibleSteps = 3;

/// Couleurs de l'onboarding : celles de l'accueil (graphite + un seul violet
/// d'action) en sombre, les rôles M3 du thème en clair. Le vert reste réservé à
/// l'état « en ligne » ; aucune couleur n'est inventée pour l'occasion.
class _OnbPalette {
  _OnbPalette(BuildContext context)
    : _dark = Theme.of(context).brightness == Brightness.dark,
      _scheme = Theme.of(context).colorScheme;

  final bool _dark;
  final ColorScheme _scheme;

  static const Color action = AppTheme.actionViolet;
  Color get onAction => Colors.white;
  Color get accentSoft =>
      _dark ? AppTheme.actionVioletSoft : AppTheme.actionViolet;
  Color get card => _dark ? AppTheme.homeCard : _scheme.surfaceContainerLow;
  Color get cardBorder =>
      _dark ? AppTheme.homeCardBorder : _scheme.outlineVariant;
  Color get tile =>
      _dark ? AppTheme.homeNavSelected : _scheme.surfaceContainerHighest;
  Color get note => _dark ? AppTheme.homeClusterBg : _scheme.surfaceContainer;
  Color get muted => _dark ? AppTheme.homeMuted : _scheme.onSurfaceVariant;
  Color get ghostBorder => _dark ? AppTheme.homeGhostBorder : _scheme.outline;
  Color get track => _dark ? const Color(0xFF2A2E3A) : _scheme.outlineVariant;
}

/// Une étape de l'onboarding : même squelette partout (progression, titre,
/// contenu, actions) pour que le parcours se lise comme le reste de l'app.
///
/// [step] vaut 1..3 pour les trois étapes numérotées, `null` pour l'accueil et
/// la fin, qui n'ont ni progression ni numéro.
class _OnboardingStepScaffold extends StatelessWidget {
  final int? step;
  final String title;
  final String? subtitle;
  final List<Widget> body;
  final Widget? leading;
  final List<Widget> actions;
  final VoidCallback? onRemindLater;
  final VoidCallback? onSkip;
  final bool centered;

  const _OnboardingStepScaffold({
    required this.title,
    required this.actions,
    this.step,
    this.subtitle,
    this.body = const [],
    this.leading,
    this.onRemindLater,
    this.onSkip,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= _onboardingWideBreakpoint;
    final showRail = wide && step != null;
    final content = _content(context);
    return Scaffold(
      body: SafeArea(
        child: showRail
            ? Row(
                children: [
                  _StepRail(step: step!, onSkip: onSkip),
                  Expanded(child: _centered(content)),
                ],
              )
            : _centered(content),
      ),
    );
  }

  Widget _centered(Widget child) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _onboardingContentMaxWidth),
      child: child,
    ),
  );

  Widget _content(BuildContext context) {
    final palette = _OnbPalette(context);
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= _onboardingWideBreakpoint;
    final showProgress = step != null && !wide;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showProgress)
            _ProgressHeader(
              step: step!,
              palette: palette,
              onRemindLater: onRemindLater,
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: centered
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  if (centered) const SizedBox(height: AppTheme.spacingXxl),
                  if (leading != null) ...[
                    Align(alignment: Alignment.centerLeft, child: leading),
                    const SizedBox(height: AppTheme.spacingXl),
                  ] else
                    const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: palette.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                  for (final widget in body) ...[
                    const SizedBox(height: AppTheme.spacingXl),
                    widget,
                  ],
                  const SizedBox(height: AppTheme.spacingXl),
                ],
              ),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(height: AppTheme.spacingSm),
            actions[i],
          ],
        ],
      ),
    );
  }
}

/// Barre segmentée + « Étape N sur 3 » + report : l'en-tête des étapes
/// numérotées, à la place de la barre d'application Material.
class _ProgressHeader extends StatelessWidget {
  final int step;
  final _OnbPalette palette;
  final VoidCallback? onRemindLater;

  const _ProgressHeader({
    required this.step,
    required this.palette,
    required this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 1; i <= _onboardingVisibleSteps; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: AppTheme.animNormal,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= step ? _OnbPalette.action : palette.track,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                ),
              ),
            ],
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                context.tr.onboarding_step_indicator(
                  step,
                  _onboardingVisibleSteps,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: palette.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRemindLater != null)
              TextButton(
                onPressed: onRemindLater,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: palette.muted,
                ),
                child: Text(context.tr.onboarding_remind_later),
              ),
          ],
        ),
      ],
    );
  }
}

/// Colonne d'étapes des grands écrans : même rôle que la barre segmentée, sans
/// laisser le contenu flotter au milieu d'un écran vide.
class _StepRail extends StatelessWidget {
  final int step;
  final VoidCallback? onSkip;

  const _StepRail({required this.step, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    final labels = <String>[
      context.tr.onboarding_create_desc,
      context.tr.onboarding_command_desc,
      context.tr.onboarding_start_desc,
    ];
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(24, 32, 16, 24),
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: palette.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(
                icon: Icons.smart_toy_rounded,
                size: 40,
                palette: palette,
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Text(
                context.tr.app_title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXxl * 1.5),
          for (var i = 1; i <= labels.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: i == step ? palette.tile : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(
                  color: i == step ? palette.cardBorder : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  _NumberBadge(
                    number: i,
                    palette: palette,
                    filled: i == step,
                    done: i < step,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      labels[i - 1],
                      style: TextStyle(
                        fontWeight: i == step
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: i == step ? null : palette.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          if (onSkip != null)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                foregroundColor: palette.muted,
              ),
              child: Text(context.tr.onboarding_skip_confirm),
            ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final _OnbPalette palette;
  final Color? color;

  const _IconTile({
    required this.icon,
    required this.palette,
    this.size = 72,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: palette.tile,
        borderRadius: BorderRadius.circular(size / 3),
        border: Border.all(color: palette.cardBorder),
      ),
      child: AppIcon.fromMaterial(
        icon,
        size: size / 2,
        color: color ?? palette.accentSoft,
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;
  final _OnbPalette palette;
  final bool filled;
  final bool done;

  const _NumberBadge({
    required this.number,
    required this.palette,
    this.filled = false,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? _OnbPalette.action : palette.tile,
        border: filled ? null : Border.all(color: palette.cardBorder),
      ),
      child: done
          ? AppIcon.fromMaterial(
              Icons.check_rounded,
              size: 16,
              color: palette.accentSoft,
            )
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? Colors.white : palette.accentSoft,
              ),
            ),
    );
  }
}

/// Carte graphite à bordure fine, comme les cartes de l'accueil.
class _OnbCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const _OnbCard({required this.children, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: palette.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

/// Liste numérotée dans une carte : les étapes d'un pas à pas.
class _NumberedList extends StatelessWidget {
  final List<String> items;

  const _NumberedList({required this.items});

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    return _OnbCard(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(height: 1, thickness: 1, color: palette.cardBorder),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                _NumberBadge(number: i + 1, palette: palette),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(child: Text(items[i])),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Information discrète (jeton, indication) : surface neutre et texte
/// secondaire, jamais une couleur d'alerte.
class _OnbNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? extra;

  const _OnbNote({required this.icon, required this.text, this.extra});

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.note,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: AppIcon.fromMaterial(icon, size: 20, color: palette.muted),
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: palette.muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                if (extra != null) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    extra!,
                    style: TextStyle(
                      color: palette.muted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// L'unique action principale de l'écran : violet d'action, texte blanc.
class _PrimaryAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _PrimaryAction({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: _OnbPalette.action,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? trailingIcon;

  const _SecondaryAction({
    required this.label,
    required this.onPressed,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        side: BorderSide(color: palette.ghostBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Text(label, textAlign: TextAlign.center)),
          if (trailingIcon != null) ...[
            const SizedBox(width: AppTheme.spacingSm),
            AppIcon.fromMaterial(trailingIcon!, size: 16, color: palette.muted),
          ],
        ],
      ),
    );
  }
}

/// Action tertiaire : un lien, jamais un bouton plein.
class _LinkAction extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool muted;

  const _LinkAction({
    required this.label,
    required this.onPressed,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(88, 44),
        foregroundColor: muted ? palette.muted : palette.accentSoft,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

/// Retire le numéro « 1. » d'un texte déjà numéroté par la traduction : la
/// numérotation est dessinée par l'interface, pas par la chaîne.
List<String> _splitSteps(String text) => [
  for (final line in text.split('\n'))
    if (line.trim().isNotEmpty)
      line.trim().replaceFirst(RegExp(r'^\d+[.)]\s*'), ''),
];

/// Root onboarding flow - presents 5 steps to guide new users through first bot creation
class OnboardingPage extends StatefulWidget {
  /// Called when onboarding is completed or skipped
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late OnboardingManager _manager;
  late PageController _pageController;
  int _currentStep = 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializeManager();
    AppAnalytics.logEvent(name: 'onboarding_started');
  }

  Future<void> _initializeManager() async {
    final prefs = await SharedPreferences.getInstance();
    _manager = OnboardingManager(prefs);
    setState(() {
      _currentStep = _manager.currentStep;
    });
    unawaited(ActivationFunnel.onboardingStepView(step: _currentStep));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    _manager.setCurrentStep(step);
    setState(() => _currentStep = step);
    unawaited(ActivationFunnel.onboardingStepView(step: step));
  }

  void _nextStep() {
    if (_currentStep < 5) {
      _goToStep(_currentStep + 1);
    }
  }

  // ── F7: Interactive onboarding actions ─────────────────────────────────────

  /// Count bots before navigation so we can detect creation on return.
  int _botCountBefore = 0;

  /// Navigate to the bot creation page. When the user returns, if a new bot
  /// was created, auto-advance to step 3.
  Future<void> _createBotNow() async {
    _botCountBefore = (await appManager.getAllApps()).length;
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AppCreatePage()));
    if (!mounted) return;
    final botCountAfter = (await appManager.getAllApps()).length;
    if (botCountAfter > _botCountBefore) {
      AppAnalytics.logEvent(name: 'onboarding_bot_created');
      // Auto-advance to step 3 (Add Command)
      if (_currentStep < 3) {
        _goToStep(3);
      }
    }
  }

  /// Navigate to the most recently created bot's editor so the user can add
  /// a command. When they return, auto-advance to step 4.
  Future<void> _addCommandNow() async {
    final apps = await appManager.getAllApps();
    if (apps.isEmpty) return;

    final latest = apps.last as Map<String, dynamic>;
    final botIdStr = (latest['id'] ?? latest['appId'] ?? '').toString();
    final botName = (latest['name'] ?? 'Bot').toString();
    final botId = int.tryParse(botIdStr);
    if (botId == null) return;

    final commandsBefore = await appManager.listAppCommands(botIdStr);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppEditPage(
          appName: botName,
          id: botId,
          avatarUrl: latest['avatar']?.toString(),
        ),
      ),
    );
    if (!mounted) return;
    final commandsAfter = await appManager.listAppCommands(botIdStr);
    if (commandsAfter.length > commandsBefore.length) {
      AppAnalytics.logEvent(name: 'onboarding_command_created');
      if (_currentStep < 4) {
        _goToStep(4);
      }
    }
  }

  void _skipOnboarding() async {
    await _manager.skipOnboarding();
    AppAnalytics.logEvent(
      name: 'onboarding_skipped',
      parameters: {'step': _currentStep.toString()},
    );
    if (mounted) {
      widget.onComplete();
    }
  }

  /// Postpone onboarding but remember where the user left off so it can resume
  /// later (unlike skip, which marks onboarding as completed/skipped).
  void _remindLater() async {
    await _manager.setCurrentStep(_currentStep);
    AppAnalytics.logEvent(
      name: 'onboarding_remind_later',
      parameters: {'step': _currentStep.toString()},
    );
    if (mounted) {
      widget.onComplete();
    }
  }

  void _completeOnboarding() async {
    await _manager.completeOnboarding();
    unawaited(ActivationFunnel.onboardingCompleted(finalStep: _currentStep));
    if (mounted) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe, use buttons only
        children: [
          _WelcomeStep(onNext: _nextStep, onSkip: _skipOnboarding),
          _CreateBotStep(
            currentStep: 2,
            onNext: _nextStep,
            onSkip: _skipOnboarding,
            onRemindLater: _remindLater,
            onCreateBot: _createBotNow,
          ),
          _AddCommandStep(
            currentStep: 3,
            onNext: _nextStep,
            onSkip: _skipOnboarding,
            onRemindLater: _remindLater,
            onAddCommand: _addCommandNow,
          ),
          _StartBotStep(
            currentStep: 4,
            onNext: _nextStep,
            onSkip: _skipOnboarding,
            onRemindLater: _remindLater,
          ),
          _SuccessStep(onDone: _completeOnboarding, currentStep: 5),
        ],
      ),
      extendBody: true,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Accueil
// ═════════════════════════════════════════════════════════════════════════════

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _WelcomeStep({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    return _OnboardingStepScaffold(
      centered: true,
      leading: _IconTile(icon: Icons.smart_toy_rounded, palette: palette),
      title: context.tr.onboarding_welcome_title,
      subtitle: context.tr.onboarding_welcome_desc,
      body: [
        _OnbCard(
          children: [
            for (final entry in [
              context.tr.onboarding_create_desc,
              context.tr.onboarding_command_desc,
              context.tr.onboarding_start_desc,
            ].indexed) ...[
              if (entry.$1 > 0)
                Divider(height: 1, thickness: 1, color: palette.cardBorder),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    _NumberBadge(number: entry.$1 + 1, palette: palette),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
      actions: [
        _PrimaryAction(
          label: context.tr.onboarding_welcome_start,
          onPressed: onNext,
        ),
        _LinkAction(
          label: context.tr.onboarding_welcome_skip,
          onPressed: onSkip,
          muted: true,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Étape 1 : jeton Discord
// ═════════════════════════════════════════════════════════════════════════════

class _CreateBotStep extends StatelessWidget {
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onRemindLater;
  final VoidCallback onCreateBot;

  const _CreateBotStep({
    required this.currentStep,
    required this.onNext,
    required this.onSkip,
    required this.onRemindLater,
    required this.onCreateBot,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingStepScaffold(
      step: currentStep - 1,
      onRemindLater: onRemindLater,
      onSkip: onSkip,
      title: context.tr.onboarding_create_desc,
      body: [
        _NumberedList(items: _splitSteps(context.tr.onboarding_create_steps)),
        _OnbNote(
          icon: Icons.lock_outline_rounded,
          text: context.tr.onboarding_create_tip,
        ),
      ],
      actions: [
        _PrimaryAction(
          label: context.tr.onboarding_create_now,
          onPressed: onCreateBot,
        ),
        _SecondaryAction(
          label: context.tr.onboarding_create_open_portal,
          trailingIcon: Icons.open_in_new_rounded,
          onPressed: () async {
            await launchUrl(
              Uri.parse('https://discord.com/developers/applications'),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
        Row(
          children: [
            Expanded(
              child: _LinkAction(
                label: context.tr.onboarding_create_tutorial,
                onPressed: () => openDocumentationArticle(
                  context,
                  url: botTokenTutorialUrl,
                  title: context.tr.onboarding_create_tutorial,
                ),
              ),
            ),
            Expanded(
              child: _LinkAction(
                label: context.tr.onboarding_create_button,
                onPressed: onNext,
                muted: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Étape 2 : première commande
// ═════════════════════════════════════════════════════════════════════════════

class _AddCommandStep extends StatelessWidget {
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onRemindLater;
  final VoidCallback onAddCommand;

  const _AddCommandStep({
    required this.currentStep,
    required this.onNext,
    required this.onSkip,
    required this.onRemindLater,
    required this.onAddCommand,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    // La chaîne d'exemple est « Exemple :\n/hello → réponse » : l'étiquette est
    // déjà fournie à part, on n'affiche que la ligne de l'exemple.
    final exampleLines = context.tr.onboarding_command_example
        .split('\n')
        .skip(1)
        .join('\n')
        .trim();
    return _OnboardingStepScaffold(
      step: currentStep - 1,
      onRemindLater: onRemindLater,
      onSkip: onSkip,
      title: context.tr.onboarding_command_desc,
      subtitle: context.tr.onboarding_command_text,
      body: [
        _OnbCard(
          padding: const EdgeInsets.all(18),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr.onb_example_label.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: palette.muted,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd + 2),
                border: Border.all(color: palette.cardBorder),
              ),
              child: Text(
                exampleLines,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  height: 1.5,
                  color: palette.accentSoft,
                ),
              ),
            ),
          ],
        ),
      ],
      actions: [
        _PrimaryAction(
          label: context.tr.onboarding_command_now,
          onPressed: onAddCommand,
        ),
        _LinkAction(
          label: context.tr.onboarding_command_button,
          onPressed: onNext,
          muted: true,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Étape 3 : démarrer le bot
// ═════════════════════════════════════════════════════════════════════════════

class _StartBotStep extends StatelessWidget {
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback onRemindLater;

  const _StartBotStep({
    required this.currentStep,
    required this.onNext,
    required this.onSkip,
    required this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    return _OnboardingStepScaffold(
      step: currentStep - 1,
      onRemindLater: onRemindLater,
      onSkip: onSkip,
      title: context.tr.onboarding_start_desc,
      subtitle: context.tr.onboarding_start_text,
      body: [
        _OnbNote(
          icon: Icons.info_outline_rounded,
          text: context.tr.onboarding_start_tip,
          extra: context.tr.onboarding_start_hint,
        ),
      ],
      actions: [
        _PrimaryAction(
          label: context.tr.onboarding_start_button,
          onPressed: onNext,
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Fin
// ═════════════════════════════════════════════════════════════════════════════

class _SuccessStep extends StatelessWidget {
  final VoidCallback onDone;
  final int currentStep;

  const _SuccessStep({required this.onDone, this.currentStep = 5});

  @override
  Widget build(BuildContext context) {
    final palette = _OnbPalette(context);
    final tips = <(IconData, String)>[
      (Icons.terminal_rounded, context.tr.onboarding_success_tip1),
      (Icons.account_tree_outlined, context.tr.onboarding_success_tip2),
      (Icons.cloud_upload_outlined, context.tr.onboarding_success_tip3),
    ];
    return _OnboardingStepScaffold(
      centered: true,
      // Le vert signale un état réussi, comme le « en ligne » de l'accueil.
      leading: _IconTile(
        icon: Icons.check_rounded,
        palette: palette,
        color: AppTheme.statusOnline,
      ),
      title: context.tr.onboarding_success_title,
      subtitle: context.tr.onboarding_success_desc,
      body: [
        Text(
          context.tr.onboarding_success_whatsnext,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        _OnbCard(
          children: [
            for (final entry in tips.indexed) ...[
              if (entry.$1 > 0)
                Divider(height: 1, thickness: 1, color: palette.cardBorder),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    _IconTile(icon: entry.$2.$1, size: 36, palette: palette),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        entry.$2.$2,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
      actions: [
        _PrimaryAction(
          label: context.tr.onboarding_success_button,
          onPressed: onDone,
        ),
      ],
    );
  }
}
