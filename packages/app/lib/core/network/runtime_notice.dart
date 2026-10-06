import 'package:bot_creator/core/i18n/i18n.dart';

/// Ce qui empêche un démarrage, décrit SANS texte : la raison, et les valeurs à
/// intercaler.
///
/// POURQUOI une raison TYPÉE et pas un message tout fait : ce fichier est une
/// couche de résolution SANS `BuildContext`, donc sans langue. Quand il
/// assemblait le texte lui-même, il ne pouvait choisir qu'entre DEUX langues
/// lues sur l'appareil (`PlatformDispatcher.locale`) : les quatre autres langues
/// de l'application recevaient de l'ANGLAIS, et changer la langue DANS
/// l'application ne changeait rien à ces messages. La couche réseau rend donc
/// une raison ; l'écran, qui a les localisations, la traduit.
enum RuntimeNotice {
  runnerEmbeddedDesync,
  runnerEmbeddedRawError,
  localUnsupportedIosSignIn,
  signInRequired,
  sessionExpired,
  localUnsupportedIosConfigure,
  planLimit,
  invalidBotId,
  invalidBotIdDetails,
  serversNotReady,
  startupInProgress,
  startupFailed,
  startupFailedWithDetail,
  unreachable,
  requestFailed,
}

/// Une [RuntimeNotice] accompagnée des valeurs à intercaler (`null` là où
/// l'information n'existe pas — l'affichage ne montre alors rien).
class RuntimeNoticeMessage {
  const RuntimeNoticeMessage(
    this.notice, {
    this.detail,
    this.status,
    this.error,
  });

  final RuntimeNotice notice;
  final String? detail;
  final String? status;
  final String? error;
}

/// Traduit [message] avec les localisations de l'écran appelant.
///
/// POURQUOI la traduction vit ICI et pas dans l'écran : une seule phrase doit
/// servir partout, et les écrans qui démarrent un bot importent déjà ce fichier.
String resolveRuntimeNotice(
  AppLocalizations l10n,
  RuntimeNoticeMessage message,
) {
  final detail = message.detail ?? '';
  final status = message.status ?? '';
  final error = message.error ?? '';
  switch (message.notice) {
    case RuntimeNotice.localUnsupportedIosSignIn:
      return l10n.runtime_local_unsupported_ios_sign_in;
    case RuntimeNotice.signInRequired:
      return l10n.runtime_sign_in_required;
    case RuntimeNotice.sessionExpired:
      return l10n.runtime_session_expired;
    case RuntimeNotice.localUnsupportedIosConfigure:
      return l10n.runtime_local_unsupported_ios_configure;
    case RuntimeNotice.planLimit:
      return l10n.runtime_plan_limit;
    case RuntimeNotice.invalidBotId:
      return l10n.runtime_invalid_bot_id(error);
    case RuntimeNotice.invalidBotIdDetails:
      return l10n.runtime_invalid_bot_id_details(detail);
    case RuntimeNotice.serversNotReady:
      return l10n.runtime_servers_not_ready(error);
    case RuntimeNotice.startupInProgress:
      return l10n.runtime_startup_in_progress(status, error);
    case RuntimeNotice.startupFailed:
      return l10n.runtime_startup_failed(error);
    case RuntimeNotice.startupFailedWithDetail:
      return l10n.runtime_startup_failed_with_detail(detail, error);
    case RuntimeNotice.unreachable:
      return l10n.runtime_unreachable(error);
    case RuntimeNotice.requestFailed:
      return l10n.runtime_request_failed(error);
    case RuntimeNotice.runnerEmbeddedDesync:
      return l10n.runner_embedded_desync_detail;
    case RuntimeNotice.runnerEmbeddedRawError:
      // Donnée technique du runner (message d'erreur brut) : rien à traduire, et
      // lui coller une phrase traduite la déguiserait en explication.
      return error;
  }
}
