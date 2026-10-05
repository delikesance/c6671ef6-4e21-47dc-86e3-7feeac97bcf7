import 'package:flutter/widgets.dart';

/// D'où viennent les octets d'un avatar. L'app y branche son cache disque
/// (mémoire → disque → réseau) ; par défaut, simple image réseau.
abstract class AvatarImageSource {
  Future<ImageProvider> providerFor(String url);

  static AvatarImageSource defaultSource = const NetworkAvatarImageSource();
}

class NetworkAvatarImageSource implements AvatarImageSource {
  const NetworkAvatarImageSource();

  @override
  Future<ImageProvider> providerFor(String url) async => NetworkImage(url);
}
