import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:bot_creator_shared/bot_creator_shared.dart';
import 'package:bot_creator_shared/actions/executors/image_executor.dart';

void main() async {
  print('Initial RSS: ${ProcessInfo.currentRss / (1024 * 1024)} MB');

  final source = '''
\$canvasCreate[mute;800;400;#1e1f22]
\$canvasLoadImage[https://cdn.discordapp.com/embed/avatars/0.png;0;0;800;400]
\$canvasDrawCircle[130;200;95;#5865F2;true]
\$canvasDrawCircle[130;200;88;white;true]
\$canvasCompositeImage[https://cdn.discordapp.com/embed/avatars/0.png;42;112;176;176;circle]
\$canvasDrawText[PUNISHMENT APPLIED;260;90;36;#5865F2]
\$canvasDrawLine[260;125;700;125;#5865F2;3]
\$canvasDrawText[Action: Mute;260;180;28;white]
\$canvasDrawText[User: TestUser;260;225;24;white]
\$canvasDrawText[Duration: 30 Minutes;260;270;24;white]
\$canvasDrawText[Reason: Spamming in chat;260;315;24;lightgray]
\$canvasDrawText[Issued by Punishment;260;360;20;#5865F2]
\$attachImage[card]
''';

  print('Compiling script...');
  final compileResult = BdfdCompiler().compile(source);
  print('Compiled into ${compileResult.actions.length} actions.');

  final imageAction = compileResult.actions.firstWhere(
    (a) => a.type == BotCreatorActionType.runtimeImageBlock,
  );

  final client = http.Client();
  final staticCache = <String, Uint8List>{};

  print('Running simulation loop (WITH PRELOAD FIX)...');
  for (var i = 1; i <= 150; i++) {
    final results = <String, String>{};
    final variables = <String, String>{};

    // ── Preload HTTP images on main isolate ──
    final preloadedImages = <String, Uint8List>{};
    final operations = imageAction.payload['operations'];
    if (operations is List) {
      for (final op in operations) {
        if (op is! Map) continue;
        final opName = (op['op'] ?? '').toString();
        if (opName == 'loadImage' || opName == 'compositeImage') {
          final url = (op['url'] ?? op['dataUrl'] ?? '').toString();
          if (url.startsWith('http://') || url.startsWith('https://')) {
            if (staticCache.containsKey(url)) {
              preloadedImages[url] = staticCache[url]!;
            } else {
              final bytes = await resolveImageSource(url, client: client);
              if (bytes != null) {
                staticCache[url] = bytes;
                preloadedImages[url] = bytes;
              }
            }
          }
        }
      }
    }

    // Run executeRuntimeImageBlock with preloaded images map
    await executeRuntimeImageBlock(
      payload: imageAction.payload,
      resultKey: 'rtImage_0',
      results: results,
      variables: variables,
      resolveValue: (val) => val,
      // We pass the preloaded map. Wait, our current image_executor doesn't accept preloaded map yet,
      // so in this simulation we will execute it using a custom call or we will modify the actual executor.
      // Let's modify the actual executor to support preloadedImages first, then run!
    );

    // Simulate cleanup of temp._canvasAttachment_card
    variables.removeWhere((k, v) => k.startsWith('temp._canvasAttachment_'));

    if (i % 15 == 0 || i == 1) {
      final rss = ProcessInfo.currentRss / (1024 * 1024);
      print('Iteration $i - RSS: ${rss.toStringAsFixed(2)} MB');
    }
  }

  staticCache.clear();
  client.close();
  print('Simulation complete. Waiting 5 seconds for idle GC...');
  await Future.delayed(const Duration(seconds: 5));
  final finalRss = ProcessInfo.currentRss / (1024 * 1024);
  print('Final RSS: ${finalRss.toStringAsFixed(2)} MB');
}
