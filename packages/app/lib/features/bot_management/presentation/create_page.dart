import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/analytics/activation_funnel.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/analytics/user_properties.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:developer' as developer;
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';

class AppCreatePage extends StatefulWidget {
  const AppCreatePage({super.key});

  @override
  State<AppCreatePage> createState() => _AppCreatePageState();
}

class _AppCreatePageState extends State<AppCreatePage> {
  String _token = "";
  bool _isSaving = false;
  bool _obscureToken = true;
  final _tokenController = TextEditingController();
  bool _createJavascriptBot = false;

  @override
  void initState() {
    super.initState();
    // Log the opening of the create app page
    AppAnalytics.logScreenView(
      screenName: "AppCreatePage",
      screenClass: "AppCreatePage",
    );
  }

  Future<void> _openExternalPage(String url) async {
    final uri = Uri.parse(url);

    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && mounted) {
        _showErrorDialog(context.tr.app_open_link_error);
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showErrorDialog(String message) {
    final dialog = AlertDialog(
      title: Text(context.tr.error),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.tr.ok),
        ),
      ],
    );

    showDialog(context: context, builder: (_) => dialog);
  }

  void _showTokenErrorDialog() {
    final dialog = AlertDialog(
      title: Row(
        children: [
          const AppIcon.fromMaterial(
            Icons.vpn_key_off_rounded,
            color: Colors.orange,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr.app_token_invalid_title)),
        ],
      ),
      content: Text(context.tr.app_token_invalid_content),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.tr.ok),
        ),
      ],
    );

    showDialog(context: context, builder: (_) => dialog);
  }

  Future<void> _saveBot() async {
    final token = _token.trim();
    if (_isSaving || token.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    // The token passed the guards and the flow starts here: the exchange, the
    // Discord identity fetch and the local write all follow.
    unawaited(ActivationFunnel.botCreateStart(source: BotCreateSource.scratch));

    try {
      final discordUser = await getDiscordUser(token);

      // Check if bot is already known to the manager.
      final apiConfig = await MainApiSettingsStore.loadConfig();
      if (apiConfig.isConfigured) {
        final client = MainApiClient(baseUrl: apiConfig.baseUrl);
        try {
          final session = await client.exchangeDiscordBotToken(botToken: token);
          final currentSession = await MainApiSettingsStore.loadSession();
          final isDiscordSession = currentSession?.refreshToken != null;

          if (!isDiscordSession) {
            // Not logged in via Discord, but the bot is in the manager.
            // We list bots just to confirm the manager has data for this owner.
            await client.withAccessToken(session.accessToken).listBots();
            if (mounted) {
              final proceed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(context.tr.app_sync_manager_title),
                  content: Text(context.tr.app_sync_manager_desc),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.tr.app_sync_manager_manual),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(context.tr.app_sync_manager_connect),
                    ),
                  ],
                ),
              );

              if (proceed == true) {
                // Trigger Discord OAuth
                if (mounted) {
                  Navigator.pushNamed(
                    context,
                    '/settings',
                    arguments: {'triggerDiscordAuth': true},
                  );
                  return;
                }
              }
            }
          }
        } catch (_) {
          // Manager doesn't know this bot or exchange failed, proceed normally.
        }
      }

      await appManager.createOrUpdateApp(
        id: discordUser.id,
        username: discordUser.username,
        avatarHash: discordUser.avatarHash,
        discriminator: discordUser.discriminator,
        token: token,
      );
      if (_createJavascriptBot) {
        await setBotRuntimeEngine(
          discordUser.id.toString(),
          runtimeEngineJavascript,
        );
      }
      await AppAnalytics.logEvent(
        name: "create_app",
        parameters: {
          "app_name": discordUser.username as Object,
          "app_id": discordUser.id.toString() as Object,
        },
      );
      // The bot exists locally now (createOrUpdateApp returned): this is the
      // funnel's bot_create_success point, and the bot count bucket the user
      // properties carry has just changed.
      unawaited(
        ActivationFunnel.botCreateSuccess(source: BotCreateSource.scratch),
      );
      unawaited(AppUserProperties.refresh());

      if (mounted) {
        await _offerSampleCommand(
          discordUser.id.toString(),
          discordUser.username,
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      developer.log("Error creating app: $e", name: "AppCreatePage");
      if (mounted) {
        final errorString = e.toString();
        // Detect invalid token (401 Unauthorized from Discord)
        final isInvalidToken =
            errorString.contains('401') ||
            errorString.contains('Unauthorized') ||
            errorString.contains('authorized');
        if (isInvalidToken) {
          _showTokenErrorDialog();
        } else {
          _showErrorDialog(errorString);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// Offers the user a chance to create a sample /ping command for their new bot.
  Future<void> _offerSampleCommand(String botId, String botName) async {
    if (!mounted) return;
    final createSample = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            AppIcon.fromMaterial(
              Icons.smart_toy_rounded,
              color: Theme.of(ctx).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(context.tr.app_create_sample_title)),
          ],
        ),
        content: Text(context.tr.app_create_sample_desc(botName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.app_create_sample_skip),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const AppIcon.fromMaterial(
              Icons.add_circle_outline_rounded,
              size: 18,
            ),
            label: Text(context.tr.app_create_sample_confirm),
          ),
        ],
      ),
    );

    if (createSample != true || !mounted) return;

    try {
      final sampleCommand = _buildSamplePingCommand(
        javascript: _createJavascriptBot,
      );
      final commandId = sampleCommand['id'] as String;
      await appManager.saveAppCommand(botId, commandId, sampleCommand);

      await AppAnalytics.logEvent(
        name: "create_sample_command",
        parameters: {"bot_id": botId as Object, "command_name": "ping"},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.app_create_sample_success),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      developer.log('Error creating sample command: $e', name: 'AppCreatePage');
    }
  }

  /// Builds the data payload for a sample /ping command with a "Pong!" response.
  Map<String, dynamic> _buildSamplePingCommand({bool javascript = false}) {
    final now = DateTime.now().toIso8601String();
    final internalId = 'sample_ping_${DateTime.now().millisecondsSinceEpoch}';
    return <String, dynamic>{
      'name': 'ping',
      'description': 'Check if the bot is responsive',
      'type': 'chatInput',
      'id': internalId,
      'createdAt': now,
      'updatedAt': now,
      'data': <String, dynamic>{
        'version': 1,
        'commandType': 'chatInput',
        'editorMode': 'advanced',
        'executionMode': javascript ? 'javascript' : 'workflow',
        'bdfdScriptContent': '',
        'jsScriptContent': javascript
            ? 'await interaction.reply("Pong!");'
            : '',
        'legacyModeEnabled': false,
        'legacyLocalOnly': false,
        'legacyPrefixOverride': '',
        'legacyResponseTarget': 'reply',
        'simpleConfig': <String, dynamic>{},
        'defaultMemberPermissions': '',
        'actions': <Map<String, dynamic>>[
          <String, dynamic>{
            'type': 'respondWithMessage',
            'key': 'sample_ping_response',
            'enabled': true,
            'payload': <String, dynamic>{
              'content': 'Pong!',
              'embeds': <Map<String, dynamic>>[],
              'components': <String, dynamic>{},
              'ephemeral': false,
              'replyToMessage': false,
            },
          },
        ],
      },
    };
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _openHostedBot() async {
    if (MobileAccountGate.isRequired &&
        !await MobileAccountGate.hasRequiredAccount()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.mobile_account_required_body)),
      );
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ContainerDeployPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 24, bottom: 32),
          child: BotCreateSetup(
            javascript: _createJavascriptBot,
            onEngineChanged: (value) {
              AppAnalytics.logEvent(
                name: 'select_app_type',
                parameters: {'type': value ? 'javascript_bot' : 'discord_bot'},
              );
              setState(() => _createJavascriptBot = value);
            },
            tokenController: _tokenController,
            obscureToken: _obscureToken,
            onToggleToken: () => setState(() => _obscureToken = !_obscureToken),
            onTokenChanged: (value) => setState(() => _token = value),
            saving: _isSaving,
            onSave: _token.trim().isEmpty || _isSaving ? null : _saveBot,
            onBack: () => Navigator.of(context).maybePop(),
            showBack: !windowChromeOwnsBackButton(),
            onPortal: () => _openExternalPage(
              'https://discord.com/developers/applications',
            ),
            onGuide: () => openDocumentationArticle(
              context,
              url: botTokenTutorialUrl,
              title: context.tr.app_open_token_tutorial,
            ),
            onHosted:
                !ResponsiveHelper.isDesktopPlatform() &&
                    PremiumCapabilities.hostedAppsRolloutEnabled
                ? _openHostedBot
                : null,
          ),
        ),
      ),
    ),
  );
}

