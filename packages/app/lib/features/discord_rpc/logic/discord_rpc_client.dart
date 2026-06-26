import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:win32/win32.dart';

const List<String> _discordIpcEnvPriority = <String>[
  'XDG_RUNTIME_DIR',
  'TMPDIR',
  'TMP',
  'TEMP',
];

List<String> buildDiscordUnixIpcCandidates({
  required Map<String, String> environment,
}) {
  final directories = <String>[];
  for (final key in _discordIpcEnvPriority) {
    final value = environment[key]?.trim();
    if (value != null && value.isNotEmpty && !directories.contains(value)) {
      directories.add(value);
    }
  }
  if (!directories.contains('/tmp')) {
    directories.add('/tmp');
  }

  final candidates = <String>[];
  for (final directory in directories) {
    for (var index = 0; index < 10; index += 1) {
      candidates.add(path.posix.join(directory, 'discord-ipc-$index'));
    }
  }
  return candidates;
}

List<String> buildDiscordWindowsIpcCandidates() {
  return List<String>.generate(
    10,
    (index) =>
        r'\\.\pipe\discord-ipc-'
        '$index',
    growable: false,
  );
}

bool isDiscordRpcTransportSupported({
  required bool isWeb,
  required bool isLinux,
  required bool isMacOS,
  required bool isWindows,
}) {
  if (isWeb) {
    return false;
  }
  return isLinux || isMacOS || isWindows;
}

class DiscordRpcClient {
  DiscordRpcClient({this.timeout = const Duration(seconds: 10)});

  static const int _handshakeOpcode = 0;
  static const int _frameOpcode = 1;
  static const int _closeOpcode = 2;
  static const int _pingOpcode = 3;
  static const int _pongOpcode = 4;

  final Duration timeout;
  final Uuid _uuid = const Uuid();
  final List<int> _incomingBytes = <int>[];
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests =
      <String, Completer<Map<String, dynamic>>>{};
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  _DiscordRpcTransport? _transport;
  StreamSubscription<Uint8List>? _transportSubscription;
  Completer<Map<String, dynamic>>? _readyCompleter;
  String? _connectedEndpoint;

  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  bool get isConnected => _transport != null;

  String? get connectedEndpoint => _connectedEndpoint;

  Future<void> connect({required String clientId}) async {
    await AppDiagnostics.logInfo(
      'Discord RPC client connect requested',
      data: <String, Object?>{
        'clientId': _maskClientId(clientId),
        'timeoutMs': timeout.inMilliseconds,
      },
    );
    await close();
    final transport = await _connectTransport();
    _bindTransport(transport);
    _connectedEndpoint = transport.endpoint;
    _readyCompleter = Completer<Map<String, dynamic>>();
    await AppDiagnostics.logInfo(
      'Discord RPC handshake sent',
      data: <String, Object?>{
        'endpoint': transport.endpoint,
        'clientId': _maskClientId(clientId),
      },
    );
    await _writeJsonFrame(_handshakeOpcode, <String, dynamic>{
      'v': 1,
      'client_id': clientId,
    });

    final readyPayload = await _readyCompleter!.future.timeout(timeout);
    await AppDiagnostics.logInfo(
      'Discord RPC ready event received',
      data: _commandResponseLogData(
        'HANDSHAKE',
        readyPayload,
        endpoint: transport.endpoint,
      ),
    );
  }

  Future<Map<String, dynamic>> authorize({
    required String clientId,
    required List<String> scopes,
    String? rpcToken,
    String? username,
    String? responseType,
    String? state,
    String? prompt,
    String? codeChallenge,
    String? codeChallengeMethod,
  }) {
    return _sendCommand(
      'AUTHORIZE',
      args: <String, dynamic>{
        'client_id': clientId,
        'scopes': scopes,
        'response_type': ?_normalize(responseType),
        'state': ?_normalize(state),
        'prompt': ?_normalize(prompt),
        'code_challenge': ?_normalize(codeChallenge),
        'code_challenge_method': ?_normalize(codeChallengeMethod),
        'rpc_token': ?_normalize(rpcToken),
        'username': ?_normalize(username),
      },
    );
  }

  Future<Map<String, dynamic>> authenticate(String accessToken) {
    return _sendCommand(
      'AUTHENTICATE',
      args: <String, dynamic>{'access_token': accessToken},
    );
  }

