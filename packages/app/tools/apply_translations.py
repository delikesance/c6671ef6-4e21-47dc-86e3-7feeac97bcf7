#!/usr/bin/env python3
"""Insert missing ARB translations from untranslated_messages.json."""

from __future__ import annotations

import json
import re
from pathlib import Path

L10N_DIR = Path(__file__).resolve().parent.parent / "lib" / "core" / "i18n" / "l10n"
UNTRANSLATED = Path(__file__).resolve().parent.parent / "untranslated_messages.json"

# English source + @metadata copied from app_en.arb where needed.
METADATA: dict[str, dict] = {
    "cmd_block_editor_action_label": {
        "placeholders": {"index": {"type": "int"}}
    },
    "mobile_account_required_failed": {
        "placeholders": {"error": {"type": "String"}}
    },
    "mobile_login_failed": {
        "placeholders": {"error": {"type": "String"}}
    },
    "settings_alternative_login_current_email": {
        "placeholders": {"email": {"type": "String"}}
    },
    "subscriptions_hub_expires_at": {
        "placeholders": {
            "date": {"type": "String"},
            "time": {"type": "String"},
        }
    },
    "container_deploy_registry_detected": {
        "placeholders": {"host": {"type": "String"}}
    },
    "registry_credentials_delete_body": {
        "placeholders": {"label": {"type": "String"}}
    },
    "registry_credentials_delete_failed": {
        "placeholders": {"error": {"type": "String"}}
    },
    "registry_credentials_save_failed": {
        "placeholders": {"error": {"type": "String"}}
    },
    "container_detail_private_registry": {
        "placeholders": {
            "host": {"type": "String"},
            "username": {"type": "String"},
        }
    },
}

