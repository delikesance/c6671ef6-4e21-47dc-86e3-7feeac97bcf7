// LE « LABORATOIRE DE FONCTIONS » : toute fonction enregistrée est trouvable,
// les cas de régression manquants sont visibles, et l'utilisateur peut tester
// sa propre source/ses fixtures pour une fonction. Partagé entre l'app (cas lus
// dans le moteur embarqué) et le Studio (cas servis par le runner).
library;

// Par chemin : liste de noms pure, sans dépendance au moteur.
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';
import 'command_sandbox_page.dart';
import 'sandbox_host.dart';

/// Every registered function is discoverable. Missing regression cases are
/// visible, and users can test their own source/fixtures for that function.
class SandboxFunctionsPage extends StatefulWidget {
  const SandboxFunctionsPage({super.key, required this.host});

  final SandboxHost host;

  @override
  State<SandboxFunctionsPage> createState() => _SandboxFunctionsPageState();
}

class _SandboxFunctionsPageState extends State<SandboxFunctionsPage> {
  String search = '';
  List<SandboxFunctionCaseInfo>? cases;
  Object? loadError;
  bool get french => Localizations.localeOf(context).languageCode == 'fr';
  String label(String fr, String en) => french ? fr : en;

  @override
  void initState() {
    super.initState();
    cases = widget.host.preloadedFunctionCases;
    if (cases == null) _load();
  }

  Future<void> _load() async {
    setState(() {
      cases = null;
      loadError = null;
    });
    try {
      final loaded = await widget.host.loadFunctionCases();
      if (mounted) setState(() => cases = loaded);
    } catch (e) {
      if (mounted) setState(() => loadError = e);
    }
  }

  String caseTitle(SandboxFunctionCaseInfo sample, int index) =>
      switch (sample.label) {
        'allowed' => label('Autorisé', 'Allowed'),
        'denied' => label('Refusé', 'Denied'),
        '' => label('Cas ${index + 1}', 'Case ${index + 1}'),
        _ => sample.label,
      };

  Future<void> openFunction(
    String name,
    List<SandboxFunctionCaseInfo> samples,
  ) async {
    SandboxFunctionCaseInfo? sample = samples.isEmpty ? null : samples.first;
    if (samples.length > 1) {
      sample = await showDialog<SandboxFunctionCaseInfo>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(label('Scénarios pour \$$name', 'Scenarios for \$$name')),
          children: [
            for (var index = 0; index < samples.length; index++)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(samples[index]),
                child: Text(caseTitle(samples[index], index)),
              ),
          ],
        ),
      );
      if (sample == null) return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CommandSandboxPage(
          host: widget.host,
          script: sample?.script ?? '\$$name[]',
          editableScript: true,
          initialScenario: sample == null
              ? const {}
              : {...sample.scenario, 'options': sample.options},
          expectedResponse: sample?.expected,
          expectedValues: sample?.expectedValues ?? const {},
        ),
      ),
    );
  }

  Widget _status() {
    final error = loadError;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SelectableText(
                describeSandboxError(context, error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: Text(label('Réessayer', 'Retry')),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    final loaded = cases;
    final names =
        allBdfdFunctions
            .where((name) => name.contains(search.toLowerCase()))
            .toList()
          ..sort();
    final covered = loaded?.map((sample) => sample.function).toSet().length;
    return Scaffold(
      appBar: AppBar(
        title: Text(label('Laboratoire de fonctions', 'Function laboratory')),
      ),
      body: SafeArea(
        child: loaded == null
            ? _status()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: label(
                          'Rechercher une fonction',
                          'Search functions',
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 10, right: 8),
                          child: AppIcon.fromMaterial(Icons.search, size: 18),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) => setState(() {
                        search = value;
                      }),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      label(
                        '$covered fonctions disposent de ${loaded.length} scénarios de régression. Les autres restent à vérifier.',
                        '$covered functions have ${loaded.length} regression scenarios. The others remain to be verified.',
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: names.length,
                      itemBuilder: (context, index) {
                        final name = names[index];
                        final samples = loaded
                            .where((c) => c.function == name)
                            .toList();
                        return ListTile(
                          title: Text(String.fromCharCode(36) + name),
                          subtitle: Text(
                            samples.isEmpty
                                ? label(
                                    'Cas à écrire · test manuel disponible',
                                    'Case needed · manual test available',
                                  )
                                : label(
                                    'Cas de test disponible',
                                    'Test case available',
                                  ),
                          ),
                          trailing: const AppIcon.fromMaterial(
                            Icons.science_outlined,
                          ),
                          onTap: () => openFunction(name, samples),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
