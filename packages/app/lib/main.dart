import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/i18n/extensions.dart';
import 'package:bot_creator/core/i18n/locale_provider.dart';
import 'package:bot_creator/firebase_options.dart';
import 'package:bot_creator/core/analytics/posthog_service.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nyxx/nyxx.dart' hide Locale, Builder;
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/app_editor_page.dart';
import 'package:provider/provider.dart';
import 'package:bot_creator/features/onboarding/presentation/onboarding_page.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/diagnostics/ui_stall_bindings.dart';
import 'package:bot_creator/core/diagnostics/ui_stall_monitor.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/notifications/logic/notification_service.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/features/ads/logic/ad_native_service.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/core/auth/mobile_account_gate.dart';
import 'package:bot_creator/core/auth/mobile_account_session.dart';
import 'package:bot_creator/core/network/main_api_auth_service.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/runner/embedded_js_runner_service.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/core/code_editor/code_editor_settings_provider.dart';
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/core/widgets/desktop_title_bar.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/features/auth/presentation/mobile_account_gate_shell.dart';
import 'package:window_manager/window_manager.dart';
import 'package:bot_creator/features/documentation/documentation_hub_page.dart';
import 'package:bot_creator/features/documentation/webview_platform_bootstrap.dart';
import 'package:bot_creator/features/settings/presentation/settings_page.dart';

@pragma('vm:entry-point')
AppManager? _appManager;

@pragma('vm:entry-point')
AppManager get appManager => _appManager ??= AppManager();

@pragma('vm:entry-point')
set appManager(AppManager value) => _appManager = value;

/// Thread-safe bounded log buffer to prevent unbounded memory growth.
final LogBuffer currentLogList = LogBuffer(maxEntries: 5000);

/// Registry of active gateway connections keyed by bot ID.
@pragma('vm:entry-point')
final Map<String, NyxxGateway> gateways = <String, NyxxGateway>{};

FirebaseApp? firebaseApp;
Future<void>? warmUpFuture;

/// UI-thread stall instrumentation, installed once in `main()`.
///
/// The monitor is reachable from hot paths through `activeUiStallMonitor`
/// (declared in ui_stall_bindings.dart); these bindings own the ticker, the
/// frame timings callback and the lifecycle observer, so `stop()` releases
/// them instead of leaving the isolate with an orphan timer or observer.
UiStallBindings? uiStallBindings;

bool get _isFirebaseSupported {
  if (kIsWeb) {
    return true;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return false;
    default:
      return false;
  }
}

