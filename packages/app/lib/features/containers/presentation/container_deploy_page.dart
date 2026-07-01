import 'package:flutter/material.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class ContainerDeployPage extends StatefulWidget {
  final MainApiClient? client;

  const ContainerDeployPage({super.key, this.client});

  @override
  State<ContainerDeployPage> createState() => _ContainerDeployPageState();
}

class _ContainerDeployPageState extends State<ContainerDeployPage> {
  final _formKey = GlobalKey<FormState>();
  final _imageCtrl = TextEditingController(text: 'nginx:alpine');
  final _ttlCtrl = TextEditingController(text: '120');
  final _envKeyCtrl = TextEditingController();
  final _envValCtrl = TextEditingController();

  final List<MapEntry<String, String>> _envVars = [];
  bool _deploying = false;
  MainApiClient? _client;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  Future<void> _initClient() async {
    if (widget.client != null) {
      _client = widget.client;
      return;
    }
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (session != null && !session.isExpired && config.isConfigured) {
        _client = MainApiClient(baseUrl: config.baseUrl, accessToken: session.accessToken);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _imageCtrl.dispose();
    _ttlCtrl.dispose();
    _envKeyCtrl.dispose();
    _envValCtrl.dispose();
    super.dispose();
  }

  void _addEnvVar() {
    final key = _envKeyCtrl.text.trim();
    final val = _envValCtrl.text.trim();
    if (key.isEmpty) return;
    setState(() => _envVars.add(MapEntry(key, val)));
    _envKeyCtrl.clear();
    _envValCtrl.clear();
  }

  Future<void> _deploy() async {
    if (!_formKey.currentState!.validate()) return;
    if (_client == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.container_deploy_not_auth), backgroundColor: Colors.red));
      return;
    }

    setState(() => _deploying = true);
    try {
      final image = _imageCtrl.text.trim();
      final ttl = int.parse(_ttlCtrl.text.trim());
      final env = {for (final e in _envVars) e.key: e.value};

      final result = await _client!.deployContainer(image: image, cpuMillis: 250, memoryMb: 192, storageGb: 1, env: env, ttlMinutes: ttl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.container_deploy_success(result['container_id'])), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr.container_deploy_failed(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _deploying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.container_deploy_title)),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(context.tr.container_deploy_image_label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _imageCtrl,
            decoration: InputDecoration(hintText: 'nginx:alpine', helperText: context.tr.container_deploy_image_hint),
            validator: (v) => (v == null || v.trim().isEmpty) ? context.tr.container_deploy_image_required : null,
          ),
          const SizedBox(height: 24),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr.container_deploy_ttl_label, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _ttlCtrl, keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '120'),
                validator: (v) { final n = int.tryParse(v ?? ''); if (n == null || n < 1) return context.tr.container_deploy_ttl_min; return null; },
              ),
            ])),
          ]),
          const SizedBox(height: 24),

          Text(context.tr.container_deploy_env_label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._envVars.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Expanded(child: Text('${e.key}=${e.value}', overflow: TextOverflow.ellipsis)),
              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => setState(() => _envVars.remove(e))),
            ]),
          )),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextFormField(controller: _envKeyCtrl, decoration: InputDecoration(hintText: context.tr.container_deploy_env_key_hint, isDense: true))),
            const SizedBox(width: 8),
            Expanded(child: TextFormField(controller: _envValCtrl, decoration: InputDecoration(hintText: context.tr.container_deploy_env_value_hint, isDense: true))),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: _addEnvVar),
          ]),
          const SizedBox(height: 24),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 20, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('0.25 CPU · 192 MB RAM', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Ephemeral storage (no persistent volume)', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _deploying ? null : _deploy,
            icon: _deploying
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.rocket_launch),
            label: Text(_deploying ? context.tr.container_deploy_submitting : context.tr.container_deploy_submit),
          ),
        ]),
      ),
    );
  }
}
