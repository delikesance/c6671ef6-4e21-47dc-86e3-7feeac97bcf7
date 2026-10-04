import 'dart:math';

import 'package:bot_creator/main.dart';

import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/widgets/premium_locked_hint.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/editor_sub_page_ui.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/theme/block_category.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/module_list_widgets.dart';

class InboundWebhooksPage extends StatefulWidget {
  const InboundWebhooksPage({super.key, required this.botId});

  final String botId;

  @override
  State<InboundWebhooksPage> createState() => _InboundWebhooksPageState();
}

class _InboundWebhooksPageState extends State<InboundWebhooksPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _webhooks = const <Map<String, dynamic>>[];
  List<String> _workflowNames = const <String>[];

  bool get _hasCapability =>
      PremiumCapabilities.hasCapability(PremiumCapability.inboundWebhooks);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final workflows = await appManager.getWorkflows(widget.botId);
    final workflowNames =
        workflows
            .where(
              (entry) =>
                  normalizeWorkflowType(entry['workflowType']) ==
                  workflowTypeGeneral,
            )
            .map((entry) => (entry['name'] ?? '').toString().trim())
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList(growable: false)
          ..sort();

    final webhooks = await appManager.getInboundWebhooks(widget.botId);

    if (!mounted) {
      return;
    }

    setState(() {
      _workflowNames = workflowNames;
      _webhooks = webhooks;
      _loading = false;
    });
  }

  Future<void> _showEditor({Map<String, dynamic>? initial}) async {
    if (_workflowNames.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.webhooks_no_workflows)));
      return;
    }

    final pathCtrl = TextEditingController(
      text: (initial?['path'] ?? '').toString(),
    );
    final secretCtrl = TextEditingController(
      text: (initial?['secret'] ?? _generateSecret()).toString(),
    );

    var selectedWorkflow =
        ((initial?['workflowName'] ?? '').toString().trim().isNotEmpty)
        ? (initial!['workflowName'] as String)
        : _workflowNames.first;
    var enabled = initial == null ? true : initial['enabled'] != false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setInnerState) {
            return AlertDialog.adaptive(
              title: Text(
                initial == null
                    ? context.tr.webhooks_add_title
                    : context.tr.webhooks_edit_title,
              ),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: pathCtrl,
                        decoration: InputDecoration(
                          labelText: context.tr.webhooks_path_label,
                          hintText: context.tr.webhooks_path_hint,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedWorkflow,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: context.tr.webhooks_target_label,
                          border: OutlineInputBorder(),
                        ),
                        items: _workflowNames
                            .map(
                              (name) => DropdownMenuItem<String>(
                                value: name,
                                child: Text(name),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setInnerState(() {
                            selectedWorkflow = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: secretCtrl,
                        decoration: InputDecoration(
                          labelText: context.tr.webhooks_secret_label,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            tooltip: context.tr.webhooks_generate,
                            icon: const AppIcon.fromMaterial(
                              Icons.casino_outlined,
                            ),
                            onPressed: () {
                              setInnerState(() {
                                secretCtrl.text = _generateSecret();
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: enabled,
                        title: Text(context.tr.common_enabled),
                        onChanged: (value) {
                          setInnerState(() {
                            enabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.tr.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(context.tr.app_save),
                ),
              ],
            );
          },
        );
      },
    );

    if (save != true) {
      return;
    }

    try {
      await appManager.saveInboundWebhook(
        widget.botId,
        path: pathCtrl.text,
        workflowName: selectedWorkflow,
        secret: secretCtrl.text,
        enabled: enabled,
        webhookId: (initial?['id'] ?? '').toString().trim().isEmpty
            ? null
            : (initial?['id'] ?? '').toString(),
      );
      await _load();
    } catch (error) {
      if (!mounted) {
        return;
      }
      final text = error.toString();
      if (text.contains('inbound_webhook_limit_reached')) {
        final limit = PremiumCapabilities.limitFor(
          PremiumCapability.inboundWebhooks,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.webhooks_limit_reached(limit))),
        );
      } else if (text.contains('inbound_webhook_path_conflict')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.webhooks_path_exists)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.webhooks_save_failed('$error'))),
        );
      }
    }
  }

  Future<void> _deleteWebhook(Map<String, dynamic> webhook) async {
    final label = (webhook['path'] ?? '').toString().trim();

    final confirm = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.webhooks_delete_title,
      content: label.isEmpty
          ? context.tr.webhooks_delete_confirm_no_label
          : context.tr.webhooks_delete_confirm(label),
      confirmLabel: context.tr.delete,
      isDestructive: true,
    );

    if (!confirm) {
      return;
    }

    await appManager.deleteInboundWebhook(
      widget.botId,
      (webhook['id'] ?? '').toString(),
    );
    if (!mounted) return;
    setState(() {
      _webhooks = _webhooks
          .where((entry) => entry['id'] != webhook['id'])
          .toList();
    });
  }

  Future<void> _copyFullWebhookUrl(Map<String, dynamic> webhook) async {
    final baseUrl = await RunnerSettings.getUrl();
    final normalizedBase = (baseUrl ?? '').trim();
    if (normalizedBase.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.webhooks_runner_url_required)),
      );
      return;
    }

    final path = (webhook['path'] ?? '').toString().trim();
    final secret = (webhook['secret'] ?? '').toString().trim();
    if (path.isEmpty || secret.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.webhooks_missing_data)));
      return;
    }

    try {
      final baseUri = Uri.parse(normalizedBase);
      final combinedSegments = <String>[
        ...baseUri.pathSegments.where((segment) => segment.isNotEmpty),
        'bots',
        widget.botId,
        'inbound',
        ...path.split('/').where((segment) => segment.trim().isNotEmpty),
      ];
      final fullUri = baseUri.replace(
        pathSegments: combinedSegments,
        queryParameters: <String, String>{'secret': secret},
      );
      await Clipboard.setData(ClipboardData(text: fullUri.toString()));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.webhooks_copied)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.webhooks_invalid_runner_url)),
      );
    }
  }

  String _generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final chars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return chars;
  }

  Widget _buildUpsellCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ModuleUpsellCard(
        title: context.tr.subscription_feature_webhooks_title,
        description: context.tr.subscription_feature_webhooks_desc,
        action: PremiumCapabilities.canShowPurchaseUI
            ? FilledButton.icon(
                onPressed: () async {
                  await SubscriptionPage.show(context);
                  if (!mounted) {
                    return;
                  }
                  await _load();
                },
                icon: const AppIcon.fromMaterial(
                  Icons.workspace_premium_rounded,
                ),
                label: Text(context.tr.premium_card_button),
              )
            // Verrou de FORMULE, pas de plateforme (voir PremiumLockedHint).
            : const PremiumLockedHint(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final limit = PremiumCapabilities.limitFor(
      PremiumCapability.inboundWebhooks,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: editorSubPageLeading(context),
        title: Text(context.tr.webhooks_page_title),
        actions: [
          IconButton(
            tooltip: context.tr.common_refresh,
            onPressed: _load,
            icon: const AppIcon.fromMaterial(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _hasCapability
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _showEditor(),
              icon: const AppIcon.fromMaterial(Icons.add),
              label: Text(context.tr.webhooks_add_action),
            )
          : null,
      body: SafeArea(
        top: false,
        child: PageContent(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (!_hasCapability) _buildUpsellCard(),
                    Padding(
                      // Marges horizontales portées par PageContent.
                      padding: const EdgeInsets.only(
                        top: AppTheme.spacingMd,
                        bottom: AppTheme.spacingSm,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ModuleOverline(
                          context.tr.webhooks_count(
                            _webhooks.length,
                            limit > 0 ? ' / $limit' : '',
                          ),
                          family: BlockFamily.http,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _webhooks.isEmpty
                          ? EditorEmptyState(
                              icon: Icons.webhook_rounded,
                              title: context.tr.webhooks_empty,
                              description: _workflowNames.isEmpty
                                  ? context.tr.webhooks_no_workflows
                                  : null,
                              actionLabel: _hasCapability
                                  ? context.tr.webhooks_add_action
                                  : null,
                              onAction: _hasCapability ? _showEditor : null,
                            )
                          : ListView.separated(
                              padding: EdgeInsets.only(
                                bottom:
                                    FloatingGlassNavBar.contentClearanceOf(
                                      context,
                                    ) +
                                    24,
                              ),
                              itemCount: _webhooks.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final webhook = _webhooks[index];
                                final path = (webhook['path'] ?? '').toString();
                                final workflow = (webhook['workflowName'] ?? '')
                                    .toString();
                                final secret = (webhook['secret'] ?? '')
                                    .toString();
                                final enabled = webhook['enabled'] != false;
                                return ModuleRowCard(
                                  key: ValueKey(
                                    'inbound_webhook_${webhook['id']}',
                                  ),
                                  family: BlockFamily.http,
                                  icon: Icons.webhook_rounded,
                                  title: '/$path',
                                  titleMono: true,
                                  summary: context.tr
                                      .webhooks_workflow_subtitle(workflow),
                                  monoSummary: false,
                                  dimmed: !enabled,
                                  trailing: [
                                    Switch.adaptive(
                                      value: enabled,
                                      onChanged: _hasCapability
                                          ? (value) async {
                                              await appManager
                                                  .saveInboundWebhook(
                                                    widget.botId,
                                                    path: path,
                                                    workflowName: workflow,
                                                    secret: secret,
                                                    enabled: value,
                                                    webhookId:
                                                        (webhook['id'] ?? '')
                                                            .toString(),
                                                  );
                                              await _load();
                                            }
                                          : null,
                                    ),
                                    moduleMoreButton<String>(
                                      context: context,
                                      tooltip: context.tr.webhooks_actions,
                                      itemBuilder: (context) => [
                                        moduleMenuItem<String>(
                                          context,
                                          value: 'copy_url',
                                          icon: Icons.content_copy_outlined,
                                          label: context.tr.webhooks_copy_url,
                                          onTap: () =>
                                              _copyFullWebhookUrl(webhook),
                                        ),
                                        moduleMenuItem<String>(
                                          context,
                                          value: 'copy_path',
                                          icon: Icons.link_outlined,
                                          label: context.tr.webhooks_copy_path,
                                          onTap: () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: '/$path'),
                                            );
                                            if (!mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  this
                                                      .context
                                                      .tr
                                                      .webhooks_path_copied,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        moduleMenuItem<String>(
                                          context,
                                          value: 'copy_secret',
                                          icon: Icons.key_outlined,
                                          label:
                                              context.tr.webhooks_copy_secret,
                                          onTap: () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: secret),
                                            );
                                            if (!mounted) {
                                              return;
                                            }
                                            ScaffoldMessenger.of(
                                              this.context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  this
                                                      .context
                                                      .tr
                                                      .webhooks_secret_copied,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        if (_hasCapability) ...[
                                          moduleMenuItem<String>(
                                            context,
                                            value: 'edit',
                                            icon: Icons.edit_outlined,
                                            label: context.tr.common_edit,
                                            onTap: () =>
                                                _showEditor(initial: webhook),
                                          ),
                                          const PopupMenuDivider(),
                                          moduleMenuItem<String>(
                                            context,
                                            value: 'delete',
                                            icon: Icons.delete_outline,
                                            label: context.tr.common_delete,
                                            danger: true,
                                            onTap: () =>
                                                _deleteWebhook(webhook),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
