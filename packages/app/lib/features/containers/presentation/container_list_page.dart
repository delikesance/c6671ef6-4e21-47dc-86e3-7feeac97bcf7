import 'package:flutter/material.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:bot_creator/features/containers/presentation/container_detail_page.dart';

class ContainerListPage extends StatefulWidget {
  const ContainerListPage({super.key});

  @override
  State<ContainerListPage> createState() => _ContainerListPageState();
}

class _ContainerListPageState extends State<ContainerListPage> {
  MainApiClient? _client;
  List<ContainerInfo>? _containers;
  bool _loading = true;
  bool _initError = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (session == null || session.isExpired || !config.isConfigured) {
        if (mounted) setState(() { _initError = true; _loading = false; });
        return;
      }
      _client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      await _load();
    } catch (e) {
      if (mounted) setState(() { _initError = true; _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _load() async {
    if (_client == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final containers = await _client!.listContainers();
      if (mounted) setState(() { _containers = containers; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
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

  IconData _stateIcon(String state) {
    switch (state) {
      case 'RUNNING': return Icons.check_circle;
      case 'PENDING': return Icons.hourglass_top;
      case 'STOPPED': case 'STOPPING': return Icons.stop_circle;
      case 'FAILED': return Icons.error;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.container_list_title),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final deployed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => ContainerDeployPage(client: _client),
                ),
              );
              if (deployed == true) _load();
            },
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_initError) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(context.tr.container_list_session_missing, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(context.tr.container_list_session_hint, style: TextStyle(color: colorScheme.onSurfaceVariant)),
        ]),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(context.tr.container_list_error, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(onPressed: _load, icon: const Icon(Icons.refresh), label: Text(context.tr.container_list_retry)),
        ]),
      );
    }

    if (_containers == null || _containers!.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.storage_rounded, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(context.tr.container_list_empty, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(context.tr.container_list_empty_hint, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () async {
              final deployed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => ContainerDeployPage(client: _client)),
              );
              if (deployed == true) _load();
            },
            icon: const Icon(Icons.add),
            label: Text(context.tr.container_list_deploy_btn),
          ),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _containers!.length,
        itemBuilder: (context, index) {
          final c = _containers![index];
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: InkWell(
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ContainerDetailPage(containerId: c.id, client: _client),
                ));
                _load();
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(_stateIcon(c.state), color: _stateColor(c.state), size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.image, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text('${c.cpuMillis} CPU · ${c.memoryMb}MB', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _stateColor(c.state).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                        child: Text(_stateLabel(c.state, context.tr), style: TextStyle(color: _stateColor(c.state), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Text(_formatExpiry(c.expiresAt, context.tr), style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11)),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatExpiry(DateTime dt, AppLocalizations tr) {
    if (dt.isBefore(DateTime.now())) return tr.container_list_expired;
    final diff = dt.difference(DateTime.now());
    if (diff.inMinutes < 60) return tr.container_list_expiry_minutes(diff.inMinutes);
    if (diff.inHours < 24) return tr.container_list_expiry_hours(diff.inHours, diff.inMinutes % 60);
    return tr.container_list_expiry_days(diff.inDays, diff.inHours % 24);
  }
}
