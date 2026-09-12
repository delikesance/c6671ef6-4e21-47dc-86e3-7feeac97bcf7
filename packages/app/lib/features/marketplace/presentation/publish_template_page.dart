import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator_shared/bot/marketplace_template.dart';
import 'package:flutter/material.dart';

/// Publish flow: select commands + workflows + variables, add metadata, publish.
/// When [existingTemplate] is provided, the page operates in edit mode (pre-filled fields, PUT on publish).
class PublishTemplatePage extends StatefulWidget {
  final String botId;
  final MainApiClient? apiClient;
  final String authorId;
  final String authorName;
  final MarketplaceTemplate? existingTemplate;

  const PublishTemplatePage({
    super.key,
    required this.botId,
    this.apiClient,
    required this.authorId,
    required this.authorName,
    this.existingTemplate,
  });

  @override
  State<PublishTemplatePage> createState() => _PublishTemplatePageState();
}

class _PublishTemplatePageState extends State<PublishTemplatePage> {
  int _step = 0;

  List<Map<String, dynamic>>? _allCommands;
  List<Map<String, dynamic>>? _allWorkflows;
  Map<String, dynamic>? _appData;
  final _selectedCommands = <String>{};
  final _selectedWorkflows = <String>{};
  bool _loadingData = true;

  final _selectedVars = <String, bool>{};

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _descLongCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _iconCtrl = TextEditingController(text: '\ud83d\udce6');
  final _versionCtrl = TextEditingController(text: '1.0.0');

  bool _publishing = false;

