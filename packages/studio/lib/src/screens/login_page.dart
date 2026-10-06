import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../auth/auth_controller.dart';
import '../l10n_ext.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Seul écran accessible sans session valide.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.auth});

  final AuthController auth;

  /// Motif connu traduit, sinon le message brut du serveur.
  String? _errorText(BuildContext context) => switch (auth.issue) {
    AuthIssue.sessionExpired => context.l10n.authSessionExpired,
    AuthIssue.discordRefused => context.l10n.authDiscordRefused(
      auth.issueDetail ?? '',
    ),
    AuthIssue.invalidResponse => context.l10n.authInvalidResponse,
    null => auth.errorMessage,
  };

  @override
  Widget build(BuildContext context) {
    final failed = auth.status == AuthStatus.error;
    final error = _errorText(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: StudioColors.card,
                border: Border.all(color: StudioColors.cardBorder),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const StudioLogo(size: 56),
                  const SizedBox(height: 20),
                  Text(
                    context.l10n.appTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: StudioColors.muted,
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: StudioColors.errorText,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: failed
                        ? FilledButton(
                            onPressed: auth.retry,
                            child: Text(context.l10n.commonRetry),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: StudioColors.discord,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: auth.signIn,
                            icon: const AppIcon.fromMaterial(
                              Icons.login,
                              size: 18,
                            ),
                            label: Text(context.l10n.loginDiscord),
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