TRANSLATIONS: dict[str, dict[str, str]] = {
    "de": {
        "command_permissions_admin_warning": "Administrator ausgewählt: Dies umgeht andere Berechtigungsprüfungen.",
        "command_cloud_sync_failed_saved": "Auf Discord und lokal gespeichert. Cloud-Backup fehlgeschlagen.",
        "command_cloud_sync_retry": "Synchronisierung wiederholen",
        "cmd_block_editor_empty_title": "Noch keine Aktionen",
        "cmd_block_editor_empty_hint": "Füge einen Aktionsblock hinzu, um zu definieren, was dein Befehl beim Ausführen tut.",
        "cmd_block_editor_add_action": "Aktion hinzufügen",
        "cmd_block_editor_action_label": "Aktion {index}",
        "onboarding_command_learn": "So funktionieren Befehle",
        "onboarding_skip_confirm": "Onboarding überspringen",
        "onboarding_skip_dialog_desc": "Du kannst beim nächsten Mal dort weitermachen, wo du aufgehört hast, oder die Tour ganz überspringen.",
        "onboarding_skip_dialog_title": "Onboarding verlassen?",
        "mobile_account_required_title": "Anmelden",
        "mobile_account_required_body": "Melde dich mit Discord oder E-Mail an.",
        "mobile_account_required_feature_bots": "Bots aus der Cloud synchronisieren und wiederherstellen",
        "mobile_account_required_feature_hosted": "Gehostete Anwendungen bereitstellen und verwalten",
        "mobile_account_required_feature_recovery": "Alles nach Neuinstallation oder auf einem neuen Handy wiederherstellen",
        "mobile_account_required_failed": "Discord-Anmeldung fehlgeschlagen: {error}",
        "mobile_login_or_divider": "oder",
        "mobile_login_show_email": "Mit E-Mail anmelden",
        "mobile_login_hide_email": "E-Mail-Anmeldung ausblenden",
        "mobile_login_email_title": "Mit E-Mail anmelden",
        "mobile_login_email_hint": "Verwende die E-Mail und das Passwort deines Kontos.",
        "mobile_login_email": "E-Mail",
        "mobile_login_password": "Passwort",
        "mobile_login_submit": "Anmelden",
        "mobile_login_invalid_credentials": "Ungültige E-Mail oder ungültiges Passwort.",
        "mobile_login_failed": "Anmeldung fehlgeschlagen: {error}",
        "settings_alternative_login_title": "Alternative Anmeldung",
        "settings_alternative_login_desc": "Füge E-Mail und Passwort hinzu, um dich ohne Discord anzumelden.",
        "settings_alternative_login_current_email": "Aktuelle E-Mail: {email}",
        "settings_alternative_login_current_password": "Aktuelles Passwort",
        "settings_alternative_login_confirm_password": "Passwort bestätigen",
        "settings_alternative_login_update": "Anmeldedaten aktualisieren",
        "settings_add_credentials": "Anmeldedaten speichern",
        "settings_alternative_login_missing_fields": "E-Mail und Passwort sind erforderlich.",
        "settings_alternative_login_password_mismatch": "Passwörter stimmen nicht überein.",
        "settings_credentials_saved": "Alternative Anmeldung gespeichert.",
        "subscriptions_hub_title": "Abonnements",
        "subscriptions_hub_subtitle": "Verwalte deine Bot-Premium- und Gehostete-Anwendungen-Pläne.",
        "subscriptions_hub_open_settings": "Abonnements & Abrechnung",
        "subscriptions_hub_bot_premium_section": "Bot Premium",
        "subscriptions_hub_bot_premium_desc": "Entferne Werbung und schalte Premium-Funktionen für deine Discord-Bots frei.",
        "subscriptions_hub_hosted_section": "Gehostete Anwendungen",
        "subscriptions_hub_hosted_desc": "Führe Docker-Container in der Cloud aus, ohne Werbung anzusehen.",
        "subscriptions_hub_status_active": "Aktiv",
        "subscriptions_hub_status_inactive": "Nicht abonniert",
        "subscriptions_hub_subscribe": "Abonnieren",
        "subscriptions_hub_summary_both": "Bot Premium und Gehostete Anwendungen aktiv",
        "subscriptions_hub_summary_bot_only": "Bot Premium aktiv",
        "subscriptions_hub_summary_hosted_only": "Gehostete Anwendungen aktiv",
        "subscriptions_hub_summary_none": "Keine aktiven Abonnements",
        "subscriptions_hub_expires_at": "Verlängert bis {date} um {time}",
        "subscription_upgrade_annual": "Auf Jahresabo upgraden",
        "subscription_upgrade_two_apps": "Auf 2 Container upgraden",
        "subscription_manage_cancel_hint": "Zum Kündigen oder Ändern der Abrechnung nutze Abonnement verwalten — dies öffnet den App Store oder Google Play.",
        "container_detail_start_btn": "Starten",
        "container_detail_starting": "Wird gestartet...",
        "container_detail_started_ok": "Container wird gestartet",
        "container_detail_delete_title": "Container löschen",
        "container_detail_delete_confirm": "Dies löscht den Container dauerhaft aus der Datenbank und der Cloud. Dies kann nicht rückgängig gemacht werden.",
        "container_detail_delete_btn": "Löschen",
        "container_detail_deleted_ok": "Container gelöscht",
        "container_detail_stopped_hint": "Dieser Container ist heruntergefahren. Du kannst ihn neu starten, ohne Umgebungsvariablen erneut einzugeben.",
        "container_hosted_resume_with_time": "Du hast noch Hosting-Zeit auf diesem Container. Tippe auf Starten, um fortzufahren.",
        "container_deploy_private_image": "Privates Image",
        "container_deploy_private_image_hint": "Registry-Anmeldedaten angeben, um private Images zu pullen (z. B. GHCR).",
        "container_deploy_use_custom_credentials": "Eigene Anmeldedaten verwenden",
        "container_deploy_registry_profile": "Gespeichertes Registry-Profil",
        "container_deploy_registry_profile_none": "Profil auswählen",
        "container_deploy_registry_detected": "Registry: {host}",
        "container_deploy_save_registry_auth": "Anmeldedaten zur Wiederverwendung speichern",
        "container_deploy_registry_auth_required": "Benutzername und Passwort sind für private Images erforderlich.",
        "container_deploy_registry_profile_required": "Wähle ein gespeichertes Registry-Profil oder verwende eigene Anmeldedaten.",
        "registry_credentials_title": "Registry-Anmeldedaten",
        "registry_credentials_add": "Anmeldedaten hinzufügen",
        "registry_credentials_edit": "Anmeldedaten bearbeiten",
        "registry_credentials_manage": "Registry-Anmeldedaten verwalten",
        "registry_credentials_empty": "Noch keine gespeicherten Registry-Anmeldedaten.",
        "registry_credentials_label": "Bezeichnung",
        "registry_credentials_label_required": "Bezeichnung ist erforderlich",
        "registry_credentials_host": "Registry-Host",
        "registry_credentials_host_required": "Registry-Host ist erforderlich",
        "registry_credentials_username": "Benutzername",
        "registry_credentials_username_required": "Benutzername ist erforderlich",
        "registry_credentials_password": "Passwort oder Token",
        "registry_credentials_password_required": "Passwort oder Token ist erforderlich",
        "registry_credentials_password_hint": "Personal Access Token oder Registry-Passwort",
        "registry_credentials_password_edit_hint": "Leer lassen, um das aktuelle Passwort beizubehalten",
        "registry_credentials_ghcr_hint": "Für GHCR verwende ein GitHub-PAT mit read:packages-Bereich.",
        "registry_credentials_delete_title": "Anmeldedaten löschen?",
        "registry_credentials_delete_body": "\"{label}\" löschen? Dies kann nicht rückgängig gemacht werden.",
        "registry_credentials_deleted": "Registry-Anmeldedaten gelöscht",
        "registry_credentials_delete_failed": "Löschen der Anmeldedaten fehlgeschlagen: {error}",
        "registry_credentials_save_failed": "Speichern der Anmeldedaten fehlgeschlagen: {error}",
        "container_detail_private_registry": "Private Registry: {host} · {username}",
    },
    "fr": {
        "onboarding_command_learn": "Comprendre le fonctionnement des commandes",
        "onboarding_skip_confirm": "Passer l'introduction",
        "onboarding_skip_dialog_desc": "Vous pourrez reprendre là où vous vous êtes arrêté la prochaine fois, ou ignorer complètement la visite.",
        "onboarding_skip_dialog_title": "Quitter l'introduction ?",
        "mobile_account_required_feature_bots": "Synchroniser et restaurer vos bots depuis le cloud",
        "mobile_account_required_feature_hosted": "Déployer et gérer des applications hébergées",
        "mobile_account_required_feature_recovery": "Tout récupérer après réinstallation ou sur un nouveau téléphone",
        "mobile_account_required_failed": "Échec de la connexion Discord : {error}",
        "subscriptions_hub_title": "Abonnements",
        "subscriptions_hub_subtitle": "Consultez et gérez vos offres Bot Premium et applications hébergées.",
        "subscriptions_hub_open_settings": "Abonnements et facturation",
        "subscriptions_hub_bot_premium_section": "Bot Premium",
        "subscriptions_hub_bot_premium_desc": "Supprimez les publicités et débloquez les fonctionnalités premium pour vos bots Discord.",
        "subscriptions_hub_hosted_section": "Applications hébergées",
        "subscriptions_hub_hosted_desc": "Exécutez des conteneurs Docker dans le cloud sans regarder de publicités.",
        "subscriptions_hub_status_active": "Actif",
        "subscriptions_hub_status_inactive": "Non abonné",
        "subscriptions_hub_subscribe": "S'abonner",
        "subscriptions_hub_summary_both": "Bot Premium et applications hébergées actifs",
        "subscriptions_hub_summary_bot_only": "Bot Premium actif",
        "subscriptions_hub_summary_hosted_only": "Applications hébergées actives",
        "subscriptions_hub_summary_none": "Aucun abonnement actif",
        "subscriptions_hub_expires_at": "Renouvelé jusqu'au {date} à {time}",
        "subscription_upgrade_annual": "Passer à l'abonnement annuel",
        "subscription_upgrade_two_apps": "Passer à 2 conteneurs",
        "subscription_manage_cancel_hint": "Pour annuler ou modifier la facturation, utilisez Gérer l'abonnement — cela ouvre l'App Store ou Google Play.",
        "container_deploy_private_image": "Image privée",
        "container_deploy_private_image_hint": "Fournissez des identifiants de registre pour récupérer des images privées (ex. GHCR).",
        "container_deploy_use_custom_credentials": "Utiliser des identifiants personnalisés",
        "container_deploy_registry_profile": "Profil de registre enregistré",
        "container_deploy_registry_profile_none": "Sélectionner un profil",
        "container_deploy_registry_detected": "Registre : {host}",
        "container_deploy_save_registry_auth": "Enregistrer les identifiants pour réutilisation",
        "container_deploy_registry_auth_required": "Le nom d'utilisateur et le mot de passe sont requis pour les images privées.",
        "container_deploy_registry_profile_required": "Sélectionnez un profil de registre enregistré ou utilisez des identifiants personnalisés.",
        "registry_credentials_title": "Identifiants de registre",
        "registry_credentials_add": "Ajouter des identifiants",
        "registry_credentials_edit": "Modifier les identifiants",
        "registry_credentials_manage": "Gérer les identifiants de registre",
        "registry_credentials_empty": "Aucun identifiant de registre enregistré pour le moment.",
        "registry_credentials_label": "Libellé",
        "registry_credentials_label_required": "Le libellé est requis",
        "registry_credentials_host": "Hôte du registre",
        "registry_credentials_host_required": "L'hôte du registre est requis",
        "registry_credentials_username": "Nom d'utilisateur",
        "registry_credentials_username_required": "Le nom d'utilisateur est requis",
        "registry_credentials_password": "Mot de passe ou jeton",
        "registry_credentials_password_required": "Le mot de passe ou le jeton est requis",
        "registry_credentials_password_hint": "Jeton d'accès personnel ou mot de passe du registre",
        "registry_credentials_password_edit_hint": "Laisser vide pour conserver le mot de passe actuel",
        "registry_credentials_ghcr_hint": "Pour GHCR, utilisez un PAT GitHub avec la portée read:packages.",
        "registry_credentials_delete_title": "Supprimer les identifiants ?",
        "registry_credentials_delete_body": "Supprimer « {label} » ? Cette action est irréversible.",
        "registry_credentials_deleted": "Identifiants de registre supprimés",
        "registry_credentials_delete_failed": "Échec de la suppression des identifiants : {error}",
        "registry_credentials_save_failed": "Échec de l'enregistrement des identifiants : {error}",
        "container_detail_private_registry": "Registre privé : {host} · {username}",
    },
    "ja": {
        "command_cloud_sync_failed_saved": "Discordとローカルに保存しました。クラウドバックアップに失敗しました。",
        "command_cloud_sync_retry": "同期を再試行",
        "cmd_block_editor_empty_title": "アクションはまだありません",
        "cmd_block_editor_empty_hint": "アクションブロックを追加して、コマンド実行時の動作を定義します。",
        "cmd_block_editor_add_action": "アクションを追加",
        "cmd_block_editor_action_label": "アクション {index}",
        "onboarding_command_learn": "コマンドの仕組みを学ぶ",
        "onboarding_skip_confirm": "オンボーディングをスキップ",
        "onboarding_skip_dialog_desc": "次回は中断したところから再開するか、ツアーを完全にスキップできます。",
        "onboarding_skip_dialog_title": "オンボーディングを終了しますか？",
        "mobile_account_required_title": "サインイン",
        "mobile_account_required_body": "Discordまたはメールでサインインしてください。",
        "mobile_account_required_feature_bots": "クラウドからボットを同期・復元",
        "mobile_account_required_feature_hosted": "ホスト型アプリケーションのデプロイと管理",
        "mobile_account_required_feature_recovery": "再インストール後や新しい端末ですべてを復元",
        "mobile_account_required_failed": "Discordサインインに失敗しました: {error}",
        "mobile_login_or_divider": "または",
        "mobile_login_show_email": "メールでサインイン",
        "mobile_login_hide_email": "メールサインインを非表示",
        "mobile_login_email_title": "メールでサインイン",
        "mobile_login_email_hint": "アカウントに登録したメールとパスワードを使用してください。",
        "mobile_login_email": "メール",
        "mobile_login_password": "パスワード",
        "mobile_login_submit": "サインイン",
        "mobile_login_invalid_credentials": "メールまたはパスワードが無効です。",
        "mobile_login_failed": "サインインに失敗しました: {error}",
        "settings_alternative_login_title": "代替サインイン",
        "settings_alternative_login_desc": "Discordなしでサインインするためのメールとパスワードを追加します。",
        "settings_alternative_login_current_email": "現在のメール: {email}",
        "settings_alternative_login_current_password": "現在のパスワード",
        "settings_alternative_login_confirm_password": "パスワードを確認",
        "settings_alternative_login_update": "認証情報を更新",
        "settings_add_credentials": "認証情報を保存",
        "settings_alternative_login_missing_fields": "メールとパスワードは必須です。",
        "settings_alternative_login_password_mismatch": "パスワードが一致しません。",
        "settings_credentials_saved": "代替サインインを保存しました。",
        "subscriptions_hub_title": "サブスクリプション",
        "subscriptions_hub_subtitle": "Bot Premiumとホスト型アプリのプランを表示・管理します。",
        "subscriptions_hub_open_settings": "サブスクリプションと請求",
        "subscriptions_hub_bot_premium_section": "Bot Premium",
        "subscriptions_hub_bot_premium_desc": "広告を削除し、Discordボットのプレミアム機能を利用できます。",
        "subscriptions_hub_hosted_section": "ホスト型アプリケーション",
        "subscriptions_hub_hosted_desc": "広告を見ずにクラウドでDockerコンテナを実行します。",
        "subscriptions_hub_status_active": "有効",
        "subscriptions_hub_status_inactive": "未加入",
        "subscriptions_hub_subscribe": "登録する",
        "subscriptions_hub_summary_both": "Bot Premiumとホスト型アプリが有効",
        "subscriptions_hub_summary_bot_only": "Bot Premiumが有効",
        "subscriptions_hub_summary_hosted_only": "ホスト型アプリが有効",
        "subscriptions_hub_summary_none": "有効なサブスクリプションはありません",
        "subscriptions_hub_expires_at": "{date} {time} まで更新",
        "subscription_upgrade_annual": "年間プランにアップグレード",
        "subscription_upgrade_two_apps": "2コンテナにアップグレード",
        "subscription_manage_cancel_hint": "解約や請求の変更は「サブスクリプションを管理」から行ってください。App StoreまたはGoogle Playが開きます。",
        "container_detail_start_btn": "開始",
        "container_detail_starting": "開始中...",
        "container_detail_started_ok": "コンテナを開始しています",
        "container_detail_delete_title": "コンテナを削除",
        "container_detail_delete_confirm": "データベースとクラウドからコンテナが完全に削除されます。元に戻せません。",
        "container_detail_delete_btn": "削除",
        "container_detail_deleted_ok": "コンテナを削除しました",
        "container_detail_stopped_hint": "このコンテナは停止中です。環境変数を再入力せずに再起動できます。",
        "container_hosted_resume_with_time": "このコンテナにはまだホスティング時間が残っています。開始をタップして再開してください。",
        "container_deploy_private_image": "プライベートイメージ",
        "container_deploy_private_image_hint": "プライベートイメージを取得するにはレジストリ認証情報を入力してください（例: GHCR）。",
        "container_deploy_use_custom_credentials": "カスタム認証情報を使用",
        "container_deploy_registry_profile": "保存済みレジストリプロファイル",
        "container_deploy_registry_profile_none": "プロファイルを選択",
        "container_deploy_registry_detected": "レジストリ: {host}",
        "container_deploy_save_registry_auth": "認証情報を保存して再利用",
        "container_deploy_registry_auth_required": "プライベートイメージにはユーザー名とパスワードが必要です。",
        "container_deploy_registry_profile_required": "保存済みレジストリプロファイルを選択するか、カスタム認証情報を使用してください。",
        "registry_credentials_title": "レジストリ認証情報",
        "registry_credentials_add": "認証情報を追加",
        "registry_credentials_edit": "認証情報を編集",
        "registry_credentials_manage": "レジストリ認証情報を管理",
        "registry_credentials_empty": "保存されたレジストリ認証情報はまだありません。",
        "registry_credentials_label": "ラベル",
        "registry_credentials_label_required": "ラベルは必須です",
        "registry_credentials_host": "レジストリホスト",
        "registry_credentials_host_required": "レジストリホストは必須です",
        "registry_credentials_username": "ユーザー名",
        "registry_credentials_username_required": "ユーザー名は必須です",
        "registry_credentials_password": "パスワードまたはトークン",
        "registry_credentials_password_required": "パスワードまたはトークンは必須です",
        "registry_credentials_password_hint": "パーソナルアクセストークンまたはレジストリパスワード",
        "registry_credentials_password_edit_hint": "空白のままにすると現在のパスワードを保持します",
        "registry_credentials_ghcr_hint": "GHCRでは read:packages スコープのGitHub PATを使用してください。",
        "registry_credentials_delete_title": "認証情報を削除しますか？",
        "registry_credentials_delete_body": "「{label}」を削除しますか？元に戻せません。",
        "registry_credentials_deleted": "レジストリ認証情報を削除しました",
        "registry_credentials_delete_failed": "認証情報の削除に失敗しました: {error}",
        "registry_credentials_save_failed": "認証情報の保存に失敗しました: {error}",
        "container_detail_private_registry": "プライベートレジストリ: {host} · {username}",
    },
    "pt": {
        "command_cloud_sync_failed_saved": "Salvo no Discord e localmente. Falha no backup na nuvem.",
        "command_cloud_sync_retry": "Tentar sincronizar novamente",
        "cmd_block_editor_empty_title": "Nenhuma ação ainda",
        "cmd_block_editor_empty_hint": "Adicione um bloco de ação para definir o que seu comando faz ao ser executado.",
        "cmd_block_editor_add_action": "Adicionar ação",
        "cmd_block_editor_action_label": "Ação {index}",
        "onboarding_command_learn": "Aprenda como os comandos funcionam",
        "onboarding_skip_confirm": "Pular introdução",
        "onboarding_skip_dialog_desc": "Você pode continuar de onde parou na próxima vez ou pular o tour completamente.",
        "onboarding_skip_dialog_title": "Sair da introdução?",
        "mobile_account_required_title": "Entrar",
        "mobile_account_required_body": "Entre com Discord ou e-mail.",
        "mobile_account_required_feature_bots": "Sincronize e restaure seus bots da nuvem",
        "mobile_account_required_feature_hosted": "Implante e gerencie aplicações hospedadas",
        "mobile_account_required_feature_recovery": "Recupere tudo após reinstalar ou em um novo telefone",
        "mobile_account_required_failed": "Falha no login com Discord: {error}",
        "mobile_login_or_divider": "ou",
        "mobile_login_show_email": "Entrar com e-mail",
        "mobile_login_hide_email": "Ocultar login por e-mail",
        "mobile_login_email_title": "Entrar com e-mail",
        "mobile_login_email_hint": "Use o e-mail e a senha vinculados à sua conta.",
        "mobile_login_email": "E-mail",
        "mobile_login_password": "Senha",
        "mobile_login_submit": "Entrar",
        "mobile_login_invalid_credentials": "E-mail ou senha inválidos.",
        "mobile_login_failed": "Falha no login: {error}",
        "settings_alternative_login_title": "Login alternativo",
        "settings_alternative_login_desc": "Adicione um e-mail e senha para entrar sem Discord.",
        "settings_alternative_login_current_email": "E-mail atual: {email}",
        "settings_alternative_login_current_password": "Senha atual",
        "settings_alternative_login_confirm_password": "Confirmar senha",
        "settings_alternative_login_update": "Atualizar credenciais",
        "settings_add_credentials": "Salvar credenciais",
        "settings_alternative_login_missing_fields": "E-mail e senha são obrigatórios.",
        "settings_alternative_login_password_mismatch": "As senhas não coincidem.",
        "settings_credentials_saved": "Login alternativo salvo.",
        "subscriptions_hub_title": "Assinaturas",
        "subscriptions_hub_subtitle": "Veja e gerencie seus planos Bot Premium e aplicações hospedadas.",
        "subscriptions_hub_open_settings": "Assinaturas e cobrança",
        "subscriptions_hub_bot_premium_section": "Bot Premium",
        "subscriptions_hub_bot_premium_desc": "Remova anúncios e desbloqueie recursos premium para seus bots Discord.",
        "subscriptions_hub_hosted_section": "Aplicações hospedadas",
        "subscriptions_hub_hosted_desc": "Execute contêineres Docker na nuvem sem assistir anúncios.",
        "subscriptions_hub_status_active": "Ativo",
        "subscriptions_hub_status_inactive": "Não assinado",
        "subscriptions_hub_subscribe": "Assinar",
        "subscriptions_hub_summary_both": "Bot Premium e aplicações hospedadas ativos",
        "subscriptions_hub_summary_bot_only": "Bot Premium ativo",
        "subscriptions_hub_summary_hosted_only": "Aplicações hospedadas ativas",
        "subscriptions_hub_summary_none": "Nenhuma assinatura ativa",
        "subscriptions_hub_expires_at": "Renova até {date} às {time}",
        "subscription_upgrade_annual": "Atualizar para anual",
        "subscription_upgrade_two_apps": "Atualizar para 2 contêineres",
        "subscription_manage_cancel_hint": "Para cancelar ou alterar a cobrança, use Gerenciar assinatura — isso abre a App Store ou Google Play.",
        "container_detail_start_btn": "Iniciar",
        "container_detail_starting": "Iniciando...",
        "container_detail_started_ok": "Contêiner está iniciando",
        "container_detail_delete_title": "Excluir contêiner",
        "container_detail_delete_confirm": "Isso exclui permanentemente o contêiner do banco de dados e da nuvem. Não pode ser desfeito.",
        "container_detail_delete_btn": "Excluir",
        "container_detail_deleted_ok": "Contêiner excluído",
        "container_detail_stopped_hint": "Este contêiner está desligado. Você pode reiniciá-lo sem inserir as variáveis de ambiente novamente.",
        "container_hosted_resume_with_time": "Você ainda tem tempo de hospedagem neste contêiner. Toque em Iniciar para retomar.",
        "container_deploy_private_image": "Imagem privada",
        "container_deploy_private_image_hint": "Forneça credenciais do registry para baixar imagens privadas (ex.: GHCR).",
        "container_deploy_use_custom_credentials": "Usar credenciais personalizadas",
        "container_deploy_registry_profile": "Perfil de registry salvo",
        "container_deploy_registry_profile_none": "Selecionar um perfil",
        "container_deploy_registry_detected": "Registry: {host}",
        "container_deploy_save_registry_auth": "Salvar credenciais para reutilização",
        "container_deploy_registry_auth_required": "Nome de usuário e senha são obrigatórios para imagens privadas.",
        "container_deploy_registry_profile_required": "Selecione um perfil de registry salvo ou use credenciais personalizadas.",
        "registry_credentials_title": "Credenciais do registry",
        "registry_credentials_add": "Adicionar credenciais",
        "registry_credentials_edit": "Editar credenciais",
        "registry_credentials_manage": "Gerenciar credenciais do registry",
        "registry_credentials_empty": "Nenhuma credencial de registry salva ainda.",
        "registry_credentials_label": "Rótulo",
        "registry_credentials_label_required": "O rótulo é obrigatório",
        "registry_credentials_host": "Host do registry",
        "registry_credentials_host_required": "O host do registry é obrigatório",
        "registry_credentials_username": "Nome de usuário",
        "registry_credentials_username_required": "O nome de usuário é obrigatório",
        "registry_credentials_password": "Senha ou token",
        "registry_credentials_password_required": "Senha ou token é obrigatório",
        "registry_credentials_password_hint": "Token de acesso pessoal ou senha do registry",
        "registry_credentials_password_edit_hint": "Deixe em branco para manter a senha atual",
        "registry_credentials_ghcr_hint": "Para GHCR, use um PAT do GitHub com escopo read:packages.",
        "registry_credentials_delete_title": "Excluir credenciais?",
        "registry_credentials_delete_body": "Excluir \"{label}\"? Isso não pode ser desfeito.",
        "registry_credentials_deleted": "Credenciais do registry excluídas",
        "registry_credentials_delete_failed": "Falha ao excluir credenciais: {error}",
        "registry_credentials_save_failed": "Falha ao salvar credenciais: {error}",
        "container_detail_private_registry": "Registry privado: {host} · {username}",
    },
    "tr": {
        "command_cloud_sync_failed_saved": "Discord ve yerel olarak kaydedildi. Bulut yedekleme başarısız oldu.",
        "command_cloud_sync_retry": "Senkronizasyonu yeniden dene",
        "cmd_block_editor_empty_title": "Henüz eylem yok",
        "cmd_block_editor_empty_hint": "Komutunuz çalıştığında ne yapacağını tanımlamak için bir eylem bloğu ekleyin.",
        "cmd_block_editor_add_action": "Eylem ekle",
        "cmd_block_editor_action_label": "Eylem {index}",
        "onboarding_command_learn": "Komutların nasıl çalıştığını öğrenin",
        "onboarding_skip_confirm": "Tanıtımı atla",
        "onboarding_skip_dialog_desc": "Bir sonraki sefer kaldığınız yerden devam edebilir veya turu tamamen atlayabilirsiniz.",
        "onboarding_skip_dialog_title": "Tanıtımdan çıkılsın mı?",
        "mobile_account_required_title": "Giriş yap",
        "mobile_account_required_body": "Discord veya e-posta ile giriş yapın.",
        "mobile_account_required_feature_bots": "Botlarınızı buluttan senkronize edin ve geri yükleyin",
        "mobile_account_required_feature_hosted": "Barındırılan uygulamaları dağıtın ve yönetin",
        "mobile_account_required_feature_recovery": "Yeniden yüklemeden veya yeni telefonda her şeyi kurtarın",
        "mobile_account_required_failed": "Discord girişi başarısız: {error}",
        "mobile_login_or_divider": "veya",
        "mobile_login_show_email": "E-posta ile giriş yap",
        "mobile_login_hide_email": "E-posta girişini gizle",
        "mobile_login_email_title": "E-posta ile giriş yap",
        "mobile_login_email_hint": "Hesabınıza bağlı e-posta ve şifreyi kullanın.",
        "mobile_login_email": "E-posta",
        "mobile_login_password": "Şifre",
        "mobile_login_submit": "Giriş yap",
        "mobile_login_invalid_credentials": "Geçersiz e-posta veya şifre.",
        "mobile_login_failed": "Giriş başarısız: {error}",
        "settings_alternative_login_title": "Alternatif giriş",
        "settings_alternative_login_desc": "Discord olmadan giriş yapmak için e-posta ve şifre ekleyin.",
        "settings_alternative_login_current_email": "Mevcut e-posta: {email}",
        "settings_alternative_login_current_password": "Mevcut şifre",
        "settings_alternative_login_confirm_password": "Şifreyi onayla",
        "settings_alternative_login_update": "Kimlik bilgilerini güncelle",
        "settings_add_credentials": "Kimlik bilgilerini kaydet",
        "settings_alternative_login_missing_fields": "E-posta ve şifre gereklidir.",
        "settings_alternative_login_password_mismatch": "Şifreler eşleşmiyor.",
        "settings_credentials_saved": "Alternatif giriş kaydedildi.",
        "subscriptions_hub_title": "Abonelikler",
        "subscriptions_hub_subtitle": "Bot Premium ve barındırılan uygulama planlarınızı görüntüleyin ve yönetin.",
        "subscriptions_hub_open_settings": "Abonelikler ve faturalandırma",
        "subscriptions_hub_bot_premium_section": "Bot Premium",
        "subscriptions_hub_bot_premium_desc": "Reklamları kaldırın ve Discord botlarınız için premium özelliklerin kilidini açın.",
        "subscriptions_hub_hosted_section": "Barındırılan uygulamalar",
        "subscriptions_hub_hosted_desc": "Reklam izlemeden bulutta Docker konteynerleri çalıştırın.",
        "subscriptions_hub_status_active": "Aktif",
        "subscriptions_hub_status_inactive": "Abone değil",
        "subscriptions_hub_subscribe": "Abone ol",
        "subscriptions_hub_summary_both": "Bot Premium ve barındırılan uygulamalar aktif",
        "subscriptions_hub_summary_bot_only": "Bot Premium aktif",
        "subscriptions_hub_summary_hosted_only": "Barındırılan uygulamalar aktif",
        "subscriptions_hub_summary_none": "Aktif abonelik yok",
        "subscriptions_hub_expires_at": "{date} {time} tarihine kadar yenilenir",
        "subscription_upgrade_annual": "Yıllık plana yükselt",
        "subscription_upgrade_two_apps": "2 konteynere yükselt",
        "subscription_manage_cancel_hint": "İptal etmek veya faturalandırmayı değiştirmek için Aboneliği yönet'i kullanın — App Store veya Google Play açılır.",
        "container_detail_start_btn": "Başlat",
        "container_detail_starting": "Başlatılıyor...",
        "container_detail_started_ok": "Konteyner başlatılıyor",
        "container_detail_delete_title": "Konteyneri sil",
        "container_detail_delete_confirm": "Bu, konteyneri veritabanından ve buluttan kalıcı olarak siler. Geri alınamaz.",
        "container_detail_delete_btn": "Sil",
        "container_detail_deleted_ok": "Konteyner silindi",
        "container_detail_stopped_hint": "Bu konteyner kapatıldı. Ortam değişkenlerini yeniden girmeden yeniden başlatabilirsiniz.",
        "container_hosted_resume_with_time": "Bu konteynerde hâlâ barındırma süreniz var. Devam etmek için Başlat'a dokunun.",
        "container_deploy_private_image": "Özel görüntü",
        "container_deploy_private_image_hint": "Özel görüntüleri çekmek için kayıt defteri kimlik bilgilerini girin (örn. GHCR).",
        "container_deploy_use_custom_credentials": "Özel kimlik bilgileri kullan",
        "container_deploy_registry_profile": "Kayıtlı kayıt defteri profili",
        "container_deploy_registry_profile_none": "Profil seç",
        "container_deploy_registry_detected": "Kayıt defteri: {host}",
        "container_deploy_save_registry_auth": "Kimlik bilgilerini yeniden kullanım için kaydet",
        "container_deploy_registry_auth_required": "Özel görüntüler için kullanıcı adı ve şifre gereklidir.",
        "container_deploy_registry_profile_required": "Kayıtlı bir kayıt defteri profili seçin veya özel kimlik bilgileri kullanın.",
        "registry_credentials_title": "Kayıt defteri kimlik bilgileri",
        "registry_credentials_add": "Kimlik bilgisi ekle",
        "registry_credentials_edit": "Kimlik bilgilerini düzenle",
        "registry_credentials_manage": "Kayıt defteri kimlik bilgilerini yönet",
        "registry_credentials_empty": "Henüz kayıtlı kayıt defteri kimlik bilgisi yok.",
        "registry_credentials_label": "Etiket",
        "registry_credentials_label_required": "Etiket gereklidir",
        "registry_credentials_host": "Kayıt defteri ana bilgisayarı",
        "registry_credentials_host_required": "Kayıt defteri ana bilgisayarı gereklidir",
        "registry_credentials_username": "Kullanıcı adı",
        "registry_credentials_username_required": "Kullanıcı adı gereklidir",
        "registry_credentials_password": "Şifre veya jeton",
        "registry_credentials_password_required": "Şifre veya jeton gereklidir",
        "registry_credentials_password_hint": "Kişisel erişim jetonu veya kayıt defteri şifresi",
        "registry_credentials_password_edit_hint": "Mevcut şifreyi korumak için boş bırakın",
        "registry_credentials_ghcr_hint": "GHCR için read:packages kapsamına sahip bir GitHub PAT kullanın.",
        "registry_credentials_delete_title": "Kimlik bilgileri silinsin mi?",
        "registry_credentials_delete_body": "\"{label}\" silinsin mi? Bu işlem geri alınamaz.",
        "registry_credentials_deleted": "Kayıt defteri kimlik bilgileri silindi",
        "registry_credentials_delete_failed": "Kimlik bilgileri silinemedi: {error}",
        "registry_credentials_save_failed": "Kimlik bilgileri kaydedilemedi: {error}",
        "container_detail_private_registry": "Özel kayıt defteri: {host} · {username}",
    },
}


