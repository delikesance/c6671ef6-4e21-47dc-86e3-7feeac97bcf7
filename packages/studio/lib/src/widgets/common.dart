import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../l10n_ext.dart';
import '../theme.dart';

class Overline extends StatelessWidget {
  const Overline(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.84,
      color: StudioColors.muted,
    ),
  );
}

class CountChip extends StatelessWidget {
  const CountChip(this.count, {super.key});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
    height: 20,
    padding: const EdgeInsets.symmetric(horizontal: 7),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: StudioColors.countChip,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      '$count',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: StudioColors.muted,
      ),
    ),
  );
}

/// Message centré pour une section pas encore portée sur le web.
class ComingSoon extends StatelessWidget {
  const ComingSoon({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          context.l10n.comingSoonBody,
          textAlign: TextAlign.center,
          style: TextStyle(color: StudioColors.muted),
        ),
      ],
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: StudioColors.card,
        border: Border.all(color: StudioColors.cardBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon.fromMaterial(
            Icons.error_outline_rounded,
            color: StudioColors.errorText,
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.loadError,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: StudioColors.muted),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    ),
  );
}

class BlockChip extends StatelessWidget {
  const BlockChip(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: StudioColors.selected,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: StudioColors.muted,
      ),
    ),
  );
}

class StudioLogo extends StatelessWidget {
  const StudioLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Bot Creator',
      ),
    );
  }
}
