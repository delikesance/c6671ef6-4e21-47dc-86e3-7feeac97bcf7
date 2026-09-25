import 'dart:io';

/// Occurrence d'un littéral de chaîne potentiellement affiché dans l'UI.
class HardcodedStringFinding {
  const HardcodedStringFinding({
    required this.path,
    required this.line,
    required this.content,
  });

  /// Chemin normalisé (séparateurs `/`).
  final String path;

  /// Numéro de ligne (1-indexé).
  final int line;

  /// Contenu de la ligne, nettoyé des espaces de bord.
  final String content;
}

// ─── Motifs de détection ─────────────────────────────────────────────────────

/// `Text('…')` contenant au moins une lettre — sensible à la casse
/// volontairement : en insensible, le motif attraperait `text('…')` du vrai
/// code (identifiants, appels de méthodes).
final RegExp _textLiteralPattern = RegExp(
  r"""Text\(\s*(?:const\s+)?['"][^'"\n]*[A-Za-zÀ-ÿ][^'"\n]*['"]""",
);

/// Paramètres nommés d'UI portant un littéral (`labelText: '…'`).
///
/// Insensible à la casse depuis le durcissement : `confirmLabel:` /
/// `cancelLabel:` échappaient au scan d'origine, et c'est par cette faille que
/// « Discard » s'est affiché en anglais dans une UI française. La famille de
/// paramètres couvre aussi les libellés de dialogues, d'accessibilité, les
/// titres, sous-titres, descriptions et messages.
///
/// `fr` et `en` sont dans la liste pour la MÊME raison, et c'est la faille la
/// plus large qui restait : le repli maison `_uiCopy(fr: '…', en: '…')` rend le
/// français ou l'anglais, et RIEN pour l'allemand, le japonais, le portugais et
/// le turc — quatre des six langues livrées reçoivent de l'anglais. Ce motif
/// était invisible au scan, donc la dette n'était ni comptée ni verrouillée.
final RegExp _namedLiteralPattern = RegExp(
  r"""(?:labelText|hintText|helperText|errorText|semanticsLabel|confirmLabel|"""
  r"""cancelLabel|dialogTitle|tooltip|title|subtitle|description|message|"""
  r"""label|content|fr|en)\s*:\s*(?:const\s+)?['"][^'"\n]*[A-Za-zÀ-ÿ][^'"\n]*['"]""",
  caseSensitive: false,
);

// ─── Exclusions internes du scan ─────────────────────────────────────────────

/// Fichiers/dossiers hors scan.
///
/// Les deux entrées mortes qui figuraient ici (`lib/utils/trad/`,
/// `lib/routes/app/workflows.page.dart`) ne correspondaient à AUCUN chemin :
/// elles ne masquaient rien et laissaient croire que ces dossiers étaient
/// couverts. `lib/l10n/` désignait l'ancien emplacement des localisations
/// GÉNÉRÉES, qui vivent maintenant sous `lib/core/i18n/l10n/` — c'est ce chemin
/// qui doit être exclu, sinon un changement de forme du générateur (un
/// `title: '...'` dans les fichiers produits) ferait remonter des milliers de
/// faux positifs et noierait la vraie dette.
const Set<String> _skipFiles = <String>{
  'lib/core/i18n/l10n/',
};

const List<String> _skipSnippets = <String>[
  r'((${',
  r"'/$path'",
  "'• \$line'",
  r'${entry.locale} (${entry.count})',
  r'$optionsCount',
  r'$actionsCount',
  r'$subcommandCount',
  r'((${item.',
  r'((${suggestion.',
  r'(({item.',
  r'(({suggestion.',
];

bool _shouldSkipFile(String path) {
  return _skipFiles.any((segment) => path.contains(segment));
}

bool _isHardcodedUiLiteralLine(String line) {
  if (_skipSnippets.any(line.contains)) return false;
  return _textLiteralPattern.hasMatch(line) ||
      _namedLiteralPattern.hasMatch(line);
}

// ─── Allow-list documentée ───────────────────────────────────────────────────
//
// Littéraux dont l'absence de traduction est VOLONTAIRE : messages techniques,
// données/payloads et identifiants. Chaque entrée porte sa justification.
// Règle : on n'ajoute ici qu'un littéral qui n'est PAS un libellé d'UI à
// traduire ; une vraie fuite se corrige, ou se déclare dans `knownUiLeaks`.
//
// Une entrée sans `snippetPattern` couvre tout le fichier ; sinon le motif est
// cherché dans la ligne du finding (contenu nettoyé).