def key_exists(content: str, key: str) -> bool:
    return re.search(rf'^\s*"{re.escape(key)}"\s*:', content, re.MULTILINE) is not None


def format_metadata_block(key: str) -> list[str]:
    if key not in METADATA:
        return []
    lines = [f'  "@{key}": {{']
    lines.append('    "placeholders": {')
    placeholders = METADATA[key]["placeholders"]
    ph_items = list(placeholders.items())
    for i, (ph_key, ph_val) in enumerate(ph_items):
        lines.append(f'      "{ph_key}": {{')
        for meta_key, meta_val in ph_val.items():
            lines.append(f'        "{meta_key}": "{meta_val}"')
        suffix = "," if i < len(ph_items) - 1 else ""
        lines.append(f"      }}{suffix}")
    lines.append("    }")
    lines.append("  }")
    return lines


def format_entry(key: str, value: str) -> str:
    entry = f'  "{key}": {json.dumps(value, ensure_ascii=False)}'
    meta = format_metadata_block(key)
    if not meta:
        return entry
    return entry + ",\n" + "\n".join(meta)


FIRST_ADDED_KEY = {
    "de": "command_permissions_admin_warning",
    "fr": "onboarding_command_learn",
    "ja": "command_cloud_sync_failed_saved",
    "pt": "command_cloud_sync_failed_saved",
    "tr": "command_cloud_sync_failed_saved",
}


