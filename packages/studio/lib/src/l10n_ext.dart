import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

export '../l10n/app_localizations.dart';

/// `context.l10n.navHome` : les textes du Studio dans la langue courante.
extension StudioL10n on BuildContext {
  StudioLocalizations get l10n => StudioLocalizations.of(this);
}
