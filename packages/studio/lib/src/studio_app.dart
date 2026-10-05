import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'screens/login_page.dart';
import 'screens/studio_shell.dart';
import 'theme.dart';

class StudioApp extends StatefulWidget {
  const StudioApp({super.key, this.auth});

  /// Injectable pour les tests ; par défaut, l'API configurée à la compilation.
  final AuthController? auth;

  @override
  State<StudioApp> createState() => _StudioAppState();
}

class _StudioAppState extends State<StudioApp> {
  late final AuthController _auth = widget.auth ?? AuthController();

  @override
  void initState() {
    super.initState();
    _auth.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bot Creator Studio',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: StudioTheme.dark(),
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
    );
  }
}
