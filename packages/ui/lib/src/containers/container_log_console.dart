import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../utils/poll_cadence.dart';
import '../widgets/app_icon.dart';

// ─── Console de logs ────────────────────────────────────────────────────────

/// Sévérité d'une ligne de log.
///
/// Elle ne sert qu'à hiérarchiser la LECTURE : couleur du texte, et pour les
/// alertes un liseré + un fond à peine teinté. Aucun cadre ni badge n'est ajouté
/// par ligne — c'est justement l'empilement de cadres et de sur-titres qui
/// rendait la console illisible.
enum ContainerLogSeverity { debug, info, warn, error }

/// Largeur de la colonne des horodatages : de quoi tenir « 23:59:59 » en 11 px.
const double _logTimeColumnWidth = 58;

/// Interlignage des lignes : confortable (≈ 18 px de ligne) sans diluer.
const double _logLineHeight = 1.45;
const double _logFontSize = 12.5;
const double _logTimeFontSize = 11;

/// Marqueur de niveau, dans les formes les plus répandues : `ERROR`, `[ERROR]`,
/// `error:`, `INFO -`, `SEVERE`, et `12:00:00 - DEBUG message` (séparateur avant
/// le niveau, comme le fait logback).
final RegExp _logLevelToken = RegExp(
  r'^\[?\s*[-–:|]?\s*(TRACE|VERBOSE|DEBUG|DBG|FINE|INFO|NOTICE|LOG|WARN|WARNING|ERROR|ERR|SEVERE|FATAL|CRITICAL|PANIC)\b[\]\:\-\s]*',
  caseSensitive: false,
);

/// Niveau écrit dans le corps de la ligne : `level=error`, `"level":"error"`.
final RegExp _logInlineLevel = RegExp(
  r'"?level"?\s*[=:]\s*"?([A-Za-z]+)',
  caseSensitive: false,
);

/// Horodatage en tête de ligne : ISO 8601 (`2026-09-19T12:34:56.789Z`),
/// `2026-09-19 12:34:56`, `[12:34:56]`, `12:34:56,789`, et la forme
/// `time=12:34:56` des runtimes qui étiquettent en `clé=valeur`. Le groupe 1 est
/// l'heure seule : c'est elle qu'on affiche, la date alourdirait chaque ligne
/// pour un tampon qui ne couvre que les derniers logs.
final RegExp _logTimestamp = RegExp(
  r'^\[?\s*(?:(?:time|ts|timestamp)\s*[=:]\s*)?(?:\d{4}-\d{2}-\d{2}[T ])?(\d{2}:\d{2}:\d{2})(?:[.,]\d{1,6})?(?:Z|[+-]\d{2}:?\d{2})?\s*\]?\s*',
);

/// Signaux d'alerte cherchés dans le message quand le bot n'étiquette pas ses
/// lignes : c'est ce repli qui fait ressortir une erreur sur une image qui se
/// contente d'écrire sur sa sortie standard.
final RegExp _logErrorSignal = RegExp(
  r'\b(error|erreur|exception|traceback|fatal|panic|crash|err!|refused|eacces|econnrefused)\b',
  caseSensitive: false,
);
final RegExp _logWarnSignal = RegExp(
  r'\b(warn|warning|avertissement|deprecated|timeout|timed out|retry\w*)\b',
  caseSensitive: false,
);

/// Débuts typiques d'une ligne rattachée à la précédente (trace d'exception,
/// message multiligne) : elles sont alors alignées sur la colonne du message,
/// pour ne pas laisser croire à un nouvel événement.
final RegExp _logTracePrefix = RegExp(
  r'^(\s|at |File "|Caused by|During handling|\.{3} \d+ more|Traceback)',
);

/// Séquences ANSI : un tampon de conteneur peut en contenir, et elles se
/// liraient comme des saletés au milieu du message.
final RegExp _logAnsi = RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]');

/// Une ligne de log analysée.
///
/// L'horodatage et le niveau sont sortis du texte pour deux raisons : la colonne
/// des heures reste alignée d'une ligne à l'autre (l'œil peut la sauter), et le
/// niveau devient une couleur au lieu d'un motif répété.
class ContainerLogLine {
  const ContainerLogLine({
    required this.raw,
    required this.time,
    required this.level,
    required this.message,
    required this.severity,
    required this.isContinuation,
  });

  /// Ligne d'origine, ANSI retiré.
  final String raw;

  /// Heure nue (« 12:34:56 »), vide quand la ligne n'en porte pas.
  final String time;

