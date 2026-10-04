import 'dart:convert';

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_functions.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';

/// Compare the production native registry with the project's function catalogue.
/// Registration is not proof of official BDFD behavior or endpoint coverage.
/// The validation adapters prevent storage, network, and Discord operations.
///
/// The hidden `bc_*` functions that run visual blocks on the native engine are
/// not part of the script registry (a BDFD script cannot call them); they are
/// added here so the audit lists them as registered outside the catalogue.
void main() {
  final registered = {
    ...BdfdEngine.validation().supportedFunctions,
    ...bdfdVisualFunctionNames(),
  };
  final known = registered.intersection(allBdfdFunctions).toList()..sort();
  final missing = allBdfdFunctions.difference(registered).toList()..sort();
  final extensions = registered.difference(allBdfdFunctions).toList()..sort();
  print(
    const JsonEncoder.withIndent('  ').convert({
      'scope':
          'Production registry registration only; no behavior verification.',
      'catalogueCount': allBdfdFunctions.length,
      'registeredCount': registered.length,
      'registeredCatalogueCount': known.length,
      'unregisteredCatalogueCount': missing.length,
      'registeredCatalogueFunctions': known,
      'unregisteredCatalogueFunctions': missing,
      'registeredOutsideCatalogue': extensions,
    }),
  );
}