bool get _isCrashlyticsSupported {
  if (kIsWeb) {
    return false;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return false;
    default:
      return false;
  }
}

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // ── UI-thread stall instrumentation ──────────────────────────────
      // Crashlytics' ANR reports carry no Dart frame at all, so the
      // UI-thread operation that froze the app has to be named on the
      // device. The monitor is pure Dart; UiStallBindings feeds it from the
      // Flutter side (ticker, frame timings, lifecycle) and every event
      // lands in the Crashlytics breadcrumb trail through
      // AppDiagnostics.logInfo. Installed as soon as the binding exists, so
      // the bootstrap work that runs before runApp() — PostHog,
      // SharedPreferences, windowManager — is measured too.
      final stallMonitor = UiStallMonitor(
        currentScreen: () => AppDiagnostics.currentScreen,
        onStall: (message, data) =>
            unawaited(AppDiagnostics.logInfo(message, data: data)),
      );
      activeUiStallMonitor = stallMonitor;
      uiStallBindings = UiStallBindings(monitor: stallMonitor)..start();

      // ── Google Fonts: fully offline (no fonts.gstatic.com round-trip) ──
      // The 5 families used by the app (Inter, SpaceGrotesk, JetBrainsMono,
      // FiraCode, Alexandria) are bundled as local assets under
      // assets/fonts/<family>/ (declared in pubspec.yaml), so google_fonts
      // finds them in the AssetManifest and never needs the network.
      //
      // Left at its default `true`, google_fonts would issue a GET to
      // fonts.gstatic.com on the first render of any family that is not
      // bundled: a font flash (FOUT) on first paint, and — ugly on desktop,
      // where the page is CSS-rendered — a silent loss of the whole
      // typography when the device is offline or gstatic is blocked by a
      // firewall/DNS. Setting this to false makes such a miss throw a clear
      // "font was not found in the application assets" error instead of
      // quietly degrading, which is exactly what we want: a loud failure at
      // the source rather than a silent visual regression.
      //
      // Must run before the first GoogleFonts.* call, hence here in main()
      // right after the binding is initialised and well before runApp().
      GoogleFonts.config.allowRuntimeFetching = false;

      ensureDocumentationWebViewPlatform();

      // Windows TLS compatibility override — required for HTTP requests to
      // succeed on Windows (cert store behaviour diverges from other platforms).
      HttpOverrides.global = _WindowsHttpOverrides();

      // Tune Flutter's global image cache to be more conservative.
      // Default: 1000 images / 100 MB. For a mobile app that loads
      // many large images (especially in the image editor), this can
      // cause OOM. Reduce to a safer default.
      final cache = PaintingBinding.instance.imageCache;
      cache.maximumSize = 200;
      cache.maximumSizeBytes = 50 << 20; // 50 MB

      await AppDiagnostics.initialize();
      AppDiagnostics.installGlobalErrorHandlers();
      try {
        FlutterForegroundTask.initCommunicationPort();
        await AppDiagnostics.logInfo(
          'Foreground task communication initialized',
        );
      } catch (error, stack) {
        await AppDiagnostics.logError(
          'Foreground task communication initialization failed',
          error,
          stack,
          fatal: false,
        );
      }

      await _bootstrapAndRunApp();
    },
    (error, stack) async {
      // Network/TLS errors (SocketException, HandshakeException, etc.) are not
      // application bugs — the platform may have a bad connection, VPN issues,
      // or flaky mobile data.  Log as non-fatal to avoid polluting Crashlytics.
      final fatal =
          !AppDiagnostics.isTransientNetworkError(error) &&
          !AppDiagnostics.isBenignFlutterFrameworkError(error);
      await AppDiagnostics.logError(
        'Uncaught zone error during bootstrap/runtime',
        error,
        stack,
        fatal: fatal,
      );
    },
  );
}

Future<void> _bootstrapAndRunApp() async {
  try {
    appManager = AppManager();

    // ── PostHog analytics & session recording ─────────────────────────
    await PosthogService.init();

    initRunnerAutoReload();
    final prefs = await SharedPreferences.getInstance();
    final onboardingManager = OnboardingManager(prefs);

    if (MobileAccountGate.isRequired) {
      await restoreMainApiSessionIfNeeded();
    }

    if (ResponsiveHelper.isDesktopPlatform()) {
      try {
        await windowManager.ensureInitialized();
        const windowOptions = WindowOptions(
          size: Size(1280, 720),
          minimumSize: Size(800, 600),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
        );
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      } catch (e, stack) {
        await AppDiagnostics.logError(
          'Failed to initialize windowManager',
          e,
          stack,
          fatal: false,
        );
      }
    }

    runApp(
      PostHogWidget(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            // Personnalisation de l'editeur de code (theme, police, indentation).
            // Rose Pine est le defaut ; `load()` est fire-and-forget : la page
            // affiche d'abord les defauts puis se reconstruit quand les reglages
            // persistes arrivent (notifyListeners).
            ChangeNotifierProvider(
              create: (_) => CodeEditorSettingsProvider()..load(),
            ),
            Provider(create: (_) => onboardingManager),
          ],
          child: const MyApp(),
        ),
      ),
    );

    warmUpFuture = _warmUpServicesAfterLaunch();
    unawaited(warmUpFuture!);
  } catch (error, stack) {
    await AppDiagnostics.logError(
      'Fatal startup error before runApp',
      error,
      stack,
      fatal: true,
    );
    runApp(StartupFailureApp(error: error.toString()));
  }
}

