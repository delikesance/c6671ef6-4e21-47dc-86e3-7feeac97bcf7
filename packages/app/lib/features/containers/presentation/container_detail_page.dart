import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class ContainerDetailPage extends StatefulWidget {
  final String containerId;
  final MainApiClient? client;

  const ContainerDetailPage({super.key, required this.containerId, this.client});

  @override
  State<ContainerDetailPage> createState() => _ContainerDetailPageState();
}

class _ContainerDetailPageState extends State<ContainerDetailPage> {
  MainApiClient? _client;
  Map<String, dynamic>? _status;
  bool _loading = true;
  bool _stopping = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    if (widget.client != null) {
      _client = widget.client;
    } else {
      try {
        final config = await MainApiSettingsStore.loadConfig();
        final session = await MainApiSettingsStore.loadSession();
        if (session != null && !session.isExpired && config.isConfigured) {
          _client = MainApiClient(baseUrl: config.baseUrl, accessToken: session.accessToken);
        }
      } catch (_) {}
    }
    await _loadStatus();
  }

  Future<void> _loadStatus() async {
    if (_client == null) return;
    setState(() => _loading = true);
    try {
      final status = await _client!.getContainerStatus(widget.containerId);
      if (mounted) setState(() { _status = status; _loading = false; });
      final state = status['state']?.toString() ?? '';
      if (state == 'PENDING') {
        _pollTimer ??= Timer.periodic(const Duration(seconds: 10), (_) => _loadStatus());
      } else {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _stopContainer() async {
    if (_client == null) return;
    final tr = context.tr;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr.container_detail_stop_title),
      content: Text(tr.container_detail_stop_confirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(tr.container_detail_stop_btn)),
      ],
    ));
    if (confirm != true) return;

    setState(() => _stopping = true);
    try {
      await _client!.stopContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_stopped_ok), backgroundColor: Colors.green));
        _loadStatus();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  Future<void> _extendTTL() async {
    if (_client == null) return;
    final tr = context.tr;
    final ttlCtrl = TextEditingController(text: '60');
    final ttl = await showDialog<int>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr.container_detail_extend_ttl),
      content: TextField(controller: ttlCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr.container_detail_extend_hint, hintText: '60')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr.cancel)),
        FilledButton(onPressed: () { final n = int.tryParse(ttlCtrl.text); if (n == null || n < 1) return; Navigator.pop(ctx, n); }, child: Text(tr.container_detail_extend_btn)),
      ],
    ));
    ttlCtrl.dispose();
    if (ttl == null) return;

    try {
      final result = await _client!.extendContainerTTL(widget.containerId, ttl);
      if (mounted) { _status = result; setState(() {}); }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_extended_ok), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
    }
  }

  Future<void> _updateResources() async {
    if (_client == null) return;
    final tr = context.tr;
    final cpuCtrl = TextEditingController(text: '1000');
    final memCtrl = TextEditingController(text: '1024');
    final updated = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr.container_detail_update_resources),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: cpuCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr.container_deploy_cpu_label, hintText: '1000')),
        const SizedBox(height: 12),
        TextField(controller: memCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: tr.container_deploy_memory_label, hintText: '1024')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr.container_detail_update_btn)),
      ],
    ));
    cpuCtrl.dispose();
    memCtrl.dispose();
    if (updated != true) return;

    final cpu = int.tryParse(cpuCtrl.text);
    final mem = int.tryParse(memCtrl.text);
    if (cpu == null || mem == null) return;

    try {
      await _client!.updateContainerResources(widget.containerId, cpuMillis: cpu, memoryMb: mem);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_updated_ok), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
    }
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'RUNNING': return Colors.green;
      case 'PENDING': return Colors.orange;
      case 'STOPPED': case 'STOPPING': return Colors.grey;
      case 'FAILED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _stateLabel(String state, AppLocalizations tr) {
    switch (state) {
      case 'RUNNING': return tr.container_state_running;
      case 'PENDING': return tr.container_state_pending;
      case 'STOPPED': return tr.container_state_stopped;
      case 'STOPPING': return tr.container_state_stopping;
      case 'FAILED': return tr.container_state_failed;
      default: return state;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tr = context.tr;
    final state = _status?['state']?.toString() ?? '';
    final expiresAt = _status?['expires_at']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(tr.container_detail_title(widget.containerId.substring(0, 8)))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _stateColor(state), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(tr.container_detail_state, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Text(_stateLabel(state, tr), style: TextStyle(fontWeight: FontWeight.bold, color: _stateColor(state))),
                ]),
                if (expiresAt.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    const Icon(Icons.timer_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(tr.container_detail_expires, style: Theme.of(context).textTheme.titleSmall),
                    const Spacer(),
                    Text(expiresAt, style: const TextStyle(fontSize: 13)),
                  ]),
                ],
              ]))),
              const SizedBox(height: 24),
              if (state == 'RUNNING') ...[
                FilledButton.icon(onPressed: _extendTTL, icon: const Icon(Icons.timer), label: Text(tr.container_detail_extend_ttl)),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(onPressed: _updateResources, icon: const Icon(Icons.tune), label: Text(tr.container_detail_update_resources)),
                const SizedBox(height: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: _stopping ? null : _stopContainer,
                  icon: _stopping
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.stop),
                  label: Text(_stopping ? tr.container_state_stopping : tr.container_detail_stop_title),
                ),
                const SizedBox(height: 24),
                Text(tr.container_detail_console, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: _client != null
                        ? WebSocketConsole(channel: _client!.connectContainerConsole(widget.containerId))
                        : Center(child: Text(tr.container_detail_not_connected)),
                  ),
                ),
              ],
              if (state == 'PENDING')
                Center(child: Column(children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(tr.container_detail_deploying)])),
              if (state == 'STOPPED' || state == 'FAILED')
                Center(child: Text(tr.container_detail_status_stopped(_stateLabel(state, tr)), style: TextStyle(color: colorScheme.onSurfaceVariant))),
            ]),
    );
  }
}