class BotCreateSetup extends StatelessWidget {
  const BotCreateSetup({
    super.key,
    required this.javascript,
    required this.onEngineChanged,
    required this.tokenController,
    required this.obscureToken,
    required this.onToggleToken,
    required this.onTokenChanged,
    required this.saving,
    required this.onSave,
    required this.onBack,
    required this.showBack,
    required this.onPortal,
    required this.onGuide,
    this.onHosted,
  });
  final bool javascript, obscureToken, saving, showBack;
  final ValueChanged<bool> onEngineChanged;
  final TextEditingController tokenController;
  final ValueChanged<String> onTokenChanged;
  final VoidCallback onToggleToken, onBack, onPortal, onGuide;
  final VoidCallback? onSave, onHosted;

  Widget _panel(BuildContext context, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? HomeTokens.of(context).card
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _resource(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon.fromMaterial(
              icon,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: homeDisplayStyle(14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppIcon.fromMaterial(
              Icons.chevron_right_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final scheme = Theme.of(context).colorScheme;
    final form = _panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.bot_create_mode, style: homeSectionLabelStyle(context)),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(tr.bot_create_visual_title),
              ),
              ButtonSegment(
                value: true,
                label: Text(tr.cmd_execution_mode_javascript),
              ),
            ],
            selected: {javascript},
            onSelectionChanged: saving
                ? null
                : (values) => onEngineChanged(values.first),
            style: SegmentedButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
              selectedBackgroundColor: Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surfaceContainerLow,
              ),
              selectedForegroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            javascript
                ? tr.bot_create_javascript_description
                : tr.bot_create_visual_description,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 28),
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: 24),
          Text(
            tr.app_token_section_title,
            style: homeDisplayStyle(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            tr.app_token_section_desc,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: tokenController,
            enabled: !saving,
            obscureText: obscureToken,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onChanged: onTokenChanged,
            onSubmitted: (_) => onSave?.call(),
            decoration: InputDecoration(
              labelText: tr.app_bot_token,
              hintText: tr.app_enter_token,
              helperText: tr.app_token_field_helper,
              helperMaxLines: 3,
              prefixIcon: const AppIcon.fromMaterial(
                Icons.key_rounded,
                size: 18,
              ),
              suffixIcon: IconButton(
                tooltip: obscureToken ? tr.app_show_token : tr.app_hide_token,
                onPressed: onToggleToken,
                icon: AppIcon.fromMaterial(
                  obscureToken
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon.fromMaterial(
                Icons.lock_outline_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.app_token_security_hint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSave,
            icon: saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const AppIcon.fromMaterial(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(tr.app_save_bot),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          ),
        ],
      ),
    );
    final resources = _panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.app_resources_title, style: homeSectionLabelStyle(context)),
          _resource(
            context,
            Icons.open_in_new_rounded,
            tr.app_open_discord_portal,
            tr.app_open_discord_portal_desc,
            onPortal,
          ),
          Divider(color: scheme.outlineVariant, height: 1),
          _resource(
            context,
            Icons.menu_book_outlined,
            tr.app_open_token_tutorial,
            tr.app_open_token_tutorial_desc,
            onGuide,
          ),
          if (onHosted != null) ...[
            Divider(color: scheme.outlineVariant, height: 1),
            _resource(
              context,
              Icons.smart_toy_outlined,
              tr.app_create_type_hosted,
              tr.app_create_type_hosted_desc,
              onHosted!,
            ),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBack) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: HomeHeaderIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onBack,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(tr.home_overline, style: homeSectionLabelStyle(context)),
        const SizedBox(height: 8),
        Text(
          tr.bot_create_title,
          style: homeDisplayStyle(30, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          tr.bot_create_description,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [form, const SizedBox(height: 20), resources],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: resources),
              ],
            );
          },
        ),
      ],
    );
  }
}
