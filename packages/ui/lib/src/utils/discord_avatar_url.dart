/// URL de l'avatar Discord d'un utilisateur.
///
/// Sans avatar (ou `0`), l'avatar par défaut de Discord ; avec, l'image du CDN.
/// Accepte aussi une URL ou un chemin contenant le hachage de l'avatar.
String discordAvatarUrl(
  String userId, {
  String? avatarId,
  bool isAnimated = false,
  String legacyFormat = 'webp',
  String? discriminator,
}) {
  if (avatarId == null || avatarId.isEmpty || avatarId == '0') {
    if (discriminator != null &&
        discriminator != '0' &&
        discriminator != '0000') {
      final parsedDiscrim = int.tryParse(discriminator);
      if (parsedDiscrim != null) {
        return 'https://cdn.discordapp.com/embed/avatars/${parsedDiscrim % 5}.png';
      }
    }
    final parsedId = BigInt.tryParse(userId);
    if (parsedId != null) {
      return 'https://cdn.discordapp.com/embed/avatars/${(parsedId >> 22).toInt() % 6}.png';
    }
    return 'https://cdn.discordapp.com/embed/avatars/0.png';
  }

  var cleanAvatarId = avatarId.trim();
  if (cleanAvatarId.contains('/')) {
    final hashMatch = RegExp(
      r'([a-f0-9]{32}|a_[a-f0-9]{32})',
      caseSensitive: false,
    ).allMatches(cleanAvatarId);
    if (hashMatch.isNotEmpty) {
      cleanAvatarId = hashMatch.last.group(0)!;
    } else if (cleanAvatarId.startsWith('http://') ||
        cleanAvatarId.startsWith('https://')) {
      return cleanAvatarId.split('?').first;
    }
  }

  if (cleanAvatarId.startsWith('a_')) {
    isAnimated = true;
  }

  if (isAnimated && legacyFormat == 'gif') {
    return 'https://cdn.discordapp.com/avatars/$userId/$cleanAvatarId.gif?size=1024';
  }

  return 'https://cdn.discordapp.com/avatars/$userId/$cleanAvatarId.$legacyFormat?size=1024';
}
