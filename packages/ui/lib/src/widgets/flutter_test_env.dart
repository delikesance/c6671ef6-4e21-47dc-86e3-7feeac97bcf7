import 'package:flutter/widgets.dart';

/// Vrai sous `flutter test` : le binding de test remplace `Platform.environment`
/// (indisponible sur le web) pour désactiver ce qui dépend du bureau réel.
bool get isRunningFlutterTest => WidgetsBinding.instance.runtimeType
    .toString()
    .contains('TestWidgetsFlutterBinding');