Future<void> _warmUpServicesAfterLaunch() async {
  await AppDiagnostics.logInfo('Post-launch service warm-up started');

  await _runStartupTask(
    label: 'Main API session restore',
    operation: 'startup_main_api_session_restore',
    timeout: const Duration(seconds: 8),
    action: _restorePersistedMainApiSession,
  );

  var firebaseReady = false;
  if (_isFirebaseSupported) {
    firebaseReady = await _runStartupTask(
      label: 'Firebase initialization',
      operation: 'startup_firebase_init',
      timeout: const Duration(seconds: 10),
      action: () async {
        await AppDiagnostics.logInfo(
          'Initializing Firebase',
          data: {'platform': defaultTargetPlatform.name},
        );
        firebaseApp = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        if (!firebaseApp!.isAutomaticDataCollectionEnabled) {
          await firebaseApp!.setAutomaticDataCollectionEnabled(true);
        }
        await AppDiagnostics.logInfo('Firebase initialized');
      },
    );
  }

  await _runStartupTask(
    label: 'PostHog initialization',
    operation: 'startup_posthog_init',
    timeout: const Duration(seconds: 10),
    action: () async {
      await AppDiagnostics.logInfo('Initializing PostHog');
      await PosthogService.init();
      await AppDiagnostics.logInfo('PostHog initialized');
    },
  );

  await _runStartupTask(
    label: 'Crashlytics configuration',
    operation: 'startup_crashlytics_config',
    timeout: const Duration(seconds: 5),
    action: () async {
      await AppDiagnostics.configureCrashlytics(
        crashlyticsSupported: _isCrashlyticsSupported,
        firebaseReady: firebaseReady,
      );
    },
  );

  await _runStartupTask(
    label: 'Ad consent flow',
    operation: 'startup_ad_consent',
    timeout: const Duration(seconds: 15),
    action: () async {
      await AdConsentService.ensureCanRequestAds(
        requestTrackingTransparency: false,
      );
    },
  );

  await _runStartupTask(
    label: 'Rewarded ads initialization',
    operation: 'startup_ad_reward_init',
    timeout: const Duration(seconds: 15),
    action: () async {
      await AdRewardService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Native ads initialization',
    operation: 'startup_ad_native_init',
    timeout: const Duration(seconds: 15),
    action: () async {
      await AdNativeService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Subscription service initialization',
    operation: 'startup_subscription_init',
    timeout: const Duration(seconds: 15),
    action: () async {
      await SubscriptionService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Hosted app subscription service initialization',
    operation: 'startup_hosted_subscription_init',
    timeout: const Duration(seconds: 10),
    action: () async {
      await HostedAppSubscriptionService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Hosted app subscription server refresh',
    operation: 'startup_hosted_subscription_refresh',
    timeout: const Duration(seconds: 8),
    action: () async {
      await HostedAppSubscriptionService.refreshFromServer(forceRefresh: true);
    },
  );

  await _runStartupTask(
    label: 'Main API client hashes load',
    operation: 'startup_main_api_hashes',
    timeout: const Duration(seconds: 5),
    action: () async {
      await MainApiClient.initialize();
    },
  );

  await _runStartupTask(
    label: 'Debug replay state load',
    operation: 'startup_debug_replay_state',
    timeout: const Duration(seconds: 5),
    action: () async {
      await loadDebugReplayCapturingState();
    },
  );

  await _runStartupTask(
    label: 'Discord RPC initialization',
    operation: 'startup_discord_rpc_init',
    timeout: const Duration(seconds: 5),
    action: () async {
      await DiscordRpcService.instance.initialize();
    },
  );

  await _runStartupTask(
    label: 'Notification service initialization',
    operation: 'startup_notification_init',
    timeout: const Duration(seconds: 10),
    action: () async {
      // Detect environment from the connected Manager URL
      String managerUrl = '';
      try {
        final config = await MainApiSettingsStore.loadConfig();
        managerUrl = config.baseUrl;
      } catch (_) {}
      await NotificationService.instance.initialize(managerBaseUrl: managerUrl);
      try {
        if (managerUrl.isNotEmpty) {
          final client = MainApiClient(baseUrl: managerUrl);
          await NotificationService.instance.registerWithApi(client);
        }
      } catch (_) {}
    },
  );

  await _runStartupTask(
    label: 'Runner associations load',
    operation: 'startup_runner_associations',
    timeout: const Duration(seconds: 5),
    action: () async {
      await RunnerSettings.loadAssociations();
    },
  );

  await _runStartupTask(
    label: 'Embedded JS runner startup',
    operation: 'startup_embedded_js_runner',
    timeout: const Duration(minutes: 6),
    action: () async {
      if (!kIsWeb &&
          (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final embedded = await RunnerSettings.prepareEmbeddedJsRunner();
        final service = EmbeddedJsRunnerService.instance;
        if (embedded == null) {
          await AppDiagnostics.logError(
            'Embedded JS runner failed to start on desktop warm-up',
            service.lastStartupError ?? 'unknown',
            StackTrace.current,
            fatal: false,
            information:
                'phase=${service.lastStartupPhase ?? 'unknown'}; '
                'logPath=${service.logPath ?? 'n/a'}',
          );
        } else {
          await AppDiagnostics.logInfo(
            'Embedded JS runner warm-up succeeded',
            data: <String, Object?>{
              'baseUrl': embedded.url,
              'logPath': service.logPath,
            },
          );
        }
      }
    },
  );

  await AppDiagnostics.logInfo('Post-launch service warm-up completed');
}

Future<void> _restorePersistedMainApiSession() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return;
  }

  try {
    final session = await restoreMainApiSessionIfNeeded();
    if (session != null) {
      await AppDiagnostics.logInfo(
        'Main API session restored from refresh token on startup',
        data: <String, Object?>{
          'expiresAt': session.expiresAt.toUtc().toIso8601String(),
        },
      );
    }
  } catch (error, stack) {
    await AppDiagnostics.logError(
      'Main API session restore failed on startup',
      error,
      stack,
      fatal: false,
    );
  }

  if (MobileAccountGate.isRequired) {
    await MobileAccountSession.instance.recheck();
  }
}

Future<bool> _runStartupTask({
  required String label,
  required String operation,
  required Duration timeout,
  required Future<void> Function() action,
}) async {
  // Every startup step is marked: when the warm-up freezes the UI isolate,
  // the breadcrumb names the step (`startup_*`) and how long it took,
  // instead of leaving an ANR report with no Dart frame to explain it.
  activeUiStallMonitor?.markStart(operation);
  try {
    await action().timeout(
      timeout,
      onTimeout: () async {
        // Don't throw — network timeouts are expected on slow connections.
        // Log to the diagnostics file only (info level, NOT Crashlytics).
        await AppDiagnostics.logInfo(
          '$label did not complete within ${timeout.inSeconds}s (network may be slow)',
          data: {'step': label, 'timeoutSeconds': timeout.inSeconds},
        );
      },
    );
    await AppDiagnostics.logInfo(
      'Startup step completed',
      data: {'step': label},
    );
    return true;
  } catch (error, stack) {
    // Unexpected failures ARE Crashlytics-worthy (crashes, not timeouts).
    await AppDiagnostics.logError(
      '$label failed during startup warm-up',
      error,
      stack,
      fatal: false,
    );
    return false;
  } finally {
    // Always closed, including on a timeout or a thrown error, so a slow
    // step is reported exactly once with its real duration.
    activeUiStallMonitor?.markEnd(operation);
  }
}

class OAuthCallbackRedirectPage extends StatefulWidget {
  const OAuthCallbackRedirectPage({super.key});

  @override
  State<OAuthCallbackRedirectPage> createState() =>
      _OAuthCallbackRedirectPageState();
}

class _OAuthCallbackRedirectPageState extends State<OAuthCallbackRedirectPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final routeName = ModalRoute.of(context)?.settings.name;
      final callbackUri = routeName == null ? null : Uri.tryParse(routeName);
      if (callbackUri != null) {
        await MainApiAuthService.tryCompleteMobileOAuthCallback(callbackUri);
      }
      await MobileAccountSession.instance.recheck();

      if (!mounted) {
        return;
      }
      final navigator = MyApp.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    DesktopTitleBarNotifier.instance.navigatorKey = MyApp.navigatorKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_requestTrackingAndEnableAnalytics());
    });
  }

  Future<void> _requestTrackingAndEnableAnalytics() async {
    await AdConsentService.requestTrackingTransparencyIfNeeded();
    try {
      await AppAnalytics.setCollectionEnabled(true);
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Analytics collection setup failed',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    AppAnalytics.logAppOpen();
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final onboardingManager = context.read<OnboardingManager>();

    return MaterialApp(
      navigatorKey: MyApp.navigatorKey,
      navigatorObservers: [PosthogObserver(), DesktopTitleBarNotifier.instance],
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        if (!ResponsiveHelper.isDesktopPlatform()) {
          return content;
        }
        return DesktopAppShell(child: content);
      },
      onGenerateTitle: (context) => context.tr.app_title,
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (_isOAuthCallbackRoute(name)) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => const OAuthCallbackRedirectPage(),
          );
        }
        return null;
      },
      locale: Locale(localeProvider.locale.code),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.lightTheme(appearance: themeProvider.appearance),
      darkTheme: AppTheme.darkTheme(appearance: themeProvider.appearance),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: onboardingManager.isFirstRun
          ? OnboardingPage(
              onComplete: () {
                // When onboarding completes, navigate to main app.
                // Use the app navigator key instead of outer build context.
                final navigator = MyApp.navigatorKey.currentState;
                if (navigator != null) {
                  navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                }
              },
            )
          : const MobileAccountGateShell(child: MyMainPage()),
      routes: {
        '/home': (context) => const MobileAccountGateShell(child: MyMainPage()),
      },
    );
  }

  bool _isOAuthCallbackRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(routeName);
    if (uri == null) {
      return false;
    }

    return uri.path == '/oauth/main-api/discord' ||
        uri.path == '/main-api/discord';
  }
}

