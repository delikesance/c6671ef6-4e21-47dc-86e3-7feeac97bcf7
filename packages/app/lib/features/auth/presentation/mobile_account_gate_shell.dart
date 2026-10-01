import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_auth_service.dart';
import 'package:bot_creator/features/auth/presentation/mobile_account_required_page.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Wraps the main app on mobile and blocks access until Discord OAuth succeeds.
class MobileAccountGateShell extends StatefulWidget {
  const MobileAccountGateShell({super.key, required this.child});

  final Widget child;

  @override
  State<MobileAccountGateShell> createState() => _MobileAccountGateShellState();
}

class _MobileAccountGateShellState extends State<MobileAccountGateShell>
    with WidgetsBindingObserver {
  final MobileAccountSession _session = MobileAccountSession.instance;
  bool _hasBeenSatisfied = false;
  bool _dismissedReauthOverlay = false;

  @override
  void initState() {
    super.initState();
    if (_session.loaded && _session.satisfied) {
      _hasBeenSatisfied = true;
    }
    WidgetsBinding.instance.addObserver(this);
    _session.addListener(_onSessionChanged);
    _session.recheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_completePendingOAuthCallbackIfNeeded());
      _session.recheck();
    }
  }

  Future<void> _completePendingOAuthCallbackIfNeeded() async {
    try {
      final link = await AppLinks().getInitialLink();
      if (link != null) {
        await MainApiAuthService.tryCompleteMobileOAuthCallback(link);
      }
    } catch (_) {}
  }

  void _onSessionChanged() {
    if (mounted) {
      if (_session.satisfied) {
        _hasBeenSatisfied = true;
        _dismissedReauthOverlay = false;
      }
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MobileAccountGate.isRequired) {
      return widget.child;
    }

    if (!_session.loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_session.satisfied) {
      _hasBeenSatisfied = true;
      _dismissedReauthOverlay = false;
      return Stack(fit: StackFit.expand, children: [widget.child]);
    }

    if (!_hasBeenSatisfied) {
      return MobileAccountRequiredPage(onConnected: () => _session.recheck());
    }

    // When the session drops after having been active (e.g. token revocation),
    // preserve widget.child in the widget tree so that active drafts, unsaved
    // scripts, form controllers, and editing states are never unmounted or lost.
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_dismissedReauthOverlay)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Material(
                elevation: 4,
                color: scheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      AppIcon.fromMaterial(
                        Icons.warning_amber_rounded,
                        color: scheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr.team_unavailable,
                          style: TextStyle(
                            color: scheme.onErrorContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor: scheme.onErrorContainer,
                        ),
                        onPressed: () {
                          setState(() => _dismissedReauthOverlay = false);
                        },
                        child: Text(context.tr.settings_account_connect_label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          Positioned.fill(
            child: Material(
              color: Colors.black.withValues(alpha: 0.65),
              child: MobileAccountRequiredPage(
                onConnected: () => _session.recheck(),
                onDismiss: () => setState(() => _dismissedReauthOverlay = true),
              ),
            ),
          ),
      ],
    );
  }
}
