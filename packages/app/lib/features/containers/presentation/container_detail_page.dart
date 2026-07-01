import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_hosting_actions.dart';
import 'package:bot_creator/features/containers/presentation/hosted_app_upsell_widgets.dart';

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
  bool _starting = false;
  bool _deleting = false;
  bool _claimingAd = false;
  bool _loadingEligibility = true;
  HostedAppEligibility? _eligibility;
  Timer? _pollTimer;
  WebSocketChannel? _consoleChannel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _closeConsoleChannel();
    super.dispose();
  }

  void _closeConsoleChannel() {
    _consoleChannel?.sink.close();
    _consoleChannel = null;
  }

  void _syncConsoleChannel(String state) {
    if (state != 'RUNNING' || _client == null) {
      _closeConsoleChannel();
      return;
    }
    _consoleChannel ??= _client!.connectContainerConsole(widget.containerId);
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
    await Future.wait([
      _loadStatus(showFullScreenLoader: true),
      _refreshEligibility(),
    ]);
  }

  Future<void> _refreshEligibility() async {
    if (_client == null) {
      if (mounted) setState(() => _loadingEligibility = false);
      return;
    }
    setState(() => _loadingEligibility = true);
    try {
      final elig = await _client!.getHostedAppEligibility();
      if (mounted) {
        setState(() {
          _eligibility = elig;
          _loadingEligibility = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingEligibility = false);
    }
  }

  DateTime? get _expiresAt {
    final raw = _status?['expires_at']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> _watchAdAndTopUp() async {
    if (_client == null || _claimingAd) return;
    setState(() => _claimingAd = true);
    try {
      final result = await HostedAppHostingActions.watchAdAndClaim(
        client: _client!,
        placement: 'hosted_app_topup',
        containerId: widget.containerId,
        applyToContainer: true,
      );
      await Future.wait([
        _refreshEligibility(),
        _loadStatus(),
      ]);
      if (mounted && result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.appliedToContainer
                  ? context.tr.container_detail_topup_applied(result.grantedMinutes)
                  : context.tr.container_detail_topup_credited(result.grantedMinutes),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingAd = false);
    }
  }

  Future<void> _applyStoredMinutes() async {
    final elig = _eligibility;
    if (_client == null || elig == null || elig.premium || elig.hostingMinutesBalance <= 0) {
      return;
    }
    try {
      await _client!.extendContainerTTL(
        widget.containerId,
        elig.hostingMinutesBalance,
      );
      await Future.wait([
        _refreshEligibility(),
        _loadStatus(),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.container_detail_minutes_applied(elig.hostingMinutesBalance),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.container_detail_failed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadStatus({bool showFullScreenLoader = false}) async {
    if (_client == null) return;
    if (showFullScreenLoader || _status == null) {
      setState(() => _loading = true);
    }
    try {
      final status = await _client!.getContainerStatus(widget.containerId);
      if (mounted) {
        final nextState = status['state']?.toString() ?? '';
        setState(() {
          _status = status;
          _loading = false;
        });
        _syncConsoleChannel(nextState);
      }
      final state = status['state']?.toString() ?? '';
      if (state == 'PENDING' || state == 'PROVISIONING') {
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
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr.container_detail_stop_btn)),
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

  Future<void> _startContainer() async {
    if (_client == null) return;
    final tr = context.tr;
    setState(() => _starting = true);
    try {
      await _client!.startContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_started_ok), backgroundColor: Colors.green));
        _loadStatus(showFullScreenLoader: true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _deleteContainer() async {
    if (_client == null) return;
    final tr = context.tr;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text(tr.container_detail_delete_title),
      content: Text(tr.container_detail_delete_confirm),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr.cancel)),
        FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(ctx, true), child: Text(tr.container_detail_delete_btn)),
      ],
    ));
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await _client!.deleteContainer(widget.containerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_deleted_ok), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr.container_detail_failed(e.toString())), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String _formatMemoryUsage(Map<String, dynamic>? status) {
    if (status == null) return '—';
    final limitMb = ContainerInfo.parseInt(status['memory_mb'], 0);
    final usageBytes = ContainerInfo.parseInt(status['memory_usage_bytes'], 0);
    if (usageBytes > 0) {
      final usedMb = (usageBytes / (1024 * 1024)).ceil();
      return '$usedMb / $limitMb MB';
    }
    return '$limitMb MB';
  }

  Color _stateColor(String state) {
    switch (state) {
      case 'RUNNING': return Colors.green;
      case 'PENDING': case 'PROVISIONING': return Colors.orange;
      case 'STOPPED': case 'STOPPING': return Colors.grey;
      case 'FAILED': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _stateLabel(String state, AppLocalizations tr) {
    switch (state) {
      case 'RUNNING': return tr.container_state_running;
      case 'PENDING': case 'PROVISIONING': return tr.container_state_pending;
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
    final image = _status?['image']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(tr.container_detail_title(widget.containerId.substring(0, 8)))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (!_loadingEligibility && _eligibility != null && !_eligibility!.premium) ...[
                HostedAppFreeHostingBanner(
                  eligibility: _eligibility!,
                  claimingAd: _claimingAd,
                  onWatchAd: (state == 'RUNNING' || state == 'PROVISIONING')
                      ? _watchAdAndTopUp
                      : null,
                  showTopUpHint: state == 'RUNNING' || state == 'PROVISIONING',
                  expiresAt: _expiresAt,
                ),
                if (_eligibility!.hostingMinutesBalance > 0 &&
                    (state == 'RUNNING' || state == 'PROVISIONING'))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: OutlinedButton.icon(
                      onPressed: _applyStoredMinutes,
                      icon: const Icon(Icons.schedule),
                      label: Text(
                        context.tr.container_detail_apply_stored_minutes(
                          _eligibility!.hostingMinutesBalance,
                        ),
                      ),
                    ),
                  ),
                const HostedAppPremiumUpsell(compact: true),
                const SizedBox(height: 8),
              ],
              Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (image.isNotEmpty) ...[
                  Text(image, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: _stateColor(state), shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(tr.container_detail_state, style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Text(_stateLabel(state, tr), style: TextStyle(fontWeight: FontWeight.bold, color: _stateColor(state))),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.memory_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('RAM', style: Theme.of(context).textTheme.titleSmall),
                  const Spacer(),
                  Text(_formatMemoryUsage(_status), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ]))),
              const SizedBox(height: 24),
              if (state == 'RUNNING' || state == 'PROVISIONING') ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
                  onPressed: _stopping ? null : _stopContainer,
                  icon: _stopping
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.power_settings_new),
                  label: Text(_stopping ? tr.container_state_stopping : tr.container_detail_stop_title),
                ),
                if (state == 'RUNNING') ...[
                const SizedBox(height: 24),
                Text(tr.container_detail_console, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                SizedBox(
                  height: 300,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: _consoleChannel != null
                        ? WebSocketConsole(
                            key: ValueKey(widget.containerId),
                            channel: _consoleChannel!,
                          )
                        : Center(child: Text(tr.container_detail_not_connected)),
                  ),
                ),
                ],
              ],
              if (state == 'PENDING')
                Center(child: Column(children: [const CircularProgressIndicator(), const SizedBox(height: 12), Text(tr.container_detail_deploying)])),
              if (state == 'STOPPED') ...[
                Text(tr.container_detail_stopped_hint, style: TextStyle(color: colorScheme.onSurfaceVariant)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _starting ? null : _startContainer,
                  icon: _starting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow),
                  label: Text(_starting ? tr.container_detail_starting : tr.container_detail_start_btn),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: _deleting ? null : _deleteContainer,
                  icon: _deleting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_outline),
                  label: Text(_deleting ? tr.container_detail_delete_btn : tr.container_detail_delete_title),
                ),
              ],
              if (state == 'FAILED')
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
  StreamSubscription<dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.channel.stream.listen(
      (data) {
        if (!mounted) return;
        final text = switch (data) {
          final String s => s,
          final List<int> bytes => String.fromCharCodes(bytes),
          _ => data.toString(),
        };
        if (text.isEmpty) return;
        setState(() {
          _connected = true;
          _lines.add(text);
        });
        _scrollToBottom();
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _connected = false;
          _lines.add(context.tr.container_detail_failed(error.toString()));
        });
      },
      onDone: () {
        if (!mounted) return;
        setState(() {
          _connected = false;
          _lines.add(context.tr.container_detail_console_closed);
        });
      },
      cancelOnError: false,
    );
  }

  void _sendCommand(String cmd) {
    if (cmd.trim().isEmpty || !_connected) return;
    final line = cmd.endsWith('\n') ? cmd : '$cmd\n';
    widget.channel.sink.add(line);
    setState(() => _lines.add('> ${cmd.trim()}'));
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
    _subscription?.cancel();
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
