import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';

class AppCreatePage extends StatefulWidget {
  const AppCreatePage({super.key});

  @override
  State<AppCreatePage> createState() => _AppCreatePageState();
}

class _AppCreatePageState extends State<AppCreatePage> {
  String _token = "";
  bool _isSaving = false;
  bool _obscureToken = true;
  String? _selectedType;

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
          const Icon(Icons.vpn_key_off_rounded, color: Colors.orange),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.tr.app_token_invalid_title),
          ),
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
                builder:
                    (context) => AlertDialog(
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
      await AppAnalytics.logEvent(
        name: "create_app",
        parameters: {
          "app_name": discordUser.username as Object,
          "app_id": discordUser.id.toString() as Object,
        },
      );

      if (mounted) {
        await _offerSampleCommand(discordUser.id.toString(), discordUser.username);
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
            Icon(Icons.smart_toy_rounded,
                color: Theme.of(ctx).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(context.tr.app_create_sample_title),
            ),
          ],
        ),
        content: Text(
          context.tr.app_create_sample_desc(botName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.app_create_sample_skip),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
            label: Text(context.tr.app_create_sample_confirm),
          ),
        ],
      ),
    );

    if (createSample != true || !mounted) return;

    try {
      final sampleCommand = _buildSamplePingCommand();
      final commandId = sampleCommand['id'] as String;
      await appManager.saveAppCommand(botId, commandId, sampleCommand);

      await AppAnalytics.logEvent(
        name: "create_sample_command",
        parameters: {
          "bot_id": botId as Object,
          "command_name": "ping",
        },
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
      developer.log(
        'Error creating sample command: $e',
        name: 'AppCreatePage',
      );
    }
  }

  /// Builds the data payload for a sample /ping command with a "Pong!" response.
  Map<String, dynamic> _buildSamplePingCommand() {
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
        'executionMode': 'workflow',
        'bdfdScriptContent': '',
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

  Widget _buildTypeSelectionView(
    BuildContext context,
    bool isMobile,
    ColorScheme colorScheme,
  ) {
    final cards = <Widget>[
      _TypeSelectionCard(
        title: context.tr.app_create_type_discord,
        description: context.tr.app_create_type_discord_desc,
        icon: Icons.smart_toy_rounded,
        iconColor: const Color(0xFF5865F2),
        iconBackgroundColor: const Color(0xFF5865F2).withOpacity(0.12),
        onTap: () {
          AppAnalytics.logEvent(
            name: "select_app_type",
            parameters: {"type": "discord_bot"},
          );
          setState(() {
            _selectedType = 'discord_bot';
          });
        },
      ),
      if (PremiumCapabilities.hostedAppsRolloutEnabled)
        _TypeSelectionCard(
          title: context.tr.app_create_type_hosted,
          description: context.tr.app_create_type_hosted_desc,
          icon: Icons.storage_rounded,
          iconColor: Colors.teal,
          iconBackgroundColor: Colors.teal.withOpacity(0.12),
          onTap: () {
            AppAnalytics.logEvent(
              name: "select_app_type",
              parameters: {"type": "hosted_application"},
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ContainerDeployPage(),
              ),
            );
          },
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          context.tr.app_create_select_type_title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.app_create_select_type_desc,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 32),
        if (isMobile)
          Column(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                cards[i],
              ],
            ],
          )
        else if (cards.length == 1)
          cards[0]
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 20),
                Expanded(child: cards[i]),
              ],
            ],
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildDiscordBotView(
    BuildContext context,
    bool isMobile,
    double maxWidth,
    double horizontalPadding,
    ColorScheme colorScheme,
    double sectionSpacing,
    EdgeInsets cardPadding,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(isMobile ? 20 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.smart_toy_rounded,
                size: isMobile ? 40 : 48,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr.app_create_hero_title,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.app_create_hero_desc,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: sectionSpacing),
        Card(
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.app_resources_title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr.app_resources_desc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _ExternalActionCard(
                  icon: Icons.open_in_new_rounded,
                  title: context.tr.app_open_discord_portal,
                  subtitle: context.tr.app_open_discord_portal_desc,
                  badgeLabel: context.tr.app_external_link_badge,
                  onTap:
                      () => _openExternalPage(
                        'https://discord.com/developers/applications',
                      ),
                ),
                const SizedBox(height: 12),
                _ExternalActionCard(
                  icon: Icons.school_rounded,
                  title: context.tr.app_open_token_tutorial,
                  subtitle: context.tr.app_open_token_tutorial_desc,
                  badgeLabel: context.tr.app_external_link_badge,
                  onTap:
                      () => _openExternalPage(
                        'https://bot-creator.fr/tutorials/setup/security/2025/05/18/how-to-create-a-bot-token-bot-creator.html',
                      ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: sectionSpacing),
        Card(
          child: Padding(
            padding: cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.app_token_section_title,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr.app_token_section_desc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: context.tr.app_bot_token,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.radiusLg,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: context.tr.app_enter_token,
                    helperText: context.tr.app_token_field_helper,
                    isDense: isMobile,
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      tooltip:
                          _obscureToken
                              ? context.tr.app_show_token
                              : context.tr.app_hide_token,
                      onPressed: () {
                        setState(
                          () => _obscureToken = !_obscureToken,
                        );
                      },
                      icon: Icon(
                        _obscureToken
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                  obscureText: _obscureToken,
                  enableSuggestions: false,
                  autocorrect: false,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  onChanged:
                      (value) => setState(() {
                        _token = value;
                      }),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      AppTheme.radiusLg,
                    ),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          context.tr.app_token_security_hint,
                          style:
                              Theme.of(
                                context,
                              ).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _token.trim().isEmpty || _isSaving
                            ? null
                            : _saveBot,
                    icon:
                        _isSaving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(
                              Icons.check_circle_outline_rounded,
                            ),
                    label: Text(context.tr.app_save_bot),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final maxWidth = ResponsiveHelper.getContentMaxWidth(context);
    final horizontalPadding = ResponsiveHelper.getHorizontalPaddingValue(
      context,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final sectionSpacing = ResponsiveHelper.getSpacing(context, factor: 1.5);
    final cardPadding = EdgeInsets.all(isMobile ? 16 : 20);

    final showSelection = _selectedType == null;

    return PopScope(
      canPop: showSelection,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_selectedType != null) {
          setState(() {
            _selectedType = null;
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr.app_create_page_title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () {
              if (_selectedType != null) {
                setState(() {
                  _selectedType = null;
                });
              } else {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 16,
                  ),
                  child: showSelection
                      ? _buildTypeSelectionView(context, isMobile, colorScheme)
                      : _buildDiscordBotView(
                          context,
                          isMobile,
                          maxWidth,
                          horizontalPadding,
                          colorScheme,
                          sectionSpacing,
                          cardPadding,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExternalActionCard extends StatelessWidget {
  const _ExternalActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                      ),
                      child: Text(
                        badgeLabel,
                        style: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeSelectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final bool isEnabled;
  final String? badgeText;
  final VoidCallback onTap;

  const _TypeSelectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.onTap,
    this.isEnabled = true,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: isEnabled ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          side: BorderSide(
            color: isEnabled 
                ? colorScheme.outlineVariant 
                : colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        size: 32,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEnabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isEnabled ? colorScheme.onSurfaceVariant : colorScheme.onSurfaceVariant.withOpacity(0.8),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
                if (badgeText != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(
                          color: colorScheme.secondary.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        badgeText!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
