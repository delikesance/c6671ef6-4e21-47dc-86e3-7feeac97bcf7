import 'dart:async';
import 'dart:convert';

import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/function_suite.dart';

/// Signature of the engine entry point, injectable so the limits can be tested
/// without waiting for a real isolate to hit them.
typedef SandboxRunFn =
    Future<Map<String, dynamic>> Function(
      Map<String, dynamic> request, {
      Duration timeout,
    });

/// A refusal the HTTP layer maps one-to-one onto a status and a stable `code`.
class SandboxRefusal implements Exception {
  const SandboxRefusal(this.status, this.code, this.message);

  final int status;
  final String code;
  final String message;

  @override
  String toString() => '$code: $message';
}

/// Server-side execution of the command sandbox for clients that cannot run
/// the Dart engine themselves (the Studio, which is a web build).
///
/// The engine already guarantees that nothing leaves the process:
///  * it only reads the fixtures of the request, never a real bot store;
///  * Discord is a fixture gateway that throws on anything it does not model;
///  * `http` actions go through a mock client that answers from the request's
///    own fixtures, and the worker isolate runs under an `HttpOverrides` that
///    refuses to create any real `HttpClient` (so a code path that bypassed the
///    mock would still not reach the network or an internal address).
/// This class adds what is specific to exposing it over HTTP: a body size cap,
/// a wall-clock limit, a concurrency cap and a stable error vocabulary.
class RunnerSandboxService {
  RunnerSandboxService({
    this.maxBodyBytes = defaultMaxBodyBytes,
    this.timeout = defaultTimeout,
    this.maxConcurrent = defaultMaxConcurrent,
    SandboxRunFn? run,
  }) : _run = run ?? _engineRun;

  /// Request bodies above this are refused before being parsed.
  static const int defaultMaxBodyBytes = 256 * 1024;

  /// Kept below the Manager's own runner-call timeout (10 s by default) so a
  /// slow script is reported by the runner, not as a gateway timeout.
  static const Duration defaultTimeout = Duration(seconds: 5);

  /// Each run spawns an isolate: this bounds the CPU and memory one runner
  /// spends on sandbox work, whatever the number of callers.
  static const int defaultMaxConcurrent = 2;

  final int maxBodyBytes;
  final Duration timeout;
  final int maxConcurrent;
  final SandboxRunFn _run;

  int _active = 0;
  List<Map<String, dynamic>>? _catalog;

  /// Runs in flight; exposed for tests.
  int get activeRuns => _active;

  static Future<Map<String, dynamic>> _engineRun(
    Map<String, dynamic> request, {
    Duration timeout = const Duration(seconds: 3),
  }) => testCommandInSandbox(request, timeout: timeout);

  /// Parses a raw body into the request object, enforcing the size cap on the
  /// bytes actually received (a lying `Content-Length` cannot get around it,
  /// see the web server's streaming read).
  Map<String, dynamic> decodeBody(List<int> bytes) {
    if (bytes.length > maxBodyBytes) {
      throw SandboxRefusal(
        413,
        'payload_too_large',
        'Sandbox request exceeds $maxBodyBytes bytes.',
      );
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(bytes));
    } on FormatException {
      throw const SandboxRefusal(
        400,
        'invalid_request',
        'Sandbox request body must be valid JSON.',
      );
    }
    if (decoded is! Map) {
      throw const SandboxRefusal(
        400,
        'invalid_request',
        'Sandbox request body must be a JSON object.',
      );
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// Executes one request. The engine's own failures (bad script, budget
  /// exceeded, invalid fixture) are part of a normal result, exactly as on a
  /// device; only the limits of THIS service are refusals.
  Future<Map<String, dynamic>> run(Map<String, dynamic> request) async {
    if (_active >= maxConcurrent) {
      throw const SandboxRefusal(
        429,
        'sandbox_busy',
        'Too many sandbox runs in progress; retry in a moment.',
      );
    }
    _active++;
    try {
      final result = await _run(request, timeout: timeout);
      if (result['terminated'] == true) {
        throw SandboxRefusal(
          504,
          'sandbox_timeout',
          (result['error'] ?? 'Sandbox execution time limit exceeded')
              .toString(),
        );
      }
      return _jsonSafe(result);
    } on SandboxRefusal {
      rethrow;
    } catch (error) {
      throw SandboxRefusal(
        500,
        'sandbox_failed',
        'Sandbox execution failed: $error',
      );
    } finally {
      _active--;
    }
  }

  /// Every regression case of the function laboratory, in wire form. The list
  /// is static for a given build, so it is built once.
  List<Map<String, dynamic>> functionCases() =>
      _catalog ??= List<Map<String, dynamic>>.unmodifiable(
        sandboxFunctionCases.map((c) => c.toJson()),
      );

  /// Results are plain data, but a stray `NaN`, a `Duration` or a class
  /// instance in a fixture echo must not turn into a 500 at serialization.
  static Map<String, dynamic> _jsonSafe(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(
        jsonDecode(
              jsonEncode(value, toEncodable: (object) => object.toString()),
            )
            as Map,
      );
}
