import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';

/// Hauteur de la barre de titre custom desktop.
const double kDesktopTitleBarHeight = 38.0;

/// Notifier et observateur de navigation pour synchroniser la barre de titre desktop
/// ([DesktopTitleBar]) avec l'état de l'application (bot sélectionné, possibilité de retour, etc.).
class DesktopTitleBarNotifier extends NavigatorObserver with ChangeNotifier {
  DesktopTitleBarNotifier._();

  static final DesktopTitleBarNotifier instance = DesktopTitleBarNotifier._();

  GlobalKey<NavigatorState>? navigatorKey;

  String? _title;
  String? _subtitle;
  VoidCallback? _onExitBot;
  bool _canPopNavigator = false;

  String? get title => _title;
  String? get subtitle => _subtitle;
  VoidCallback? get onExitBot => _onExitBot;
  bool get canPopNavigator => _canPopNavigator;

  bool get canGoBack => _canPopNavigator || _onExitBot != null;

  void updateManagingBot({String? name, int? id, VoidCallback? onExit}) {
    _title = name;
    _subtitle = id != null ? 'ID $id' : null;
    _onExitBot = onExit;
    notifyListeners();
  }

  void _checkCanPop() {
    final nav = navigator ?? navigatorKey?.currentState;
    final canPop = nav?.canPop() ?? false;
    if (_canPopNavigator != canPop) {
      _canPopNavigator = canPop;
      notifyListeners();
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCanPop());
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCanPop());
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCanPop());
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCanPop());
  }

  Future<void> handleBack() async {
    final nav = navigator ?? navigatorKey?.currentState;
    if (nav != null && nav.canPop()) {
      await nav.maybePop();
      _checkCanPop();
      return;
    }
    if (_onExitBot != null) {
      _onExitBot!();
    }
  }
}

