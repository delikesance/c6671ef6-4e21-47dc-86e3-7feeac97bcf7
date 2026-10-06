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
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' show BotCreateSetup;

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
