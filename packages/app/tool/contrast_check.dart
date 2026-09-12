// ignore_for_file: avoid_print
// Quick WCAG contrast checker for the palette pairs touched by the
// bot_sub_pages purple-removal pass. Dev-only helper, not part of the app.
// Run: dart run tool/contrast_check.dart
import 'dart:math' as math;

double _lin(int c) {
  final v = c / 255.0;
  return v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4) as double;
}

double luminance(int argb) {
  final r = _lin((argb >> 16) & 0xFF);
  final g = _lin((argb >> 8) & 0xFF);
  final b = _lin(argb & 0xFF);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

int over(int fg, double alpha, int bg) {
  int ch(int shift) {
    final f = (fg >> shift) & 0xFF;
    final b = (bg >> shift) & 0xFF;
    return (f * alpha + b * (1 - alpha)).round();
  }

  return 0xFF000000 | (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

double ratio(int fg, int bg) {
  final a = luminance(fg), b = luminance(bg);
  final hi = math.max(a, b), lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

String _tag(double r) =>
    r >= 4.5 ? 'AA-text' : (r >= 3.0 ? 'AA-graphic' : 'FAIL');

void pair(String label, int fg, int bg) {
  final r = ratio(fg, bg);
  print(
    '${r.toStringAsFixed(2).padLeft(6)}:1  ${_tag(r).padRight(10)}  $label',
  );
}

// ── theme tokens (dark) ──
// ── Surfaces COURANTES (graine graphite, variante `neutral`) ──
// Ces valeurs étaient obsolètes (palette violette) : l'outil mesurait donc des
// paires qui n'existent plus, et validait des contrastes faux.
const scaffoldDark = 0xFF111111;
const homeCard = 0xFF1D1D1D; // surfaceContainer / card
const navSelected = 0xFF262626; // surfaceContainerHighest
const clusterBg = 0xFF151515; // surfaceContainerLow
const muted = 0xFF888888; // onSurfaceVariant / homeMuted
const outlineVariant = 0xFF292929;
const ghost = 0xFF333333; // outline
// ANCIEN violet clair : plus l'accent du thème (voir la section « accent M3 »
// en fin de fichier). Conservé uniquement comme référence « AVANT ».
const purpleSoft = 0xFFB19DF7;
const brandPrimary = 0xFF6A0FA2;
const brandSecondary = 0xFF9B30FF;
const white = 0xFFFFFFFF;
const dataAccent = 0xFFDCF0FF;
const success = 0xFF2E7D32;
const successLight = 0xFF4CAF50;
const online = 0xFF10B981;
const info = 0xFF1976D2;
const danger = 0xFFFF4D4D;
const warning = 0xFFFFA726;
const syntaxCyan = 0xFF00ACC1;
const syntaxOrange = 0xFFFF9800;
const premiumGold = 0xFFFFC107;
const discordLight = 0xFF7983F5;
const grey = 0xFF9E9E9E;

// ── raw Material colours used by the *business* category palette ──
const teal = 0xFF009688;
const indigo = 0xFF3F51B5;
const pink = 0xFFE91E63;
const deepPurpleAccent = 0xFF7C4DFF;
const lime700 = 0xFFAFB42B;
const brown = 0xFF795548;
const cyan = 0xFF00BCD4;
// Teintes qui remplacent les 4 entrées illisibles de la palette métier
// (`brandPrimary` Components/Workflows, `Colors.indigo` Guild,
// `Colors.brown` Utilities) + `deepPurpleAccent` Music.
const lightBlue200 = 0xFF81D4FA;
const indigo200 = 0xFF9FA8DA;
const deepOrangeAccent = 0xFFFF6E40;
const lightGreenAccent = 0xFFB2FF59;
const brown200 = 0xFFBCAAA4;

void main() {
  print('=== BEFORE — decorative purple, on dark card #1F1A2D ===');
  pair('brandPrimary #6A0FA2 (icon/value text)', brandPrimary, homeCard);
  pair('brandSecondary #9B30FF (icon/value text)', brandSecondary, homeCard);
  pair(
    'brandPrimary @12% wash tint',
    over(brandPrimary, 0.12, homeCard),
    homeCard,
  );
  pair(
    'brandPrimary @8% wash over surfaceContainerHighest',
    over(brandPrimary, 0.08, navSelected),
    navSelected,
  );
  pair('brandPrimary on scaffoldDark', brandPrimary, scaffoldDark);

  print('\n=== AFTER — neutral theme tokens ===');
  pair('onSurface (white) on homeCard', white, homeCard);
  pair('onSurfaceVariant on homeCard', muted, homeCard);
  pair('onSurfaceVariant on surfaceContainerHighest', muted, navSelected);
  pair('onSurfaceVariant on surfaceContainerLow', muted, clusterBg);
  pair('white on surfaceContainerHighest', white, navSelected);
  pair(
    '[AVANT] violet #B19DF7 on homeCard (accent historique)',
    purpleSoft,
    homeCard,
  );
  pair(
    '[AVANT] violet #B19DF7 on scaffoldDark (accent historique)',
    purpleSoft,
    scaffoldDark,
  );
  pair('outlineVariant on homeCard (non-text 3:1)', outlineVariant, homeCard);
  pair('onSurfaceVariant on scaffoldDark', muted, scaffoldDark);

  print('\n=== metric-card hues (code couleur par métrique) ===');
  for (final e in {
    'brandPrimary (avant)': brandPrimary,
    'brandSecondary (avant)': brandSecondary,
    'syntaxCyan (CPU)': syntaxCyan,
    'warning (Storage)': warning,
    'syntaxOrange': syntaxOrange,
    'premiumGold': premiumGold,
    'discordLight': discordLight,
    'successLight': successLight,
    'online': online,
    'danger': danger,
    'dataAccent': dataAccent,
    'info': info,
    'grey': grey,
  }.entries) {
    pair('${e.key} on homeCard', e.value, homeCard);
  }

  print('\n=== business category palette (scratch_block_palette) ===');
  // Palette COURANTE (alignée sur `scratch_block_palette.getCategoryColor`).
  // Les 4 entrées qui échouaient (brandPrimary Components/Workflows 1.77:1,
  // indigo 2.46:1, brown 2.58:1) ont été remplacées par des teintes lisibles.
  for (final e in {
    'success Messages': success,
    'warning Reactions': warning,
    'info Channels': info,
    'error Moderation': danger,
    'lightBlue.shade200 Components': lightBlue200,
    'Colors.teal Webhooks': teal,
    'indigo.shade200 Guild & Members': indigo200,
    'Colors.cyan HTTP & Variables': cyan,
    'deepOrangeAccent Workflows': deepOrangeAccent,
    'Colors.pink Logic & Flow': pink,
    'premiumGold Interactions': premiumGold,
    'lightGreenAccent Music': lightGreenAccent,
    'lime.shade700 EntryPoint': lime700,
    'brown.shade200 Utilities': brown200,
  }.entries) {
    pair('${e.key} on homeCard', e.value, homeCard);
  }

  print('\n=== accent M3 (paires on*/primary après retrait du violet) ===');
  // L'accent du thème n'est plus `brandPurpleSoft`/`brandPrimary` : il est
  // dérivé de la graine graphite. Ce sont les paires des boutons d'action et
  // des états sélectionnés — il faut donc les mesurer.
  for (final e in {
    'clair  onPrimary(blanc) / primary #5B5E6C': const [0xFFFFFFFF, 0xFF5B5E6C],
    'sombre onPrimary #2D3037 / primary #C4C5D6': const [
      0xFF2D3037,
      0xFFC4C5D6,
    ],
    'clair  onSecondaryContainer / secondaryContainer': const [
      0xFF1A1C20,
      0xFFE2E1EC,
    ],
  }.entries) {
    pair(e.key, e.value[0], e.value[1]);
  }
}
