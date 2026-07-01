import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/features/auth/presentation/mobile_account_required_page.dart';
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
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
      _session.recheck();
    }
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!MobileAccountGate.isRequired) {
      return widget.child;
    }

    if (!_session.loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_session.satisfied) {
      return MobileAccountRequiredPage(
        onConnected: () => _session.recheck(),
      );
    }

    return widget.child;
  }
}
