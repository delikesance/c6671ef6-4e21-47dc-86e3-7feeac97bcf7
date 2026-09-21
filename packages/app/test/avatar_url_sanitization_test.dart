import 'package:bot_creator/core/utils/global.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('makeAvatarUrl sanitization', () {
    test('standard clean hash produces valid Discord avatar URL', () {
      final url = makeAvatarUrl(
        '1350824555119382678',
        avatarId: '06494ccb46424d2d26c59ddc41682375',
      );
      expect(
        url,
        'https://cdn.discordapp.com/avatars/1350824555119382678/06494ccb46424d2d26c59ddc41682375.webp?size=1024',
      );
    });

    test('already formed full URL extracts hash and does not nest', () {
      const existingUrl =
          'https://cdn.discordapp.com/avatars/1350824555119382678/06494ccb46424d2d26c59ddc41682375.webp?size=1024';
      final url = makeAvatarUrl('1350824555119382678', avatarId: existingUrl);
      expect(
        url,
        'https://cdn.discordapp.com/avatars/1350824555119382678/06494ccb46424d2d26c59ddc41682375.webp?size=1024',
      );
    });

    test('deeply nested corrupted URL extracts real hash cleanly', () {
      const corruptedUrl =
          'https://cdn.discordapp.com/avatars/1350824555119382678/https://cdn.discordapp.com/avatars/1350824555119382678/06494ccb46424d2d26c59ddc41682375.webp?size=1024.webp?size=1024';
      final url = makeAvatarUrl('1350824555119382678', avatarId: corruptedUrl);
      expect(
        url,
        'https://cdn.discordapp.com/avatars/1350824555119382678/06494ccb46424d2d26c59ddc41682375.webp?size=1024',
      );
    });

    test('animated avatar starting with a_ is recognized as gif', () {
      final url = makeAvatarUrl(
        '1350824555119382678',
        avatarId: 'a_06494ccb46424d2d26c59ddc41682375',
        legacyFormat: 'gif',
      );
      expect(
        url,
        'https://cdn.discordapp.com/avatars/1350824555119382678/a_06494ccb46424d2d26c59ddc41682375.gif?size=1024',
      );
    });
  });
}
