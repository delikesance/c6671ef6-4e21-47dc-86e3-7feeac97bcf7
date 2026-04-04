import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/utils/app_diagnostics.dart';
import 'package:bot_creator/utils/discord_rich_presence.dart';
import 'package:bot_creator/utils/discord_rpc_client.dart';
import 'package:bot_creator/utils/discord_rpc_settings.dart';
import 'package:flutter/foundation.dart';

enum DiscordRpcRuntimeState {
  disabled,
  unsupportedPlatform,
  transportUnsupported,
  notConfigured,
  disconnected,
  needsAuthorization,
  authorizationCodePendingExchange,
  connecting,
  authorizing,
  exchangingCode,
  authenticating,
  connected,
  error,
}

class DiscordRpcSnapshot {
  const DiscordRpcSnapshot({
    required this.config,
    required this.runtimeState,
    this.session,
    this.lastError,
    this.connectedEndpoint,
    this.controllingBotId,
    this.controllingBotName,
    this.lastPresence,
  });

  final DiscordRpcConfig config;
  final DiscordRpcRuntimeState runtimeState;
  final DiscordRpcSession? session;
  final String? lastError;
  final String? connectedEndpoint;
  final String? controllingBotId;
  final String? controllingBotName;
  final DiscordRichPresence? lastPresence;

  bool get hasSession => session != null;

  bool get isConnected => runtimeState == DiscordRpcRuntimeState.connected;
}

class DiscordRpcService {
  DiscordRpcService._({DiscordRpcClient Function()? clientFactory})
    : _clientFactory = clientFactory ?? (() => DiscordRpcClient());

  static final DiscordRpcService instance = DiscordRpcService._();

  @visibleForTesting
  factory DiscordRpcService.test({DiscordRpcClient Function()? clientFactory}) {
    return DiscordRpcService._(clientFactory: clientFactory);
  }

  final StreamController<DiscordRpcSnapshot> _snapshotController =
      StreamController<DiscordRpcSnapshot>.broadcast();
  final DiscordRpcClient Function() _clientFactory;

  DiscordRpcConfig _config = const DiscordRpcConfig();
  DiscordRpcSession? _session;
  DiscordRpcRuntimeState _runtimeState = DiscordRpcRuntimeState.disabled;
  DiscordRpcClient? _client;
  StreamSubscription<Map<String, dynamic>>? _clientEventsSubscription;
  DiscordRichPresence? _lastPresence;
  String? _lastError;
  String? _connectedEndpoint;
  String? _controllingBotId;
  String? _controllingBotName;
  DateTime? _presenceStartedAt;
  bool _initialized = false;
  Future<DiscordRpcSnapshot>? _initializeFuture;
  Future<void> _serialQueue = Future<void>.value();

  Stream<DiscordRpcSnapshot> get snapshots => _snapshotController.stream;

  Future<DiscordRpcSnapshot> initialize() {
    if (_initialized) {
      return Future<DiscordRpcSnapshot>.value(_buildSnapshot());
    }
    final existing = _initializeFuture;
    if (existing != null) {
      return existing;
    }

    final future = _performInitialize();
    _initializeFuture = future;
    return future.whenComplete(() {
      _initializeFuture = null;
    });
  }

  Future<DiscordRpcSnapshot> getSnapshot() async {
    await initialize();
    return _buildSnapshot();
  }

  Future<DiscordRpcSnapshot> updateConfig({
    required bool enabled,
    required String clientId,
    required String clientSecret,
    required String brokerUrl,
  }) {
    return _enqueue(() async {
      await initialize();
      final legacyFieldsIgnored = <String, Object?>{
        if (clientId.trim().isNotEmpty) 'clientId': _maskClientId(clientId),
        if (clientSecret.trim().isNotEmpty) 'clientSecret': 'ignored',
        if (brokerUrl.trim().isNotEmpty) 'brokerUrl': 'ignored',
      };
      final nextConfig = DiscordRpcConfig(enabled: enabled);
      _config = nextConfig;
      await DiscordRpcSettingsStore.saveConfig(nextConfig);
      await AppDiagnostics.logInfo(
        'Discord RPC config updated',
        data: <String, Object?>{
          ..._configLogData(nextConfig),
          if (legacyFieldsIgnored.isNotEmpty)
            'legacyFieldsIgnored': legacyFieldsIgnored,
        },
      );

      if (_session != null) {
        await AppDiagnostics.logInfo(
          'Discord RPC legacy OAuth session cleared after config change',
          data: _sessionLogData(_session),
        );
      }
      _session = null;
      await DiscordRpcSettingsStore.clearSession();

      if (!enabled) {
        await AppDiagnostics.logInfo(
          'Discord RPC disabled by configuration',
          data: <String, Object?>{
            'hadConnectedClient': _client?.isConnected == true,
          },
        );
        await _closeClient();
      }

      _lastError = null;
      _runtimeState = _deriveIdleState();
      _emitSnapshot();

      if (nextConfig.enabled) {
        unawaited(connectIfPossible());
      }

      return _buildSnapshot();
    });
  }