class MyMainPage extends StatefulWidget {
  const MyMainPage({super.key});

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> {
  int _compactTabIndex = 0;
  int? _managingBotId;
  String? _managingBotName;

  void _openManageBot(String id, String name) {
    setState(() {
      _managingBotId = int.tryParse(id) ?? 0;
      _managingBotName = name;
      _compactTabIndex = 0;
    });
    DesktopTitleBarNotifier.instance.updateManagingBot(
      name: name,
      id: _managingBotId,
      onExit: _closeManageBot,
    );
  }

  void _closeManageBot() {
    setState(() {
      _managingBotId = null;
      _managingBotName = null;
    });
    DesktopTitleBarNotifier.instance.updateManagingBot(
      name: null,
      id: null,
      onExit: null,
    );
    // Refresh home running state after leaving the editor.
    unawaited(HomePageState.current?.triggerRefresh());
  }

  @override
  void dispose() {
    DesktopTitleBarNotifier.instance.updateManagingBot(
      name: null,
      id: null,
      onExit: null,
    );
    super.dispose();
  }

  Widget _homeOrManage() {
    final botId = _managingBotId;
    final botName = _managingBotName;
    if (botId != null && botName != null) {
      return AppEditPage(
        key: ValueKey<int>(botId),
        appName: botName,
        id: botId,
        embedded: true,
        onExit: _closeManageBot,
      );
    }
    return HomePage(onManageBot: _openManageBot);
  }

  @override
  Widget build(BuildContext context) {
    final isWide =
        MediaQuery.sizeOf(context).width >= AppTheme.desktopBreakpoint;

    if (isWide) {
      return Scaffold(
        body: SafeArea(
          bottom: false,
          top: !ResponsiveHelper.isDesktopPlatform(),
          child: _homeOrManage(),
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            top: !ResponsiveHelper.isDesktopPlatform(),
            child: IndexedStack(
              index: _compactTabIndex,
              children: [
                _homeOrManage(),
                _aboveFloatingNav(
                  const DocumentationHubPage(
                    showDiscordJsTab: true,
                    embedded: true,
                  ),
                ),
                _aboveFloatingNav(const SettingPage(embedded: true)),
              ],
            ),
          ),
          if (_managingBotId == null)
            Positioned(
              left: FloatingGlassNavBar.margin,
              right: FloatingGlassNavBar.margin,
              bottom: FloatingGlassNavBar.bottomOffsetOf(context),
              child: FloatingGlassNavBar(items: _shellNavItems(context)),
            ),
        ],
      ),
    );
  }