  Future<Map<String, dynamic>> setActivity({
    required int pid,
    required Map<String, dynamic> activity,
  }) {
    return _sendCommand(
      'SET_ACTIVITY',
      args: <String, dynamic>{'pid': pid, 'activity': activity},
    );
  }

  Future<void> close() async {
    final transport = _transport;
    final subscription = _transportSubscription;
    final endpoint = _connectedEndpoint;
    final pendingRequests = _pendingRequests.length;
    _transport = null;
    _transportSubscription = null;
    _connectedEndpoint = null;
    _incomingBytes.clear();

    if (subscription != null) {
      await subscription.cancel();
    }

    if (transport != null) {
      try {
        await transport.close();
      } catch (_) {}
    }

    _completePendingWithError(StateError('Discord RPC connection closed.'));

    if (transport != null || subscription != null || endpoint != null) {
      await AppDiagnostics.logInfo(
        'Discord RPC client connection closed',
        data: <String, Object?>{
          'endpoint': ?endpoint,
          'pendingRequests': pendingRequests,
        },
      );
    }
  }

  Future<_DiscordRpcTransport> _connectTransport() async {
    if (kIsWeb) {
      throw UnsupportedError('Discord RPC is not available on web builds.');
    }
    if (Platform.isWindows) {
      return _connectWindowsPipeTransport();
    }
    if (!(Platform.isLinux || Platform.isMacOS)) {
      throw UnsupportedError(
        'Discord RPC is currently available only on Linux and macOS builds.',
      );
    }
    return _connectUnixSocketTransport();
  }

  Future<_DiscordRpcTransport> _connectUnixSocketTransport() async {
    Object? firstError;
    final candidates = buildDiscordUnixIpcCandidates(
      environment: Platform.environment,
    );
    await AppDiagnostics.logInfo(
      'Discord RPC socket discovery started',
      data: <String, Object?>{
        'platform': defaultTargetPlatform.name,
        'candidateCount': candidates.length,
      },
    );
    for (final candidate in candidates) {
      await AppDiagnostics.logInfo(
        'Discord RPC socket candidate attempt',
        data: <String, Object?>{'candidate': candidate},
      );
      try {
        final address = InternetAddress(
          candidate,
          type: InternetAddressType.unix,
        );
        final socket = await Socket.connect(address, 0, timeout: timeout);
        await AppDiagnostics.logInfo(
          'Discord RPC socket connected',
          data: <String, Object?>{'candidate': candidate},
        );
        return _DiscordRpcSocketTransport(socket, candidate);
      } catch (error) {
        firstError ??= error;
        await AppDiagnostics.logInfo(
          'Discord RPC socket candidate unavailable',
          data: <String, Object?>{
            'candidate': candidate,
            'error': _truncateLogValue(error.toString()),
          },
        );
      }
    }

    await AppDiagnostics.logInfo(
      'Discord RPC socket discovery failed',
      data: <String, Object?>{
        'error': _truncateLogValue((firstError ?? 'unknown').toString()),
      },
    );

    throw SocketException(
      'Unable to connect to the local Discord IPC socket.',
      osError: firstError is OSError ? firstError : null,
    );
  }

  Future<_DiscordRpcTransport> _connectWindowsPipeTransport() async {
    final candidates = buildDiscordWindowsIpcCandidates();
    final deadline = DateTime.now().add(timeout);
    Object? firstError;

    await AppDiagnostics.logInfo(
      'Discord RPC pipe discovery started',
      data: <String, Object?>{
        'platform': defaultTargetPlatform.name,
        'candidateCount': candidates.length,
      },
    );

    while (DateTime.now().isBefore(deadline)) {
      for (final candidate in candidates) {
        await AppDiagnostics.logInfo(
          'Discord RPC pipe candidate attempt',
          data: <String, Object?>{'candidate': candidate},
        );
        try {
          final handle = _openWindowsPipeHandle(candidate);
          await AppDiagnostics.logInfo(
            'Discord RPC pipe connected',
            data: <String, Object?>{'candidate': candidate},
          );
          return _DiscordRpcWindowsPipeTransport(
            handle,
            candidate,
            pollInterval: const Duration(milliseconds: 50),
          );
        } catch (error) {
          firstError ??= error;
          await AppDiagnostics.logInfo(
            'Discord RPC pipe candidate unavailable',
            data: <String, Object?>{
              'candidate': candidate,
              'error': _truncateLogValue(error.toString()),
            },
          );
        }
      }

      await Future<void>.delayed(const Duration(milliseconds: 120));
    }

    await AppDiagnostics.logInfo(
      'Discord RPC pipe discovery failed',
      data: <String, Object?>{
        'error': _truncateLogValue((firstError ?? 'unknown').toString()),
      },
    );

    throw SocketException(
      'Unable to connect to the local Discord IPC named pipe.',
      osError:
          firstError is _DiscordRpcWindowsPipeException
              ? OSError(firstError.message, firstError.errorCode)
              : null,
    );
  }

