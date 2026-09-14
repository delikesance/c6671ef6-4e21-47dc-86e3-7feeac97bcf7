import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppDiagnostics {
  static bool _initialized = false;
  static bool _crashlyticsEnabled = false;
  static bool _firebaseReady = false;
  static File? _logFile;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      final docs = await getAppStorageDirectory();
      final diagnosticsDir = Directory('${docs.path}/diagnostics');
      if (!await diagnosticsDir.exists()) {
        await diagnosticsDir.create(recursive: true);
      }
      _logFile = File('${diagnosticsDir.path}/startup_diagnostics.log');
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }
      await logInfo(
        'Diagnostics initialized',
        data: {
          'platform': defaultTargetPlatform.name,
          'mode': kReleaseMode
              ? 'release'
              : kProfileMode
              ? 'profile'
              : 'debug',
        },
      );
    } catch (error, stack) {
      debugPrint('Failed to initialize diagnostics storage: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  static Future<void> configureCrashlytics({
    required bool crashlyticsSupported,
    required bool firebaseReady,
  }) async {
    _crashlyticsEnabled = crashlyticsSupported && firebaseReady;
    _firebaseReady = firebaseReady;
    await logInfo(
      'Crashlytics configuration',
      data: {
        'supported': crashlyticsSupported,
        'firebaseReady': firebaseReady,
        'enabled': _crashlyticsEnabled,
      },
    );

    if (!_crashlyticsEnabled) {
      return;
    }

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      await FirebaseCrashlytics.instance.setCustomKey(
        'app_platform',
        defaultTargetPlatform.name,
      );
      await FirebaseCrashlytics.instance.setCustomKey(
        'app_mode',
        kReleaseMode
            ? 'release'
            : kProfileMode
            ? 'profile'
            : 'debug',
      );
    } catch (error, stack) {
      await logError(
        'Failed to configure Crashlytics collection',
        error,
        stack,
        fatal: false,
      );
    }
  }

  static void installGlobalErrorHandlers() {
    final previousFlutterOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Keep default debug error surface (red screen + console) so startup
      // issues are visible instead of silently rendering a blank frame.
      FlutterError.presentError(details);
      previousFlutterOnError?.call(details);

      // Layout overflow errors are non-fatal — the UI may have minor rendering issues
      // but the app can continue to function.
      // Flutter framework debug assertion errors (e.g. ListTile/ColoredBox conflicts,
      // missing Material ancestors) are also non-fatal validation warnings.
      final isLayoutError = details.exceptionAsString().contains('overflowed');
      final isDebugAssertion =
          details.stack?.toString().contains('._debug') ?? false;
      final isBenign = isBenignFlutterFrameworkError(
        details.exception,
        context: details.context?.toDescription(),
        library: details.library,
      );
      unawaited(
        recordFlutterError(
          details,
          fatal: !(isLayoutError || isDebugAssertion || isBenign),
        ),
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final fatal =
          !isBenignFlutterFrameworkError(error) &&
          !isTransientNetworkError(error);
      unawaited(
        logError('Uncaught platform error', error, stack, fatal: fatal),
      );
      return true;
    };
  }

  static Future<void> recordFlutterError(
    FlutterErrorDetails details, {
    required bool fatal,
  }) async {
    await logError(
      'Flutter framework error',
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: fatal,
      reason: details.context?.toDescription(),
      information: details.informationCollector
          ?.call()
          .map((item) => item.toString())
          .join(' | '),
    );
  }

  /// Mirrors a diagnostics line into the Crashlytics breadcrumb buffer so the
  /// Firebase console replays the sequence of events leading up to a crash.
  /// Crashlytics keeps the last 64 kB and evicts the oldest entries itself.
  static void logBreadcrumb(String message) {
    if (!_crashlyticsEnabled || !_firebaseReady) {
      return;
    }
    try {
      unawaited(FirebaseCrashlytics.instance.log(message));
    } catch (error) {
      debugPrint('Failed to record Crashlytics breadcrumb: $error');
    }
  }

  /// Attributes subsequent reports to one user, so a crash can be tied to an
  /// account instead of an anonymous installation. Pass an empty string to
  /// clear it (sign-out).
  static Future<void> setUserIdentifier(String identifier) async {
    if (!_crashlyticsEnabled || !_firebaseReady) {
      return;
    }
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } catch (error) {
      debugPrint('Failed to set Crashlytics user identifier: $error');
    }
  }

  /// Attaches one state key to subsequent reports. Crashlytics allows 64 keys
  /// of 1 kB each, so callers must use a bounded set of names.
  static Future<void> setCustomKey(String key, Object value) async {
    if (!_crashlyticsEnabled || !_firebaseReady) {
      return;
    }
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (error) {
      debugPrint('Failed to set Crashlytics custom key "$key": $error');
    }
  }

  static Future<void> logInfo(
    String message, {
    Map<String, Object?>? data,
  }) async {
    final suffix = data == null || data.isEmpty
        ? ''
        : ' | ${_toInlineData(data)}';
    logBreadcrumb('INFO: $message$suffix');
    await _appendLine(
      '[${DateTime.now().toIso8601String()}] INFO: $message$suffix',
    );
  }

  /// Transient network/TLS exception type names.
  ///
  /// Matched against BOTH the runtime type and the stringified error, because
  /// wrapper exceptions hide the leaf type: `web_socket_channel`'s
  /// `WebSocketChannelException` wraps a `WebSocketException` and matches
  /// neither name on its own (the runtime type is `WebSocketChannelException`,
  /// not `WebSocketException`), so a gateway handshake failure used to be
  /// reported to Crashlytics as a FATAL app error.
  static const List<String> _transientNetworkTypes = <String>[
    'SocketException',
    'HandshakeException',
    'TlsException',
    'ClientException',
    'TimeoutException',
    'HttpException',
    'WebSocketException',
    'WebSocketChannelException',
  ];

  /// Returns `true` for transient network/TLS failures that should not be
  /// reported to Crashlytics (DNS failures, no connectivity, circuit breaker).
  static bool isTransientNetworkError(Object error) {
    final name = error.runtimeType.toString();
    final message = error.toString().toLowerCase();
    for (final type in _transientNetworkTypes) {
      if (name.contains(type) || message.contains(type.toLowerCase())) {
        return true;
      }
    }
    // The UMP (ad consent) SDK reports a network failure as "Error making
    // request." with error code 2, through the same channel as a real
    // misconfiguration, so match its signature explicitly.
    return message.contains('error making request') ||
        message.contains('requestconsentinfoupdate failed') ||
        message.contains('connection timed out') ||
        message.contains('connection refused') ||
        message.contains('network is unreachable') ||
        message.contains('failed host lookup') ||
        message.contains('handshake') ||
        message.contains('no route to host') ||
        message.contains('circuit breaker open') ||
        message.contains('request failed after retries') ||
        message.contains('connection abort') ||
        message.contains('software caused connection abort') ||
        message.contains('resolving an image codec');
  }

  /// Non-fatal framework/platform noise (WebView after dispose, IME selection races).
  static bool isBenignFlutterFrameworkError(
    Object error, {
    String? context,
    String? library,
  }) {
    if (isTransientNetworkError(error)) {
      return true;
    }
    final text = '${error.toString()} ${context ?? ''} ${library ?? ''}'
        .toLowerCase();
    return text.contains('invalid selection start') ||
        text.contains('invalid selection end') ||
        text.contains('setting text input editing state') ||
        text.contains('string is not well-formed utf-16') ||
        text.contains('building a textspan') ||
        (text.contains('platform message callback') &&
            (text.contains('webview') ||
                text.contains('webchromeclient') ||
                text.contains('android_webkit')));
  }

  static Future<void> logError(
    String message,
    Object error,
    StackTrace stack, {
    required bool fatal,
    String? reason,
    String? information,
  }) async {
    final combined =
        '$message ${reason ?? ''} ${error.toString()} ${information ?? ''}';
    var reportFatal = fatal;
    if (reportFatal &&
        (isTransientNetworkError(error) ||
            isBenignFlutterFrameworkError(error, context: combined))) {
      reportFatal = false;
    }
    final payload = StringBuffer()
      ..write('[${DateTime.now().toIso8601String()}] ')
      ..write(reportFatal ? 'FATAL' : 'ERROR')
      ..write(': $message')
      ..write(' | error=$error');
    if (reason != null && reason.isNotEmpty) {
      payload.write(' | reason=$reason');
    }
    if (information != null && information.isNotEmpty) {
      payload.write(' | info=$information');
    }
    payload.write(' | stack=$stack');
    await _appendLine(payload.toString());

    // The breadcrumb buffer is capped at 64 kB, so mirror a compact line and
    // never the stack trace (which already ships with the report itself).
    logBreadcrumb(
      '${reportFatal ? 'FATAL' : 'ERROR'}: $message | error=$error'
      '${reason == null || reason.isEmpty ? '' : ' | reason=$reason'}',
    );

    if (!_crashlyticsEnabled || !_firebaseReady) {
      return;
    }

    // Transient network/TLS failures and benign framework noise are not app
    // bugs. Recording them creates one event per failure — DNS lookups and
    // websocket handshakes alone accounted for thousands of events (2358 over
    // 97 users on a single issue) and buried the real crashes — so they stay in
    // the local diagnostics log and the breadcrumb trail only.
    if (isTransientNetworkError(error) ||
        isBenignFlutterFrameworkError(error, context: combined)) {
      return;
    }

    try {
      final crashInformation = information == null
          ? const <Object>[]
          : <Object>[DiagnosticsNode.message(information)];
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason ?? message,
        information: crashInformation,
        fatal: reportFatal,
      );
    } catch (recordError, recordStack) {
      await _appendLine(
        '[${DateTime.now().toIso8601String()}] ERROR: Failed to send Crashlytics event | '
        'error=$recordError | stack=$recordStack',
      );
    }
  }

  static Future<String> readLog({int? maxLines = 250}) async {
    if (_logFile == null || !await _logFile!.exists()) {
      return 'No diagnostics log found yet.';
    }
    final lines = await _logFile!.readAsLines();
    if (maxLines == null || maxLines <= 0 || lines.length <= maxLines) {
      return lines.join('\n');
    }
    return lines.sublist(lines.length - maxLines).join('\n');
  }

  static Future<String> readAllLog() async {
    return readLog(maxLines: null);
  }

  static Future<void> clearLog() async {
    if (_logFile == null || !await _logFile!.exists()) {
      return;
    }
    await _logFile!.writeAsString('');
    await logInfo('Diagnostics log cleared');
  }

  static Future<void> copyLogToClipboard({int? maxLines = 250}) async {
    final text = await readLog(maxLines: maxLines);
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> _appendLine(String line) async {
    // Suppress Discord RPC spam — these fire on every presence update and
    // fill the diagnostics file with noise that is never read.
    if (line.contains('Discord RPC')) {
      return;
    }
    if (_logFile == null) {
      return;
    }
    try {
      await _logFile!.writeAsString('$line\n', mode: FileMode.append);
    } catch (_) {}
  }

  static String _toInlineData(Map<String, Object?> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join(', ');
  }
}
