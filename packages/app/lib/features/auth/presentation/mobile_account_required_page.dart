import 'package:bot_creator/core/auth/main_api_account_bootstrap.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_auth_service.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MobileAccountRequiredPage extends StatefulWidget {
  const MobileAccountRequiredPage({super.key, required this.onConnected});

  final VoidCallback onConnected;

  @override
  State<MobileAccountRequiredPage> createState() =>
      _MobileAccountRequiredPageState();
}

class _MobileAccountRequiredPageState extends State<MobileAccountRequiredPage> {
  bool _connecting = false;

  Future<void> _connectDiscord() async {
    if (_connecting) {
      return;
    }

    setState(() => _connecting = true);
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final client = MainApiClient(baseUrl: config.baseUrl);
      final session = await MainApiAuthService.connectWithDiscord(client: client);
      await MainApiSettingsStore.saveDiscordOAuthSession(session);

      try {
        await syncManagedBotsAfterDiscordLogin(
          baseUrl: config.baseUrl,
          accessToken: session.accessToken,
        );
      } catch (_) {}

      if (!mounted) {
        return;
      }
      widget.onConnected();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.mobile_account_required_failed(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.account_circle_outlined,
                    size: 72,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr.mobile_account_required_title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tr.mobile_account_required_body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _FeatureRow(
                    icon: Icons.smart_toy_outlined,
                    text: tr.mobile_account_required_feature_bots,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.storage_rounded,
                    text: tr.mobile_account_required_feature_hosted,
                  ),
                  const SizedBox(height: 12),
                  _FeatureRow(
                    icon: Icons.phone_android_outlined,
                    text: tr.mobile_account_required_feature_recovery,
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: _connecting ? null : _connectDiscord,
                    icon: _connecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: Text(tr.settings_account_connect_label),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}
