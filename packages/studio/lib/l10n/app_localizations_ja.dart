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
  String get navReplay => 'デバッガーリプレイ';

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
  String get modulesDescReplay => 'コマンド実行をステップごとに再生';

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

  @override
  String get featureReplayTitle => 'ビジュアルデバッグリプレイ';

  @override
  String get featureReplayDesc => 'デバッグ用にコマンドアクションをステップごとに記録・再生。';

  @override
  String get commonSaved => '保存済み';

  @override
  String get commonAdd => '追加';

  @override
  String get deleteIrreversible => 'この操作は元に戻せません。';

  @override
  String deleteNamedTitle(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get commandNew => '新しいコマンド';

  @override
  String get commandSaved => 'コマンドを保存しました。';

  @override
  String get commandChangedElsewhere =>
      'このボットは別の場所（アプリまたは別のセッション）で変更されました。保存する前にコマンドを再読み込みしてください。';

  @override
  String get scriptEdit => 'スクリプトを編集';

  @override
  String get commandTriggerHybrid => 'スラッシュ＋テキストメッセージ';

  @override
  String get workflowNew => '新しいワークフロー';

  @override
  String get workflowsEmpty =>
      'ワークフローがありません。アクションの流れを再利用したり、イベントに反応させたりするには、ワークフローを作成してください。';

  @override
  String get workflowSaved => 'ワークフローを保存しました。';

  @override
  String get workflowDeleteBody => 'このワークフローを呼び出すコマンドは、実行するものがなくなります。';

  @override
  String get workflowTypeGeneral => '汎用（コマンドから呼び出し）';

  @override
  String get workflowCategory => 'カテゴリ';

  @override
  String workflowScriptNotice(String mode) {
    return 'このワークフローは $mode で書かれています。Studio で編集できるのはビジュアルのワークフローのみです。内容はそのまま保存されます。';
  }

  @override
  String get variablesGlobalSubtitle => 'ボット全体で記憶されるデータ。';

  @override
  String get variablesScopedHint =>
      '定義はデフォルト値を決めます。その後、サーバー・チャンネル・メンバーごとに独自の値が保持されます。';

  @override
  String get variableScopedRemoveNote => '定義は削除されますが、すでに保存されている値は消去されません。';

  @override
  String get copilotNoCredits => 'AIクレジットが不足しています。モバイルアプリからチャージしてください。';

  @override
  String get copilotChatTooLong => 'この会話は長すぎます。新しい会話を始めてください。';

  @override
  String get copilotUnavailable => 'コパイロットは現在利用できません。';

  @override
  String get copilotGenerationFailed => '生成に失敗しました。';

  @override
  String get copilotDeleteChat => '会話を削除';

  @override
  String copilotWants(String tool) {
    return 'コパイロットの要求: $tool';
  }

  @override
  String get dashboardRuns => '実行回数';

  @override
  String get dashboardSinceStart => '開始から';

  @override
  String get dashboardLatencyP50P95 => 'レイテンシ P50 / P95';

  @override
  String get dashboardActivity => 'アクティビティ';

  @override
  String get dashboardLanguages => '言語';

  @override
  String get dashboardNoRuns => 'この期間の実行はありません。';

  @override
  String get dashboardNoActivity => 'この期間のアクティビティはありません。';

  @override
  String get dashboardOneExecution => '1 回の実行';

  @override
  String dashboardAgoDays(int days) {
    return '$days 日前';
  }

  @override
  String dashboardAgoHours(int hours) {
    return '$hours 時間前';
  }

  @override
  String dashboardErrorRateOf(String rate) {
    return 'エラー $rate %';
  }

  @override
  String dashboardLatencyPercentiles(int p50, int p95) {
    return 'P50 $p50 ms · P95 $p95 ms';
  }

  @override
  String get dashboardLatencyNone => 'レイテンシ —';

  @override
  String get botStopFailed => 'ボットを停止できません';

  @override
  String get botStartFailed => 'ボットを起動できません';

  @override
  String get refusalNoFreeTimeTitle => 'ホスティング時間を使い切りました';

  @override
  String get refusalNoFreeTimeBody =>
      'このボットには無料のホスティング時間が残っていません。モバイルアプリで広告を視聴して獲得するか、Premiumにアップグレードしてください。Studioでは広告の表示も購入もできません。';

  @override
  String get authSessionExpired => 'セッションの有効期限が切れました。もう一度サインインしてください。';

  @override
  String authDiscordRefused(String reason) {
    return 'Discordサインインが拒否されました（$reason）。';
  }

  @override
  String get authInvalidResponse => 'サインインの応答が無効です。もう一度お試しください。';

  @override
  String get validationCommandNameFormat =>
      '無効な名前です。小文字、数字、「-」と「_」のみ使用でき、スペースは使えません。';

  @override
  String validationDescriptionTooLong(int max) {
    return '説明は最大$max文字です。';
  }

  @override
  String get validationWorkflowNameRequired => 'ワークフロー名は必須です。';

  @override
  String validationWorkflowNameTooLong(int max) {
    return '名前は最大$max文字です。';
  }

  @override
  String validationWorkflowTooManyBlocks(int max) {
    return 'ワークフローあたり最大$maxブロックです。';
  }

  @override
  String validationOptionNameInvalid(String name) {
    return 'オプション「$name」：小文字、数字、「-」と「_」のみ、最大32文字です。';
  }

  @override
  String validationOptionDescription(String name) {
    return 'オプション「$name」：説明は必須です（最大100文字）。';
  }

  @override
  String validationOptionRequiredOrder(String name) {
    return '必須オプションは任意オプションより前に置く必要があります（「$name」）。';
  }

  @override
  String get schedulerPremiumOnly =>
      'スケジューラーはPremiumアカウント専用です。サブスクリプションはアプリで管理します。';

  @override
  String get webhooksPremiumOnly =>
      '受信Webhookはプレミアムアカウント専用です。サブスクリプションはアプリで管理します。';
}
