import 'dart:io';

import 'package:flutter/foundation.dart';

/// Sait si l'application tourne sur un poste de travail (Windows, Linux, macOS).
///
/// Pourquoi un fichier dédié : les getters historiques calculaient cette valeur
/// directement avec `Platform.*` depuis une demi-douzaine de fichiers, ce qui
/// rendait impossible tout test d'un comportement « desktop » (la plateforme
/// d'exécution des tests ne change pas). Ici la valeur est surchargeable, donc
/// vérifiable.
///
/// Attention : `Platform` lève une exception sur le web, d'où le test `kIsWeb`
/// évalué EN PREMIER (l'ancien code s'en remettait au court-circuit de
/// `!kIsWeb && !_isDesktop`).
@visibleForTesting
bool? debugForceDesktopPlatform;

/// Vrai si l'application tourne sur un poste de travail (Windows, Linux, macOS).
///
/// Une seule notion de « poste de travail » dans l'application : ce getter, et il
/// honore `debugDefaultTargetPlatformOverride` (le levier de test de Flutter). Sans
/// cela deux définitions coexistaient — celle-ci basée sur `Platform` (la vraie
/// machine) et celle de `remote_runtime.dart` basée sur `defaultTargetPlatform`
/// (que `flutter_test` rapporte en `android` par défaut) — et **un test « desktop »
/// pouvait passer en empruntant le chemin mobile**, donc ne rien prouver.
bool get isDesktopRunPlatform {
  if (debugForceDesktopPlatform != null) {
    return debugForceDesktopPlatform!;
  }
  if (kIsWeb) {
    return false;
  }
  final overridden = debugDefaultTargetPlatformOverride;
  if (overridden != null) {
    return overridden == TargetPlatform.windows ||
        overridden == TargetPlatform.linux ||
        overridden == TargetPlatform.macOS;
  }
  return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
}

/// Force temporairement la valeur pour un test, en restaurant l'état précédent.
///
/// Renvoie la fonction de restauration : les tests n'ont pas à connaître la
/// valeur d'origine de la plateforme sur laquelle ils s'exécutent.
VoidCallback debugOverrideDesktopPlatform(bool value) {
  final previous = debugForceDesktopPlatform;
  debugForceDesktopPlatform = value;
  return () {
    debugForceDesktopPlatform = previous;
  };
}

/// Le serveur (Bot Creator Manager) peut-il piloter un bot depuis cette plateforme ?
///
/// Oui PARTOUT, poste de travail compris : c'est l'ASSOCIATION du bot qui décide où
/// il s'exécute, pas la plateforme — un bot peut être hébergé pendant que l'app tourne
/// sur un poste. Sept copies de cette règle existaient dans l'application, six
/// répondaient « non » sur un poste de travail : la page de logs ne pouvait alors
/// afficher que « Local sur cet appareil », les statistiques et les variables globales
/// ignoraient le serveur, et le bot restait invisible côté hébergement. La règle vit
/// ici, et une garde de test interdit de la réécrire dans une page.
bool get supportsManagerRuntime => !kIsWeb;
