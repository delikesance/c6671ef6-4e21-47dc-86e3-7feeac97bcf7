import 'dart:convert';

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';

/// Compare the production native registry with the project's function catalogue.
/// Registration is not proof of official BDFD behavior or endpoint coverage.
/// The validation adapters prevent storage, network, and Discord operations.
void main() {
  final registered = BdfdEngine.validation().supportedFunctions;
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