  /// Réserve la hauteur de la barre flottante sous [child] : sans cela, le bas
  /// des pages du shell (`DocumentationHubPage`, `SettingPage`) est masqué,
  /// puisque `extendBody: true` fait passer le contenu sous la barre.
  ///
  /// `HomePage` est volontairement exclue : elle réserve déjà l'espace
  /// nécessaire dans son propre `ListView` (padding bas codé en dur), et
  /// cumuler les deux ajouterait un vide en fin de liste.
  Widget _aboveFloatingNav(Widget child) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: FloatingGlassNavBar.contentClearanceOf(context),
      ),
      child: child,
    );
  }

  /// Les 3 destinations du shell : Accueil / Documentation / Réglages.
  List<FloatingGlassNavItem> _shellNavItems(BuildContext context) {
    final tr = context.tr;
    return [
      FloatingGlassNavItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: tr.home_tab,
        selected: _compactTabIndex == 0,
        onTap: () => setState(() => _compactTabIndex = 0),
      ),
      FloatingGlassNavItem(
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book_rounded,
        label: tr.docs_hub_title,
        selected: _compactTabIndex == 1,
        onTap: () => setState(() => _compactTabIndex = 1),
      ),
      FloatingGlassNavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: tr.settings_tab,
        selected: _compactTabIndex == 2,
        onTap: () => setState(() => _compactTabIndex = 2),
      ),
    ];
  }
}

