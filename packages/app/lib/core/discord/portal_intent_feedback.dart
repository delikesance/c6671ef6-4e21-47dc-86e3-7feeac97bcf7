import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:flutter/material.dart';

void showPortalIntentOutcomeSnackbars(
  BuildContext context,
  PortalIntentFetchOutcome outcome,
) {
  if (outcome.missingPrivilegedIntents.isEmpty) {
    return;
  }

  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    SnackBar(
      content: Text(context.tr.bot_settings_intents_verified_bot_manual),
    ),
  );
}
