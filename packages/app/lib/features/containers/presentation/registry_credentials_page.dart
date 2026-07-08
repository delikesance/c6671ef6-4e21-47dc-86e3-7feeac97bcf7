import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:flutter/material.dart';

class RegistryCredentialsPage extends StatefulWidget {
  final MainApiClient? client;

  const RegistryCredentialsPage({super.key, this.client});

  @override
  State<RegistryCredentialsPage> createState() => _RegistryCredentialsPageState();
}

class _RegistryCredentialsPageState extends State<RegistryCredentialsPage> {
  MainApiClient? _client;
  bool _loading = true;
  String? _error;
  List<RegistryCredential> _credentials = const [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (widget.client != null) {
      _client = widget.client;
    } else {
      try {
        final config = await MainApiSettingsStore.loadConfig();
        final session = await MainApiSettingsStore.loadSession();
        if (session != null && !session.isExpired && config.isConfigured) {
          _client = MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          );
        }
      } catch (_) {}
    }
    await _load();
  }

  Future<void> _load() async {
    if (_client == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = context.tr.container_list_session_missing;
        });
      }
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final creds = await _client!.listRegistryCredentials();
      if (mounted) {
        setState(() {
          _credentials = creds;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor({RegistryCredential? existing}) async {
    if (_client == null) return;
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RegistryCredentialEditorSheet(
        client: _client!,
        existing: existing,
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _delete(RegistryCredential cred) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr.registry_credentials_delete_title),
        content: Text(context.tr.registry_credentials_delete_body(cred.label)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || _client == null) return;
    try {
      await _client!.deleteRegistryCredential(cred.id);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.registry_credentials_deleted)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.registry_credentials_delete_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.registry_credentials_title),
      ),
      floatingActionButton: _client == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: Text(context.tr.registry_credentials_add),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: Text(context.tr.container_list_retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _credentials.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          context.tr.registry_credentials_empty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _credentials.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cred = _credentials[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.vpn_key_outlined),
                            title: Text(cred.label),
                            subtitle: Text(
                              '${cred.registryHost} · ${cred.username}',
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _openEditor(existing: cred);
                                } else if (value == 'delete') {
                                  _delete(cred);
                                }
                              },
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: Text(context.tr.registry_credentials_edit),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(context.tr.delete),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _RegistryCredentialEditorSheet extends StatefulWidget {
  const _RegistryCredentialEditorSheet({
    required this.client,
    this.existing,
  });

  final MainApiClient client;
  final RegistryCredential? existing;

  @override
  State<_RegistryCredentialEditorSheet> createState() =>
      _RegistryCredentialEditorSheetState();
}

class _RegistryCredentialEditorSheetState
    extends State<_RegistryCredentialEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _hostCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _passCtrl;
  bool _saving = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.existing?.label ?? '');
    _hostCtrl = TextEditingController(
      text: widget.existing?.registryHost ?? 'ghcr.io',
    );
    _userCtrl = TextEditingController(text: widget.existing?.username ?? '');
    _passCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _hostCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await widget.client.createRegistryCredential(
          label: _labelCtrl.text.trim(),
          registryHost: _hostCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          password: _passCtrl.text,
        );
      } else {
        await widget.client.updateRegistryCredential(
          widget.existing!.id,
          label: _labelCtrl.text.trim(),
          registryHost: _hostCtrl.text.trim(),
          username: _userCtrl.text.trim(),
          password: _passCtrl.text.trim().isEmpty ? null : _passCtrl.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.registry_credentials_save_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? context.tr.registry_credentials_add
                  : context.tr.registry_credentials_edit,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                labelText: context.tr.registry_credentials_label,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.tr.registry_credentials_label_required
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hostCtrl,
              decoration: InputDecoration(
                labelText: context.tr.registry_credentials_host,
                hintText: 'ghcr.io',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.tr.registry_credentials_host_required
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _userCtrl,
              decoration: InputDecoration(
                labelText: context.tr.registry_credentials_username,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? context.tr.registry_credentials_username_required
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: context.tr.registry_credentials_password,
                helperText: widget.existing == null
                    ? context.tr.registry_credentials_password_hint
                    : context.tr.registry_credentials_password_edit_hint,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (widget.existing != null) return null;
                if (v == null || v.isEmpty) {
                  return context.tr.registry_credentials_password_required;
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.registry_credentials_ghcr_hint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(
                _saving
                    ? context.tr.container_deploy_submitting
                    : context.tr.save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