/// Entrée d'allow-list : littéraux légitimes dans le fichier correspondant à
/// [pathFragment] (correspondance par `contains` sur le chemin normalisé).
class AllowListEntry {
  const AllowListEntry({
    required this.pathFragment,
    this.snippetPattern,
    required this.reason,
  });

  final String pathFragment;

  /// Source d'expression régulière testée sur la ligne du finding.
  /// `null` = tous les littéraux du fichier sont concernés.
  final String? snippetPattern;

  /// Justification de l'exemption (français, une phrase).
  final String reason;
}

const List<AllowListEntry> allowListedPatterns = <AllowListEntry>[
  // ── Logs / technique : messages internes, jamais des libellés d'UI ──
  AllowListEntry(
    pathFragment: 'lib/core/diagnostics/recovery_manager.dart',
    reason:
        'Résultats internes de l\'auto-backup (AutoBackupRunResult.message), '
        'consommés par la logique et les diagnostics, pas par l\'UI.',
  ),
  AllowListEntry(
    pathFragment: 'lib/main.dart',
    snippetPattern: r"^label: '[^']*',$",
    reason:
        'Labels de _runStartupTask(...) : ils identifient les tâches de '
        'démarrage dans les logs, ils ne sont jamais affichés.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/notifications/logic/notification_service.dart',
    reason:
        'Descriptions de canal de notifications de plateforme (Android) : '
        'hors catalogue ARB, gérées par l\'OS.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/bot_editor/logic/bot.mobile_service.dart',
    snippetPattern: r"^notificationTitle: 'Bots are running',$",
    reason:
        'Titre de la notification de plateforme « bot(s) en cours » — même '
        'classe que les canaux de notification, hors catalogue ARB.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/actions/bot_actions/delete_message.dart',
    reason:
        'Messages d\'erreur du moteur d\'action (résultats d\'exécution des '
        'bots), pas des libellés d\'UI.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/discord_rpc/logic/discord_rpc_client.dart',
    reason: 'Message d\'erreur technique (StateError) du client Discord RPC.',
  ),

  // ── Données / payloads : valeurs stockées, envoyées ou composées ──
  AllowListEntry(
    pathFragment: 'lib/core/storage/drive.dart',
    snippetPattern: r"^label: 'Backup',$",
    reason:
        'Libellé de snapshot stocké dans la donnée de sauvegarde — une '
        'donnée, pas un libellé d\'UI.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/containers/logic/hosted_app_templates.dart',
    reason:
        'Titres des modèles de bots clés en main : contenu/donnée utilisateur.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/screens/bot_sub_pages/builder/'
        'http_request_editor_page.dart',
    snippetPattern: r"^label: '(URL|JSON Body|Text Body)',$",
    reason:
        'Noms des champs techniques de la requête HTTP (URL, corps JSON / '
        'Texte) = valeurs du payload de l\'action.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/marketplace/presentation/marketplace_page.dart',
    snippetPattern: r"^label: '\$\{template\.downloads\}',$",
    reason: 'Compteur de téléchargements interpolé (donnée).',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/marketplace/presentation/marketplace_page.dart',
    snippetPattern: r'context\.tr\.marketplace_connect_manager',
    reason:
        'Snackbar composée d\'une clé DÉJÀ localisée + erreur dynamique : '
        'faux positif du motif, rien à traduire.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/marketplace/presentation/marketplace_detail_page.dart',
    snippetPattern: r"Text\('/\$name'",
    reason:
        'Handle du template (identifiant préfixé « / » affiché en '
        'monospace), pas un libellé.',
  ),
  AllowListEntry(
    pathFragment: 'lib/features/bot_editor/logic/command_variable_catalog.dart',
    reason:
        'Descriptions du catalogue de variables BDFD : documentation '
        'technique des placeholders (données), pas des libellés d\'UI.',
  ),
  AllowListEntry(
    pathFragment: 'lib/core/js_editor/js_editor_snippets.dart',
    reason: 'Noms d\'API JS des snippets de l\'éditeur = identifiants.',
  ),

  // ── Identifiants / nomenclature interne ──
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/widgets/blueprint/'
        'blueprint_layout_engine.dart',
    reason:
        'Vocabulaire interne du graphe blueprint (In/Out/True/Else If/'
        'Completed) : nomenclature du moteur de rendu, pas des libellés.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/widgets/editor_sidebar.dart',
    snippetPattern: r"message: '\$appName",
    reason: 'Tooltip composé du nom + ID du bot (données d\'identité).',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/widgets/scratch_blocks/'
        'metadata_block.dart',
    snippetPattern: r"^label: '\$advancedCount',$",
    reason: 'Badge compteur (nombre d\'options avancées).',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/widgets/scratch_blocks/'
        'metadata_block.dart',
    snippetPattern: r'''^label: '\$\{widget\.options!\.length\}',$''',
    reason: 'Badge compteur (nombre d\'options).',
  ),
  AllowListEntry(
    pathFragment: 'lib/core/widgets/variable_text_field.dart',
    snippetPattern: r"Text\('\$count'",
    reason: 'Badge compteur de caractères interpolé, pas de texte fixe.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/settings/presentation/code_editor_settings_page.dart',
    snippetPattern: r'''^label: '\$\{settings\.fontSize\.toInt\(\)\} px',$''',
    reason: 'Libellé composé valeur + unité (px) du réglage de police.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/containers/presentation/container_detail_page.dart',
    snippetPattern: r"^Text\('(RAM|CPU)',",
    reason: 'Acronymes universels des indicateurs de ressources (RAM/CPU).',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/containers/presentation/registry_credentials_page.dart',
    snippetPattern: r"hintText: 'ghcr\.io'",
    reason: 'Exemple d\'hôte de registre (identifiant technique ghcr.io).',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/widgets/command_create_cards/'
        'basic_info_card.dart',
    snippetPattern: r"hintText: 'p, ping'",
    reason:
        'Exemple de format pour les alias de commande (syntaxe technique : '
        'deux alias séparés par une virgule), pas un libellé d\'UI.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/components_v2/presentation/component_v2_builder/'
        'component_node_editor.dart',
    snippetPattern: r"labelText: 'SKU ID'",
    reason: 'Identifiant technique de champ (SKU ID), pas un libellé.',
  ),
  AllowListEntry(
    pathFragment:
        'lib/features/bot_editor/presentation/screens/bot_sub_pages/settings.dart',
    snippetPattern:
        r"Text\('(Bot Creator \(Dart / blocks\)|JavaScript \(runner-js\))'\)",
    reason:
        'Noms des moteurs d\'exécution (identifiants Dart/JS), stables '
        'entre les locales.',
  ),
  // ── Texte COMPOSÉ depuis une traduction ──────────────────────────────────────
  AllowListEntry(
    // Tous les fichiers : la règle porte sur la FORME de la ligne.
    pathFragment: '',
    snippetPattern: r'\$\{(?:context\.)?tr\.',
    reason:
        'Ligne qui COMPOSE son texte à partir d\'une clé ARB (recherche '
        'context.tr.… ou tr.…, la variable locale de la même chose, interpolée '
        'avec des données) : le littéral n\'est pas de la copie en dur, la partie '
        'traduite est déjà une clé. Toute autre chaîne du fichier reste soumise '
        'à la règle — c\'est pour cela que l\'exemption est un MOTIF et non une '
        'exclusion de fichier.',
  ),
  // ── Littéral SANS TEXTE HUMAIN : uniquement des valeurs interpolées ──────────
  AllowListEntry(
    pathFragment: '',
    // Le contenu du littéral n'est fait que d'interpolations, d'espaces, de
    // chiffres et de ponctuation : il n'y a pas un mot à traduire.
    snippetPattern:
        r"^[^']*'[\s\d(),.:/|*+_\[\]-]*(\$\{[^}]*\}|\$[a-zA-Z_][a-zA-Z0-9_]*)"
        r"[\s\d(),.:/|*+_\[\]-]*'[^']*$",
    reason:
        'Texte 100 % DONNÉE : un compteur, un identifiant ou une longueur '
        'interpolés, sans un seul mot humain — il n\'y a donc rien à traduire. '
        'Un chiffre ou un identifiant s\'affiche tel quel dans toutes les langues.',
  ),
  AllowListEntry(
    pathFragment: '',
    snippetPattern: r"hintText: '\\u",
    reason:
        'Placeholder de champ décoré par un EMOJI (échappement `\\uXXXX`), pas '
        'un libellé.',
  ),
  AllowListEntry(
    pathFragment: '',
    snippetPattern: r"hintText: 'p, ping'",
    reason:
        'Exemple de préfixe affiché tel quel dans le champ (`p, ping`) : c\'est '
        'une DONNÉE d\'exemple — les traduire ferait diverger l\'exemple du '
        'comportement réel du bot.',
  ),
  AllowListEntry(
    pathFragment: '',
    snippetPattern: r"title: 'Bot Creator'",
    reason:
        'NOM DE MARQUE : il ne se traduit pas — le traduire ferait perdre le '
        'produit (et l\'app apparaîtrait sous deux noms selon la langue).',
  ),
  AllowListEntry(
    pathFragment: '',
    snippetPattern: r"label: (?:const )?Text\('(?:Dart|JS|JavaScript|Java|C\+\+)'\)",
    reason:
        'Identifiants de MOTEUR ou de langage (Dart, JS, JavaScript…) : ce sont '
        'des noms propres techniques, identiques dans les 6 langues. Même '
        'logique que l\'entrée équivalente de l\'éditeur de bot.',
  ),
];

