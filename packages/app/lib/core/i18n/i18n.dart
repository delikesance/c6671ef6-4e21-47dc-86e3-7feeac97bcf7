import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';

export 'app_locale.dart';
export 'locale_provider.dart';
export 'l10n/app_localizations.dart' show AppLocalizations;

/// Convenient access to [AppLocalizations] from any [BuildContext].
///
/// Usage: `context.tr.app_title`
extension AppLocalizationsX on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);
}