  bool get _isEditing => widget.existingTemplate != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onMetadataChanged);
    _descCtrl.addListener(_onMetadataChanged);
    _versionCtrl.addListener(_onMetadataChanged);

    if (_isEditing) {
      final t = widget.existingTemplate!;
      _nameCtrl.text = t.name;
      _descCtrl.text = t.description;
      _descLongCtrl.text = t.descriptionLong ?? '';
      _categoryCtrl.text = t.category;
      _tagsCtrl.text = t.tags.join(', ');
      _iconCtrl.text = t.icon;
      _versionCtrl.text = t.version;
    }

    _loadData();
  }

  void _onMetadataChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onMetadataChanged);
    _descCtrl.removeListener(_onMetadataChanged);
    _versionCtrl.removeListener(_onMetadataChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _descLongCtrl.dispose();
    _categoryCtrl.dispose();
    _tagsCtrl.dispose();
    _iconCtrl.dispose();
    _versionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loadingData = true);
    try {
      final commands = await appManager.listAppCommands(widget.botId);
      final appData = await appManager.getApp(widget.botId);
      final workflows = List<Map<String, dynamic>>.from(
        (appData['workflows'] as List?)?.whereType<Map>().map(
              (w) => Map<String, dynamic>.from(w),
            ) ??
            const [],
      );

      if (mounted) {
        setState(() {
          _allCommands = commands
              .map((c) => Map<String, dynamic>.from(c))
              .toList();
          _allWorkflows = workflows;
          _appData = appData;

          if (_isEditing) {
            final t = widget.existingTemplate!;
            _selectedCommands.addAll(
              t.commands.map((c) => c.name).where((n) => n.isNotEmpty),
            );
            _selectedWorkflows.addAll(
              t.workflows
                  .map((w) => (w['name'] ?? '').toString())
                  .where((n) => n.isNotEmpty),
            );
            for (final v in t.globalVariables) {
              _selectedVars[v.name] = v.required;
            }
          }

          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.marketplace_load_error(e.toString())),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _globalVars {
    final vars = (_appData?['globalVariables'] as Map?)
        ?.cast<String, dynamic>();
    if (vars == null) return [];
    return vars.entries.map((e) => {'name': e.key, 'value': e.value}).toList();
  }

  int get _selectedCount =>
      _selectedCommands.length + _selectedWorkflows.length;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.marketplace_publish_title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 3),
        ),
      ),
      body: SafeArea(
        child: _loadingData
            ? const Center(child: CircularProgressIndicator())
            : _buildStep(cs),
      ),
      bottomNavigationBar: _buildBottomBar(cs),
    );
  }

  Widget _buildStep(ColorScheme cs) {
    switch (_step) {
      case 0:
        return _buildSelectionStep(cs);
      case 1:
        return _buildVariablesStep(cs);
      case 2:
        return _buildMetadataStep(cs);
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Step 1 ──────────────────────────────────────────────────

  Widget _buildSelectionStep(ColorScheme cs) {
    final tr = context.tr;
    final commands = _allCommands ?? [];
    final workflows = _allWorkflows ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.marketplace_publish_select,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            tr.marketplace_publish_select_hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          if (commands.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.arrow_forward, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr.marketplace_publish_commands(commands.length.toString()),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedCommands.length == commands.length) {
                        _selectedCommands.clear();
                      } else {
                        _selectedCommands.addAll(
                          commands.map((c) => c['name']?.toString() ?? ''),
                        );
                      }
                    });
                  },
                  child: Text(
                    _selectedCommands.length == commands.length
                        ? tr.marketplace_publish_deselect_all
                        : tr.marketplace_publish_select_all,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...commands.map((cmd) {
              final name = cmd['name']?.toString() ?? '';
              final desc = cmd['description']?.toString() ?? '';
              return CheckboxListTile(
                dense: true,
                value: _selectedCommands.contains(name),
                title: Text(
                  '/$name',
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
                subtitle: Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedCommands.add(name);
                    } else {
                      _selectedCommands.remove(name);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 24),
          ],

          if (workflows.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.account_tree, size: 20),
                const SizedBox(width: 8),
                Text(
                  tr.marketplace_publish_workflows(workflows.length.toString()),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedWorkflows.length == workflows.length) {
                        _selectedWorkflows.clear();
                      } else {
                        _selectedWorkflows.addAll(
                          workflows.map((w) => w['name']?.toString() ?? ''),
                        );
                      }
                    });
                  },
                  child: Text(
                    _selectedWorkflows.length == workflows.length
                        ? tr.marketplace_publish_deselect_all
                        : tr.marketplace_publish_select_all,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...workflows.map((wf) {
              final name = wf['name']?.toString() ?? '';
              final type = wf['workflowType']?.toString() ?? 'event';
              return CheckboxListTile(
                dense: true,
                value: _selectedWorkflows.contains(name),
                title: Text(name),
                subtitle: Text(type),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedWorkflows.add(name);
                    } else {
                      _selectedWorkflows.remove(name);
                    }
                  });
                },
              );
            }),
          ],

          if (commands.isEmpty && workflows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  tr.marketplace_publish_no_content,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Step 2 ──────────────────────────────────────────────────

  Widget _buildVariablesStep(ColorScheme cs) {
    final tr = context.tr;
    final vars = _globalVars;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.marketplace_publish_variables,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            tr.marketplace_publish_variables_hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          if (vars.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  tr.marketplace_no_variables,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...vars.map((v) {
              final name = v['name']?.toString() ?? '';
              final value = v['value']?.toString() ?? '';
              final included = _selectedVars.containsKey(name);
              final required = _selectedVars[name] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                Text(
                                  value,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: included,
                            onChanged: (v) {
                              setState(() {
                                if (v) {
                                  _selectedVars[name] = false;
                                } else {
                                  _selectedVars.remove(name);
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (included)
                        CheckboxListTile(
                          dense: true,
                          value: required,
                          title: Text(tr.marketplace_publish_user_must_define),
                          subtitle: Text(
                            tr.marketplace_publish_user_must_define_hint,
                          ),
                          onChanged: (v) {
                            setState(() => _selectedVars[name] = v ?? false);
                          },
                        ),
                    ],
                  ),
                ),
              );
            }),

          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showAddVariableDialog(),
            icon: const Icon(Icons.add),
            label: Text(tr.marketplace_publish_add_variable),
          ),
        ],
      ),
    );
  }

  void _showAddVariableDialog() {
    final tr = context.tr;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.marketplace_publish_add_variable_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: tr.marketplace_publish_variable_name_label,
                hintText: tr.marketplace_publish_variable_name_hint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(
                labelText: tr.marketplace_publish_variable_desc_label,
                hintText: tr.marketplace_publish_variable_desc_hint,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr.marketplace_cancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _selectedVars[name] = false;
                  if (_appData != null) {
                    final gv =
                        (_appData!['globalVariables'] as Map?)
                            ?.cast<String, dynamic>() ??
                        {};
                    gv[name] = '';
                    _appData!['globalVariables'] = gv;
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: Text(tr.marketplace_add),
          ),
        ],
      ),
    );
  }

  // ── Step 3 ──────────────────────────────────────────────────

  Widget _buildMetadataStep(ColorScheme cs) {
    final tr = context.tr;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.marketplace_publish_metadata,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            tr.marketplace_publish_metadata_hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),

          _buildSummaryCard(cs, tr),
          const SizedBox(height: 24),

          Row(
            children: [
              GestureDetector(
                onTap: _showEmojiPicker,
                child: AbsorbPointer(
                  child: SizedBox(
                    width: 56,
                    child: TextField(
                      controller: _iconCtrl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28),
                      decoration: InputDecoration(
                        hintText: '\ud83d\udce6',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(8),
                      ),
                      maxLength: 2,
                      buildCounter:
                          (
                            _, {
                            required currentLength,
                            required isFocused,
                            maxLength,
                          }) => null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: '${tr.marketplace_publish_name_label} *',
                    hintText: tr.marketplace_publish_name_hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '${tr.marketplace_publish_desc_label} *',
              hintText: tr.marketplace_publish_desc_hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _descLongCtrl,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: tr.marketplace_publish_desc_long_label,
              hintText: tr.marketplace_publish_desc_long_hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _categoryCtrl,
                  decoration: InputDecoration(
                    labelText: tr.marketplace_publish_category_label,
                    hintText: tr.marketplace_publish_category_hint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _versionCtrl,
                  decoration: InputDecoration(
                    labelText: '${tr.marketplace_publish_version_label} *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _tagsCtrl,
            decoration: InputDecoration(
              labelText: tr.marketplace_publish_tags_label,
              hintText: tr.marketplace_publish_tags_hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs, AppLocalizations tr) {
    final cmdCount = _selectedCommands.length;
    final wfCount = _selectedWorkflows.length;
    final varCount = _selectedVars.length;
    final requiredVarCount = _selectedVars.values.where((v) => v).length;

    return Card(
      color: cs.primaryContainer.withAlpha(80),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.marketplace_publish_summary,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _summaryRow(
              Icons.arrow_forward,
              tr.marketplace_summary_commands(cmdCount),
            ),
            _summaryRow(
              Icons.account_tree,
              tr.marketplace_summary_workflows(wfCount),
            ),
            _summaryRow(
              Icons.data_object,
              tr.marketplace_summary_variables(varCount, requiredVarCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  // ── Bottom bar ──────────────────────────────────────────────

  Widget _buildBottomBar(ColorScheme cs) {
    final tr = context.tr;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (_step > 0)
              OutlinedButton(
                onPressed: () => setState(() => _step--),
                child: Text(tr.marketplace_publish_back),
              ),
            const Spacer(),
            if (_step < 2)
              FilledButton(
                onPressed: _canAdvance ? () => setState(() => _step++) : null,
                child: Text(tr.marketplace_publish_next),
              )
            else
              FilledButton.icon(
                onPressed: _publishing || !_metadataValid ? null : _publish,
                icon: _publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _publishing
                      ? tr.marketplace_publishing
                      : tr.marketplace_publish_button,
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool get _canAdvance {
    if (_step == 0) return _selectedCount > 0;
    if (_step == 2) return _metadataValid;
    return true;
  }

  bool get _metadataValid =>
      _nameCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty &&
      _versionCtrl.text.trim().isNotEmpty;

  void _showEmojiPicker() {
    const emojis = <String, List<String>>{
      'Smileys': [
        '😀',
        '😃',
        '😄',
        '😁',
        '😅',
        '😂',
        '🤣',
        '😊',
        '😇',
        '🙂',
        '😉',
        '😌',
        '😍',
        '🥰',
        '😘',
        '😗',
        '😋',
        '😛',
        '😜',
        '🤪',
        '😎',
        '🤩',
        '🥳',
        '😏',
        '😒',
        '😔',
        '😢',
        '😭',
        '😤',
        '😡',
        '🥺',
        '😱',
      ],
      'Gestures': [
        '👍',
        '👎',
        '👏',
        '🙌',
        '🤝',
        '💪',
        '✌️',
        '🤞',
        '👌',
        '🤌',
        '🤏',
        '👋',
        '🤚',
        '🖐️',
        '✋',
        '🖖',
        '🤟',
        '🤘',
        '🤙',
        '🫶',
        '🙏',
        '💅',
        '🤳',
        '🦾',
        '🦿',
      ],
      'Objects': [
        '📦',
        '🎁',
        '🎉',
        '🎊',
        '🎈',
        '🏆',
        '🏅',
        '🥇',
        '🥈',
        '🥉',
        '💎',
        '🔮',
        '🎵',
        '🎶',
        '🎤',
        '🎧',
        '📱',
        '💻',
        '🖥️',
        '⌨️',
        '🖱️',
        '🖨️',
        '📷',
        '📹',
        '🔦',
        '💡',
        '🔋',
        '💰',
        '💳',
      ],
      'Symbols': [
        '❤️',
        '🧡',
        '💛',
        '💚',
        '💙',
        '💜',
        '🖤',
        '🤍',
        '🤎',
        '💔',
        '❣️',
        '💕',
        '💞',
        '💓',
        '💗',
        '💖',
        '💝',
        '💘',
        '💌',
        '☮️',
        '✝️',
        '☪️',
        '🕉️',
        '☸️',
        '✡️',
        '🔯',
        '🕎',
        '☯️',
        '☦️',
        '🛐',
        '⚛️',
      ],
      'Nature': [
        '🐶',
        '🐱',
        '🐭',
        '🐹',
        '🐰',
        '🦊',
        '🐻',
        '🐼',
        '🐨',
        '🐯',
        '🦁',
        '🐮',
        '🐷',
        '🐸',
        '🐵',
        '🐔',
        '🐧',
        '🐦',
        '🐤',
        '🦆',
        '🦅',
        '🦉',
        '🦇',
        '🐺',
        '🐗',
        '🐴',
        '🦄',
        '🐝',
        '🐛',
        '🦋',
        '🐌',
      ],
      'Misc': [
        '🔥',
        '⭐',
        '🌟',
        '✨',
        '💫',
        '🌈',
        '☀️',
        '🌤️',
        '⛅',
        '🌧️',
        '⛈️',
        '🌩️',
        '❄️',
        '☃️',
        '⛄',
        '💧',
        '💦',
        '🌊',
        '🎯',
        '🏹',
        '⚔️',
        '🛡️',
        '🗡️',
        '🔧',
        '🔨',
        '⚒️',
        '🛠️',
        '⛏️',
        '🔩',
        '⚙️',
        '🗜️',
      ],
    };

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.85,
          expand: false,
          builder: (ctx, scrollController) {
            return DefaultTabController(
              length: emojis.length,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurfaceVariant.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(fontSize: 13),
                    tabs: emojis.keys.map((cat) => Tab(text: cat)).toList(),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: emojis.values.map((list) {
                        return GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                mainAxisSpacing: 6,
                                crossAxisSpacing: 6,
                              ),
                          itemCount: list.length,
                          itemBuilder: (ctx, i) {
                            return InkWell(
                              onTap: () {
                                _iconCtrl.text = list[i];
                                Navigator.pop(ctx);
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: _iconCtrl.text == list[i]
                                      ? cs.primary.withAlpha(30)
                                      : null,
                                ),
                                child: Text(
                                  list[i],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _publish() async {
    final tr = context.tr;

    // Guard: validate required fields before publishing
    if (!_metadataValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr.marketplace_publish_required_fields)),
      );
      return;
    }

    final client = widget.apiClient;
    if (client == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.marketplace_api_unavailable)));
      return;
    }

    setState(() => _publishing = true);

    try {
      final commands = (_allCommands ?? [])
          .where((c) => _selectedCommands.contains(c['name']?.toString() ?? ''))
          .map(
            (c) => {
              'name': c['name'],
              'description': c['description'] ?? '',
              'data': Map<String, dynamic>.from(c['data'] ?? c),
            },
          )
          .toList();

      final workflows = (_allWorkflows ?? [])
          .where(
            (w) => _selectedWorkflows.contains(w['name']?.toString() ?? ''),
          )
          .toList();

      final globalVariables = _selectedVars.entries.map((e) {
        final existing = _globalVars.firstWhere(
          (v) => v['name'] == e.key,
          orElse: () => {'value': ''},
        );
        return {
          'name': e.key,
          'description': 'Global variable ${e.key}',
          'required': e.value,
          'defaultValue': existing['value']?.toString(),
          'sensitive': false,
        };
      }).toList();

      final intents = Map<String, bool>.from(
        (_appData?['intents'] as Map?)?.cast<String, bool>() ?? {},
      );

      final template = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'descriptionLong': _descLongCtrl.text.trim().isEmpty
            ? null
            : _descLongCtrl.text.trim(),
        'authorId': widget.authorId,
        'authorName': widget.authorName,
        'version': _versionCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'tags': _tagsCtrl.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        'icon': _iconCtrl.text.trim(),
        'intents': intents,
        'commands': commands,
        'workflows': workflows,
        'globalVariables': globalVariables,
      };

      if (_isEditing) {
        await client.updateMarketplaceTemplate(
          widget.existingTemplate!.id,
          template,
        );
      } else {
        await client.createMarketplaceTemplate(template);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr.marketplace_publish_success)));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.marketplace_publish_error(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }
}
