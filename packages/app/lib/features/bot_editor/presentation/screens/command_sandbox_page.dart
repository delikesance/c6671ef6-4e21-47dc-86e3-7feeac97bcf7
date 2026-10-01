import 'dart:convert';

import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/function_suite.dart';
import 'package:flutter/material.dart';
import 'sandbox_functions_page.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Tests the editor's draft, without saving or registering a Discord command.
class CommandSandboxPage extends StatefulWidget {
  const CommandSandboxPage({
    super.key,
    this.script,
    this.runner,
    this.editableScript = false,
    this.initialScenario = const {},
    this.expectedResponse,
    this.expectedValues = const {},
    this.actions,
    this.options = const [],
    this.definitions = const [],
  });
  final String? script;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)? runner;
  final bool editableScript;
  final Map<String, dynamic> initialScenario;
  final String? expectedResponse;
  final Map<String, dynamic> expectedValues;
  final List<Map<String, dynamic>>? actions;
  final List<Map<String, dynamic>> options;
  final List<Map<String, dynamic>> definitions;
  @override
  State<CommandSandboxPage> createState() => _CommandSandboxPageState();
}

class _CommandSandboxPageState extends State<CommandSandboxPage> {
  final source = TextEditingController();
  final guild = TextEditingController(text: '10');
  final user = TextEditingController(text: '20');
  final message = TextEditingController();
  final initial = TextEditingController(text: '{}');
  final inputs = <String, TextEditingController>{};
  bool admin = false;
  bool running = false;
  Map<String, dynamic>? result;
  String? error;
  bool get french => Localizations.localeOf(context).languageCode == 'fr';
  String label(String fr, String en) => french ? fr : en;

