part of 'home.dart';

extension _AppHomePageUI on _AppHomePageState {
  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  Color _hostingTimeColor(int minutes) {
    const minutesPerDay = 60 * 24;
    const minutesThreeDays = minutesPerDay * 3;

    if (minutes < minutesPerDay) return AppTheme.error;
    if (minutes < minutesThreeDays) return AppTheme.warning;
    return AppTheme.successAccent;
  }

  String formatDuration(int i) {
    final hours = i ~/ 60;
    final minutes = i % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingMd,
              AppTheme.spacingLg,
              AppTheme.spacingSm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: AppTheme.spacingXs),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }
}