  /// Niveau nu et en majuscules (« ERROR »), vide quand la ligne n'en porte pas.
  final String level;

  /// Message débarrassé de l'horodatage et du niveau.
  final String message;

  /// Sévérité : niveau explicite s'il existe, contenu sinon.
  final ContainerLogSeverity severity;

  /// Vraie pour une ligne rattachée à la précédente (trace, continuation).
  final bool isContinuation;

  /// Texte à rendre : le message si l'analyse en a extrait un, sinon la ligne
  /// brute — une ligne réduite à un horodatage ne doit pas disparaître.
  String get displayMessage => message.trim().isEmpty ? raw.trim() : message;
}

/// Analyse un tampon de logs : une entrée par ligne non vide, horodatage et
/// niveau sortis du texte.
///
/// La sévérité d'une ligne de continuation suit celle de sa ligne d'en-tête :
/// une trace d'exception hérite donc de la couleur de son `Error:`, ce qui donne
/// un bloc repérable au lieu de lignes indépendantes.
List<ContainerLogLine> parseContainerLogLines(String raw) {
  final parsed = <ContainerLogLine>[];
  for (final rawLine in raw.split('\n')) {
    // Une ligne vide n'apprend rien et gonfle le défilement : on la saute.
    if (rawLine.trim().isEmpty) continue;
    final previous = parsed.isEmpty
        ? ContainerLogSeverity.info
        : parsed.last.severity;
    // Une trace hérite du rouge/orange de son en-tête ; sinon c'est du bruit
    // (trace d'un log normal), donc atténué.
    final inherited =
        previous == ContainerLogSeverity.error ||
            previous == ContainerLogSeverity.warn
        ? previous
        : ContainerLogSeverity.debug;
    parsed.add(_parseContainerLogLine(rawLine, inherited: inherited));
  }
  return parsed;
}

ContainerLogLine _parseContainerLogLine(
  String raw, {
  ContainerLogSeverity inherited = ContainerLogSeverity.info,
}) {
  final cleaned = raw.replaceAll(_logAnsi, '');
  var rest = cleaned;

  final timeMatch = _logTimestamp.firstMatch(rest);
  final time = timeMatch?.group(1) ?? '';
  if (timeMatch != null) {
    rest = rest.substring(timeMatch.end);
  }

  var level = '';
  final levelMatch = _logLevelToken.firstMatch(rest);
  if (levelMatch != null) {
    level = levelMatch.group(1)!.toUpperCase();
    rest = rest.substring(levelMatch.end);
  } else {
    final inlineLevel = _logInlineLevel.firstMatch(rest);
    if (inlineLevel != null) level = inlineLevel.group(1)!.toUpperCase();
  }

  final message = rest.trimLeft();
  final isContinuation =
      time.isEmpty && level.isEmpty && _logTracePrefix.hasMatch(cleaned);
  return ContainerLogLine(
    raw: cleaned,
    time: time,
    level: level,
    message: message,
    severity: isContinuation ? inherited : _logSeverity(level, message),
    isContinuation: isContinuation,
  );
}

/// Sévérité d'une ligne : le niveau explicite prime, sinon le contenu décide.
ContainerLogSeverity _logSeverity(String level, String message) {
  switch (level) {
    case 'TRACE':
    case 'VERBOSE':
    case 'DEBUG':
    case 'DBG':
    case 'FINE':
      return ContainerLogSeverity.debug;
    case 'WARN':
    case 'WARNING':
      return ContainerLogSeverity.warn;
    case 'ERROR':
    case 'ERR':
    case 'SEVERE':
    case 'FATAL':
    case 'CRITICAL':
    case 'PANIC':
      return ContainerLogSeverity.error;
    case 'INFO':
    case 'NOTICE':
    case 'LOG':
      return ContainerLogSeverity.info;
  }
  if (_logErrorSignal.hasMatch(message)) return ContainerLogSeverity.error;
  if (_logWarnSignal.hasMatch(message)) return ContainerLogSeverity.warn;
  return ContainerLogSeverity.info;
}

/// Console de logs d'un conteneur (bot clé en main / app hébergée).
///
/// Même rendu pour les DEUX portes d'entrée — le pavé « console » de la page de
/// détail et l'écran de logs ouvert depuis la carte d'accueil : une seule mise
/// en page, donc plus de divergence entre les deux écrans.
///
/// Une ligne = un horodatage discret aligné en colonne + un message monospace.
/// La sévérité passe par la couleur (et un liseré pour les alertes) et non par
/// des cadres empilés. Le bandeau du haut résume le tampon (nombre d'erreurs) et
/// permet de le copier d'un geste.
class ContainerLogsViewer extends StatefulWidget {
  /// Lit le tampon texte des derniers logs (l'hôte le tire de `GET
  /// /containers/{id}/logs`). Appelée à chaque tick du sondage.
  final Future<String> Function() loadLogs;
  final String containerId;

