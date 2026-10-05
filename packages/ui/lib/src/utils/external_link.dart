import 'package:url_launcher/url_launcher.dart';

/// Ouvre une URL hors de l'application. Les plateformes qui ont besoin d'un
/// traitement particulier (Linux : `xdg-open` sans `LD_LIBRARY_PATH`) branchent
/// leur propre ouvreur dans [ExternalLinkOpener.current].
abstract final class ExternalLinkOpener {
  static Future<bool> Function(Uri uri) current = (uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openExternalUrl(Uri uri) => ExternalLinkOpener.current(uri);