/// Dette i18n restante : fichiers contenant encore des libellés d'UI codés en
/// dur (non traduits). Filet TEMPORAIRE — **à vider au fil des corrections** :
/// retirer un fichier dès que ses littéraux sont localisés.
///
/// Le contrôle est par FICHIER (pas par ligne) : tant qu'un fichier est ici,
/// un nouveau littéral dans ce fichier reste toléré. Ne jamais y ajouter une
/// entrée pour faire taire le test : corriger la chaîne. Le test bloquant
/// échoue dès qu'un littéral apparaît hors allow-list ET hors de cet ensemble
/// (fixture, ou fichier inconnu à ce jour).
const Set<String> knownUiLeaks = <String>{
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/image_editor_page.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/command.create.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/commands.list.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/global.variables.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/home.sync.part.dart',
  // Dette rendue VISIBLE par le durcissement du motif (`fr:`/`en:` en plus des
  // paramètres nommés) : ces fichiers portaient du repli français/anglais, donc
  // l'allemand, le japonais, le portugais et le turc affichaient de l'ANGLAIS.
  // Le vrai correctif de `remote_runtime.dart` n'est pas une clé ARB de plus :
  // ces messages naissent dans une couche SANS `BuildContext` (le résolveur rend
  // une `String` que l'UI affiche telle quelle), il faut donc rendre une RAISON
  // typée et laisser l'UI la traduire.
  'lib/core/network/remote_runtime.dart',
  'lib/features/home/presentation/home_page.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/bot_stats.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/home.logic.part.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/settings.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/workflow_block_editor.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_card.dart',
  'lib/features/bot_editor/presentation/screens/bot_sub_pages/builder/http_request_editor_page.dart',
  'lib/features/bot_editor/presentation/screens/bot_config_versions_page.dart',
  'lib/features/bot_editor/presentation/widgets/blueprint/blueprint_context_menu.dart',
  'lib/features/bot_editor/presentation/widgets/blueprint/blueprint_graph_canvas.dart',
  'lib/features/bot_editor/presentation/widgets/blueprint/blueprint_inspector_panel.dart',
  'lib/features/bot_editor/presentation/widgets/option_widget.dart',
  'lib/features/bot_editor/presentation/widgets/scratch_blocks/metadata_block.dart',
  'lib/features/components_v2/presentation/component_v2_builder/component_node_editor.dart',
  'lib/features/components_v2/presentation/component_v2_builder/modal_builder.dart',
  'lib/features/marketplace/presentation/marketplace_detail_page.dart',
  'lib/features/marketplace/presentation/marketplace_page.dart',
  'lib/features/marketplace/presentation/publish_template_page.dart',
  'lib/features/settings/presentation/settings_page.dart',
  'lib/main.dart',
};