  int _openWindowsPipeHandle(String candidate) {
    final pipeName = candidate.toNativeUtf16();
    try {
      final result = CreateFile(
        pipeName,
        GENERIC_READ | GENERIC_WRITE,
        0,
        nullptr,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0,
      );
      final handle = result;
      if (handle != INVALID_HANDLE_VALUE) {
        return handle;
      }

      throw _DiscordRpcWindowsPipeException(
        'CreateFile failed for $candidate',
        GetLastError(),
      );
    } finally {
      calloc.free(pipeName);
    }
  }

  void _bindTransport(_DiscordRpcTransport transport) {
    _transport = transport;
    _transportSubscription = transport.stream.listen(
      _handleTransportData,
      onError: _handleTransportError,
      onDone: _handleTransportDone,
      cancelOnError: true,
    );
  }

  void _handleTransportData(Uint8List chunk) {
    _incomingBytes.addAll(chunk);

    while (_incomingBytes.length >= 8) {
      final header = Uint8List.fromList(_incomingBytes.sublist(0, 8));
      final headerView = ByteData.sublistView(header);
      final opcode = headerView.getUint32(0, Endian.little);
      final length = headerView.getUint32(4, Endian.little);
      if (_incomingBytes.length < 8 + length) {
        return;
      }

      final payloadBytes = Uint8List.fromList(
        _incomingBytes.sublist(8, 8 + length),
      );
      _incomingBytes.removeRange(0, 8 + length);
      unawaited(_processFrame(opcode, payloadBytes));
    }
  }

  Future<void> _processFrame(int opcode, Uint8List payloadBytes) async {
    switch (opcode) {
      case _frameOpcode:
        if (payloadBytes.isEmpty) {
          return;
        }
        final decoded = jsonDecode(utf8.decode(payloadBytes));
        if (decoded is! Map) {
          return;
        }
        final payload = Map<String, dynamic>.from(decoded);
        final nonce = _normalize(payload['nonce']?.toString());
        final isError = (payload['evt'] ?? '').toString() == 'ERROR';
        final evt = (payload['evt'] ?? '').toString();

        if (isError || evt == 'READY' || evt.isNotEmpty) {
          await AppDiagnostics.logInfo(
            isError
                ? 'Discord RPC error frame received'
                : 'Discord RPC event frame received',
            data: _eventLogData(payload, endpoint: _connectedEndpoint),
          );
        }

        if (isError && nonce != null && _pendingRequests.containsKey(nonce)) {
          final completer = _pendingRequests.remove(nonce)!;
          if (!completer.isCompleted) {
            completer.completeError(_rpcErrorFromPayload(payload));
          }
        } else if (nonce != null && _pendingRequests.containsKey(nonce)) {
          final completer = _pendingRequests.remove(nonce)!;
          if (!completer.isCompleted) {
            completer.complete(payload);
          }
        }

        if (_readyCompleter != null && !_readyCompleter!.isCompleted) {
          if (evt == 'READY') {
            _readyCompleter!.complete(payload);
          } else if (isError) {
            _readyCompleter!.completeError(_rpcErrorFromPayload(payload));
          }
        }

        _eventsController.add(payload);
        return;
      case _pingOpcode:
        await AppDiagnostics.logInfo(
          'Discord RPC ping received',
          data: <String, Object?>{
            if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
            'payloadBytes': payloadBytes.length,
          },
        );
        await _writeRawFrame(_pongOpcode, payloadBytes);
        return;
      case _closeOpcode:
        await AppDiagnostics.logInfo(
          'Discord RPC close frame received',
          data: <String, Object?>{
            if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
            'payloadBytes': payloadBytes.length,
          },
        );
        _eventsController.add(<String, dynamic>{
          'evt': 'DISCONNECTED',
          'data': <String, dynamic>{'reason': 'remote_close'},
        });
        await close();
        return;
      default:
        return;
    }
  }

