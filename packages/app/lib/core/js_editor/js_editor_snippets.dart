import 'package:bot_creator/core/code_editor/script_editor_snippet.dart';

/// Extrait insérable depuis la barre de chips de l'éditeur JavaScript.
///
/// Alias du modèle partagé du chrome ([ScriptEditorSnippet]) : les constantes
/// ci-dessous alimentent directement `ScriptEditorScaffold.snippets`.
typedef JsEditorSnippet = ScriptEditorSnippet;

const jsEditorSnippets = <JsEditorSnippet>[
  JsEditorSnippet(
    label: 'reply',
    insert: 'await interaction.reply("");',
    cursorOffset: 25,
  ),
  JsEditorSnippet(label: 'defer', insert: 'await interaction.deferReply();\n'),
  JsEditorSnippet(
    label: 'followUp',
    insert: 'await interaction.followUp("");',
    cursorOffset: 28,
  ),
  JsEditorSnippet(label: 'ping', insert: 'await interaction.reply("pong");'),
  JsEditorSnippet(
    label: 'getString',
    insert: 'interaction.options.getString("")',
    cursorOffset: 32,
  ),
  JsEditorSnippet(
    label: 'client',
    insert:
        "const { Client, GatewayIntentBits } = require('discord.js');\n"
        'const client = new Client({ intents: [GatewayIntentBits.Guilds] });\n'
        'client.login("TOKEN");\n',
  ),
  JsEditorSnippet(
    label: 'db.user.get',
    insert: "const coins = await db.user.get('coins');",
  ),
  JsEditorSnippet(
    label: 'db.user.set',
    insert: "await db.user.set('coins', 0);",
  ),
  JsEditorSnippet(
    label: 'db.user.setId',
    insert: "await db.user.set('coins', 0, interaction.user.id);",
  ),
  JsEditorSnippet(
    label: 'db.guild.get',
    insert: "const score = await db.guild.get('score');",
  ),
  JsEditorSnippet(
    label: 'db.user.list',
    insert:
        "const leaderboard = await db.user.list('coins', 'desc', 10, 0);\n"
        '// → [{ id: "userId", value: coins }, ...]',
  ),
  JsEditorSnippet(
    label: 'db.user.find',
    insert:
        "const richUsers = await db.user.find((entry) => Number(entry.value) >= 100);",
  ),
  JsEditorSnippet(
    label: 'db.user.reset',
    insert: "await db.user.reset('coins');",
  ),
  JsEditorSnippet(
    label: 'db.guildMember.get',
    insert: "const xp = await db.guildMember.get('xp');",
  ),
  JsEditorSnippet(
    label: 'db.guildMember.set',
    insert: "await db.guildMember.set('xp', 0);",
  ),
  JsEditorSnippet(
    label: 'db.guildMember.setIds',
    insert:
        "await db.guildMember.set('xp', 0, interaction.user.id, interaction.guildId);",
  ),
  JsEditorSnippet(
    label: 'db.guildMember.reset',
    insert: "await db.guildMember.reset('xp');",
  ),
  JsEditorSnippet(
    label: 'db.global',
    insert:
        "await db.global.set('counter', 1);\nconst n = await db.global.get('counter');",
  ),
  JsEditorSnippet(
    label: 'message.reply',
    insert: 'await message.reply("");',
    cursorOffset: 24,
  ),
];

const defaultJsAutocompleteScript =
    'const focused = interaction.options.getFocused(true);\n'
    'const query = String(focused.value ?? "");\n\n'
    'await interaction.respond([\n'
    r'  { name: `Suggestion for ${query || "..."}`, value: query || "default" },'
    '\n'
    ']);';

const jsAutocompleteSnippets = <JsEditorSnippet>[
  JsEditorSnippet(
    label: 'respond',
    insert: 'await interaction.respond([\n  { name: "", value: "" },\n]);',
    cursorOffset: 35,
  ),
  JsEditorSnippet(
    label: 'focused',
    insert: 'interaction.options.getFocused(true)',
  ),
  JsEditorSnippet(
    label: 'query',
    insert:
        'const query = String(interaction.options.getFocused(true).value ?? "");',
  ),
];