  Future<DiscordRpcSnapshot> connectIfPossible() {
    return _enqueue(() async {
      await initialize();
      return _connectWithStoredSessionLocked();
    });
  }

  Future<DiscordRpcSnapshot> authenticateOrAuthorize({
    bool forceReauthorize = false,
  }) {
    return _enqueue(() async {
      await initialize();
      await AppDiagnostics.logInfo(
        'Discord RPC manual refresh requested',
        data: <String, Object?>{
          'forceReauthorize': forceReauthorize,
          ..._configLogData(_config),
        },
      );
      if (forceReauthorize && _session != null) {
        await AppDiagnostics.logInfo(
          'Discord RPC legacy OAuth session cleared before manual refresh',
          data: _sessionLogData(_session),
        );
      }
      _session = null;
      await DiscordRpcSettingsStore.clearSession();
      return _connectWithStoredSessionLocked();
    });
  }

  Future<DiscordRpcSnapshot> disconnect({bool clearSession = false}) {
    return _enqueue(() async {
      await initialize();
      await AppDiagnostics.logInfo(
        'Discord RPC disconnect requested',
        data: <String, Object?>{
          'clearSession': clearSession,
          'hasSession': _session != null,
          'hasClient': _client?.isConnected == true,
        },
      );

      if (_session != null) {
        await AppDiagnostics.logInfo(
          'Discord RPC legacy OAuth session cleared on disconnect',
          data: _sessionLogData(_session),
        );
      }
      _session = null;
      await DiscordRpcSettingsStore.clearSession();

      await _closeClient();
      _lastError = null;
      _runtimeState = _deriveIdleState();
      _emitSnapshot();
      return _buildSnapshot();
    });
  }

  Future<DiscordRpcSnapshot> syncBotRuntimeState({
    required Set<String> runningBotIds,
    required Map<String, String> botNamesById,
    required bool runnerModeEnabled,
    String? preferredBotId,
    String? preferredBotName,
    String? activeRunnerLabel,
  }) {
    return _enqueue(() async {
      await initialize();
      final previousPresenceFingerprint = _presenceFingerprint(_lastPresence);
      final previousBotId = _controllingBotId;

      if (runningBotIds.isEmpty) {
        _controllingBotId = null;
        _controllingBotName = null;
        _presenceStartedAt = null;
      } else {
        final sortedIds = runningBotIds.toList(growable: false)..sort();
        final resolvedBotId =
            preferredBotId != null && runningBotIds.contains(preferredBotId)
                ? preferredBotId
                : sortedIds.first;
        final resolvedBotName =
            (preferredBotId == resolvedBotId ? preferredBotName : null) ??
            botNamesById[resolvedBotId] ??
            resolvedBotId;
        if (_controllingBotId != resolvedBotId) {
          _presenceStartedAt = DateTime.now().toUtc();
        }
        _controllingBotId = resolvedBotId;
        _controllingBotName = resolvedBotName;
      }

      _lastPresence = buildBotCreatorRichPresence(
        runningBotIds: runningBotIds,
        botNamesById: botNamesById,
        runnerModeEnabled: runnerModeEnabled,
        preferredBotId: _controllingBotId,
        preferredBotName: _controllingBotName,
        activeRunnerLabel: activeRunnerLabel,
        startedAt: _presenceStartedAt,
      );
      final nextPresenceFingerprint = _presenceFingerprint(_lastPresence);
      if (previousBotId != _controllingBotId ||
          previousPresenceFingerprint != nextPresenceFingerprint) {
        await AppDiagnostics.logInfo(
          'Discord RPC runtime state synced',
          data: _presenceLogData(
            _lastPresence,
            runningBotCount: runningBotIds.length,
            controllingBotId: _controllingBotId,
            controllingBotName: _controllingBotName,
            runnerModeEnabled: runnerModeEnabled,
            activeRunnerLabel: activeRunnerLabel,
          ),
        );
      }
      _emitSnapshot();

      if (_runtimeState == DiscordRpcRuntimeState.connected &&
          _client != null &&
          _lastPresence != null) {
        try {
          await _pushPresence(_lastPresence!);
        } catch (error, stackTrace) {
          await AppDiagnostics.logError(
            'Discord RPC presence update failed',
            error,
            stackTrace,
            fatal: false,
          );
          _lastError = error.toString();
          _runtimeState = DiscordRpcRuntimeState.error;
          _emitSnapshot();
        }
      } else if (_config.enabled) {
        unawaited(connectIfPossible());
      }

      return _buildSnapshot();
    });
  }