  void _handleTransportError(Object error, [StackTrace? stackTrace]) {
    unawaited(
      AppDiagnostics.logInfo(
        'Discord RPC transport error',
        data: <String, Object?>{
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
          'error': _truncateLogValue(error.toString()),
        },
      ),
    );
    _eventsController.add(<String, dynamic>{
      'evt': 'DISCONNECTED',
      'data': <String, dynamic>{'reason': error.toString()},
    });
    unawaited(close());
  }

  void _handleTransportDone() {
    unawaited(
      AppDiagnostics.logInfo(
        'Discord RPC transport closed by peer',
        data: <String, Object?>{
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
        },
      ),
    );
    _eventsController.add(<String, dynamic>{
      'evt': 'DISCONNECTED',
      'data': const <String, dynamic>{'reason': 'transport_done'},
    });
    unawaited(close());
  }

  Future<Map<String, dynamic>> _sendCommand(
    String command, {
    required Map<String, dynamic> args,
    String? event,
  }) async {
    if (_transport == null) {
      throw StateError('Discord RPC is not connected.');
    }

    final nonce = _uuid.v4();
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[nonce] = completer;

    await AppDiagnostics.logInfo(
      'Discord RPC command sent',
      data: _commandRequestLogData(
        command,
        args,
        event: event,
        endpoint: _connectedEndpoint,
      ),
    );

    await _writeJsonFrame(_frameOpcode, <String, dynamic>{
      'cmd': command,
      'nonce': nonce,
      'evt': ?_normalize(event),
      'args': args,
    });

    try {
      final response = await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingRequests.remove(nonce);
          throw TimeoutException('Discord RPC command timed out: $command');
        },
      );
      await AppDiagnostics.logInfo(
        'Discord RPC command completed',
        data: _commandResponseLogData(
          command,
          response,
          endpoint: _connectedEndpoint,
        ),
      );
      return response;
    } catch (error) {
      await AppDiagnostics.logInfo(
        'Discord RPC command failed',
        data: <String, Object?>{
          'command': command,
          if (_connectedEndpoint != null) 'endpoint': _connectedEndpoint,
          'error': _truncateLogValue(error.toString()),
        },
      );
      rethrow;
    }
  }

  Future<void> _writeJsonFrame(int opcode, Map<String, dynamic> payload) async {
    await _writeRawFrame(opcode, utf8.encode(jsonEncode(payload)));
  }

  Future<void> _writeRawFrame(int opcode, List<int> payloadBytes) async {
    final transport = _transport;
    if (transport == null) {
      throw StateError('Discord RPC transport is not connected.');
    }

    final header =
        ByteData(8)
          ..setUint32(0, opcode, Endian.little)
          ..setUint32(4, payloadBytes.length, Endian.little);

    await transport.write(<int>[
      ...header.buffer.asUint8List(),
      ...payloadBytes,
    ]);
  }

  void _completePendingWithError(Object error) {
    for (final completer in _pendingRequests.values.toList(growable: false)) {
      if (!completer.isCompleted) {
        completer.completeError(error);
      }
    }
    _pendingRequests.clear();

    final readyCompleter = _readyCompleter;
    _readyCompleter = null;
    if (readyCompleter != null && !readyCompleter.isCompleted) {
      readyCompleter.completeError(error);
    }
  }
}

abstract class _DiscordRpcTransport {
  String get endpoint;
  Stream<Uint8List> get stream;

  Future<void> write(List<int> bytes);
  Future<void> close();
}

class _DiscordRpcSocketTransport implements _DiscordRpcTransport {
  _DiscordRpcSocketTransport(this._socket, this.endpoint);

  final Socket _socket;

  @override
  final String endpoint;

  @override
  Stream<Uint8List> get stream => _socket;

