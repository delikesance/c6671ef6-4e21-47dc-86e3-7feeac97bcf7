import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;

import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';

import 'package:bot_creator_shared/bot/bot_template.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

/// Const icon mapping so Flutter's icon tree-shaker can resolve them
/// statically (dynamic `IconData(codePoint)` breaks AOT builds).
const Map<String, IconData> _templateIcons = {
  'welcome': Icons.waving_hand,
  'moderation': Icons.shield,
  'utility': Icons.build,
  'fun': Icons.casino,
};

/// Gallery page that displays bot templates loaded dynamically from GitHub
/// and lets the user apply them to the current bot.
class TemplateGalleryPage extends StatefulWidget {
  final String botId;
  final NyxxRest? client;

  const TemplateGalleryPage({super.key, required this.botId, this.client});

  @override
  State<TemplateGalleryPage> createState() => _TemplateGalleryPageState();
}

class _TemplateGalleryPageState extends State<TemplateGalleryPage> {
  List<BotTemplate>? _templates;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse(
          'https://raw.githubusercontent.com/ketsuna-org/bot-creator-shared/refs/heads/main/template.json',
        ),
      );
      final response = await request.close().timeout(const Duration(seconds: 8));
      final payload = await utf8.decodeStream(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(payload);
      if (decoded is List) {
        final parsed = loadTemplatesFromJsonList(decoded);
        if (mounted) {
          setState(() {
            _templates = parsed;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Invalid template JSON format');
      }
    } catch (e) {
      developer.log('Error fetching templates: $e', name: 'TemplateGallery');
      if (mounted) {
        // Robust offline fallback to local template asset JSON
        try {
          final localAsset = await rootBundle.loadString('assets/template.json');
          final decoded = jsonDecode(localAsset);
          if (decoded is List) {
            final parsed = loadTemplatesFromJsonList(decoded);
            setState(() {
              _templates = parsed;
              _isLoading = false;
            });
          } else {
            throw Exception('Invalid asset format');
          }
        } catch (assetError) {
          developer.log('Error reading fallback template asset: $assetError', name: 'TemplateGallery');
          setState(() {
            _templates = const [];
            _isLoading = false;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to fetch templates from GitHub. Loading offline templates.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      client.close(force: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppAnalytics.logScreenView(
      screenName: 'TemplateGalleryPage',
      screenClass: 'TemplateGalleryPage',
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.template_gallery_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchTemplates,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading templates from GitHub...'),
                  ],
                ),
              )
            : (_templates == null || _templates!.isEmpty)
                ? Center(child: Text(context.tr.template_gallery_empty))
                : RefreshIndicator(
                    onRefresh: _fetchTemplates,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            context.tr.template_gallery_subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        ..._templates!.map(
                          (template) => _TemplateCard(
                            template: template,
                            botId: widget.botId,
                            client: widget.client,
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _TemplateCard extends StatefulWidget {
  final BotTemplate template;
  final String botId;
  final NyxxRest? client;

  const _TemplateCard({
    required this.template,
    required this.botId,
    this.client,
  });

  @override
  State<_TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<_TemplateCard> {
  bool _applying = false;

  Future<void> _applyTemplate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _TemplatePreviewDialog(template: widget.template),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _applying = true);

    try {
      final existingCommands = await appManager.listAppCommands(widget.botId);
      final existingNames =
          existingCommands
              .map((c) => (c['name'] ?? '').toString().toLowerCase())
              .toSet();

      final skipped = <String>[];
      var addedCommands = 0;
      final client = widget.client;

      for (final cmd in widget.template.commands) {
        if (existingNames.contains(cmd.name.toLowerCase())) {
          skipped.add(cmd.name);
          continue;
        }

        final commandType = (cmd.data['commandType'] ?? 'chatInput').toString();
        final templateOrigin = <String, dynamic>{
          'templateId': widget.template.id,
          'appliedAt': DateTime.now().toIso8601String(),
        };
        final commandData = Map<String, dynamic>.from(cmd.data);

        if (client != null) {
          // Register on Discord and save with real ID
          try {
            final ApplicationCommandBuilder commandBuilder;
            if (commandType == 'user') {
              commandBuilder = ApplicationCommandBuilder.user(name: cmd.name);
            } else if (commandType == 'message') {
              commandBuilder = ApplicationCommandBuilder.message(
                name: cmd.name,
              );
            } else {
              commandBuilder = ApplicationCommandBuilder.chatInput(
                name: cmd.name,
                description: cmd.description,
                options: [],
              );
            }
            await createCommand(client, commandBuilder, data: commandData);
          } catch (_) {
            // Discord registration failed — save locally with temp ID
            final commandId =
                DateTime.now().millisecondsSinceEpoch.toString() +
                Random().nextInt(99999).toString();
            final commandMap = <String, dynamic>{
              'id': commandId,
              'name': cmd.name,
              'description': cmd.description,
              'type': commandType,
              'templateOrigin': templateOrigin,
              'data': commandData,
            };
            await appManager.saveAppCommand(
              widget.botId,
              commandId,
              commandMap,
            );
          }
        } else {
          // No client — save locally with temp ID
          final commandId =
              DateTime.now().millisecondsSinceEpoch.toString() +
              Random().nextInt(99999).toString();
          final commandMap = <String, dynamic>{
            'id': commandId,
            'name': cmd.name,
            'description': cmd.description,
            'type': commandType,
            'templateOrigin': templateOrigin,
            'data': commandData,
          };
          await appManager.saveAppCommand(widget.botId, commandId, commandMap);
        }
        addedCommands++;
      }

      // Apply workflows to the bot config
      var addedWorkflows = 0;
      if (widget.template.workflows.isNotEmpty) {
        final appData = await appManager.getApp(widget.botId);
        if (appData.isNotEmpty) {
          final existingWorkflows = List<Map<String, dynamic>>.from(
            (appData['workflows'] as List?)?.whereType<Map>().map(
                  (w) => Map<String, dynamic>.from(w),
                ) ??
                const <Map<String, dynamic>>[],
          );
          final existingWfNames =
              existingWorkflows
                  .map((w) => (w['name'] ?? '').toString().toLowerCase())
                  .toSet();

          for (final wf in widget.template.workflows) {
            final wfName = (wf['name'] ?? '').toString().toLowerCase();
            if (wfName.isEmpty || existingWfNames.contains(wfName)) {
              continue;
            }
            existingWorkflows.add({
              ...Map<String, dynamic>.from(wf),
              'templateOrigin': {
                'templateId': widget.template.id,
                'appliedAt': DateTime.now().toIso8601String(),
              },
            });
            addedWorkflows++;
          }

          appData['workflows'] = existingWorkflows;

          // Merge intents
          final existingIntents = Map<String, bool>.from(
            (appData['intents'] as Map?)?.cast<String, bool>() ??
                const <String, bool>{},
          );
          for (final entry in widget.template.intents.entries) {
            if (entry.value) {
              existingIntents[entry.key] = true;
            }
          }
          appData['intents'] = existingIntents;

          await appManager.saveApp(widget.botId, appData);
        }
      }

      if (!mounted) return;

      for (final name in skipped) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.template_gallery_already_exists(name)),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.template_gallery_apply_success(
              addedCommands,
              addedWorkflows,
            ),
          ),
        ),
      );

      if (client == null && addedCommands > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.template_gallery_sync_warning),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      await AppAnalytics.logEvent(
        name: 'apply_template',
        parameters: {
          'template_id': widget.template.id as Object,
          'commands_added': addedCommands as Object,
          'workflows_added': addedWorkflows as Object,
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.template_gallery_apply_error(e.toString()),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  Future<void> _removeTemplateContent() async {
    final templateId = widget.template.id;

    // Find commands generated by this template.
    final commands = await appManager.listAppCommands(widget.botId);
    final templateCommands =
        commands.where((cmd) {
          final origin = cmd['templateOrigin'] as Map?;
          return (origin?['templateId'] ?? '').toString() == templateId;
        }).toList();

    // Find workflows generated by this template.
    final appData = await appManager.getApp(widget.botId);
    final allWorkflows = List<Map<String, dynamic>>.from(
      (appData['workflows'] as List?)?.whereType<Map>().map(
            (w) => Map<String, dynamic>.from(w),
          ) ??
          const <Map<String, dynamic>>[],
    );
    final templateWorkflows =
        allWorkflows.where((wf) {
          final origin = wf['templateOrigin'] as Map?;
          return (origin?['templateId'] ?? '').toString() == templateId;
        }).toList();

    final totalCount = templateCommands.length + templateWorkflows.length;

    if (!mounted) return;

    if (totalCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr.template_gallery_nothing_to_remove(
              widget.template.nameKey,
            ),
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(context.tr.template_gallery_remove_title),
            content: Text(context.tr.template_gallery_remove_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(context.tr.cancel),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(context.tr.delete),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _applying = true);

    try {
      for (final cmd in templateCommands) {
        await appManager.deleteAppCommand(
          widget.botId,
          (cmd['id'] ?? '').toString(),
        );
      }

      if (templateWorkflows.isNotEmpty) {
        final remaining =
            allWorkflows.where((wf) {
              final origin = wf['templateOrigin'] as Map?;
              return (origin?['templateId'] ?? '').toString() != templateId;
            }).toList();
        appData['workflows'] = remaining;
        await appManager.saveApp(widget.botId, appData);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.template_gallery_removed)),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: _applying ? null : _applyTemplate,
        onLongPress: _applying ? null : _removeTemplateContent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Icon(
                  _templateIcons[template.id] ?? Icons.smart_toy,
                  size: 28,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.nameKey,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      template.descriptionKey,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _InfoChip(
                          icon: Icons.code,
                          label: context.tr.template_gallery_commands_count(
                            template.commands.length,
                          ),
                        ),
                        if (template.workflows.isNotEmpty)
                          _InfoChip(
                            icon: Icons.account_tree,
                            label: context.tr.template_gallery_workflows_count(
                              template.workflows.length,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_applying)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplatePreviewDialog extends StatelessWidget {
  final BotTemplate template;

  const _TemplatePreviewDialog({required this.template});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      titlePadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _templateIcons[template.id] ?? Icons.smart_toy,
              color: colorScheme.onPrimaryContainer,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.nameKey,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.category.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template.descriptionKey,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              
              // COMMANDS
              Row(
                children: [
                  Icon(Icons.code, size: 18, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Commands to add (${template.commands.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              ...template.commands.map((cmd) {
                final type = (cmd.data['commandType'] ?? 'chatInput').toString();
                String badgeText = 'Slash';
                if (type == 'user') badgeText = 'User Menu';
                if (type == 'message') badgeText = 'Msg Menu';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type == 'chatInput' ? '/' : '🖱️ ',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  cmd.name,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    badgeText,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cmd.description,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 20),

              // WORKFLOWS
              if (template.workflows.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.account_tree, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Workflows to add (${template.workflows.length})',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                ...template.workflows.map((wf) {
                  final eventTrigger = wf['eventTrigger'] as Map?;
                  final eventName = eventTrigger != null
                      ? '${eventTrigger['category']}.${eventTrigger['event']}'
                      : 'custom';
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_right_alt,
                          size: 16,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (wf['name'] ?? '').toString(),
                                style: textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Trigger: $eventName',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // REQUIRED INTENTS
              if (template.intents.entries.any((e) => e.value)) ...[
                Row(
                  children: [
                    Icon(Icons.lock_open, size: 18, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Required Gateway Intents',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: template.intents.entries
                      .where((e) => e.value)
                      .map((e) => Chip(
                            label: Text(
                              e.key,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            backgroundColor: colorScheme.secondaryContainer,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.tr.template_gallery_apply),
        ),
      ],
    );
  }
}
