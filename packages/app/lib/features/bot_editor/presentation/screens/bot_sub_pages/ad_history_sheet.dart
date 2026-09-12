import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/utils/duration_formatter.dart';
import 'package:flutter/material.dart';

/// Body of the rewarded-ads grant history bottom sheet.
///
/// Extracted from `home.dart` to keep the `_AppHomePageState` focused on the
/// bot lifecycle; the sheet only needs the resolved [MainApiClient] and the
/// bot id, so it is rendered as a plain [StatelessWidget].
class AdHistorySheet extends StatelessWidget {
  const AdHistorySheet({super.key, required this.client, required this.botId});

  final MainApiClient client;
  final String botId;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: client.getBotAdHistory(botId),
      builder: (ctx, snapshot) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, color: AppTheme.brandPrimary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      context.tr.home_hosting_ad_rewards_history_title,
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXl),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (snapshot.hasError)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: Center(
                    child: Text(
                      context.tr.home_hosting_ad_history_error,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                )
              else if (!snapshot.hasData || snapshot.data!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingXl),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.tv_off_outlined,
                          size: 48,
                          color: colorScheme.outline,
                        ),
                        const SizedBox(height: AppTheme.spacingMd),
                        Text(
                          context.tr.home_hosting_ad_history_empty,
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: snapshot.data!.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final claim = snapshot.data![i];
                      final minutes =
                          claim['granted_minutes'] ??
                          claim['grantedMinutes'] ??
                          0;
                      final placement = (claim['placement'] ?? 'admob_rewarded')
                          .toString();
                      final occurredRaw =
                          claim['occurred_at'] ?? claim['occurredAt'];
                      final occurred = occurredRaw != null
                          ? DateTime.tryParse(occurredRaw.toString())?.toLocal()
                          : null;
                      final dateStr = occurred != null
                          ? '${occurred.day.toString().padLeft(2, '0')}/${occurred.month.toString().padLeft(2, '0')}/${occurred.year} à ${occurred.hour.toString().padLeft(2, '0')}:${occurred.minute.toString().padLeft(2, '0')}'
                          : '';

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.success,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          '+$minutes min ($placement)',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          dateStr,
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        trailing: Text(
                          formatHostingDuration(
                            ctx,
                            minutes is int
                                ? minutes
                                : int.tryParse(minutes.toString()) ?? 0,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
