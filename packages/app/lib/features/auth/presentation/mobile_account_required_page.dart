import 'package:bot_creator/core/auth/main_api_account_bootstrap.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_auth_service.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';

import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/features/auth/presentation/mobile_email_login_form.dart';
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
  bool _emailLoginExpanded = false;

  Future<void> _connectDiscord() async {
    if (_connecting) {
      return;
    }

    setState(() => _connecting = true);
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final client = MainApiClient(baseUrl: config.baseUrl);
      final session = await MainApiAuthService.connectWithDiscord(
        client: client,
      );
      await MainApiSettingsStore.saveSession(
        session.copyWith(authMethod: MainApiAuthMethod.discordOauth),
      );

      try {
        await syncManagedBotsAfterDiscordLogin(
          baseUrl: config.baseUrl,
          accessToken: session.accessToken,
        );
      } catch (_) {}

      await MobileAccountSession.instance.recheck();

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
          content: Text(
            context.tr.mobile_account_required_failed(error.toString()),
          ),
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
                    size: 56,
                    // Icône décorative : neutre du thème. Le violet reste
                    // réservé au bouton primaire ci-dessous.
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr.mobile_account_required_title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr.mobile_account_required_body,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _connecting ? null : _connectDiscord,
                    icon: _connecting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(tr.settings_account_connect_label),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _connecting
                        ? null
                        : () => setState(
                            () => _emailLoginExpanded = !_emailLoginExpanded,
                          ),
                    child: Text(
                      _emailLoginExpanded
                          ? tr.mobile_login_hide_email
                          : tr.mobile_login_show_email,
                    ),
                  ),
                  if (_emailLoginExpanded)
                    MobileEmailLoginForm(
                      busy: _connecting,
                      compact: true,
                      onSuccess: () async {
                        await MobileAccountSession.instance.recheck();
                        if (!mounted) {
                          return;
                        }
                        widget.onConnected();
                      },
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
