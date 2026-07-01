import 'dart:async';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

typedef PurchaseUpdatesHandler = Future<void> Function(
  List<PurchaseDetails> purchases,
);

/// Fan-out hub for [InAppPurchase.purchaseStream], which only allows one listener.
class SharedPurchaseStream {
  SharedPurchaseStream._();

  static final SharedPurchaseStream instance = SharedPurchaseStream._();

  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Set<PurchaseUpdatesHandler> _handlers = <PurchaseUpdatesHandler>{};

  void addHandler(PurchaseUpdatesHandler handler) {
    _handlers.add(handler);
    _ensureListening();
  }

  void removeHandler(PurchaseUpdatesHandler handler) {
    _handlers.remove(handler);
    if (_handlers.isEmpty) {
      unawaited(_subscription?.cancel());
      _subscription = null;
    }
  }

  void _ensureListening() {
    if (_subscription != null) {
      return;
    }
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchases) async {
        for (final handler in List<PurchaseUpdatesHandler>.from(_handlers)) {
          await handler(purchases);
        }
      },
      onError: (Object error, StackTrace stack) {
        unawaited(
          AppDiagnostics.logError(
            'Shared purchase stream error',
            error,
            stack,
            fatal: false,
          ),
        );
      },
    );
  }
}