/// Apparence de l'application : mode clair/sombre, preset de couleurs et
/// personnalisations (graine + accent), persistés en JSON.
///
/// Deux clés de `SharedPreferences` cohabitent le temps de la migration :
///   * `app_appearance` — configuration complète (JSON), écrite par ce
///     provider ;
///   * `theme_mode` — ANCIENNE clé (mode seul) : lue une dernière fois au
///     démarrage pour initialiser le mode, puis supprimée.
class ThemeProvider extends ChangeNotifier {
  /// Clé de la configuration d'apparence complète.
  static const _key = 'app_appearance';

  /// Ancienne clé, conservée uniquement pour la migration.
  static const _legacyKey = 'theme_mode';

  AppAppearanceConfig _appearance = AppAppearanceConfig.defaults;

  /// Config d'apparence courante (mode + couleurs).
  AppAppearanceConfig get appearance => _appearance;

  /// Mode clair/sombre/système (raccourci consommé par `MaterialApp`).
  ThemeMode get themeMode => _appearance.mode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _appearance = AppAppearanceConfig.decode(saved);
      // Migration déjà faite : l'ancienne clé de mode n'a plus de raison d'être.
      if (prefs.containsKey(_legacyKey)) {
        await prefs.remove(_legacyKey);
      }
    } else {
      // Migration : la seule information disponible est l'ancien mode.
      final legacyMode = _legacyModeFrom(prefs);
      _appearance = _appearance.copyWith(mode: legacyMode);
      if (prefs.containsKey(_legacyKey)) {
        await _persist();
        await prefs.remove(_legacyKey);
      }
    }
    notifyListeners();
  }

  /// Mode lu dans l'ancienne clé `theme_mode` (cette version ne l'écrit plus) ;
  /// toute valeur absente ou inconnue vaut sombre, comme avant.
  ThemeMode _legacyModeFrom(SharedPreferences prefs) =>
      prefs.getString(_legacyKey) == 'light' ? ThemeMode.light : ThemeMode.dark;

  Future<void> setMode(ThemeMode mode) =>
      _update(_appearance.copyWith(mode: mode));

  /// Applique un preset : graine et accent reprennent ses couleurs (les
  /// personnalisations précédentes sont donc remplacées). L'accent persisté
  /// est la variante CLAIRE ([AppAppearancePreset.accentLight]) — référence
  /// stable du preset, indépendante du mode : la variante peinte suit le mode
  /// courant (`AppAppearanceConfig.accentFor`).
  Future<void> setPreset(AppAppearancePreset preset) => _update(
    _appearance.copyWith(
      presetId: preset.id,
      seedColor: preset.seed,
      accentColor: preset.accentLight,
    ),
  );

  /// Personnalisation de l'accent d'action (boutons, focus, états actifs).
  Future<void> setAccent(Color accentColor) =>
      _update(_appearance.copyWith(accentColor: accentColor));

  /// Personnalisation de la graine (teinte des surfaces du thème).
  Future<void> setSeed(Color seedColor) =>
      _update(_appearance.copyWith(seedColor: seedColor));

  /// Bascule clair ↔ sombre (bouton de la page Paramètres).
  Future<void> toggleTheme() => setMode(
    _appearance.mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
  );

  /// Réinitialise l'apparence aux valeurs d'usine (graphite sombre).
  Future<void> resetToDefaults() async {
    _appearance = AppAppearanceConfig.defaults;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    // Sans cela, l'ancienne clé de mode rejouerait un mode après la
    // réinitialisation, au prochain démarrage.
    await prefs.remove(_legacyKey);
  }

  /// Ancien nom de [resetToDefaults] — `settings_page.dart` l'appelle encore
  /// (la page Apparence le remplacera).
  Future<void> resetToDefault() => resetToDefaults();

  /// Applique [config] en mémoire, notifie puis la persiste.
  Future<void> _update(AppAppearanceConfig config) async {
    _appearance = config;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _appearance.encode());
  }
}

class StartupFailureApp extends StatefulWidget {
  const StartupFailureApp({super.key, required this.error});

  final String error;

  @override
  State<StartupFailureApp> createState() => _StartupFailureAppState();
}

class _StartupFailureAppState extends State<StartupFailureApp> {
  String _diagnostics = 'Loading diagnostics...';
  bool _copying = false;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    final text = await AppDiagnostics.readLog(maxLines: 200);
    if (!mounted) {
      return;
    }
    setState(() {
      _diagnostics = text;
    });
  }

  Future<void> _copyDiagnostics(BuildContext context) async {
    setState(() {
      _copying = true;
    });
    try {
      await AppDiagnostics.copyLogToClipboard(maxLines: 300);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.startup_diagnostics_copied)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _copying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bot Creator',
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr.startup_error_title)),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr.startup_failed_message,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(widget.error),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _copying
                            ? null
                            : () => _copyDiagnostics(context),
                        child: Text(context.tr.startup_copy_diagnostics),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _loadDiagnostics,
                        child: Text(context.tr.startup_refresh_diagnostics),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(_diagnostics),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Windows TLS compatibility override.
class _WindowsHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    if (Platform.isWindows) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    }
    return client;
  }
}
