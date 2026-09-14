// Regression: gateway WebSocket failures were reported to Crashlytics as
// FATAL app errors.
//
// Crashlytics grouped ~823 events / 27 users under a single FATAL issue whose
// exception was `WebSocketChannelException: ... was not upgraded to websocket,
// HTTP status code: 400`. `AppDiagnostics.isTransientNetworkError` compared
// only `error.runtimeType.toString()` against `WebSocketException`, a name a
// wrapper type never contains, so every gateway-down / offline start was
// classified as a fatal application bug.

import 'dart:io';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  group('AppDiagnostics.isTransientNetworkError', () {
    test(
      'a WebSocketChannelException wrapping a handshake failure is transient',
      () {
        final error = WebSocketChannelException(
          "Connection to 'https://api.bot-creator.fr:0/gateway/bots/events#' was "
          'not upgraded to websocket, HTTP status code: 400',
        );

        // The runtime type is the wrapper, never the leaf `WebSocketException`.
        expect(error.runtimeType.toString(), 'WebSocketChannelException');
        expect(AppDiagnostics.isTransientNetworkError(error), isTrue);
      },
    );

    test('a DNS failure surfacing as SocketException is transient', () {
      const error = SocketException(
        "Failed host lookup: 'api.bot-creator.fr'",
        osError: OSError('No address associated with hostname', 7),
      );

      expect(AppDiagnostics.isTransientNetworkError(error), isTrue);
    });

    test(
      'an opaque wrapper whose message carries the leaf type is transient',
      () {
        final error = Exception(
          'SocketException: Failed host lookup: api.bot-creator.fr',
        );

        expect(AppDiagnostics.isTransientNetworkError(error), isTrue);
      },
    );

    test('a genuine application error is not transient', () {
      expect(
        AppDiagnostics.isTransientNetworkError(StateError('Unexpected null')),
        isFalse,
      );
      expect(
        AppDiagnostics.isTransientNetworkError(
          RangeError.index(3, <int>[1, 2], 'index'),
        ),
        isFalse,
      );
    });
  });

  group('AppDiagnostics Crashlytics enrichment', () {
    // These run from startup paths that execute before Firebase is ready (and
    // in tests, where Crashlytics is never configured). They must never throw:
    // an exception here would replace the real startup failure with a
    // diagnostics failure.
    test('breadcrumb, user id and custom key are safe before init', () async {
      expect(() => AppDiagnostics.logBreadcrumb('startup'), returnsNormally);
      await expectLater(AppDiagnostics.setUserIdentifier('user-1'), completes);
      await expectLater(AppDiagnostics.setCustomKey('k', 'v'), completes);
      await expectLater(AppDiagnostics.setUserIdentifier(''), completes);
    });
  });
}
