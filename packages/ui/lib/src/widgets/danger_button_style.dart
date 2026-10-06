import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Style d'un bouton « contour » destructif ou de sortie (se déconnecter,
/// arrêter) : texte et contour rouges, fond rouge très léger. Le rouge dit ce
/// que l'action a d'irréversible avant même qu'on lise le libellé.
ButtonStyle dangerOutlinedButtonStyle({Size minimumSize = const Size(0, 44)}) =>
    OutlinedButton.styleFrom(
      minimumSize: minimumSize,
      foregroundColor: AppTheme.statusErrorText,
      backgroundColor: AppTheme.danger.withValues(alpha: 0.08),
      side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.45)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
