import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Convenient access to [AppLocalizations] from any [BuildContext].
///
/// Usage: `context.tr.app_title`
extension AppLocalizationsX on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);
}
