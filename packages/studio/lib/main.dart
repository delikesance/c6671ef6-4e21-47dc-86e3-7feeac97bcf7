import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';

import 'src/studio_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UiFonts.registerBundled();
  runApp(const StudioApp());
}
