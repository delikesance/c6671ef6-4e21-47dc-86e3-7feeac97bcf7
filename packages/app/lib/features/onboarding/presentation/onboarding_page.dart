import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/app_editor_page.dart';
import 'package:bot_creator/main.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

const double _onboardingContentMaxWidth = 560;

class _OnboardingScrollableSection extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const _OnboardingScrollableSection({
    required this.padding,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : _onboardingContentMaxWidth;
        final contentWidth = availableWidth > _onboardingContentMaxWidth
            ? _onboardingContentMaxWidth
            : availableWidth;

        return Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: padding,
              child: SizedBox(width: contentWidth, child: child),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingBottomAction extends StatelessWidget {
  final Widget child;

  const _OnboardingBottomAction({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Align(
          alignment: Alignment.center,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: _onboardingContentMaxWidth,
            ),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}

/// Shows a "Step X of Y" label followed by a row of dots. The dot for the
/// current step is wider and uses the brand color; the others are muted grey.
class _StepProgressIndicator extends StatelessWidget {
  final int currentStep;

  const _StepProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const totalSteps = 5;
    // L'étape courante est un état sélectionné. Elle suivait `brandPrimary` en
    // clair et `brandPurpleSoft` en sombre : c'était l'accent violet historique,
    // désormais retiré de l'interface (voir `AppTheme.darkTheme`). L'indicateur
    // suit donc l'accent M3 neutre du thème, dont la paire `on*` est correcte
    // par construction.
    final activeColor = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr.onboarding_step_indicator(currentStep, totalSteps),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.grey),
        ),
        SizedBox(height: AppTheme.spacingSm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep - 1;
            return Padding(
              padding: EdgeInsets.only(
                right: index == totalSteps - 1 ? 0 : AppTheme.spacingXs,
              ),
              child: AnimatedContainer(
                duration: AppTheme.animNormal,
                width: isActive ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: isActive
                      ? activeColor
                      : AppTheme.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

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
        builder: (_) => AppEditPage(appName: botName, id: botId),
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
    AppAnalytics.logEvent(
      name: 'onboarding_completed',
      parameters: {'final_step': _currentStep.toString()},
    );
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
// Step 1: Welcome
// ═════════════════════════════════════════════════════════════════════════════

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _WelcomeStep({required this.onNext, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: _OnboardingScrollableSection(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  // Tuile décorative : neutre du thème (le violet n'est plus
                  // qu'un accent, réservé au CTA ci-dessous et à la pastille
                  // d'étape courante).
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(
                  Icons.smart_toy_rounded,
                  size: 60,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr.onboarding_welcome_title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.onboarding_welcome_desc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    context.tr.onboarding_welcome_start,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onSkip,
                  child: Text(context.tr.onboarding_welcome_skip),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Step 2: Create Bot
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr.onboarding_create_title),
        actions: [
          TextButton(
            onPressed: onRemindLater,
            child: Text(context.tr.onboarding_remind_later),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(context.tr.onboarding_welcome_skip),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _OnboardingScrollableSection(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepProgressIndicator(currentStep: currentStep),
              SizedBox(height: AppTheme.spacingXxl),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.key_rounded,
                  size: 50,
                  color: AppTheme.info,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr.onboarding_create_desc,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.onboarding_create_steps,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.premiumGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.premiumGold.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  context.tr.onboarding_create_tip,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(context.tr.onboarding_create_tutorial),
                  onPressed: () => openDocumentationArticle(
                    context,
                    url: botTokenTutorialUrl,
                    title: context.tr.onboarding_create_tutorial,
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCreateBot,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.success,
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    context.tr.onboarding_create_now,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.open_in_browser),
                  label: Text(context.tr.onboarding_create_open_portal),
                  onPressed: () async {
                    await launchUrl(
                      Uri.parse('https://discord.com/developers/applications'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _OnboardingBottomAction(
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            context.tr.onboarding_create_button,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Step 3: Add Command
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr.onboarding_command_title),
        actions: [
          TextButton(
            onPressed: onRemindLater,
            child: Text(context.tr.onboarding_remind_later),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(context.tr.onboarding_welcome_skip),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _OnboardingScrollableSection(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepProgressIndicator(currentStep: currentStep),
              SizedBox(height: AppTheme.spacingXxl),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.terminal_rounded,
                  size: 50,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr.onboarding_command_desc,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.onboarding_command_text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exemple:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr.onboarding_command_example,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddCommand,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.success,
                  ),
                  icon: const Icon(Icons.terminal),
                  label: Text(
                    context.tr.onboarding_command_now,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _OnboardingBottomAction(
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            context.tr.onboarding_command_button,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Step 4: Start Bot
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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.tr.onboarding_start_title),
        actions: [
          TextButton(
            onPressed: onRemindLater,
            child: Text(context.tr.onboarding_remind_later),
          ),
          TextButton(
            onPressed: onSkip,
            child: Text(context.tr.onboarding_welcome_skip),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _OnboardingScrollableSection(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepProgressIndicator(currentStep: currentStep),
              SizedBox(height: AppTheme.spacingXxl),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.play_circle_outline_rounded,
                  size: 50,
                  color: AppTheme.warning,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr.onboarding_start_desc,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.onboarding_start_text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: AppTheme.success.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.onboarding_start_tip,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      context.tr.onboarding_start_hint,
                      style: TextStyle(fontSize: 13, color: AppTheme.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _OnboardingBottomAction(
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: Text(
            context.tr.onboarding_start_button,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Step 5: Success
// ═════════════════════════════════════════════════════════════════════════════

class _SuccessStep extends StatelessWidget {
  final VoidCallback onDone;
  final int currentStep;

  const _SuccessStep({required this.onDone, this.currentStep = 5});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _OnboardingScrollableSection(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepProgressIndicator(currentStep: currentStep),
              SizedBox(height: AppTheme.spacingXxl),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 70,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                context.tr.onboarding_success_title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.onboarding_success_desc,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.onboarding_success_whatsnext,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  _TipRow(
                    icon: Icons.auto_fix_high,
                    title: context.tr.onboarding_success_tip1,
                  ),
                  _TipRow(
                    icon: Icons.workspaces,
                    title: context.tr.onboarding_success_tip2,
                  ),
                  _TipRow(
                    icon: Icons.backup,
                    title: context.tr.onboarding_success_tip3,
                  ),
                ],
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onDone,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    context.tr.onboarding_success_button,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String title;

  const _TipRow({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title)),
        ],
      ),
    );
  }
}
