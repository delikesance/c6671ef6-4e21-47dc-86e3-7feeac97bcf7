import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/app_update/logic/app_update_models.dart';
import 'package:bot_creator/features/app_update/logic/app_update_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Version de l'APPLICATION et mises à jour.
///
/// Pourquoi ces deux cartes ne vivent plus dans les réglages d'un bot : elles ne
/// parlent pas du bot. Elles affichent la version installée de l'application, la
/// version du runner et la recherche de mise à jour — des informations GLOBALES,
/// qui n'avaient rien à faire dans les réglages d'un bot en particulier (on y
/// arrivait par un bot, et le même contenu réapparaissait pour chaque bot).
///
/// Briques rendues ici, dans l'ordre :
///   * « Version » : version applicative (package) et version du runner connecté,
///     ou l'état « non connecté » — jamais une valeur inventée ;
///   * « Mises à jour » : la version installée est TOUJOURS affichée, la
///     vérification reste un geste explicite (aucune requête store au simple
///     affichage), et le retour est honnête : à jour / mise à jour disponible /
///     vérification impossible.
///
/// Auto-portante (elle charge elle-même ses informations) : l'écran qui l'accueille
/// n'a rien à lui fournir, donc il n'y a qu'un endroit à corriger.
class AppVersionAndUpdatesCard extends StatefulWidget {
  const AppVersionAndUpdatesCard({super.key});

  @override
  State<AppVersionAndUpdatesCard> createState() =>
      _AppVersionAndUpdatesCardState();
}

class _AppVersionAndUpdatesCardState extends State<AppVersionAndUpdatesCard> {
  String _appVersion = '';
  String _appVersionName = '';
  String _appBuildNumber = '';
  bool _isCheckingUpdate = false;
  AppUpdateCheckResult? _updateResult;
  String? _updateCheckMessage;
  String? _runnerVersion;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    final info = await PackageInfo.fromPlatform();
    final client = await RunnerSettings.createClient();
    final rv = await client?.getRunnerVersion();
    if (!mounted) return;
    setState(() {
      _appVersion = '${info.version}+${info.buildNumber}';
      _appVersionName = info.version;
      _appBuildNumber = info.buildNumber;
      _runnerVersion = rv;
    });
  }

  /// Vérification demandée par l'utilisateur : elle court-circuite la
  /// politique de relance (`force: true`), c'est un geste explicite.
  Future<void> _checkForAppUpdate() async {
    if (mounted) setState(() => _isCheckingUpdate = true);
    final result = await AppUpdateService.check(force: true);
    if (!mounted) return;
    setState(() {
      _isCheckingUpdate = false;
      _updateResult = result;
      _updateCheckMessage = _updateMessageFor(result);
    });
  }

  /// Retour honnête : on ne dit jamais « à jour » quand on n'a pas pu lire le store.
  String _updateMessageFor(AppUpdateCheckResult result) {
    switch (result.status) {
      case AppUpdateCheckStatus.updateAvailable:
        return context.tr.settings_app_update_available(
          result.availableVersion ?? '',
        );
      case AppUpdateCheckStatus.upToDate:
        return context.tr.settings_app_update_up_to_date;
      case AppUpdateCheckStatus.unavailable:
        return context.tr.settings_app_update_unavailable;
      case AppUpdateCheckStatus.notSupported:
        return context.tr.settings_app_update_unsupported;
      case AppUpdateCheckStatus.throttled:
        // Impossible ici (`force: true`), mais le switch doit rester exhaustif.
        return context.tr.settings_app_update_unavailable;
    }
  }

  Future<void> _launchAppUpdate() async {
    final result = _updateResult;
    if (result == null) return;
    final outcome = await AppUpdateService.launchUpdate(result);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case AppUpdateLaunchOutcome.flexibleStarted:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr.app_update_download_started)),
        );
      case AppUpdateLaunchOutcome.flexibleCompleted:
      case AppUpdateLaunchOutcome.storeOpened:
      case AppUpdateLaunchOutcome.declined:
        // Rien à dire : l'app se relance pour installer, ou l'utilisateur a
        // explicitement refusé.
        break;
      case AppUpdateLaunchOutcome.failed:
        messenger.showSnackBar(
          SnackBar(content: Text(context.tr.app_update_store_open_failed)),
        );
    }
  }

  Future<void> _openStoreListing() async {
    final uri = _updateResult?.storeUri;
    if (uri == null) return;
    final opened = await AppUpdateService.openStore(uri);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr.app_update_store_open_failed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.settings_version_title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const AppIcon.fromMaterial(Icons.phone_android, size: 18),
                    const SizedBox(width: 8),
                    Text(context.tr.settings_app_version_value(_appVersion)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const AppIcon.fromMaterial(Icons.dns_outlined, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.tr.settings_runner_version_value(
                        _runnerVersion ??
                            context.tr.settings_runner_not_connected,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Mises à jour : la version installée est TOUJOURS affichée, la
        // vérification est un bouton explicite. Aucune requête store au simple
        // affichage de la page, et le retour est honnête : à jour / mise à jour
        // disponible / vérification impossible.
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.settings_app_update_title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const AppIcon.fromMaterial(
                      Icons.system_update_alt,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr.settings_app_update_installed_version(
                          _appVersionName,
                          _appBuildNumber,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_updateCheckMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _updateCheckMessage!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isCheckingUpdate ? null : _checkForAppUpdate,
                    icon: _isCheckingUpdate
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const AppIcon.fromMaterial(Icons.refresh),
                    label: Text(
                      _isCheckingUpdate
                          ? context.tr.settings_app_update_checking
                          : context.tr.settings_app_update_check_button,
                    ),
                  ),
                ),
                if (_updateResult != null && _updateResult!.isUpdateAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _launchAppUpdate,
                        icon: const AppIcon.fromMaterial(
                          Icons.download_for_offline,
                        ),
                        label: Text(context.tr.app_update_update_now),
                      ),
                    ),
                  )
                else if (_updateResult?.status ==
                        AppUpdateCheckStatus.unavailable &&
                    _updateResult?.storeUri != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openStoreListing,
                        icon: const AppIcon.fromMaterial(Icons.open_in_new),
                        label: Text(context.tr.settings_app_update_open_store),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
