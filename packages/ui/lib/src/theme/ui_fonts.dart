import 'package:flutter/services.dart';

/// Familles de polices embarquées par `bot_creator_ui`.
abstract final class UiFonts {
  /// Noms qualifiés, tels que Flutter les expose aux applications qui
  /// dépendent du paquet.
  static const sans = 'packages/bot_creator_ui/Inter';
  static const mono = 'packages/bot_creator_ui/JetBrainsMono';

  static const _inter = [
    'Inter-Regular.ttf',
    'Inter-Medium.ttf',
    'Inter-SemiBold.ttf',
    'Inter-Bold.ttf',
  ];
  static const _mono = [
    'JetBrainsMono-Regular.ttf',
    'JetBrainsMono-SemiBold.ttf',
    'JetBrainsMono-Bold.ttf',
  ];

  /// Enregistre `Inter` et `JetBrainsMono` sous leur nom court.
  ///
  /// Les widgets partagés écrivent `fontFamily: 'JetBrainsMono'` comme dans
  /// l'app, où la famille est déclarée par le pubspec de l'application ; une
  /// application qui n'a pas ces fichiers (le Studio) les enregistre ici, à
  /// partir de ceux du paquet, avant `runApp`.
  static Future<void> registerBundled() async {
    Future<void> register(
      String family,
      String folder,
      List<String> files,
    ) async {
      final loader = FontLoader(family);
      for (final file in files) {
        loader.addFont(
          rootBundle.load('packages/bot_creator_ui/assets/fonts/$folder/$file'),
        );
      }
      await loader.load();
    }

    await register('Inter', 'inter', _inter);
    await register('JetBrainsMono', 'jetbrainsmono', _mono);
  }
}
