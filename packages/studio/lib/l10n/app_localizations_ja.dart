// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class StudioLocalizationsJa extends StudioLocalizations {
  StudioLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get navHome => 'ホーム';

  @override
  String get navDocs => 'ドキュメント';

  @override
  String get navSettings => '設定';

  @override
  String get navBack => '戻る';

  @override
  String get navCommands => 'コマンド';

  @override
  String get navCommandsShort => 'Cmd';

  @override
  String get navCopilot => 'AIコパイロット';

  @override
  String get navFlows => 'フロー';

  @override
  String get navVars => '変数';

  @override
  String get navSched => 'スケジュール';

  @override
  String get navHooks => '受信Webhook';

  @override
  String get navEmojis => '絵文字';

  @override
  String get navTeam => 'Team';

  @override
  String get navGuilds => 'サーバー';

  @override
  String get navDashboard => 'ダッシュボード';

  @override
  String get navModules => 'Modules';

  @override
  String get navBeginner => 'ビギナーモード';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesSearch => '検索';

  @override
  String get modulesGroupCreate => '作成';

  @override
  String get modulesGroupAutomation => '自動化';

  @override
  String get modulesGroupManagement => '管理';

  @override
  String get modulesGroupTools => 'Tools';

  @override
  String get modulesWorkflows => 'ワークフロー';

  @override
  String get modulesVariables => 'グローバル変数';

  @override
  String get modulesEmojis => '絵文字';

  @override
  String get modulesScheduler => 'スケジューラー';

  @override
  String get modulesDescWorkflows => 'アクションやイベントを自動化';

  @override
  String get modulesDescVariables => 'すべてのコマンドで共有';

  @override
  String get modulesDescEmojis => 'ボットのアプリケーション絵文字';

  @override
  String get modulesDescScheduler => 'X 分ごとにワークフローを実行';

  @override
  String get modulesDescHooks => 'ワークフローにルーティングされる HTTP 呼び出し';

  @override
  String get modulesDescTeam => 'コラボレーターとチームチャット';

  @override
  String get modulesDescGuilds => 'ボットが参加しているサーバー';

  @override
  String get modulesDescDashboard => 'Command usage over 24 h, 7 d, 30 d';

  @override
  String get modulesDescCopilot => 'Assistant to build your commands';

  @override
  String get beginnerOnHint => '基本タブのみ表示';

  @override
  String get beginnerOffHint => 'すべての機能を表示';

  @override
  String get commonRetry => '再試行';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonRefresh => '更新';

  @override
  String get commonSend => 'Send';

  @override
  String get statusOnline => 'オンライン';

  @override
  String get statusStopped => '停止済み';

  @override
  String get loadError => '読み込みエラー';

  @override
  String get comingSoonBody =>
      'This section is coming soon to Studio. It is still available in the Bot Creator app.';

  @override
  String get comingSoonShort => 'Coming soon to Studio.';

  @override
  String get appTitle => 'Bot Creator Studio';

  @override
  String get loginSubtitle =>
      'Sign in with Discord to access your bots. Studio always requires a valid sign-in.';

  @override
  String get loginDiscord => 'Discordで接続';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSignedIn => 'Signed in with Discord';

  @override
  String accountSignedInAs(String name) {
    return 'Signed in with Discord: $name';
  }

  @override
  String get accountPlanPremium => 'Premium plan';

  @override
  String get accountPlanFree =>
      'Free plan: manage your subscription from the mobile app.';

  @override
  String get accountSignOut => 'サインアウト';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get languageSystem => 'システム';

  @override
  String get botsOverline => 'My projects';

  @override
  String get botsTitle => 'マイボット';

  @override
  String get botsCreate => 'ボットを作成';

  @override
  String get botsManage => '管理';

  @override
  String get botStop => '停止';

  @override
  String get botStart => 'ボット起動';

  @override
  String get botsEmptyTitle => 'まだアプリがありません。';

  @override
  String get botsEmptyHint =>
      'Create your first bot from the Bot Creator app: it will show up here.';

  @override
  String get hostingIncludedTitle => 'ホスティング込み';

  @override
  String get hostingIncludedValue => 'サブスクリプションで無制限';

  @override
  String get hostingRemainingTitle => '残り時間';

  @override
  String get hostingExpired => 'ホスティングの有効期限が切れました';

  @override
  String get hostingSessionActive => 'アクティブなセッション';

  @override
  String get hostingSessionActiveOnline => 'アクティブなセッション（オンライン）';

  @override
  String get hostingPreservedTitle => '保持される時間';

  @override
  String hostingReserve(String time) {
    return 'Reserve: $time';
  }

  @override
  String get hostingReserveAvailable => '一時停止中の時間（一時停止）';

  @override
  String get hostingPreservedDetail => 'ボットが停止している間、時間は保持されます。';

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createBotToken => 'Discord bot token';

  @override
  String get createBotTokenHint =>
      'It is sent over HTTPS to the Bot Creator server and never kept in the browser.';

  @override
  String createBotValidNamed(String name) {
    return 'Valid token: $name';
  }

  @override
  String createBotValidId(String id) {
    return 'Valid token (ID $id)';
  }

  @override
  String get createBotSamplePing => 'サンプル/pingコマンドを追加';

  @override
  String get createBotBusy =>
      'Creating the bot: this can take up to two minutes. Do not close this page.';

  @override
  String get createBotVerify => 'Check token';

  @override
  String get createBotSubmit => 'Create bot';

  @override
  String get createBotSyncBusy =>
      'This bot is already being synchronized. Please wait a few minutes.';

  @override
  String get createBotNoId => 'Could not read the bot ID from this token.';

  @override
  String get overviewLogs => 'Logs';

  @override
  String overviewLogsUnavailable(String error) {
    return 'Logs unavailable: $error';
  }

  @override
  String get overviewNoLogs => 'No logs yet.';

  @override
  String get commandsSearch => 'コマンドを検索...';

  @override
  String get commandsEmpty =>
      'No commands yet. Create one from the Bot Creator app.';

  @override
  String get commandsNoMatch => '現在のフィルターに一致するコマンドはありません。';

  @override
  String get teamSubtitle => 'Collaborators and team chat.';

  @override
  String get teamChatTitle => 'Team chat';

  @override
  String get teamNoChatAccess =>
      'The owner has not given you access to the chat.';

  @override
  String get teamNoMessages => 'No messages.';

  @override
  String get teamWriteHint => 'Write a message…';

  @override
  String get teamOwner => '所有者';

  @override
  String get teamNoPermissions => 'No specific permissions';

  @override
  String get teamRemove => 'Remove from team';

  @override
  String get teamPermEditCommands => 'Edit commands';

  @override
  String get teamPermStartStop => 'Start / stop';

  @override
  String get teamPermClaimAds => 'Earn time (ads)';

  @override
  String get teamPermInvite => 'Invite';

  @override
  String get premiumHint =>
      'Your account is on the free plan: subscriptions are activated from the mobile app (Studio shows no ads or purchases).';

  @override
  String get featureSchedulerTitle => 'スケジューラートリガー';

  @override
  String get featureSchedulerDesc => 'X分ごとに自動的にワークフローを実行（最大10個まで有効）。';

  @override
  String get featureAnalyticsTitle => 'プレミアム分析';

  @override
  String get featureAnalyticsDesc => 'エラー率、レイテンシパーセンタイル、ロケールインサイトをアンロックします。';

  @override
  String get featureHooksTitle => '受信Webhook';

  @override
  String get featureHooksDesc => '安全なWebhookエンドポイントを作成し、呼び出しをワークフローにルーティング。';
}