  const ContainerLogsViewer({
    super.key,
    required this.loadLogs,
    required this.containerId,
  });

  @override
  State<ContainerLogsViewer> createState() => _ContainerLogsViewerState();
}

class _ContainerLogsViewerState extends State<ContainerLogsViewer> {
  final _scrollCtrl = ScrollController();
  String _logs = '';

  /// Tampon analysé une fois par tick : le défilement ne relance pas l'analyse.
  List<ContainerLogLine> _lines = const <ContainerLogLine>[];
  bool _loading = true;
  String? _error;
  Timer? _pollTimer;

  /// Cadence du sondage des logs d'app hébergée : un panneau laissé ouvert sur une app
  /// calme ne doit pas générer 12 requêtes par minute. Le plafond est plus haut que le
  /// défaut (15 s) : c'est un encart de consultation, pas l'écran principal.
  final PollCadence _logsCadence = PollCadence(
    nominal: const Duration(seconds: 5),
    ceiling: const Duration(seconds: 15),
  );

  @override
  void initState() {
    super.initState();
    // Premier chargement immédiat, puis sondage réarmé selon la cadence adaptative
    // (voir `_refreshLogs`) : plus de `Timer.periodic` fixe de 5 s.
    unawaited(_refreshLogs());
  }

  /// Un tick : charge les logs, enregistre le résultat dans la cadence et réarme le
  /// prochain tick. C'est ce réarmement, et non un `Timer.periodic`, qui espace les
  /// requêtes tant que le contenu ne change pas.
  Future<void> _refreshLogs({bool silent = false}) async {
    final outcome = await _loadLogs(silent: silent);
    _logsCadence.consume(outcome);
    // Réarmer une minuterie alors que le widget est démonté laisse « A Timer is still
    // pending even after the widget tree was disposed ».
    if (!mounted) {
      return;
    }
    _pollTimer?.cancel();
    _pollTimer = Timer(
      _logsCadence.current,
      () => unawaited(_refreshLogs(silent: true)),
    );
  }

