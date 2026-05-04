import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/i18n/extensions.dart';
import 'package:bot_creator/core/i18n/locale_provider.dart';
import 'package:bot_creator/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:nyxx/nyxx.dart' hide Locale;
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/settings/presentation/settings_page.dart';
import 'package:provider/provider.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:bot_creator/features/onboarding/presentation/onboarding_page.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/features/ads/logic/ad_native_service.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';

import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/core/theme/app_theme.dart';

@pragma('vm:entry-point')
AppManager? _appManager;

@pragma('vm:entry-point')
AppManager get appManager => _appManager ??= AppManager();

@pragma('vm:entry-point')
set appManager(AppManager value) => _appManager = value;
List<String> currentLogList = [];
@pragma('vm:entry-point')
List<NyxxGateway> gateways = [];
FirebaseApp? firebaseApp;

bool get _isFirebaseSupported {
  if (kIsWeb) {
    return true;
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return true;
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
    case TargetPlatform.macOS:
      return true;
    case TargetPlatform.windows:
    case TargetPlatform.linux:
      return false;
    default:
      return false;
  }
}

Future<void> main() async {
  HttpOverrides.global = _WindowsHttpOverrides();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
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
      await AppDiagnostics.logError(
        'Uncaught zone error during bootstrap/runtime',
        error,
        stack,
        fatal: true,
      );
    },
  );
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

Future<void> _bootstrapAndRunApp() async {
  try {
    appManager = AppManager();
    initRunnerAutoReload();
    final prefs = await SharedPreferences.getInstance();
    final onboardingManager = OnboardingManager(prefs);

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          Provider(create: (_) => onboardingManager),
        ],
        child: const MyApp(),
      ),
    );

    unawaited(_warmUpServicesAfterLaunch());
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
    timeout: const Duration(seconds: 8),
    action: () async {
      await AdConsentService.ensureCanRequestAds(
        requestTrackingTransparency: false,
      );
    },
  );

  await _runStartupTask(
    label: 'Rewarded ads initialization',
    timeout: const Duration(seconds: 8),
    action: () async {
      await AdRewardService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Native ads initialization',
    timeout: const Duration(seconds: 8),
    action: () async {
      await AdNativeService.initialize();
    },
  );

  await _runStartupTask(
    label: 'Subscription service initialization',
    timeout: const Duration(seconds: 8),
    action: () async {
      await SubscriptionService.initialize();
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

  await AppDiagnostics.logInfo('Post-launch service warm-up completed');
}

Future<void> _restorePersistedMainApiSession() async {
  final config = await MainApiSettingsStore.loadConfig();
  final session = await MainApiSettingsStore.loadSession();
  if (session == null) {
    return;
  }

  if (session.isExpired && session.refreshToken == null) {
    await MainApiSettingsStore.clearSession();
    return;
  }

  final refreshToken = session.refreshToken?.trim() ?? '';
  if (refreshToken.isEmpty || !session.expiresSoon()) {
    return;
  }

  final client = MainApiClient(
    baseUrl: config.baseUrl,
    timeout: const Duration(seconds: 6),
  );
  try {
    final refreshedSession = await client.refreshSession(
      refreshToken: refreshToken,
    );
    await MainApiSettingsStore.saveSession(refreshedSession);
    await AppDiagnostics.logInfo(
      'Main API session restored from refresh token on startup',
      data: <String, Object?>{
        'sessionExpired': session.isExpired,
        'expiresAt': refreshedSession.expiresAt.toUtc().toIso8601String(),
      },
    );
  } catch (error, stack) {
    await AppDiagnostics.logError(
      'Main API session restore failed on startup',
      error,
      stack,
      fatal: false,
    );
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
      onTimeout:
          () =>
              throw TimeoutException(
                '$label timed out after ${timeout.inSeconds} seconds',
              ),
    );
    await AppDiagnostics.logInfo(
      'Startup step completed',
      data: {'step': label},
    );
    return true;
  } catch (error, stack) {
    await AppDiagnostics.logError(
      '$label failed during startup warm-up',
      error,
      stack,
      fatal: false,
    );
    return false;
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
      onGenerateTitle: (context) => context.tr.app_title,
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (_isOAuthCallbackRoute(name)) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (context) => MyMainPage(title: context.tr.app_title),
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
              : MyMainPage(title: context.tr.app_title),
      routes: {'/home': (context) => MyMainPage(title: context.tr.app_title)},
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
  const MyMainPage({super.key, required this.title});
  final String title;

  @override
  State<MyMainPage> createState() => _MyMainPageState();
}

class _MyMainPageState extends State<MyMainPage> {
  final GlobalKey<HomePageState> _homePageKey = GlobalKey<HomePageState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(106, 15, 162, 1),
        title: Text(widget.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: () {
              _homePageKey.currentState?.syncAllBotsFromManager();
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
      body: HomePage(key: _homePageKey),
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

  Future<void> _copyDiagnostics() async {
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
      title: context.tr.app_title,
      home: Scaffold(
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
                    onPressed: _copying ? null : _copyDiagnostics,
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
      ),
    );
  }
}