  @override
  Future<void> write(List<int> bytes) async {
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> close() async {
    await _socket.close();
  }
}

class _DiscordRpcWindowsPipeTransport implements _DiscordRpcTransport {
  _DiscordRpcWindowsPipeTransport(
    this._handle,
    this.endpoint, {
    required this.pollInterval,
  }) {
    _pollTimer = Timer.periodic(pollInterval, (_) {
      if (_polling || _closed) {
        return;
      }
      unawaited(_pollOnce());
    });
  }

  static const int _maxReadChunkSize = 64 * 1024;

  final int _handle;
  final Duration pollInterval;
  final StreamController<Uint8List> _streamController =
      StreamController<Uint8List>.broadcast();

  Timer? _pollTimer;
  bool _polling = false;
  bool _closed = false;

  @override
  final String endpoint;

  @override
  Stream<Uint8List> get stream => _streamController.stream;

  @override
  Future<void> write(List<int> bytes) async {
    if (_closed) {
      throw StateError('Discord RPC named pipe is closed.');
    }
    if (bytes.isEmpty) {
      return;
    }

    final buffer = calloc<Uint8>(bytes.length);
    final bytesWritten = calloc<Uint32>();
    try {
      buffer.asTypedList(bytes.length).setAll(0, bytes);
      final result = WriteFile(
        _handle,
        buffer,
        bytes.length,
        bytesWritten,
        nullptr,
      );
      if (result == 0 || bytesWritten.value != bytes.length) {
        throw _DiscordRpcWindowsPipeException(
          'WriteFile failed for $endpoint',
          GetLastError(),
        );
      }
    } finally {
      calloc.free(buffer);
      calloc.free(bytesWritten);
    }
  }

  Future<void> _pollOnce() async {
    if (_closed) {
      return;
    }

    _polling = true;
    try {
      while (!_closed) {
        final available = _peekAvailableBytes();
        if (available <= 0) {
          break;
        }

        final chunk = _readChunk(available);
        if (chunk.isEmpty) {
          break;
        }
        _streamController.add(chunk);
      }
    } catch (error, stackTrace) {
      if (!_streamController.isClosed) {
        _streamController.addError(error, stackTrace);
      }
      await close();
    } finally {
      _polling = false;
    }
  }

  int _peekAvailableBytes() {
    final bytesAvailable = calloc<Uint32>();
    try {
      final result = PeekNamedPipe(
        _handle,
        nullptr,
        0,
        nullptr,
        bytesAvailable,
        nullptr,
      );
      if (result == 0) {
        throw _DiscordRpcWindowsPipeException(
          'PeekNamedPipe failed for $endpoint',
          GetLastError(),
        );
      }
      return bytesAvailable.value;
    } finally {
      calloc.free(bytesAvailable);
    }
  }

  Uint8List _readChunk(int bytesAvailable) {
    final bytesToRead =
        bytesAvailable > _maxReadChunkSize ? _maxReadChunkSize : bytesAvailable;
    final buffer = calloc<Uint8>(bytesToRead);
    final bytesRead = calloc<Uint32>();
    try {
      final result = ReadFile(_handle, buffer, bytesToRead, bytesRead, nullptr);
      if (result == 0) {
        final errorCode = GetLastError();
        if (errorCode == ERROR_MORE_DATA && bytesRead.value > 0) {
          return Uint8List.fromList(buffer.asTypedList(bytesRead.value));
        }
        throw _DiscordRpcWindowsPipeException(
          'ReadFile failed for $endpoint',
          errorCode,
        );
      }

      if (bytesRead.value == 0) {
        return Uint8List(0);
      }

      return Uint8List.fromList(buffer.asTypedList(bytesRead.value));
    } finally {
      calloc.free(buffer);
      calloc.free(bytesRead);
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    CloseHandle(_handle);
    if (!_streamController.isClosed) {
      await _streamController.close();
    }
  }
}

class _DiscordRpcWindowsPipeException implements Exception {
  const _DiscordRpcWindowsPipeException(this.message, this.errorCode);

  final String message;
  final int errorCode;