  Future<DiscordRpcSnapshot> _performInitialize() async {
    final storedConfig = await DiscordRpcSettingsStore.loadConfig();
    final storedSession = await DiscordRpcSettingsStore.loadSession();
    _config = DiscordRpcConfig(enabled: storedConfig.enabled);
    _session = null;
    _lastPresence ??= _defaultDiscordRichPresence();
    _runtimeState = _deriveIdleState();
    _initialized = true;

    await DiscordRpcSettingsStore.saveConfig(_config);
    if (storedSession != null) {
      await DiscordRpcSettingsStore.clearSession();
    }

    await AppDiagnostics.logInfo(
      'Discord RPC service initialized',
      data: <String, Object?>{
        ..._configLogData(_config),
        'hadLegacySession': storedSession != null,
        'hasPresence': _lastPresence != null,
        'runtimeState': _runtimeState.name,
      },
    );
    _emitSnapshot();

    if (_config.enabled) {
      unawaited(connectIfPossible());
    }

    return _buildSnapshot();
  }

  Future<DiscordRpcSnapshot> _connectWithStoredSessionLocked() async {
    await AppDiagnostics.logInfo(
      'Discord RPC presence connect started',
      data: <String, Object?>{
        'runtimeState': _runtimeState.name,
        ..._configLogData(_config),
      },
    );
    if (!_isDesktopPlatform) {
      await AppDiagnostics.logInfo(
        'Discord RPC presence connect skipped',
        data: const <String, Object?>{'reason': 'unsupported_platform'},
      );
      _runtimeState = DiscordRpcRuntimeState.unsupportedPlatform;
      _emitSnapshot();
      return _buildSnapshot();
    }
    if (!_transportSupported) {
      await AppDiagnostics.logInfo(
        'Discord RPC presence connect skipped',
        data: const <String, Object?>{'reason': 'transport_unsupported'},
      );
      _runtimeState = DiscordRpcRuntimeState.transportUnsupported;
      _emitSnapshot();
      return _buildSnapshot();
    }
    if (!_config.enabled) {
      await AppDiagnostics.logInfo(
        'Discord RPC presence connect skipped',
        data: const <String, Object?>{'reason': 'disabled'},
      );
      _runtimeState = DiscordRpcRuntimeState.disabled;
      _emitSnapshot();
      return _buildSnapshot();
    }
    if (!_config.hasClientId) {
      await AppDiagnostics.logInfo(
        'Discord RPC presence connect skipped',
        data: const <String, Object?>{'reason': 'missing_client_id'},
      );
      _runtimeState = DiscordRpcRuntimeState.notConfigured;
      _emitSnapshot();
      return _buildSnapshot();
    }

    try {
      await _ensureClientConnected();
      _runtimeState = DiscordRpcRuntimeState.connected;
      _lastError = null;
      _emitSnapshot();
      await AppDiagnostics.logInfo(
        'Discord RPC local IPC ready for SET_ACTIVITY',
        data: <String, Object?>{
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
          'applicationId': _config.clientId,
        },
      );

      if (_lastPresence != null) {
        await _pushPresence(_lastPresence!);
      }
      return _buildSnapshot();
    } catch (error, stackTrace) {
      await AppDiagnostics.logError(
        'Discord RPC connect/set activity failed',
        error,
        stackTrace,
        fatal: false,
      );
      await _closeClient();
      _lastError = error.toString();
      _runtimeState = _runtimeStateForError(error);
      _emitSnapshot();
      return _buildSnapshot();
    }
  }