// ─── API publique ─────────────────────────────────────────────────────────────

final Map<String, RegExp> _allowSnippetCache = <String, RegExp>{};

/// Vrai si le finding correspond à une entrée de [allowListedPatterns].
bool isAllowListedFinding(HardcodedStringFinding finding) {
  for (final entry in allowListedPatterns) {
    if (!finding.path.contains(entry.pathFragment)) continue;
    final pattern = entry.snippetPattern;
    if (pattern == null) return true;
    final regexp = _allowSnippetCache.putIfAbsent(
      pattern,
      () => RegExp(pattern),
    );
    if (regexp.hasMatch(finding.content)) return true;
  }
  return false;
}

/// Vrai si le fichier figure dans [knownUiLeaks] (dette i18n restante).
bool isKnownUiLeakPath(String path) {
  return knownUiLeaks.any((fragment) => path.contains(fragment));
}

List<HardcodedStringFinding> findHardcodedStringFindings({
  required String rootPath,
  List<File>? filesOverride,
}) {
  final findings = <HardcodedStringFinding>[];

  final files =
      filesOverride ??
      Directory(rootPath)
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList(growable: false);

  for (final file in files) {
    final normalizedPath = file.path.replaceAll('\\', '/');
    if (_shouldSkipFile(normalizedPath)) continue;

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (!_isHardcodedUiLiteralLine(line)) continue;
      findings.add(
        HardcodedStringFinding(
          path: normalizedPath,
          line: i + 1,
          content: line.trim(),
        ),
      );
    }
  }

  return findings;
}