def truncate_bad_append(locale: str) -> None:
    arb_path = L10N_DIR / f"app_{locale}.arb"
    content = arb_path.read_text(encoding="utf-8")
    key = FIRST_ADDED_KEY[locale]
    pattern = rf',?\n  "{re.escape(key)}":'
    match = re.search(pattern, content)
    if not match:
        return
    content = content[: match.start()].rstrip()
    if content.endswith(","):
        content = content[:-1]
    arb_path.write_text(content + "\n}\n", encoding="utf-8")


def main() -> None:
    missing = json.loads(UNTRANSLATED.read_text(encoding="utf-8"))
    for locale in missing:
        truncate_bad_append(locale)
    for locale, keys in missing.items():
        arb_path = L10N_DIR / f"app_{locale}.arb"
        content = arb_path.read_text(encoding="utf-8")
        to_add: list[str] = []
        for key in keys:
            if key_exists(content, key):
                continue
            translation = TRANSLATIONS.get(locale, {}).get(key)
            if not translation:
                raise KeyError(f"Missing translation for {locale}.{key}")
            to_add.append(format_entry(key, translation))
        if not to_add:
            print(f"{locale}: nothing to add")
            continue
        block = ",\n".join(to_add)
        content = content.rstrip()
        if content.endswith("}"):
            content = content[:-1].rstrip()
            if not content.endswith(","):
                content += ","
            content += "\n" + block + "\n}"
        arb_path.write_text(content + "\n", encoding="utf-8")
        print(f"{locale}: added {len(to_add)} keys")


if __name__ == "__main__":
    main()
