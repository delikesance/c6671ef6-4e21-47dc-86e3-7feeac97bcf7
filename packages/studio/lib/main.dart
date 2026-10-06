import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import 'src/editor/bdfd_hooks.dart';
import 'src/studio_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Comme l'app : polices servies par le paquet partagé, jamais par le réseau.
  GoogleFonts.config.allowRuntimeFetching = false;
  await UiFonts.registerBundled();
  bindStudioBdfdHooks();
  runApp(const StudioApp());
}