  Widget responsePreview(Map response) {
    final payload = Map<String, dynamic>.from(response['payload'] as Map);
    final content = (payload['content'] ?? payload['text'] ?? '').toString();
    final details = Map<String, dynamic>.from(payload)
      ..remove('content')
      ..remove('text')
      ..removeWhere(
        (_, value) =>
            value == null ||
            (value is List && value.isEmpty) ||
            (value is Map && value.isEmpty),
      );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.isNotEmpty) SelectableText(content),
        if (details.isNotEmpty || content.isEmpty)
          SelectableText(const JsonEncoder.withIndent('  ').convert(details)),
        if (response['api_components'] != null || response['api_modal'] != null)
          ExpansionTile(
            title: Text(label('Composants générés', 'Generated components')),
            children: [
              SelectableText(
                const JsonEncoder.withIndent(
                  '  ',
                ).convert(response['api_modal'] ?? response['api_components']),
              ),
            ],
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    source.text = widget.script ?? '';
    initial.text = const JsonEncoder.withIndent(
      '  ',
    ).convert(widget.initialScenario);
    for (final option in widget.options) {
      if ((option['type'] as num? ?? 3) >= 3) {
        inputs[option['name'].toString()] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in [
      source,
      guild,
      user,
      message,
      initial,
      ...inputs.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> run() async {
    setState(() {
      running = true;
      error = null;
      result = null;
    });
    try {
      final options = <String, dynamic>{};
      for (final option in widget.options) {
        final key = option['name'].toString();
        final text = inputs[key]?.text.trim() ?? '';
        if (text.isEmpty) {
          if (option['required'] == true) {
            throw FormatException(
              '$key: ${label("valeur requise", "required value")}',
            );
          }
          continue;
        }
        final type = option['type'];
        options[key] = switch (type) {
          4 => int.parse(text),
          10 => num.parse(text),
          5 => switch (text.toLowerCase()) {
            'true' => true,
            'false' => false,
            _ => throw FormatException('$key: true / false'),
          },
          6 || 7 || 8 || 9 => {'id': text},
          _ => text,
        };
      }
      final seed = jsonDecode(initial.text);
      if (seed is! Map) {
        throw const FormatException('Initial state must be an object');
      }
      // Advanced fixtures cannot replace the source displayed in the editor.
      seed.remove('script');
      seed.remove('actions');
      final value = await (widget.runner ?? testCommandInSandbox)({
        if (widget.script != null) 'script': source.text,
        if (widget.actions != null) 'actions': widget.actions,
        'options': options,
        'variables': {
          'guild.id': guild.text,
          'author.id': user.text,
          'user.id': user.text,
          'member.isAdmin': admin,
          'member.permissions': admin ? 'administrator' : '',
          'message.content': message.text,
        },
        'definitions': widget.definitions,
        ...Map<String, dynamic>.from(seed),
      });
      if (widget.expectedResponse != null || widget.expectedValues.isNotEmpty) {
        final contract = evaluateSandboxContract(
          value,
          expectedContent: widget.expectedResponse,
          expectedValues: widget.expectedValues,
        );
        value['contract_passed'] = contract['passed'];
        value['contract_checks'] = contract['checks'];
      }
      if (mounted) {
        setState(() {
          result = value;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          running = false;
        });
      }
    }
  }

  Widget field(
    TextEditingController controller,
    String name, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: name,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(label('Tester la commande', 'Test command')),
      actions: [
        IconButton(
          icon: const AppIcon.fromMaterial(Icons.science_outlined),
          tooltip: label('Tester les fonctions', 'Test functions'),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SandboxFunctionsPage(),
            ),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                label(
                  'Simulation locale · Discord et les données du bot restent intacts.',
                  'Local simulation · Discord and bot data remain untouched.',
                ),
              ),
              const SizedBox(height: 16),
              if (widget.editableScript)
                field(
                  source,
                  label("Script à tester", "Test script"),
                  lines: 5,
                ),
              if (widget.expectedResponse != null)
                Text(
                  label("Réponse attendue : ", "Expected response: ") +
                      widget.expectedResponse!,
                ),
              if (widget.expectedValues.isNotEmpty)
                ExpansionTile(
                  title: Text(label('Résultat attendu', 'Expected result')),
                  children: [
                    SelectableText(
                      const JsonEncoder.withIndent(
                        '  ',
                      ).convert(widget.expectedValues),
                    ),
                  ],
                ),
              field(
                guild,
                label('ID du serveur simulé', 'Simulated server ID'),
              ),
              field(user, label('ID du membre simulé', 'Simulated member ID')),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: admin,
                title: Text(
                  label('Membre administrateur', 'Administrator member'),
                ),
                onChanged: running
                    ? null
                    : (value) => setState(() {
                        admin = value;
                      }),
              ),
              for (final entry in inputs.entries) field(entry.value, entry.key),
              field(
                message,
                label('Message texte simulé', 'Simulated message text'),
                lines: 2,
              ),
              ExpansionTile(
                title: Text(
                  label('État initial avancé', 'Advanced initial state'),
                ),
                subtitle: Text(
                  label(
                    'Variables de test et valeurs initiales (JSON)',
                    'Test variables and initial values (JSON)',
                  ),
                ),
                children: [
                  field(
                    initial,
                    label('Fixtures JSON', 'JSON fixtures'),
                    lines: 6,
                  ),
                  const SelectableText(
                    '{"scoped":{"guildMember":{"10:20":{"xp":156,"level":2}}}}',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: running ? null : run,
                icon: running
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const AppIcon.fromMaterial(Icons.play_arrow),
                label: Text(label('Exécuter le test', 'Run test')),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(error!),
                ),
              if (result case final value?) ...[
                const SizedBox(height: 16),
                Text(
                  value['success'] == true && value['contract_passed'] != false
                      ? label('Test exécuté', 'Test executed')
                      : label('Test en échec', 'Test failed'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (value['error'] != null)
                  SelectableText(value['error'].toString()),
                Text(
                  label('Réponses simulées', 'Simulated responses'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final response in value['responses'] as List? ?? [])
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: responsePreview(response as Map),
                    ),
                  ),
                if (value['images'] case final Map images
                    when images.isNotEmpty) ...[
                  Text(
                    label('Images générées', 'Generated images'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final entry in images.entries)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key.toString()),
                            const SizedBox(height: 8),
                            if ((value['variables']
                                    as Map?)?['temp._canvasAttachment_${entry.key}']
                                case final String encoded)
                              Image.memory(
                                base64Decode(encoded),
                                width: 240,
                                height: 180,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => Text(
                                  label('Image illisible', 'Unreadable image'),
                                ),
                              ),
                            Text(
                              '${(entry.value as Map)['width']} × '
                              '${(entry.value as Map)['height']}',
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
                for (final key in [
                  'storage_before',
                  'storage_after',
                  'effects',
                  'logs',
                  'trace',
                  'diagnostics',
                  if (value['contract_checks'] != null) 'contract_checks',
                ])
                  ExpansionTile(
                    title: Text(switch (key) {
                      'storage_before' => label(
                        'Variables avant',
                        'Variables before',
                      ),
                      'storage_after' => label(
                        'Variables après',
                        'Variables after',
                      ),
                      'trace' => label('Étapes exécutées', 'Executed steps'),
                      'effects' => label('Appels simulés', 'Simulated calls'),
                      'contract_checks' => label(
                        'Vérifications du résultat',
                        'Result checks',
                      ),
                      _ => label('Diagnostics', 'Diagnostics'),
                    }),
                    children: [
                      SelectableText(
                        const JsonEncoder.withIndent('  ').convert(value[key]),
                      ),
                    ],
                  ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ),
  );
}
