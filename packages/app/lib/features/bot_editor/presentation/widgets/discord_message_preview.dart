import 'package:flutter/material.dart';

import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

/// A compact Discord-style message bubble that renders a live preview of what
/// the bot's response will look like.
///
/// Used inside the action editor for message-producing actions
/// (respondWithMessage, sendMessage, sendDm) so the user can see their
/// text formatted in a Discord chat bubble as they type.
///
/// S4 — Live Preview (UX-INSPECTION.md)
class DiscordMessagePreview extends StatelessWidget {
  const DiscordMessagePreview({
    super.key,
    required this.content,
    this.botName = 'Bot',
    this.ephemeral = false,
    this.embeds = const [],
    this.components,
  });

  /// The raw message content text (may contain ((placeholders))).
  final String content;

  /// Display name shown for the bot in the preview header.
  final String botName;

  /// Whether this is an ephemeral message (only visible to the command author).
  final bool ephemeral;

  /// Embeds attached to the message. Each embed map may contain 'title',
  /// 'description', 'color', 'fields', 'footer', etc.
  final List<Map<String, dynamic>> embeds;

  /// Normal message components (action rows with buttons/selects).
  final Map<String, dynamic>? components;

  @override
  Widget build(BuildContext context) {
    final hasContent = content.trim().isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.discordDarkerBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.discordBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Preview header bar ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: AppTheme.discordDarkBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusSm),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: AppTheme.discordText.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr.live_preview_label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.discordText.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (ephemeral)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Text(
                      context.tr.live_preview_ephemeral_tag,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.warning,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Message bubble ──
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bot avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.discord,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bot name + timestamp
                      Row(
                        children: [
                          Text(
                            botName,
                            style: const TextStyle(
                              color: AppTheme.discord,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.tr.live_preview_today,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.discordText.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      // Content
                      if (hasContent)
                        _buildContentText(content.trim())
                      else
                        Text(
                          context.tr.live_preview_empty,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.discordText.withValues(alpha: 0.4),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      // ── Embeds ──
                      if (embeds.isNotEmpty) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        ...embeds.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _buildEmbedPreview(e),
                        )),
                      ],
                      // ── Buttons ──
                      if (_hasButtons) ...[
                        const SizedBox(height: AppTheme.spacingSm),
                        _buildButtonsPreview(),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Embed & Button helpers ─────────────────────────────────────────────────

  bool get _hasButtons {
    final comps = components;
    if (comps == null) return false;
    final list = comps['components'];
    if (list is! List || list.isEmpty) return false;
    for (final row in list) {
      if (row is! Map) continue;
      final btns = row['components'];
      if (btns is List && btns.isNotEmpty) return true;
    }
    return false;
  }

  Widget _buildEmbedPreview(Map<String, dynamic> embed) {
    final title = (embed['title'] ?? '').toString().trim();
    final description = (embed['description'] ?? '').toString().trim();
    final colorStr = (embed['color'] ?? '').toString().trim();
    final color = _parseEmbedColor(colorStr);
    final fields = embed['fields'] as List<dynamic>?;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.discordDarkBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border(
          left: BorderSide(
            color: color ?? AppTheme.brandPrimary,
            width: 4,
          ),
        ),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (description.isNotEmpty) ...[
            if (title.isNotEmpty) const SizedBox(height: 4),
            _buildContentText(description),
          ],
          if (fields != null && fields.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: fields.whereType<Map>().map((f) {
                final fName = (f['name'] ?? '').toString();
                final fValue = (f['value'] ?? '').toString();
                return SizedBox(
                  width: 140,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        fValue,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.discordText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Color? _parseEmbedColor(String colorStr) {
    if (colorStr.isEmpty) return null;
    // Accept hex colors like "#1abc9c" or decimal strings like "16777215"
    final hex = colorStr.replaceFirst('#', '');
    final parsed = int.tryParse(hex, radix: 16);
    if (parsed != null) return Color(parsed | 0xFF000000);
    return null;
  }

  Widget _buildButtonsPreview() {
    final comps = components!;
    final list = comps['components'] as List<dynamic>;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: list.whereType<Map>().expand((row) {
        final btns = row['components'] as List<dynamic>? ?? [];
        return btns.whereType<Map>().map((btn) {
          final label = (btn['label'] ?? '').toString();
          final style = (btn['style'] ?? 1) as int;
          final isLink = style == 5;
          final isPrimary = style == 1;
          final isSuccess = style == 3;
          final isDanger = style == 4;
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: isLink
                  ? Colors.transparent
                  : isPrimary
                      ? AppTheme.discord
                      : isSuccess
                          ? const Color(0xFF3BA55D)
                          : isDanger
                              ? const Color(0xFFED4245)
                              : const Color(0xFF4F545C),
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
            ),
            child: Text(
              label.isEmpty ? 'Button' : label,
              style: TextStyle(
                color: isLink ? AppTheme.discordLight : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildContentText(String text) {
    return RichText(
      text: _parseContent(text),
      textAlign: TextAlign.left,
    );
  }

  TextSpan _parseContent(String text) {
    final children = <InlineSpan>[];
    // Pattern matches: **bold**, *italic*, `code`, ((placeholder))
    final pattern = RegExp(
      r'\*\*(.+?)\*\*'      // **bold**
      r'|\*(.+?)\*'          // *italic*
      r'|`(.+?)`'            // `code`
      r'|\(\((.+?)\)\)',     // ((placeholder))
    );

    var lastEnd = 0;
    for (final match in pattern.allMatches(text)) {
      // Add plain text before this match
      if (match.start > lastEnd) {
        children.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: const TextStyle(
              color: AppTheme.discordText,
              fontSize: 14,
            ),
          ),
        );
      }

      if (match.group(1) != null) {
        // Bold
        children.add(TextSpan(
          text: match.group(1),
          style: const TextStyle(
            color: AppTheme.discordText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ));
      } else if (match.group(2) != null) {
        // Italic
        children.add(TextSpan(
          text: match.group(2),
          style: const TextStyle(
            color: AppTheme.discordText,
            fontSize: 14,
            fontStyle: FontStyle.italic,
          ),
        ));
      } else if (match.group(3) != null) {
        // Inline code
        children.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            color: AppTheme.discordText,
            fontSize: 13,
            fontFamily: 'monospace',
            backgroundColor: AppTheme.discordBorder.withValues(alpha: 0.5),
          ),
        ));
      } else if (match.group(4) != null) {
        // ((placeholder))
        children.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            color: AppTheme.brandSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            backgroundColor: AppTheme.brandSecondary.withValues(alpha: 0.12),
          ),
        ));
      }

      lastEnd = match.end;
    }

    // Remaining plain text
    if (lastEnd < text.length) {
      children.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(
          color: AppTheme.discordText,
          fontSize: 14,
        ),
      ));
    }

    return TextSpan(children: children);
  }
}
