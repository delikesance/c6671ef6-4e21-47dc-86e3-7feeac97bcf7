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
import 'package:nyxx/nyxx.dart' hide Locale, Builder;
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/settings/presentation/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:bot_creator/features/onboarding/presentation/onboarding_page.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
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
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/features/auth/presentation/mobile_account_gate_shell.dart';


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
      final fatal = !_isTransientNetworkError(error);
      await AppDiagnostics.logError(
        'Uncaught zone error during bootstrap/runtime',
        error,
        stack,
        fatal: fatal,
      );
    },
  );
}

/// Returns `true` when [error] is a transient network/TLS failure that should
/// NOT be treated as an application crash.
bool _isTransientNetworkError(Object error) {
  final name = error.runtimeType.toString();
  if (name.contains('SocketException') ||
      name.contains('HandshakeException') ||
      name.contains('TlsException') ||
      name.contains('ClientException') ||
      name.contains('TimeoutException') ||
      name.contains('HttpException') ||
      name.contains('WebSocketException')) {
    return true;
  }
  final message = error.toString().toLowerCase();
  return message.contains('connection timed out') ||
      message.contains('connection refused') ||
      message.contains('network is unreachable') ||
      message.contains('handshake') ||
      message.contains('no route to host');
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

    runApp(
      PostHogWidget(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
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
    timeout: const Duration(seconds: 8),
    action: _restorePersistedMainApiSession,
  );

  var firebaseReady = false;
  if (_isFirebaseSupported) {
    firebaseReady = await _runStartupTask(
      label: 'Firebase initialization',
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
    timeout: const Duration(seconds: 10),
    action: () async {
      await AppDiagnostics.logInfo('Initializing PostHog');
      await PosthogService.init();
      await AppDiagnostics.logInfo('PostHog initialized');
    },
  );

  await _runStartupTask(
    label: 'Crashlytics configuration',
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
    timeout: const Duration(seconds: 15),
    action: () async {
      await AdConsentService.ensureCanRequestAds(
        requestTrackingTransparency: false,
      );
    },
  );

  await _runStartupTask(
    label: 'Rewarded ads initialization',
    timeout: const Duration(seconds: 15),
    action: () async {
      await AdRewardService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Native ads initialization',
    timeout: const Duration(seconds: 15),
    action: () async {
      await AdNativeService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Subscription service initialization',
    timeout: const Duration(seconds: 15),
    action: () async {
      await SubscriptionService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Hosted app subscription service initialization',
    timeout: const Duration(seconds: 10),
    action: () async {
      await HostedAppSubscriptionService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Hosted app subscription server refresh',
    timeout: const Duration(seconds: 8),
    action: () async {
      await HostedAppSubscriptionService.refreshFromServer(forceRefresh: true);
    },
  );

  await _runStartupTask(
    label: 'Main API client hashes load',
    timeout: const Duration(seconds: 5),
    action: () async {
      await MainApiClient.initialize();
    },
  );

  await _runStartupTask(
    label: 'Debug replay state load',
    timeout: const Duration(seconds: 5),
    action: () async {
      await loadDebugReplayCapturingState();
    },
  );

  await _runStartupTask(
    label: 'Discord RPC initialization',
    timeout: const Duration(seconds: 5),
    action: () async {
      await DiscordRpcService.instance.initialize();
    },
  );

  await _runStartupTask(
    label: 'Notification service initialization',
    timeout: const Duration(seconds: 10),
    action: () async {
      // Detect environment from the connected Manager URL
      String managerUrl = '';
      try {
        final config = await MainApiSettingsStore.loadConfig();
        managerUrl = config.baseUrl;
      } catch (_) {}
      await NotificationService.instance.initialize(
        managerBaseUrl: managerUrl,
      );
    },
  );

  await _runStartupTask(
    label: 'Runner associations load',
    timeout: const Duration(seconds: 5),
    action: () async {
      await RunnerSettings.loadAssociations();
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
  required Duration timeout,
  required Future<void> Function() action,
}) async {
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
  }
}

class OAuthCallbackRedirectPage extends StatefulWidget {
  const OAuthCallbackRedirectPage({super.key});

  @override
  State<OAuthCallbackRedirectPage> createState() => _OAuthCallbackRedirectPageState();
}

class _OAuthCallbackRedirectPageState extends State<OAuthCallbackRedirectPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = MyApp.navigatorKey.currentState;
      if (navigator != null) {
        navigator.pushNamedAndRemoveUntil('/home', (route) => false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
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
      navigatorObservers: [PosthogObserver()],
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.brandPrimary),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home:
          onboardingManager.isFirstRun
              ? OnboardingPage(
                onComplete: () {
                  // When onboarding completes, navigate to main app.
                  // Use the app navigator key instead of outer build context.
                  final navigator = MyApp.navigatorKey.currentState;
                  if (navigator != null) {
                    navigator.pushNamedAndRemoveUntil(
                      '/home',
                      (route) => false,
                    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(106, 15, 162, 1),
        title: Text(context.tr.app_title),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: context.tr.common_refresh,
            onPressed: () {
              HomePageState.current?.triggerRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingPage()),
              );
            },
          ),
        ],
      ),
      body: const HomePage(),
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AppCreatePage()),
          );
        },
        backgroundColor: const Color.fromRGBO(106, 15, 162, 1),
        icon: const Icon(Icons.add),
        label: Text(context.tr.app_create_button),
      ),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  static const _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    _themeMode = saved == 'light' ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      _themeMode == ThemeMode.dark ? 'dark' : 'light',
    );
  }

  Future<void> resetToDefault() async {
    _themeMode = ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
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
                        onPressed:
                            _copying ? null : () => _copyDiagnostics(context),
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
