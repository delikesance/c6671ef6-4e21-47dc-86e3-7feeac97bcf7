import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart'
    as app_ser;
import 'package:bot_creator_ui/discord.dart' as lite;
import 'package:bot_creator_ui/discord.dart' as lite_ser;
import 'package:nyxx/nyxx.dart' as ny;

/// Les éditeurs partagés (`bot_creator_ui`) utilisent des équivalents web-safe
/// des types nyxx ; l'app, elle, garde les vrais types. Ce pont convertit à la
/// frontière (par valeur ; les options passent par leur sérialisation JSON,
/// qui porte aussi la configuration d'autocomplétion).
lite.ApplicationCommandType toLiteCommandType(ny.ApplicationCommandType t) =>
    lite.ApplicationCommandType(t.value);

ny.ApplicationCommandType fromLiteCommandType(lite.ApplicationCommandType t) =>
    ny.ApplicationCommandType(t.value);

List<lite.ApplicationIntegrationType> toLiteIntegrationTypes(
  List<ny.ApplicationIntegrationType> types,
) => [for (final t in types) lite.ApplicationIntegrationType(t.value)];

List<ny.ApplicationIntegrationType> fromLiteIntegrationTypes(
  List<lite.ApplicationIntegrationType> types,
) => [for (final t in types) ny.ApplicationIntegrationType(t.value)];

List<lite.InteractionContextType> toLiteContexts(
  List<ny.InteractionContextType> types,
) => [for (final t in types) lite.InteractionContextType(t.value)];

List<ny.InteractionContextType> fromLiteContexts(
  List<lite.InteractionContextType> types,
) => [for (final t in types) ny.InteractionContextType(t.value)];

List<lite.CommandOptionBuilder> toLiteOptions(
  List<ny.CommandOptionBuilder> options,
) => lite_ser.deserializeCommandOptions(
  app_ser.serializeCommandOptions(options),
);

List<ny.CommandOptionBuilder> fromLiteOptions(
  List<lite.CommandOptionBuilder> options,
) => app_ser.deserializeCommandOptions(
  lite_ser.serializeCommandOptions(options),
);