  Future<DiscordRpcClient> _ensureClientConnected() async {
    final existingClient = _client;
    if (existingClient != null && existingClient.isConnected) {
      await AppDiagnostics.logInfo(
        'Discord RPC reusing connected IPC client',
        data: <String, Object?>{
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
        },
      );
      return existingClient;
    }

    await _closeClient();
    final client = _clientFactory();
    _runtimeState = DiscordRpcRuntimeState.connecting;
    _emitSnapshot();
    await AppDiagnostics.logInfo(
      'Discord RPC opening IPC client connection',
      data: <String, Object?>{'clientId': _maskClientId(_config.clientId)},
    );

    await client.connect(clientId: _config.clientId);
    _client = client;
    _connectedEndpoint = client.connectedEndpoint;
    await AppDiagnostics.logInfo(
      'Discord RPC IPC client connected',
      data: <String, Object?>{
        if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
      },
    );
    _clientEventsSubscription = client.events.listen((payload) {
      unawaited(_handleClientEvent(payload));
    });
    _emitSnapshot();
    return client;
  }

  Future<void> _handleClientEvent(Map<String, dynamic> payload) async {
    final evt = (payload['evt'] ?? '').toString();
    if (evt == 'ERROR') {
      await AppDiagnostics.logInfo(
        'Discord RPC client error event received',
        data: <String, Object?>{
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
          'message': _extractDiscordRpcMessage(payload) ?? 'Discord RPC error.',
        },
      );
      _lastError = _extractDiscordRpcMessage(payload) ?? 'Discord RPC error.';
      _runtimeState = DiscordRpcRuntimeState.error;
      _emitSnapshot();
      return;
    }

    if (evt == 'DISCONNECTED') {
      await AppDiagnostics.logInfo(
        'Discord RPC client disconnected event received',
        data: <String, Object?>{
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
          'reason': _extractDiscordRpcMessage(payload) ?? 'disconnected',
        },
      );
      _connectedEndpoint = null;
      if (_runtimeState != DiscordRpcRuntimeState.disabled) {
        _runtimeState = _deriveIdleState();
        _emitSnapshot();
      }
    }
  }

  Future<void> _closeClient() async {
    final client = _client;
    final subscription = _clientEventsSubscription;
    final endpoint = _connectedEndpoint;
    _client = null;
    _clientEventsSubscription = null;
    _connectedEndpoint = null;

    if (client != null || subscription != null || endpoint != null) {
      await AppDiagnostics.logInfo(
        'Discord RPC closing IPC client',
        data: <String, Object?>{if (endpoint != null) 'endpoint': endpoint},
      );
    }

    if (subscription != null) {
      await subscription.cancel();
    }
    if (client != null) {
      await client.close();
    }
  }

  Future<void> _pushPresence(DiscordRichPresence presence) async {
    final client = _client;
    if (client == null) {
      throw StateError('Discord RPC client is not connected.');
    }
    await AppDiagnostics.logInfo(
      'Discord RPC pushing rich presence',
      data: _presenceLogData(
        presence,
        controllingBotId: _controllingBotId,
        controllingBotName: _controllingBotName,
      ),
    );
    await client.setActivity(pid: pid, activity: presence.toActivityJson());
  }

  DiscordRpcSnapshot _buildSnapshot() {
    return DiscordRpcSnapshot(
      config: _config,
      runtimeState: _runtimeState,
      session: _session,
      lastError: _lastError,
      connectedEndpoint: _connectedEndpoint,
      controllingBotId: _controllingBotId,
      controllingBotName: _controllingBotName,
      lastPresence: _lastPresence,
    );
  }

  void _emitSnapshot() {
    if (_snapshotController.isClosed) {
      return;
    }
    _snapshotController.add(_buildSnapshot());
  }

