// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get action_add_else_if => 'ELSE IF を追加';

  @override
  String get action_add_header => 'ヘッダーを追加';

  @override
  String get action_add_new_item => '新しい項目を追加';

  @override
  String get action_advanced_settings => '詳細設定';

  @override
  String action_and_more(int count) {
    return '… 他 $count 件';
  }

  @override
  String get action_bulk_import_hint => '一括インポート (Key: Value 形式で貼り付け)';

  @override
  String get action_cannot_format_json => 'フォーマット不可: 無効なJSON';

  @override
  String get action_category_channels => 'チャンネル';

  @override
  String get action_category_components => 'コンポーネント';

  @override
  String get action_category_guild_members => 'サーバー & メンバー';

  @override
  String get action_category_http_variables => 'HTTP & 変数';

  @override
  String get action_category_interactions => 'インタラクション';

  @override
  String get action_category_logic_flow => 'ロジック & フロー';

  @override
  String get action_category_messages => 'メッセージ';

  @override
  String get action_category_moderation => 'モデレーション';

  @override
  String get action_category_music => '音楽';

  @override
  String get action_category_reactions => 'リアクション';

  @override
  String get action_category_webhooks => 'Webhook';

  @override
  String get action_category_workflows => 'ワークフロー';

  @override
  String action_choose_param(String name) {
    return '$name を選択';
  }

  @override
  String get action_clear_all => 'すべてクリア';

  @override
  String get action_condition_value => '条件値';

  @override
  String get action_condition_variable => '条件変数';

  @override
  String get action_description_addReaction => 'メッセージに絵文字リアクションを追加';

  @override
  String get action_description_addRole => 'メンバーにロールを付与';

  @override
  String get action_description_addThreadMember => 'スレッドにメンバーを追加します';

  @override
  String get action_description_appendArrayElement =>
      'グローバルまたはスコープ付きのJSON配列に新しい要素を追加します';

  @override
  String get action_description_attachImage =>
      'メッセージ応答に画像ファイルを添付します（URL、データURL、またはbase64）';

  @override
  String get action_description_banUser => 'ユーザーをサーバーから永久追放';

  @override
  String get action_description_calculate => '数学的な演算を実行し、結果を保存します';

  @override
  String get action_description_canvasCreateBlock => '空白の画像キャンバスを作成します';

  @override
  String get action_description_canvasDrawCircleBlock => '画像キャンバスに円を描画します';

  @override
  String get action_description_canvasDrawLineBlock => 'キャンバスに線を描画します';

  @override
  String get action_description_canvasDrawRectBlock => '画像キャンバスに長方形を描画します';

  @override
  String get action_description_canvasDrawTextBlock =>
      'スタイルオプション付きで画像キャンバスにテキストを描画します';

  @override
  String get action_description_canvasLoadImageBlock =>
      'URLまたはソースからキャンバスに画像を読み込みます';

  @override
  String get action_description_clearAllReactions => 'メッセージからすべてのリアクションを削除';

  @override
  String get action_description_cooldown => 'ユーザーまたはサーバーにコマンドクールダウンを適用';

  @override
  String get action_description_createAutoModRule => 'ギルドの自動モデレーションルールを作成します';

  @override
  String get action_description_createChannel => '新しいチャンネルを作成します';

  @override
  String get action_description_createEmoji => '画像データからギルド絵文字を作成します';

  @override
  String get action_description_createInvite => 'チャンネルの新しい招待リンクを作成します';

  @override
  String get action_description_createPoll => 'チャンネル内に投票メッセージを作成します';

  @override
  String get action_description_createThread =>
      'サポートされているテキストチャンネル内にスレッドを作成します';

  @override
  String get action_description_debugProfile => '実行プロファイルと診断情報を生成します';

  @override
  String get action_description_deferInteraction =>
      'Discordのタイムアウトを防ぐためにインタラクションの応答を保留します';

  @override
  String get action_description_deleteAutoModRule => '自動モデレーションルールを削除します';

  @override
  String get action_description_deleteChannelPermission =>
      'チャンネルの権限オーバーライトを削除します';

  @override
  String get action_description_deleteEmoji => 'ギルド絵文字を削除します';

  @override
  String get action_description_deleteInvite => 'コードで既存の招待を削除します';

  @override
  String get action_description_deleteMessages => '1件以上のメッセージを削除';

  @override
  String get action_description_deleteTrigger => 'このコマンドを起動したメッセージを削除';

  @override
  String get action_description_deleteWebhook => 'Webhookを削除します';

  @override
  String get action_description_disconnectFromVoice => 'メンバーを音声から切断します';

  @override
  String get action_description_editChannelPermissions =>
      'チャンネルの権限オーバーライトを作成または更新します';

  @override
  String get action_description_editComponentV2 => '既存のコンポーネントを編集します';

  @override
  String get action_description_editInteractionMessage =>
      '保留中または元のインタラクション応答を編集します';

  @override
  String get action_description_editMessage => '既存のメッセージを編集';

  @override
  String get action_description_editWebhook => '既存のWebhookを編集します';

  @override
  String get action_description_endPoll => 'アクティブな投票メッセージを即座に終了します';

  @override
  String get action_description_forLoop => '数値の範囲でループします（forループ）';

  @override
  String get action_description_getGlobalVariable => 'グローバル変数を読み込み、実行時変数に注入します';

  @override
  String get action_description_getGuildOnboarding => '現在のギルドオンボーディング設定を取得します';

  @override
  String get action_description_getInvite => 'コードで招待情報を取得します';

  @override
  String get action_description_getMember => 'メンバー情報を取得します';

  @override
  String get action_description_getMessage => 'メッセージを取得し、そのフィールドを公開します';

  @override
  String get action_description_getMusicInfo => '現在再生中のトラックの情報を取得します';

  @override
  String get action_description_getScopedVariable =>
      'スコープ付き変数を読み込み、実行時変数に注入します';

  @override
  String get action_description_getWebhook => 'IDでWebhookの情報を取得します';

  @override
  String get action_description_httpRequest =>
      '動的なURL、メソッド、ヘッダー、ボディでHTTPリクエストを送信します';

  @override
  String get action_description_ifBlock => '条件分岐：条件に基づいて異なるアクションを実行します';

  @override
  String get action_description_jumpToAction => 'キー、ID、または位置で特定のアクションにジャンプします';

  @override
  String get action_description_joinVoice => 'ボイスチャンネルに接続します';

  @override
  String get action_description_jsonForEachLoop =>
      'JSON配列またはオブジェクトの各要素をループします（forEach）';

  @override
  String get action_description_kickUser => 'メンバーをサーバーからキック';

  @override
  String get action_description_leaveGuild => 'ボットをサーバーから退出させます';

  @override
  String get action_description_leaveVoice => 'ボイスチャンネルから退出してプレイヤーを破棄します';

  @override
  String get action_description_listAutoModRules =>
      'ギルド内のすべての自動モデレーションルールを一覧表示します';

  @override
  String get action_description_listMembers => 'オプション付きでギルド内のメンバーを一覧表示します';

  @override
  String get action_description_listScopedVariableIndex =>
      'インデックス付きスコープ値を値順にソートし、オフセットと制限付きで一覧表示します';

  @override
  String get action_description_listWebhooks =>
      'チャンネルまたはギルド内のすべてのWebhookを一覧表示します';

  @override
  String get action_description_listenAndExecute =>
      'ボタンのクリック、選択メニューの使用、またはモーダルの送信時に実行するワークフローを登録します';

  @override
  String get action_description_listenForButtonClick =>
      'ボタンがクリックされたときに実行するワークフローを登録します';

  @override
  String get action_description_listenForModalSubmit =>
      'モーダルが送信されたときに実行するワークフローを登録します';

  @override
  String get action_description_listenForSelectMenu =>
      '選択メニューが使用されたときに実行するワークフローを登録します';

  @override
  String get action_description_log => '診断メッセージをアクションログに出力または保存します';

  @override
  String get action_description_moveToVoiceChannel => 'メンバーを特定の音声チャンネルに移動します';

  @override
  String get action_description_muteUser => 'メンバーを一時的に除外 (タイムアウト)';

  @override
  String get action_description_pauseMusic => '現在のトラックを一時停止します';

  @override
  String get action_description_pinMessage => 'チャンネル内のメッセージをピン留めします';

  @override
  String get action_description_playMusic => '検索クエリまたはURLでトラックを再生します';

  @override
  String get action_description_queryArray => '実行時のJSON配列をフィルタリング、ソート、ページングします';

  @override
  String get action_description_randomChoice => 'リストからランダムに1項目を選び変数に保存';

  @override
  String get action_description_registerGuildCommands =>
      'アプリケーションコマンドをギルドに登録します';

  @override
  String get action_description_removeArrayElement =>
      'グローバルまたはスコープ付きのJSON配列からインデックスで要素を削除します';

  @override
  String get action_description_removeChannel => 'チャンネルを削除します';

  @override
  String get action_description_removeGlobalVariable => 'グローバル変数を削除します';

  @override
  String get action_description_removeReaction => 'メッセージからリアクションを削除';

  @override
  String get action_description_removeRole => 'メンバーからロールを削除';

  @override
  String get action_description_removeScopedVariable => 'スコープ付き変数を削除します';

  @override
  String get action_description_removeThreadMember => 'スレッドからメンバーを削除します';

  @override
  String get action_description_renameScopedVariable => 'スコープ付き変数のキーの名前を変更します';

  @override
  String get action_description_respondWithAutocomplete =>
      'Discordのオートコンプリートに最大25個の動的選択肢で返信します';

  @override
  String get action_description_respondWithComponentV2 =>
      'コマンドにボタンまたは選択メニューで返信します';

  @override
  String get action_description_respondWithMessage => 'コマンドに通常のメッセージで返信します';

  @override
  String get action_description_respondWithModal => 'ユーザーにモーダルダイアログを表示します';

  @override
  String get action_description_resumeMusic => '一時停止中のトラックを再開します';

  @override
  String get action_description_runBdfdScript =>
      'BDFDスクリプトをインラインでコンパイルし、ワークフローアクションとして実行します';

  @override
  String get action_description_runWorkflow =>
      '保存されたワークフローを実行します（エントリポイントと引数をサポート）';

  @override
  String get action_description_runtimeImageBlock =>
      '画像キャンバス処理アクションのブロックを実行します';

  @override
  String get action_description_runtimeJsonBlock => 'JSON処理アクションのブロックを実行します';

  @override
  String get action_description_seekMusic => '現在のトラックの指定した位置に移動します';

  @override
  String get action_description_sendComponentV2 => 'インタラクティブなコンポーネントを送信します';

  @override
  String get action_description_sendDm => '特定のユーザーにプライベートメッセージを送信';

  @override
  String get action_description_sendMessage => '特定のチャンネルにメッセージを送信';

  @override
  String get action_description_sendWebhook => 'Webhook経由でメッセージを送信します';

  @override
  String get action_description_serverDeafenMember =>
      'メンバーのサーバー聴覚保護を設定または解除します';

  @override
  String get action_description_serverMuteMember => 'メンバーのサーバーミュートを設定または解除します';

  @override
  String get action_description_setGlobalVariable =>
      'このボットのグローバル変数を新規作成または更新します';

  @override
  String get action_description_setMusicLoop => 'キューのループ再生を有効または無効にします';

  @override
  String get action_description_setMusicVolume => 'プレイヤーの音量を設定します (0〜200)';

  @override
  String get action_description_setNickname => 'サーバーメンバーのニックネームを変更';

  @override
  String get action_description_setScopedVariable =>
      'スコープ付き変数（ギルド/ユーザー/チャンネル/メンバー/メッセージ）を作成または更新します';

  @override
  String get action_description_setTemporaryVariable =>
      'ローカル実行で一時変数を作成または更新します';

  @override
  String get action_description_skipActions => '指定された数の後続アクションをスキップします';

  @override
  String get action_description_skipMusic => 'キューの次のトラックに進みます';

  @override
  String get action_description_slowmode => 'チャンネルの低速モード時間を設定';

  @override
  String get action_description_stop => '現在のワークフローの実行を即座に停止';

  @override
  String get action_description_stopMusic => '再生を停止し、キューをクリアします';

  @override
  String get action_description_stopUnless =>
      '条件が満たされない場合にワークフローを停止します（ガード/フィルター）';

  @override
  String get action_description_unbanUser => 'ユーザーの追放を解除';

  @override
  String get action_description_unmuteUser => 'メンバーの一時除外を解除';

  @override
  String get action_description_unpinMessage => 'チャンネル内のメッセージのピン留めを解除します';

  @override
  String get action_description_unregisterGuildCommands =>
      'アプリケーションコマンドをギルドから登録解除します';

  @override
  String get action_description_updateAutoMod => '自動モデレーション設定を更新します';

  @override
  String get action_description_updateChannel => 'チャンネル設定を更新します';

  @override
  String get action_description_updateEmoji => 'ギルド絵文字の名前またはロールアクセスを更新します';

  @override
  String get action_description_updateGuild => 'ギルド設定を更新します';

  @override
  String get action_description_updateGuildOnboarding => 'ギルドオンボーディング設定を更新します';

  @override
  String get action_description_updateSelfUser =>
      '現在のボットのユーザープロファイル（ユーザー名/アバター）を更新します';

  @override
  String get action_description_wait => 'ワークフローの実行を指定時間一時停止';

  @override
  String get action_dynamic => '動的';

  @override
  String get action_dynamic_bool_hint => 'true/false または ((変数))';

  @override
  String action_dynamic_id_hint(String type) {
    return '動的 $type (((...)) 対応)';
  }

  @override
  String get action_dynamic_multiselect_hint => '動的な値 (((...)) 対応)';

  @override
  String get action_dynamic_numeric => '動的数値候補';

  @override
  String get action_dynamic_variable => '動的変数候補';

  @override
  String action_edit_nested(int count) {
    return '$count 件を編集';
  }

  @override
  String action_edit_nested_parens(int count) {
    return '編集 ($count)';
  }

  @override
  String action_edit_param(String name) {
    return '$name を編集';
  }

  @override
  String get action_edit_raw_json => '生JSONを編集';

  @override
  String action_else_if_label(int index) {
    return 'ELSE IF $index — アクション';
  }

  @override
  String get action_error_continue => '続行';

  @override
  String get action_error_stop => '停止';

  @override
  String get action_expression => '式';

  @override
  String get action_format_json => 'JSONをフォーマット';

  @override
  String get action_hint_color => '#FFFFFF または rgb(255,255,255)';

  @override
  String get action_hint_condition_value => '比較する値';

  @override
  String get action_hint_condition_var => '((変数名)) または実行時の値を使用';

  @override
  String get action_hint_cooldown_error => 'クールダウン中に送信するメッセージ (%time% 対応)';

  @override
  String get action_hint_cooldown_time => '時間 (例: 10s, 5m)';

  @override
  String get action_hint_duration => '例: 5m, 1h, 30s';

  @override
  String get action_hint_emoji => '絵文字 (例: 🪜) または <:名前:ID>';

  @override
  String action_hint_enter_type(String type) {
    return '$type を入力';
  }

  @override
  String get action_hint_random_choices => '選択肢リスト (; 区切り)';

  @override
  String get action_hint_random_var => '結果を保存する変数名';

  @override
  String get action_hint_variable_key => '変数キーを選択';

  @override
  String get action_hint_workflow => '保存済みワークフロー名';

  @override
  String get action_http_headers_title => 'HTTP ヘッダー (Key/Value ペア)';

  @override
  String action_http_paths_parsed(int count) {
    return '$count 件のパスを解析';
  }

  @override
  String get action_http_response_body => 'レスポンスボディ (Raw):';

  @override
  String action_http_status(int status) {
    return 'ステータス: $status';
  }

  @override
  String get action_http_test_button => 'テストリクエスト送信 & ルート自動検出';

  @override
  String get action_http_test_title => 'テストリクエスト結果';

  @override
  String get action_json_editor_hint => 'JSONオブジェクトエディタ (ネストされたオブジェクト/配列対応)';

  @override
  String get action_key_field => 'アクションキー';

  @override
  String get action_key_value_pairs => 'Key / Value ペア';

  @override
  String get action_literal => 'リテラル';

  @override
  String get action_loading_keys => 'キーを読み込み中...';

  @override
  String get action_manage_variable_keys => '変数キーを管理';

  @override
  String get action_name_addReaction => 'リアクション追加';

  @override
  String get action_name_addRole => 'ロール追加';

  @override
  String get action_name_addThreadMember => 'スレッドメンバー追加';

  @override
  String get action_name_appendArrayElement => '配列要素を追加';

  @override
  String get action_name_attachImage => '画像を添付';

  @override
  String get action_name_banUser => 'ユーザー追放';

  @override
  String get action_name_calculate => '計算';

  @override
  String get action_name_canvasCreateBlock => 'キャンバス作成';

  @override
  String get action_name_canvasDrawCircleBlock => '円を描画';

  @override
  String get action_name_canvasDrawLineBlock => '線を描画';

  @override
  String get action_name_canvasDrawRectBlock => '四角形を描画';

  @override
  String get action_name_canvasDrawTextBlock => 'テキストを描画';

  @override
  String get action_name_canvasLoadImageBlock => '画像を読み込み';

  @override
  String get action_name_clearAllReactions => '全リアクション削除';

  @override
  String get action_name_cooldown => 'クールダウン';

  @override
  String get action_name_createAutoModRule => '自動モデレーションルール作成';

  @override
  String get action_name_createChannel => 'チャンネル作成';

  @override
  String get action_name_createEmoji => '絵文字作成';

  @override
  String get action_name_createInvite => '招待作成';

  @override
  String get action_name_createPoll => '投票作成';

  @override
  String get action_name_createThread => 'スレッド作成';

  @override
  String get action_name_debugProfile => 'デバッグプロファイル';

  @override
  String get action_name_deferInteraction => 'インタラクションを保留';

  @override
  String get action_name_deleteAutoModRule => '自動モデレーションルール削除';

  @override
  String get action_name_deleteChannelPermission => 'チャンネル権限削除';

  @override
  String get action_name_deleteEmoji => '絵文字削除';

  @override
  String get action_name_deleteInvite => '招待削除';

  @override
  String get action_name_deleteMessages => 'メッセージ削除';

  @override
  String get action_name_deleteTrigger => 'トリガーメッセージ削除';

  @override
  String get action_name_deleteWebhook => 'Webhook削除';

  @override
  String get action_name_disconnectFromVoice => 'ボイスチャンネル切断';

  @override
  String get action_name_editChannelPermissions => 'チャンネル権限編集';

  @override
  String get action_name_editComponentV2 => 'コンポーネント編集 V2';

  @override
  String get action_name_editInteractionMessage => 'インタラクションメッセージ編集';

  @override
  String get action_name_editMessage => 'メッセージ編集';

  @override
  String get action_name_editWebhook => 'Webhook編集';

  @override
  String get action_name_endPoll => '投票終了';

  @override
  String get action_name_forLoop => 'For ループ';

  @override
  String get action_name_getGlobalVariable => 'グローバル変数取得';

  @override
  String get action_name_getGuildOnboarding => 'サーバーオンボーディング取得';

  @override
  String get action_name_getInvite => '招待取得';

  @override
  String get action_name_getMember => 'メンバー取得';

  @override
  String get action_name_getMessage => 'メッセージ取得';

  @override
  String get action_name_getMusicInfo => '音楽情報を取得';

  @override
  String get action_name_getScopedVariable => 'スコープ変数取得';

  @override
  String get action_name_getWebhook => 'Webhook取得';

  @override
  String get action_name_httpRequest => 'HTTP リクエスト';

  @override
  String get action_name_ifBlock => 'IF / ELSE ブロック';

  @override
  String get action_name_jumpToAction => 'アクションにジャンプ';

  @override
  String get action_name_joinVoice => 'ボイスチャンネルに参加';

  @override
  String get action_name_jsonForEachLoop => 'JSON For Each ループ';

  @override
  String get action_name_kickUser => 'ユーザーキック';

  @override
  String get action_name_leaveGuild => 'サーバーを退出';

  @override
  String get action_name_leaveVoice => 'ボイスチャンネルから退出';

  @override
  String get action_name_listAutoModRules => '自動モデレーションルール一覧';

  @override
  String get action_name_listMembers => 'メンバー一覧';

  @override
  String get action_name_listScopedVariableIndex => 'スコープ変数インデックス一覧';

  @override
  String get action_name_listWebhooks => 'Webhook一覧';

  @override
  String get action_name_listenAndExecute => '監視して実行';

  @override
  String get action_name_listenForButtonClick => 'ボタンクリック待機';

  @override
  String get action_name_listenForModalSubmit => 'モーダル送信待機';

  @override
  String get action_name_listenForSelectMenu => 'セレクトメニュー待機';

  @override
  String get action_name_log => 'ログメッセージ';

  @override
  String get action_name_moveToVoiceChannel => 'ボイスチャンネルに移動';

  @override
  String get action_name_muteUser => 'ユーザーミュート';

  @override
  String get action_name_pauseMusic => '音楽を一時停止';

  @override
  String get action_name_pinMessage => 'メッセージピン留め';

  @override
  String get action_name_playMusic => '音楽を再生';

  @override
  String get action_name_queryArray => '配列クエリ';

  @override
  String get action_name_randomChoice => 'ランダム選択';

  @override
  String get action_name_registerGuildCommands => 'サーバーコマンド登録';

  @override
  String get action_name_removeArrayElement => '配列要素削除';

  @override
  String get action_name_removeChannel => 'チャンネル削除';

  @override
  String get action_name_removeGlobalVariable => 'グローバル変数削除';

  @override
  String get action_name_removeReaction => 'リアクション削除';

  @override
  String get action_name_removeRole => 'ロール削除';

  @override
  String get action_name_removeScopedVariable => 'スコープ変数削除';

  @override
  String get action_name_removeThreadMember => 'スレッドメンバー削除';

  @override
  String get action_name_renameScopedVariable => 'スコープ変数名変更';

  @override
  String get action_name_respondWithAutocomplete => 'オートコンプリートで応答';

  @override
  String get action_name_respondWithComponentV2 => 'コンポーネント V2 で応答';

  @override
  String get action_name_respondWithMessage => 'メッセージで応答';

  @override
  String get action_name_respondWithModal => 'モーダルで応答';

  @override
  String get action_name_resumeMusic => '音楽を再開';

  @override
  String get action_name_runBdfdScript => 'BDFD スクリプト実行';

  @override
  String get action_name_runWorkflow => 'ワークフロー実行';

  @override
  String get action_name_runtimeImageBlock => '画像キャンバスを実行';

  @override
  String get action_name_runtimeJsonBlock => 'JSON 操作を実行';

  @override
  String get action_name_seekMusic => '再生位置を変更';

  @override
  String get action_name_sendComponentV2 => 'コンポーネント V2 送信';

  @override
  String get action_name_sendDm => 'ダイレクトメッセージ送信';

  @override
  String get action_name_sendMessage => 'メッセージ送信';

  @override
  String get action_name_sendWebhook => 'Webhook送信';

  @override
  String get action_name_serverDeafenMember => 'サーバー聴覚無効化';

  @override
  String get action_name_serverMuteMember => 'サーバーミュート';

  @override
  String get action_name_setGlobalVariable => 'グローバル変数設定';

  @override
  String get action_name_setMusicLoop => 'ループ再生を設定';

  @override
  String get action_name_setMusicVolume => '音量を設定';

  @override
  String get action_name_setNickname => 'ニックネーム設定';

  @override
  String get action_name_setScopedVariable => 'スコープ変数設定';

  @override
  String get action_name_setTemporaryVariable => '一時変数設定';

  @override
  String get action_name_skipActions => 'アクションをスキップ';

  @override
  String get action_name_skipMusic => '音楽をスキップ';

  @override
  String get action_name_slowmode => '低速モード';

  @override
  String get action_name_stop => '実行停止';

  @override
  String get action_name_stopMusic => '音楽を停止';

  @override
  String get action_name_stopUnless => '条件付き停止';

  @override
  String get action_name_unbanUser => '追放解除';

  @override
  String get action_name_unmuteUser => 'ミュート解除';

  @override
  String get action_name_unpinMessage => 'ピン留め解除';

  @override
  String get action_name_unregisterGuildCommands => 'サーバーコマンド登録解除';

  @override
  String get action_name_updateAutoMod => '自動モデレーション更新';

  @override
  String get action_name_updateChannel => 'チャンネル更新';

  @override
  String get action_name_updateEmoji => '絵文字更新';

  @override
  String get action_name_updateGuild => 'サーバー更新';

  @override
  String get action_name_updateGuildOnboarding => 'サーバーオンボーディング更新';

  @override
  String get action_name_updateSelfUser => '自己ユーザー更新 (Botプロフィール)';

  @override
  String get action_name_wait => '待機';

  @override
  String get action_no_actions_yet => 'このブランチにはまだアクションがありません。';

  @override
  String get action_no_args_tap_edit => '引数なし - 編集をタップして追加';

  @override
  String get action_no_else_if_yet =>
      'ELSE IF ブランチがまだありません。ELSE の前に条件を追加してください。';

  @override
  String get action_no_headers_tap_edit => 'ヘッダーなし - 編集をタップして追加';

  @override
  String get action_no_items_tap_edit => '項目なし - 編集をタップして追加';

  @override
  String get action_no_properties_tap_edit => 'プロパティなし - 編集をタップして設定';

  @override
  String get action_no_saved_keys => '保存されたキーが見つかりません。キーは初回アクセス時に自動生成されます。';

  @override
  String get action_on_error => 'エラー時';

  @override
  String get action_options_tooltip => 'アクションオプション';

  @override
  String get action_or_type_workflow => 'またはワークフロー名を入力';

  @override
  String get action_order_tip => 'ヒント: 矢印でアクションの順序を変更できます。';

  @override
  String action_position(int index, int total) {
    return 'アクション $index/$total';
  }

  @override
  String get action_preview_json => 'ハイライトJSONをプレビュー';

  @override
  String get action_provide_valid_url => '有効なURLを入力してください。';

  @override
  String get action_refresh_keys => 'キーを更新';

  @override
  String get action_remove_confirm => 'このアクションをワークフローから削除します。続行しますか？';

  @override
  String get action_remove_else_if => 'ELSE IF を削除';

  @override
  String get action_remove_menu => 'アクションを削除';

  @override
  String get action_remove_title => 'アクションを削除';

  @override
  String get action_root_must_json => 'ルートはJSONオブジェクトである必要があります';

  @override
  String get action_select_saved_key => '保存されたキーを選択';

  @override
  String get action_select_stored_key => '保存されたキーを選択 (bc_ 接頭辞は任意)';

  @override
  String get action_static_badge => '(静的)';

  @override
  String get action_status_disabled => '無効';

  @override
  String get action_status_enabled => '有効';

  @override
  String get action_store_results => '結果をグローバル変数に保存';

  @override
  String actions_active_route(String label) {
    return 'アクティブルート: $label';
  }

  @override
  String get actions_add_label => 'アクションを追加';

  @override
  String get actions_add_new_title => '新しいアクションを追加';

  @override
  String actions_build_button(int count) {
    return 'アクションを構築 ($count)';
  }

  @override
  String get actions_builder_title => 'アクションビルダー';

  @override
  String get actions_description => 'このコマンドのランタイムアクションを構築';

  @override
  String get actions_global_variables => 'グローバル変数';

  @override
  String actions_key_label(String key) {
    return 'キー: $key';
  }

  @override
    @override
  String get actions_missing_field_content => '"{action}"："{field}" は必須です。';

  @override
  String get actions_missing_field_title => '不足フィールド';

  @override
  String get actions_no_matches => '一致するものが見つかりません';

  @override
  String actions_save_count(int count) {
    return '$count アクションを保存';
  }

  @override
  String get actions_save_tooltip => 'アクションを保存';

  @override
  String get actions_save_workflow_title => 'ワークフローとして保存';

  @override
  String get actions_search_hint => 'アクションを検索...';

  @override
  String get actions_search_sequence_hint => 'シーケンスを検索...';

  @override
  String actions_sequence_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count アクション',
      one: '1 アクション',
      zero: 'アクションなし',
    );
    return '$_temp0';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'ステップ $index/$total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'BDFD スクリプト | $lines 行 | $diagnostics 診断';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count アクション設定済み';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Dart スクリプト | $lines 行 | $diagnostics 診断';
  }

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count アクション (アクティブルート) | $routes ルート';
  }

  @override
  String get actions_title => 'アクション';

  @override
  String get actions_workflow_name_label => 'ワークフロー名';

  @override
  String get actions_workflows => 'ワークフロー';

  @override
  String get ads_consent_accept => '同意する';

  @override
  String get ads_consent_message =>
      'GDPRに準拠するため、広告表示前に同意が必要です。同意しなくてもアプリは引き続きご利用いただけます。';

  @override
  String get ads_consent_refuse => '拒否する';

  @override
  String get ads_consent_refused_info => '広告同意が拒否されました。ボットは通常通り起動します。';

  @override
  String get ads_consent_title => '広告の同意';

  @override
  String get app_bot_token => 'Bot トークン';

  @override
  String get app_create_button => 'ボットを作成';

  @override
  String get app_create_hero_desc =>
      '適切なページを開き、トークンをコピーしてボットを安全にインポートするためのガイド付きセットアップ。';

  @override
  String get app_create_hero_title => 'Discordボットに接続';

  @override
  String get app_create_new => '新しいアプリを作成';

  @override
  String get app_create_page_title => 'ボットを作成';

  @override
  String get app_enter_token => 'ボットトークンをここに入力';

  @override
  String get app_external_link_badge => '外部リンク';

  @override
  String get app_hide_token => 'トークンを隠す';

  @override
  String get app_how_to_create_token => 'Botトークンの作成方法';

  @override
  String get app_loading_error => '読み込みエラー';

  @override
  String get app_no_apps => 'まだアプリがありません。';

  @override
  String get app_note =>
      '注意: Discord Developer Portalで新しいアプリを作成し、ボットトークンを取得する必要があります。';

  @override
  String get app_open_discord_portal => 'Discord Developer Portal を開く';

  @override
  String get app_open_discord_portal_desc => 'アプリケーションを作成し、ボットセクションを有効にします。';

  @override
  String get app_open_link_error => 'この外部ページを開けません。';

  @override
  String get app_open_token_tutorial => 'トークンチュートリアルを読む';

  @override
  String get app_open_token_tutorial_desc =>
      'ボットトークンを生成してコピーするためのステップバイステップガイド。';

  @override
  String get app_resources_desc => 'これらのアクションは、ボットをここに保存する前に必要な公式ページを開きます。';

  @override
  String get app_resources_title => 'ガイド付きセットアップ';

  @override
  String get app_save => '変更を保存';

  @override
  String get app_save_bot => 'ボットを追加';

  @override
  String get app_show_token => 'トークンを表示';

  @override
  String get app_sync_manager_connect => 'Discordに接続';

  @override
  String get app_sync_manager_desc =>
      'このボットは既にBot Creator Managerに保存されています。Discordに接続して同期してください。';

  @override
  String get app_sync_manager_manual => 'ローカルに保持';

  @override
  String get app_sync_manager_title => 'ボットは既に管理されています';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_invalid_content =>
      '提供されたDiscordトークンは無効か、取り消されています。有効なトークンを生成するにはチュートリアルに従うことをお勧めします。';

  @override
  String get app_token_invalid_title => '無効なトークン';

  @override
  String get app_token_field_helper => 'Discordから提供されたトークンをそのまま貼り付けてください。';

  @override
  String get app_token_section_desc => 'トークンをコピーしたら、以下に貼り付けてボットをアプリに追加します。';

  @override
  String get app_token_section_title => 'ボットトークンを貼り付け';

  @override
  String get app_token_security_hint =>
      'このトークンは秘密にしてください。トークンを知っている人は誰でもボットを操作できます。';

  @override
  String get autocomplete_dynamic => '動的オートコンプリート';

  @override
  String get autocomplete_dynamic_desc => '静的な値の代わりにワークフローから選択肢を解決します。';

  @override
  String get autocomplete_filter_hint => 'ユーザーの入力に応じて候補がフィルタリングされます。';

  @override
  String get autocomplete_loading => 'ワークフローを読み込み中…';

  @override
  String get autocomplete_no_workflows => '保存されたワークフローが見つかりません';

  @override
  String get autocomplete_select_workflow => '保存されたワークフローを選択';

  @override
  String get autocomplete_type_name => 'またはワークフロー名を入力';

  @override
  String get autocomplete_workflow_label => 'オートコンプリートワークフロー';

  @override
  String backup_completed(String id) {
    return 'バックアップ完了: $id';
  }

  @override
  String backup_failed(String error) {
    return 'バックアップ失敗: $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'このBDFDスクリプトはコンパイルできませんでした:\n$summary';
  }

  @override
  String get bdfd_compile_error_simple => 'このBDFDスクリプトはコンパイルできませんでした。';

  @override
  String get bdfd_compiled_no_actions =>
      'このBDFDスクリプトは正常にコンパイルされましたが、アクションが生成されませんでした。';

  @override
  String get bdfd_docs_category_channels => 'チャンネル & スレッド';

  @override
  String get bdfd_docs_category_components => 'コンポーネント';

  @override
  String get bdfd_docs_category_control => '制御フロー';

  @override
  String get bdfd_docs_category_cooldowns => 'クールダウン';

  @override
  String get bdfd_docs_category_embeds => '埋め込み';

  @override
  String get bdfd_docs_category_guards => 'ガード & 権限';

  @override
  String get bdfd_docs_category_http => 'HTTP リクエスト';

  @override
  String get bdfd_docs_category_json => 'JSON';

  @override
  String get bdfd_docs_category_leaderboards => 'リーダーボード';

  @override
  String get bdfd_docs_category_math => '数学';

  @override
  String get bdfd_docs_category_messages => 'メッセージ & コンテンツ';

  @override
  String get bdfd_docs_category_misc => 'その他';

  @override
  String get bdfd_docs_category_modals => 'モーダル';

  @override
  String get bdfd_docs_category_moderation => 'モデレーション';

  @override
  String get bdfd_docs_category_reactions => 'リアクション';

  @override
  String get bdfd_docs_category_roles => 'ロール';

  @override
  String get bdfd_docs_category_text => 'テキスト & 文字列';

  @override
  String get bdfd_docs_category_tickets => 'チケット';

  @override
  String get bdfd_docs_category_variables => '変数';

  @override
  String get bdfd_docs_category_webhooks => 'Webhook';

  @override
  String get bdfd_docs_desc_and =>
      '論理AND — 複数の条件を結合します。すべてがtrueである必要があります。\n\n使用法: \$if[\$and[\$\n…';

  @override
  String get bdfd_docs_desc_awaitfunc =>
      'ユーザーの応答を待つコールバックを登録します。\n\n使用法: \$awaitFunc[name;use…';

  @override
  String get bdfd_docs_desc_callworkflow =>
      'Bot Creator専用 — 名前で別のワークフローを呼び出し、引数を渡します。\n\n構文:';

  @override
  String get bdfd_docs_desc_defer =>
      'インタラクション応答を遅延させ、処理時間を延長します。ユーザーには「考え中…」と表示されます。';

  @override
  String get bdfd_docs_desc_elseif =>
      '\$ifブロック内に代替条件を追加します。\$ifと\$endifの間に配置する必要があります。';

  @override
  String get bdfd_docs_desc_embedsuppresserrors =>
      '\$suppressErrorsと同じ — すべてのエラーメッセージを黙って抑制します。';

  @override
  String get bdfd_docs_desc_ephemeral =>
      '応答をコマンド実行者にのみ表示します。\$sendMessageの前に配置する必要があります。';

  @override
  String get bdfd_docs_desc_eval =>
      'BDFDスクリプト文字列を実行時に実行します。引数として渡されたコードは再コンパイルされます。';

  @override
  String get bdfd_docs_desc_for =>
      'Bot Creator専用 — コードブロックをN回繰り返します。\n\nシンプル: \$for[5]...\$endfor →';

  @override
  String get bdfd_docs_desc_httpaddheader =>
      '次のHTTPリクエストにヘッダーを追加します。ヘッダーは次の\$http…まで累積されます。';

  @override
  String get bdfd_docs_desc_httpget =>
      '指定されたURLにHTTP GETリクエストを送信します。事前に\$httpAddHeaderでヘッダーを設定してください。';

  @override
  String get bdfd_docs_desc_httpresult =>
      '最後のHTTPレスポンスのボディを返します。オプションでJSONパスを指定して値を抽出できます。';

  @override
  String get bdfd_docs_desc_if =>
      '条件ブロック。ネストと豊富な演算子をサポート: ==, !=, >=, <=, >, <, co';

  @override
  String get bdfd_docs_desc_jsonparse =>
      'JSON文字列を操作のためにメモリにパースします。すべてのJSON操作(\$jsonSet…';

  @override
  String get bdfd_docs_desc_jsonset =>
      '現在のJSONコンテキストに値を設定します。ドット記法のパスをサポート。\n\n使用法: \$';

  @override
  String get bdfd_docs_desc_jsonstringify =>
      '現在のJSONコンテキストを文字列に変換します。\$jsonParseと\$js…の後に使用します。';

  @override
  String get bdfd_docs_desc_loop =>
      'Bot Creator専用 — \$forのエイリアス。詳細は\$forを参照。\$endloopでブロックを閉じます。';

  @override
  String get bdfd_docs_desc_or =>
      '論理OR — 複数の条件を結合します。少なくとも1つがtrueである必要があります。\n\n使用法: \$i';

  @override
  String get bdfd_docs_desc_stop =>
      '現在のスクリプトの実行を即座に停止します。\$stop以降のアクションは実行されません。';

  @override
  String get bdfd_docs_desc_suppresserrors =>
      'エラーメッセージがユーザーに送信されるのを防ぎます。アクションが失敗してもエラーは抑制されます。';

  @override
  String get bdfd_docs_desc_try =>
      'エラーハンドリングのためにブロックをラップします。\n\n使用法:\n\$try\n  \$httpGet[https://api.example.co';

  @override
  String get bdfd_docs_desc_url =>
      'URLで使用するためにテキストをエンコードまたはデコードします。テキストをURLセーフにするには「encode」を、元に戻すには「decode」を使用します。\\n\\n使用法: \$url[encode;Hello world!!]';

  @override
  String get bdfd_docs_desc_workflowresponse =>
      'Bot Creator専用 — 最後の\$callWorkflowからの応答を返します。\n\n\$workf…を使用';

  @override
  String get bdfd_docs_empty => '一致する関数がありません。';

  @override
  String get bdfd_docs_no_params => 'パラメータなし — \$functionName として使用';

  @override
  String get bdfd_docs_parameters => 'パラメータ';

  @override
  String get bdfd_docs_search_hint => '関数を検索…';

  @override
  String get bdfd_docs_syntax => '構文';

  @override
  String get bdfd_docs_title => 'BDFD ドキュメント';

  @override
  String get bdfd_editor_auto_indent => '• Enterでスマート自動インデント';

  @override
  String get bdfd_editor_diagnostics_toggle => '診断パネルの切替';

  @override
  String get bdfd_editor_docs => 'BDFD 関数リファレンス';

  @override
  String get bdfd_editor_empty => '空のスクリプト — 入力を開始すると診断が表示されます。';

  @override
  String get bdfd_editor_includes => '含まれるもの:';

  @override
  String get bdfd_editor_indent_guides => '• ライブインデントガイド';

  @override
  String get bdfd_editor_quick_keys => '• BDFD記号用モバイルクイックキー';

  @override
  String get bdfd_editor_tap_hint => 'タップしてエディタを開く';

  @override
  String get bdfd_editor_title => 'BDFD エディタ';

  @override
  String get bdfd_editor_toggle_indent => 'インデントガイドの切替';

  @override
  String get bdfd_editor_ux_title => 'エディタ UX';

  @override
  String get bdfd_editor_wrap_toggle => '行の折り返し切替';

  @override
  String get bdfd_runtime_execution_error => 'このBDFDスクリプトの実行中にエラーが発生しました。';

  @override
  String get bot_home_create_command => '最初のコマンドを作成';

  @override
  String get bot_home_customize => 'ボットをカスタマイズ';

  @override
  String get bot_home_delete => 'アプリを削除';

  @override
  String get bot_home_delete_confirm => 'このアプリを削除してもよろしいですか？';

  @override
  String get bot_home_invite => 'ボットを招待';

  @override
  String get bot_home_invite_error => '招待リンクを開けませんでした';

  @override
  String get bot_home_ios_notice_content =>
      'ローカルモードでは、iOSがバックグラウンドでアプリを中断する場合があります。ボットは起動できますが、';

  @override
  String get bot_home_ios_notice_title => 'iOSのローカル制約';

  @override
  String get bot_home_log_desktop_stop => 'デスクトップボット停止要求';

  @override
  String get bot_home_log_start => 'ボット起動要求';

  @override
  String get bot_home_log_stop => 'ボット停止要求';

  @override
  String get bot_home_notif_required => 'ボットサービスを起動するには通知権限が必要です。';

  @override
  String get bot_home_section_danger => '危険ゾーン';

  @override
  String get bot_home_section_getting_started => 'はじめに';

  @override
  String get bot_home_section_monitoring => '監視';

  @override
  String get bot_home_section_tools => 'ツール';

  @override
  String get bot_home_service_not_started => 'フォアグラウンドサービスが起動しませんでした。';

  @override
  String get bot_home_start => 'ボット起動';

  @override
  String bot_home_start_error(String error) {
    return '起動できませんでした: $error';
  }

  @override
  String get bot_home_starting => '起動中…';

  @override
  String get bot_home_stop => 'ボット停止';

  @override
  String get bot_home_sync => 'アプリを同期';

  @override
  String get bot_home_sync_success => 'アプリが正常に同期されました';

  @override
  String get bot_home_pull => 'クラウドからダウンロード';

  @override
  String get bot_home_push => 'クラウドにアップロード';

  @override
  String get bot_home_pull_success => 'アプリをクラウドから正常にダウンロードしました';

  @override
  String get bot_home_push_success => 'アプリをクラウドに正常にアップロードしました';

  @override
  String get bot_home_version_history => 'バージョン履歴';

  @override
  String get bot_config_versions_title => 'バージョン履歴';

  @override
  String get bot_config_versions_empty => '以前のバージョンは見つかりません';

  @override
  String get bot_config_versions_restore => '復元';

  @override
  String get bot_config_versions_restore_confirm =>
      'このバージョンを復元しますか？現在の設定は先にバックアップされます。';

  @override
  String get bot_config_versions_restored => '設定が正常に復元されました！';

  @override
  String get bot_config_versions_error => 'バージョンの読み込みに失敗しました';

  @override
  String get bot_config_versions_restore_error => 'バージョンの復元に失敗しました';

  @override
  String get bot_home_pull_dialog_changes => '適用する変更:';

  @override
  String get bot_home_pull_dialog_local => 'ローカル (端末)';

  @override
  String get bot_home_pull_dialog_local_only => 'ローカルのみ (保持)';

  @override
  String get bot_home_pull_dialog_local_preserved => 'クラウドにないローカルコマンドは保持されます。';

  @override
  String get bot_home_pull_dialog_new_commands => '新しいコマンド';

  @override
  String get bot_home_pull_dialog_remote => 'リモート (クラウド)';

  @override
  String get bot_home_pull_dialog_unchanged => '変更なし';

  @override
  String get bot_home_pull_dialog_up_to_date => '既に最新です — 変更は必要ありません。';

  @override
  String get bot_home_pull_dialog_updated_commands => '更新されたコマンド';

  @override
  String get bot_home_push_refused_empty =>
      'プッシュ拒否: ローカル設定が空または破損しています。コマンドを確認してください。';

  @override
  String get bot_home_token_invalid_content =>
      '提供されたトークンでDiscordに接続できません。無効か失効している可能性があります。';

  @override
  String get bot_home_token_invalid_title => 'トークンが無効のようです';

  @override
  String get bot_home_view_logs => 'ボットログを表示';

  @override
  String get bot_home_view_replay => 'デバッガーリプレイを表示';

  @override
  String get bot_home_view_stats => 'ボット統計を表示';

  @override
  String get bot_logs_copied => 'ログをコピーしました';

  @override
  String get bot_logs_disable_debug => 'デバッグログを無効化';

  @override
  String get bot_logs_empty => 'まだログがありません';

  @override
  String get bot_logs_enable_debug => 'デバッグログを有効化';

  @override
  String get bot_logs_filter_count => '表示ログ数';

  @override
  String get bot_logs_go_to_bottom => '最下部へ';

  @override
  String get bot_logs_go_to_latest => '最新ログへ';

  @override
  String get bot_logs_newest_first => '新しい順';

  @override
  String get bot_logs_oldest_first => '古い順';

  @override
  String bot_logs_ram(String memory) {
    return 'ボットプロセスRAM: $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return '推定ボットRAM: $memory';
  }

  @override
  String get bot_logs_raw_mode => 'コンパクト生ログ';

  @override
  String get bot_logs_rich_mode => 'リッチフォーマットログ';

  @override
  String get bot_logs_show_all => 'すべて表示';

  @override
  String get bot_logs_show_less => '表示を減らす';

  @override
  String get bot_logs_show_more => 'もっと表示';

  @override
  String bot_logs_show_n(int count) {
    return '$count 件のログを表示';
  }

  @override
  String get bot_logs_title => 'ボットログ';

  @override
  String get bot_offline_token_desc =>
      'トークンが無効または不足しています。新しいDiscordボットトークンを入力して接続を復元してください。';

  @override
  String get bot_settings_activity_state_label => 'アクティビティ状態 (任意)';

  @override
  String get bot_settings_activity_url_label => 'ストリームURL (ストリーミング用)';

  @override
  String get bot_settings_add_status => 'アクティビティを追加';

  @override
  String get bot_settings_app_flags => 'アプリケーションフラグ';

  @override
  String get bot_settings_avatar_clear_selection => '選択をクリア';

  @override
  String get bot_settings_avatar_important_note =>
      '重要: プロフィール変更（ユーザー名とアバター）は、保存時にのみDiscordに適用されます。';

  @override
  String get bot_settings_avatar_local_path => 'アバターのローカルファイルパス';

  @override
  String get bot_settings_avatar_none_selected =>
      '新しい画像が選択されていません。「参照」をクリックして選択してください。';

  @override
  String get bot_settings_avatar_path_hint => '/absolute/path/to/avatar.png';

  @override
  String get bot_settings_avatar_preview_error => '画像をプレビューできません';

  @override
  String get bot_settings_avatar_preview_label => 'アバタープレビュー';

  @override
  String get bot_settings_avatar_selected => '選択された画像:';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return '選択されたファイル: $path';
  }

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return '未対応のアバター形式: $ext。対応形式: $formats。';
  }

  @override
  String get bot_settings_browse => '参照';

  @override
  String get bot_settings_cancel_token_edit_btn => 'トークン編集をキャンセル';

  @override
  String get bot_settings_danger_zone => '危険ゾーン';

  @override
  String get bot_settings_delete_bot => 'ボットを削除';

  @override
  String get bot_settings_delete_bot_btn => '完全に削除';

  @override
  String get bot_settings_delete_bot_desc =>
      'この操作は元に戻せません。すべてのローカルデータとリモート設定が完全に削除されます。';

  @override
  String bot_settings_delete_desc(String id) {
    return 'ボット $id を削除してもよろしいですか？すべてのデータが失われます。';
  }

  @override
  String get bot_settings_delete_title => '削除の確認';

  @override
  String get bot_settings_edit_token_btn => 'トークンを編集';

  @override
  String get bot_settings_export_import => 'エクスポート / インポート';

  @override
  String get bot_settings_export_import_desc =>
      'ボット設定をZIPファイルとしてエクスポートまたはインポートします。';

  @override
  String get bot_settings_gateway_intents => 'ゲートウェイインテント設定';

  @override
  String get bot_settings_gateway_intents_desc =>
      'ボットに必要なインテントを選択してください。Discord Developer Portalで設定してください。';

  @override
  String get bot_settings_intents_saved => 'インテントが正常に保存されました';

  @override
  String get bot_settings_no_activities => 'アクティビティが設定されていません';

  @override
  String get bot_settings_presence_dnd => '取り込み中';

  @override
  String get bot_settings_presence_idle => '退席中';

  @override
  String get bot_settings_presence_invisible => 'オフライン表示';

  @override
  String get bot_settings_presence_online => 'オンライン';

  @override
  String get bot_settings_presence_status_label => 'プレゼンス';

  @override
  String get bot_settings_presence_status_title => 'ボットプレゼンス状態';

  @override
  String get bot_settings_profile_saved => 'プロフィール/ステータスが正常に適用されました';

  @override
  String get bot_settings_profile_title => 'ボットプロフィール';

  @override
  String get bot_settings_remove_status => 'アクティビティを削除';

  @override
  String get bot_settings_save_intents_btn => 'インテントを保存';

  @override
  String get bot_settings_save_intents_caption => 'ゲートウェイインテント設定のみを更新します。';

  @override
  String get bot_settings_save_profile_caption =>
      'ユーザー名/アバターを即座に適用し、ステータスローテーションを保存します。';

  @override
  String get bot_settings_save_profile_status_btn => 'プロフィールとステータスを保存';

  @override
  String get bot_settings_save_success => '設定が正常に保存されました';

  @override
  String get bot_settings_save_token_btn => 'トークンとインテントを保存';

  @override
  String get bot_settings_save_token_caption =>
      'トークン変更は保護されています。まず「トークンを編集」をクリックしてから保存してください。';

  @override
  String get bot_settings_save_token_first =>
      'プロフィール/ステータス変更を適用する前に、まずトークンを保存してください。';

  @override
  String get bot_settings_save_token_only_btn => 'トークンを保存';

  @override
  String bot_settings_status_item_title(int index) {
    return 'アクティビティ $index';
  }

  @override
  String get bot_settings_status_max_interval => '最大間隔 (秒)';

  @override
  String get bot_settings_status_min_interval => '最小間隔 (秒)';

  @override
  String get bot_settings_status_rotation_desc =>
      '1つ以上のアクティビティを追加してください。各アクティビティにはタイプ、名前、最小/最大間隔(秒)が必要です。';

  @override
  String get bot_settings_status_rotation_title => 'アクティビティローテーション';

  @override
  String get bot_settings_status_text_label => 'アクティビティ名';

  @override
  String get bot_settings_status_type_competing => '競技中';

  @override
  String get bot_settings_status_type_label => 'タイプ';

  @override
  String get bot_settings_status_type_listening => 'リスニング';

  @override
  String get bot_settings_status_type_playing => 'プレイ中';

  @override
  String get bot_settings_status_type_streaming => '配信中';

  @override
  String get bot_settings_status_type_watching => '視聴中';

  @override
  String get bot_settings_tab_advanced => '詳細 & メンテナンス';

  @override
  String get bot_settings_tab_general => '一般';

  @override
  String get bot_settings_tab_intents => 'インテント & 権限';

  @override
  String get bot_settings_tab_presence => 'プレゼンス & ステータス';

  @override
  String get bot_settings_title => 'ボットのカスタマイズ / プロフィール';

  @override
  String get bot_settings_token_hidden_desc => 'トークン入力は安全のためデフォルトで非表示です。';

  @override
  String get bot_settings_token_hint => 'ボットトークンをここに入力';

  @override
  String get bot_settings_token_mismatch_confirm => 'それでもトークンを置き換える';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'このトークンはボット $newId のものですが、現在のデータはボット $oldId 用です。コマンドと設定が失われる可能性があります。';
  }

  @override
  String get bot_settings_token_mismatch_title => '異なるボットが検出されました';

  @override
  String get bot_settings_token_required => 'ボットトークンが必要です。';

  @override
  String get bot_settings_token_saved => 'トークンが正常に保存されました';

  @override
  String get bot_settings_token_title => 'ボットトークン';

  @override
  String get bot_settings_update_token => 'ボットトークンを更新';

  @override
  String get bot_settings_username_hint => '現在のユーザー名を維持する場合は空欄';

  @override
  String get bot_settings_username_override => 'ユーザー名上書き';

  @override
  String get bot_settings_workflow_docs => 'ドキュメントセンター';

  @override
  String get bot_settings_workflow_docs_desc =>
      'コマンド、ワークフロー、ランタイム変数、実行動作に関する一元化されたドキュメント。';

  @override
  String get bot_stats_collecting => '収集中…';

  @override
  String get bot_stats_cpu => 'ボットプロセスCPU';

  @override
  String get bot_stats_notes =>
      '注意: CPUはAndroid/Linuxで利用可能。ストレージ = アプリ内のボットデータファイル。';

  @override
  String get bot_stats_ram_estimated => 'ボットRAMのみ (推定)';

  @override
  String get bot_stats_ram_process => 'ボットプロセスRAM';

  @override
  String get bot_stats_source_local_hosting => 'ソース: ローカルホスティング';

  @override
  String get bot_stats_source_runner_api => 'ソース: Runner API';

  @override
  String get bot_stats_storage => 'ボットストレージ (アプリデータ)';

  @override
  String get bot_stats_title => 'ボット統計';

  @override
  String get cancel => 'キャンセル';

  @override
  String get close => '閉じる';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      '\$ を入力して関数名を書き始めると、クイックスクリプト候補が表示されます。';

  @override
  String get cmd_bdfd_autocomplete_title => 'BDFD プレフィックスオートコンプリート';

  @override
  String get cmd_bdfd_diagnostics_clean => '現在のスクリプトに問題は検出されませんでした。';

  @override
  String get cmd_bdfd_diagnostics_error => 'エラー';

  @override
  String get cmd_bdfd_diagnostics_title => 'BDFD 診断';

  @override
  String get cmd_bdfd_diagnostics_warning => '警告';

  @override
  String get cmd_bdfd_script_empty_error => 'BDFDスクリプト本文は空にできません。';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator';

  @override
  String get cmd_bdfd_script_label => 'BDFD スクリプト本文';

  @override
  String get cmd_bdfd_script_validation_error =>
      'このBDFDスクリプトにはまだ診断メッセージが含まれています:';

  @override
  String get cmd_create_tooltip => 'コマンドを作成';

  @override
  String get cmd_dart_diagnostics_clean => '現在のDartスクリプトに問題は検出されませんでした。';

  @override
  String get cmd_dart_diagnostics_error => 'エラー';

  @override
  String get cmd_dart_diagnostics_title => 'Dart 診断';

  @override
  String get cmd_dart_diagnostics_warning => '警告';

  @override
  String get cmd_dart_script_hint => 'return \"Hello from Dart Direct\";';

  @override
  String get cmd_dart_script_label => 'Dart スクリプト本文';

  @override
  String get cmd_delete_tooltip => 'コマンドを削除';

  @override
  String get cmd_delete_confirm => 'コマンド "{name}" を削除しますか？';

  @override
  String get cmd_delete_success => 'コマンド "{name}" を削除しました';

  @override
  String get cmd_batch_delete_confirm => '{count} 個のコマンドを削除しますか？';

  @override
  String get cmd_batch_delete_success => '{count} 個のコマンドを削除しました';

  @override
  String get cmd_deploy_close_button => '閉じる';

  @override
  String get cmd_deploy_cloud_sync_subtitle => 'オンラインスペースとの安全な同期';

  @override
  String get cmd_deploy_cloud_sync_title => 'クラウドバックアップ';

  @override
  String cmd_deploy_config_subtitle(String name) {
    return '/$name の設定';
  }

  @override
  String get cmd_deploy_discord_sync_subtitle => 'コマンドをDiscord APIに公開中';

  @override
  String get cmd_deploy_discord_sync_title => 'Discord同期';

  @override
  String get cmd_deploy_failed_title => 'デプロイ失敗';

  @override
  String get cmd_deploy_hot_reload_subtitle => 'ボットランナーの即時更新';

  @override
  String get cmd_deploy_hot_reload_title => 'ホットリロード';

  @override
  String get cmd_deploy_in_progress_title => 'デプロイ中...';

  @override
  String get cmd_deploy_local_save_subtitle => 'コマンドをデバイスに保存中';

  @override
  String get cmd_deploy_local_save_title => 'ローカル保存';

  @override
  String get cmd_deploy_reload_bot_subtitle => 'ホットリロード設定を適用中';

  @override
  String get cmd_deploy_reload_bot_title => 'ボットを再読み込み中';

  @override
  String get cmd_deploy_retry_button => '再試行';

  @override
  String get cmd_deploy_success_title => 'デプロイ成功！';

  @override
  String cmd_deploy_success_toast(String name) {
    return 'コマンド \"$name\" がデプロイされ、有効になりました！';
  }

  @override
  String get cmd_editor_mode_advanced => '詳細モード';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'カスタムレスポンス、オプション、アクションビルダーを備えたフルエディタ。';

  @override
  String get cmd_editor_mode_locked => 'このコマンドでは詳細モードがロックされています。';

  @override
  String get cmd_editor_mode_simple => 'シンプルモード';

  @override
  String get cmd_editor_mode_simple_desc =>
      'ガイド付きオプションと事前設定されたアクションで素早くコマンドを構築。';

  @override
  String get cmd_editor_mode_switch_adv => '詳細モードに切り替え';

  @override
  String get cmd_editor_mode_switch_adv_confirm => '切り替え';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'この切り替えはこのコマンドでは一方通行です。シンプルモードに戻ることはできません。';

  @override
  String get cmd_editor_mode_switch_adv_title => '詳細モードに切り替えますか？';

  @override
  String get cmd_editor_mode_title => '編集モード';

  @override
  String get cmd_error_fill_fields => 'すべてのフィールドに入力してください';

  @override
  String get cmd_execution_mode_bdfd => 'BDFD スクリプトモード';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'コマンド定義をビジュアルに保ちながら、コマンド本文をBDFDスタイルのスクリプトとして記述します。';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'スクリプトは内部アクションにコンパイルされます。編集中に診断が表示されます。無効なスクリプトは保存できません。';

  @override
  String get cmd_execution_mode_dart => 'Dart ダイレクトモード';

  @override
  String get cmd_execution_mode_dart_desc => 'ランタイム診断付きでコマンド本文を直接Dartで記述します。';

  @override
  String get cmd_execution_mode_dart_note =>
      'Dartコードはサンドボックスエンジンを通じて実行時にコンパイルされます。スクリプトは決定論的かつ安全に保ってください。';

  @override
  String get cmd_execution_mode_desc =>
      'コマンドメタデータはビジュアルビルダーに残ります。コマンド本文の実行方法を選択してください。';

  @override
  String get cmd_execution_mode_title => '実行モード';

  @override
  String get cmd_execution_mode_workflow => 'ワークフローモード';

  @override
  String get cmd_execution_mode_workflow_desc =>
      '既存のビジュアルレスポンスとアクションビルダーを使用します。';

  @override
  String get cmd_execution_mode_workflow_note =>
      'ワークフローモードは現在の本番パスであり、引き続き完全にサポートされています。';

  @override
  String get cmd_migrate_bdfd_to_dart_action => '移行';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      '現在のBDFDスクリプトからDart移行スキャフォールドを生成します。';

  @override
  String get cmd_offline_incomplete_warning =>
      'このコマンドは完全に読み込めませんでした（オフラインまたはトークン無効）。有効なトークンを接続してください。';

  @override
  String get cmd_show_variables => '変数ドキュメントを開く';

  @override
  String get cmd_simple_action_add_role => 'ロールを追加';

  @override
  String get cmd_simple_action_add_role_desc =>
      '選択した /role を選択した /user に付与します。';

  @override
  String get cmd_simple_action_ban => 'ユーザーを追放';

  @override
  String get cmd_simple_action_ban_delete_days_hint => '削除する最近のメッセージの日数 (0〜7)';

  @override
  String get cmd_simple_action_ban_delete_days_label => '追放時のメッセージ削除日数';

  @override
  String get cmd_simple_action_ban_desc => '選択した /user をサーバーから追放します。';

  @override
  String get cmd_simple_action_create_invite => '招待を作成';

  @override
  String get cmd_simple_action_create_invite_desc =>
      '現在のチャンネルまたはオプションの /channel の招待を作成します。';

  @override
  String get cmd_simple_action_create_poll => '投票を作成';

  @override
  String get cmd_simple_action_create_poll_desc =>
      '動的な /question と固定の回答選択肢で投票を作成します。';

  @override
  String get cmd_simple_action_delete => 'メッセージを削除';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      '/count が指定されていない場合に使用';

  @override
  String get cmd_simple_action_delete_default_count_label => 'デフォルト削除数';

  @override
  String get cmd_simple_action_delete_desc =>
      '現在のチャンネルのメッセージを削除します (オプションの /count)。';

  @override
  String get cmd_simple_action_kick => 'ユーザーをキック';

  @override
  String get cmd_simple_action_kick_desc => '選択した /user をサーバーからキックします。';

  @override
  String get cmd_simple_action_mute => 'ユーザーをミュート';

  @override
  String get cmd_simple_action_mute_desc => '選択した /user を一時的にミュートします。';

  @override
  String get cmd_simple_action_mute_duration_hint => '例: 10m, 2h, 1d, または秒数';

  @override
  String get cmd_simple_action_mute_duration_label => 'ミュート時間';

  @override
  String get cmd_simple_action_pin => 'メッセージをピン留め';

  @override
  String get cmd_simple_action_pin_desc =>
      '/message_id を使用して現在のチャンネルのメッセージをピン留めします。';

  @override
  String get cmd_simple_action_reason_hint => 'モデレーションアクションで共有されるオプションの理由';

  @override
  String get cmd_simple_action_reason_label => '監査ログの理由';

  @override
  String get cmd_simple_action_remove_role => 'ロールを削除';

  @override
  String get cmd_simple_action_remove_role_desc =>
      '選択した /role を選択した /user から削除します。';

  @override
  String get cmd_simple_action_send_message => 'メッセージを送信';

  @override
  String get cmd_simple_action_send_message_desc => '現在のチャンネルに追加メッセージを送信します。';

  @override
  String get cmd_simple_action_send_message_hint => 'メッセージ送信アクションで送信されるメッセージ';

  @override
  String get cmd_simple_action_send_message_label => 'アクションメッセージ';

  @override
  String get cmd_simple_action_unban => '追放解除';

  @override
  String get cmd_simple_action_unban_desc =>
      '指定された /user_id 文字列でユーザーの追放を解除します。';

  @override
  String get cmd_simple_action_unmute => 'ミュート解除';

  @override
  String get cmd_simple_action_unmute_desc => '選択した /user のタイムアウトを解除します。';

  @override
  String get cmd_simple_action_unpin => 'ピン留め解除';

  @override
  String get cmd_simple_action_unpin_desc =>
      '/message_id を使用して現在のチャンネルのメッセージのピン留めを解除します。';

  @override
  String get cmd_simple_actions_desc => 'このコマンドの動作を選択してください。オプションは自動生成されます。';

  @override
  String get cmd_simple_actions_title => 'シンプルアクション';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'シンプルモードでは「ユーザー追放」と「追放解除」を同時に有効にできません。';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'シンプルモードでは「ユーザーミュート」と「ミュート解除」を同時に有効にできません。';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'シンプルモードでは「ピン留め」と「ピン留め解除」を同時に有効にできません。';

  @override
  String get cmd_simple_execution_desc => 'シンプルモードを離れずに生成されたアクションを微調整します。';

  @override
  String get cmd_simple_execution_title => '実行設定';

  @override
  String get cmd_simple_generated_none =>
      'まだオプションが生成されていません。少なくとも1つのアクションを選択してください。';

  @override
  String get cmd_simple_generated_options => '生成されたコマンドオプション';

  @override
  String get cmd_simple_group_messages_desc =>
      '現在のコンテキストで動作するメッセージとチャンネルアクション。';

  @override
  String get cmd_simple_group_messages_title => 'メッセージ';

  @override
  String get cmd_simple_group_moderation_desc =>
      'ガイド付きオプション付きのメンバーとモデレーションアクション。';

  @override
  String get cmd_simple_group_moderation_title => 'モデレーション';

  @override
  String get cmd_simple_group_utility_desc => '招待や投票などの便利な追加機能。';

  @override
  String get cmd_simple_group_utility_title => 'ユーティリティ';

  @override
  String get cmd_simple_invite_max_age_hint => '有効期限なしは0、最大604800';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      '招待の有効期限は0から604800秒の間の数値である必要があります。';

  @override
  String get cmd_simple_invite_max_age_label => '招待有効期限 (秒)';

  @override
  String get cmd_simple_invite_max_uses_hint => '無制限は0';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      '招待の最大使用回数は0から1000000の間の数値である必要があります。';

  @override
  String get cmd_simple_invite_max_uses_label => '最大使用回数';

  @override
  String get cmd_simple_invite_settings_desc => '生成された招待作成アクションで使用されるデフォルト値。';

  @override
  String get cmd_simple_invite_settings_title => '招待設定';

  @override
  String get cmd_simple_invite_temporary_desc => 'ロールを取得する前に退出したメンバーは削除されます。';

  @override
  String get cmd_simple_invite_temporary_label => '一時メンバーシップ';

  @override
  String get cmd_simple_invite_unique_desc => '既存の招待を再利用せず、常に新しい招待を作成します。';

  @override
  String get cmd_simple_invite_unique_label => '一意の招待を強制';

  @override
  String get cmd_simple_option_channel => '/channel (チャンネル)';

  @override
  String get cmd_simple_option_channel_desc => '招待作成用のオプションのチャンネル上書き';

  @override
  String get cmd_simple_option_count => '/count (整数)';

  @override
  String get cmd_simple_option_count_desc => '削除するメッセージ数';

  @override
  String get cmd_simple_option_message_id => '/message_id (テキスト)';

  @override
  String get cmd_simple_option_message_id_desc => '対象のメッセージID';

  @override
  String get cmd_simple_option_question => '/question (テキスト)';

  @override
  String get cmd_simple_option_question_desc => '投票の質問';

  @override
  String get cmd_simple_option_role => '/role (ロール)';

  @override
  String get cmd_simple_option_role_desc => '対象ロール';

  @override
  String get cmd_simple_option_user => '/user (ユーザー)';

  @override
  String get cmd_simple_option_user_desc => '対象ユーザー';

  @override
  String get cmd_simple_option_user_id => '/user_id (テキスト)';

  @override
  String get cmd_simple_option_user_id_desc => '追放解除するユーザーID';

  @override
  String get cmd_simple_poll_answers_hint => '1行に1つの回答、またはカンマ区切り。最小2、最大10。';

  @override
  String get cmd_simple_poll_answers_invalid =>
      '投票の回答は2〜10個の空でない選択肢を含む必要があります。';

  @override
  String get cmd_simple_poll_answers_label => '投票の回答';

  @override
  String get cmd_simple_poll_duration_hint => '1〜168時間';

  @override
  String get cmd_simple_poll_duration_invalid => '投票時間は1〜168時間の間の数値である必要があります。';

  @override
  String get cmd_simple_poll_duration_label => '投票時間 (時間)';

  @override
  String get cmd_simple_poll_multiselect_desc => 'ユーザーは複数の選択肢を選べます。';

  @override
  String get cmd_simple_poll_multiselect_label => '複数回答を許可';

  @override
  String get cmd_simple_poll_settings_desc => '生成された投票作成アクションで使用されるデフォルト値。';

  @override
  String get cmd_simple_poll_settings_title => '投票設定';

  @override
  String get cmd_simple_response_desc => 'アクション実行後にユーザーに返信されるメッセージ。';

  @override
  String get cmd_simple_response_embeds_desc => '最終応答と共に送信されるオプションの埋め込み。';

  @override
  String get cmd_simple_response_embeds_title => '応答埋め込み';

  @override
  String get cmd_simple_response_hint => '完了 ✅';

  @override
  String get cmd_simple_response_title => '最終応答';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'エフェメラル';

  @override
  String get cmd_simple_response_visibility_label => '応答の可視性';

  @override
  String get cmd_simple_response_visibility_public => '公開';

  @override
  String get cmd_simple_send_message_required => '保存する前にアクションメッセージを入力してください。';

  @override
  String get cmd_variables_title => 'コマンド変数';

  @override
  String get command_awaited_error => 'エラー';

  @override
  String get command_awaited_filter_hint => '例: <numeric> または <yes/no/cancel>';

  @override
  String get command_awaited_filter_label => 'フィルター (オプション)';

  @override
  String get command_awaited_name_hint => '例: say';

  @override
  String get command_awaited_name_label => '待機コールバック名';

  @override
  String get command_awaited_preset_active => '待機コールバックプリセット';

  @override
  String get command_awaited_preset_button => '待機コールバックプリセットを使用';

  @override
  String get command_awaited_preset_desc =>
      'コマンド名が自動生成され、内部レガシーコールバックとして保存されます。';

  @override
  String get command_awaited_success => '成功';

  @override
  String get command_context_bot_dm => 'Bot DM';

  @override
  String get command_context_group_dm => 'グループDM / その他';

  @override
  String get command_context_guild => 'サーバー';

  @override
  String get command_description_length => 'コマンドの説明は最大100文字である必要があります';

  @override
  String get command_description_required => 'コマンドの説明を入力してください';

  @override
  String get command_edit_raw_name => '生の名前を編集';

  @override
  String get command_error_missing_bot_id => 'ローカルコマンド保存にボットIDがありません。';

  @override
  String get command_execution_error => 'このコマンドの実行中にエラーが発生しました。';

  @override
  String get command_export_tooltip => 'コマンドペイロードをエクスポート';

  @override
  String get command_import_tooltip => 'コマンドペイロードをインポート';

  @override
  String get command_info_desc => '基本メタデータと利用可能性';

  @override
  String get command_info_title => 'コマンド情報';

  @override
  String get command_integration_guild => 'サーバーインストール';

  @override
  String get command_integration_label => 'このコマンドを使用できる場所';

  @override
  String get command_integration_user => 'ユーザーインストール';

  @override
  String get command_legacy_mode_subtitle =>
      '位置オプションを使用します (例: !config #channel)。';

  @override
  String get command_legacy_mode_title => 'このコマンドでレガシーモードを有効にする';

  @override
  String get command_legacy_prefix_desc =>
      'messageCreateから<prefix><command>でコマンドを処理します。';

  @override
  String get command_legacy_prefix_title => 'レガシープレフィックスモード';

  @override
  String get command_legacy_preset_desc =>
      '内部待機コールバックトリガーを生成し、このコマンドを必要なローカルレガシー設定に切り替えます。';

  @override
  String get command_legacy_preset_title => 'レガシープリセット';

  @override
  String get command_legacy_response_label => 'レガシー応答モード';

  @override
  String get command_modal_disabled_legacy => 'モーダルはレガシーモードでは無効です。';

  @override
  String get command_name_generated => '待機コールバックプリセットによって生成されました。';

  @override
  String get command_name_label => '名前';

  @override
  String get command_not_found => 'コマンドが見つかりません';

  @override
  String get command_options_legacy_params => 'レガシー位置パラメータ (順序: 必須、次にオプション)';

  @override
  String get command_options_slash_params => 'スラッシュコマンドパラメータ';

  @override
  String get command_options_title => 'コマンドオプション';

  @override
  String get command_payload_hint => 'コマンドペイロード';

  @override
  String get command_permissions_admin_warning =>
      '管理者が選択されました: 他の権限チェックをバイパスします。';

  @override
  String get command_permissions_bitfield => '計算された権限ビットフィールド';

  @override
  String get command_permissions_bitfield_helper => '選択された権限から自動計算されます。';

  @override
  String command_permissions_count(int count) {
    return '$count 件の権限が選択されました';
  }

  @override
  String get command_permissions_label => 'デフォルトメンバー権限 (オプション)';

  @override
  String get command_permissions_none => '選択なし (全員がコマンドを使用可能)';

  @override
  String get command_permissions_tip =>
      'ヒント: すべて未チェックにすると、デフォルトで全員がコマンドを使用できます。';

  @override
  String get command_permissions_title => '権限を選択';

  @override
  String command_permissions_unknown_bits(String bits) {
    return '警告: 保存データから不明な権限ビットが検出され、保持されました: $bits';
  }

  @override
  String get command_prefix_helper =>
      'テンプレートとスコープ変数をサポート (bc_ はオプション)。例: ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint => '例: ? または ((guild.prefix | !))';

  @override
  String get command_prefix_override_label => 'プレフィックス上書き (オプション)';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_scope_label => 'コマンドのスコープ (コンテキスト)';

  @override
  String get command_subcommand_workflow_desc => '設定するサブコマンドを選択してください。';

  @override
  String get command_subcommand_workflow_title => 'サブコマンドワークフロー';

  @override
  String command_sync_failed_local(String error) {
    return 'ローカルに保存されました。Discord同期に失敗: $error';
  }

  @override
  String get command_target_subcommand => '対象サブコマンド';

  @override
  String get command_type_label => 'コマンドタイプ';

  @override
  String get command_type_legacy => 'レガシーコマンド';

  @override
  String get command_type_locked => 'コマンドタイプは作成後に変更できません。';

  @override
  String get command_type_message => 'メッセージコマンド';

  @override
  String get command_type_slash => 'スラッシュコマンド';

  @override
  String get command_type_user => 'ユーザーコマンド';

  @override
  String get command_unsaved_confirm => '未保存の変更があります。破棄しますか？';

  @override
  String get command_unsaved_keep => '編集を続ける';

  @override
  String get command_unsaved_title => '未保存の変更';

  @override
  String get commands_all_folders => 'すべてのフォルダ';

  @override
  String get commands_create_button => 'コマンドを作成';

  @override
  String get commands_create_folder => 'フォルダを作成';

  @override
  String commands_create_from_query(String query) {
    return 'コマンド \"$query\" を作成';
  }

  @override
  String get commands_delete_folder => 'フォルダを削除';

  @override
  String get commands_delete_folder_desc => 'フォルダ内のコマンドは削除されず、フォルダ解除のみ行われます。';

  @override
  String get commands_empty => 'コマンドが見つかりません';

  @override
  String commands_error(String error) {
    return 'エラー: $error';
  }

  @override
  String get commands_filter_legacy_local => 'レガシーローカル';

  @override
  String get commands_filter_template => 'テンプレート';

  @override
  String get commands_filter_type_label => 'タイプ';

  @override
  String get commands_folder_hint => 'オプションのフォルダ名';

  @override
  String get commands_folder_label => 'フォルダ';

  @override
  String get commands_move_to_folder => 'フォルダに移動';

  @override
  String get commands_new_folder_hint => '新しいフォルダ名';

  @override
  String get commands_no_folder => 'フォルダなし';

  @override
  String get commands_no_match_filters => '現在のフィルターに一致するコマンドはありません。';

  @override
  String get commands_remove_from_folder => 'フォルダから削除';

  @override
  String get commands_rename_folder => 'フォルダ名を変更';

  @override
  String get commands_reorder_title => 'コマンドを整理';

  @override
  String get commands_search_hint => 'コマンドを検索...';

  @override
  String get commands_tab => 'コマンド';

  @override
  String get commands_tab_short => 'Cmd';

  @override
  String get commands_title => 'コマンド';

  @override
  String get common_add_argument => '引数を追加';

  @override
  String get common_add_option => 'オプションを追加';

  @override
  String get common_add_section => 'セクションを追加';

  @override
  String get common_all => 'すべて';

  @override
  String get common_apply => '適用';

  @override
  String get common_back => '戻る';

  @override
  String get common_bot => 'ボット';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get common_clear => 'クリア';

  @override
  String get common_close => '閉じる';

  @override
  String get common_custom_id => 'カスタムID';

  @override
  String get common_custom_id_required => 'カスタムID *';

  @override
  String get common_default => 'デフォルト';

  @override
  String get common_delete => '削除';

  @override
  String get common_description => '説明';

  @override
  String get common_disabled => '無効';

  @override
  String get common_edit => '編集';

  @override
  String get common_enabled => '有効';

  @override
  String get common_import => 'インポート';

  @override
  String get common_key => 'キー';

  @override
  String get common_label => 'ラベル';

  @override
  String get common_manage_workflows => 'ワークフローを管理';

  @override
  String get common_move_down => '下に移動';

  @override
  String get common_move_up => '上に移動';

  @override
  String get common_name => '名前';

  @override
  String get common_next => '次へ';

  @override
  String get common_none => 'なし';

  @override
  String get common_ok => 'OK';

  @override
  String get common_operator => '演算子';

  @override
  String get common_pick => '選択';

  @override
  String get common_placeholder => 'プレースホルダー';

  @override
  String get common_refresh => '更新';

  @override
  String get common_refresh_workflows => 'ワークフローを更新';

  @override
  String get common_remove => '削除';

  @override
  String get common_required => '必須';

  @override
  String get common_retry => '再試行';

  @override
  String get common_save => '保存';

  @override
  String get common_search => '検索';

  @override
  String get common_static_options => '静的オプション';

  @override
  String get common_style => 'スタイル';

  @override
  String get common_type => 'タイプ';

  @override
  String get common_url => 'URL';

  @override
  String get common_value => '値';

  @override
  String get common_workflow => 'ワークフロー';

  @override
  String get component_accent_color => 'アクセントカラー (Hex, 例: FF0000)';

  @override
  String get component_add_checkbox_option => 'チェックボックスオプションを追加';

  @override
  String get component_add_child => '子コンポーネントを追加';

  @override
  String get component_add_media_item => 'メディア項目を追加';

  @override
  String get component_add_radio_option => 'ラジオオプションを追加';

  @override
  String get component_add_root => 'ルートコンポーネントを追加';

  @override
  String get component_add_text_display => 'テキスト表示を追加';

  @override
  String get component_add_tooltip => 'コンポーネントを追加';

  @override
  String get component_block_label_style => 'スタイル';

  @override
  String get component_block_workflow => 'ワークフロー';

  @override
  String get component_checkbox_options => 'チェックボックスオプション';

  @override
  String get component_checked_by_default => 'デフォルトでチェック';

  @override
  String get component_choose_color => '色を選択';

  @override
  String get component_component_to_wrap => 'ラップするコンポーネント:';

  @override
  String get component_custom_id => 'カスタムID';

  @override
  String get component_custom_id_required => 'カスタムID *';

  @override
  String get component_default_choice_label => '選択肢';

  @override
  String get component_default_option_label => 'オプション';

  @override
  String get component_empty_option => '空';

  @override
  String get component_file_url => 'ファイルURL';

  @override
  String get component_label => 'ラベル';

  @override
  String get component_label_title => 'ラベルタイトル';

  @override
  String get component_markdown_content => 'Markdown コンテンツ';

  @override
  String get component_max_selections => '最大選択数';

  @override
  String get component_media_url => '画像 / 動画 URL';

  @override
  String get component_media_urls => 'メディアURL';

  @override
  String get component_min_selections => '最小選択数';

  @override
  String get component_new_checkbox => '新しいチェックボックス';

  @override
  String get component_new_option => '新しいオプション';

  @override
  String get component_new_radio => '新しいラジオ';

  @override
  String get component_not_implemented => 'エディタはまだ実装されていません';

  @override
  String get component_on_click_workflow => 'クリック時にワークフロー';

  @override
  String get component_on_select_workflow => '選択時にワークフロー';

  @override
  String get component_options => 'オプション';

  @override
  String get component_pick_accent_color => 'アクセントカラーを選択';

  @override
  String get component_placeholder => 'プレースホルダー';

  @override
  String get component_radio_options => 'ラジオオプション';

  @override
  String get component_remove_confirm => 'このコンポーネントをレイアウトから削除します。続行しますか？';

  @override
  String get component_remove_row_title => 'アクション行を削除';

  @override
  String get component_remove_title => 'コンポーネントを削除';

  @override
  String get component_section_accessory => 'アクセサリノード (オプション)';

  @override
  String get component_section_text_displays => 'テキスト表示';

  @override
  String get component_selection_range => '選択範囲';

  @override
  String get component_spacing_large => '大スペーシング';

  @override
  String get component_spacing_small => '小スペーシング';

  @override
  String get component_style => 'スタイル';

  @override
  String get component_thumbnail_url => 'サムネイルURL';

  @override
  String get component_unknown_component => '不明なコンポーネント';

  @override
  String get component_url => 'URL';

  @override
  String get component_validation_required => '必須';

  @override
  String get component_value_hint => 'コンポーネント値のヒント';

  @override
  String get component_visible_divider => '可視線';

  @override
  String get component_workflow_args_hint => '例: ticketId = ((opts.ticket))';

  @override
  String get component_workflow_args_title => 'ワークフロー呼び出し引数';

  @override
  String get component_workflow_click_hint => 'クリック時に実行する保存済みワークフロー名';

  @override
  String get component_workflow_optional => 'ワークフロー呼び出し (オプション)';

  @override
  String get component_workflow_select_hint => '選択時に実行する保存済みワークフロー名';

  @override
  String get confirm => '確認';

  @override
  String get copy => 'コピー';

  @override
  String get create => '作成';

  @override
  String get dart_editor_empty => '空のスクリプト — 入力を開始するとDart診断が表示されます。';

  @override
  String get dart_editor_tap_hint => 'タップしてDartエディタを開く';

  @override
  String get dart_editor_title => 'Dart エディタ';

  @override
  String get dashboard_analysis_period => '分析期間';

  @override
  String dashboard_error(String error) {
    return '統計を読み込めませんでした: $error';
  }

  @override
  String get dashboard_error_rate => 'エラー率';

  @override
  String get dashboard_execution_health_title => '実行健全性';

  @override
  String dashboard_executions(int count) {
    return '$count 実行';
  }

  @override
  String get dashboard_failed_commands => '失敗';

  @override
  String get dashboard_loading => '統計を読み込み中...';

  @override
  String get dashboard_no_data => 'まだコマンド使用データがありません。ボットを実行して追跡を開始してください。';

  @override
  String get dashboard_p50_latency => 'レイテンシ p50';

  @override
  String get dashboard_p95_latency => 'レイテンシ p95';

  @override
  String get dashboard_period_24h => '過去24時間';

  @override
  String get dashboard_period_30d => '過去30日間';

  @override
  String get dashboard_period_7d => '過去7日間';

  @override
  String get dashboard_premium_analytics_desc =>
      'エラー率、レイテンシパーセンタイル、ロケールインサイトをアンロックします。';

  @override
  String get dashboard_premium_analytics_title => 'プレミアム分析';

  @override
  String get dashboard_refresh_sources_tooltip => '実行サーバーを更新';

  @override
  String get dashboard_requires_runner => 'ランナーに接続してコマンド使用統計を表示します。';

  @override
  String dashboard_selected_period_total(int count) {
    return '選択期間内 $count 件';
  }

  @override
  String get dashboard_single_runner_notice =>
      '表示されている統計は現在設定されているランナーのみのものです。複数のランナーでボットを実行している場合、';

  @override
  String get dashboard_timeline => '時系列の使用状況';

  @override
  String get dashboard_title => 'ダッシュボード';

  @override
  String get dashboard_top_commands => 'トップコマンド';

  @override
  String get dashboard_top_locales => 'トップロケール';

  @override
  String get dashboard_total => '総コマンド数';

  @override
  String get debug_replay_clear => 'リプレイをクリア';

  @override
  String get debug_replay_clear_confirm => '記録されたすべてのリプレイが削除されます。続行しますか？';

  @override
  String get debug_replay_clear_title => 'リプレイをクリア';

  @override
  String get debug_replay_duration_label => '所要時間';

  @override
  String get debug_replay_empty_capturing => 'キャプチャ中… コマンドを実行してリプレイを記録してください。';

  @override
  String get debug_replay_empty_idle =>
      'キャプチャはオフです。有効にしてコマンドを実行し、リプレイを記録してください。';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'ループ深度 $depth, 反復 $iteration';
  }

  @override
  String get debug_replay_overview => '概要';

  @override
  String get debug_replay_pause => '一時停止';

  @override
  String get debug_replay_play => '再生';

  @override
  String get debug_replay_premium_desc =>
      'コマンド実行をステップごとに記録・再生します。各アクションの動作、所要時間を正確に確認できます。';

  @override
  String get debug_replay_premium_title => 'ビジュアルデバッガーリプレイ';

  @override
  String get debug_replay_result_empty => '(結果なし)';

  @override
  String get debug_replay_result_label => '結果';

  @override
  String get debug_replay_start_capture => 'キャプチャを有効化';

  @override
  String debug_replay_start_offset(int ms) {
    return '開始から +$ms ms';
  }

  @override
  String get debug_replay_step_back => '前のステップ';

  @override
  String get debug_replay_step_first => '最初のステップ';

  @override
  String get debug_replay_step_forward => '次のステップ';

  @override
  String get debug_replay_step_last => '最後のステップ';

  @override
  String get debug_replay_stop_capture => 'キャプチャを無効化';

  @override
  String get debug_replay_title => 'デバッガーリプレイ';

  @override
  String get debug_replay_variables_empty => '(変数なし)';

  @override
  String get debug_replay_variables_label => '変数';

  @override
  String get delete => '削除';

  @override
  String get doc_action_http_request_checklist_l1 =>
      '可能な場合はサービスレイヤーで明示的なタイムアウトとリトライを設定してください。';

  @override
  String get doc_action_http_request_checklist_l2 =>
      'APIキーはグローバル変数または安全なバックエンドに保存し、トークンをハードコードしないでください。';

  @override
  String get doc_action_http_request_checklist_l3 =>
      '次のアクションの前にステータスコードとレスポンスボディを検証してください。';

  @override
  String get doc_action_http_request_section_checklist => '信頼性チェックリスト';

  @override
  String get doc_action_http_request_subtitle => 'ワークフロー内で外部HTTP呼び出しを実行します。';

  @override
  String get doc_action_http_request_summary =>
      'Webhook、内部API、モデレーションサービス、AIエンドポイント、統合に使用します。';

  @override
  String get doc_action_http_request_title => 'アクション: httpRequest';

  @override
  String get doc_action_if_block_execution_l1 => '条件は1回だけ評価されます。';

  @override
  String get doc_action_if_block_execution_l2 =>
      '最初に一致するブランチが実行されます: THEN、次にELSE IFブロックが順に、最後にELSE。';

  @override
  String get doc_action_if_block_execution_l3 =>
      'ネストされたアクションにはrunWorkflow、API呼び出し、インタラクション応答を含められます。';

  @override
  String get doc_action_if_block_section_execution => '実行モデル';

  @override
  String get doc_action_if_block_subtitle =>
      'THEN、ELSE IF、ELSEのネストされたアクションリスト間の分岐実行。';

  @override
  String get doc_action_if_block_summary =>
      'ランタイム状態に基づいて複数の結果を処理しながら単一のワークフローを維持するために使用します。';

  @override
  String get doc_action_if_block_title => 'アクション: ifBlock';

  @override
  String get doc_action_run_workflow_practices_l1 =>
      'トップレベルのワークフローは薄く保ち、ドメインワークフローに委譲してください。';

  @override
  String get doc_action_run_workflow_practices_l2 =>
      '暗黙的なグローバル変数に頼らず、明示的な引数を渡してください。';

  @override
  String get doc_action_run_workflow_practices_l3 =>
      'エントリポイントを使用してサブルーチンをモデル化します (create, close, assign, escalate)。';

  @override
  String get doc_action_run_workflow_section_practices => 'ベストプラクティス';

  @override
  String get doc_action_run_workflow_subtitle =>
      'エントリポイントと引数を使用して別のワークフローを呼び出します。';

  @override
  String get doc_action_run_workflow_summary =>
      'ビジネスロジックを再利用可能なユニットに分割するための中核的な構成プリミティブ。';

  @override
  String get doc_action_run_workflow_title => 'アクション: runWorkflow';

  @override
  String get doc_action_stop_unless_example =>
      'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅';

  @override
  String get doc_action_stop_unless_format_l1 =>
      '生のキーを使用できます: message.content[0]';

  @override
  String get doc_action_stop_unless_format_l2 =>
      'ラップされた変数を使用できます: ((message.content[0]))';

  @override
  String get doc_action_stop_unless_format_l3 => 'どちらもランタイムによって解決されます。';

  @override
  String get doc_action_stop_unless_operators_l1 =>
      '一致する, 一致しない, 含む, 含まない, 前方一致, 後方一致';

  @override
  String get doc_action_stop_unless_operators_l2 => 'より大きい, より小さい, 以上, 以下';

  @override
  String get doc_action_stop_unless_operators_l3 => '空である, 空ではない, 正規表現に一致する';

  @override
  String get doc_action_stop_unless_section_format => '条件変数の形式';

  @override
  String get doc_action_stop_unless_section_operators => 'サポートされている演算子';

  @override
  String get doc_action_stop_unless_subtitle => '条件が失敗したときにワークフローを停止するガード句。';

  @override
  String get doc_action_stop_unless_summary =>
      'コンテキストが一致しない場合に不要なアクションを防ぐために、ワークフローの先頭で使用します。';

  @override
  String get doc_action_stop_unless_title => 'アクション: stopUnless';

  @override
  String get doc_available_variables => '利用可能な変数';

  @override
  String get doc_center_clear_search => '検索をクリア';

  @override
  String get doc_center_empty => '検索に一致するドキュメントエントリがありません。';

  @override
  String get doc_center_search_hint => 'コマンド、ワークフロー、変数、アクション、インテント、例を検索...';

  @override
  String get doc_center_title => 'ドキュメントセンター';

  @override
  String get doc_common_section_best_use_cases => '最適なユースケース';

  @override
  String get doc_common_section_important_notes => '重要な注意事項';

  @override
  String get doc_event_audit_log_create_best_use_l1 =>
      '機密アクション（ロール削除、Webhook作成、追放など）についてスタッフに警告します。';

  @override
  String get doc_event_audit_log_create_best_use_l2 =>
      '特定のアクションタイプを専用ワークフローにルーティングします。';

  @override
  String get doc_event_audit_log_create_subtitle =>
      '新しい監査ログエントリが作成されたときにトリガーされます。';

  @override
  String get doc_event_audit_log_create_summary => '管理セキュリティ監視のための高価値イベント。';

  @override
  String get doc_event_audit_log_create_title => 'イベント: guildAuditLogCreate';

  @override
  String get doc_event_message_create_best_use_l1 =>
      'スラッシュコマンドなしで入力されたコマンドを検出します。';

  @override
  String get doc_event_message_create_best_use_l2 => '応答前にアンチスパムフィルターを適用します。';

  @override
  String get doc_event_message_create_best_use_l3 =>
      '最初の単語またはメンションに基づいて再利用可能なワークフローにルーティングします。';

  @override
  String get doc_event_message_create_example =>
      'ガード: ((message.isBot)) equals false\nガード: ((message.content[0])) equals !ticket\nThen: runWorkflow';

  @override
  String get doc_event_message_create_intent_1 => 'サーバーメッセージ';

  @override
  String get doc_event_message_create_intent_2 => 'メッセージ内容';

  @override
  String get doc_event_message_create_notes_l1 =>
      'Message Contentインテントがオフの場合、コンテンツ依存の条件が失敗する可能性があります。';

  @override
  String get doc_event_message_create_notes_l2 =>
      'message.content[index]は単語ベースで、ランタイム抽出によって上限があります。';

  @override
  String get doc_event_message_create_notes_l3 =>
      'author.isBotはボットのループを防ぐのに役立ちます。';

  @override
  String get doc_event_message_create_subtitle => '新しく作成されたメッセージごとにトリガーされます。';

  @override
  String get doc_event_message_create_summary =>
      'モデレーション、キーワードパイプライン、自動返信、コマンドスタイルの解析、分析にこのイベントを使用します。';

  @override
  String get doc_event_message_create_title => 'イベント: messageCreate';

  @override
  String get doc_event_poll_vote_add_best_use_l1 =>
      '各回答IDを異なるアクションブランチにマッピングします。';

  @override
  String get doc_event_poll_vote_add_best_use_l2 =>
      'チャンネルまたはユーザーグループごとの投票参加を追跡します。';

  @override
  String get doc_event_poll_vote_add_intent => 'サーバーメッセージ';

  @override
  String get doc_event_poll_vote_add_notes_l1 =>
      'poll.answer.idがルーティングに最も安定したキーです。';

  @override
  String get doc_event_poll_vote_add_notes_l2 =>
      'poll.questionはオプションで、ペイロードによっては空の場合があります。';

  @override
  String get doc_event_poll_vote_add_subtitle => 'ユーザーが投票の回答に投票したときにトリガーされます。';

  @override
  String get doc_event_poll_vote_add_summary =>
      'スコア追跡、投票オプションによるロール割り当て、アンケート処理に役立ちます。';

  @override
  String get doc_event_poll_vote_add_title => 'イベント: messagePollVoteAdd';

  @override
  String get doc_event_reaction_add_best_use_l1 => 'Unicode絵文字で承認/拒否フロー。';

  @override
  String get doc_event_reaction_add_best_use_l2 => 'カスタム絵文字IDを使用した多段階投票。';

  @override
  String get doc_event_reaction_add_best_use_l3 => 'スタッフチャンネルからのクイックモデレーション信号。';

  @override
  String get doc_event_reaction_add_example =>
      'ガード: ((reaction.emoji.name)) equals ✅\nアクション: addRole -> user=((userId)) role=((global.approvedRole))';

  @override
  String get doc_event_reaction_add_intent => 'サーバーメッセージリアクション';

  @override
  String get doc_event_reaction_add_notes_l1 =>
      'reaction.emoji.idはUnicode絵文字の場合空になることがあります。';

  @override
  String get doc_event_reaction_add_notes_l2 =>
      '汎用マッチングにはreaction.emoji.nameを使用してください。';

  @override
  String get doc_event_reaction_add_notes_l3 =>
      '厳密なカスタム絵文字マッチングにはreaction.emoji.idを使用してください。';

  @override
  String get doc_event_reaction_add_subtitle =>
      'ユーザーがメッセージにリアクションを追加したときにトリガーされます。';

  @override
  String get doc_event_reaction_add_summary =>
      'コンポーネントなしのボタン風UX、投票システム、ロールメニュー、軽量承認に最適です。';

  @override
  String get doc_event_reaction_add_title => 'イベント: messageReactionAdd';

  @override
  String get doc_event_user_update_notes_l1 =>
      'ほとんどの場合、このイベントにはチャンネルコンテキストがありません。';

  @override
  String get doc_event_user_update_notes_l2 =>
      '直接のユーザー向け返信よりもログ記録とモデレーション警告を優先してください。';

  @override
  String get doc_event_user_update_subtitle =>
      'ユーザープロフィールデータが変更されたときにトリガーされます。';

  @override
  String get doc_event_user_update_summary =>
      'プロフィール変更監査やユーザー名/アバター駆動のトリガーに役立ちます。';

  @override
  String get doc_event_user_update_title => 'イベント: userUpdate';

  @override
  String get doc_event_voice_state_update_automations_l1 =>
      '自己ミュート/自己聴覚無効化のポリシー違反を検出します。';

  @override
  String get doc_event_voice_state_update_automations_l2 =>
      'サポートチャンネルのボイス参加時にウェルカムメッセージをトリガーします。';

  @override
  String get doc_event_voice_state_update_automations_l3 =>
      'チャンネル変更を使用して退出/参加パターンをログに記録します。';

  @override
  String get doc_event_voice_state_update_intent => 'サーバー';

  @override
  String get doc_event_voice_state_update_section_title => '典型的な自動化';

  @override
  String get doc_event_voice_state_update_subtitle =>
      'ユーザーのボイス状態が変更されたときにトリガーされます。';

  @override
  String get doc_event_voice_state_update_summary =>
      'ボイスチャンネルの自動モデレーション、出席チェック、ボイス自動化に使用します。';

  @override
  String get doc_event_voice_state_update_title => 'イベント: voiceStateUpdate';

  @override
  String get doc_example => '例';

  @override
  String doc_interaction_commands_example(String name, String id) {
    return 'オートコンプリートワークフロー:\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nresponseWithAutocomplete';
  }

  @override
  String get doc_interaction_commands_section_builtin_title => '組み込みコマンド変数';

  @override
  String get doc_interaction_commands_section_execution_l1 =>
      'スラッシュ、ユーザー、メッセージコマンドはすべてアプリケーションコマンドインタラクションとしてランナーに入ります。';

  @override
  String get doc_interaction_commands_section_execution_l2 =>
      'ランナーはDiscordコマンドIDでコマンドを照合し、保存されたタイプと受信タイプを検証します。';

  @override
  String get doc_interaction_commands_section_execution_l3 =>
      'タイプの不一致は警告としてログに記録されますが、実行をハード停止しません。';

  @override
  String get doc_interaction_commands_section_execution_title => '実行モデル';

  @override
  String get doc_interaction_commands_section_guidance_l1 =>
      'commandTypeまたはinteraction.command.typeに対して条件付きロジックを記述してください。';

  @override
  String get doc_interaction_commands_section_guidance_l2 =>
      'スラッシュと非スラッシュコマンド間でテンプレートを共有する場合はフォールバック構文を優先し、オートコンプリートを使用してください。';

  @override
  String get doc_interaction_commands_section_guidance_l3 =>
      'コマンドワークフロー内でイベント専用名を避けてテンプレートの移植性を保ちます。動的オートコンプリートは';

  @override
  String get doc_interaction_commands_section_guidance_title => '作成ガイダンス';

  @override
  String get doc_interaction_commands_section_per_type_l1 =>
      'chatInput: パラメータとサブコマンドにopts.*。';

  @override
  String get doc_interaction_commands_section_per_type_l2 =>
      'user: target.user.* および利用可能な場合 target.member.*。';

  @override
  String get doc_interaction_commands_section_per_type_l3 =>
      'message: target.message.* (解決された場合、コンテンツと作成者IDを含む)。';

  @override
  String get doc_interaction_commands_section_per_type_title => 'タイプ別変数';

  @override
  String get doc_interaction_commands_subtitle =>
      'スラッシュ、ユーザー、メッセージコマンドのランタイム動作。';

  @override
  String get doc_interaction_commands_summary =>
      'アプリケーションコマンドは共有インタラクションパスを通じて実行され、ランタイム変数は以下に依存します。';

  @override
  String get doc_interaction_commands_title => 'インタラクションコマンド';

  @override
  String get doc_kind_action => 'アクション';

  @override
  String get doc_kind_all => 'すべて';

  @override
  String get doc_kind_event => 'イベント';

  @override
  String get doc_kind_runtime => 'ランタイム';

  @override
  String get doc_kind_template => 'テンプレート';

  @override
  String get doc_required_intents => '必要なインテント';

  @override
  String get doc_runtime_action_outputs_example =>
      'ステータス: ((action.http.status|http.status|unknown))\nボディ: ((action.http.body|http.body))\n削除済み: ((c';

  @override
  String get doc_runtime_action_outputs_section_caveats_l1 =>
      'すべてのアクションがすべてのサフィックスを公開するわけではありません。利用可能性はエグゼキュータ固有です。';

  @override
  String get doc_runtime_action_outputs_section_caveats_l2 =>
      '移植性のために、オプションの出力フィールドを読み取る際はフォールバック式を優先してください。';

  @override
  String get doc_runtime_action_outputs_section_caveats_l3 =>
      'キーが存在しない場合、テンプレート解決は空の文字列を返します。';

  @override
  String get doc_runtime_action_outputs_section_caveats_title => '注意事項';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l1 =>
      'HTTPアクション: status, body, jsonPath。';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l2 =>
      'メッセージング/リストアクション: count, mode, deleteItself, deleteResponse。';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l3 =>
      '配列アクション: items, length, removed, total。';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l4 =>
      '他のエグゼキュータはresultやmessageIdフィールドを公開する場合があります。';

  @override
  String get doc_runtime_action_outputs_section_common_fields_title =>
      '共通出力フィールド';

  @override
  String get doc_runtime_action_outputs_section_patterns_l1 =>
      '主出力は通常 <resultKey> として保存されます。';

  @override
  String get doc_runtime_action_outputs_section_patterns_l2 =>
      '多くのエグゼキュータは明確さと名前空間のために action.<resultKey>.* フィールドも公開します。';

  @override
  String get doc_runtime_action_outputs_section_patterns_l3 =>
      '一部のフィールドは action. プレフィックスあり/なしの両方でミラーリングされます。';

  @override
  String get doc_runtime_action_outputs_section_patterns_title => '出力パターン';

  @override
  String get doc_runtime_action_outputs_subtitle =>
      'アクション結果キーがランタイム変数として公開される方法。';

  @override
  String get doc_runtime_action_outputs_summary =>
      'ほとんどのアクションは主結果キーを書き込み、action.<resultKey>.* の下にプレフィックス付きフィールドも公開する場合があります。';

  @override
  String get doc_runtime_action_outputs_title => 'ランタイムアクション出力';

  @override
  String get doc_runtime_execution_flow_section_parity_l1 =>
      '変数はローカルアプリランタイムとランナーランタイム間で同一である必要があります。';

  @override
  String get doc_runtime_execution_flow_section_parity_l2 =>
      '移植性を保つために条件で同じ変数名を使用してください。';

  @override
  String get doc_runtime_execution_flow_section_parity_title => 'パリティルール';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l1 =>
      '1) ゲートウェイイベントを受信。';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l2 =>
      '2) コンテキスト変数マップを構築。';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l3 =>
      '3) イベント名でワークフローを照合。';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l4 =>
      '4) グローバル変数をマージ。';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l5 =>
      '5) 条件付きでアクションを順次実行。';

  @override
  String get doc_runtime_execution_flow_section_pipeline_title => 'パイプライン';

  @override
  String get doc_runtime_execution_flow_subtitle => 'イベントワークフローが選択され実行される方法。';

  @override
  String get doc_runtime_execution_flow_summary =>
      'イベントが到着すると、ランタイムはeventTrigger.eventで設定されたワークフローを照合し、アクションを実行します。';

  @override
  String get doc_runtime_execution_flow_title => 'ランタイム実行フロー';

  @override
  String get doc_template_advanced_variables_example =>
      '種類: ((interaction.kind))\n選択数: ((interaction.values.count|0))\nスレッド所有者: ((channel.thread.ownerId))';

  @override
  String get doc_template_advanced_variables_section_aliases_l1 =>
      '構造化されたユーザーエイリアス（user.id, user.username, user.tag, user.avatar, user.banner）が利用可能です。';

  @override
  String get doc_template_advanced_variables_section_aliases_l2 =>
      'member.idはユーザーとサーバーメンバーのコンテキストの両方が必要な場合に便利です。';

  @override
  String get doc_template_advanced_variables_section_aliases_title =>
      'ユーザーとメンバーのエイリアス';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l1 =>
      'channel.kind, channel.position, channel.bitrate, channel.userLimitはコンテキスト依存のチャンネル詳細です。';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l2 =>
      'スレッドコンテキストはchannel.thread.*値を公開できます（archived, locked, ownerId, autoArchiveDuration）。';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l3 =>
      'guild.kindは高度なワークフローで部分/完全なサーバーペイロードを区別するのに役立ちます。';

  @override
  String get doc_template_advanced_variables_section_channel_guild_title =>
      'チャンネルとサーバーの詳細';

  @override
  String get doc_template_advanced_variables_section_interaction_l1 =>
      'interaction.kindは受信インタラクションモードを識別します（button, select, modal, command, autocomplete）。';

  @override
  String get doc_template_advanced_variables_section_interaction_l2 =>
      'interaction.valuesとinteraction.values.countはセレクトメニュー用に設定されます。';

  @override
  String get doc_template_advanced_variables_section_interaction_l3 =>
      'interaction.command.nameとinteraction.command.idは診断とルーティングチェックに役立ちます。';

  @override
  String get doc_template_advanced_variables_section_interaction_title =>
      'インタラクションメタデータ';

  @override
  String get doc_template_advanced_variables_subtitle =>
      '特定のコンテキストで利用可能な追加のランタイムキー。';

  @override
  String get doc_template_advanced_variables_summary =>
      'これらのキーは、インタラクションペイロードとチャンネル/サーバー/ユーザーのランタイム詳細から生成されます。';

  @override
  String get doc_template_advanced_variables_title => 'テンプレート高度変数';

  @override
  String get doc_template_functions_example =>
      '正規化: ((uppercase(trim(userName))))\n管理者ロールあり: ((contains(userRole, \"admin\")))\nトップスコア:';

  @override
  String get doc_template_functions_section_array_l1 =>
      'length(source), at(source, index), first(source), last(source)。';

  @override
  String get doc_template_functions_section_array_l2 =>
      'slice(source, start, end?) と join(source, separator)。';

  @override
  String get doc_template_functions_section_array_l3 =>
      'sum(source): 数値項目を加算し、非数値は無視します。';

  @override
  String get doc_template_functions_section_array_l4 =>
      'formatEach(...) と embedFields(...) はオブジェクト配列をテキストと埋め込み用にフォーマットします。';

  @override
  String get doc_template_functions_section_array_title => '配列関数';

  @override
  String get doc_template_functions_section_notes_l1 => '関数名は大文字小文字を区別しません。';

  @override
  String get doc_template_functions_section_notes_l2 =>
      '不明な関数や無効な引数は空文字列に解決されます。';

  @override
  String get doc_template_functions_section_notes_l3 =>
      'ルートレベルで | を使ったフォールバック構文: ((replace(name, \"_\", \" \")|Unknown))。';

  @override
  String get doc_template_functions_section_notes_l4 =>
      '関数から返される配列とオブジェクトはJSONテキストとしてシリアル化されます。';

  @override
  String get doc_template_functions_section_notes_title => '重要な注意事項';

  @override
  String get doc_template_functions_section_random_l1 =>
      'coin() と random(): 条件分岐用に \"true\" または \"\" を返します。';

  @override
  String get doc_template_functions_section_random_l2 =>
      'randomchoice(a, b, ...) と randomint(min, max)。';

  @override
  String get doc_template_functions_section_random_title => 'ランダムヘルパー';

  @override
  String get doc_template_functions_section_string_l1 =>
      'uppercase(s), lowercase(s), trim(s), replace(s, old, new)。';

  @override
  String get doc_template_functions_section_string_l2 =>
      'contains(haystack, needle), startsWith(s, prefix), endsWith(s, suffix)。';

  @override
  String get doc_template_functions_section_string_l3 =>
      'trim(source): 先頭と末尾のスペースを削除します。';

  @override
  String get doc_template_functions_section_string_l4 =>
      'replace(source, search, replacement) と contains(source, needle) による置換と検索。';

  @override
  String get doc_template_functions_section_string_title => '文字列関数';

  @override
  String get doc_template_functions_subtitle => 'ランタイム変数の変換とフォーマットのための組み込み関数。';

  @override
  String get doc_template_functions_summary =>
      'これらの関数はテンプレート式内で使用でき、ランタイム変数に対して変換、比較、配列操作を実行します。';

  @override
  String get doc_template_functions_title => 'テンプレート関数';

  @override
  String doc_template_variables_example(String name, String score) {
    return 'こんにちは ((target.user.username|userName))\nプレイヤー: ((join(scores.items.\$, \", \")))';
  }

  @override
  String get doc_template_variables_section_builtin_title => '組み込みコマンド変数';

  @override
  String get doc_template_variables_section_fallbacks_l1 =>
      'オプションがない場合のフォールバックには ((opts.user|userName)) を使用します。';

  @override
  String get doc_template_variables_section_fallbacks_l2 =>
      'アクション出力にJSONPath構文を使用: ((myHttp.body.\$.data[0].id)); 配列と';

  @override
  String get doc_template_variables_section_fallbacks_l3 =>
      'length(...), join(...), formatEach(...), embedFields(...) などの関数が';

  @override
  String get doc_template_variables_section_fallbacks_title => 'フォールバックとパス';

  @override
  String get doc_template_variables_section_sources_l1 =>
      'コマンド変数: commandName, commandId, commandType, target.*, opts.*。';

  @override
  String get doc_template_variables_section_sources_l2 =>
      'イベント変数: event.*, message.*, reaction.*, voice.*, role.* など。';

  @override
  String get doc_template_variables_section_sources_l3 =>
      'ワークフロー変数: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*';

  @override
  String get doc_template_variables_section_sources_l4 =>
      'グローバル変数: global.<key>';

  @override
  String get doc_template_variables_section_sources_l5 =>
      'アクション出力: 利用可能な場合 action.<key>。';

  @override
  String get doc_template_variables_section_sources_title => '変数ソース';

  @override
  String get doc_template_variables_section_types_l1 =>
      'スラッシュコマンドは commandType = chatInput を使用し、opts.<option> 変数を公開します。';

  @override
  String get doc_template_variables_section_types_l2 =>
      'ユーザーコマンドは commandType = user を使用し、target.user.* 変数を公開します。';

  @override
  String get doc_template_variables_section_types_l3 =>
      'メッセージコマンドは commandType = message を使用し、target.message.* 変数を公開します。';

  @override
  String get doc_template_variables_section_types_l4 =>
      'サブコマンドは引き続き opts.* を通じて引数を公開します。';

  @override
  String get doc_template_variables_section_types_title => 'コマンドタイプ';

  @override
  String get doc_template_variables_subtitle => '動的プレースホルダーの解決方法。';

  @override
  String get doc_template_variables_summary =>
      'ランタイムは現在のイベント/インタラクションコンテキスト、ワークフローを使用してプレースホルダーを解決します。';

  @override
  String get doc_template_variables_title => 'テンプレート変数';

  @override
  String get done => '完了';

  @override
  String download_completed(String id) {
    return 'ダウンロード完了: $id';
  }

  @override
  String download_failed(String error) {
    return 'ダウンロード失敗: $error';
  }

  @override
  String get download_legacy_backup => 'ダウンロード完了 (レガシーバックアップ)';

  @override
  String get drive_legacy_snapshot => 'レガシースナップショット';

  @override
  String get drive_manual_backup => '手動バックアップ';

  @override
  String get edit_shell_all_saved => 'すべての変更が保存されました';

  @override
  String get edit_shell_command_body => 'コマンド本文';

  @override
  String get edit_shell_command_settings => 'コマンド設定';

  @override
  String get edit_shell_command_settings_desc => 'メタデータ、利用可能性、権限、フォルダ配置。';

  @override
  String get edit_shell_local_draft => 'ローカル下書き';

  @override
  String get edit_shell_local_only => 'ローカルのみ';

  @override
  String edit_shell_routes_count(int count) {
    return '$count ルート';
  }

  @override
  String get edit_shell_save_changes => '変更を保存';

  @override
  String get edit_shell_subtitle => '設定と入力は上部にあります。アクションと返信は下に続きます。';

  @override
  String get edit_shell_trigger_inputs => 'トリガーと入力';

  @override
  String get edit_shell_trigger_inputs_desc => 'コマンドオプション、トリガー動作、実行モードを調整します。';

  @override
  String get edit_shell_type_command => 'コマンド';

  @override
  String get edit_shell_type_legacy => 'レガシーコマンド';

  @override
  String get edit_shell_type_message => 'メッセージコマンド';

  @override
  String get edit_shell_type_slash => 'スラッシュコマンド';

  @override
  String get edit_shell_type_user => 'ユーザーコマンド';

  @override
  String get edit_shell_unsaved => '未保存の変更';

  @override
  String get edit_shell_untitled_command => '無題のコマンド';

  @override
  String get embed_add_field => 'フィールドを追加';

  @override
  String get embed_add_section => 'セクションを追加';

  @override
  String get embed_add_tooltip => '埋め込みを追加';

  @override
  String get embed_color_picker_title => '埋め込みの色を選択';

  @override
  String get embed_delete_confirm => 'この埋め込みは削除されます。続行しますか？';

  @override
  String get embed_delete_title => '埋め込みを削除';

  @override
  String embed_empty_message(int max) {
    return '埋め込みがありません。最大 $max 個まで追加できます。';
  }

  @override
  String get embed_field_delete_confirm => 'このフィールドは埋め込みから削除されます。続行しますか？';

  @override
  String get embed_field_delete_title => 'フィールドを削除';

  @override
  String embed_field_number(int index) {
    return 'フィールド #$index';
  }

  @override
  String get embed_fields_empty => 'まだフィールドがありません。';

  @override
  String embed_fields_header(int count) {
    return 'フィールド ($count/25)';
  }

  @override
  String get embed_label_author_icon => '作成者アイコンURL';

  @override
  String get embed_label_author_name => '作成者名';

  @override
  String get embed_label_author_url => '作成者URL';

  @override
  String get embed_label_color => '色';

  @override
  String get embed_label_dynamic_fields => '動的フィールドテンプレート';

  @override
  String get embed_label_footer_icon => 'フッターアイコンURL';

  @override
  String get embed_label_footer_text => 'フッターテキスト';

  @override
  String get embed_label_image_url => '画像URL';

  @override
  String get embed_label_inline => 'インライン';

  @override
  String get embed_label_thumbnail_url => 'サムネイルURL';

  @override
  String get embed_label_timestamp => 'タイムスタンプ';

  @override
  String get embed_label_title => 'タイトル';

  @override
  String get embed_label_url => 'URL';

  @override
  String embed_number(int index) {
    return '埋め込み #$index';
  }

  @override
  String embed_response_header(int count, int max) {
    return '応答埋め込み ($count/$max)';
  }

  @override
  String get embed_section_author => '作成者';

  @override
  String get embed_section_color => '色';

  @override
  String get embed_section_dynamic_fields => '動的フィールド';

  @override
  String get embed_section_fields => 'フィールド';

  @override
  String get embed_section_footer => 'フッター';

  @override
  String get embed_section_media => 'メディア';

  @override
  String get embed_section_timestamp => 'タイムスタンプ';

  @override
  String emojis_delete_confirm_body(String name) {
    return ':$name: を削除しますか？この操作は元に戻せません。';
  }

  @override
  String get emojis_delete_confirm_title => '絵文字を削除';

  @override
  String emojis_delete_error(String error) {
    return '削除失敗: $error';
  }

  @override
  String get emojis_delete_tooltip => '削除';

  @override
  String get emojis_empty => 'まだ絵文字がありません。アップロードして始めてください。';

  @override
  String get emojis_loading_error => '絵文字の読み込みに失敗しました';

  @override
  String emojis_rename_error(String error) {
    return '名前変更失敗: $error';
  }

  @override
  String get emojis_rename_hint => '新しい名前';

  @override
  String get emojis_rename_title => '絵文字の名前を変更';

  @override
  String get emojis_rename_tooltip => '名前を変更';

  @override
  String get emojis_tab => '絵文字';

  @override
  String get emojis_tab_short => '絵文字';

  @override
  String get emojis_title => 'アプリケーション絵文字';

  @override
  String get emojis_upload => '絵文字をアップロード';

  @override
  String emojis_upload_error(String error) {
    return 'アップロード失敗: $error';
  }

  @override
  String get emojis_upload_name_hint => '絵文字名 (英数字、_)';

  @override
  String get emojis_upload_pick_image => '画像を選択';

  @override
    @override
  String get export_file_picker_busy => 'ファイルピッカーは既にアクティブです。待ってから再試行してください。';

  @override
  String get error => 'エラー';

  @override
  String get error_delete_messages_failed => 'メッセージの削除に失敗しました。';

  @override
  String get error_invalid_channel_type => 'チャンネルはテキストチャンネルではありません。';

  @override
  String get error_invalid_count => 'カウントは0より大きい必要があります。';

  @override
  String get error_network_timeout => 'アクションがタイムアウトしました。もう一度お試しください。';

  @override
  String error_with_details(String error) {
    return 'エラー: $error';
  }

  @override
  String get export_button => 'ZIPをエクスポート';

  @override
  String get export_commands => 'コマンド';

  @override
  String export_failed(String error) {
    return 'エクスポート失敗: $error';
  }

  @override
  String get export_global_variables => 'グローバル変数';

  @override
  String get export_import_title => 'エクスポート / インポート';

  @override
  String get export_section_desc =>
      'ボットの選択したセクションをZIPファイルとしてエクスポートします。ボットトークンは含まれません。';

  @override
  String get export_section_title => 'エクスポート';

  @override
  String get export_status => 'ステータスとアクティビティ';

  @override
  String get export_workflows => 'ワークフロー';

  @override
  String get globals_add => '変数を追加';

  @override
  String get globals_add_global => 'グローバル変数を追加';

  @override
  String get globals_add_scoped => 'スコープ変数を追加';

  @override
  String get globals_copy_value => '値をコピー';

  @override
  String globals_delete_confirm(String key) {
    return '\"$key\" を削除しますか？';
  }

  @override
  String get globals_delete_title => '変数を削除';

  @override
  String get globals_dialog_global_desc => 'グローバル変数はすべてのコマンドとサーバー間で共有されます。';

  @override
  String globals_dialog_ref_preview(String ref) {
    return '使用法: \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'スコープ変数は $scope コンテキストごとに個別の値を保存します。';
  }

  @override
  String get globals_edit => '変数を編集';

  @override
  String get globals_edit_global => 'グローバル変数を編集';

  @override
  String get globals_edit_scoped => 'スコープ変数を編集';

  @override
  String get globals_empty => 'まだグローバル変数がありません';

  @override
  String get globals_empty_subtitle =>
      'すべてのコマンドからアクセス可能な永続データを保存する変数を追加してください。';

  @override
  String get globals_help_global => 'すべてのコマンドで共有。\$getVar[key] でアクセス。';

  @override
  String get globals_help_scoped =>
      'コンテキストごとに保存（サーバー、ユーザー、チャンネル…）。各エントリはスコープごとに個別の値を保持します。';

  @override
  String get globals_key => 'キー';

  @override
  String get globals_key_hint => '例: prefix, level, welcome_message';

  @override
  String get globals_mode_global => 'グローバル';

  @override
  String get globals_mode_scoped => 'スコープ';

  @override
  String get globals_no_default => 'デフォルト値なし';

  @override
  String get globals_refresh => '更新';

  @override
  String get globals_retry => '再試行';

  @override
  String get globals_scope_channel => 'チャンネル';

  @override
  String get globals_scope_guild => 'サーバー';

  @override
  String get globals_scope_guildMember => 'サーバーメンバー';

  @override
  String get globals_scope_message => 'メッセージ';

  @override
  String get globals_scope_user => 'ユーザー';

  @override
  String get globals_search => '変数を検索…';

  @override
  String get globals_source_local => 'ローカル';

  @override
  String globals_source_runner(String name) {
    return 'ランナー: $name';
  }

  @override
  String get globals_tab => 'グローバル変数';

  @override
  String get globals_tab_short => '変数';

  @override
  String get globals_title => '変数';

  @override
  String get globals_value => '値';

  @override
  String get globals_value_auto_type_hint => '値は自動型付けされます（数値、真偽値、JSON）。';

  @override
  String get guilds_empty_state =>
      'ボットはどのサーバーにも参加していません。\nサーバーに招待するとここに表示されます。';

  @override
  String guilds_leave_confirm(String name) {
    return '「$name」から退出しますか？\nボットはこのサーバーから削除されます。後でDiscord開発者ポータルから再招待できます。';
  }

  @override
  String guilds_leave_failed(String error) {
    return '退出に失敗しました: $error';
  }

  @override
  String get guilds_leave_title => 'サーバーを退出';

  @override
  String get guilds_leave_tooltip => '退出';

  @override
  String guilds_left_success(String name) {
    return '「$name」から退出しました。';
  }

  @override
  String guilds_members_count_other(int count) {
    return '~$count 人のメンバー';
  }

  @override
  String get guilds_owner_label => '👑 オーナー';

  @override
  String guilds_server_count_other(int count) {
    return '$count 個のサーバー';
  }

  @override
  String get guilds_tab => 'サーバー';

  @override
  String get guilds_tab_short => 'サーバー';

  @override
  String get hint_use_variables => '必要に応じて変数/テンプレートを使用';

  @override
  String get home_add_time => '時間を追加';

  @override
  String get home_empty_support_btn => 'Discord サポート';

  @override
  String get home_empty_support_hint => 'ヘルプが必要ですか？コミュニティに参加しましょう！';

  @override
  String get home_foreground_service_not_started => 'フォアグラウンドサービスが起動しませんでした。';

  @override
  String get home_hosting_expired => 'ホスティングの有効期限が切れました';

  @override
  String home_hosting_time_left(String time) {
    return 'ホスティング残り時間: $time';
  }

  @override
  String get home_log_desktop_stop_requested => 'デスクトップボット停止が要求されました';

  @override
  String get home_log_start_requested => 'ボット起動が要求されました';

  @override
  String get home_log_stop_requested => 'ボット停止が要求されました';

  @override
  String get home_logs_tooltip => 'ログを表示';

  @override
  String get home_manage => '管理';

  @override
  String get home_notification_permission_required => 'ボットを起動するには通知権限が必要です。';

  @override
  String home_server_count_one(int count) {
    return '$count サーバー';
  }

  @override
  String home_server_count_other(int count) {
    return '$count サーバー';
  }

  @override
  String get home_start => '起動';

  @override
  String get home_start_ads => '起動 (広告を見る)';

  @override
  String get home_start_premium => '起動 (プレミアム)';

  @override
  String get home_status_offline => 'オフライン';

  @override
  String get home_status_online => 'オンライン';

  @override
  String get home_stop => '停止';

  @override
  String get home_sync_failed => '同期失敗';

  @override
  String get home_tab => 'ホーム';

  @override
  String get home_time_added => '時間が正常に追加されました';

  @override
  String home_token_missing(String botName) {
    return '$botName のトークンが見つかりません';
  }

  @override
  String get home_unknown_app => '不明';

  @override
  String get image_editor_create => '作成';

  @override
  String get image_editor_create_canvas => '画像キャンバスを作成';

  @override
  String image_editor_edit_canvas(int count) {
    return 'キャンバスを編集 ($count 操作)';
  }

  @override
  String get image_editor_open => 'エディタを開く';

  @override
  String get import_button => 'インポート';

  @override
  String import_failed(String error) {
    return 'インポート失敗: $error';
  }

  @override
  String get import_nothing => '何もインポートされませんでした。';

  @override
  String get import_overwrite => '上書き';

  @override
  String import_parse_failed(String error) {
    return 'ZIPの解析に失敗: $error';
  }

  @override
  String get import_pick_file => 'ZIPファイルを選択';

  @override
  String get import_section_desc =>
      '以前にエクスポートしたZIPファイルをインポートします。競合は項目ごとに解決できます。';

  @override
  String get import_section_title => 'インポート';

  @override
  String get import_skip => 'スキップ';

  @override
  String import_summary_commands_imported(int count) {
    return '$count コマンドをインポートしました';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count コマンドをスキップしました';
  }

  @override
  String get import_summary_status_imported => 'ステータスをインポートしました';

  @override
  String get import_summary_variables_imported => '変数をインポートしました';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count ワークフローをインポートしました';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count ワークフローをスキップしました';
  }

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'コマンド \"$command\" のBDFDスクリプト実行に失敗: $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'messageCreateから<prefix><command>でコマンドを処理します。';

  @override
  String get legacy_prefix_mode_subtitle =>
      '位置オプションを使用します (例: !config #channel)。';

  @override
  String get legacy_prefix_mode_title => 'レガシープレフィックスモード';

  @override
  String get legacy_prefix_override_hint => '例: ? または ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label => 'プレフィックス上書き (オプション)';

  @override
  String get legacy_response_banner_body =>
      '一部のコマンドはまだ古い応答形式を使用しています。エディタで開いて再保存してください。';

  @override
  String get legacy_response_banner_dismiss => '閉じる';

  @override
  String get legacy_response_banner_migrate => 'すべて移行';

  @override
  String get legacy_response_banner_migrate_failed => '移行に失敗しました';

  @override
  String legacy_response_banner_migrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count コマンドを移行しました',
      one: '1 コマンドを移行しました',
    );
    return '$_temp0';
  }

  @override
  String get legacy_response_banner_migrated_none => '移行が必要なコマンドはありません';

  @override
  String get legacy_response_banner_migrating => '移行中...';

  @override
  String get legacy_response_banner_short_body =>
      'コマンドを開いて再保存し、新しい形式に移行してください。';

  @override
  String get legacy_response_banner_short_title => 'コマンド更新が利用可能です';

  @override
  String get legacy_response_banner_title => 'コマンド応答形式の更新';

  @override
  String get legacy_response_mode_label => 'レガシー応答モード';

  @override
  String get local_command_awaited_desc =>
      '待機コールバックプリセットは内部ランタイムコールバックであるため、ローカルのままです。';

  @override
  String get local_command_desc =>
      'コマンドをBot Creatorにのみ保存します。特定のサーバーに動的に登録できます。';

  @override
  String get local_command_title => 'ローカルコマンド (Discordに登録しない)';

  @override
  String logs_runner_source(String name) {
    return 'ログ元: $name';
  }

  @override
  String get marketplace_about => '概要';

  @override
  String get marketplace_add => '追加';

  @override
  String get marketplace_api_unavailable => 'APIクライアントが利用できません';

  @override
  String get marketplace_apply => 'テンプレートを適用';

  @override
  String marketplace_apply_error(Object error) {
    return '適用に失敗: $error';
  }

  @override
  String get marketplace_apply_success => 'テンプレートが正常に適用されました！';

  @override
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  ) {
    return '$addedCount個のコマンドを追加、$skippedCount個をスキップ（重複）。';
  }

  @override
  String get marketplace_applying => '適用中...';

  @override
  String marketplace_by_author(Object author, Object version) {
    return '作成者 $author · v$version';
  }

  @override
  String get marketplace_cancel => 'キャンセル';

  @override
  String marketplace_command_preview_actions(Object count) {
    return '$count 個のアクション';
  }

  @override
  String get marketplace_command_preview_no_actions => 'アクションなし';

  @override
  String marketplace_command_preview_options(Object count) {
    return '$count 個のオプション';
  }

  @override
  String get marketplace_command_preview_type_message => 'メッセージのコンテキストメニュー';

  @override
  String get marketplace_command_preview_type_slash => 'スラッシュコマンド';

  @override
  String get marketplace_command_preview_type_user => 'ユーザーのコンテキストメニュー';

  @override
  String marketplace_commands_label(Object count) {
    return 'コマンド ($count)';
  }

  @override
  String get marketplace_config_hint => 'このテンプレートを適用する前に必要な値を入力してください。';

  @override
  String get marketplace_config_required => '設定が必要です';

  @override
  String marketplace_conflict_apply_choice(Object count) {
    return '適用 ($count 個のテンプレート)';
  }

  @override
  String get marketplace_conflict_keep_local => 'ローカルを維持';

  @override
  String marketplace_conflict_local_info(Object count) {
    return 'ローカル ($count 個のアクション)';
  }

  @override
  String get marketplace_conflict_subtitle =>
      '一部のテンプレートコマンドが既に存在します。維持するバージョンを選択してください：';

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'テンプレート ($count 個のアクション)';
  }

  @override
  String get marketplace_conflict_title => 'コマンドの競合';

  @override
  String get marketplace_conflict_use_template => 'テンプレートを使用';

  @override
  String get marketplace_connect_discord => 'Discordで接続';

  @override
  String get marketplace_connect_manager =>
      'マーケットプレイスにアクセスするにはManagerに接続してください。';

  @override
  String get marketplace_connect_publish => 'テンプレートを公開するにはManagerに接続してください。';

  @override
  String marketplace_count(Object count) {
    return '$count テンプレート';
  }

  @override
  String get marketplace_delete => '削除';

  @override
  String marketplace_delete_confirm(Object name) {
    return '\"$name\"を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get marketplace_delete_confirm_title => 'テンプレートを削除';

  @override
  String get marketplace_delete_success => 'テンプレートを削除しました。';

  @override
  String get marketplace_edit => '編集';

  @override
  String get marketplace_edit_hint => '編集するには、ボットのコマンドリストから同じ名前で再公開してください。';

  @override
  String get marketplace_empty => 'まだテンプレートがありません。\n最初に公開しましょう！';

  @override
  String marketplace_load_error(Object error) {
    return 'データの読み込みに失敗: $error';
  }

  @override
  String get marketplace_login_hint =>
      'マーケットプレイスにアクセスするにはDiscordアカウントを接続してください。';

  @override
  String get marketplace_login_instructions =>
      'マーケットプレイスを引き続き利用するにはDiscordで認証してください。';

  @override
  String get marketplace_login_required => 'Discord接続が必要です';

  @override
  String get marketplace_login_success => 'Discordに接続しました！';

  @override
  String get marketplace_login_title => 'Managerに接続';

  @override
  String marketplace_more(Object count) {
    return '+$count 件';
  }

  @override
  String get marketplace_my_templates => '自分のテンプレート';

  @override
  String marketplace_no_results(Object query) {
    return '\"$query\" に一致するテンプレートはありません';
  }

  @override
  String get marketplace_no_variables => 'グローバル変数が定義されていません。';

  @override
  String get marketplace_publish_add_variable => 'カスタム変数を追加';

  @override
  String get marketplace_publish_add_variable_title => '変数を追加';

  @override
  String get marketplace_publish_back => '戻る';

  @override
  String get marketplace_publish_button => '公開';

  @override
  String get marketplace_publish_category_hint => '例: ai, moderation, fun';

  @override
  String get marketplace_publish_category_label => 'カテゴリ';

  @override
  String marketplace_publish_commands(Object count) {
    return 'コマンド ($count)';
  }

  @override
  String get marketplace_publish_desc_hint => 'マーケットプレイスに表示される1行の概要';

  @override
  String get marketplace_publish_desc_label => '短い説明';

  @override
  String get marketplace_publish_desc_long_hint => '詳細な使用手順、Markdown対応...';

  @override
  String get marketplace_publish_desc_long_label => '完全なドキュメント (オプション)';

  @override
  String get marketplace_publish_deselect_all => 'すべて解除';

  @override
  String marketplace_publish_error(Object error) {
    return '公開に失敗: $error';
  }

  @override
  String get marketplace_publish_metadata => 'テンプレート詳細';

  @override
  String get marketplace_publish_metadata_hint =>
      '他の人が見つけて使用できるようにテンプレートを説明します。';

  @override
  String get marketplace_publish_name_hint => '例: AIモデレーションボット';

  @override
  String get marketplace_publish_name_label => 'テンプレート名';

  @override
  String get marketplace_publish_next => '次へ';

  @override
  String get marketplace_publish_no_content =>
      '公開するコマンドやワークフローがありません。\n最初に作成してください！';

  @override
  String get marketplace_publish_required_fields =>
      '公開する前に、すべての必須項目（テンプレート名、概要、バージョン）を入力してください。';

  @override
  String get marketplace_publish_select => '含めるものを選択';

  @override
  String get marketplace_publish_select_all => 'すべて選択';

  @override
  String get marketplace_publish_select_hint =>
      'コマンド、ワークフロー、またはその両方を選択します。それぞれがテンプレートの一部になります。';

  @override
  String get marketplace_publish_success => 'テンプレートが正常に公開されました！';

  @override
  String get marketplace_publish_summary => 'テンプレート概要';

  @override
  String get marketplace_publish_tags_hint => '例: openai, chatbot, moderation';

  @override
  String get marketplace_publish_tags_label => 'タグ (カンマ区切り)';

  @override
  String get marketplace_publish_title => 'テンプレートを公開';

  @override
  String get marketplace_publish_user_must_define => 'ユーザーがこの値を定義する必要があります';

  @override
  String get marketplace_publish_user_must_define_hint => '適用前にユーザーに入力を求めます';

  @override
  String get marketplace_publish_variable_desc_hint => 'この変数の用途';

  @override
  String get marketplace_publish_variable_desc_label => '説明';

  @override
  String get marketplace_publish_variable_name_hint => '例: TOKEN_OPENAI';

  @override
  String get marketplace_publish_variable_name_label => '変数名';

  @override
  String get marketplace_publish_variables => 'グローバル変数';

  @override
  String get marketplace_publish_variables_hint =>
      '変数を含め、ユーザーが入力する必要があるものをマークします。';

  @override
  String get marketplace_publish_version_label => 'バージョン';

  @override
  String marketplace_publish_workflows(Object count) {
    return 'ワークフロー ($count)';
  }

  @override
  String get marketplace_publishing => '公開中...';

  @override
  String get marketplace_rate_success => '評価を送信しました！';

  @override
  String get marketplace_rate_title => 'このテンプレートを評価';

  @override
  String get marketplace_retry => '再試行';

  @override
  String get marketplace_search_hint => 'テンプレートを検索...';

  @override
  String get marketplace_title => 'マーケットプレイス';

  @override
  String marketplace_variable_required(Object name) {
    return '$name は必須です';
  }

  @override
  String get marketplace_variables_label => '事前設定変数';

  @override
  String marketplace_workflows_label(Object count) {
    return 'ワークフロー ($count)';
  }

  @override
  String get modal_add_text_input => 'テキスト入力を追加';

  @override
  String get modal_builder_title => 'モーダルビルダー';

  @override
  String get modal_custom_id_hint => 'このモーダルを識別するために使用';

  @override
  String get modal_custom_id_label => 'カスタムID';

  @override
  String get modal_default_value => 'デフォルト値';

  @override
  String modal_field_default_label(int index) {
    return 'フィールド $index';
  }

  @override
  String modal_input_index(int index) {
    return '入力 $index';
  }

  @override
  String modal_inputs_count(int count) {
    return '$count/5 入力';
  }

  @override
  String get modal_remove_field_confirm => 'このフィールドはモーダルから削除されます。続行しますか？';

  @override
  String get modal_remove_field_title => 'モーダルフィールドを削除';

  @override
  String get modal_style => 'スタイル:';

  @override
  String get modal_title_label => 'モーダルタイトル';

  @override
  String get modal_workflow_submit => '送信時に実行するワークフロー (オプション)';

  @override
  String get more_options_title => 'その他のオプション';

  @override
  String get more_tab => 'その他';

  @override
  String get nav_webhooks => 'Webhook';

  @override
  String get nav_webhooks_compact => 'フック';

  @override
  String get no_more_options => '利用可能な他のオプションはありません';

  @override
  String notion_create_workflow_from_query(String query) {
    return 'ワークフロー \"$query\" を作成';
  }

  @override
  String get notion_filter_add => 'フィルターを追加';

  @override
  String get notion_filter_type => 'タイプ';

  @override
  String get ok => 'OK';

  @override
  String get onboarding_command_button => '続ける';

  @override
  String get onboarding_command_desc => '最初のコマンドを作成';

  @override
  String get onboarding_command_example =>
      '例:\n/hello → ボットが \"こんにちは！ 👋\" と返信';

  @override
  String get onboarding_command_text =>
      'コマンドはボットの心臓部です。ユーザーはコマンドを通じてボットと対話します。';

  @override
  String get onboarding_command_title => 'ステップ2: コマンドを追加';

  @override
  String get onboarding_create_button => '続ける';

  @override
  String get onboarding_create_desc => 'Discordトークンを取得';

  @override
  String get onboarding_create_steps =>
      '1. Discord Developer Portal にアクセス\n2. 新しいアプリを作成\n3. ボットトークンをコピー\n4. ここに貼り付け';

  @override
  String get onboarding_create_tip =>
      '💡 ヒント: トークンは絶対に共有しないでください！ボットへの完全なアクセス権を与えます。';

  @override
  String get onboarding_create_title => 'ステップ1: ボットを作成';

  @override
  String get onboarding_create_tutorial => 'チュートリアル: トークンの取得方法';

  @override
  String get onboarding_start_button => '続ける';

  @override
  String get onboarding_start_desc => 'ボットを起動！';

  @override
  String get onboarding_start_text =>
      'ボットカードの「起動」ボタンをクリックしてください。その後Discordでコマンドをテストしましょう！';

  @override
  String get onboarding_start_tip =>
      '✨ 素晴らしい！最初のDiscordボットを作成しました。さらにコマンドを追加して';

  @override
  String get onboarding_start_title => 'ステップ3: ボットを起動';

  @override
  String get onboarding_success_button => '始める！';

  @override
  String get onboarding_success_desc => 'Discordボットの準備ができました！';

  @override
  String get onboarding_success_tip1 => 'さらにコマンドを追加';

  @override
  String get onboarding_success_tip2 => 'ワークフローを作成';

  @override
  String get onboarding_success_tip3 => 'データをバックアップ';

  @override
  String get onboarding_success_title => 'おめでとうございます！ 🎉';

  @override
  String get onboarding_success_whatsnext => '次は何をしますか？';

  @override
  String get onboarding_welcome_desc =>
      '3つの簡単なステップで最初のDiscordボットを作成します。各ステップをガイドします。';

  @override
  String get onboarding_welcome_skip => 'スキップ';

  @override
  String get onboarding_welcome_start => '始める';

  @override
  String get onboarding_welcome_title => 'Bot Creator へようこそ';

  @override
  String get option_add_choice => '選択肢を追加';

  @override
  String get option_add_localizations => 'ローカライズを追加';

  @override
  String get option_choice_delete_confirm => 'この選択肢は削除されます。続行しますか？';

  @override
  String get option_choice_delete_title => '選択肢を削除';

  @override
  String get option_choice_name => '選択肢名';

  @override
  String option_choice_number(int index) {
    return '選択肢 $index';
  }

  @override
  String get option_choice_value => '選択肢の値';

  @override
  String option_default_name(int index) {
    return 'オプション $index';
  }

  @override
  String get option_delete_argument_confirm => 'この引数は削除されます。続行しますか？';

  @override
  String get option_delete_argument_title => '引数を削除';

  @override
  String get option_delete_choice_confirm => 'この選択肢は削除されます。続行しますか？';

  @override
  String get option_delete_choice_title => 'オプションを削除';

  @override
  String get option_delete_confirm => 'このオプションは削除されます。続行しますか？';

  @override
  String get option_delete_localization_confirm =>
      'このローカライズエントリは削除されます。続行しますか？';

  @override
  String get option_delete_localization_title => 'ローカライズを削除';

  @override
  String get option_delete_title => 'オプションを削除';

  @override
  String get option_desc_required => 'オプションの説明を入力してください';

  @override
  String option_label_number(int index) {
    return 'ラベル $index';
  }

  @override
  String get option_localized_description => 'ローカライズされた説明';

  @override
  String get option_localized_name => 'ローカライズされた名前';

  @override
  String get option_max_value => '最大値';

  @override
  String get option_min_value => '最小値';

  @override
  String get option_name_duplicate => 'この名前は既にこのレベルで使用されています';

  @override
  String get option_name_invalid_chars => 'オプション名には英数字とアンダースコアのみ使用できます';

  @override
  String get option_name_invalid_start => 'オプション名がサポートされていない文字で始まっています';

  @override
  String get option_name_max_length => 'オプション名は最大32文字です';

  @override
  String get option_name_required => 'オプションの名前を入力してください';

  @override
  String get option_select_language => '言語を選択';

  @override
  String option_static_label_n(int index) {
    return 'ラベル $index';
  }

  @override
  String option_static_value_n(int index) {
    return '値 $index';
  }

  @override
  String get option_subcommand_options => 'サブコマンドオプション';

  @override
  String get option_subcommands => 'サブコマンド';

  @override
  String get option_type_attachment => '添付ファイル';

  @override
  String get option_type_boolean => '真偽値';

  @override
  String get option_type_channel => 'チャンネル';

  @override
  String get option_type_integer => '整数';

  @override
  String get option_type_mentionable => 'メンション可能';

  @override
  String get option_type_number => '数値';

  @override
  String get option_type_role => 'ロール';

  @override
  String get option_type_string => '文字列';

  @override
  String get option_type_subcommand => 'サブコマンド';

  @override
  String get option_type_subcommand_group => 'サブコマンドグループ';

  @override
  String get option_type_unknown => '不明';

  @override
  String get option_type_user => 'ユーザー';

  @override
  String option_value_number(int index) {
    return '値 $index';
  }

  @override
  String get premium_active_desc => 'ご支援ありがとうございます！すべての広告が無効になりました。';

  @override
  String get premium_active_title => 'プレミアム有効';

  @override
  String get premium_card_button => 'プランを見る';

  @override
  String get premium_card_desc => 'サブスクライブしてすべての広告を削除し、ポップアップなしで即座にボットを起動できます。';

  @override
  String get premium_card_title => '広告を削除';

  @override
  String get quick_access_title => 'クイックアクセス';

  @override
  String get recovery_delete_bot => 'ボットをローカルで削除';

  @override
  String get recovery_label => 'リカバリー';

  @override
  String get recovery_retry_discord => 'Discord接続を再試行';

  @override
  String get recovery_title => 'リカバリーモード';

  @override
  String reply_active_route(String label) {
    return 'アクティブルート: $label';
  }

  @override
  String get reply_buttons_desc => 'このメッセージにインタラクティブなボタンやドロップダウンを追加';

  @override
  String get reply_buttons_optional => 'ボタンとセレクトメニュー (オプション)';

  @override
  String get reply_choose_type => '送信する応答の種類を選択';

  @override
  String get reply_command_reply_title => 'コマンド返信';

  @override
  String get reply_configure_workflow => '応答ワークフローを設定';

  @override
  String get reply_editor_title => '返信詳細';

  @override
  String get reply_mode_layout => 'レイアウトモード';

  @override
  String get reply_mode_layout_desc =>
      'Discordのリッチレイアウトシステム — コンテナ、メディア、テキスト、フォーム';

  @override
  String get reply_mode_modal => 'モーダルフォーム';

  @override
  String get reply_mode_modal_desc => 'テキスト入力フィールド付きのポップアップダイアログ';

  @override
  String get reply_mode_standard => '標準メッセージ';

  @override
  String get reply_mode_standard_desc => 'テキスト、埋め込み、オプションのボタン/セレクトメニュー';

  @override
  String get reply_response_text_helper =>
      'スラッシュコマンドの返信テキストとして使用。((変数)) 構文をサポート。';

  @override
  String get reply_response_text_label => '応答テキスト';

  @override
  String get reply_response_workflow => '応答ワークフロー';

  @override
  String response_embeds_count(int count) {
    return '$count 埋め込み';
  }

  @override
  String get response_interactive_components => 'インタラクティブコンポーネント';

  @override
  String get response_mode_layout => 'レイアウトモード';

  @override
  String get response_mode_modal => 'モーダルフォーム';

  @override
  String get response_mode_standard => '標準メッセージ';

  @override
  String get response_visibility_ephemeral => 'エフェメラル';

  @override
  String get response_visibility_public => '公開';

  @override
  String get response_workflow_auto_defer => 'アクションがある場合自動遅延';

  @override
  String get response_workflow_auto_defer_desc =>
      '迅速に確認応答し、アクションを実行してから最終応答を編集します。';

  @override
  String get response_workflow_condition_desc =>
      '変数が存在し空でない場合 => THENテキスト、それ以外はELSEテキスト。';

  @override
  String get response_workflow_conditional_title => '条件付き応答 (MVP)';

  @override
  String get response_workflow_deferred_reply => '遅延返信';

  @override
  String get response_workflow_else_text => 'ELSE 応答テキスト (オプション)';

  @override
  String get response_workflow_enable_condition => '条件を有効化';

  @override
  String get response_workflow_ephemeral_only_user => 'エフェメラル (コマンド実行者 only)';

  @override
  String get response_workflow_error_policy => 'エラーポリシー';

  @override
  String get response_workflow_error_policy_desc =>
      'アクションが失敗した場合、遅延メッセージをエラーで編集します。';

  @override
  String get response_workflow_mode_component => 'コンポーネント';

  @override
  String get response_workflow_mode_modal => 'モーダル';

  @override
  String get response_workflow_mode_normal => '通常';

  @override
  String get response_workflow_public => '公開';

  @override
  String get response_workflow_revert_tooltip => 'すべての変更を元に戻す';

  @override
  String get response_workflow_then_text => 'THEN 応答テキスト (オプション)';

  @override
  String get response_workflow_title => '応答ワークフロー';

  @override
  String get response_workflow_variable_key => '変数キー (例: opts.userId)';

  @override
  String get response_workflow_visibility => '可視性';

  @override
  String get restore_completed => '復元完了';

  @override
  String get restore_runtime_db_recommended => '復元完了 (SQLiteランタイム復元、再起動推奨)';

  @override
  String get review_actions_title => 'アクション';

  @override
  String review_description_line(String desc) {
    return '説明: $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'フォルダ: $folder';
  }

  @override
  String get review_info_title => '情報';

  @override
  String get review_legacy_mode => 'レガシーモード有効';

  @override
  String get review_local_only => 'ローカルのみのコマンド';

  @override
  String review_name_line(String name) {
    return '名前: $name';
  }

  @override
  String get review_name_untitled => '(無題)';

  @override
  String review_options_count(int count) {
    return '$count オプション';
  }

  @override
  String get review_reply_title => '返信';

  @override
  String review_subcommand_routes(int count) {
    return '$count サブコマンドルート';
  }

  @override
  String get review_trigger_inputs_title => 'トリガーと入力';

  @override
  String review_type_line(String type) {
    return 'タイプ: $type';
  }

  @override
  String get rewarded_start_complete_ad => 'ホスティングセッションを開始するには広告を最後まで視聴してください。';

  @override
  String get rewarded_start_continue => '続ける';

  @override
  String get rewarded_start_message =>
      'このホスティングセッションを開始するには広告が必要です。これはプロジェクトの資金となります。プレミアムユーザー';

  @override
  String get rewarded_start_no_ad_available => '現在利用可能な広告がありません。後でもう一度お試しください。';

  @override
  String get rewarded_start_skip => 'スキップ';

  @override
  String get rewarded_start_thanks => 'ご支援ありがとうございます！';

  @override
  String get rewarded_start_title => '広告が必要です';

  @override
  String get rewarded_start_watch => '広告を見る';

  @override
  String get runner_select_source => 'ランナーを選択';

  @override
  String get runner_source_all => 'すべてのランナー';

  @override
  String runner_source_label(String name) {
    return 'ランナー: $name';
  }

  @override
  String get runner_source_local => 'ローカル';

  @override
  String get runner_source_manager => 'Bot Creator サーバー';

  @override
  String get runner_source_manager_unavailable =>
      '設定でBot Creatorにサインインして、Bot Creatorサーバーからの統計を読み込んでください。';

  @override
  String get save => '保存';

  @override
  String get scheduler_add_title => 'スケジュールを追加';

  @override
  String get scheduler_add_trigger => 'トリガーを追加';

  @override
  String scheduler_delete_confirm(String label) {
    return 'スケジュール \"$label\" を削除しますか？';
  }

  @override
  String get scheduler_delete_title => 'スケジュールを削除';

  @override
  String get scheduler_edit_title => 'スケジュールを編集';

  @override
  String get scheduler_empty => 'まだスケジュールされたトリガーがありません。';

  @override
  String get scheduler_every_minutes => '間隔 (分)';

  @override
  String get scheduler_invalid_minutes => '間隔は0より大きい必要があります。';

  @override
  String get scheduler_label_field => 'ラベル';

  @override
  String get scheduler_label_hint => 'オプションの表示ラベル';

  @override
  String scheduler_limit_reached(int limit) {
    return 'スケジューラーの上限に達しました ($limit)。';
  }

  @override
  String get scheduler_no_workflows => 'スケジュールを追加する前に少なくとも1つのワークフローを作成してください。';

  @override
  String get scheduler_page_title => 'スケジューラー';

  @override
  String scheduler_save_failed(String error) {
    return 'スケジュールの保存に失敗: $error';
  }

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'ワークフロー: $workflow • $minutes 分ごと';
  }

  @override
  String get scheduler_tab => 'スケジューラー';

  @override
  String get scheduler_tab_short => 'スケジュール';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'トリガー: $count$limit';
  }

  @override
  String get scoped_default_value => 'デフォルト値';

  @override
  String get scoped_default_value_hint => 'オプション';

  @override
  String scoped_delete_confirm(String key) {
    return '\"$key\" とその保存されたすべてのランタイムデータを削除しますか？';
  }

  @override
  String get scoped_delete_title => 'スコープ変数を削除';

  @override
  String get scoped_empty => 'スコープ変数が定義されていません';

  @override
  String get scoped_empty_subtitle =>
      'スコープ変数はDiscordコンテキスト（ユーザー、サーバー…）ごとに値を保存します。実行時に設定されます。';

  @override
  String get scoped_explore_runtime => 'ランタイムデータを探索';

  @override
  String scoped_ref(String ref) {
    return '参照: $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'レガシー: $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'すべてコピー';

  @override
  String get scoped_runtime_empty => 'ランタイムデータがありません。\nこのキーは実行時にボットによって設定されます。';

  @override
  String get scoped_runtime_search => 'IDまたは名前で検索…';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'スコープ: $scope · $count コンテキストが見つかりました';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'ランタイムデータ — \"$key\"';
  }

  @override
  String get scoped_scope => 'スコープ';

  @override
  String get scoped_scope_help => '変数が保存されるエンティティレベル。';

  @override
  String get scoped_title => 'スコープ変数';

  @override
  String get scratch_add_block => 'ブロックを追加';

  @override
  String get scratch_bdfd_script => 'BDFD スクリプト';

  @override
  String get scratch_block_entry_point => 'コマンドトリガー';

  @override
  String get scratch_block_metadata => 'メタデータ';

  @override
  String get scratch_block_required => '必須';

  @override
  String get scratch_dart_script => 'Dart スクリプト';

  @override
  String get scratch_entry_event_trigger => 'イベントトリガー';

  @override
  String get scratch_entry_function => '関数';

  @override
  String get scratch_entry_interaction => 'スラッシュコマンド (/)';

  @override
  String get scratch_entry_message => 'テキストメッセージ';

  @override
  String get scratch_entry_point_hint => 'スクラッチエントリポイントのヒント';

  @override
  String get scratch_entry_point_label => 'エントリポイント名';

  @override
  String get scratch_entry_point_listen => 'このコマンドはいつ実行されますか？';

  @override
  String get scratch_event_category => 'イベントカテゴリ';

  @override
  String get scratch_event_name => 'イベント名';

  @override
  String get scratch_event_variables => 'イベント変数';

  @override
  String get scratch_execution_mode => 'コマンドはどのように構築されますか？';

  @override
  String get scratch_legacy_config => 'レガシー設定';

  @override
  String get scratch_meta_advanced => '詳細設定';

  @override
  String get scratch_meta_desc_hint => 'コマンドの説明';

  @override
  String get scratch_meta_name_hint => 'コマンド名';

  @override
  String get scratch_meta_type_label => 'コマンドタイプ';

  @override
  String get scratch_meta_type_message => 'メッセージコマンド';

  @override
  String get scratch_meta_type_message_desc => 'メッセージのコンテキストメニューからトリガーされます。';

  @override
  String get scratch_meta_type_prefix => 'プレフィックスコマンド';

  @override
  String get scratch_meta_type_prefix_desc => 'テキストプレフィックスでトリガーされます（例: !help）。';

  @override
  String get scratch_meta_type_slash => 'スラッシュコマンド';

  @override
  String get scratch_meta_type_slash_desc => 'Discordで / を入力してトリガーされます。';

  @override
  String get scratch_meta_type_user => 'ユーザーコマンド';

  @override
  String get scratch_meta_type_user_desc => 'ユーザーのコンテキストメニューからトリガーされます。';

  @override
  String get scratch_mode_bdfd => 'BDFD コード';

  @override
  String get scratch_mode_blocks => 'ビジュアル (ブロック)';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_response_block => '応答';

  @override
  String get scratch_response_components => 'コンポーネント';

  @override
  String get scratch_response_edit => '応答を編集';

  @override
  String get scratch_workflow_add_argument => '引数を追加';

  @override
  String get scratch_workflow_arguments => '引数 (変数)';

  @override
  String get scratch_workflow_metadata => 'ワークフロー設定';

  @override
  String get scratch_workflow_name => 'ワークフロー名';

  @override
  String get scratch_workflow_type => 'ワークフロータイプ';

  @override
  String get scratch_workflow_type_event => 'イベント駆動';

  @override
  String get scratch_workflow_type_general => '一般';

  @override
  String get serialization_export_base64_title => 'コマンドをBase64でエクスポート';

  @override
  String get serialization_export_json_subtitle => '読み取り可能なJSONをクリップボードにコピー';

  @override
  String get serialization_export_json_title => 'コマンドをJSONでエクスポート';

  @override
  String get serialization_import_desc => 'コマンドペイロードを貼り付け（JSON または Base64）。';

  @override
  String get serialization_import_title => 'コマンドをインポート';

  @override
  String get serialization_imported => 'コマンドがエディタにインポートされました。';

  @override
  String get serialization_invalid_format => '無効なコマンドペイロード形式です。';

  @override
  String get serialization_invalid_structure => '無効なコマンドペイロード構造です。';

  @override
  String get settings_account_connect_label => 'DiscordでBot Creatorにサインイン';

  @override
  String get settings_account_connected_hint =>
      'アカウントが接続されました。ボットとデータがBot Creatorと同期されました。';

  @override
  String get settings_account_disconnect_label => 'サインアウト';

  @override
  String get settings_account_disconnected_hint =>
      'Bot Creatorアカウントはボットを追加すると自動的に作成されます。その後Discordでサインインしてください。';

  @override
  String get settings_account_status_connected => 'アカウント接続済み';

  @override
  String get settings_account_status_disconnected => '未サインイン';

  @override
  String get settings_ads_privacy_loading => '広告プライバシー設定を確認中...';

  @override
  String get settings_ads_privacy_manage => '広告プライバシー設定を管理';

  @override
  String get settings_ads_privacy_not_required => '現在、広告プライバシーオプションは必要ありません';

  @override
  String get settings_ads_privacy_open_error => '広告プライバシーオプションを開けませんでした';

  @override
  String get settings_ads_privacy_opened => '広告プライバシーオプションが開かれました';

  @override
  String get settings_app_version => 'アプリ';

  @override
  String get settings_appearance_title => '外観と言語';

  @override
  String get settings_auto_backup_check_loading => '自動バックアップ確認中…';

  @override
  String get settings_auto_backup_every_12h => '12時間ごと';

  @override
  String get settings_auto_backup_every_24h => '24時間ごと';

  @override
  String get settings_auto_backup_every_6h => '6時間ごと';

  @override
  String get settings_auto_backup_every_72h => '72時間ごと';

  @override
  String get settings_auto_backup_interval => '自動バックアップ間隔';

  @override
  String get settings_backup_now => '今すぐバックアップ';

  @override
  String get settings_backup_restore_desc => 'Google Driveとのデータ同期を管理';

  @override
  String get settings_backup_restore_title => 'バックアップと復元';

  @override
  String get settings_builtin_help => '組み込みレガシー !help コマンド';

  @override
  String get settings_builtin_help_subtitle =>
      '明示的なトグル付きの必須機能。カスタムヘルプ動作のみが必要な場合は無効にしてください。';

  @override
  String get settings_clear_logs => 'ログをクリア';

  @override
  String get settings_cloud_hosting_enabled =>
      'モバイルボットはBot Creatorサーバーを使用するようになりました。';

  @override
  String get settings_compatibility_desc => 'BDFDから移行するユーザー向けの機能カバレッジのクイックビュー。';

  @override
  String get settings_compatibility_functions_category_components =>
      'コンポーネント / インタラクション';

  @override
  String get settings_compatibility_functions_category_control => '制御フロー';

  @override
  String get settings_compatibility_functions_category_embeds => '埋め込み';

  @override
  String get settings_compatibility_functions_category_guards => 'ガードと権限';

  @override
  String get settings_compatibility_functions_category_http => 'HTTP ヘルパー';

  @override
  String get settings_compatibility_functions_category_json => 'JSON ヘルパー';

  @override
  String get settings_compatibility_functions_category_logging => 'ログ';

  @override
  String get settings_compatibility_functions_category_messages => 'メッセージ';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'ランタイムプレースホルダー';

  @override
  String get settings_compatibility_functions_category_threads => 'スレッド';

  @override
  String get settings_compatibility_functions_category_variables => 'スコープ変数';

  @override
  String settings_compatibility_functions_count(int count) {
    return '互換関数: $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'BDFD参照総数: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'Bot Creator対応: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Bot Creatorのみ: $count';
  }

  @override
  String settings_compatibility_functions_count_both(int count) {
    return '両方で対応: $count';
  }

  @override
  String settings_compatibility_functions_count_missing(int count) {
    return 'Bot Creatorで未対応: $count';
  }

  @override
  String get settings_compatibility_functions_empty => 'このセクションに関数はありません。';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'BDFD専用エントリは、提供されたBDFDカタログに記載されているが現在実装されていない関数です。';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Bot Creator実装とBDFD参照関数の差分ビュー。';

  @override
  String get settings_compatibility_functions_note =>
      'このページは現在の実装範囲から生成されており、時間とともに成長します。';

  @override
  String get settings_compatibility_functions_search_hint =>
      '関数を検索 (例: \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Bot Creatorのみ対応';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'ループヘルパーは現在Bot Creator固有です。';

  @override
  String get settings_compatibility_functions_section_both =>
      'Bot CreatorとBDFDの両方で対応';

  @override
  String get settings_compatibility_functions_section_missing =>
      'BDFDで利用可能だがBot Creatorで未対応';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Bot Creator BDFDモードで現在実装され使用可能な関数。';

  @override
  String get settings_compatibility_functions_title => '互換BDFD関数';

  @override
  String get settings_compatibility_item_bdscript_desc => 'BDFD関数カタログの完全カバレッジ。';

  @override
  String get settings_compatibility_item_bdscript_title => 'BDScript関数パリティ';

  @override
  String get settings_compatibility_item_events_desc =>
      'ほとんどの一般的なイベントがサポートされています。一部はランタイム制限があります。';

  @override
  String get settings_compatibility_item_events_title => 'イベントカバレッジ';

  @override
  String get settings_compatibility_item_runner_desc =>
      'リモートランナーが利用可能です。マルチランナーサポートは進行中です。';

  @override
  String get settings_compatibility_item_runner_title => 'ランナーアーキテクチャ';

  @override
  String get settings_compatibility_item_variables_desc =>
      '動的変数とテンプレートヘルパーがサポートされています。';

  @override
  String get settings_compatibility_item_variables_title => 'ランタイム変数とテンプレート';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'ビジュアルコマンドと応答ワークフローが利用可能です。';

  @override
  String get settings_compatibility_item_workflows_title => 'ワークフロービルダー';

  @override
  String get settings_compatibility_note =>
      'このスナップショットは意図的に高レベルであり、リリースとともに進化します。';

  @override
  String get settings_compatibility_open_functions => '互換関数を表示';

  @override
  String get settings_compatibility_status_missing => '未対応';

  @override
  String get settings_compatibility_status_partial => '部分的';

  @override
  String get settings_compatibility_status_supported => '対応済み';

  @override
  String get settings_compatibility_title => 'BDFD互換性スナップショット';

  @override
  String get settings_data_operations_title => 'データ操作';

  @override
  String get settings_debug_desc => 'テスト用にローカル設定をリセットするか、オンボーディングを再実行します。';

  @override
  String get settings_debug_premium_bypass => 'プレミアムバイパス';

  @override
  String get settings_debug_premium_bypass_desc =>
      'サブスクリプションなしですべてのプレミアム機能を解除（デバッグのみ）。';

  @override
  String get settings_debug_title => 'デバッグツール';

  @override
  String get settings_diagnostics_copied => '診断情報がクリップボードにコピーされました';

  @override
  String get settings_diagnostics_copy_all => 'すべてのログをコピー';

  @override
  String get settings_diagnostics_dialog_title => '起動診断';

  @override
  String get settings_diagnostics_empty => 'まだアプリケーションログがありません。';

  @override
  String get settings_diagnostics_page_scope_note =>
      'アプリ診断ログのみを表示します（ボットログは除外）。';

  @override
  String get settings_diagnostics_page_title => 'アプリケーションログ';

  @override
  String get settings_diagnostics_refresh => 'ログを更新';

  @override
  String get settings_diagnostics_section_title => '診断';

  @override
  String get settings_discord_rpc_authenticating => 'Discordで認証中…';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      '認証コードがキャッシュされました。再試行してトークン交換を完了してください';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      '認証コードを受信しました';

  @override
  String get settings_discord_rpc_authorize => '認証';

  @override
  String get settings_discord_rpc_authorizing => 'Discord認証を待機中…';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label => 'OAuthブローカーURL (詳細、オプション)';

  @override
  String get settings_discord_rpc_broker_required =>
      '公開クライアントフローにはクライアントIDで十分です。ブローカーURLとクライアントシークレットはオプションです。';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'このIDはBot Creatorで固定されており、設定から変更できません。';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'DiscordアプリケーションクライアントIDが必要です';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'ローカルで処理される機密クライアントフロー用のオプションの高度なフォールバック。';

  @override
  String get settings_discord_rpc_client_secret_hint => 'クライアントシークレット';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Discordアプリケーションクライアントシークレット (オプション)';

  @override
  String get settings_discord_rpc_complete_authorization => '認証を完了';

  @override
  String get settings_discord_rpc_connect => 'プレゼンスを更新';

  @override
  String get settings_discord_rpc_connected => 'プレゼンスがDiscordに送信されました';

  @override
  String get settings_discord_rpc_connecting => 'Discordに接続中…';

  @override
  String get settings_discord_rpc_desc =>
      'Bot CreatorデスクトップアクティビティをローカルDiscordクライアントに公開します。Bot Creatorは常に使用します';

  @override
  String get settings_discord_rpc_disabled => '無効';

  @override
  String get settings_discord_rpc_disconnect => 'IPCを閉じる';

  @override
  String get settings_discord_rpc_disconnected => 'IPCが閉じられました';

  @override
  String get settings_discord_rpc_enable => 'Discord Rich Presenceを有効にする';

  @override
  String get settings_discord_rpc_enable_first =>
      '最初にDiscord Rich Presenceを有効にしてください';

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'IPCエンドポイント: $endpoint';
  }

  @override
  String get settings_discord_rpc_error => 'Discord RPCエラー';

  @override
  String get settings_discord_rpc_exchanging_code => 'OAuth交換を完了中…';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'ローカルDiscord IPC接続済み。OAuth HTTPリクエストは未送信、認証がまだ必要です';

  @override
  String get settings_discord_rpc_ipc_open => 'ローカルIPCは既に開いています';

  @override
  String settings_discord_rpc_last_error(String error) {
    return '最後のエラー: $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization => '認証が必要です';

  @override
  String get settings_discord_rpc_not_configured => 'クライアントIDが必要です';

  @override
  String get settings_discord_rpc_open_ipc => 'ローカルIPCを開く';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presenceはデスクトップのみ対応です';

  @override
  String get settings_discord_rpc_save => '設定を保存';

  @override
  String get settings_discord_rpc_saved => 'Discord Rich Presence設定が保存されました';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'このプラットフォームではDiscordトランスポートはまだサポートされていません';

  @override
  String settings_discord_rpc_user(String user) {
    return '認証済みユーザー: $user';
  }

  @override
  String get settings_drive_connect => 'Google Driveに接続';

  @override
  String get settings_drive_connect_loading => 'Google Driveに接続中…';

  @override
  String get settings_drive_connected => 'Google Driveに接続されました';

  @override
  String get settings_drive_desc => 'Google Driveアカウントを接続してデータを同期';

  @override
  String get settings_drive_disconnect => '切断';

  @override
  String get settings_drive_disconnect_loading => '切断中…';

  @override
  String get settings_drive_disconnected => 'Google Driveから切断されました';

  @override
  String get settings_drive_status_connected => '接続済み';

  @override
  String get settings_drive_title => 'Google Drive接続';

  @override
  String get settings_enable_auto_backup => '自動バックアップを有効にする';

  @override
  String get settings_enable_auto_backup_desc =>
      '期限が来たら自動的にバージョン管理されたスナップショットを作成します。';

  @override
  String get settings_execution_mode_desc =>
      'このプラットフォームでは、Bot Creatorがボットをホストすることはありません。セルフホストランナーを使用するか、';

  @override
  String get settings_execution_mode_local_active =>
      'ボットはローカルで起動するようになりました。ランナー設定は保存され、いつでも再有効化できます。';

  @override
  String get settings_execution_mode_no_runner =>
      'まだランナーが設定されていません。追加するまでアプリはローカルのままです。';

  @override
  String get settings_execution_mode_runner_priority =>
      'セルフホストランナーが優先されます。ランナーが設定されていない場合、アプリはローカルにフォールバックします。';

  @override
  String get settings_execution_mode_title => '実行モード';

  @override
  String get settings_execution_mode_use_runner => 'セルフホストランナーを使用';

  @override
  String get settings_export => 'エクスポート';

  @override
  String get settings_export_app_data => 'アプリデータをエクスポート';

  @override
  String get settings_export_loading => 'エクスポート中…';

  @override
  String get settings_import => 'インポート';

  @override
  String get settings_import_app_data => 'アプリデータをインポート';

  @override
  String get settings_import_loading => 'インポート中…';

  @override
  String get settings_language_desc => 'アプリで使用する言語を選択してください。';

  @override
  String get settings_language_system => '自動 (デバイス)';

  @override
  String get settings_language_title => '言語';

  @override
  String get settings_language_updated => '言語が更新されました';

  @override
  String settings_last_auto_backup_at(String date) {
    return '最終自動バックアップ: $date';
  }

  @override
  String get settings_last_auto_backup_never => '最終自動バックアップ: なし';

  @override
  String get settings_legacy_prefix => 'レガシーコマンドプレフィックス';

  @override
  String get settings_legacy_prefix_helper =>
      'テンプレートとスコープ変数をサポート (bc_ はオプション)。例: ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? または ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc => 'データの取り扱いと保存方法を確認してください。';

  @override
  String get settings_legal_title => '法的情報';

  @override
  String get settings_local_hosting_enabled =>
      'モバイルボットはデバイスを使用してホスティングするようになりました。';

  @override
  String get settings_logs_cleared => '診断ログがクリアされました';

  @override
  String get settings_main_api_auth_failed =>
      'Bot Creator Serverセッションが無効または期限切れです';

  @override
  String get settings_main_api_check => 'Bot Creator Serverを確認';

  @override
  String get settings_main_api_clear => 'クリア';

  @override
  String get settings_main_api_cleared => 'Bot Creator Server設定がクリアされました';

  @override
  String get settings_main_api_connect_discord => 'Discordアカウントを接続';

  @override
  String get settings_main_api_connected => 'Bot Creator Server 到達可能 ✓';

  @override
  String get settings_main_api_connected_discord => 'Discordアカウント接続済み';

  @override
  String settings_main_api_connected_user(String user) {
    return '$user として接続中';
  }

  @override
  String get settings_main_api_desc =>
      'Bot CreatorをBot Creator Serverに接続し、Discordでサインインします。Discordクライアント';

  @override
  String get settings_main_api_desktop_only =>
      'Bot Creator Server経由のDiscordログインはデスクトップのみ対応です。';

  @override
  String get settings_main_api_disconnect => 'アカウントを切断';

  @override
  String get settings_main_api_not_configured => 'Bot Creator Server URLが必要です';

  @override
  String get settings_main_api_save => 'Bot Creator Serverを保存';

  @override
  String get settings_main_api_saved => 'Bot Creator Server設定が保存されました';

  @override
  String get settings_main_api_session_connected => 'Discordセッション有効';

  @override
  String get settings_main_api_session_disconnected => 'Discordセッション切断';

  @override
  String get settings_main_api_session_expired => 'Discordセッション期限切れ';

  @override
  String get settings_main_api_title => 'Bot Creator Server';

  @override
  String get settings_main_api_unreachable => 'Bot Creator Serverに到達できません';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_url_required => 'Bot Creator Server URLが必要です';

  @override
  String get settings_main_api_user_unknown => 'Discordユーザー';

  @override
  String get settings_manual_snapshot_label => '手動スナップショット';

  @override
  String get settings_member_badge => 'メンバー';

  @override
  String get settings_notifications_desc => '受信したいプッシュ通知の種類を選択してください。';

  @override
  String get settings_notifications_title => '通知';

  @override
  String get settings_notifications_topic_billing => '請求';

  @override
  String get settings_notifications_topic_billing_desc =>
      'サブスクリプションの更新リマインダーと支払い確認。';

  @override
  String get settings_notifications_topic_botAlerts => 'ボットアラート';

  @override
  String get settings_notifications_topic_botAlerts_desc =>
      'ボットがオフラインになったりエラーが発生した場合の警告。';

  @override
  String get settings_notifications_topic_broadcast => 'お知らせ';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'Bot Creatorからの重要なお知らせとニュース。';

  @override
  String get settings_notifications_topic_updates => 'アップデート';

  @override
  String get settings_notifications_topic_updates_desc =>
      '新機能、アプリアップデート、変更履歴のハイライト。';

  @override
  String get settings_open_ad_inspector => '広告インスペクターを開く';

  @override
  String get settings_oss_licenses => 'オープンソースライセンス';

  @override
  String get settings_owner_badge => '所有者';

  @override
  String get settings_owner_fallback => '所有者';

  @override
  String get settings_personal_owner_fallback => '個人ユーザー';

  @override
  String get settings_personal_owner_id_label => '所有者ID:';

  @override
  String get settings_personal_owner_label => '所有者:';

  @override
  String get settings_personal_ownership => '個人所有権';

  @override
  String get settings_preferences_reset_done => '設定がリセットされました';

  @override
  String get settings_privacy_policy => 'プライバシーポリシー';

  @override
  String get settings_raw_json_tile => '生JSONを表示 (RAW JSON)';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_replay_onboarding => 'オンボーディングを再実行';

  @override
  String get settings_replay_onboarding_desc => 'オンボーディングをリセットして今すぐ再起動します。';

  @override
  String get settings_reset_preferences => '設定をリセット';

  @override
  String get settings_reset_preferences_desc => 'テーマ、言語、オンボーディングの進行状況をリセットします。';

  @override
  String get settings_restore_snapshot => 'このスナップショットを復元';

  @override
  String get settings_run_auto_backup_now => '今すぐ自動バックアップを実行';

  @override
  String get settings_run_diagnostics => '診断を実行';

  @override
  String settings_runner_active(String url) {
    return 'アクティブランナーAPI: $url';
  }

  @override
  String get settings_runner_auth_failed => 'ランナーがAPIトークンを拒否しました';

  @override
  String get settings_runner_check => '接続を確認';

  @override
  String get settings_runner_clear => 'クリア';

  @override
  String get settings_runner_cleared => 'ランナー設定がクリアされました';

  @override
  String get settings_runner_connected => 'ランナー到達可能 ✓';

  @override
  String get settings_runner_connecting => '接続を確認中…';

  @override
  String get settings_runner_desc =>
      'アプリをBot Creatorランナーに接続します。リモートランナーは信頼できるネットワークに配置してください。';

  @override
  String get settings_runner_disable_temp => 'ランナーを一時的に無効化';

  @override
  String get settings_runner_disable_temp_desc =>
      'ランナー設定を保持したまま、再有効化までローカルモードを強制します。';

  @override
  String get settings_runner_disconnected => 'ランナーが切断されました';

  @override
  String get settings_runner_not_connected => '未接続';

  @override
  String get settings_runner_reenabled => 'ランナーが再有効化されました';

  @override
  String get settings_runner_save => '設定を保存';

  @override
  String get settings_runner_saved => 'ランナー設定が保存されました';

  @override
  String get settings_runner_temporarily_disabled =>
      'ランナーが一時的に無効化されました（ローカルモード有効）';

  @override
  String get settings_runner_temporarily_disabled_saved => 'ランナーが一時的に無効化されました';

  @override
  String get settings_runner_title => 'ランナーAPI';

  @override
  String get settings_runner_token_hint => 'Bearer トークン (localhostではオプション)';

  @override
  String get settings_runner_token_label => 'ランナーAPIトークン';

  @override
  String get settings_runner_unreachable => 'ランナーに到達できません';

  @override
  String get settings_runner_url_clear => 'クリア';

  @override
  String get settings_runner_url_cleared => 'ランナーURLがクリアされました';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_url_save => 'URLを保存';

  @override
  String get settings_runner_url_saved => 'ランナーURLが保存されました';

  @override
  String get settings_runner_version => 'ランナー';

  @override
  String settings_snapshot_apps_count(int count) {
    return 'アプリ: $count';
  }

  @override
  String get settings_snapshot_apps_list => 'このスナップショット内のアプリ';

  @override
  String get settings_snapshot_create_loading => 'スナップショットを作成中…';

  @override
  String settings_snapshot_created_at(String date) {
    return '作成日時: $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'スナップショットが作成されました: $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'スナップショットを削除中…';

  @override
  String get settings_snapshot_deleted => 'スナップショットが削除されました';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'ファイル: $count • サイズ: $size';
  }

  @override
  String settings_snapshot_id(String id) {
    return 'ID: $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'ラベル: $label';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date • $count ファイル • $size';
  }

  @override
  String get settings_snapshot_no_metadata => 'アプリメタデータがありません。';

  @override
  String get settings_snapshot_preview_title => 'スナップショットプレビュー';

  @override
  String get settings_snapshot_restore_loading => 'スナップショットを復元中…';

  @override
  String get settings_snapshots_delete_all => 'すべてのスナップショットを削除';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return '$count 個のスナップショットを完全に削除しますか？この操作は元に戻せません。';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count 個のスナップショットが削除されました。';
  }

  @override
  String get settings_snapshots_delete_all_loading => 'すべてのスナップショットを削除中…';

  @override
  String get settings_snapshots_delete_all_title => 'すべてのスナップショットを削除';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return '\"$label\" を完全に削除しますか？この操作は元に戻せません。';
  }

  @override
  String get settings_snapshots_delete_select_desc =>
      '削除するスナップショットを選択してください（古い順）。';

  @override
  String get settings_snapshots_delete_select_title => 'スナップショットを削除';

  @override
  String get settings_snapshots_delete_select_tooltip => '選択したスナップショットを削除';

  @override
  String get settings_snapshots_empty => 'まだスナップショットが見つかりません。';

  @override
  String get settings_snapshots_refresh => 'スナップショットを更新';

  @override
  String get settings_snapshots_refresh_loading => 'スナップショットを更新中…';

  @override
  String get settings_snapshots_title => 'スナップショット';

  @override
  String get settings_solo_pill => 'ソロ';

  @override
  String get settings_startup_mode_cloud_desc =>
      'AndroidとiOSで推奨。ログ、統計、起動はすべてBot Creatorを経由します。';

  @override
  String get settings_startup_mode_desc =>
      'ボットをBot Creatorサーバーで起動するか、このデバイスでローカルに起動するかを選択します。';

  @override
  String get settings_startup_mode_ios_unavailable => 'iOSではローカルモードは利用できません。';

  @override
  String get settings_startup_mode_ios_warning =>
      'iOSではローカルモードはサポートされていません。ボットは常にBot Creatorサーバーを使用します。';

  @override
  String get settings_startup_mode_local_desc =>
      'ボットはこのデバイスでローカルに起動するようになりました。';

  @override
  String get settings_startup_mode_local_warning =>
      'ローカルモードはデバッグや特定のニーズ向けの高度なオプションです。通常の使用では、';

  @override
  String get settings_startup_mode_title => 'ボット起動モード';

  @override
  String get settings_startup_mode_use_cloud => 'Bot Creatorサーバーを使用';

  @override
  String get settings_status_remove_confirm => 'このステータスエントリは削除されます。続行しますか？';

  @override
  String get settings_tab => '設定';

  @override
  String get settings_team_id_label => 'チームID:';

  @override
  String settings_team_members_label(int count) {
    return 'チームメンバー ($count)';
  }

  @override
  String get settings_team_name_label => 'チーム名:';

  @override
  String get settings_team_owner_label => 'チームリーダー';

  @override
  String get settings_team_ownership => 'チーム所有権';

  @override
  String get settings_team_pill => 'チーム';

  @override
  String get settings_theme_switch_dark => 'ダークモードに切り替え';

  @override
  String get settings_theme_switch_light => 'ライトモードに切り替え';

  @override
  String get settings_version_title => 'バージョン';

  @override
  String get settings_view_startup_logs => '起動ログを表示';

  @override
  String get startup_copy_diagnostics => '診断情報をコピー';

  @override
  String get startup_diagnostics_copied => '診断情報がクリップボードにコピーされました';

  @override
  String get startup_error_title => '起動エラー';

  @override
  String get startup_failed_message => 'このデバイスでBot Creatorの起動に失敗しました。';

  @override
  String get startup_refresh_diagnostics => '診断情報を更新';

  @override
  String get subscription_active_annual => 'プレミアム — 年間';

  @override
  String get subscription_active_label => 'アクティブプラン:';

  @override
  String get subscription_active_monthly => 'プレミアム — 月間';

  @override
  String get subscription_annual_title => '年間';

  @override
  String get subscription_benefit_fast_start => 'ボットが即座に起動、ポップアップなし';

  @override
  String get subscription_benefit_no_ads => 'アプリ内の広告を完全に削除';

  @override
  String get subscription_benefit_support => '独立した開発を支援';

  @override
  String get subscription_error => '購入を完了できませんでした。もう一度お試しください。';

  @override
  String get subscription_error_product_unavailable =>
      'このプランは現在利用できません。後でもう一度お試しください。';

  @override
  String get subscription_error_purchase_start_failed =>
      '購入を開始できませんでした。もう一度お試しください。';

  @override
  String get subscription_error_store_unavailable =>
      'App Storeが現在利用できません。しばらくしてからもう一度お試しください。';

  @override
  String get subscription_feature_analytics_desc =>
      'エラー率、レイテンシパーセンタイル、ロケールインサイトにアクセス。';

  @override
  String get subscription_feature_analytics_title => '高度な分析';

  @override
  String get subscription_feature_auto_restart_desc =>
      '完全な再起動が必要な場合にボットを自動的に再起動します。';

  @override
  String get subscription_feature_auto_restart_title => '自動再起動';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'シャードワーカーに負荷を分散して大規模ボットをスケーリング。';

  @override
  String get subscription_feature_auto_sharding_title => '自動シャーディング';

  @override
  String get subscription_feature_coming_soon => '近日公開';

  @override
  String get subscription_feature_debug_replay_desc =>
      'デバッグ用にコマンドアクションをステップごとに記録・再生。';

  @override
  String get subscription_feature_debug_replay_title => 'ビジュアルデバッグリプレイ';

  @override
  String get subscription_feature_instant_start_desc => '報酬広告の中断なしにボットを即座に起動。';

  @override
  String get subscription_feature_instant_start_title => 'インスタント起動';

  @override
  String get subscription_feature_lavalink_desc =>
      'Play music and audio in Discord voice channels using Lavalink.';

  @override
  String get subscription_feature_lavalink_title => 'Lavalink audio support';

  @override
  String get subscription_feature_no_ads_desc => 'アプリ体験全体からすべての広告配置を削除。';

  @override
  String get subscription_feature_no_ads_title => '広告なし';

  @override
  String get subscription_feature_scheduler_desc =>
      'X分ごとに自動的にワークフローを実行（最大10個まで有効）。';

  @override
  String get subscription_feature_scheduler_title => 'スケジューラートリガー';

  @override
  String get subscription_feature_webhooks_desc =>
      '安全なWebhookエンドポイントを作成し、呼び出しをワークフローにルーティング。';

  @override
  String get subscription_feature_webhooks_title => '受信Webhook';

  @override
  String get subscription_manage => 'サブスクリプションを管理';

  @override
  String get subscription_monthly_title => '月間';

  @override
  String get subscription_not_available_on_platform =>
      'サブスクリプションは現在モバイルのみ対応です。';

  @override
  String get subscription_per_month => '月額';

  @override
  String get subscription_per_year => '年額';

  @override
  String get subscription_plan_desc => '広告を削除し、現在および今後のすべてのプレミアム機能にアクセスできます。';

  @override
  String get subscription_plan_label => 'プレミアムベーシック';

  @override
  String get subscription_privacy => 'プライバシーポリシー';

  @override
  String get subscription_restore => '購入を復元';

  @override
  String get subscription_restore_not_found => 'アクティブなサブスクリプションが見つかりません。';

  @override
  String get subscription_restored => 'サブスクリプションが正常に復元されました！';

  @override
  String get subscription_save_badge => '67% 割引';

  @override
  String get subscription_subtitle => 'すべてのプレミアム機能を解除するプランを選択してください。';

  @override
  String get subscription_success => 'プレミアムへようこそ！すべての広告が削除されました。';

  @override
  String get subscription_terms => '利用規約';

  @override
  String get subscription_title => 'プレミアム';

  @override
  String get subscription_unavailable_platform => 'このプラットフォームでは利用できません。';

  @override
  String get support_card_desc => '質問、バグ、提案がありますか？チームやコミュニティとチャットしましょう。';

  @override
  String get support_card_title => 'サポート & コミュニティ';

  @override
  String get support_discord_badge => '公式サポート';

  @override
  String get support_join_discord => 'Discordサーバーに参加';

  @override
  String get template_fun_description => 'コイントス、投票、マジック8ボール。';

  @override
  String get template_fun_name => 'お楽しみボット';

  @override
  String template_gallery_already_exists(String name) {
    return 'コマンド \"$name\" は既に存在するためスキップされました。';
  }

  @override
  String get template_gallery_apply => 'このテンプレートを使用';

  @override
  String template_gallery_apply_error(String error) {
    return 'テンプレートの適用に失敗: $error';
  }

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return 'テンプレートから $count コマンドと $wCount ワークフローが追加されました。';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count コマンド';
  }

  @override
  String get template_gallery_empty => '利用可能なテンプレートがありません。';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return '$name に削除するものがありません。';
  }

  @override
  String get template_gallery_remove_confirm =>
      'このテンプレートからすべてのコマンドとワークフローを削除してもよろしいですか？';

  @override
  String get template_gallery_remove_title => 'テンプレートを削除';

  @override
  String get template_gallery_removed => 'テンプレートのコマンドとワークフローが削除されました。';

  @override
  String get template_gallery_subtitle => '既製のテンプレートでボットを素早く始めましょう。';

  @override
  String get template_gallery_sync_warning =>
      'コマンドはローカルに保存されました。Discordに登録するにはボットを起動してください。';

  @override
  String get template_gallery_title => 'テンプレート';

  @override
  String template_gallery_workflows_count(int count) {
    return '$count ワークフロー';
  }

  @override
  String get template_moderation_description => '追放、キック、メンバーミュート、メッセージ削除。';

  @override
  String get template_moderation_name => 'モデレーションボット';

  @override
  String get template_utility_description => 'Ping、アバター検索、ボット発言コマンド。';

  @override
  String get template_utility_name => 'ユーティリティボット';

  @override
  String get template_welcome_description => '新規メンバーを歓迎、挨拶、サーバー情報を表示。';

  @override
  String get template_welcome_name => 'ウェルカムボット';

  @override
  String unit_day(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日',
      one: '1日',
      zero: '0日',
    );
    return '$_temp0';
  }

  @override
  String unit_hour(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count時間',
      one: '1時間',
      zero: '0時間',
    );
    return '$_temp0';
  }

  @override
  String unit_minute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count分',
      one: '1分',
      zero: '0分',
    );
    return '$_temp0';
  }

  @override
  String unit_month(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countヶ月',
      one: '1ヶ月',
      zero: '0ヶ月',
    );
    return '$_temp0';
  }

  @override
  String get validation_awaited_callback_format =>
      '待機コールバックは \$awaitedCommand[name;filter] または \$awaitedCommandError[name] を使用する必要があります。';

  @override
  String validation_awaited_callback_length(int max) {
    return '待機コールバックトリガーは最大 $max 文字です';
  }

  @override
  String get validation_awaited_callback_local_only =>
      '待機コールバックにはローカルのみのレガシーコマンドが必要です。';

  @override
  String get validation_command_name_invalid_chars =>
      'コマンド名には英数字とアンダースコアのみ使用できます';

  @override
  String validation_command_name_length(int max) {
    return 'コマンド名は最大 $max 文字です';
  }

  @override
  String get validation_command_name_no_ampersand => 'コマンド名をアンパサンドで始めることはできません';

  @override
  String get validation_command_name_no_at => 'コマンド名をアットマークで始めることはできません';

  @override
  String get validation_command_name_no_exclamation => 'コマンド名を感嘆符で始めることはできません';

  @override
  String get validation_command_name_no_hash => 'コマンド名をハッシュで始めることはできません';

  @override
  String get validation_command_name_no_percent => 'コマンド名をパーセント記号で始めることはできません';

  @override
  String get validation_command_name_no_slash => 'コマンド名をスラッシュで始めることはできません';

  @override
  String get validation_command_name_no_spaces => 'コマンド名にスペースを含めることはできません';

  @override
  String get validation_command_name_no_underscore =>
      'コマンド名をアンダースコアで始めることはできません';

  @override
  String get validation_command_name_required => 'コマンド名を入力してください';

  @override
  String get validation_interaction_no_response =>
      'インタラクションコマンドには少なくとも1つの応答アクションが必要です（メッセージで応答、コンポーネントで応答';

  @override
  String get validation_interaction_no_response_short => '応答アクションがありません';

  @override
  String get validation_invalid_permissions =>
      '無効なデフォルトメンバー権限ビットフィールドです。正の整数を使用するか空欄にしてください。';

  @override
  String get validation_legacy_chat_input_only =>
      'レガシーモードはチャット入力コマンドでのみ利用可能です。';

  @override
  String get validation_legacy_only_new_or_local =>
      'レガシー専用モードは新規コマンドまたは既存のローカルコマンドでのみ使用できます。';

  @override
  String get validation_legacy_only_requires_legacy =>
      'レガシー専用コマンドにはレガシーモードが有効である必要があります。';

  @override
  String get validation_modal_not_legacy => 'モーダル応答はレガシーコマンドモードではサポートされていません。';

  @override
  String get validation_option_description_required => 'すべてのオプションに説明が必要です。';

  @override
  String get validation_option_group_only_subcommands =>
      'サブコマンドグループにはサブコマンドオプションのみを含められます。';

  @override
  String get validation_option_group_top_level_only =>
      'サブコマンドグループはトップレベルでのみ許可されます。';

  @override
  String get validation_option_hierarchy_no_choices =>
      'サブコマンドとサブコマンドグループは選択肢を定義できません。';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'サブコマンドとサブコマンドグループは最小/最大値を定義できません。';

  @override
  String get validation_option_hierarchy_not_required =>
      'サブコマンドとサブコマンドグループを必須にすることはできません。';

  @override
  String get validation_option_leaf_no_nested =>
      '通常のオプションにはネストされたオプションを含められません。';

  @override
  String get validation_option_max_entries => '各オプションレベルは最大25エントリまでサポートします。';

  @override
  String validation_option_name_duplicate(String name) {
    return '同じレベルに重複したオプション名 \"$name\" があります。';
  }

  @override
  String get validation_option_name_required => 'すべてのオプションに名前が必要です。';

  @override
  String get validation_option_no_mix_top_level =>
      'トップレベルオプションでサブコマンド/グループと通常オプションを混在させることはできません。';

  @override
  String get validation_option_subcommand_depth =>
      'サブコマンドのネスト深度がDiscordの制限を超えています。';

  @override
  String get validation_option_subcommand_no_nested =>
      'サブコマンドにはネストされたサブコマンドやサブコマンドグループを含められません。';

  @override
  String get variable_autocomplete_numeric_title => '動的数値候補';

  @override
  String get variable_autocomplete_title => '利用可能な変数 — タップして挿入';

  @override
  String get variable_category_author => '作成者';

  @override
  String get variable_category_bot => 'ボット';

  @override
  String get variable_category_channel => 'チャンネル';

  @override
  String get variable_category_context => 'コンテキスト';

  @override
  String get variable_category_functions => '関数';

  @override
  String get variable_category_guild => 'サーバー';

  @override
  String get variable_category_interaction => 'インタラクション';

  @override
  String get variable_category_member => 'メンバー';

  @override
  String get variable_category_message => 'メッセージ';

  @override
  String get variable_category_other => 'その他';

  @override
  String get variable_category_temp => '一時';

  @override
  String get variable_category_user => 'ユーザー';

  @override
  String get webhooks_actions => 'アクション';

  @override
  String get webhooks_add_action => 'Webhookを追加';

  @override
  String get webhooks_add_title => '受信Webhookを追加';

  @override
  String get webhooks_copied => '完全なWebhook URLがコピーされました。';

  @override
  String get webhooks_copy_path => 'パスをコピー';

  @override
  String get webhooks_copy_secret => 'シークレットをコピー';

  @override
  String get webhooks_copy_url => 'URLをコピー';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhook: $count$limit';
  }

  @override
  String webhooks_delete_confirm(String label) {
    return '\"$label\" を削除しますか？元に戻せません。';
  }

  @override
  String get webhooks_delete_confirm_no_label => '元に戻せません。';

  @override
  String get webhooks_delete_title => '受信Webhookを削除しますか？';

  @override
  String get webhooks_edit_title => '受信Webhookを編集';

  @override
  String get webhooks_empty => 'まだ受信Webhookがありません。';

  @override
  String get webhooks_generate => '生成';

  @override
  String get webhooks_invalid_runner_url => 'ランナーURLが無効です。';

  @override
  String webhooks_limit_reached(int limit) {
    return '受信Webhookの上限に達しました ($limit)。';
  }

  @override
  String get webhooks_missing_data => 'Webhookのパスまたはシークレットが不足しています。';

  @override
  String get webhooks_no_workflows =>
      '受信Webhookを追加する前に少なくとも1つのワークフローを作成してください。';

  @override
  String get webhooks_page_title => '受信Webhook';

  @override
  String get webhooks_path_copied => 'パスがコピーされました。';

  @override
  String get webhooks_path_exists => 'このパスは既に存在します。別のものを選択してください。';

  @override
  String get webhooks_path_hint => 'orders/new';

  @override
  String get webhooks_path_label => 'パス';

  @override
  String get webhooks_runner_url_required =>
      '完全なWebhook URLをコピーするには、最初にランナーURLを設定してください。';

  @override
  String webhooks_save_failed(String error) {
    return '受信Webhookの保存に失敗: $error';
  }

  @override
  String get webhooks_secret_copied => 'シークレットがコピーされました。';

  @override
  String get webhooks_secret_label => 'Webhookシークレット';

  @override
  String get webhooks_target_label => 'ワークフローターゲット';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'ワークフロー: $workflow';
  }

  @override
  String get wizard_advanced_trigger => '高度なトリガー設定';

  @override
  String get wizard_apply_quick_start => 'クイックスタートを下書きに適用';

  @override
  String get wizard_bdfd_mode_enabled => 'BDFDスクリプトモード有効';

  @override
  String get wizard_code_advanced => 'コード / 詳細';

  @override
  String get wizard_command_body => 'コマンド本文';

  @override
  String get wizard_create_command => 'コマンドを作成';

  @override
  String get wizard_dart_mode_enabled => 'Dartスクリプトモード有効';

  @override
  String get wizard_edit_reply => '返信詳細を編集';

  @override
  String get wizard_legacy_options_subtitle => 'レガシーコマンドオプションとローカルのみの動作';

  @override
  String get wizard_quick_start_applied => 'クイックスタートがコマンド下書きに適用されました。';

  @override
  String get wizard_quick_start_subtitle =>
      'レガシーシンプルビルダーを出発点として使用し、共有下書きに適用します。';

  @override
  String get wizard_quick_starts => 'クイックスタート';

  @override
  String get wizard_reply_summary => '返信概要';

  @override
  String get wizard_save_command => 'コマンドを保存';

  @override
  String get wizard_step_actions => 'アクション';

  @override
  String get wizard_step_infos => '情報';

  @override
  String get wizard_step_reply => '返信';

  @override
  String get wizard_step_review => '確認';

  @override
  String get wizard_step_trigger_inputs => 'トリガーと入力';

  @override
  String get wizard_visual_mode_enabled => 'ビジュアルワークフローモード有効';

  @override
  String get workflow_argument_hint => 'ワークフロー引数 (\$arg でアクセス可能)';

  @override
  String get workflow_arguments_section => 'ワークフロー引数';

  @override
  String get workflow_auto_defer => '自動遅延';

  @override
  String get workflow_auto_defer_actions => 'アクションがある場合自動遅延';

  @override
  String get workflow_bdfd_editor_desc =>
      'このワークフロー応答の完全なBDFDコードを記述します。診断がライブ表示されます。';

  @override
  String get workflow_bdfd_editor_title => 'BDFDスクリプトエディタ';

  @override
  String get workflow_condition_off => '条件オフ';

  @override
  String get workflow_condition_off_upper => '条件 OFF';

  @override
  String get workflow_condition_on => '条件オン';

  @override
  String get workflow_condition_on_upper => '条件 ON';

  @override
  String get workflow_dart_editor_desc =>
      'このワークフロー応答の完全なDartコードを記述します。診断がライブ表示されます。';

  @override
  String get workflow_dart_editor_title => 'Dartスクリプトエディタ';

  @override
  String workflow_edit_call_args(int count) {
    return '呼び出し引数を編集 ($count)';
  }

  @override
  String get workflow_entry_point => 'エントリポイント';

  @override
  String get workflow_entry_point_helper => '空の場合はワークフローのエントリポイントがデフォルト';

  @override
  String get workflow_entry_point_optional => 'エントリポイント (オプション)';

  @override
  String get workflow_hint_name => '例: handle_form_submit';

  @override
  String get workflow_manual => '手動';

  @override
  String get workflow_mode_bdfd => 'BDFDスクリプト';

  @override
  String get workflow_mode_bdfd_note =>
      'ワークフロー全体を単一のBDFDスクリプトとして記述します。スクリプトはコンパイルされて検証されます。';

  @override
  String get workflow_mode_dart => 'Dartダイレクト';

  @override
  String get workflow_mode_dart_note =>
      'ワークフローをDartで記述します。編集中に診断が更新され、エラーを早期に検出します。';

  @override
  String get workflow_mode_desc => 'ビジュアルアクションビルダーかフルBDFDスクリプトエディタを選択します。';

  @override
  String get workflow_mode_title => 'ワークフローモード';

  @override
  String get workflow_mode_visual => 'ビジュアル';

  @override
  String get workflow_mode_visual_note =>
      'カードエディタで個別のアクションを追加してビジュアルにワークフローを構築します。';

  @override
  String get workflow_no_auto_defer => '自動遅延なし';

  @override
  String get workflow_no_workflow_note =>
      '注意: ワークフローが選択されていない場合、このモーダルを送信しても何も起こりません。';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return '送信時にワークフロー \"$name\" が実行されます (エントリ: $entry, 引数: $args)。';
  }

  @override
  String get workflow_root_json_error => 'ルートはJSONオブジェクトである必要があります';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'ワークフロー \"$name\" が保存されました ($count アクション)。';
  }

  @override
  String get workflow_set_call_args => '呼び出し引数を設定';

  @override
  String get workflow_visibility_ephemeral => 'エフェメラル';

  @override
  String get workflow_visibility_public => '公開';

  @override
  String get workflows_add_arg => '引数を追加';

  @override
  String get workflows_arg_default => 'デフォルト値';

  @override
  String get workflows_arg_hint =>
      '引数は ((arg.name)) および ((workflow.arg.name)) としてランタイム変数になります。';

  @override
  String get workflows_arg_name => '名前';

  @override
  String get workflows_arg_required_short => '必須';

  @override
  String get workflows_arguments => '引数';

  @override
  String get workflows_continue => '続ける';

  @override
  String get workflows_copy_done_base64 => 'ワークフローがBase64としてコピーされました。';

  @override
  String get workflows_copy_done_json => 'ワークフローがJSONとしてコピーされました。';

  @override
  String get workflows_copy_none => 'コピーするワークフローがありません。';

  @override
  String get workflows_create => 'ワークフローを作成';

  @override
  String workflows_delete_confirm(String name) {
    return '\"$name\" を削除してもよろしいですか？この操作は元に戻せません。';
  }

  @override
  String get workflows_delete_title => 'ワークフローを削除';

  @override
  String get workflows_docs_tooltip => 'ドキュメントセンターを開く';

  @override
  String get workflows_edit => 'ワークフローを編集';

  @override
  String get workflows_empty => 'まだワークフローがありません';

  @override
  String get workflows_entry_point => 'デフォルトエントリポイント';

  @override
  String get workflows_entry_point_hint => '呼び出し元が上書きしない場合に使用';

  @override
  String get workflows_event_available_vars => '利用可能な変数';

  @override
  String get workflows_event_category => 'イベントカテゴリ';

  @override
  String get workflows_event_category_channels => 'チャンネル';

  @override
  String get workflows_event_category_invites => '招待';

  @override
  String get workflows_event_category_members => 'メンバー';

  @override
  String get workflows_event_category_messages => 'メッセージ';

  @override
  String get workflows_event_channel_update => 'チャンネル更新';

  @override
  String get workflows_event_channel_update_desc => 'チャンネルが更新されるたびにトリガーされます。';

  @override
  String get workflows_event_hint => 'このワークフローをトリガーするDiscordイベントを選択してください。';

  @override
  String get workflows_event_invite_create => '招待作成';

  @override
  String get workflows_event_invite_create_desc => '招待が作成されるたびにトリガーされます。';

  @override
  String get workflows_event_member_join => 'メンバー参加';

  @override
  String get workflows_event_member_join_desc => 'メンバーがサーバーに参加するたびにトリガーされます。';

  @override
  String get workflows_event_member_remove => 'メンバー退出';

  @override
  String get workflows_event_member_remove_desc =>
      'メンバーが退出するかサーバーから削除されるたびにトリガーされます。';

  @override
  String get workflows_event_message_create => 'メッセージ作成';

  @override
  String get workflows_event_message_create_desc =>
      '新しいメッセージが作成されるたびにトリガーされます。';

  @override
  String get workflows_event_message_delete => 'メッセージ削除';

  @override
  String get workflows_event_message_delete_desc => 'メッセージが削除されるたびにトリガーされます。';

  @override
  String get workflows_event_message_update => 'メッセージ更新';

  @override
  String get workflows_event_message_update_desc =>
      '既存のメッセージが編集されるたびにトリガーされます。';

  @override
  String workflows_event_preview(String event) {
    return '待機: $event';
  }

  @override
  String get workflows_event_section => 'イベントワークフロー';

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count アクション • 待機: $event';
  }

  @override
  String get workflows_export_base64 => 'Base64としてコピー';

  @override
  String get workflows_export_base64_desc => 'コンパクトな共有に便利です。';

  @override
  String get workflows_export_json => 'JSONとしてコピー';

  @override
  String get workflows_export_json_desc => '読みやすく編集しやすい。';

  @override
  String get workflows_export_tooltip => 'ワークフローをコピー';

  @override
  String get workflows_folder_hint => 'オプションのフォルダ名';

  @override
  String get workflows_folder_label => 'フォルダ';

  @override
  String get workflows_general_section => '一般ワークフロー';

  @override
  String get workflows_import_action => 'インポート';

  @override
  String get workflows_import_desc =>
      'Bot CreatorからエクスポートされたJSONペイロードまたはBase64(JSON)を貼り付けます。';

  @override
  String workflows_import_done(int count) {
    return '$count ワークフローがインポートされました。';
  }

  @override
  String get workflows_import_empty => 'インポートするデータがありません。';

  @override
  String get workflows_import_input_hint => 'JSONまたはBase64をここに貼り付け...';

  @override
  String get workflows_import_invalid_format =>
      '無効な形式です。JSONまたはBase64(JSON)を使用してください。';

  @override
  String get workflows_import_no_valid => '有効なワークフローが見つかりません。';

  @override
  String get workflows_import_overwrite => '名前が既に存在する場合は置き換え';

  @override
  String get workflows_import_title => 'ワークフローをインポート';

  @override
  String get workflows_import_tooltip => 'ワークフローをインポート';

  @override
  String get workflows_listen_for => '待機対象';

  @override
  String get workflows_move_to_folder => 'フォルダに移動';

  @override
  String get workflows_name => 'ワークフロー名';

  @override
  String get workflows_new_folder_hint => '新しいフォルダ名';

  @override
  String get workflows_no_match => '現在のフィルターに一致するワークフローはありません。';

  @override
  String get workflows_no_matches => '現在のフィルターに一致するワークフローはありません。';

  @override
  String get workflows_remove_from_folder => 'フォルダから削除';

  @override
  String get workflows_search_hint => 'ワークフローを検索...';

  @override
  String workflows_subtitle(int count, String entry, String args) {
    return '$count アクション • エントリ: $entry • 引数: $args';
  }

  @override
  String get workflows_tab => 'ワークフロー';

  @override
  String get workflows_tab_short => 'フロー';

  @override
  String get workflows_title => 'ワークフロー';

  @override
  String get workflows_type_badge_event => 'イベント';

  @override
  String get workflows_type_badge_general => '一般';

  @override
  String get workflows_type_event => 'イベントワークフロー';

  @override
  String get workflows_type_event_desc => 'Discordがイベントを発行すると自動的に反応します。';

  @override
  String get workflows_type_general => '一般ワークフロー';

  @override
  String get workflows_type_general_desc =>
      'コマンド、ボタン、モーダル、他のワークフローから呼び出される再利用可能なロジック。';

  @override
  String get workflows_type_title => 'ワークフロータイプ';
}