class WebSocketConsole extends StatefulWidget {
  final WebSocketChannel channel;
  const WebSocketConsole({super.key, required this.channel});

  @override
  State<WebSocketConsole> createState() => _WebSocketConsoleState();
}

class _WebSocketConsoleState extends State<WebSocketConsole> {
  final List<String> _lines = <String>[];
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();
  bool _connected = false;

  @override
  void initState() {
    super.initState();
    _lines.add(context.tr.container_detail_console_connecting);
    widget.channel.stream.listen(
      (data) {
        if (mounted) {
          setState(() {
            _lines.add(data.toString());
            _connected = true;
          });
          _scrollToBottom();
        }
      },
      onError: (error) {
        if (mounted) setState(() => _lines.add(context.tr.container_detail_failed(error.toString())));
      },
      onDone: () {
        if (mounted) {
          setState(() {
            _lines.add(context.tr.container_detail_console_closed);
            _connected = false;
          });
        }
      },
      cancelOnError: false,
    );
    setState(() {
      _lines.removeLast();
      _connected = true;
    });
  }

  void _sendCommand(String cmd) {
    if (cmd.trim().isEmpty) return;
    widget.channel.sink.add(cmd);
    setState(() => _lines.add('> $cmd'));
    _inputCtrl.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!_connected)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 8),
                Text(context.tr.container_detail_console_connecting, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.all(8),
            itemCount: _lines.length,
            itemBuilder: (_, i) => Text(
              _lines[i],
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.4),
            ),
          ),
        ),
        const Divider(height: 1),
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  enabled: _connected,
                  decoration: InputDecoration(
                    hintText: context.tr.container_detail_console_hint,
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  onSubmitted: _sendCommand,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, size: 20),
                onPressed: _connected ? () => _sendCommand(_inputCtrl.text) : null,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