  Future<TickOutcome> _loadLogs({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final logs = await widget.loadLogs();
      if (!mounted) return TickOutcome.unchanged;
      // Comparaison faite sur la chaîne déjà en mémoire (le contrat de l'endpoint est un
      // tampon texte) : le changement se détecte sans requête supplémentaire.
      final changed = logs != _logs;
      // Analyse faite ici, une fois par tick : le rendu se contente de lire.
      final lines = parseContainerLogLines(logs);
      setState(() {
        _logs = logs;
        _lines = lines;
        _loading = false;
        _error = null;
      });
      _scrollToBottom();
      return changed ? TickOutcome.changed : TickOutcome.unchanged;
    } catch (e) {
      if (!mounted) return TickOutcome.unchanged;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
      // Un endpoint en échec ne doit pas être martelé : le compter comme inchangé espace
      // le sondage, ce qui sert de repli progressif jusqu'au rétablissement.
      return TickOutcome.unchanged;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  /// Copie le tampon BRUT (horodatages et niveaux d'origine compris) : c'est ce
  /// qu'on colle dans un ticket, pas la version mise en page par l'app.
  Future<void> _copyLogs() async {
    await Clipboard.setData(ClipboardData(text: _logs));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.bot_logs_copied)));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _logs.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null && _logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.tr.container_detail_failed(_error!),
            style: const TextStyle(fontSize: 12, color: AppTheme.errorLight),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_lines.isEmpty) {
      // Un tampon vide n'est pas une panne : on le dit calmement, sans encadré.
      return Center(
        child: Text(
          context.tr.bot_logs_empty,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // Seules les lignes d'en-tête comptent : une trace de dix lignes ne doit pas
    // s'afficher comme dix erreurs.
    final errorCount = _lines
        .where(
          (line) =>
              line.severity == ContainerLogSeverity.error &&
              !line.isContinuation,
        )
        .length;
    // La colonne des horodatages n'est réservée que si le tampon en porte : sur
    // téléphone, 58 px gaspillés par ligne coûteraient un tiers du message.
    final showTime = _lines.any((line) => line.time.isNotEmpty);

    return Column(
      children: [
        _LogConsoleHeaderStrip(errorCount: errorCount, onCopy: _copyLogs),
        Expanded(
          // `SelectionArea` conserve le copier-coller du contenu, comme le
          // `SelectableText` d'avant, mais ligne par ligne.
          child: SelectionArea(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _lines.length,
              itemBuilder: (context, index) => ContainerLogRow(
                key: ValueKey<String>('container-log-$index'),
                line: _lines[index],
                showTime: showTime,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Une ligne de la console.
///
/// Hiérarchie voulue : l'horodatage est une colonne discrète et alignée, le
/// message est en monospace avec un interlignage confortable, et la sévérité ne
/// coûte AUCUN cadre — seulement une couleur, plus un liseré et un fond à peine
/// teinté pour les alertes.
class ContainerLogRow extends StatelessWidget {
  const ContainerLogRow({super.key, required this.line, this.showTime = true});

  /// Clés stables des deux colonnes, utilisées par les tests de mise en page.
  static const Key timeKey = Key('container-log-time');
  static const Key messageKey = Key('container-log-message');

  final ContainerLogLine line;

  /// Vrai quand le tampon porte des horodatages : sinon la colonne est omise.
  final bool showTime;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = _logAccentColor(line.severity);
    return Container(
      decoration: BoxDecoration(
        color: _logBackgroundTint(line.severity),
        border: accent == null
            ? null
            : Border(left: BorderSide(color: accent, width: 2)),
      ),
      padding: EdgeInsets.only(
        left: line.isContinuation ? 18 : 8,
        right: 10,
        top: 1,
        bottom: 1,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTime)
            SizedBox(
              width: _logTimeColumnWidth,
              child: line.time.isEmpty
                  ? null
                  : Text(
                      line.time,
                      key: timeKey,
                      maxLines: 1,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: _logTimeFontSize,
                        height: _logLineHeight,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
            ),
          Expanded(
            child: Text(
              line.displayMessage,
              key: messageKey,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: _logFontSize,
                height: _logLineHeight,
                color: _logTextColor(line.severity, scheme),
                fontWeight: line.severity == ContainerLogSeverity.error
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'état de la console : le nombre d'erreurs du tampon (pour savoir
/// qu'il y en a sans dérouler les 200 lignes) et la copie du tampon brut.
///
/// Volontairement réduit à une ligne, sans titre : l'écran porte déjà son titre,
/// le répéter ici était du chrome en trop.
class _LogConsoleHeaderStrip extends StatelessWidget {
  const _LogConsoleHeaderStrip({
    required this.errorCount,
    required this.onCopy,
  });

  final int errorCount;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasErrors = errorCount > 0;
    final color = hasErrors ? AppTheme.errorLight : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          AppIcon.fromMaterial(
            hasErrors
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              context.tr.container_logs_errors_count(errorCount),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          IconButton(
            onPressed: onCopy,
            tooltip: context.tr.copy,
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            icon: const AppIcon.fromMaterial(Icons.copy_rounded),
          ),
        ],
      ),
    );
  }
}

/// Couleur du texte : c'est elle qui porte le niveau, sans badge répété.
Color _logTextColor(ContainerLogSeverity severity, ColorScheme scheme) {
  switch (severity) {
    case ContainerLogSeverity.debug:
      return scheme.onSurfaceVariant.withValues(alpha: 0.5);
    case ContainerLogSeverity.warn:
      return AppTheme.warning;
    case ContainerLogSeverity.error:
      return AppTheme.errorLight;
    case ContainerLogSeverity.info:
      return scheme.onSurface.withValues(alpha: 0.92);
  }
}

/// Liseré des alertes et des erreurs : un repère vertical qu'on suit du coin de
/// l'œil en défilant, sans bordure autour de chaque ligne.
Color? _logAccentColor(ContainerLogSeverity severity) {
  switch (severity) {
    case ContainerLogSeverity.warn:
      return AppTheme.warning;
    case ContainerLogSeverity.error:
      return AppTheme.errorLight;
    case ContainerLogSeverity.debug:
    case ContainerLogSeverity.info:
      return null;
  }
}

/// Fond à peine teinté : assez pour détacher un bloc d'erreur, trop peu pour
/// transformer la console en damier.
Color? _logBackgroundTint(ContainerLogSeverity severity) {
  switch (severity) {
    case ContainerLogSeverity.warn:
      return AppTheme.warning.withValues(alpha: 0.07);
    case ContainerLogSeverity.error:
      return AppTheme.error.withValues(alpha: 0.10);
    case ContainerLogSeverity.debug:
    case ContainerLogSeverity.info:
      return null;
  }
}
