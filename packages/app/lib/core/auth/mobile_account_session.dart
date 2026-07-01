import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:flutter/foundation.dart';

/// Notifies the app shell when the mobile Discord account requirement changes.
class MobileAccountSession extends ChangeNotifier {
  MobileAccountSession._();

  static final MobileAccountSession instance = MobileAccountSession._();

  bool _loaded = false;
  bool _satisfied = false;

  bool get loaded => _loaded;
  bool get satisfied => _satisfied;

  Future<void> recheck() async {
    final next = await MobileAccountGate.hasRequiredAccount();
    final changed = !_loaded || next != _satisfied;
    _loaded = true;
    _satisfied = next;
    if (changed) {
      notifyListeners();
    }
  }
}
