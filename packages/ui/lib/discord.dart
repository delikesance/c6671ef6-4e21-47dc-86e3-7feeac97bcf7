/// Équivalents web-safe des types Discord de nyxx et leur sérialisation JSON.
/// Bibliothèque à part : ses noms (`Locale`, `CommandOptionType`…) sont ceux de
/// nyxx et se heurteraient à eux si on les exportait avec le reste du paquet.
library;

export 'src/discord/command_autocomplete_lite.dart';
export 'src/discord/nyxx_lite.dart';
export 'src/editor/logic/command_option_serialization.dart';
