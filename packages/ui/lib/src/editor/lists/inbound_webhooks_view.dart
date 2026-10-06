import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../theme/block_family.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../widgets/page_layout.dart';
import '../logic/workflow_call.dart';
import 'editor_sub_page_ui.dart';
import 'module_list_widgets.dart';

/// Ce que l'écran des webhooks entrants demande à son hôte.
///
/// Le SECRET d'un webhook est lisible ([secretReadable]) dans l'app, qui le
/// garde localement ; il est en écriture seule dans le Studio (le Manager ne le
/// renvoie jamais) : l'écran n'y propose alors ni « copier le secret » ni
/// l'URL complète, et un secret laissé vide est conservé ou généré par le
/// serveur, puis montré une seule fois.
abstract class InboundWebhooksController {
  const InboundWebhooksController();

  Future<List<Map<String, dynamic>>> webhooks();
  Future<List<Map<String, dynamic>>> workflows();

  /// Enregistre ; rend le secret généré par l'hôte quand il y en a un à
  /// montrer (création sans secret saisi), sinon `null`.
  Future<String?> save({
    required String path,
    required String workflowName,
    required String? secret,
    required bool enabled,
    String? webhookId,
  });

  Future<void> delete(String webhookId);

  bool get secretReadable => true;

  /// URL complète (avec secret) à copier ; `null` : indisponible, l'entrée
  /// est alors masquée.
  Future<String?> fullUrl(Map<String, dynamic> webhook) async => null;

  bool get hasCapability => true;
  int get limit => 0;
  Widget? upsell(BuildContext context, Future<void> Function() reload) => null;
  bool isLimitError(Object error) =>
      error.toString().contains('inbound_webhook_limit_reached');
  bool isPathConflict(Object error) =>
      error.toString().contains('inbound_webhook_path_conflict');
}

class InboundWebhooksView extends StatefulWidget {
  const InboundWebhooksView({super.key, required this.controller});

  final InboundWebhooksController controller;

  @override
  State<InboundWebhooksView> createState() => _InboundWebhooksViewState();
}

class _InboundWebhooksViewState extends State<InboundWebhooksView> {
  bool _loading = true;
  List<Map<String, dynamic>> _webhooks = const <Map<String, dynamic>>[];
  List<String> _workflowNames = const <String>[];

  bool get _hasCapability => widget.controller.hasCapability;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final workflows = await widget.controller.workflows();
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

    final webhooks = await widget.controller.webhooks();

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
    final readable = widget.controller.secretReadable;
    final secretCtrl = TextEditingController(
      text: readable
          ? (initial?['secret'] ?? _generateSecret()).toString()
          : '',
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
                          helperText: readable
                              ? null
                              : initial == null
                              ? '—'
                              : '••••••••',
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

    if (save != true || !mounted) {
      return;
    }

    try {
      final generated = await widget.controller.save(
        path: pathCtrl.text,
        workflowName: selectedWorkflow,
        secret: secretCtrl.text.trim().isEmpty ? null : secretCtrl.text.trim(),
        enabled: enabled,
        webhookId: (initial?['id'] ?? '').toString().trim().isEmpty
            ? null
            : (initial?['id'] ?? '').toString(),
      );
      await _load();
      if (generated != null && mounted) await _showGeneratedSecret(generated);
    } catch (error) {
      if (!mounted) {
        return;
      }
      if (widget.controller.isLimitError(error)) {
        final limit = widget.controller.limit;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.webhooks_limit_reached(limit))),
        );
      } else if (widget.controller.isPathConflict(error)) {
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

    await widget.controller.delete((webhook['id'] ?? '').toString());
    if (!mounted) return;
    setState(() {
      _webhooks = _webhooks
          .where((entry) => entry['id'] != webhook['id'])
          .toList();
    });
  }

  Future<void> _copyFullWebhookUrl(Map<String, dynamic> webhook) async {
    final url = await widget.controller.fullUrl(webhook);
    if (!mounted) return;
    if (url == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.webhooks_missing_data)));
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.tr.webhooks_copied)));
  }

  /// Le secret généré par l'hôte n'est montré qu'ici, une seule fois.
  Future<void> _showGeneratedSecret(String secret) => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog.adaptive(
      title: Text(context.tr.webhooks_secret_label),
      content: SelectableText(
        secret,
        style: const TextStyle(fontFamily: 'JetBrainsMono'),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: secret));
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          },
          child: Text(context.tr.webhooks_copy_secret),
        ),
      ],
    ),
  );

  String _generateSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    final chars = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return chars;
  }

  @override
  Widget build(BuildContext context) {
    final limit = widget.controller.limit;

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
                    if (!_hasCapability)
                      ?widget.controller.upsell(context, _load),
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
                                              await widget.controller.save(
                                                path: path,
                                                workflowName: workflow,
                                                secret:
                                                    widget
                                                        .controller
                                                        .secretReadable
                                                    ? secret
                                                    : null,
                                                enabled: value,
                                                webhookId: (webhook['id'] ?? '')
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
                                        if (widget.controller.secretReadable)
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
                                        if (widget.controller.secretReadable)
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