/// Enveloppe globale pour les applications desktop.
///
/// Elle intègre la [DesktopTitleBar] de façon permanente tout en haut
/// de la fenêtre au niveau de l'application (via [MaterialApp.builder]),
/// assurant ainsi que les contrôles de fenêtre et la navigation retour
/// restent disponibles quelle que soit la route poussée.
class DesktopAppShell extends StatelessWidget {
  const DesktopAppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          SizedBox(
            height: kDesktopTitleBarHeight,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => ListenableBuilder(
                    listenable: DesktopTitleBarNotifier.instance,
                    builder: (context, _) {
                      final notifier = DesktopTitleBarNotifier.instance;
                      return DesktopTitleBar(
                        title: notifier.title,
                        subtitle: notifier.subtitle,
                        canGoBack: notifier.canGoBack,
                        onBack: notifier.handleBack,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Barre de titre et de menu custom pour desktop (Linux, macOS, Windows).
///
/// Elle intègre :
/// - Un bouton « Retour » universel si [canGoBack] est vrai, évitant la duplication
///   dans les tiroirs et appbars des sous-pages.
/// - Le titre / fil d'Ariane de l'application (« Bot Creator » + bot actif si applicable).
/// - Une zone glissable permettant de déplacer la fenêtre (`windowManager.startDragging()`).
/// - Les contrôles de fenêtre natifs (réduire, agrandir/restaurer, fermer).
class DesktopTitleBar extends StatefulWidget {
  const DesktopTitleBar({
    super.key,
    this.title,
    this.subtitle,
    this.canGoBack = false,
    this.onBack,
  });

  /// Titre ou nom de l'élément en cours d'édition (ex: nom du bot).
  final String? title;

  /// Sous-titre ou fil d'Ariane (ex: 'ID 12345').
  final String? subtitle;

  /// Indique si un retour en arrière est possible.
  final bool canGoBack;

  /// Action déclenchée par le bouton retour universel.
  final VoidCallback? onBack;

  @override
  State<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends State<DesktopTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (ResponsiveHelper.isDesktopPlatform()) {
      windowManager.addListener(this);
      _checkMaximized();
    }
  }

  @override
  void dispose() {
    if (ResponsiveHelper.isDesktopPlatform()) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximized() async {
    try {
      final max = await windowManager.isMaximized();
      if (mounted) {
        setState(() => _isMaximized = max);
      }
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    // Si nous ne sommes pas sur un desktop OS, ne rien rendre.
    if (!ResponsiveHelper.isDesktopPlatform()) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<HomeTokens>();
    final bgColor = isDark
        ? (tokens?.navBar ?? AppTheme.homeNavBar)
        : Theme.of(context).colorScheme.surface;
    final borderColor = isDark
        ? (tokens?.cardBorder ?? AppTheme.homeCardBorder)
        : Theme.of(context).colorScheme.outlineVariant;
    final fgColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final mutedColor = isDark
        ? (tokens?.muted ?? AppTheme.homeMuted)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    final isMac = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

    return Container(
      height: kDesktopTitleBarHeight,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sur macOS, les fenêtres ont souvent les boutons à gauche, mais comme
          // nous avons une barre custom uniforme qui remplace la barre native,
          // on peut laisser la zone de contrôle à droite ou afficher un padding à gauche.
          if (widget.canGoBack)
            _DesktopTitleBarButton(
              icon: Icons.arrow_back_rounded,
              tooltip:
                  Localizations.of<AppLocalizations>(
                    context,
                    AppLocalizations,
                  )?.common_back ??
                  'Back',
              onTap: widget.onBack,
            )
          else
            const SizedBox(width: 8),

          // Icône et titre de l'application
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.smart_toy_rounded,
                  size: 16,
                  color:
                      tokens?.accent ?? Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  Localizations.of<AppLocalizations>(
                        context,
                        AppLocalizations,
                      )?.app_title ??
                      'Bot Creator',
                  style: GoogleFonts.alexandria(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
                if (widget.title != null && widget.title!.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '/',
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedColor,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  Text(
                    widget.title!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: fgColor,
                    ),
                  ),
                ],
                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.subtitle!,
                    style: GoogleFonts.inter(fontSize: 11, color: mutedColor),
                  ),
                ],
              ],
            ),
          ),

          // Zone draggable pour déplacer la fenêtre
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (details) {
                windowManager.startDragging();
              },
              onDoubleTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
              child: const SizedBox(height: kDesktopTitleBarHeight),
            ),
          ),

          // Boutons de contrôle de fenêtre (Réduire, Agrandir/Restaurer, Fermer)
          if (!isMac) ...[
            _DesktopWindowControlButton(
              icon: Icons.remove_rounded,
              tooltip: context.tr.common_minimize,
              onTap: () => windowManager.minimize(),
            ),
            _DesktopWindowControlButton(
              icon: _isMaximized
                  ? Icons.filter_none_rounded
                  : Icons.crop_square_rounded,
              iconSize: _isMaximized ? 13 : 15,
              tooltip: _isMaximized
                  ? context.tr.common_restore
                  : context.tr.common_maximize,
              onTap: () async {
                if (await windowManager.isMaximized()) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              },
            ),
            _DesktopWindowControlButton(
              icon: Icons.close_rounded,
              tooltip: context.tr.common_close,
              isClose: true,
              onTap: () => windowManager.close(),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesktopTitleBarButton extends StatelessWidget {
  const _DesktopTitleBarButton({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).colorScheme.onSurface;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 34,
            height: 30,
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: fg),
          ),
        ),
      ),
    );
  }
}

class _DesktopWindowControlButton extends StatefulWidget {
  const _DesktopWindowControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 16,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;
  final bool isClose;

  @override
  State<_DesktopWindowControlButton> createState() =>
      _DesktopWindowControlButtonState();
}

class _DesktopWindowControlButtonState
    extends State<_DesktopWindowControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color iconColor;

    if (widget.isClose) {
      bg = _isHovered ? const Color(0xFFE81123) : Colors.transparent;
      iconColor = _isHovered
          ? Colors.white
          : (isDark ? const Color(0xFFC0C0C0) : const Color(0xFF404040));
    } else {
      bg = _isHovered
          ? (isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06))
          : Colors.transparent;
      iconColor = isDark ? const Color(0xFFC0C0C0) : const Color(0xFF404040);
    }

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: kDesktopTitleBarHeight,
            color: bg,
            alignment: Alignment.center,
            child: Icon(widget.icon, size: widget.iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