  @override
  String toString() => '$message (error $errorCode)';
}

Object _rpcErrorFromPayload(Map<String, dynamic> payload) {
  final data = payload['data'];
  final message =
      data is Map && data['message'] != null
          ? data['message'].toString()
          : 'Discord RPC request failed.';
  final code = data is Map ? data['code']?.toString() : null;
  return StateError(code == null ? message : '$message (code $code)');
}

String? _normalize(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, Object?> _commandRequestLogData(
  String command,
  Map<String, dynamic> args, {
  String? event,
  String? endpoint,
}) {
  final data = <String, Object?>{
    'command': command,
    'endpoint': ?endpoint,
    'event': ?_normalize(event),
  };

  switch (command) {
    case 'AUTHORIZE':
      final scopes = args['scopes'];
      data.addAll(<String, Object?>{
        'clientId': _maskClientId((args['client_id'] ?? '').toString()),
        'scopesCount': scopes is List ? scopes.length : 0,
        'responseType': _normalize(args['response_type']?.toString()),
        'hasCodeChallenge':
            _normalize(args['code_challenge']?.toString()) != null,
        'codeChallengeMethod': _normalize(
          args['code_challenge_method']?.toString(),
        ),
        'hasRpcToken': _normalize(args['rpc_token']?.toString()) != null,
        'hasUsername': _normalize(args['username']?.toString()) != null,
      });
      break;
    case 'AUTHENTICATE':
      data.addAll(<String, Object?>{
        'hasAccessToken': _normalize(args['access_token']?.toString()) != null,
      });
      break;
    case 'SET_ACTIVITY':
      final activity =
          args['activity'] is Map<String, dynamic>
              ? args['activity'] as Map<String, dynamic>
              : Map<String, dynamic>.from(
                (args['activity'] as Map?) ?? const <Object?, Object?>{},
              );
      data.addAll(<String, Object?>{
        'pid': args['pid'],
        ..._activityLogData(activity),
      });
      break;
    default:
      data.addAll(<String, Object?>{'argCount': args.length});
      break;
  }

  return data;
}

Map<String, Object?> _commandResponseLogData(
  String command,
  Map<String, dynamic> payload, {
  String? endpoint,
}) {
  final data = <String, Object?>{
    'command': command,
    'endpoint': ?endpoint,
    'event': ?_normalize(payload['evt']?.toString()),
    'hasNonce': payload['nonce'] != null,
  };
  final responseData = payload['data'];
  final user = responseData is Map ? responseData['user'] : null;
  final userId = user is Map ? _normalize(user['id']?.toString()) : null;

  switch (command) {
    case 'HANDSHAKE':
      data.addAll(<String, Object?>{
        'ready': (payload['evt'] ?? '').toString() == 'READY',
      });
      break;
    case 'AUTHORIZE':
      data.addAll(<String, Object?>{
        'authorizationCodeReceived':
            responseData is Map &&
            _normalize(responseData['code']?.toString()) != null,
      });
      break;
    case 'AUTHENTICATE':
      data.addAll(<String, Object?>{
        'hasUser': user is Map,
        'userId': ?userId,
      });
      break;
    case 'SET_ACTIVITY':
      data.addAll(<String, Object?>{'accepted': true});
      break;
  }

  return data;
}

Map<String, Object?> _eventLogData(
  Map<String, dynamic> payload, {
  String? endpoint,
}) {
  final data = payload['data'];
  return <String, Object?>{
    'endpoint': ?endpoint,
    'event': ?_normalize(payload['evt']?.toString()),
    'command': ?_normalize(payload['cmd']?.toString()),
    'hasNonce': payload['nonce'] != null,
    if (data is Map &&
        data['code'] != null &&
        (payload['evt'] ?? '') == 'ERROR')
      'code': data['code'],
    if (data is Map && data['message'] != null)
      'message': _truncateLogValue(data['message'].toString()),
  };
}

Map<String, Object?> _activityLogData(Map<String, dynamic> activity) {
  final timestamps = activity['timestamps'];
  final assets = activity['assets'];
  final largeImage =
      assets is Map ? _normalize(assets['large_image']?.toString()) : null;
  return <String, Object?>{
    if (_normalize(activity['details']?.toString()) case final value?)
      'details': _truncateLogValue(value),
    if (_normalize(activity['state']?.toString()) case final value?)
      'state': _truncateLogValue(value),
    'hasTimestamps': timestamps is Map,
    'largeImage': ?largeImage,
  };
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

String _truncateLogValue(String value, {int maxLength = 160}) {
  if (value.length <= maxLength) {
    return value;
  }
  return '${value.substring(0, maxLength)}...';
}
