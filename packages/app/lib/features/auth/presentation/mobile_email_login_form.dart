import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_credentials_auth_service.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';

import 'package:flutter/material.dart';

class MobileEmailLoginForm extends StatefulWidget {
  const MobileEmailLoginForm({
    super.key,
    required this.onSuccess,
    this.busy = false,
    this.compact = false,
  });

  final VoidCallback onSuccess;
  final bool busy;
  final bool compact;

  @override
  State<MobileEmailLoginForm> createState() => _MobileEmailLoginFormState();
}

class _MobileEmailLoginFormState extends State<MobileEmailLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || widget.busy) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final client = MainApiClient(baseUrl: config.baseUrl);
      await MainApiCredentialsAuthService.login(
        client: client,
        email: email,
        password: password,
      );
      if (!mounted) {
        return;
      }
      widget.onSuccess();
    } on MainApiCredentialsAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'invalid_credentials'
                ? context.tr.mobile_login_invalid_credentials
                : context.tr.mobile_login_failed(error.message),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr.mobile_login_failed(error.toString())),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final isBusy = _submitting || widget.busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.compact) ...[
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr.mobile_login_or_divider,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            tr.mobile_login_email_title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            tr.mobile_login_email_hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ] else
          const SizedBox(height: 4),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const <String>[AutofillHints.username],
          decoration: InputDecoration(
            labelText: tr.mobile_login_email,
            border: const OutlineInputBorder(),
          ),
          enabled: !isBusy,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofillHints: const <String>[AutofillHints.password],
          decoration: InputDecoration(
            labelText: tr.mobile_login_password,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: isBusy
                  ? null
                  : () => setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          enabled: !isBusy,
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: isBusy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 14),
          ),
          child: isBusy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(tr.mobile_login_submit),
        ),
      ],
    );
  }
}
