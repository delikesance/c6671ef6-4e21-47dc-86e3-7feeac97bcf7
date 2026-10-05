import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'l10n_ext.dart';
import 'locale_controller.dart';
import 'screens/login_page.dart';
import 'screens/studio_shell.dart';
import 'theme.dart';

class StudioApp extends StatefulWidget {
  const StudioApp({super.key, this.auth, this.locale});

  /// Injectables pour les tests ; par défaut, l'API configurée à la compilation
  /// et la langue du navigateur.
  final AuthController? auth;
  final LocaleController? locale;

  @override
  State<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends State<StudioApp> {
  late final AuthController _auth = widget.auth ?? AuthController();
  late final LocaleController _locale = widget.locale ?? LocaleController();

  @override
  void initState() {
    super.initState();
    _locale.load();
    _auth.init();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _locale,
      child: ListenableBuilder(
        listenable: _locale,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => context.l10n.appTitle,
          debugShowCheckedModeBanner: false,
          themeMode: ThemeMode.dark,
          darkTheme: StudioTheme.dark(),
          locale: _locale.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListenableBuilder(
            listenable: _auth,
            builder: (context, _) {
              // Aucune route de travail sans session validée par le serveur.
              switch (_auth.status) {
                case AuthStatus.signedIn:
                  return StudioShell(auth: _auth);
                case AuthStatus.loading:
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                case AuthStatus.signedOut:
                case AuthStatus.error:
                  return LoginPage(auth: _auth);
              }
            },
          ),
        ),
      ),
    );
  }
}
