import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:reicon_flutter/reicon_flutter.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'copilot_markdown.dart';
import 'copilot_section.dart';

/// Texte français ou anglais selon la langue courante (les libellés du
/// Copilote qui n'ont pas de clé de traduction).
String copilotCopy(BuildContext context, String french, String english) =>
    Localizations.localeOf(context).languageCode == 'fr' ? french : english;

/// Une discussion de l'historique.
class CopilotChatSummary {
  const CopilotChatSummary({required this.id, required this.title});

  final String id;
  final String title;
}

/// En-tête du Copilote : le bot (ou « discussion globale »), le titre de la
/// discussion et où s'exécutent les outils.
class CopilotContextHeader extends StatelessWidget {
  const CopilotContextHeader({
    super.key,
    required this.botName,
    required this.title,
    this.isBot = true,
    this.local = false,
    this.cloudRunning,
  });

  /// Nom du bot ; ignoré quand [isBot] est faux (discussion globale).
  final String botName;
  final String? title;
  final bool isBot;

  /// Les outils s'exécutent sur l'appareil (app) plutôt que sur le serveur.
  final bool local;

  /// État du bot hébergé (`null` : inconnu).
  final bool? cloudRunning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = isBot ? botName : context.tr.copilot_global_discussion;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.homeCard,
              border: Border.all(color: AppTheme.homeCardBorder),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: AppIcon(
                isBot ? Reicon.outline.cpu : Reicon.outline.magicStar,
                color: AppTheme.actionVioletSoft,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title ?? context.tr.copilot_new_discussion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isBot) _location(context, colors),
        ],
      ),
    );
  }

  Widget _location(BuildContext context, ColorScheme colors) {
    final live = !local && cloudRunning == true;
    final tint = live ? AppTheme.statusOnline : colors.onSurfaceVariant;
    final label = local
        ? context.tr.copilot_location_local
        : cloudRunning == false
        ? '${context.tr.copilot_location_remote} · ${copilotCopy(context, 'arrêté', 'stopped')}'
        : cloudRunning == true
        ? '${context.tr.copilot_location_remote} · ${copilotCopy(context, 'actif', 'running')}'
        : context.tr.copilot_location_remote;
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: live ? .1 : .08),
        border: Border.all(color: tint.withValues(alpha: live ? .25 : .18)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: tint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau du solde de crédits IA (mobile).
class CopilotWalletStrip extends StatelessWidget {
  const CopilotWalletStrip({
    super.key,
    required this.available,
    this.reserved,
    required this.onOpenCredits,
  });

  /// Montants déjà formatés (crédits).
  final String available;
  final String? reserved;
  final VoidCallback onOpenCredits;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppTheme.homeCard,
          border: Border.all(color: AppTheme.homeCardBorder),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.actionViolet.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: AppIcon(
                  Reicon.outline.coin,
                  size: 20,
                  color: AppTheme.actionVioletSoft,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 140),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            available,
                            softWrap: false,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          copilotCopy(context, 'crédits IA', 'AI credits'),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                  if (reserved != null)
                    Text(
                      copilotCopy(
                        context,
                        '$reserved en cours d’utilisation',
                        '$reserved being used right now',
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              tooltip: context.tr.copilot_action_credits,
              onPressed: onOpenCredits,
              icon: AppIcon(
                Reicon.outline.arrowRight,
                size: 18,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Colonne des discussions (desktop) : recherche, liste, « charger plus ».
class CopilotDiscussionsPane extends StatelessWidget {
  const CopilotDiscussionsPane({
    super.key,
    required this.search,
    required this.history,
    required this.selectedId,
    required this.busy,
    required this.hasMore,
    required this.onOpen,
    required this.onSearch,
    required this.onLoadMore,
  });

  final TextEditingController search;
  final List<CopilotChatSummary> history;
  final String? selectedId;
  final bool busy;
  final bool hasMore;
  final ValueChanged<String> onOpen;
  final VoidCallback onSearch;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            controller: search,
            decoration: InputDecoration(
              isDense: true,
              hintText: context.tr.copilot_search_title_hint,
              prefixIcon: const AppIcon.fromMaterial(
                Icons.search_rounded,
                size: 18,
              ),
            ),
            onSubmitted: (_) => onSearch(),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              if (history.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    context.tr.copilot_no_conversations,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              for (final c in history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ListTile(
                    dense: true,
                    minTileHeight: 44,
                    selected: selectedId == c.id,
                    selectedTileColor: AppTheme.homeNavSelected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: busy ? null : () => onOpen(c.id),
                  ),
                ),
              if (hasMore)
                TextButton(
                  onPressed: onLoadMore,
                  child: Text(context.tr.copilot_load_more),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Panneau latéral desktop : crédits et capacités.
class CopilotSidePanel extends StatelessWidget {
  const CopilotSidePanel({
    super.key,
    required this.available,
    this.consumedInDiscussion,
    required this.onOpenCredits,
    required this.botLabel,
    required this.tools,
    this.onConnection,
  });

  /// Crédits disponibles, formatés (`null` : solde inconnu).
  final String? available;

  /// Crédits consommés par la discussion ouverte, formatés.
  final String? consumedInDiscussion;
  final VoidCallback onOpenCredits;
  final String botLabel;
  final Iterable<String> tools;

  /// Connexion MCP (app desktop) ; absent : pas de bouton.
  final VoidCallback? onConnection;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final muted = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant);
    return ListView(
      children: [
        CopilotSection(
          title: copilotCopy(context, 'Crédits IA', 'AI credits'),
          child: available == null
              ? Text('—', style: muted)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          AppIcon(
                            Reicon.outline.coin,
                            size: 16,
                            color: AppTheme.actionVioletSoft,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr.copilot_available,
                              style: muted,
                            ),
                          ),
                          Text(
                            available!,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (consumedInDiscussion != null)
                      Text(
                        context.tr.copilot_credits_in_discussion(
                          consumedInDiscussion!,
                        ),
                        style: muted,
                      ),
                    TextButton(
                      onPressed: onOpenCredits,
                      child: Text(context.tr.copilot_action_credits),
                    ),
                  ],
                ),
        ),
        CopilotSection(
          title: copilotCopy(context, 'Capacités', 'Capabilities'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(botLabel, style: muted),
              const SizedBox(height: 8),
              for (final tool in tools)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      AppIcon.fromMaterial(
                        Icons.check_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(tool, style: muted)),
                    ],
                  ),
                ),
              if (onConnection != null)
                TextButton(
                  onPressed: onConnection,
                  child: Text(context.tr.copilot_action_mcp_connection),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Écran d'accueil d'une discussion vide : suggestions et dernières discussions.
class CopilotWelcome extends StatelessWidget {
  const CopilotWelcome({
    super.key,
    required this.ready,
    required this.history,
    required this.onSuggestion,
    required this.onOpen,
  });

  final bool ready;
  final List<CopilotChatSummary> history;
  final ValueChanged<String> onSuggestion;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.copilot_welcome_title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.tr.copilot_welcome_subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 22),
          for (final suggestion in [
            (
              Reicon.outline.search,
              context.tr.copilot_suggestion_check_title,
              context.tr.copilot_suggestion_check_prompt,
            ),
            (
              Reicon.outline.code,
              context.tr.copilot_suggestion_command_title,
              context.tr.copilot_suggestion_command_prompt,
            ),
            (
              Reicon.outline.lightbulb,
              context.tr.copilot_suggestion_feature_title,
              context.tr.copilot_suggestion_feature_prompt,
            ),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: !ready ? null : () => onSuggestion(suggestion.$3),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        AppIcon(suggestion.$1, size: 19, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion.$2,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        AppIcon(
                          Reicon.outline.arrowUpRight,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (history.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              context.tr.copilot_history_section_title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            for (final c in history.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: AppIcon(
                  Reicon.outline.chatRound,
                  size: 19,
                  color: colors.onSurfaceVariant,
                ),
                title: Text(
                  c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: AppIcon(Reicon.outline.arrowRight2, size: 18),
                onTap: () => onOpen(c.id),
              ),
          ],
        ],
      ),
    );
  }
}

/// Un message de la discussion (bulle utilisateur ou réponse en Markdown).
class CopilotMessageBubble extends StatelessWidget {
  const CopilotMessageBubble({
    super.key,
    required this.content,
    required this.user,
    this.streaming = false,
    this.credits,
  });

  final String content;
  final bool user;
  final bool streaming;

  /// Crédits de la réponse, formatés (`null` : rien à afficher).
  final String? credits;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: user ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: user ? MediaQuery.sizeOf(context).width * .82 : 850,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.symmetric(
          horizontal: user ? 12 : 2,
          vertical: user ? 8 : 2,
        ),
        decoration: BoxDecoration(
          // Bulle utilisateur neutre : fond relevé, bordure fine, pas de teinte.
          color: user ? AppTheme.homeCard : Colors.transparent,
          border: user ? Border.all(color: AppTheme.homeGhostBorder) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(user ? 16 : 4),
            bottomRight: Radius.circular(user ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!user) ...[
                  AppIcon(
                    Reicon.outline.magicStar,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 7),
                ],
                Expanded(
                  child: Text(
                    user
                        ? context.tr.copilot_role_you
                        : context.tr.copilot_role_assistant,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: user ? colors.onSurfaceVariant : colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (streaming)
                  Text(
                    context.tr.copilot_generating,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                else
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: context.tr.copilot_copy_message,
                    icon: AppIcon(
                      Reicon.outline.copy,
                      size: 14,
                      color: colors.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: content)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            CopilotMarkdown(content: content),
            if (!user && !streaming && credits != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(
                      Reicon.outline.coin,
                      size: 14,
                      color: AppTheme.actionVioletSoft,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      copilotCopy(
                        context,
                        '$credits crédits',
                        '$credits credits',
                      ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Zone de saisie : solde restant, champ et bouton d'envoi.
class CopilotComposer extends StatelessWidget {
  const CopilotComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.onSend,
    this.focusNode,
    this.availableCredits,
    this.retryPending = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool canSend;
  final VoidCallback onSend;

  /// Crédits restants, formatés (`null` : rien à afficher).
  final String? availableCredits;

  /// Une demande a échoué : le bouton la relance au lieu d'en envoyer une.
  final bool retryPending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant.withValues(alpha: .4)),
        ),
      ),
      child: Column(
        children: [
          if (availableCredits != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Row(
                children: [
                  AppIcon(
                    Reicon.outline.coin,
                    size: 14,
                    color: AppTheme.actionVioletSoft,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: availableCredits,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: copilotCopy(
                              context,
                              ' crédits restants',
                              ' credits left',
                            ),
                          ),
                        ],
                      ),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 4, 6, 4),
            decoration: BoxDecoration(
              color: AppTheme.homeCard,
              border: Border.all(color: AppTheme.homeClusterBorder),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 5,
                    enabled: enabled,
                    decoration: InputDecoration(
                      hintText: context.tr.copilot_input_hint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.actionViolet,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.homeGhostBorder,
                    minimumSize: const Size(44, 44),
                    fixedSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                  ),
                  tooltip: retryPending
                      ? copilotCopy(
                          context,
                          'Réessayer la demande en attente',
                          'Retry pending request',
                        )
                      : context.tr.copilot_send,
                  onPressed: canSend ? onSend : null,
                  icon: Transform.translate(
                    offset: retryPending
                        ? Offset.zero
                        : const Offset(1.5, -0.5),
                    child: AppIcon.fromMaterial(
                      retryPending ? Icons.replay_rounded : Icons.send,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libellé traduit d'un outil du Copilote (les lectures non listées se
/// présentent comme « inspecter le bot »).
String copilotToolLabel(BuildContext context, String name) {
  final tr = context.tr;
  return switch (name) {
    'remote_start_bot' || 'local_start_bot' => tr.copilot_tool_start_bot,
    'remote_stop_bot' || 'local_stop_bot' => tr.copilot_tool_stop_bot,
    'local_create_command' => tr.copilot_tool_create_command,
    'local_update_command_execution' => tr.copilot_tool_update_command,
    'library_search' || 'library_get' => tr.copilot_tool_library_search,
    'local_create_command_from_library' => tr.copilot_tool_create_from_library,
    'local_patch_command_execution' => tr.copilot_tool_patch_command,
    'local_update_command_options' => tr.copilot_tool_options,
    'local_update_command_settings' => tr.copilot_tool_settings,
    'local_create_workflow' => tr.copilot_tool_create_workflow,
    'local_update_workflow' => tr.copilot_tool_update_workflow,
    'local_update_bot_presence' => tr.copilot_tool_presence,
    'local_update_bot_profile' => tr.copilot_tool_profile,
    'local_set_variable' => tr.copilot_tool_variable,
    'local_update_scheduled_trigger' => tr.copilot_tool_schedule,
    'local_update_inbound_webhook' => tr.copilot_tool_webhook,
    'docs_search' || 'docs_get' => tr.copilot_tool_read_docs,
    _ => tr.copilot_tool_inspect_bot,
  };
}
