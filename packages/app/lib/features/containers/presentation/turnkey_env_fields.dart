import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/logic/turnkey_env_payload.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Un contrôleur par variable À SAISIR déclarée par le template, pré-rempli avec
/// la valeur par défaut du template. Le token Discord n'en a pas : il garde le
/// champ de saisie dédié de l'écran de déploiement (partagé avec le sélecteur de
/// bot local).
Map<String, TextEditingController> createTurnkeyEnvControllers(
  HostedAppTemplate template,
) {
  final controllers = <String, TextEditingController>{};
  for (final field in turnkeyUserEnvFields(template)) {
    controllers[field.key.trim()] = TextEditingController(
      text: initialTurnkeyEnvValue(field),
    );
  }
  return controllers;
}

/// Section du formulaire de déploiement : un champ de saisie par variable
/// déclarée par le template clé en main. Aucun nom de variable n'est supposé par
/// l'app — elle rend exactement ce que le schéma du template déclare.
///
/// Sans [controllers] fournis, la section crée (et libère) les siens, pré-remplis
/// avec les valeurs par défaut du template.
class TurnkeyEnvFieldsSection extends StatefulWidget {
  const TurnkeyEnvFieldsSection({
    super.key,
    required this.template,
    this.controllers,
  });

  final HostedAppTemplate template;

  /// Contrôleurs par clé de variable (voir [createTurnkeyEnvControllers]) quand
  /// l'écran appelant veut lire les valeurs saisies.
  final Map<String, TextEditingController>? controllers;

  @override
  State<TurnkeyEnvFieldsSection> createState() =>
      _TurnkeyEnvFieldsSectionState();
}

class _TurnkeyEnvFieldsSectionState extends State<TurnkeyEnvFieldsSection> {
  Map<String, TextEditingController>? _ownedControllers;

  Map<String, TextEditingController> get _controllers {
    final provided = widget.controllers;
    if (provided != null) return provided;
    return _ownedControllers ??= createTurnkeyEnvControllers(widget.template);
  }

  @override
  void didUpdateWidget(covariant TurnkeyEnvFieldsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provided = widget.controllers;
    if (provided == null && oldWidget.template != widget.template) {
      _disposeOwnedControllers();
    }
  }

  @override
  void dispose() {
    _disposeOwnedControllers();
    super.dispose();
  }

  void _disposeOwnedControllers() {
    final owned = _ownedControllers;
    if (owned == null) return;
    for (final controller in owned.values) {
      controller.dispose();
    }
    _ownedControllers = null;
  }

  @override
  Widget build(BuildContext context) {
    final fields = turnkeyUserEnvFields(widget.template);
    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final field in fields)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TurnkeyEnvFieldTile(
              field: field,
              controller: _controllers[field.key.trim()],
            ),
          ),
      ],
    );
  }
}

/// Un champ de saisie pour UNE variable déclarée par le template : pré-rempli
/// avec sa valeur par défaut, masqué s'il est `secret`, en lecture seule s'il est
/// verrouillé (valeur imposée par le serveur).
class TurnkeyEnvFieldTile extends StatefulWidget {
  const TurnkeyEnvFieldTile({super.key, required this.field, this.controller});

  final HostedAppEnvField field;

  /// Contrôleur fourni par l'écran appelant. À défaut, le champ crée le sien
  /// (pré-rempli) et le libère.
  final TextEditingController? controller;

  @override
  State<TurnkeyEnvFieldTile> createState() => _TurnkeyEnvFieldTileState();
}

class _TurnkeyEnvFieldTileState extends State<TurnkeyEnvFieldTile> {
  TextEditingController? _ownedController;
  late bool _obscure = widget.field.secret;

  TextEditingController get _controller {
    final provided = widget.controller;
    if (provided != null) return provided;
    return _ownedController ??= TextEditingController(
      text: initialTurnkeyEnvValue(widget.field),
    );
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final field = widget.field;
    final label = field.displayLabel;

    if (field.isLocked) {
      return TextFormField(
        controller: _controller,
        enabled: false,
        obscureText: field.secret,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const AppIcon.fromMaterial(Icons.lock_outline),
          helperText: tr.container_deploy_env_server_provided,
        ),
      );
    }

    return TextFormField(
      controller: _controller,
      obscureText: _obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: AppIcon.fromMaterial(
          field.secret ? Icons.key_outlined : Icons.tune,
        ),
        suffixIcon: field.secret
            ? IconButton(
                icon: AppIcon.fromMaterial(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
      ),
      validator: (value) {
        if (!field.required) return null;
        if (value == null || value.trim().isEmpty) {
          return tr.container_deploy_env_field_required(label);
        }
        return null;
      },
    );
  }
}
