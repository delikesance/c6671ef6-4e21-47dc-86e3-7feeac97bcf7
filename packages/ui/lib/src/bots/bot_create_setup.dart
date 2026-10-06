import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import '../widgets/home_ui.dart';

/// Formulaire « Créer un bot » : moteur (Visuel / JavaScript), jeton, sécurité
/// et ressources (portail Discord, tutoriel). Partagé entre l'app et le Studio :
/// la page qui l'héberge porte le contrat (valider le jeton, écrire le bot).
///
/// [onHosted] est optionnel : sans lui, la ligne « bot hébergé » n'apparaît pas.
class BotCreateSetup extends StatelessWidget {
  const BotCreateSetup({
    super.key,
    required this.javascript,
    required this.onEngineChanged,
    required this.tokenController,
    required this.obscureToken,
    required this.onToggleToken,
    required this.onTokenChanged,
    required this.saving,
    required this.onSave,
    required this.onBack,
    required this.showBack,
    required this.onPortal,
    required this.onGuide,
    this.onHosted,
  });
  final bool javascript, obscureToken, saving, showBack;
  final ValueChanged<bool> onEngineChanged;
  final TextEditingController tokenController;
  final ValueChanged<String> onTokenChanged;
  final VoidCallback onToggleToken, onBack, onPortal, onGuide;
  final VoidCallback? onSave, onHosted;

  Widget _panel(BuildContext context, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? HomeTokens.of(context).card
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _resource(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    VoidCallback onTap,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppIcon.fromMaterial(
              icon,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: homeDisplayStyle(14, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppIcon.fromMaterial(
              Icons.chevron_right_rounded,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final scheme = Theme.of(context).colorScheme;
    final form = _panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.bot_create_mode, style: homeSectionLabelStyle(context)),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text(tr.bot_create_visual_title),
              ),
              ButtonSegment(
                value: true,
                label: Text(tr.cmd_execution_mode_javascript),
              ),
            ],
            selected: {javascript},
            onSelectionChanged: saving
                ? null
                : (values) => onEngineChanged(values.first),
            style: SegmentedButton.styleFrom(
              foregroundColor: scheme.onSurfaceVariant,
              selectedBackgroundColor: Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surfaceContainerLow,
              ),
              selectedForegroundColor: scheme.onSurface,
              side: BorderSide(color: scheme.outlineVariant),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            javascript
                ? tr.bot_create_javascript_description
                : tr.bot_create_visual_description,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 28),
          Divider(color: scheme.outlineVariant, height: 1),
          const SizedBox(height: 24),
          Text(
            tr.app_token_section_title,
            style: homeDisplayStyle(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            tr.app_token_section_desc,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: tokenController,
            enabled: !saving,
            obscureText: obscureToken,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onChanged: onTokenChanged,
            onSubmitted: (_) => onSave?.call(),
            decoration: InputDecoration(
              labelText: tr.app_bot_token,
              hintText: tr.app_enter_token,
              helperText: tr.app_token_field_helper,
              helperMaxLines: 3,
              prefixIcon: const AppIcon.fromMaterial(
                Icons.key_rounded,
                size: 18,
              ),
              suffixIcon: IconButton(
                tooltip: obscureToken ? tr.app_show_token : tr.app_hide_token,
                onPressed: onToggleToken,
                icon: AppIcon.fromMaterial(
                  obscureToken
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIcon.fromMaterial(
                Icons.lock_outline_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr.app_token_security_hint,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSave,
            icon: saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : const AppIcon.fromMaterial(
                    Icons.arrow_forward_rounded,
                    size: 18,
                  ),
            label: Text(tr.app_save_bot),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
          ),
        ],
      ),
    );
    final resources = _panel(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.app_resources_title, style: homeSectionLabelStyle(context)),
          _resource(
            context,
            Icons.open_in_new_rounded,
            tr.app_open_discord_portal,
            tr.app_open_discord_portal_desc,
            onPortal,
          ),
          Divider(color: scheme.outlineVariant, height: 1),
          _resource(
            context,
            Icons.menu_book_outlined,
            tr.app_open_token_tutorial,
            tr.app_open_token_tutorial_desc,
            onGuide,
          ),
          if (onHosted != null) ...[
            Divider(color: scheme.outlineVariant, height: 1),
            _resource(
              context,
              Icons.smart_toy_outlined,
              tr.app_create_type_hosted,
              tr.app_create_type_hosted_desc,
              onHosted!,
            ),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBack) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: HomeHeaderIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onBack,
            ),
          ),
          const SizedBox(height: 20),
        ],
        Text(tr.home_overline, style: homeSectionLabelStyle(context)),
        const SizedBox(height: 8),
        Text(
          tr.bot_create_title,
          style: homeDisplayStyle(30, weight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          tr.bot_create_description,
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 760) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [form, const SizedBox(height: 20), resources],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: resources),
              ],
            );
          },
        ),
      ],
    );
  }
}