  DiscordRpcRuntimeState _deriveIdleState() {
    if (!_isDesktopPlatform) {
      return DiscordRpcRuntimeState.unsupportedPlatform;
    }
    if (!_transportSupported) {
      return DiscordRpcRuntimeState.transportUnsupported;
    }
    if (!_config.enabled) {
      return DiscordRpcRuntimeState.disabled;
    }
    if (!_config.hasClientId) {
      return DiscordRpcRuntimeState.notConfigured;
    }
    return DiscordRpcRuntimeState.disconnected;
  }

  DiscordRpcRuntimeState _runtimeStateForError(Object error) {
    if (error is UnsupportedError) {
      return _transportSupported
          ? DiscordRpcRuntimeState.unsupportedPlatform
          : DiscordRpcRuntimeState.transportUnsupported;
    }
    return DiscordRpcRuntimeState.error;
  }

  bool get _isDesktopPlatform {
    if (kIsWeb) {
      return false;
    }
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  bool get _transportSupported {
    if (kIsWeb) {
      return false;
    }
    return Platform.isLinux || Platform.isMacOS;
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _serialQueue = _serialQueue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

DiscordRichPresence _defaultDiscordRichPresence() {
  return buildBotCreatorRichPresence(
    runningBotIds: const <String>{},
    botNamesById: const <String, String>{},
    runnerModeEnabled: false,
  );
}

String? _extractDiscordRpcMessage(Map<String, dynamic> payload) {
  final data = payload['data'];
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  if (data is Map && data['reason'] != null) {
    return data['reason'].toString();
  }
  return _normalize(payload['message']?.toString());
}

String? _normalize(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, Object?> _configLogData(DiscordRpcConfig config) {
  return <String, Object?>{
    'enabled': config.enabled,
    'hasClientId': config.hasClientId,
    'clientId': _maskClientId(config.clientId),
    'exchangeMode': _exchangeModeLabel(config),
  };
}

Map<String, Object?> _sessionLogData(DiscordRpcSession? session) {
  if (session == null) {
    return const <String, Object?>{'hasSession': false};
  }
  return <String, Object?>{
    'hasSession': true,
    'expiresAt': session.expiresAt.toUtc().toIso8601String(),
    'isExpired': session.isExpired,
    'expiresSoon': session.expiresSoon(),
    'scopesCount': session.scopes.length,
    if (_normalize(session.userId) case final value?) 'userId': value,
    if (_normalize(session.username) case final value?) 'username': value,
    if (session.authorizedAt != null)
      'authorizedAt': session.authorizedAt!.toUtc().toIso8601String(),
  };
}

Map<String, Object?> _presenceLogData(
  DiscordRichPresence? presence, {
  int? runningBotCount,
  String? controllingBotId,
  String? controllingBotName,
  bool? runnerModeEnabled,
  String? activeRunnerLabel,
}) {
  return <String, Object?>{
    'hasPresence': presence != null,
    if (runningBotCount != null) 'runningBotCount': runningBotCount,
    if (_normalize(controllingBotId) case final value?)
      'controllingBotId': value,
    if (_normalize(controllingBotName) case final value?)
      'controllingBotName': value,
    if (runnerModeEnabled != null) 'runnerModeEnabled': runnerModeEnabled,
    if (_normalize(activeRunnerLabel) case final value?) 'runner': value,
    if (presence != null) ...<String, Object?>{
      'details': presence.details,
      if (_normalize(presence.state) case final value?) 'state': value,
      'hasStartTime': presence.startTime != null,
      if (presence.startTime != null)
        'startTime': presence.startTime!.toUtc().toIso8601String(),
    },
  };
}

String _presenceFingerprint(DiscordRichPresence? presence) {
  if (presence == null) {
    return '';
  }
  return jsonEncode(presence.toActivityJson());
}

String _exchangeModeLabel(DiscordRpcConfig config) {
  if (config.hasClientId) {
    return 'presence_only';
  }
  return 'not_configured';
}

String _maskClientId(String clientId) {
  final normalized = _normalize(clientId) ?? '';
  if (normalized.isEmpty) {
    return 'missing';
  }
  if (normalized.length <= 4) {
    return normalized;
  }
  return '...${normalized.substring(normalized.length - 4)}';
}
