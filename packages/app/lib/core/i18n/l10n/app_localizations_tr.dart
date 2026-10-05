// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get docs_search => 'Dokümantasyonda ara';

  @override
  String get docs_reset_filters => 'Filtreleri sıfırla';

  @override
  String docs_result_count(int count) {
    return '$count makale';
  }

  @override
  String get docs_category => 'Kategori';

  @override
  String get docs_mode => 'Mod';

  @override
  String get docs_no_results => 'Eşleşen makale yok';

  @override
  String get docs_cached_offline => 'Önbellekteki sürüm: ağ kullanılamıyor';

  @override
  String get docs_contents => 'İçindekiler';

  @override
  String get variables_migration_title => 'BDFD değişken geçişi';

  @override
  String get variables_migration_confirmation =>
      'Kullanıcı değerlerini tüm sunucularda ortak tutun. Eski BDFD betiklerini arşivleyip uyarlayın, ardından resmi sunucuya özel kullanıcı işlevlerini etkinleştirin. Değerler ve sona erme süreleri taşınmaz.';

  @override
  String get variables_migration_stop_bot =>
      'Değişkenleri taşımadan önce botu durdur.';

  @override
  String variables_migration_result(int commands, int workflows, int calls) {
    return '$commands komut, $workflows iş akışı grubu, $calls çağrı uyarlandı';
  }

  @override
  String get app_update_dialog_title => 'Yeni sürüm mevcut';

  @override
  String app_update_dialog_message(String version, String installed) {
    return 'Mağazada $version sürümü yayında (sizde $installed). En son düzeltmeler için güncelleyin.';
  }

  @override
  String get app_update_later => 'Daha sonra';

  @override
  String get app_update_update_now => 'Güncelle';

  @override
  String get app_update_store_open_failed => 'Mağaza sayfası açılamadı.';

  @override
  String get app_update_download_started =>
      'Arka planda indiriliyor — uygulamayı kullanmaya devam edebilirsiniz.';

  @override
  String get bot_token_import_btn => 'Jetonu hesabımdan içe aktar';

  @override
  String get bot_token_import_missing => 'Bu bot hesabınızda bulunmuyor.';

  @override
  String get bot_token_import_network =>
      'Sunucuya ulaşılamadı: bağlantınızı kontrol edip yeniden deneyin.';

  @override
  String get bot_token_import_no_account =>
      'Bu cihazda bağlı bir hesap yok: jetonu içe aktarmak için oturum açın.';

  @override
  String get bot_token_import_not_stored =>
      'Hesabınızda kayıtlı jeton yok: bir kez burada girin.';

  @override
  String get bot_token_import_server_cannot_read =>
      'Sunucu kayıtlı jetonu okuyamıyor.';

  @override
  String get bot_token_import_server_unsupported =>
      'Bu sunucu henüz jeton içe aktarmayı sunmuyor — güncelleyin veya yeniden dağıtın.';

  @override
  String get bot_token_import_success =>
      'Jeton hesabınızdan içe aktarıldı: bağlantı yeniden kuruldu.';

  @override
  String get container_invite_server_unsupported =>
      'Bu sunucu henüz bot davetini sunmuyor — güncelleyin veya yeniden dağıtın.';

  @override
  String get container_invite_missing =>
      'Bu kapsayıcı sunucuda artık yok — kapsayıcı listesini yenileyin.';

  @override
  String get settings_app_update_title => 'Güncellemeler';

  @override
  String settings_app_update_installed_version(String version, String build) {
    return '$version (derleme $build)';
  }

  @override
  String settings_app_version_value(String version) {
    return 'Uygulama: $version';
  }

  @override
  String settings_runner_version_value(String version) {
    return 'Runner: $version';
  }

  @override
  String get settings_app_update_check_button => 'Güncellemeleri denetle';

  @override
  String get settings_app_update_checking => 'Denetleniyor…';

  @override
  String get settings_app_update_up_to_date => 'En son sürümü kullanıyorsunuz.';

  @override
  String settings_app_update_available(String version) {
    return 'Mağazada $version sürümü mevcut.';
  }

  @override
  String get settings_app_update_unavailable =>
      'Güncellemeler şu anda denetlenemiyor.';

  @override
  String get settings_app_update_unsupported =>
      'Güncellemeler yalnızca Android veya iOS uygulamasında denetlenebilir.';

  @override
  String get settings_app_update_open_store => 'Mağaza sayfasını aç';

  @override
  String get action_add_else_if => 'ELSE IF Ekle';

  @override
  String get action_add_header => 'Başlık ekle';

  @override
  String get action_add_new_item => 'Yeni öğe ekle';

  @override
  String get action_advanced_settings => 'Gelişmiş ayarlar';

  @override
  String action_and_more(int count) {
    return '… ve $count tane daha';
  }

  @override
  String get action_bulk_import_hint =>
      'Toplu içe aktarma (Anahtar: Değer şeklinde başlıkları yapıştırın)';

  @override
  String get action_cannot_format_json => 'Formatlanamıyor: Geçersiz JSON';

  @override
  String get action_category_channels => 'Kanallar';

  @override
  String get action_category_components => 'Bileşenler';

  @override
  String get action_category_guild_members => 'Sunucu ve Üyeler';

  @override
  String get action_category_http_variables => 'HTTP ve Değişkenler';

  @override
  String get action_category_interactions => 'Etkileşimler';

  @override
  String get action_category_logic_flow => 'Mantık ve Akış';

  @override
  String get action_category_messages => 'Mesajlar';

  @override
  String get action_category_moderation => 'Moderasyon';

  @override
  String get action_category_music => 'Müzik';

  @override
  String get action_category_reactions => 'Tepkiler';

  @override
  String get action_category_webhooks => 'Webhooks';

  @override
  String get action_category_workflows => 'İş Akışları';

  @override
  String action_choose_param(String name) {
    return '$name Seç';
  }

  @override
  String get action_clear_all => 'Tümünü temizle';

  @override
  String get action_condition_value => 'Koşul Değeri';

  @override
  String get action_condition_variable => 'Koşul Değişkeni';

  @override
  String get action_description_addReaction => 'Bir mesaja emoji tepkisi ekle';

  @override
  String get action_description_addRole => 'Bir üyeye rol ata';

  @override
  String get action_description_addThreadMember =>
      'İleti dizisine bir üye ekle';

  @override
  String get action_description_appendArrayElement =>
      'Genel veya kapsamlı bir JSON dizisine yeni bir öğe ekle';

  @override
  String get action_description_attachImage =>
      'Mesaj yanıtına bir resim dosyası ekle (URL, veri URL\'si veya base64)';

  @override
  String get action_description_banUser =>
      'Permanently ban a user from the guild';

  @override
  String get action_description_calculate =>
      'Matematiksel işlemleri gerçekleştir ve sonucu kaydet';

  @override
  String get action_description_canvasCreateBlock =>
      'Boş bir resim tuvali oluştur';

  @override
  String get action_description_canvasDrawCircleBlock =>
      'Resim tuvali üzerine bir daire çiz';

  @override
  String get action_description_canvasDrawLineBlock =>
      'Tuval üzerine bir çizgi çiz';

  @override
  String get action_description_canvasDrawRectBlock =>
      'Resim tuvali üzerine bir dikdörtgen çiz';

  @override
  String get action_description_canvasDrawTextBlock =>
      'Stil seçenekleriyle resim tuvaline metin çiz';

  @override
  String get action_description_canvasLoadImageBlock =>
      'Bir URL\'den veya kaynaktan tuvale bir resim yükle';

  @override
  String get action_description_clearAllReactions =>
      'Clear all reactions from a message';

  @override
  String get action_description_cooldown =>
      'Apply a cooldown to the user or server';

  @override
  String get action_description_createAutoModRule =>
      'Sunucu otomatik denetleme kuralı oluştur';

  @override
  String get action_description_createChannel => 'Yeni bir kanal oluştur';

  @override
  String get action_description_createEmoji =>
      'Resim verilerinden bir sunucu emojisi oluştur';

  @override
  String get action_description_createInvite =>
      'Kanal için yeni bir davet bağlantısı oluştur';

  @override
  String get action_description_createPoll =>
      'Kanalda bir anket mesajı oluştur';

  @override
  String get action_description_createThread =>
      'Desteklenen bir metin kanalında ileti dizisi oluştur';

  @override
  String get action_description_debugProfile =>
      'Yürütme profilini ve teşhis bilgilerini oluştur';

  @override
  String get action_description_deferInteraction =>
      'Discord zaman aşımını önlemek için etkileşim yanıtını ertele';

  @override
  String get action_description_deleteAutoModRule =>
      'Otomatik denetleme kuralını sil';

  @override
  String get action_description_deleteChannelPermission =>
      'Kanal izin geçersiz kılmasını sil';

  @override
  String get action_description_deleteEmoji => 'Sunucu emojisini sil';

  @override
  String get action_description_deleteInvite =>
      'Koda göre mevcut bir daveti sil';

  @override
  String get action_description_deleteMessages =>
      'Bir veya daha fazla mesajı sil';

  @override
  String get action_description_deleteTrigger =>
      'Bu komutu tetikleyen mesajı sil';

  @override
  String get action_description_deleteWebhook => 'Webhook\'u sil';

  @override
  String get action_description_disconnectFromVoice =>
      'Bir üyenin ses bağlantısını kes';

  @override
  String get action_description_editChannelPermissions =>
      'Kanal izin geçersiz kılmalarını oluştur veya güncelle';

  @override
  String get action_description_editComponentV2 => 'Mevcut bileşenleri düzenle';

  @override
  String get action_description_editInteractionMessage =>
      'Ertelenmiş veya orijinal etkileşim yanıtını düzenle';

  @override
  String get action_description_editMessage => 'Mevcut bir mesajı düzenle';

  @override
  String get action_description_editWebhook => 'Mevcut bir Webhook\'u düzenle';

  @override
  String get action_description_endPoll =>
      'Etkin bir anket mesajını hemen sonlandır';

  @override
  String get action_description_forLoop =>
      'Belirli bir sayı aralığında döngü oluştur (for döngüsü)';

  @override
  String get action_description_getGlobalVariable =>
      'Genel bir değişkeni oku ve çalışma zamanı değişkenlerine aktar';

  @override
  String get action_description_getGuildOnboarding =>
      'Mevcut sunucu ilk katılım yapılandırmasını getir';

  @override
  String get action_description_getInvite =>
      'Koda göre davet bilgilerini getir';

  @override
  String get action_description_getMember => 'Üye bilgilerini al';

  @override
  String get action_description_getMessage =>
      'Bir mesajı getir ve alanlarını açığa çıkar';

  @override
  String get action_description_getMusicInfo =>
      'Şu anda çalan şarkı hakkında bilgi al';

  @override
  String get action_description_getScopedVariable =>
      'Kapsamlı bir değişkeni oku ve çalışma zamanı değişkenlerine aktar';

  @override
  String get action_description_getWebhook =>
      'Kimliğe göre Webhook bilgilerini al';

  @override
  String get action_description_httpRequest =>
      'Dinamik URL, yöntem, başlıklar ve gövde ile HTTP isteği gönder';

  @override
  String get action_description_ifBlock =>
      'Koşullu dallanma: bir koşula göre farklı eylemler çalıştır';

  @override
  String get action_description_jumpToAction =>
      'Anahtar, ID veya konuma göre belirli bir eyleme atla';

  @override
  String get action_description_joinVoice => 'Bir ses kanalına bağlan';

  @override
  String get action_description_jsonForEachLoop =>
      'Bir JSON dizisinin veya nesnesinin her öğesini döngüye al (forEach)';

  @override
  String get action_description_kickUser => 'Remove a member from the guild';

  @override
  String get action_description_leaveGuild =>
      'Botun sunucudan ayrılmasını sağla';

  @override
  String get action_description_leaveVoice =>
      'Ses kanalından ayrıl ve oynatıcıyı kapat';

  @override
  String get action_description_listAutoModRules =>
      'Sunucudaki tüm otomatik denetleme kurallarını listele';

  @override
  String get action_description_listMembers =>
      'Seçeneklerle bir sunucudaki üyeleri listele';

  @override
  String get action_description_listScopedVariableIndex =>
      'Dizinlenmiş kapsamlı değerleri, uzaklık ve sınırla değere göre sıralanmış olarak listele';

  @override
  String get action_description_listWebhooks =>
      'Bir kanal veya sunucudaki tüm Webhook\'ları listele';

  @override
  String get action_description_listenAndExecute =>
      'Bir butona tıklandığında, seçim menüsü kullanıldığında veya bir modal gönderildiğinde çalışacak bir iş akışı kaydet';

  @override
  String get action_description_listenForButtonClick =>
      'Bir butona tıklandığında çalışacak bir iş akışı kaydet';

  @override
  String get action_description_listenForModalSubmit =>
      'Bir modal gönderildiğinde çalışacak bir iş akışı kaydet';

  @override
  String get action_description_listenForSelectMenu =>
      'Bir seçim menüsü kullanıldığında çalışacak bir iş akışı kaydet';

  @override
  String get action_description_log =>
      'Eylem günlüklerine teşhis mesajı yazdır veya depola';

  @override
  String get action_description_moveToVoiceChannel =>
      'Bir üyeyi belirli bir ses kanalına taşı';

  @override
  String get action_description_muteUser => 'Temporarily timeout a member';

  @override
  String get action_description_pauseMusic => 'Çalan şarkıyı duraklat';

  @override
  String get action_description_pinMessage => 'Kanalda bir mesajı sabitle';

  @override
  String get action_description_playMusic =>
      'Arama sorgusu veya URL ile bir şarkı çal';

  @override
  String get action_description_queryArray =>
      'Herhangi bir çalışma zamanı JSON dizisini filtrele, sırala ve sayfala';

  @override
  String get action_description_randomChoice =>
      'Pick a random item from a list';

  @override
  String get action_description_registerGuildCommands =>
      'Uygulama komutlarını bir sunucuya kaydet';

  @override
  String get action_description_removeArrayElement =>
      'Dizin ile genel veya kapsamlı bir JSON dizisinden bir öğeyi kaldır';

  @override
  String get action_description_removeChannel => 'Kanalı sil';

  @override
  String get action_description_removeGlobalVariable =>
      'Genel bir değişkeni sil';

  @override
  String get action_description_removeReaction => 'Bir mesajdan tepkiyi kaldır';

  @override
  String get action_description_removeRole => 'Bir üyeden rolü kaldır';

  @override
  String get action_description_removeScopedVariable =>
      'Kapsamlı bir değişkeni sil';

  @override
  String get action_description_removeThreadMember =>
      'İleti dizisinden bir üyeyi kaldır';

  @override
  String get action_description_renameScopedVariable =>
      'Kapsamlı bir değişken anahtarını yeniden adlandır';

  @override
  String get action_description_respondWithAutocomplete =>
      'Discord otomatik tamamlama etkileşimine 25 adede kadar dinamik seçenekle yanıt ver';

  @override
  String get action_description_respondWithComponentV2 =>
      'Komuta butonlar veya seçim menüleri ile yanıt ver';

  @override
  String get action_description_respondWithMessage =>
      'Komuta normal bir mesajla yanıt ver';

  @override
  String get action_description_respondWithModal =>
      'Kullanıcıya bir modal iletişim kutusu göster';

  @override
  String get action_description_resumeMusic =>
      'Duraklatılmış bir şarkıyı sürdür';

  @override
  String get action_description_runBdfdScript =>
      'BDFD betiğini iş akışı eylemleri olarak satır içi derle ve çalıştır';

  @override
  String get action_description_runWorkflow =>
      'Kaydedilmiş bir iş akışını yürüt (giriş noktası ve argümanları destekler)';

  @override
  String get action_description_runtimeImageBlock =>
      'Resim tuvali işleme eylemleri bloğunu çalıştır';

  @override
  String get action_description_runtimeJsonBlock =>
      'JSON işleme eylemleri bloğunu çalıştır';

  @override
  String get action_description_seekMusic =>
      'Çalan şarkıda belirli bir süreye git';

  @override
  String get action_description_sendComponentV2 =>
      'Etkileşimli bileşenler gönder';

  @override
  String get action_description_sendDm => 'Send a direct message to a user';

  @override
  String get action_description_sendMessage => 'Send a message to a channel';

  @override
  String get action_description_sendWebhook =>
      'Webhook aracılığıyla mesaj gönder';

  @override
  String get action_description_serverDeafenMember =>
      'Bir üyeyi sunucuda sağırlaştır veya sağırlaştırmasını kaldır';

  @override
  String get action_description_serverMuteMember =>
      'Bir üyeyi sunucuda sustur veya sesini aç';

  @override
  String get action_description_setGlobalVariable =>
      'Bu bot için genel bir değişken oluştur veya güncelle';

  @override
  String get action_description_setMusicLoop =>
      'Sıra döngüsünü etkinleştir veya devre dışı bırak';

  @override
  String get action_description_setMusicVolume =>
      'Oynatıcı ses seviyesini ayarla (0 - 200)';

  @override
  String get action_description_setNickname => 'Change a member\'s nickname';

  @override
  String get action_description_setScopedVariable =>
      'Kapsamlı bir değişken (sunucu/kullanıcı/kanal/üye/mesaj) oluştur veya güncelle';

  @override
  String get action_description_setTemporaryVariable =>
      'Yerel yürütmede geçici bir değişken oluştur veya güncelle';

  @override
  String get action_description_skipActions =>
      'Belirtilen sayıda sonraki eylemi atla';

  @override
  String get action_description_skipMusic => 'Sıradaki şarkıya geç';

  @override
  String get action_description_slowmode =>
      'Set slowmode duration for a channel';

  @override
  String get action_description_stop => 'Stop the current workflow execution';

  @override
  String get action_description_stopMusic =>
      'Oynatmayı durdur ve sırayı temizle';

  @override
  String get action_description_stopUnless =>
      'Koşul karşılanmazsa iş akışını durdur (koruma/filtre)';

  @override
  String get action_description_unbanUser => 'Bir kullanıcının banını kaldır';

  @override
  String get action_description_unmuteUser => 'Remove timeout from a member';

  @override
  String get action_description_unpinMessage =>
      'Kanalda bir mesajın sabitlemesini kaldır';

  @override
  String get action_description_unregisterGuildCommands =>
      'Uygulama komutlarının sunucu kaydını sil';

  @override
  String get action_description_updateAutoMod =>
      'Otomatik denetleme ayarlarını güncelle';

  @override
  String get action_description_updateChannel => 'Kanal ayarlarını güncelle';

  @override
  String get action_description_updateEmoji =>
      'Sunucu emojisi adını veya rol erişimini güncelle';

  @override
  String get action_description_updateGuild => 'Sunucu ayarlarını güncelle';

  @override
  String get action_description_updateGuildOnboarding =>
      'Sunucu ilk katılım yapılandırmasını güncelle';

  @override
  String get action_description_updateSelfUser =>
      'Mevcut bot kullanıcı profilini (kullanıcı adı/avatar) güncelle';

  @override
  String get action_description_wait =>
      'Pause execution for a specific duration';

  @override
  String get action_dynamic => 'Dinamik';

  @override
  String get action_dynamic_bool_hint => 'true/false veya ((degisken))';

  @override
  String action_dynamic_id_hint(String type) {
    return 'Dinamik $type (((...)) destekler)';
  }

  @override
  String get action_dynamic_multiselect_hint =>
      'Dinamik değer (((...)) destekler)';

  @override
  String get action_dynamic_numeric => 'Dinamik sayısal öneriler';

  @override
  String get action_dynamic_variable => 'Dinamik değişken önerileri';

  @override
  String action_edit_nested(int count) {
    return '$count tanesini düzenle';
  }

  @override
  String action_edit_nested_parens(int count) {
    return 'Düzenle ($count)';
  }

  @override
  String action_edit_param(String name) {
    return '$name Düzenle';
  }

  @override
  String get action_edit_raw_json => 'Ham JSON\'u Düzenle';

  @override
  String action_else_if_label(int index) {
    return 'ELSE IF $index — eylemler';
  }

  @override
  String get action_error_continue => 'Devam Et';

  @override
  String get action_error_stop => 'Durdur';

  @override
  String get action_expression => 'İfade';

  @override
  String get action_format_json => 'JSON Formatla';

  @override
  String get action_hint_color => '#FFFFFF veya rgb(255,255,255)';

  @override
  String get action_hint_condition_value => 'Karşılaştırılacak değer';

  @override
  String get action_hint_condition_var =>
      '((degiskenAdi)) veya bir çalışma zamanı değeri kullanın';

  @override
  String get action_hint_cooldown_error =>
      'Özel hata mesajı (%time% destekler)';

  @override
  String get action_hint_cooldown_time => 'Süre (ör. 10s, 1m)';

  @override
  String get action_hint_duration => 'örn. 5m, 1sa, 30sn';

  @override
  String get action_hint_emoji => 'Emoji (örn. 🪜) veya <:ad:kimlik>';

  @override
  String action_hint_enter_type(String type) {
    return '$type girin';
  }

  @override
  String get action_hint_random_choices =>
      'Seçenekler listesi (; ile ayrılmış)';

  @override
  String get action_hint_random_var => 'Sonucu kaydetmek için değişken adı';

  @override
  String get action_hint_variable_key => 'Değişken anahtarını seçin';

  @override
  String get action_hint_workflow => 'Kayıtlı iş akışı adı';

  @override
  String get action_http_headers_title =>
      'HTTP Başlıkları (Anahtar/Değer çiftleri)';

  @override
  String action_http_paths_parsed(int count) {
    return '$count yol ayrıştırıldı';
  }

  @override
  String get action_http_response_body => 'Yanıt Gövdesi (Ham):';

  @override
  String action_http_status(int status) {
    return 'Durum: $status';
  }

  @override
  String get action_http_test_button =>
      'Test İsteği Gönder ve Rotaları Otomatik Algıla';

  @override
  String get action_http_test_title => 'Test İsteği Sonuçları';

  @override
  String get action_json_editor_hint =>
      'JSON nesne düzenleyici (iç içe geçmiş nesneleri/dizileri destekler)';

  @override
  String get action_key_field => 'Eylem Anahtarı';

  @override
  String get action_key_value_pairs => 'Anahtar / Değer çiftleri';

  @override
  String get action_literal => 'Değişmez (Literal)';

  @override
  String get action_loading_keys => 'Anahtarlar yükleniyor...';

  @override
  String get action_manage_variable_keys => 'Değişken Anahtarlarını Yönet';

  @override
  String get action_name_addReaction => 'Tepki Ekle';

  @override
  String get action_name_addRole => 'Rol Ekle';

  @override
  String get action_name_addThreadMember => 'Konu Üyesi Ekle';

  @override
  String get action_name_appendArrayElement => 'Dizi Öğesi Ekle';

  @override
  String get action_name_attachImage => 'Resim Ekle';

  @override
  String get action_name_banUser => 'Kullanıcıyı Yasakla';

  @override
  String get action_name_calculate => 'Hesapla';

  @override
  String get action_name_canvasCreateBlock => 'Tuval Oluştur';

  @override
  String get action_name_canvasDrawCircleBlock => 'Daire Çiz';

  @override
  String get action_name_canvasDrawLineBlock => 'Çizgi Çiz';

  @override
  String get action_name_canvasDrawRectBlock => 'Dikdörtgen Çiz';

  @override
  String get action_name_canvasDrawTextBlock => 'Metin Çiz';

  @override
  String get action_name_canvasLoadImageBlock => 'Resim Yükle';

  @override
  String get action_name_clearAllReactions => 'Tüm Tepkileri Temizle';

  @override
  String get action_name_cooldown => 'Bekleme Süresi';

  @override
  String get action_name_createAutoModRule => 'AutoMod Kuralı Oluştur';

  @override
  String get action_name_createChannel => 'Kanal Oluştur';

  @override
  String get action_name_createEmoji => 'Emoji Oluştur';

  @override
  String get action_name_createInvite => 'Davet Oluştur';

  @override
  String get action_name_createPoll => 'Anket Oluştur';

  @override
  String get action_name_createThread => 'Konu (Thread) Oluştur';

  @override
  String get action_name_debugProfile => 'Hata Ayıklama Profili';

  @override
  String get action_name_deferInteraction => 'Etkileşimi Ertele';

  @override
  String get action_name_deleteAutoModRule => 'AutoMod Kuralını Sil';

  @override
  String get action_name_deleteChannelPermission => 'Kanal İznini Sil';

  @override
  String get action_name_deleteEmoji => 'Emoji Sil';

  @override
  String get action_name_deleteInvite => 'Daveti Sil';

  @override
  String get action_name_deleteMessages => 'Mesajları Sil';

  @override
  String get action_name_deleteTrigger => 'Tetikleyiciyi Sil';

  @override
  String get action_name_deleteWebhook => 'Webhook Sil';

  @override
  String get action_name_disconnectFromVoice => 'Sesten Bağlantıyı Kes';

  @override
  String get action_name_editChannelPermissions => 'Kanal İzinlerini Düzenle';

  @override
  String get action_name_editComponentV2 => 'Bileşen V2 Düzenle';

  @override
  String get action_name_editInteractionMessage => 'Etkileşim Mesajını Düzenle';

  @override
  String get action_name_editMessage => 'Mesajı Düzenle';

  @override
  String get action_name_editWebhook => 'Webhook Düzenle';

  @override
  String get action_name_endPoll => 'Anketi Bitir';

  @override
  String get action_name_forLoop => 'For Döngüsü';

  @override
  String get action_name_getGlobalVariable => 'Genel Değişkeni Al';

  @override
  String get action_name_getGuildOnboarding => 'Sunucu Katılımını Getir';

  @override
  String get action_name_getInvite => 'Daveti Al';

  @override
  String get action_name_getMember => 'Üyeyi Getir';

  @override
  String get action_name_getMessage => 'Mesajı Al';

  @override
  String get action_name_getMusicInfo => 'Müzik Bilgisini Al';

  @override
  String get action_name_getScopedVariable => 'Kapsamlı Değişkeni Al';

  @override
  String get action_name_getWebhook => 'Webhook Getir';

  @override
  String get action_name_httpRequest => 'HTTP İsteği';

  @override
  String get action_name_ifBlock => 'IF / ELSE Bloğu';

  @override
  String get action_name_jumpToAction => 'Eyleme Atla';

  @override
  String get action_name_joinVoice => 'Ses Kanalına Katıl';

  @override
  String get action_name_jsonForEachLoop => 'JSON For Each Döngüsü';

  @override
  String get action_name_kickUser => 'Kullanıcıyı At';

  @override
  String get action_name_leaveGuild => 'Sunucudan Ayrıl';

  @override
  String get action_name_leaveVoice => 'Ses Kanalından Ayrıl';

  @override
  String get action_name_listAutoModRules => 'AutoMod Kurallarını Listele';

  @override
  String get action_name_listMembers => 'Üyeleri Listele';

  @override
  String get action_name_listScopedVariableIndex =>
      'Kapsamlı Değişken İndeksini Listele';

  @override
  String get action_name_listWebhooks => 'Webhook\'ları Listele';

  @override
  String get action_name_listenAndExecute => 'Dinle ve Yürüt';

  @override
  String get action_name_listenForButtonClick => 'Düğme Tıklamasını Dinle';

  @override
  String get action_name_listenForModalSubmit => 'Modal Gönderimini Dinle';

  @override
  String get action_name_listenForSelectMenu => 'Seçim Menüsünü Dinle';

  @override
  String get action_name_log => 'Mesajı Günlüğe Kaydet';

  @override
  String get action_name_moveToVoiceChannel => 'Ses Kanalına Taşı';

  @override
  String get action_name_muteUser => 'Kullanıcıyı Sustur';

  @override
  String get action_name_pauseMusic => 'Müziği Duraklat';

  @override
  String get action_name_pinMessage => 'Mesajı Sabitle';

  @override
  String get action_name_playMusic => 'Müzik Çal';

  @override
  String get action_name_queryArray => 'Sorgu Dizisi';

  @override
  String get action_name_randomChoice => 'Rastgele Seçim';

  @override
  String get action_name_registerGuildCommands => 'Sunucu Komutlarını Kaydet';

  @override
  String get action_name_removeArrayElement => 'Dizi Öğesini Kaldır';

  @override
  String get action_name_removeChannel => 'Kanalı Kaldır';

  @override
  String get action_name_removeGlobalVariable => 'Genel Değişkeni Kaldır';

  @override
  String get action_name_removeReaction => 'Tepkiyi Kaldır';

  @override
  String get action_name_removeRole => 'Rolü Kaldır';

  @override
  String get action_name_removeScopedVariable => 'Kapsamlı Değişkeni Kaldır';

  @override
  String get action_name_removeThreadMember => 'Konu Üyesini Kaldır';

  @override
  String get action_name_renameScopedVariable =>
      'Kapsamlı Değişkeni Yeniden Adlandır';

  @override
  String get action_name_respondWithAutocomplete =>
      'Otomatik Tamamlama ile Yanıtla';

  @override
  String get action_name_respondWithComponentV2 => 'Bileşen V2 ile Yanıtla';

  @override
  String get action_name_respondWithMessage => 'Mesajla Yanıtla';

  @override
  String get action_name_respondWithModal => 'Modal ile Yanıtla';

  @override
  String get action_name_resumeMusic => 'Müziği Sürdür';

  @override
  String get action_name_runBdfdScript => 'BDFD Betiği Çalıştır';

  @override
  String get action_name_runWorkflow => 'İş Akışını Çalıştır';

  @override
  String get action_name_runtimeImageBlock => 'Görüntü İşlemlerini Çalıştır';

  @override
  String get action_name_runtimeJsonBlock => 'JSON İşlemlerini Çalıştır';

  @override
  String get action_name_seekMusic => 'Müzik Konumuna Git';

  @override
  String get action_name_sendComponentV2 => 'Bileşen V2 Gönder';

  @override
  String get action_name_sendDm => 'DM Gönder';

  @override
  String get action_name_sendMessage => 'Mesaj Gönder';

  @override
  String get action_name_sendWebhook => 'Webhook Gönder';

  @override
  String get action_name_serverDeafenMember => 'Sunucuda Üyeyi Sağırlaştır';

  @override
  String get action_name_serverMuteMember => 'Sunucuda Üyeyi Sustur';

  @override
  String get action_name_setGlobalVariable => 'Genel Değişken Ata';

  @override
  String get action_name_setMusicLoop => 'Müzik Döngüsünü Ayarla';

  @override
  String get action_name_setMusicVolume => 'Müzik Sesini Ayarla';

  @override
  String get action_name_setNickname => 'Takma Ad Belirle';

  @override
  String get action_name_setScopedVariable => 'Kapsamlı Değişken Ata';

  @override
  String get action_name_setTemporaryVariable => 'Geçici Değişken Ata';

  @override
  String get action_name_skipActions => 'Eylemleri Atla';

  @override
  String get action_name_skipMusic => 'Müziği Geç';

  @override
  String get action_name_slowmode => 'Yavaş Mod';

  @override
  String get action_name_stop => 'Durdur';

  @override
  String get action_name_stopMusic => 'Müziği Durdur';

  @override
  String get action_name_stopUnless => 'Koşul Sağlanmadıkça Durdur';

  @override
  String get action_name_unbanUser => 'Kullanıcı Yasağını Kaldır';

  @override
  String get action_name_unmuteUser => 'Kullanıcı Susturmasını Kaldır';

  @override
  String get action_name_unpinMessage => 'Mesaj Sabitlemesini Kaldır';

  @override
  String get action_name_unregisterGuildCommands =>
      'Sunucu Komutlarının Kaydını Sil';

  @override
  String get action_name_updateAutoMod => 'AutoMod\'u Güncelle';

  @override
  String get action_name_updateChannel => 'Kanalı Güncelle';

  @override
  String get action_name_updateEmoji => 'Emoji Güncelle';

  @override
  String get action_name_updateGuild => 'Sunucuyu Güncelle';

  @override
  String get action_name_updateGuildOnboarding => 'Sunucu Katılımını Güncelle';

  @override
  String get action_name_updateSelfUser => 'Kendini Güncelle (Bot Profili)';

  @override
  String get action_name_wait => 'Bekle';

  @override
  String get action_no_actions_yet => 'Bu dalda henüz eylem yok.';

  @override
  String get action_no_args_tap_edit =>
      'Argüman yok - eklemek için düzenleye dokunun';

  @override
  String get action_no_else_if_yet =>
      'Henüz ELSE IF dalı yok. ELSE\'den önce daha fazla koşulu test etmek için bir tane ekleyin.';

  @override
  String get action_no_headers_tap_edit =>
      'Başlık yok - eklemek için düzenleye dokunun';

  @override
  String get action_no_items_tap_edit =>
      'Öğe yok - eklemek için düzenleye dokunun';

  @override
  String get action_no_properties_tap_edit =>
      'Özellik yok - yapılandırmak için düzenleye dokunun';

  @override
  String get action_no_saved_keys =>
      'Kayıtlı anahtar bulunamadı. Anahtarlar ilk erişimde otomatik olarak oluşturulur.';

  @override
  String get action_on_error => 'Hata Durumunda';

  @override
  String get action_options_tooltip => 'Eylem seçenekleri';

  @override
  String get action_or_type_workflow => 'Veya iş akışı adını yazın';

  @override
  String get action_order_tip =>
      'İpucu: eylem sırasını değiştirmek için okları kullanın.';

  @override
  String action_position(int index, int total) {
    return 'Eylem $index/$total';
  }

  @override
  String get action_preview_json => 'Vurgulanmış JSON\'u Önizle';

  @override
  String get action_provide_valid_url => 'Lütfen geçerli bir URL sağlayın.';

  @override
  String get action_refresh_keys => 'Anahtarları yenile';

  @override
  String get action_remove_confirm =>
      'Bu eylem iş akışından kaldırılacak. Devam edilsin mi?';

  @override
  String get action_remove_else_if => 'ELSE IF Kaldır';

  @override
  String get action_remove_menu => 'Eylemi kaldır';

  @override
  String get action_remove_title => 'Eylemi kaldır';

  @override
  String get action_root_must_json => 'Kök bir JSON nesnesi olmalıdır';

  @override
  String get action_select_saved_key => 'Kayıtlı bir anahtarı seçin';

  @override
  String get action_select_stored_key =>
      'Saklanan bir anahtarı seçin (bc_ ön eki isteğe bağlıdır)';

  @override
  String get action_static_badge => '(statik)';

  @override
  String get action_status_disabled => 'Devre Dışı';

  @override
  String get action_status_enabled => 'Etkin';

  @override
  String get action_store_results => 'Sonuçları genel değişkenlerde sakla';

  @override
  String actions_active_route(String label) {
    return 'Aktif rota: $label';
  }

  @override
  String get actions_add_label => 'Eylem Ekle';

  @override
  String get actions_add_new_title => 'Yeni Eylem Ekle';

  @override
  String actions_build_button(int count) {
    return 'Eylemleri Oluştur ($count)';
  }

  @override
  String get actions_empty_subtitle =>
      'Bir eylem ekleyin, ardından ayrıntıları yapılandırmak için açın.';

  @override
  String get actions_empty_title => 'Henüz eylem yok';

  @override
  String get actions_builder_title => 'Eylem Oluşturucu';

  @override
  String get actions_description =>
      'Bu komut için çalışma zamanı eylemleri oluşturun';

  @override
  String get actions_global_variables => 'Genel Değişkenler';

  @override
  String actions_key_label(String key) {
    return 'Anahtar: $key';
  }

  @override
  String actions_missing_field_content(String action, String field) {
    return '\"$action\": \"$field\" gerekli.';
  }

  @override
  String get actions_missing_field_title => 'Eksik Alan';

  @override
  String get actions_no_matches => 'Eşleşme bulunamadı';

  @override
  String actions_save_count(int count) {
    return '$count eylemi kaydet';
  }

  @override
  String get actions_save_tooltip => 'Eylemleri Kaydet';

  @override
  String get actions_save_workflow_title => 'İş Akışı Olarak Kaydet';

  @override
  String get actions_search_hint => 'Eylemlerde ara...';

  @override
  String get actions_search_sequence_hint => 'Dizide ara...';

  @override
  String actions_sequence_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eylem',
      one: '1 eylem',
      zero: 'Eylem yok',
    );
    return '$_temp0';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Adım $index / $total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'BDFD betiği | $lines satır | $diagnostics tanılama';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count eylem yapılandırıldı';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Dart betiği | $lines satır | $diagnostics tanılama';
  }

  @override
  String actions_summary_routes(int count, int routes) {
    return 'Aktif rotada $count eylem | $routes rota';
  }

  @override
  String get actions_title => 'Eylemler';

  @override
  String get actions_workflow_name_label => 'İş akışı adı';

  @override
  String get actions_workflows => 'İş Akışları';

  @override
  String get ads_consent_accept => 'Kabul ediyorum';

  @override
  String get ads_consent_message =>
      'GDPR\'ye uymak için reklam göstermeden önce onayınıza ihtiyacımız var. Reddetseniz bile uygulamayı kullanmaya devam edebilirsiniz.';

  @override
  String get ads_consent_refuse => 'Reddediyorum';

  @override
  String get ads_consent_refused_info =>
      'Reklam onayı reddedildi. Bot normal şekilde başlatılacaktır.';

  @override
  String get ads_consent_title => 'Reklam onayı';

  @override
  String get app_bot_token => 'Bot Jetonu';

  @override
  String get app_create_button => 'Uygulama oluştur';

  @override
  String get app_create_hero_desc =>
      'Doğru sayfaları açmak, jetonunuzu kopyalamak ve botu güvenli bir şekilde içe aktarmak için rehberli kurulum.';

  @override
  String get app_create_hero_title => 'Discord botunuzu bağlayın';

  @override
  String get app_create_new => 'Yeni Uygulama Oluştur';

  @override
  String get app_create_page_title => 'Uygulama oluştur';

  @override
  String get app_enter_token => 'Bot jetonunuzu buraya girin';

  @override
  String get app_external_link_badge => 'Dış bağlantı';

  @override
  String get app_hide_token => 'Jetonu gizle';

  @override
  String get app_how_to_create_token => 'Bot Jetonu nasıl oluşturulur?';

  @override
  String get app_loading_error => 'Yükleme hatası';

  @override
  String get app_no_apps => 'Henüz uygulamanız yok.';

  @override
  String get app_note =>
      'Not: Discord Geliştirici Portalı\'nda yeni bir Uygulama oluşturmanız ve bot jetonunuzu almanız gerekir.';

  @override
  String get app_open_discord_portal => 'Discord Geliştirici Portalı\'nı Aç';

  @override
  String get app_open_discord_portal_desc =>
      'Uygulamanızı oluşturun ve bot bölümünü etkinleştirin.';

  @override
  String get app_open_link_error => 'Bu harici sayfa açılamıyor.';

  @override
  String get app_open_token_tutorial => 'Jeton eğitimini oku';

  @override
  String get app_open_token_tutorial_desc =>
      'Bot jetonunuzu oluşturmak ve kopyalamak için adım adım kılavuz.';

  @override
  String get app_resources_desc =>
      'Bu eylemler, botunuzu buraya kaydetmeden önce ihtiyacınız olan resmi sayfaları açar.';

  @override
  String get app_resources_title => 'Rehberli kurulum';

  @override
  String get app_save => 'Değişiklikleri Kaydet';

  @override
  String get app_save_bot => 'Bot ekle';

  @override
  String get app_show_token => 'Jetonu göster';

  @override
  String get app_sync_manager_connect => 'Discord\'u Bağla';

  @override
  String get app_sync_manager_desc =>
      'Bu bot zaten Bot Creator Manager\'da kayıtlı. Tüm botlarınızı otomatik olarak senkronize etmek için Discord ile bağlanmak ister misiniz?';

  @override
  String get app_sync_manager_manual => 'Yerel tut';

  @override
  String get app_sync_manager_title => 'Bot zaten yönetiliyor';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_invalid_content =>
      'Jeton sıfırlanmış gibi görünüyor. Lütfen Discord Geliştirici Portalı\'ndan yeni jetonu girin.';

  @override
  String get app_token_invalid_title => 'Jeton Sıfırlaması Algılandı';

  @override
  String get app_token_field_helper =>
      'Jetonu tam olarak Discord tarafından sağlandığı şekilde yapıştırın.';

  @override
  String get app_token_section_desc =>
      'Jeton kopyalandıktan sonra, botunuzu uygulamaya eklemek için aşağıya yapıştırın.';

  @override
  String get app_token_section_title => 'Bot jetonunuzu yapıştırın';

  @override
  String get app_token_security_hint =>
      'Bu jetonu gizli tutun. Ona sahip olan herkes botunuzu kontrol edebilir.';

  @override
  String get appearance_preset_graphite => 'Grafit';

  @override
  String get appearance_preset_graphite_desc =>
      'Nötr gri yüzeyler — özgün varsayılan görünüm.';

  @override
  String get appearance_preset_violet_bc => 'Mor Bot Creator';

  @override
  String get appearance_preset_violet_bc_desc =>
      'Bot Creator marka imzası; renkli yüzeyler dahil.';

  @override
  String get appearance_preset_discord => 'Discord';

  @override
  String get appearance_preset_discord_desc =>
      'Alışıldık bir görünüm için Discord blurple rengi.';

  @override
  String get appearance_preset_ocean => 'Okyanus';

  @override
  String get appearance_preset_ocean_desc => 'Derin su gibi camgöbeği tonları.';

  @override
  String get appearance_preset_forest => 'Orman';

  @override
  String get appearance_preset_forest_desc => 'Sakin ve doğal koyu yeşil.';

  @override
  String get appearance_preset_amber => 'Amber';

  @override
  String get appearance_preset_amber_desc =>
      'Canlı bir görünüm için sıcak turuncu.';

  @override
  String get appearance_preset_rose => 'Gül';

  @override
  String get appearance_preset_rose_desc => 'Cesur ve modern magenta pembe.';

  @override
  String get appearance_preset_high_contrast => 'Yüksek kontrast';

  @override
  String get appearance_preset_high_contrast_desc =>
      'Arayüz için maksimum okunabilirlik.';

  @override
  String get autocomplete_dynamic => 'Dinamik Otomatik Tamamlama';

  @override
  String get autocomplete_dynamic_desc =>
      'Seçenekleri statik değerler yerine bir iş akışından çözün.';

  @override
  String get autocomplete_filter_hint =>
      'Öneriler, kullanıcının yazdığına göre filtrelenir.';

  @override
  String get autocomplete_loading => 'İş akışları yükleniyor…';

  @override
  String get autocomplete_no_workflows => 'Kayıtlı iş akışı bulunamadı';

  @override
  String get autocomplete_select_workflow => 'Kayıtlı bir iş akışı seçin';

  @override
  String get autocomplete_type_name => 'Veya iş akışı adını yazın';

  @override
  String get autocomplete_workflow_label => 'Otomatik Tamamlama İş Akışı';

  @override
  String backup_completed(String id) {
    return 'Yedekleme tamamlandı: $id';
  }

  @override
  String backup_failed(String error) {
    return 'Yedekleme başarısız: $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Bu BDFD betiği derlenemedi:\n$summary';
  }

  @override
  String get bdfd_compile_error_simple => 'Bu BDFD betiği derlenemedi.';

  @override
  String get bdfd_compiled_no_actions =>
      'Bu BDFD betiği başarıyla derlendi ancak herhangi bir eylem üretmedi.';

  @override
  String get bdfd_editor_auto_indent => '• Enter ile akıllı otomatik girinti';

  @override
  String get bdfd_editor_diagnostics_toggle => 'Tanılama panelini değiştir';

  @override
  String get bdfd_editor_docs => 'Dokumantasyon';

  @override
  String get bdfd_editor_empty =>
      'Boş betik — tanılamaları görmek için yazmaya başlayın.';

  @override
  String get bdfd_editor_includes => 'İçerir:';

  @override
  String get bdfd_editor_indent_guides => '• Canlı girinti kılavuzları';

  @override
  String get bdfd_editor_quick_keys =>
      '• BDFD sembolleri için mobil hızlı tuşlar';

  @override
  String get bdfd_editor_tap_hint => 'Düzenleyiciyi açmak için dokunun';

  @override
  String get bdfd_editor_title => 'BDFD Düzenleyici';

  @override
  String get bdfd_editor_toggle_indent => 'Girinti kılavuzlarını değiştir';

  @override
  String get bdfd_editor_ux_title => 'Düzenleyici UX';

  @override
  String get bdfd_editor_wrap_toggle => 'Satır kaydırmayı değiştir';

  @override
  String get bdfd_runtime_execution_error =>
      'Bu BDFD betiği yürütülürken bir hata oluştu.';

  @override
  String get bot_home_create_command => 'İlk komutumu oluştur';

  @override
  String get bot_home_customize => 'Botumu özelleştir';

  @override
  String get bot_home_delete => 'Uygulamayı Sil';

  @override
  String get bot_home_delete_confirm =>
      'Bu uygulamayı silmek istediğinizden emin misiniz?';

  @override
  String get bot_home_invite => 'Botu Davet Et';

  @override
  String get bot_home_invite_error => 'Davet bağlantısı açılamadı';

  @override
  String get bot_home_ios_notice_content =>
      'Yerel modda, iOS uygulamayı arka planda askıya alabilir. Bot başlayabilir ancak Discord bağlantısını canlı tutmak bir Runner ile olduğu kadar garanti değildir.';

  @override
  String get bot_home_ios_notice_title => 'Yerel iOS kısıtlaması';

  @override
  String get bot_home_log_desktop_stop => 'Masaüstü bot durdurma istendi';

  @override
  String get bot_home_log_start => 'Bot başlatma istendi';

  @override
  String get bot_home_log_stop => 'Bot durdurma istendi';

  @override
  String get bot_home_notif_required =>
      'Bot hizmetini başlatmak için bildirim izni gereklidir.';

  @override
  String get bot_home_section_danger => 'TEHLİKELİ BÖLGE';

  @override
  String get bot_home_section_getting_started => 'BAŞLARKEN';

  @override
  String get bot_home_section_modules => 'MODÜLLER';

  @override
  String get bot_home_section_monitoring => 'İZLEME';

  @override
  String get bot_home_section_tools => 'ARAÇLAR';

  @override
  String get bot_home_service_not_started => 'Ön plan hizmeti başlamadı.';

  @override
  String get bot_home_start => 'Botu Başlat';

  @override
  String bot_home_start_error(String error) {
    return 'Başlatılamadı: $error';
  }

  @override
  String get bot_home_starting => 'Başlatılıyor…';

  @override
  String get bot_home_restart => 'Yeniden Başlat';

  @override
  String get bot_home_stop => 'Botu Durdur';

  @override
  String get bot_home_sync => 'Uygulamayı Senkronize Et';

  @override
  String get bot_home_sync_success => 'Uygulama başarıyla senkronize edildi';

  @override
  String get bot_home_pull => 'Buluttan İndir';

  @override
  String get bot_home_push => 'Buluta Gönder';

  @override
  String get bot_home_pull_success => 'Uygulama buluttan başarıyla indirildi';

  @override
  String get bot_home_push_success => 'Uygulama buluta başarıyla gönderildi';

  @override
  String get bot_home_version_history => 'Sürüm Geçmişi';

  @override
  String get bot_config_versions_title => 'Sürüm Geçmişi';

  @override
  String get bot_config_versions_empty => 'Önceki sürüm bulunamadı';

  @override
  String get bot_config_versions_restore => 'Geri Yükle';

  @override
  String get bot_config_versions_restore_confirm =>
      'Bu sürüm geri yüklensin mi? Mevcut yapılandırmanız önce yedeklenecek.';

  @override
  String get bot_config_versions_restored =>
      'Yapılandırma yerel olarak ve bulutta geri yüklendi.';

  @override
  String get bot_config_versions_error => 'Sürümler yüklenemedi';

  @override
  String get bot_config_versions_restore_error => 'Sürüm geri yüklenemedi';

  @override
  String get bot_home_pull_dialog_changes => 'Uygulanacak değişiklikler:';

  @override
  String get bot_home_pull_dialog_local => 'Yerel (Cihaz)';

  @override
  String get bot_home_pull_dialog_local_only => 'yalnızca yerel (saklandı)';

  @override
  String get bot_home_pull_dialog_local_preserved =>
      'Bulutta olmayan yerel komut(lar) korunacak.';

  @override
  String get bot_home_pull_dialog_new_commands => 'yeni komut(lar)';

  @override
  String get bot_home_pull_dialog_remote => 'Uzak (Bulut)';

  @override
  String get bot_home_pull_dialog_unchanged => 'değişmedi';

  @override
  String get bot_home_pull_dialog_up_to_date =>
      'Zaten güncel — değişiklik gerekmiyor.';

  @override
  String get bot_home_pull_dialog_updated_commands => 'güncellenen komut(lar)';

  @override
  String get bot_home_push_refused_empty =>
      'Push reddedildi: Yerel yapılandırma boş veya bozuk. Komutlarınızı kontrol edin.';

  @override
  String get bot_home_token_invalid_content =>
      'Jeton sıfırlanmış gibi görünüyor. Lütfen Discord Geliştirici Portalı\'ndan yeni jetonu girin. Botu yine de başlatmak istiyor musunuz?';

  @override
  String get bot_home_token_invalid_title => 'Jeton sıfırlanmış gibi görünüyor';

  @override
  String get bot_home_view_logs => 'Bot günlüklerini görüntüle';

  @override
  String get bot_home_view_replay => 'Hata ayıklayıcı tekrarlarını görüntüle';

  @override
  String get bot_home_view_stats => 'Bot istatistiklerini görüntüle';

  @override
  String get bot_logs_copied => 'Günlükler kopyalandı';

  @override
  String get bot_logs_disable_debug =>
      'Hata ayıklama günlüklerini devre dışı bırak';

  @override
  String get bot_logs_empty => 'Henüz günlük yok';

  @override
  String get bot_logs_enable_debug => 'Hata ayıklama günlüklerini etkinleştir';

  @override
  String get bot_logs_filter_count => 'Görüntülenen günlük sayısı';

  @override
  String get bot_logs_go_to_bottom => 'En alta git';

  @override
  String get bot_logs_go_to_latest => 'Son günlüğe git';

  @override
  String get bot_logs_newest_first => 'Önce en yeniyi göster';

  @override
  String get bot_logs_oldest_first => 'Önce en eskiyi göster';

  @override
  String bot_logs_ram(String memory) {
    return 'Bot süreci RAM: $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'Tahmini bot RAM: $memory';
  }

  @override
  String get bot_logs_raw_mode => 'Sıkıştırılmış ham günlükler';

  @override
  String get bot_logs_rich_mode => 'Zengin formatlı günlükler';

  @override
  String get bot_logs_server_empty =>
      'Bot Creator sunucuları bu bot için günlük döndürmedi.';

  @override
  String get bot_logs_server_read_failed =>
      'Günlükler Bot Creator sunucularından okunamadı.';

  @override
  String get bot_logs_show_all => 'Tümünü göster';

  @override
  String get bot_logs_show_less => 'Daha az göster';

  @override
  String get bot_logs_show_more => 'Daha fazla göster';

  @override
  String bot_logs_show_n(int count) {
    return '$count günlüğü göster';
  }

  @override
  String get bot_logs_title => 'Bot Günlükleri';

  @override
  String get bot_offline_token_desc =>
      'Jeton geçersiz veya eksik. Bağlantıyı geri yüklemek için yeni bir Discord bot jetonu girin.';

  @override
  String get bot_settings_activity_state_label =>
      'Etkinlik durumu (isteğe bağlı)';

  @override
  String get bot_settings_activity_url_label =>
      'Yayın URL\'si (yayında türü için)';

  @override
  String get bot_settings_add_status => 'Etkinlik ekle';

  @override
  String get bot_settings_app_flags => 'Uygulama Bayrakları';

  @override
  String get bot_settings_avatar_clear_selection => 'Seçimi temizle';

  @override
  String get bot_settings_avatar_important_note =>
      'Önemli: Profil değişiklikleri (kullanıcı adı ve avatar), yalnızca alttaki \'Profili ve durumları kaydet\' düğmesini tıkladığınızda Discord\'a uygulanacaktır.';

  @override
  String get bot_settings_avatar_local_path => 'Avatar yerel dosya yolu';

  @override
  String get bot_settings_avatar_none_selected =>
      'Yeni resim seçilmedi. Seçmek için Göz At\'a tıklayın.';

  @override
  String get bot_settings_avatar_path_hint => '/tam/yol/avatar.png';

  @override
  String get bot_settings_avatar_preview_error => 'Resim önizlenemiyor';

  @override
  String get bot_settings_avatar_preview_label => 'Avatar önizleme';

  @override
  String get bot_settings_avatar_selected => 'Seçilen resim:';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Seçilen dosya: $path';
  }

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Desteklenmeyen avatar formatı: $ext. Desteklenen formatlar: $formats.';
  }

  @override
  String get bot_settings_browse => 'Gözat';

  @override
  String get bot_settings_cancel_token_edit_btn => 'Jeton düzenlemeyi iptal et';

  @override
  String get bot_settings_danger_zone => 'Tehlikeli Bölge';

  @override
  String get bot_settings_delete_bot => 'Botu Sil';

  @override
  String get bot_settings_delete_bot_btn => 'Kalıcı Olarak Sil';

  @override
  String get bot_settings_delete_bot_desc =>
      'Bu işlem geri alınamaz. Tüm yerel veriler ve uzak yapılandırmalar kalıcı olarak kaldırılacaktır.';

  @override
  String bot_settings_delete_desc(String id) {
    return '$id botunu silmek istediğinizden emin misiniz? Tüm veriler kaybolacak.';
  }

  @override
  String get bot_settings_delete_title => 'Silme İşlemini Onayla';

  @override
  String get bot_settings_edit_token_btn => 'Jetonu düzenle';

  @override
  String get bot_settings_export_import => 'Dışa Aktar / İçe Aktar';

  @override
  String get bot_settings_export_import_desc =>
      'Bot yapılandırmanızı bir ZIP dosyası olarak dışa aktarın veya içe aktarın.';

  @override
  String get bot_settings_gateway_intents => 'Gateway Intent Yapılandırması';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Botunuzun hangi intent\'lere (niyetlere) ihtiyacı olduğunu seçin. Bunları Discord Geliştirici Portalı\'nda yapılandırın.';

  @override
  String get bot_settings_intents_saved => 'Intent\'ler başarıyla kaydedildi';

  @override
  String get bot_settings_intents_auto_enabled =>
      'Ayricalikli gateway intent\'leri Developer Portal\'da otomatik olarak etkinlestirildi.';

  @override
  String get bot_settings_intents_verified_bot_manual =>
      'Bu dogrulanmis bot, Discord Developer Portal\'da ayricalikli intent\'lerin manuel olarak etkinlestirilmesini gerektirir.';

  @override
  String get bot_settings_intents_auto_enable_failed =>
      'Token kaydedildi, ancak ayricalikli intent\'ler otomatik olarak etkinlestirilemedi. Discord Developer Portal\'da etkinlestirin.';

  @override
  String get bot_settings_lavalink_add_fallback => 'Yedek sunucu ekle';

  @override
  String get bot_settings_lavalink_choose_server => 'Genel bir sunucu seç...';

  @override
  String get bot_settings_lavalink_enable_subtitle =>
      'Bot genel sunucuları kendi dener; sunucu seçimi gerekmez.';

  @override
  String get bot_settings_lavalink_enable_title => 'Müzik (Lavalink)';

  @override
  String get bot_settings_lavalink_fallback_desc =>
      'Önce genel sunucular denenir. Hiçbiri yanıt vermezse kendi sunucularınız yedek olarak kullanılır.';

  @override
  String get bot_settings_lavalink_fallback_title => 'Yedek sunucularım';

  @override
  String get bot_settings_lavalink_host => 'Sunucu';

  @override
  String get bot_settings_lavalink_host_hint =>
      'localhost veya Lavalink sunucu IP\'si';

  @override
  String get bot_settings_lavalink_invalid_server =>
      'Bir ana bilgisayar ve 1 ile 65535 arasında bir port girin.';

  @override
  String get bot_settings_lavalink_no_fallback => 'Henüz yedek sunucu yok.';

  @override
  String get bot_settings_lavalink_password => 'Parola';

  @override
  String get bot_settings_lavalink_password_hint => 'youshallnotpass';

  @override
  String get bot_settings_lavalink_port => 'Port';

  @override
  String get bot_settings_lavalink_port_hint => '2333';

  @override
  String get bot_settings_lavalink_premium_banner_desc =>
      'Botunuz için Lavalink ses desteğinin kilidini açın.';

  @override
  String get bot_settings_lavalink_premium_banner_title =>
      '🔒 Bot Creator PREMIUM ile kullanılabilir';

  @override
  String get bot_settings_lavalink_public_servers => 'Genel sunucular';

  @override
  String get bot_settings_lavalink_remove_fallback => 'Kaldır';

  @override
  String get bot_settings_lavalink_save_btn => 'Kaydet';

  @override
  String get bot_settings_lavalink_save_caption =>
      'Kaydedin: bot önce genel sunucuları, ardından yedek sunucularınızı dener.';

  @override
  String get bot_settings_lavalink_section_title => 'Lavalink Sunucusu';

  @override
  String bot_settings_lavalink_server_number(int index) {
    return 'Yedek sunucu $index';
  }

  @override
  String get bot_settings_lavalink_server_picker_title =>
      'Genel Lavalink Sunucuları';

  @override
  String bot_settings_lavalink_server_subtitle(String port, String version) {
    return 'Port $port — $version';
  }

  @override
  String bot_settings_lavalink_servers_available(int count) {
    return '$count sunucu mevcut';
  }

  @override
  String get bot_settings_lavalink_ssl => 'SSL/TLS kullan';

  @override
  String get bot_settings_lavalink_ssl_subtitle => 'Güvenli wss:// bağlantısı';

  @override
  String get bot_settings_lavalink_success => 'Bağlantı başarılı!';

  @override
  String get bot_settings_lavalink_test_btn => 'Bağlantıyı test et';

  @override
  String get bot_settings_lavalink_testing => 'Test ediliyor...';

  @override
  String get bot_settings_lavalink_view_offers => 'Teklifleri gör';

  @override
  String get bot_settings_no_activities => 'Yapılandırılmış etkinlik yok';

  @override
  String get bot_settings_presence_dnd => 'Rahatsız Etmeyin';

  @override
  String get bot_settings_presence_idle => 'Boşta (Uzakta)';

  @override
  String get bot_settings_presence_invisible => 'Görünmez';

  @override
  String get bot_settings_presence_online => 'Çevrimiçi';

  @override
  String get bot_settings_presence_status_label => 'Varlık';

  @override
  String get bot_settings_presence_status_title => 'Bot Varlık Durumu';

  @override
  String get bot_settings_profile_saved =>
      'Profil/durumlar başarıyla uygulandı';

  @override
  String get bot_settings_profile_title => 'Bot Profili';

  @override
  String get bot_settings_remove_status => 'Etkinliği kaldır';

  @override
  String get bot_settings_save_intents_btn => 'Intent\'leri kaydet';

  @override
  String get bot_settings_save_intents_caption =>
      'Bu sadece gateway intent yapılandırmasını günceller.';

  @override
  String get bot_settings_save_profile_caption =>
      'Bu, kullanıcı adını/avatarı anında uygular ve durum rotasyonunu kaydeder.';

  @override
  String get bot_settings_save_profile_status_btn =>
      'Profili ve durumları kaydet';

  @override
  String get bot_settings_save_success => 'Ayarlar başarıyla kaydedildi';

  @override
  String get bot_settings_save_token_btn => 'Jetonu ve intent\'leri kaydet';

  @override
  String get bot_settings_save_token_caption =>
      'Jeton değişiklikleri korumalıdır. Önce \"Jetonu düzenle\"ye tıklayın, ardından kaydedin.';

  @override
  String get bot_settings_save_token_first =>
      'Profil/durum değişikliklerini uygulamadan önce lütfen jetonu kaydedin.';

  @override
  String get bot_settings_save_token_only_btn => 'Jetonu kaydet';

  @override
  String bot_settings_status_item_title(int index) {
    return 'Etkinlik $index';
  }

  @override
  String get bot_settings_status_max_interval => 'Maks aralık (sn)';

  @override
  String get bot_settings_status_min_interval => 'Min aralık (sn)';

  @override
  String get bot_settings_status_rotation_desc =>
      'Bir veya daha fazla etkinlik ekleyin. Her etkinliğin bir türü, adı ve minimum/maksimum aralığı (saniye) olmalıdır.';

  @override
  String get bot_settings_status_rotation_title => 'Etkinlik Rotasyonu';

  @override
  String get bot_settings_status_text_label => 'Etkinlik adı';

  @override
  String get bot_settings_status_type_competing => 'Yarışıyor';

  @override
  String get bot_settings_status_type_label => 'Tür';

  @override
  String get bot_settings_status_type_listening => 'Dinliyor';

  @override
  String get bot_settings_status_type_playing => 'Oynuyor';

  @override
  String get bot_settings_status_type_streaming => 'Yayında';

  @override
  String get bot_settings_status_type_watching => 'İzliyor';

  @override
  String get bot_settings_tab_advanced => 'Gelişmiş & Bakım';

  @override
  String get bot_settings_tab_general => 'Genel';

  @override
  String get bot_settings_tab_intents => 'Girişler & Ayrıcalıklar';

  @override
  String get bot_settings_tab_lavalink => 'Lavalink';

  @override
  String get bot_settings_tab_database => 'Veritabanı';

  @override
  String get bot_settings_database_section_title => 'Harici Veritabanı';

  @override
  String get bot_settings_database_type_label => 'Veritabanı Türü';

  @override
  String get bot_settings_database_type_none => 'Yok (Devre dışı)';

  @override
  String get bot_settings_database_type_postgres =>
      'PostgreSQL (anahtar kelime: pgsql)';

  @override
  String get bot_settings_database_type_mysql => 'MySQL (anahtar kelime: sql)';

  @override
  String get bot_settings_database_type_mongo =>
      'MongoDB (anahtar kelime: mongo)';

  @override
  String get bot_settings_database_info_postgres =>
      'Komut dosyalarınızda genel \"pgsql\" anahtar kelimesi ile kullanılabilir (örn: await pgsql.query(\"SELECT * FROM users\")).';

  @override
  String get bot_settings_database_info_mysql =>
      'Komut dosyalarınızda genel \"sql\" anahtar kelimesi ile kullanılabilir (örn: await sql.query(\"SELECT * FROM users\")).';

  @override
  String get bot_settings_database_info_mongo =>
      'Komut dosyalarınızda genel \"mongo\" anahtar kelimesi ile kullanılabilir (örn: await mongo.collection(\"users\").find()).';

  @override
  String get bot_settings_database_uri_label => 'Bağlantı Dizesi (URI)';

  @override
  String get bot_settings_database_show_discrete_fields =>
      'Ayrı alanları yapılandır (Sunucu, Port, vb.)';

  @override
  String get bot_settings_database_hide_discrete_fields =>
      'Ayrı alanları gizle';

  @override
  String get bot_settings_database_host => 'Sunucu';

  @override
  String get bot_settings_database_host_hint => 'localhost veya IP adresi';

  @override
  String get bot_settings_database_port => 'Port';

  @override
  String get bot_settings_database_name => 'Veritabanı Adı';

  @override
  String get bot_settings_database_name_hint => 'örn: bot_db';

  @override
  String get bot_settings_database_user => 'Kullanıcı Adı';

  @override
  String get bot_settings_database_user_hint => 'örn: root veya postgres';

  @override
  String get bot_settings_database_password => 'Parola';

  @override
  String get bot_settings_database_ssl => 'SSL / TLS\'yi etkinleştir';

  @override
  String get bot_settings_database_save_btn =>
      'Veritabanı Yapılandırmasını Kaydet';

  @override
  String get bot_settings_tab_presence => 'Durum & Varlık';

  @override
  String get bot_settings_title => 'Botu Özelleştir / Profil';

  @override
  String get bot_settings_token_hidden_desc =>
      'Jeton girişi güvenlik nedeniyle varsayılan olarak gizlidir.';

  @override
  String get bot_settings_token_hint => 'Bot jetonunuzu buraya girin';

  @override
  String get bot_settings_token_mismatch_confirm => 'Yine de jetonu değiştir';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Bu jeton $newId botuna ait ancak mevcut veriler $oldId botuna ait. Komutlar ve ayarlar eşleşmeyebilir. Yine de devam edilsin mi?';
  }

  @override
  String get bot_settings_token_mismatch_title => 'Farklı bot algılandı';

  @override
  String get bot_settings_token_required => 'Bot jetonu gereklidir.';

  @override
  String get bot_settings_token_saved => 'Jeton başarıyla kaydedildi';

  @override
  String get bot_settings_token_title => 'Bot Jetonu';

  @override
  String get bot_settings_update_token => 'Bot Jetonunu Güncelle';

  @override
  String get bot_settings_username_hint =>
      'Mevcut kullanıcı adını korumak için boş bırakın';

  @override
  String get bot_settings_username_override => 'Kullanıcı adı geçersiz kılma';

  @override
  String get bot_settings_workflow_docs => 'Dokumantasyon';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Rehberler, BDFD referansi ve discord.js dokumantasyonu';

  @override
  String get bot_stats_collecting => 'Toplanıyor…';

  @override
  String get bot_stats_cpu => 'Bot süreci CPU';

  @override
  String get bot_stats_notes =>
      'Notlar: CPU Android/Linux üzerinde mevcuttur. Depolama = uygulamadaki bot veri dosyaları.';

  @override
  String get bot_stats_ram_estimated => 'Sadece bot RAM (tahmini)';

  @override
  String get bot_stats_ram_process => 'Bot süreci RAM';

  @override
  String get bot_stats_source_local_hosting => 'Kaynak: Yerel Barındırma';

  @override
  String get bot_stats_source_runner_api => 'Kaynak: Runner API';

  @override
  String get bot_stats_storage => 'Bot depolama (uygulama verisi)';

  @override
  String get bot_stats_title => 'Bot İstatistikleri';

  @override
  String get cancel => 'İptal';

  @override
  String get close => 'Kapat';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Hızlı betik önerileri almak için \$ yazın ve bir fonksiyon adı yazmaya başlayın.';

  @override
  String get cmd_bdfd_autocomplete_title => 'BDFD ön ek otomatik tamamlama';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Mevcut betikte sorun tespit edilmedi.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Hata';

  @override
  String get cmd_bdfd_diagnostics_title => 'BDFD tanılamaları';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Uyarı';

  @override
  String get cmd_bdfd_script_empty_error => 'BDFD betik gövdesi boş olamaz.';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nBot Creator\'dan merhaba';

  @override
  String get cmd_bdfd_script_label => 'BDFD betik gövdesi';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Bu BDFD betiği hala tanılamalar içeriyor:';

  @override
  String get cmd_create_tooltip => 'Komut oluştur';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Mevcut Dart betiğinde sorun tespit edilmedi.';

  @override
  String get cmd_dart_diagnostics_error => 'Hata';

  @override
  String get cmd_dart_diagnostics_title => 'Dart tanılamaları';

  @override
  String get cmd_dart_diagnostics_warning => 'Uyarı';

  @override
  String get cmd_dart_script_hint => 'return \"Dart Direct\'ten merhaba\";';

  @override
  String get cmd_dart_script_label => 'Dart betik gövdesi';

  @override
  String cmd_batch_delete_confirm(int count) {
    return '$count komut silinsin mi?';
  }

  @override
  String cmd_batch_delete_success(Object count) {
    return '$count komut silindi';
  }

  @override
  String cmd_delete_confirm(Object name) {
    return '\"$name\" komutu silinsin mi?';
  }

  @override
  String cmd_delete_success(Object name) {
    return '\"$name\" komutu silindi';
  }

  @override
  String get cmd_delete_tooltip => 'Komut sil';

  @override
  String get cmd_deploy_close_button => 'Kapat';

  @override
  String get cmd_deploy_cloud_sync_subtitle =>
      'Çevrimiçi alanınızla güvenli senkronizasyon';

  @override
  String get cmd_deploy_cloud_sync_title => 'Bulut Yedekleme';

  @override
  String cmd_deploy_config_subtitle(String name) {
    return '/$name yapılandırması';
  }

  @override
  String get cmd_deploy_discord_sync_subtitle =>
      'Komut Discord API\'sine yayınlanıyor';

  @override
  String get cmd_deploy_discord_sync_title => 'Discord Senkronizasyonu';

  @override
  String get cmd_deploy_failed_title => 'Dağıtım başarısız';

  @override
  String get cmd_deploy_hot_reload_subtitle =>
      'Bot çalıştırıcınızın anında güncellenmesi';

  @override
  String get cmd_deploy_hot_reload_title => 'Sıcak Yeniden Yükleme';

  @override
  String get cmd_deploy_in_progress_title => 'Dağıtım devam ediyor...';

  @override
  String get cmd_deploy_local_save_subtitle => 'Komut cihaza kaydediliyor';

  @override
  String get cmd_deploy_local_save_title => 'Yerel Kaydetme';

  @override
  String get cmd_deploy_reload_bot_subtitle =>
      'Sıcak yükleme yapılandırması uygulanıyor';

  @override
  String get cmd_deploy_reload_bot_title => 'Bot Yeniden Yükleniyor';

  @override
  String get cmd_deploy_retry_button => 'Yeniden Dene';

  @override
  String get cmd_deploy_success_title => 'Dağıtım başarılı!';

  @override
  String cmd_deploy_success_toast(String name) {
    return '\"$name\" komutu dağıtıldı ve aktif!';
  }

  @override
  String get cmd_editor_mode_advanced => 'Gelişmiş mod';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Özel yanıt, seçenekler ve eylem oluşturucu ile tam düzenleyici.';

  @override
  String get cmd_editor_mode_locked => 'Bu komut için gelişmiş mod kilitli.';

  @override
  String get cmd_editor_mode_simple => 'Basitleştirilmiş mod';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Rehberli seçenekler ve önceden yapılandırılmış eylemlerle hızlıca bir komut oluşturun.';

  @override
  String get cmd_editor_mode_switch_adv => 'Gelişmiş moda geç';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Geç';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Bu geçiş bu komut için tek yönlüdür. Basitleştirilmiş moda geri dönemeyeceksiniz.';

  @override
  String get cmd_editor_mode_switch_adv_title => 'Gelişmiş moda geçilsin mi?';

  @override
  String get cmd_editor_mode_title => 'Düzenleme modu';

  @override
  String get cmd_error_fill_fields => 'Lütfen tüm alanları doldurun';

  @override
  String get cmd_execution_mode_bdfd => 'BDFD Betik modu';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Komut tanımını görsel tutarken komut gövdesini BDFD tarzı betik olarak yazın.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'Betik dahili eylemlere derlenir. Düzenleme sırasında tanılamalar gösterilir; geçersiz betikler komut çalıştığında hata verir.';

  @override
  String get cmd_execution_mode_dart => 'Dart Doğrudan modu';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Çalışma zamanı tanılamalarıyla komut gövdesini doğrudan Dart ile yazın.';

  @override
  String get cmd_execution_mode_dart_note =>
      'Dart kodu, korumalı alan motoru aracılığıyla çalışma zamanında derlenir. Betikleri deterministik tutun ve gerektiğinde bir değer döndürün.';

  @override
  String get cmd_execution_mode_javascript => 'JavaScript';

  @override
  String get cmd_execution_mode_javascript_desc =>
      'Bu komut için özel JS kodu yazın.';

  @override
  String get cmd_execution_mode_javascript_note =>
      'Tüm BDFD fonksiyonları asenkron JS fonksiyonları olarak kullanılabilir. Bağlam ve değişkenlere erişmek için ctx.authorId, ctx.channelId, vars[\'key\'] kullanın.';

  @override
  String get cmd_execution_mode_desc =>
      'Komut meta verileri görsel oluşturucuda kalır. Komut gövdesinin nasıl çalışacağını seçin.';

  @override
  String get cmd_execution_mode_title => 'Yürütme modu';

  @override
  String get cmd_execution_mode_workflow => 'İş akışı modu';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Mevcut görsel yanıt ve eylem oluşturucuyu kullanın.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'İş akışı modu mevcut üretim yoludur ve tam olarak desteklenmeye devam eder.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Geçir';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Mevcut BDFD betiğinizden bir Dart geçiş iskeleti oluşturun.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Bu komut tam olarak yüklenemedi (çevrimdışı veya jeton geçersiz). Düzenlemek için geçerli bir jeton bağlayın.';

  @override
  String get cmd_show_variables => 'Değişken belgelerini aç';

  @override
  String get cmd_simple_action_add_role => 'Rol ekle';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Seçilen /rol\'ü seçilen /kullanici\'ya verir.';

  @override
  String get cmd_simple_action_ban => 'Kullanıcıyı yasakla';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      'Silinecek son 0 ila 7 günlük mesajlar';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Yasaklama mesaj silme günleri';

  @override
  String get cmd_simple_action_ban_desc =>
      'Seçilen /kullanici\'yi sunucudan yasaklar.';

  @override
  String get cmd_simple_action_create_invite => 'Davet oluştur';

  @override
  String get cmd_simple_action_create_invite_desc =>
      'Mevcut kanal veya isteğe bağlı bir /kanal için davet oluşturur.';

  @override
  String get cmd_simple_action_create_poll => 'Anket oluştur';

  @override
  String get cmd_simple_action_create_poll_desc =>
      'Dinamik bir /soru ve sabit cevap seçenekleri ile bir anket oluşturur.';

  @override
  String get cmd_simple_action_delete => 'Mesajları sil';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      '/sayi sağlanmadığında kullanılır';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Varsayılan silme sayısı';

  @override
  String get cmd_simple_action_delete_desc =>
      'Mevcut kanaldaki mesajları sil (isteğe bağlı /sayi).';

  @override
  String get cmd_simple_action_kick => 'Kullanıcıyı at';

  @override
  String get cmd_simple_action_kick_desc =>
      'Seçilen /kullanici\'yi sunucudan atar.';

  @override
  String get cmd_simple_action_mute => 'Kullanıcıyı sustur';

  @override
  String get cmd_simple_action_mute_desc =>
      'Seçilen /kullanici\'yi geçici olarak susturur.';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Örnekler: 10m, 2h, 1d veya ham saniye';

  @override
  String get cmd_simple_action_mute_duration_label => 'Susturma süresi';

  @override
  String get cmd_simple_action_pin => 'Mesajı sabitle';

  @override
  String get cmd_simple_action_pin_desc =>
      '/mesaj_id kullanarak mevcut kanalda bir mesajı sabitler.';

  @override
  String get cmd_simple_action_reason_hint =>
      'Moderasyon eylemleri tarafından paylaşılan isteğe bağlı neden';

  @override
  String get cmd_simple_action_reason_label => 'Denetim kaydı nedeni';

  @override
  String get cmd_simple_action_remove_role => 'Rolü kaldır';

  @override
  String get cmd_simple_action_remove_role_desc =>
      'Seçilen /rol\'ü seçilen /kullanici\'dan kaldırır.';

  @override
  String get cmd_simple_action_send_message => 'Mesaj gönder';

  @override
  String get cmd_simple_action_send_message_desc =>
      'Mevcut kanalda ek bir mesaj gönderir.';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Mesaj Gönder eylemi tarafından gönderilen mesaj';

  @override
  String get cmd_simple_action_send_message_label => 'Eylem mesajı';

  @override
  String get cmd_simple_action_unban => 'Yasağı kaldır';

  @override
  String get cmd_simple_action_unban_desc =>
      'Sağlanan bir /kullanici_id dizesi ile bir kullanıcının yasağını kaldırır.';

  @override
  String get cmd_simple_action_unmute => 'Susturmayı kaldır';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Seçilen /kullanici\'dan zaman aşımını kaldırır.';

  @override
  String get cmd_simple_action_unpin => 'Mesaj sabitlemesini kaldır';

  @override
  String get cmd_simple_action_unpin_desc =>
      '/mesaj_id kullanarak mevcut kanalda bir mesajın sabitlemesini kaldırır.';

  @override
  String get cmd_simple_actions_desc =>
      'Bu komutun ne yapması gerektiğini seçin. Seçenekler otomatik olarak oluşturulur.';

  @override
  String get cmd_simple_actions_title => 'Basitleştirilmiş eylemler';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Kullanıcıyı yasakla ve yasağı kaldır, basitleştirilmiş modda birlikte etkinleştirilemez.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Kullanıcıyı sustur ve susturmayı kaldır, basitleştirilmiş modda birlikte etkinleştirilemez.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Mesajı sabitle ve sabitlemeyi kaldır, basitleştirilmiş modda birlikte etkinleştirilemez.';

  @override
  String get cmd_simple_execution_desc =>
      'Basitleştirilmiş moddan ayrılmadan oluşturulan eylemlerde ince ayar yapın.';

  @override
  String get cmd_simple_execution_title => 'Yürütme ayarları';

  @override
  String get cmd_simple_generated_none =>
      'Henüz seçenek oluşturulmadı. En az bir eylem seçin.';

  @override
  String get cmd_simple_generated_options => 'Oluşturulan komut seçenekleri';

  @override
  String get cmd_simple_group_messages_desc =>
      'Mevcut bağlamda çalışan mesaj ve kanal eylemleri.';

  @override
  String get cmd_simple_group_messages_title => 'Mesajlar';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Rehberli seçeneklerle üye ve moderasyon eylemleri.';

  @override
  String get cmd_simple_group_moderation_title => 'Moderasyon';

  @override
  String get cmd_simple_group_utility_desc =>
      'Davetler ve anketler gibi yararlı ekstralar.';

  @override
  String get cmd_simple_group_utility_title => 'Araçlar';

  @override
  String get cmd_simple_invite_max_age_hint =>
      'Süre sonu olmaması için 0, 604800\'e kadar';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'Davet süresi 0 ile 604800 saniye arasında bir sayı olmalıdır.';

  @override
  String get cmd_simple_invite_max_age_label => 'Davet süresi (saniye)';

  @override
  String get cmd_simple_invite_max_uses_hint => 'Sınırsız kullanım için 0';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'Davet maksimum kullanımı 0 ile 1000000 arasında bir sayı olmalıdır.';

  @override
  String get cmd_simple_invite_max_uses_label => 'Maksimum kullanım';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Oluşturulan Davet Oluştur eylemi tarafından kullanılan varsayılanlar.';

  @override
  String get cmd_simple_invite_settings_title => 'Davet ayarları';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Üyeler bir rol almadan ayrılırlarsa çıkarılırlar.';

  @override
  String get cmd_simple_invite_temporary_label => 'Geçici üyelik';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Mevcut olanı yeniden kullanmak yerine her zaman yeni bir davet oluşturun.';

  @override
  String get cmd_simple_invite_unique_label => 'Benzersiz davet zorla';

  @override
  String get cmd_simple_option_channel => '/kanal (Kanal)';

  @override
  String get cmd_simple_option_channel_desc =>
      'Davet oluşturma için isteğe bağlı kanal geçersiz kılma';

  @override
  String get cmd_simple_option_count => '/sayi (Tam Sayı)';

  @override
  String get cmd_simple_option_count_desc => 'Silinecek mesaj sayısı';

  @override
  String get cmd_simple_option_message_id => '/mesaj_id (Metin)';

  @override
  String get cmd_simple_option_message_id_desc => 'Hedeflenecek mesaj ID\'si';

  @override
  String get cmd_simple_option_question => '/soru (Metin)';

  @override
  String get cmd_simple_option_question_desc => 'Anket sorusu';

  @override
  String get cmd_simple_option_role => '/rol (Rol)';

  @override
  String get cmd_simple_option_role_desc => 'Hedef rol';

  @override
  String get cmd_simple_option_user => '/kullanici (Kullanıcı)';

  @override
  String get cmd_simple_option_user_desc => 'Hedef kullanıcı';

  @override
  String get cmd_simple_option_user_id => '/kullanici_id (Metin)';

  @override
  String get cmd_simple_option_user_id_desc =>
      'Yasağı kaldırılacak kullanıcı ID\'si';

  @override
  String get cmd_simple_poll_answers_hint =>
      'Her satıra bir cevap veya virgül kullanın. Minimum 2, maksimum 10.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'Anket cevapları 2 ile 10 arasında boş olmayan seçenek içermelidir.';

  @override
  String get cmd_simple_poll_answers_label => 'Anket cevapları';

  @override
  String get cmd_simple_poll_duration_hint => '1 ila 168 saat arası';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'Anket süresi 1 ile 168 saat arasında bir sayı olmalıdır.';

  @override
  String get cmd_simple_poll_duration_label => 'Anket süresi (saat)';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Kullanıcılar birden fazla seçenek belirleyebilir.';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Birden fazla cevaba izin ver';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Oluşturulan Anket Oluştur eylemi tarafından kullanılan varsayılanlar.';

  @override
  String get cmd_simple_poll_settings_title => 'Anket ayarları';

  @override
  String get cmd_simple_response_desc =>
      'Eylemler yürütüldükten sonra kullanıcıya geri gönderilen mesaj.';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Final yanıtıyla birlikte gönderilen isteğe bağlı gömülü mesajlar.';

  @override
  String get cmd_simple_response_embeds_title => 'Yanıt gömülü mesajları';

  @override
  String get cmd_simple_response_hint => 'Bitti ✅';

  @override
  String get cmd_simple_response_title => 'Final yanıtı';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'Geçici (Ephemeral)';

  @override
  String get cmd_simple_response_visibility_label => 'Yanıt görünürlüğü';

  @override
  String get cmd_simple_response_visibility_public => 'Genel';

  @override
  String get cmd_simple_send_message_required =>
      'Lütfen kaydetmeden önce eylem mesajını doldurun.';

  @override
  String get cmd_variables_title => 'Komut Değişkenleri';

  @override
  String get code_editor_settings_title => 'Kod düzenleyici';

  @override
  String get code_editor_settings_subtitle =>
      'BDFD ve JavaScript düzenleyicileri için tema, yazı tipi ve düzenleme davranışı';

  @override
  String get code_editor_settings_reset_tooltip => 'Varsayılanlara sıfırla';

  @override
  String get code_editor_settings_reset_title => 'Yapılandırmayı sıfırla';

  @override
  String get code_editor_settings_reset_confirm =>
      'Tüm düzenleyici ayarları varsayılan değerlerine sıfırlansın mı?';

  @override
  String get code_editor_settings_reset_action => 'Sıfırla';

  @override
  String get code_editor_settings_reset_done =>
      'Düzenleyici ayarları varsayılana sıfırlandı';

  @override
  String get code_editor_settings_preview_title => 'Canlı önizleme';

  @override
  String get code_editor_settings_section_theme_title =>
      'Sözdizimi renklendirme teması';

  @override
  String get code_editor_settings_section_theme_subtitle =>
      'BDFD ve JavaScript için uygulanan görsel stili seçin';

  @override
  String get code_editor_settings_theme_mode_dark => 'Koyu mod';

  @override
  String get code_editor_settings_theme_mode_light => 'Açık mod';

  @override
  String get code_editor_settings_section_font_title =>
      'Yazı tipi ve tipografi';

  @override
  String get code_editor_settings_section_font_subtitle =>
      'Yazı tipi ailesini ve metin boyutunu ayarlayın';

  @override
  String get code_editor_settings_font_family => 'Yazı tipi ailesi';

  @override
  String get code_editor_settings_font_system => 'Sistem tek aralıklı';

  @override
  String get code_editor_settings_font_jetbrains_mono => 'JetBrains Mono';

  @override
  String get code_editor_settings_font_fira_code => 'Fira Code';

  @override
  String get code_editor_settings_font_consolas => 'Consolas';

  @override
  String get code_editor_settings_font_size => 'Yazı tipi boyutu';

  @override
  String get code_editor_settings_line_height =>
      'Satır yüksekliği (satır aralığı)';

  @override
  String get code_editor_settings_section_display_title =>
      'Görünüm ve görsel kılavuzlar';

  @override
  String get code_editor_settings_section_display_subtitle =>
      'Satır numaraları, girinti kılavuzları ve satır kaydırma';

  @override
  String get code_editor_settings_line_numbers => 'Satır numaraları';

  @override
  String get code_editor_settings_line_numbers_desc =>
      'Numaralandırmayı sol kenar boşluğunda gösterir';

  @override
  String get code_editor_settings_indent_guides => 'Girinti kılavuzları';

  @override
  String get code_editor_settings_indent_guides_desc =>
      'Kod bloklarını görmek için dikey çizgiler';

  @override
  String get code_editor_settings_word_wrap => 'Otomatik satır kaydırma';

  @override
  String get code_editor_settings_word_wrap_desc =>
      'Uzun satırları yatay kaydırmak yerine kaydırır';

  @override
  String get code_editor_settings_quick_chars =>
      'Hızlı karakter çubuğu (mobil)';

  @override
  String get code_editor_settings_quick_chars_desc =>
      'Klavyenin üzerinde BDFD ön eki, bağımsız değişkenler, ayırıcılar ve parantezler eklemek için hızlı düğmeler';

  @override
  String get code_editor_settings_section_editing_title =>
      'Düzenleme davranışı';

  @override
  String get code_editor_settings_section_editing_subtitle =>
      'Otomatik kapatma ve boşluklar';

  @override
  String get code_editor_settings_auto_close =>
      'Sembollerin otomatik kapanması';

  @override
  String get code_editor_settings_auto_close_desc =>
      'Köşeli parantezleri, küme parantezlerini, normal parantezleri ve tırnak işaretlerini otomatik kapatır';

  @override
  String get code_editor_settings_tab_size => 'Sekme boyutu (boşluk)';

  @override
  String get code_editor_settings_tab_size_desc =>
      'Girintilerken eklenen boşluk sayısı';

  @override
  String get command_alias_label => 'Takma ad';

  @override
  String get command_alias_hint => '!p';

  @override
  String get command_alias_help =>
      'Komut bu tetikleyici sözcüklere de yanıt verir.';

  @override
  String get command_alias_duplicate => 'Bu takma ad zaten kullanılıyor.';

  @override
  String command_alias_limit(int max) {
    return 'En fazla $max takma ad.';
  }

  @override
  String command_alias_collision(String command) {
    return '$command komutu tarafından zaten kullanılıyor.';
  }

  @override
  String get command_awaited_error => 'Hata';

  @override
  String get command_awaited_filter_hint =>
      'Örnek: <numeric> veya <yes/no/cancel>';

  @override
  String get command_awaited_filter_label => 'Filtre (isteğe bağlı)';

  @override
  String get command_awaited_name_hint => 'Örnek: soyle';

  @override
  String get command_awaited_name_label => 'Beklenen geri arama adı';

  @override
  String get command_awaited_preset_active => 'Beklenen geri arama ön ayarı';

  @override
  String get command_awaited_preset_button =>
      'Beklenen Geri Arama Ön Ayarını Kullan';

  @override
  String get command_awaited_preset_desc =>
      'Komut adı sizin için oluşturulur ve dahili bir eski geri arama olarak kaydedilir.';

  @override
  String get command_awaited_success => 'Başarılı';

  @override
  String get command_context_bot_dm => 'Bot DM';

  @override
  String get command_context_group_dm => 'Grup DM / Diğer';

  @override
  String get command_context_guild => 'Sunucu';

  @override
  String get command_description_length =>
      'Komut açıklaması en fazla 100 karakter uzunluğunda olmalıdır';

  @override
  String get command_description_required =>
      'Lütfen bir komut açıklaması girin';

  @override
  String get command_edit_raw_name => 'Ham Adı Düzenle';

  @override
  String get command_error_missing_bot_id =>
      'Yerel komut kaydı için bot ID\'si eksik.';

  @override
  String get command_execution_error =>
      'Bu komut yürütülürken bir hata oluştu.';

  @override
  String get command_export_tooltip => 'Komut yükünü dışa aktar';

  @override
  String get command_import_tooltip => 'Komut yükünü içe aktar';

  @override
  String get command_discord_rules_message_hint =>
      'Mesaj komutları bir mesajın bağlam menüsünde görünür. Ad boşluk ve büyük/küçük harf içerebilir (1-32 karakter). Discord açıklama kullanmaz.';

  @override
  String get command_discord_rules_slash_hint =>
      'Slash komutları Discord\'a kaydedilir. Ad küçük harf olmalıdır (1-32 karakter). Açıklama zorunludur (1-100 karakter). Ad, açıklama ve seçenekler toplamı 8000 karakteri aşamaz.';

  @override
  String get command_discord_rules_user_hint =>
      'Kullanıcı komutları bir kullanıcının bağlam menüsünde görünür. Ad boşluk ve büyük/küçük harf içerebilir (1-32 karakter). Discord açıklama kullanmaz.';

  @override
  String get command_info_desc => 'Temel meta veriler ve kullanılabilirlik';

  @override
  String get command_info_title => 'Komut Bilgisi';

  @override
  String get command_integration_guild => 'Sunucu Kurulumu';

  @override
  String get command_integration_label => 'Bu komut nerede kullanılabilir';

  @override
  String get command_integration_user => 'Kullanıcı Kurulumu';

  @override
  String get command_legacy_mode_subtitle =>
      'Bot ön ekiyle sohbetten çalıştırılır (örnek: !config #kanal).';

  @override
  String get command_legacy_mode_title => 'Bu komutta ön ek modunu etkinleştir';

  @override
  String get command_legacy_prefix_desc =>
      'messageCreate ile <on_ek><komut> olarak tetiklenir.';

  @override
  String get command_legacy_prefix_title => 'Ön Ek Komut Modu';

  @override
  String get command_legacy_preset_desc =>
      'Yalnızca yerel bir ön ek komutu için dahili beklenen geri arama tetikleyicisi oluşturun.';

  @override
  String get command_legacy_preset_title => 'Ön ek ön ayarı';

  @override
  String get command_legacy_response_label => 'Ön ek yanıt modu';

  @override
  String get command_modal_disabled_legacy =>
      'Modallar ön ek modunda devre dışıdır.';

  @override
  String get command_name_generated =>
      'Beklenen geri arama ön ayarı tarafından oluşturuldu.';

  @override
  String get command_name_label => 'Ad';

  @override
  String get command_not_found => 'Komut bulunamadı';

  @override
  String get command_options_legacy_params =>
      'Ön ek konumsal parametreler (sıralı: önce gerekli, sonra isteğe bağlı)';

  @override
  String get command_options_slash_params => 'Eğik çizgi komut parametreleri';

  @override
  String get command_options_title => 'Komut Seçenekleri';

  @override
  String get command_payload_hint => 'Komut yükü';

  @override
  String get command_prefix_rules_hint =>
      'Ön ek komutları sohbet mesajlarından çalışır (ör. !ping) ve Discord\'a kaydedilmez. Discord slash kuralları geçerli değildir. Açıklama isteğe bağlıdır.';

  @override
  String get command_permissions_admin_warning =>
      'Yönetici seçildi: bu diğer izin kontrollerini atlar.';

  @override
  String get command_permissions_bitfield => 'Hesaplanan İzin Bit Alanı';

  @override
  String get command_permissions_bitfield_helper =>
      'Seçilen izinlerden otomatik olarak hesaplanır.';

  @override
  String command_permissions_count(int count) {
    return '$count izin seçildi';
  }

  @override
  String get command_permissions_label =>
      'Varsayılan Üye İzinleri (isteğe bağlı)';

  @override
  String get command_permissions_none =>
      'Seçim yok (herkes komutu kullanabilir)';

  @override
  String get command_permissions_tip =>
      'İpucu: Komutu varsayılan olarak herkesin kullanımına sunmak için hepsini işaretsiz bırakın.';

  @override
  String get command_permissions_title => 'İzinleri seç';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Uyarı: kaydedilen verilerden bilinmeyen izin bitleri algılandı ve korundu: $bits';
  }

  @override
  String get command_prefix_helper =>
      'Şablonları ve kapsamlı değişkenleri destekler (bc_ isteğe bağlı). Örnek: ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint =>
      'Örnek: ? veya ((guild.prefix | !))';

  @override
  String get command_prefix_override_label =>
      'Ön ek geçersiz kılma (isteğe bağlı)';

  @override
  String get command_response_mode_channel => 'mesaj.kanal.gonder';

  @override
  String get command_response_mode_reply => 'mesaj.yanitla';

  @override
  String get command_scope_label => 'Komutun kapsamı (Bağlamlar)';

  @override
  String get command_subcommand_workflow_desc =>
      'Hangi alt komutu yapılandıracağınızı seçin.';

  @override
  String get command_subcommand_workflow_title => 'Alt Komut İş Akışı';

  @override
  String command_sync_failed_local(String error) {
    return 'Yerel olarak kaydedildi. Discord senkronizasyonu başarısız oldu: $error';
  }

  @override
  String get command_cloud_sync_failed_saved =>
      'Discord ve yerel olarak kaydedildi. Bulut yedekleme başarısız oldu.';

  @override
  String get command_cloud_sync_retry => 'Senkronizasyonu yeniden dene';

  @override
  String get cmd_block_editor_empty_title => 'Henüz eylem yok';

  @override
  String get cmd_block_editor_empty_hint =>
      'Komutunuz çalıştığında ne yapacağını tanımlamak için bir eylem bloğu ekleyin.';

  @override
  String get cmd_block_editor_add_action => 'Eylem ekle';

  @override
  String cmd_block_editor_action_label(int index) {
    return 'Eylem $index';
  }

  @override
  String get command_target_subcommand => 'Hedef alt komut';

  @override
  String get command_type_label => 'Komut Türü';

  @override
  String get command_type_legacy => 'Ön Ek Komutu';

  @override
  String get command_type_locked =>
      'Komut türü oluşturulduktan sonra değiştirilemez.';

  @override
  String get command_type_message => 'Mesaj Komutu';

  @override
  String get command_type_slash => 'Eğik Çizgi Komutu';

  @override
  String get command_type_user => 'Kullanıcı Komutu';

  @override
  String get command_unsaved_confirm =>
      'Kaydedilmemiş değişiklikleriniz var. Onları atmak istiyor musunuz?';

  @override
  String get command_unsaved_keep => 'Düzenlemeye devam et';

  @override
  String get command_unsaved_title => 'Kaydedilmemiş değişiklikler';

  @override
  String get commands_all_folders => 'Tüm klasörler';

  @override
  String get commands_create_button => 'Komut oluştur';

  @override
  String get commands_create_folder => 'Klasör oluştur';

  @override
  String commands_create_from_query(String query) {
    return '\"$query\" komutunu oluştur';
  }

  @override
  String get commands_delete_folder => 'Klasörü sil';

  @override
  String get commands_delete_folder_desc =>
      'Bu klasördeki komutlar silinmeyecek, sadece klasörden çıkarılacaktır.';

  @override
  String get commands_empty => 'Komut bulunamadı';

  @override
  String commands_error(String error) {
    return 'Hata: $error';
  }

  @override
  String get commands_filter_legacy_local => 'Eski yerel';

  @override
  String get commands_filter_template => 'Şablon';

  @override
  String get commands_filter_type_label => 'Tür';

  @override
  String get commands_folder_hint => 'İsteğe bağlı klasör adı';

  @override
  String get commands_folder_label => 'Klasör';

  @override
  String get commands_move_to_folder => 'Klasöre taşı';

  @override
  String get commands_new_folder_hint => 'Yeni klasör adı';

  @override
  String get commands_no_folder => 'Klasör yok';

  @override
  String get commands_no_match_filters =>
      'Mevcut filtrelerle eşleşen komut yok.';

  @override
  String get commands_remove_from_folder => 'Klasörden kaldır';

  @override
  String get commands_rename_folder => 'Klasörü yeniden adlandır';

  @override
  String get commands_reorder_title => 'Komutları düzenle';

  @override
  String get commands_search_hint => 'Komutlarda ara...';

  @override
  String get commands_tab => 'Komutlar';

  @override
  String get commands_tab_short => 'Komut';

  @override
  String get commands_title => 'Komutlar';

  @override
  String get common_add_argument => 'Argüman Ekle';

  @override
  String get common_add_option => 'Seçenek Ekle';

  @override
  String get common_add_section => 'Bölüm Ekle';

  @override
  String get common_all => 'Tümü';

  @override
  String get common_apply => 'Uygula';

  @override
  String get common_back => 'Geri';

  @override
  String get common_bot => 'Bot';

  @override
  String get common_cancel => 'İptal';

  @override
  String get common_clear => 'Temizle';

  @override
  String get common_close => 'Kapat';

  @override
  String get common_minimize => 'Küçült';

  @override
  String get common_maximize => 'Büyüt';

  @override
  String get common_restore => 'Geri yükle';

  @override
  String get common_custom_id => 'Özel ID';

  @override
  String get common_custom_id_required => 'Özel ID *';

  @override
  String get common_default => 'Varsayılan';

  @override
  String get common_delete => 'Sil';

  @override
  String get common_description => 'Açıklama';

  @override
  String get common_disabled => 'Devre Dışı';

  @override
  String get common_discard => 'Vazgeç';

  @override
  String get common_edit => 'Düzenle';

  @override
  String get common_enabled => 'Etkin';

  @override
  String get common_import => 'İçe Aktar';

  @override
  String get common_key => 'Anahtar';

  @override
  String get common_label => 'Etiket';

  @override
  String get common_manage_workflows => 'İş Akışlarını Yönet';

  @override
  String get common_move_down => 'Aşağı taşı';

  @override
  String get common_move_up => 'Yukarı taşı';

  @override
  String get common_name => 'Ad';

  @override
  String get common_next => 'İleri';

  @override
  String get common_none => 'Yok';

  @override
  String get common_ok => 'Tamam';

  @override
  String get common_operator => 'Operatör';

  @override
  String get common_pick => 'Seç';

  @override
  String get common_placeholder => 'Yer Tutucu';

  @override
  String get common_refresh => 'Yenile';

  @override
  String get common_refresh_workflows => 'İş akışlarını yenile';

  @override
  String get common_remove => 'Kaldır';

  @override
  String get common_required => 'Gerekli';

  @override
  String get common_retry => 'Tekrar Dene';

  @override
  String get common_save => 'Kaydet';

  @override
  String get common_search => 'Ara';

  @override
  String get common_static_options => 'Statik Seçenekler';

  @override
  String get common_style => 'Stil';

  @override
  String get common_type => 'Tür';

  @override
  String get common_url => 'URL';

  @override
  String get common_value => 'Değer';

  @override
  String get common_workflow => 'İş Akışı';

  @override
  String get component_accent_color => 'Vurgu Rengi (Hex, örn. FF0000)';

  @override
  String get component_action_row => 'Eylem Satırı';

  @override
  String get component_add_action_row => 'Eylem Satırı Ekle';

  @override
  String get component_add_button => 'Buton Ekle';

  @override
  String get component_add_button_or_select => 'Buton / Seçim Menüsü Ekle';

  @override
  String get component_add_checkbox_option => 'Onay Kutusu Seçeneği Ekle';

  @override
  String get component_add_child => 'Alt Bileşen Ekle';

  @override
  String get component_add_media_item => 'Medya Öğesi Ekle';

  @override
  String get component_add_radio_option => 'Radyo Seçeneği Ekle';

  @override
  String get component_add_root => 'Kök Bileşen Ekle';

  @override
  String get component_add_text_display => 'Metin Görüntüleme Ekle';

  @override
  String get component_add_tooltip => 'Bileşen Ekle';

  @override
  String get component_block_label_style => 'Stil';

  @override
  String get component_block_workflow => 'İş Akışı';

  @override
  String get component_button_default_label => 'Düğme';

  @override
  String get component_checkbox_options => 'Onay Kutusu Seçenekleri';

  @override
  String get component_checked_by_default => 'Varsayılan olarak işaretli';

  @override
  String get component_choose_color => 'Renk Seç';

  @override
  String get component_component_to_wrap => 'Sarmalanacak Bileşen:';

  @override
  String get component_configure_click_actions =>
      'Tıklama Eylemlerini Yapılandır';

  @override
  String get component_configure_select_actions =>
      'Seçim Eylemlerini Yapılandır';

  @override
  String get component_custom_id => 'Özel ID';

  @override
  String get component_custom_id_required => 'Özel ID *';

  @override
  String get component_default_choice_label => 'Seçim';

  @override
  String get component_default_option_label => 'Seçenek';

  @override
  String get component_disabled_hint =>
      'true/false veya ((user.bc_isVip)) gibi bir değişken girin';

  @override
  String get component_empty_option => 'Boş';

  @override
  String get component_file_url => 'Dosya URL\'si';

  @override
  String get component_label => 'Etiket';

  @override
  String get component_label_title => 'Etiket Başlığı';

  @override
  String get component_markdown_content => 'Markdown İçeriği';

  @override
  String get component_max_selections => 'Maks Seçimler';

  @override
  String get component_media_url => 'Resim / Video URL\'si';

  @override
  String get component_media_urls => 'Medya URL\'leri';

  @override
  String get component_min_selections => 'Min Seçimler';

  @override
  String get component_new_checkbox => 'Yeni Onay Kutusu';

  @override
  String get component_new_option => 'Yeni Seçenek';

  @override
  String get component_new_radio => 'Yeni Radyo';

  @override
  String get component_not_implemented => 'Düzenleyici henüz uygulanmadı';

  @override
  String get component_on_click_workflow => 'Tıklandığında iş akışı';

  @override
  String get component_on_select_workflow => 'Seçildiğinde iş akışı';

  @override
  String get component_options => 'Seçenekler';

  @override
  String get component_pick_accent_color => 'Vurgu Rengi Seç';

  @override
  String get component_placeholder => 'Yer Tutucu';

  @override
  String get component_radio_options => 'Radyo Seçenekleri';

  @override
  String get component_remove_confirm =>
      'Bu bileşen düzenden kaldırılacak. Devam edilsin mi?';

  @override
  String get component_remove_row_title => 'Eylem satırını kaldır';

  @override
  String get component_remove_title => 'Bileşeni kaldır';

  @override
  String get component_section_accessory => 'Aksesuar Düğümü (İsteğe Bağlı)';

  @override
  String get component_section_text_displays => 'Metin Görüntülemeleri';

  @override
  String get component_selection_range => 'Seçim Aralığı';

  @override
  String get component_spacing_large => 'Büyük Boşluk';

  @override
  String get component_spacing_small => 'Küçük Boşluk';

  @override
  String get component_style => 'Stil';

  @override
  String get component_thumbnail_url => 'Küçük Resim URL\'si';

  @override
  String get component_unknown_component => 'Bilinmeyen bileşen';

  @override
  String get component_url => 'URL';

  @override
  String get component_validation_required => 'Gerekli';

  @override
  String get component_value_hint => 'Bileşen değeri ipucu';

  @override
  String get component_visible_divider => 'Görünür Bölücü Çizgi';

  @override
  String get component_workflow_args_hint => 'Örnek: biletId = ((opts.bilet))';

  @override
  String get component_workflow_args_title => 'İş Akışı Çağrı Argümanları';

  @override
  String get component_workflow_click_hint =>
      'Tıklandığında çalıştırılacak kayıtlı iş akışı adı';

  @override
  String get component_workflow_optional => 'İş Akışını Çağır (isteğe bağlı)';

  @override
  String get component_workflow_select_hint =>
      'Seçildiğinde çalıştırılacak kayıtlı iş akışı adı';

  @override
  String get confirm => 'Onayla';

  @override
  String get copy => 'Kopyala';

  @override
  String get create => 'Oluştur';

  @override
  String get dart_editor_empty =>
      'Boş betik — Dart tanılamalarını görmek için yazmaya başlayın.';

  @override
  String get dart_editor_tap_hint => 'Dart düzenleyiciyi açmak için dokunun';

  @override
  String get dart_editor_title => 'Dart Düzenleyici';

  @override
  String get dashboard_analysis_period => 'Analiz dönemi';

  @override
  String dashboard_error(String error) {
    return 'İstatistikler yüklenemedi: $error';
  }

  @override
  String get dashboard_error_rate => 'Hata oranı';

  @override
  String get dashboard_execution_health_title => 'Yürütme sağlığı';

  @override
  String dashboard_executions(int count) {
    return '$count yürütme';
  }

  @override
  String get dashboard_failed_commands => 'Başarısız';

  @override
  String get dashboard_loading => 'İstatistikler yükleniyor...';

  @override
  String get dashboard_no_data =>
      'Henüz komut kullanım verisi yok. İzlemeye başlamak için botunuzu çalıştırın.';

  @override
  String get dashboard_p50_latency => 'Gecikme p50';

  @override
  String get dashboard_p95_latency => 'Gecikme p95';

  @override
  String get dashboard_period_24h => 'Son 24 sa';

  @override
  String get dashboard_period_30d => 'Son 30 gün';

  @override
  String get dashboard_period_7d => 'Son 7 gün';

  @override
  String get dashboard_premium_analytics_desc =>
      'Hata oranı, gecikme yüzdelikleri ve dil içgörülerinin kilidini açın.';

  @override
  String get dashboard_premium_analytics_title => 'Premium analitik';

  @override
  String get dashboard_refresh_sources_tooltip => 'Yürütme sunucularını yenile';

  @override
  String get dashboard_requires_runner =>
      'Komut kullanım istatistiklerini görmek için bir runner\'a bağlanın.';

  @override
  String dashboard_selected_period_total(int count) {
    return 'Seçilen dönemde $count';
  }

  @override
  String get dashboard_single_runner_notice =>
      'Gösterilen istatistikler yalnızca şu anda yapılandırılmış olan runner\'dan alınmıştır. Botları birden fazla runner\'da çalıştırıyorsanız, bu görünüm eksik olabilir.';

  @override
  String get dashboard_timeline => 'Zaman içindeki kullanım';

  @override
  String get dashboard_title => 'Panel';

  @override
  String get dashboard_top_commands => 'En çok kullanılan komutlar';

  @override
  String get dashboard_top_locales => 'En çok kullanılan diller';

  @override
  String get dashboard_total => 'Toplam komut';

  @override
  String get debug_replay_clear => 'Tekrarları temizle';

  @override
  String get debug_replay_clear_confirm =>
      'Kaydedilen tüm tekrarlar silinecek. Devam edilsin mi?';

  @override
  String get debug_replay_clear_title => 'Tekrarları temizle';

  @override
  String get debug_replay_duration_label => 'SÜRE';

  @override
  String get debug_replay_empty_capturing =>
      'Yakalanıyor… Bir tekrar kaydetmek için bir komut çalıştırın.';

  @override
  String get debug_replay_empty_idle =>
      'Yakalama kapalı. Etkinleştirin ve bir tekrar kaydetmek için bir komut çalıştırın.';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Döngü derinliği $depth, yineleme $iteration';
  }

  @override
  String get debug_replay_overview => 'Genel Bakış';

  @override
  String get debug_replay_pause => 'Duraklat';

  @override
  String get debug_replay_play => 'Oynat';

  @override
  String get debug_replay_premium_desc =>
      'Komut yürütmelerinizi adım adım kaydedin ve tekrar oynatın. Her eylemin tam olarak ne yaptığını, ne kadar sürdüğünü ve hataların nerede oluştuğunu görün.';

  @override
  String get debug_replay_premium_title => 'Görsel Hata Ayıklayıcı Tekrarı';

  @override
  String get debug_replay_result_empty => '(sonuç yok)';

  @override
  String get debug_replay_result_label => 'SONUÇ';

  @override
  String get debug_replay_start_capture => 'Yakalamayı etkinleştir';

  @override
  String debug_replay_start_offset(int ms) {
    return 'Başlangıçtan +$ms ms';
  }

  @override
  String get debug_replay_step_back => 'Önceki adım';

  @override
  String get debug_replay_step_first => 'İlk adım';

  @override
  String get debug_replay_step_forward => 'Sonraki adım';

  @override
  String get debug_replay_step_last => 'Son adım';

  @override
  String get debug_replay_stop_capture => 'Yakalamayı devre dışı bırak';

  @override
  String get debug_replay_title => 'Hata Ayıklayıcı Tekrarı';

  @override
  String get debug_replay_variables_empty => '(değişken yok)';

  @override
  String get debug_replay_variables_label => 'DEĞİŞKENLER';

  @override
  String get delete => 'Sil';

  @override
  String get done => 'Bitti';

  @override
  String download_completed(String id) {
    return 'İndirme tamamlandı: $id';
  }

  @override
  String download_failed(String error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String get download_legacy_backup => 'İndirme tamamlandı (eski yedek)';

  @override
  String get drive_legacy_snapshot => 'Eski anlık görüntü';

  @override
  String get drive_manual_backup => 'Manuel yedekleme';

  @override
  String get edit_shell_all_saved => 'Tüm değişiklikler kaydedildi';

  @override
  String get edit_shell_command_body => 'Komut gövdesi';

  @override
  String get edit_shell_command_settings => 'Komut ayarları';

  @override
  String get edit_shell_command_settings_desc =>
      'Meta veriler, kullanılabilirlik, izinler ve klasör yerleşimi.';

  @override
  String get edit_shell_local_draft => 'Yerel taslak';

  @override
  String get edit_shell_local_only => 'Yalnızca yerel';

  @override
  String edit_shell_routes_count(int count) {
    return '$count rota';
  }

  @override
  String get edit_shell_save_changes => 'Değişiklikleri kaydet';

  @override
  String get edit_shell_subtitle =>
      'Ayarlar ve girişler üsttedir. Eylemler ve yanıt aşağıdadır.';

  @override
  String get edit_shell_trigger_inputs => 'Tetikleyici ve Girişler';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Komut seçeneklerini, tetikleyici davranışını ve yürütme modunu ayarlayın.';

  @override
  String get edit_shell_type_command => 'Komut';

  @override
  String get edit_shell_type_legacy => 'Eski komut';

  @override
  String get edit_shell_type_message => 'Mesaj komutu';

  @override
  String get edit_shell_type_slash => 'Eğik çizgi komutu';

  @override
  String get edit_shell_type_user => 'Kullanıcı komutu';

  @override
  String get edit_shell_unsaved => 'Kaydedilmemiş değişiklikler';

  @override
  String get edit_shell_untitled_command => 'Adsız komut';

  @override
  String get editor_sidebar_collapse => 'Kenar çubuğunu daralt';

  @override
  String get editor_sidebar_expand => 'Kenar çubuğunu genişlet';

  @override
  String get embed_add_field => 'Alan Ekle';

  @override
  String get embed_add_section => 'Bölüm Ekle';

  @override
  String get embed_add_tooltip => 'Gömülü mesaj ekle';

  @override
  String get embed_color_picker_title => 'Gömülü mesaj rengi seç';

  @override
  String get embed_delete_confirm =>
      'Bu gömülü mesaj kaldırılacak. Devam edilsin mi?';

  @override
  String get embed_delete_title => 'Gömülü mesajı sil';

  @override
  String embed_empty_message(int max) {
    return 'Gömülü mesaj yok. En fazla $max tane ekleyebilirsiniz.';
  }

  @override
  String get embed_field_delete_confirm =>
      'Bu alan gömülü mesajdan kaldırılacak. Devam edilsin mi?';

  @override
  String get embed_field_delete_title => 'Alanı sil';

  @override
  String embed_field_number(int index) {
    return 'Alan #$index';
  }

  @override
  String get embed_fields_empty => 'Henüz alan yok.';

  @override
  String embed_fields_header(int count) {
    return 'Alanlar ($count/25)';
  }

  @override
  String get embed_label_author_icon => 'Yazar Simge URL\'si';

  @override
  String get embed_label_author_name => 'Yazar Adı';

  @override
  String get embed_label_author_url => 'Yazar URL\'si';

  @override
  String get embed_label_color => 'Renk (int veya #hex)';

  @override
  String get embed_label_dynamic_fields => 'Dinamik Alan Şablonu';

  @override
  String get embed_label_footer_icon => 'Alt Bilgi Simge URL\'si';

  @override
  String get embed_label_footer_text => 'Alt Bilgi Metni';

  @override
  String get embed_label_image_url => 'Resim URL\'si';

  @override
  String get embed_label_inline => 'Satır içi (Inline)';

  @override
  String get embed_label_thumbnail_url => 'Küçük Resim URL\'si';

  @override
  String get embed_label_timestamp => 'Zaman Damgası (ISO8601)';

  @override
  String get embed_checkbox_current_timestamp => 'Güncel Zaman Damgası';

  @override
  String get embed_hint_timestamp =>
      'Komut çalıştırıldığında güncel saati gösterir. Metinde Unix saniyesi için mesaj alanlarında ((timestamp)) kullanın.';

  @override
  String get embed_label_title => 'Başlık';

  @override
  String get embed_label_url => 'URL';

  @override
  String embed_number(int index) {
    return 'Gömülü Mesaj #$index';
  }

  @override
  String embed_response_header(int count, int max) {
    return 'Yanıt Gömülü Mesajları ($count/$max)';
  }

  @override
  String get embed_section_author => 'Yazar';

  @override
  String get embed_section_color => 'Renk';

  @override
  String get embed_section_dynamic_fields => 'Dinamik Alanlar';

  @override
  String get embed_section_fields => 'Alanlar';

  @override
  String get embed_section_footer => 'Alt Bilgi (Footer)';

  @override
  String get embed_section_media => 'Medya';

  @override
  String get embed_section_timestamp => 'Zaman Damgası';

  @override
  String emojis_delete_confirm_body(String name) {
    return ':$name: silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get emojis_delete_confirm_title => 'Emoji Sil';

  @override
  String emojis_delete_error(String error) {
    return 'Silme başarısız: $error';
  }

  @override
  String get emojis_delete_tooltip => 'Sil';

  @override
  String get emojis_empty =>
      'Henüz emoji yok. Başlamak için bir tane yükleyin.';

  @override
  String get emojis_loading_error => 'Emojiler yüklenemedi';

  @override
  String emojis_rename_error(String error) {
    return 'Ad değiştirme başarısız: $error';
  }

  @override
  String get emojis_rename_hint => 'Yeni ad';

  @override
  String get emojis_rename_title => 'Emoji Adını Değiştir';

  @override
  String get emojis_rename_tooltip => 'Yeniden Adlandır';

  @override
  String get emojis_tab => 'Emojiler';

  @override
  String get emojis_tab_short => 'Emoji';

  @override
  String get emojis_title => 'Uygulama Emojileri';

  @override
  String get emojis_upload => 'Emoji Yükle';

  @override
  String emojis_upload_error(String error) {
    return 'Yükleme başarısız: $error';
  }

  @override
  String get emojis_upload_name_hint => 'Emoji adı (harfler, sayılar, _)';

  @override
  String get emojis_upload_pick_image => 'Resim Seç';

  @override
  String get error => 'Hata';

  @override
  String get error_delete_messages_failed => 'Mesajlar silinemedi.';

  @override
  String get error_invalid_channel_type => 'Kanal bir metin kanalı değil.';

  @override
  String get error_invalid_count => 'Sayı 0\'dan büyük olmalıdır.';

  @override
  String get error_network_timeout =>
      'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin.';

  @override
  String error_with_details(String error) {
    return 'Hata: $error';
  }

  @override
  String get export_button => 'ZIP Dışa Aktar';

  @override
  String get export_commands => 'Komutlar';

  @override
  String export_failed(String error) {
    return 'Dışa aktarma başarısız: $error';
  }

  @override
  String get export_file_picker_busy => 'Dosya seçici zaten açık';

  @override
  String get export_global_variables => 'Genel Değişkenler';

  @override
  String get export_import_title => 'Dışa Aktar / İçe Aktar';

  @override
  String get export_section_desc =>
      'Botunuzun seçili bölümlerini bir ZIP dosyası olarak dışa aktarın. Bot jetonu asla dahil edilmez.';

  @override
  String get export_section_title => 'Dışa Aktar';

  @override
  String get export_status => 'Durum ve Etkinlikler';

  @override
  String get export_workflows => 'İş Akışları';

  @override
  String get globals_add => 'Değişken Ekle';

  @override
  String get globals_add_global => 'Genel Değişken Ekle';

  @override
  String get globals_add_scoped => 'Kapsamlı Değişken Ekle';

  @override
  String get globals_copy_value => 'Değeri kopyala';

  @override
  String globals_delete_confirm(String key) {
    return '\"$key\" silinsin mi?';
  }

  @override
  String get globals_delete_title => 'Değişkeni Sil';

  @override
  String get globals_dialog_global_desc =>
      'Genel değişkenler tüm komutlar ve sunucular arasında paylaşılır.';

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Kullanım: \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Kapsamlı bir değişken, $scope bağlamı başına ayrı bir değer saklar.';
  }

  @override
  String get globals_edit => 'Değişkeni Düzenle';

  @override
  String get globals_edit_global => 'Genel Değişkeni Düzenle';

  @override
  String get globals_edit_scoped => 'Kapsamlı Değişkeni Düzenle';

  @override
  String get globals_empty => 'Henüz genel değişken yok';

  @override
  String get globals_empty_subtitle =>
      'Tüm komutlar tarafından erişilebilen kalıcı verileri saklamak için bir değişken ekleyin.';

  @override
  String get globals_help_global =>
      'Tüm komutlar arasında paylaşılır. \$getVar[anahtar] ile erişin.';

  @override
  String get globals_help_scoped =>
      'Bağlam başına saklanır (sunucu, kullanıcı, kanal…). Her giriş Discord bağlamı başına ayrı bir değer tutar.';

  @override
  String get globals_key => 'Anahtar';

  @override
  String get globals_key_hint => 'örn. prefix, level, welcome_message';

  @override
  String get globals_mode_global => 'Genel';

  @override
  String get globals_mode_scoped => 'Kapsamlı';

  @override
  String get globals_no_default => 'Varsayılan değer yok';

  @override
  String get globals_refresh => 'Yenile';

  @override
  String get globals_retry => 'Tekrar Dene';

  @override
  String get globals_scope_channel => 'kanal';

  @override
  String get globals_scope_guild => 'sunucu';

  @override
  String get globals_scope_guildMember => 'Sunucu üyesi';

  @override
  String get globals_scope_message => 'mesaj';

  @override
  String get globals_scope_user => 'Global kullanıcı';

  @override
  String get globals_search => 'Değişkenlerde ara…';

  @override
  String get globals_source_local => 'Yerel';

  @override
  String globals_source_runner(String name) {
    return 'Çalıştırıcı: $name';
  }

  @override
  String get globals_tab => 'Geneller';

  @override
  String get globals_tab_short => 'Değiş';

  @override
  String get globals_title => 'Değişkenler';

  @override
  String get globals_scope_global => 'Whole bot';

  @override
  String get globals_audience_title => 'Who is this variable for?';

  @override
  String get globals_audience_global_desc =>
      'A single value for the whole bot (e.g. the number of commands run).';

  @override
  String get globals_audience_guild_desc =>
      'One value per server (e.g. the server prefix).';

  @override
  String get globals_audience_guildMember_desc =>
      'One value per member and per server (e.g. their warnings or XP on this server).';

  @override
  String get globals_audience_user_desc =>
      'One value per user, shared across all servers (e.g. their profile).';

  @override
  String get globals_audience_channel_desc =>
      'One value per channel (e.g. the channel mode).';

  @override
  String get globals_audience_message_desc =>
      'One value per message (e.g. the votes on a message).';

  @override
  String get globals_section_global => 'Whole bot';

  @override
  String get globals_section_scoped => 'Per server, member…';

  @override
  String get globals_value => 'Değer';

  @override
  String get globals_value_auto_type_hint =>
      'Değer otomatik tiplidir (sayı, boolean, JSON).';

  @override
  String get guilds_empty_state =>
      'Bot hiçbir sunucuda değil.\nBurada görmek için bir sunucuya davet edin.';

  @override
  String guilds_leave_confirm(String name) {
    return '\"$name\" sunucusundan ayrılsın mı?\nBot bu sunucudan kaldırılacak. Daha sonra Discord geliştirici portalından tekrar davet edebilirsiniz.';
  }

  @override
  String guilds_leave_failed(String error) {
    return 'Ayrılma başarısız oldu: $error';
  }

  @override
  String get guilds_leave_title => 'Sunucudan Ayrıl';

  @override
  String get guilds_leave_tooltip => 'Ayrıl';

  @override
  String guilds_left_success(String name) {
    return '\"$name\" sunucusundan ayrılındı.';
  }

  @override
  String guilds_members_count_other(int count) {
    return '~$count üye';
  }

  @override
  String get guilds_owner_label => '👑 Sahip';

  @override
  String guilds_server_count_other(int count) {
    return '$count sunucu';
  }

  @override
  String get guilds_tab => 'Sunucular';

  @override
  String get guilds_tab_short => 'Sunucular';

  @override
  String get hint_use_variables =>
      'Gerekiyorsa değişkenleri/şablonları kullanın';

  @override
  String get home_add_time => 'Zaman Ekle';

  @override
  String get home_add_time_mobile_only =>
      'Ödüllü reklamlar mobil uygulamada izlenir; kazanılan süre her yerde geçerlidir.';

  @override
  String get home_hosting_unlimited_overline => 'Barındırma dahil';

  @override
  String get home_hosting_unlimited_headline => 'Aboneliğinle sınırsız';

  @override
  String get home_hosting_remaining_overline => 'Kalan süre';

  @override
  String get home_overline => 'PROJELERİM';

  @override
  String get home_create_bot_title => 'Bot oluştur';

  @override
  String get home_create_bot_subtitle => 'Discord botun iki tıkta';

  @override
  String home_active_on_servers_one(int count) {
    return '$count sunucuda aktif';
  }

  @override
  String home_active_on_servers_other(int count) {
    return '$count sunucuda aktif';
  }

  @override
  String get home_synced_active => 'Senkron ve aktif';

  @override
  String get home_empty_support_btn => 'Discord Desteği';

  @override
  String get home_empty_support_hint =>
      'Yardıma mı ihtiyacınız var? Topluluğumuza katılın!';

  @override
  String get home_foreground_service_not_started =>
      'Ön plan hizmeti başlamadı.';

  @override
  String get home_hosting_expired => 'Barındırma süresi doldu';

  @override
  String home_hosting_time_left(String time) {
    return 'Kalan Barındırma: $time';
  }

  @override
  String home_hosting_banked(String time) {
    return 'Yedek: $time';
  }

  @override
  String home_hosting_expires_today(String time) {
    return 'Bugün saat $time sona eriyor';
  }

  @override
  String home_hosting_expires_tomorrow(String time) {
    return 'Yarın saat $time sona eriyor';
  }

  @override
  String get home_hosting_time_preserved =>
      'Bot durdurulduğu sürece süre korunur.';

  @override
  String get home_hosting_time_preserved_overline => 'Süre korunuyor';

  @override
  String get home_hosting_expiration_expected => 'Beklenen bitiş';

  @override
  String home_hosting_expires_at(String date, String time) {
    return '$date saat $time';
  }

  @override
  String get home_hosting_status_active_short => 'Aktif oturum';

  @override
  String get home_hosting_status_paused_short => 'Yedek süre';

  @override
  String get home_hosting_total => 'Toplam süre';

  @override
  String get home_hosting_status_active => 'Aktif oturum (çevrimiçi)';

  @override
  String get home_hosting_status_paused => 'Yedek süre (duraklatıldı)';

  @override
  String get home_hosting_ad_history => 'Reklam Geçmişi';

  @override
  String get home_hosting_ad_rewards_history_title => 'Reklam Ödülleri Geçmişi';

  @override
  String get home_hosting_ad_history_error => 'Reklam geçmişi yüklenemedi';

  @override
  String get home_hosting_ad_history_empty =>
      'Bu bot için kayıtlı yakın tarihli reklam ödülü yok.';

  @override
  String get home_log_desktop_stop_requested => 'Masaüstü bot durdurma istendi';

  @override
  String get home_log_start_requested => 'Bot başlatma istendi';

  @override
  String get home_log_stop_requested => 'Bot durdurma istendi';

  @override
  String get home_logs_tooltip => 'Günlükleri Görüntüle';

  @override
  String get home_manage => 'Yönet';

  @override
  String get home_notification_permission_required =>
      'Botu başlatmak için bildirim izni gereklidir.';

  @override
  String home_server_count_one(int count) {
    return '$count sunucu';
  }

  @override
  String home_server_count_other(int count) {
    return '$count sunucu';
  }

  @override
  String get home_start => 'Başlat';

  @override
  String bot_start_target_title(String bot) {
    return '$bot nerede başlatılsın?';
  }

  @override
  String get bot_start_local_title => 'Yerel olarak başlat (bu cihaz)';

  @override
  String get bot_start_local_desc =>
      'Ücretsiz, hiçbir şey tüketmez. Uygulamayı kapatırsan bot durur.';

  @override
  String get bot_start_server_title => 'Bot Creator Server\'da başlat';

  @override
  String get bot_start_server_desc =>
      'Barındırma dakikalarını tüketir (PREMIUM ile sınırsız). Bot cihazın olmadan çalışır.';

  @override
  String get bot_start_server_reason_platform =>
      'Bu cihaz uzaktan barındırmayı yönetemez.';

  @override
  String get bot_start_server_reason_no_account =>
      'Bu cihazda bağlı hesap yok.';

  @override
  String get bot_start_server_reason_cloud_disabled =>
      'Bu sunucuda bulut barındırma etkin değil.';

  @override
  String get bot_start_server_reason_no_minutes =>
      'Barındırma dakikan kalmadı: mobil uygulamadan bir reklam izle veya PREMIUM\'a geç.';

  @override
  String get home_start_ads => 'Başlat (Reklam İzle)';

  @override
  String get home_start_premium => 'Başlat (Premium)';

  @override
  String get home_status_offline => 'Çevrimdışı';

  @override
  String get home_status_online => 'Çevrimiçi';

  @override
  String get home_stop => 'Durdur';

  @override
  String get home_sync_failed => 'Senkronizasyon başarısız';

  @override
  String get home_tab => 'Ana Sayfa';

  @override
  String get home_time_added => 'Zaman başarıyla eklendi';

  @override
  String home_token_missing(String botName) {
    return '$botName için jeton bulunamadı';
  }

  @override
  String get home_unknown_app => 'Bilinmeyen';

  @override
  String get image_editor_create => 'Oluştur';

  @override
  String get image_editor_create_canvas => 'Görüntü Tuvali Oluştur';

  @override
  String image_editor_edit_canvas(int count) {
    return 'Tuvali Düzenle ($count işlem)';
  }

  @override
  String get image_editor_open => 'Düzenleyiciyi Aç';

  @override
  String get import_button => 'İçe Aktar';

  @override
  String import_failed(String error) {
    return 'İçe aktarma başarısız: $error';
  }

  @override
  String get import_nothing => 'Hiçbir şey içe aktarılmadı.';

  @override
  String get import_overwrite => 'Üzerine yaz';

  @override
  String import_parse_failed(String error) {
    return 'ZIP ayrıştırılamadı: $error';
  }

  @override
  String get import_pick_file => 'ZIP dosyası seç';

  @override
  String get import_section_desc =>
      'Daha önce dışa aktarılan bir ZIP dosyasını içe aktarın. Çakışmalar öğe başına çözülebilir.';

  @override
  String get import_section_title => 'İçe Aktar';

  @override
  String get import_skip => 'Atla';

  @override
  String import_summary_commands_imported(int count) {
    return '$count komut içe aktarıldı';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count komut atlandı';
  }

  @override
  String get import_summary_status_imported => 'durum içe aktarıldı';

  @override
  String get import_summary_variables_imported => 'değişkenler içe aktarıldı';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count iş akışı içe aktarıldı';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count iş akışı atlandı';
  }

  @override
  String js_diag_unclosed_opening(String opening, String line) {
    return 'Kapatılmamış “$opening”, $line. satırda açıldı.';
  }

  @override
  String js_diag_unexpected_closing(String closing) {
    return 'Beklenmeyen kapanış “$closing”.';
  }

  @override
  String get js_diag_unterminated_comment => 'Kapatılmamış blok yorumu.';

  @override
  String get js_diag_unterminated_string => 'Kapatılmamış dize sabiti.';

  @override
  String get js_diag_unterminated_template => 'Kapatılmamış şablon sabiti.';

  @override
  String get js_editor_auto_indent => '• Enter ile akıllı otomatik girinti';

  @override
  String get js_editor_hint => '// JavaScript bot komutunuzu buraya yazın...';

  @override
  String get js_editor_diagnostics_clean => 'Sözdizimi sorunu bulunamadı.';

  @override
  String get js_editor_empty =>
      'Boş betik — tanıları görmek için yazmaya başlayın.';

  @override
  String get js_editor_includes => 'İçerir:';

  @override
  String get js_editor_indent_guides => '• Canlı girinti kılavuzları';

  @override
  String get js_editor_quick_keys =>
      '• JavaScript sembolleri için mobil hızlı tuşlar';

  @override
  String get js_editor_segmented_label => 'JS';

  @override
  String get js_editor_subtitle => 'Bu komut için özel JavaScript yazın';

  @override
  String get js_editor_title => 'JavaScript Düzenleyici';

  @override
  String get js_editor_ux_title => 'Düzenleyici UX';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return '\"$command\" komutu için BDFD betiği çalıştırılamadı: $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'messageCreate\'den gelen komutları <on_ek><komut> kullanarak işler.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Konumsal seçenekleri kullanır (örnek: !config #kanal).';

  @override
  String get legacy_prefix_mode_title => 'Eski Ön Ek Modu';

  @override
  String get legacy_prefix_override_hint =>
      'Örnek: ? veya ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label =>
      'Ön ek geçersiz kılma (isteğe bağlı)';

  @override
  String get legacy_response_banner_body =>
      'Bazı komutlar hâlâ eski yanıt biçimini kullanıyor. Yeni biçimi etkinleştirmek için düzenleyicide açın ve yeniden kaydedin.';

  @override
  String get legacy_response_banner_dismiss => 'Kapat';

  @override
  String get legacy_response_banner_migrate => 'Hepsini geçir';

  @override
  String get legacy_response_banner_migrate_failed => 'Geçirme başarısız';

  @override
  String legacy_response_banner_migrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komut geçirildi',
      one: '1 komut geçirildi',
    );
    return '$_temp0';
  }

  @override
  String get legacy_response_banner_migrated_none => 'Geçirilecek komut yok';

  @override
  String get legacy_response_banner_migrating => 'Geçiriliyor...';

  @override
  String get legacy_response_banner_short_body =>
      'Yeni biçime geçmek için komutlarınızı açın ve yeniden kaydedin.';

  @override
  String get legacy_response_banner_short_title => 'Komut güncellemesi mevcut';

  @override
  String get legacy_response_banner_title => 'Komut yanıt biçimi güncellemesi';

  @override
  String get legacy_response_mode_label => 'Eski yanıt modu';

  @override
  String get local_command_awaited_desc =>
      'Beklenen geri arama ön ayarları, dahili çalışma zamanı geri aramaları oldukları için yerel kalır.';

  @override
  String get local_command_desc =>
      'Komutu yalnızca Bot Creator\'da saklayın. BDFD \$registerGuildCommands kullanarak belirli sunuculara dinamik olarak kaydedebilirsiniz.';

  @override
  String get local_command_title => 'Yerel Komut (Discord\'a kaydetme)';

  @override
  String logs_runner_source(String name) {
    return 'Günlüklerin kaynağı: $name';
  }

  @override
  String get marketplace_about => 'Hakkında';

  @override
  String get marketplace_add => 'Ekle';

  @override
  String get marketplace_api_unavailable => 'API istemcisi kullanılamıyor';

  @override
  String get marketplace_apply => 'Şablonu uygula';

  @override
  String marketplace_apply_error(Object error) {
    return 'Uygulama başarısız: $error';
  }

  @override
  String get marketplace_apply_success => 'Şablon başarıyla uygulandı!';

  @override
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  ) {
    return '$addedCount komut eklendi, $skippedCount atlandı (yinelenen).';
  }

  @override
  String get marketplace_applying => 'Uygulanıyor...';

  @override
  String marketplace_by_author(Object author, Object version) {
    return '$author tarafından · v$version';
  }

  @override
  String get marketplace_cancel => 'İptal';

  @override
  String marketplace_command_preview_actions(Object count) {
    return '$count eylem';
  }

  @override
  String get marketplace_command_preview_no_actions => 'Eylem yok';

  @override
  String marketplace_command_preview_options(Object count) {
    return '$count seçenek';
  }

  @override
  String get marketplace_command_preview_type_message => 'Mesaj bağlam menüsü';

  @override
  String get marketplace_command_preview_type_slash => 'Eğik çizgi komutu';

  @override
  String get marketplace_command_preview_type_user => 'Kullanıcı bağlam menüsü';

  @override
  String marketplace_commands_label(Object count) {
    return 'Komutlar ($count)';
  }

  @override
  String get marketplace_config_hint =>
      'Bu şablonu uygulamadan önce gerekli değerleri doldurun.';

  @override
  String get marketplace_config_required => 'Yapılandırma Gerekli';

  @override
  String marketplace_conflict_apply_choice(Object count) {
    return 'Uygula ($count şablon)';
  }

  @override
  String get marketplace_conflict_keep_local => 'Yereli Koru';

  @override
  String marketplace_conflict_local_info(Object count) {
    return 'Yerel ($count eylem)';
  }

  @override
  String get marketplace_conflict_subtitle =>
      'Bazı şablon komutları zaten mevcut. Hangi sürümü korumak istediğinizi seçin:';

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'Şablon ($count eylem)';
  }

  @override
  String get marketplace_conflict_title => 'Komut Çakışmaları';

  @override
  String get marketplace_conflict_use_template => 'Şablonu Kullan';

  @override
  String get marketplace_connect_discord => 'Discord ile bağlan';

  @override
  String get marketplace_connect_manager =>
      'Pazar Yerine erişmek için Manager\'a bağlan.';

  @override
  String get marketplace_connect_publish =>
      'Şablon yayınlamak için Manager\'a bağlan.';

  @override
  String marketplace_count(Object count) {
    return '$count şablon';
  }

  @override
  String get marketplace_delete => 'Sil';

  @override
  String marketplace_delete_confirm(Object name) {
    return '\"$name\" şablonunu silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get marketplace_delete_confirm_title => 'Şablonu Sil';

  @override
  String get marketplace_delete_success => 'Şablon silindi.';

  @override
  String get marketplace_edit => 'Düzenle';

  @override
  String get marketplace_edit_hint =>
      'Düzenlemek için botunuzun komut listesinden aynı adla yeniden yayınlayın.';

  @override
  String get marketplace_empty => 'Henüz şablon yok.\nİlk yayınlayan sen ol!';

  @override
  String marketplace_load_error(Object error) {
    return 'Yükleme başarısız: $error';
  }

  @override
  String get marketplace_login_hint =>
      'Pazar Yerine erişmek için Discord hesabınızı bağlamalısınız.';

  @override
  String get marketplace_login_instructions =>
      'Pazar Yerini kullanmaya devam etmek için lütfen Discord ile kimlik doğrulayın.';

  @override
  String get marketplace_login_required => 'Discord bağlantısı gerekli';

  @override
  String get marketplace_login_success => 'Discord başarıyla bağlandı!';

  @override
  String get marketplace_login_title => 'Manager\'a bağlan';

  @override
  String marketplace_more(Object count) {
    return '+$count daha';
  }

  @override
  String get marketplace_my_templates => 'Şablonlarım';

  @override
  String marketplace_no_results(Object query) {
    return '\"$query\" ile eşleşen şablon yok';
  }

  @override
  String get marketplace_no_variables => 'Genel değişken tanımlanmamış.';

  @override
  String get marketplace_publish_add_variable => 'Değişken ekle';

  @override
  String get marketplace_publish_add_variable_title => 'Değişken Ekle';

  @override
  String get marketplace_publish_back => 'Geri';

  @override
  String get marketplace_publish_button => 'Yayınla';

  @override
  String get marketplace_publish_category_hint => 'örn: ai, moderation, fun';

  @override
  String get marketplace_publish_category_label => 'Kategori';

  @override
  String marketplace_publish_commands(Object count) {
    return 'Komutlar ($count)';
  }

  @override
  String get marketplace_publish_desc_hint =>
      'Pazar yerinde gösterilen tek satırlık özet';

  @override
  String get marketplace_publish_desc_label => 'Kısa açıklama';

  @override
  String get marketplace_publish_desc_long_hint =>
      'Detaylı kullanım talimatları, markdown desteklenir...';

  @override
  String get marketplace_publish_desc_long_label =>
      'Tam dokümantasyon (isteğe bağlı)';

  @override
  String get marketplace_publish_deselect_all => 'Tümünü kaldır';

  @override
  String marketplace_publish_error(Object error) {
    return 'Yayınlama başarısız: $error';
  }

  @override
  String get marketplace_publish_metadata => 'Şablon Detayları';

  @override
  String get marketplace_publish_metadata_hint =>
      'Başkalarının bulup kullanabilmesi için şablonunu tanımla.';

  @override
  String get marketplace_publish_name_hint => 'örn: Yapay Zeka Moderasyon Botu';

  @override
  String get marketplace_publish_name_label => 'Şablon adı';

  @override
  String get marketplace_publish_next => 'İleri';

  @override
  String get marketplace_publish_no_content =>
      'Yayınlanacak komut veya iş akışı yok.\nÖnce biraz oluştur!';

  @override
  String get marketplace_publish_required_fields =>
      'Lütfen yayınlamadan önce tüm zorunlu alanları doldurun (Ad, Kısa açıklama, Sürüm).';

  @override
  String get marketplace_publish_select => 'İçeriği seç';

  @override
  String get marketplace_publish_select_all => 'Tümünü seç';

  @override
  String get marketplace_publish_select_hint =>
      'Komutları, iş akışlarını veya her ikisini seç.';

  @override
  String get marketplace_publish_success => 'Şablon başarıyla yayınlandı!';

  @override
  String get marketplace_publish_summary => 'Şablon Özeti';

  @override
  String get marketplace_publish_tags_hint =>
      'örn: openai, chatbot, moderation';

  @override
  String get marketplace_publish_tags_label => 'Etiketler (virgülle ayrılmış)';

  @override
  String get marketplace_publish_title => 'Şablon Yayınla';

  @override
  String get marketplace_publish_user_must_define =>
      'Kullanıcı bu değeri tanımlamalı';

  @override
  String get marketplace_publish_user_must_define_hint =>
      'Kullanıcıdan uygulamadan önce bu değeri girmesi istenecek';

  @override
  String get marketplace_publish_variable_desc_hint => 'Bu değişken ne için';

  @override
  String get marketplace_publish_variable_desc_label => 'Açıklama';

  @override
  String get marketplace_publish_variable_name_hint => 'örn: TOKEN_OPENAI';

  @override
  String get marketplace_publish_variable_name_label => 'Değişken adı';

  @override
  String get marketplace_publish_variables => 'Genel Değişkenler';

  @override
  String get marketplace_publish_variables_hint =>
      'Değişkenleri ekle ve kullanıcının doldurması gerekenleri işaretle.';

  @override
  String get marketplace_publish_version_label => 'Sürüm';

  @override
  String marketplace_publish_workflows(Object count) {
    return 'İş Akışları ($count)';
  }

  @override
  String get marketplace_publishing => 'Yayınlanıyor...';

  @override
  String get marketplace_rate_success => 'Değerlendirme gönderildi!';

  @override
  String get marketplace_rate_title => 'Bu şablonu değerlendir';

  @override
  String get marketplace_retry => 'Tekrar dene';

  @override
  String get marketplace_search_hint => 'Şablonlarda ara...';

  @override
  String get marketplace_title => 'Pazar Yeri';

  @override
  String marketplace_variable_required(Object name) {
    return '$name zorunludur';
  }

  @override
  String get marketplace_variables_label =>
      'Önceden Yapılandırılmış Değişkenler';

  @override
  String marketplace_workflows_label(Object count) {
    return 'İş Akışları ($count)';
  }

  @override
  String get modal_add_text_input => 'Metin Girişi Ekle';

  @override
  String get modal_builder_title => 'Modal Oluşturucu';

  @override
  String get modal_custom_id_hint => 'Bu modalı tanımlamak için kullanılır';

  @override
  String get modal_custom_id_label => 'Özel ID';

  @override
  String get modal_default_value => 'Varsayılan değer';

  @override
  String modal_field_default_label(int index) {
    return 'Alan $index';
  }

  @override
  String modal_input_index(int index) {
    return 'Giriş $index';
  }

  @override
  String modal_inputs_count(int count) {
    return '$count/5 giriş';
  }

  @override
  String get modal_remove_field_confirm =>
      'Bu alan modaldan kaldırılacak. Devam edilsin mi?';

  @override
  String get modal_remove_field_title => 'Modal alanını kaldır';

  @override
  String get modal_style => 'Stil:';

  @override
  String get modal_title_label => 'Modal Başlığı';

  @override
  String get modal_workflow_submit =>
      'Gönderildiğinde çalışacak iş akışı (isteğe bağlı)';

  @override
  String get more_options_title => 'Diğer Seçenekler';

  @override
  String get more_tab => 'Daha Fazla';

  @override
  String get nav_webhooks => 'Webhooklar';

  @override
  String get nav_webhooks_compact => 'Hooklar';

  @override
  String get no_more_options => 'Başka seçenek yok';

  @override
  String notion_create_workflow_from_query(String query) {
    return '\"$query\" iş akışını oluştur';
  }

  @override
  String get notion_filter_add => 'Filtre Ekle';

  @override
  String get notion_filter_type => 'Tür';

  @override
  String get ok => 'Tamam';

  @override
  String get onboarding_command_button => 'Devam Et';

  @override
  String get onboarding_command_desc => 'İlk komutunuzu oluşturun';

  @override
  String get onboarding_command_example =>
      'Örnek:\n/hello → Bot \"Merhaba! 👋\" yanıtını verir';

  @override
  String get onboarding_command_learn => 'Komutların nasıl çalıştığını öğrenin';

  @override
  String get onboarding_command_text =>
      'Komutlar botunuzun kalbidir. Kullanıcıların Discord üzerinden botunuzla etkileşime girmesini sağlarlar.';

  @override
  String get onboarding_command_title => 'Adım 2: Bir Komut Ekleyin';

  @override
  String get onboarding_create_button => 'Devam Et';

  @override
  String get onboarding_create_desc => 'Discord jetonunuzu (token) alın';

  @override
  String get onboarding_create_open_portal =>
      'Discord Geliştirici Portalı\'nı aç';

  @override
  String get onboarding_create_steps =>
      '1. Discord Geliştirici Portalı\'na gidin\n2. Yeni bir uygulama oluşturun\n3. Bot jetonunu kopyalayın\n4. Aşağıya yapıştırın';

  @override
  String get onboarding_create_tip =>
      '💡 İpucu: Jetonunuzu asla paylaşmayın! Botunuza tam erişim sağlar.';

  @override
  String get onboarding_create_title => 'Adım 1: Bir Bot Oluşturun';

  @override
  String get onboarding_create_tutorial => 'Eğitim: Jeton nasıl alınır';

  @override
  String get onboarding_remind_later => 'Daha sonra hatırlat';

  @override
  String get onboarding_skip_confirm => 'Tanıtımı atla';

  @override
  String get onboarding_skip_dialog_desc =>
      'Bir sonraki sefer kaldığınız yerden devam edebilir veya turu tamamen atlayabilirsiniz.';

  @override
  String get onboarding_skip_dialog_title => 'Tanıtımdan çıkılsın mı?';

  @override
  String get onboarding_start_button => 'Devam Et';

  @override
  String get onboarding_start_desc => 'Botunuzu yayınlayın!';

  @override
  String get onboarding_start_hint =>
      'Botunu oluşturduktan sonra, uygulamadaki bot kartında Başlat düğmesini bulacaksın.';

  @override
  String get onboarding_start_text =>
      'Bot kartınızdaki \"Başlat\" düğmesine tıklayın. Ardından komutunuzu Discord\'da test edin!';

  @override
  String get onboarding_start_tip =>
      '✨ Harika! İlk Discord botunuzu oluşturdunuz. Şimdi daha fazla komut ekleyebilir ve özelleştirebilirsiniz!';

  @override
  String get onboarding_start_title => 'Adım 3: Botu Başlatın';

  @override
  String onboarding_step_indicator(int current, int total) {
    return 'Adım $current / $total';
  }

  @override
  String get onboarding_success_button => 'Başla!';

  @override
  String get onboarding_success_desc => 'Discord botunuz kullanıma hazır!';

  @override
  String get onboarding_success_tip1 => 'Daha fazla komut ekle';

  @override
  String get onboarding_success_tip2 => 'İş akışları oluştur';

  @override
  String get onboarding_success_tip3 => 'Verilerini yedekle';

  @override
  String get onboarding_success_title => 'Tebrikler! 🎉';

  @override
  String get onboarding_success_whatsnext => 'Sırada ne var?';

  @override
  String get onboarding_welcome_desc =>
      '3 basit adımda ilk Discord botunuzu oluşturun. Her adımda size rehberlik edeceğiz.';

  @override
  String get onboarding_welcome_skip => 'Atla';

  @override
  String get onboarding_welcome_start => 'Başla';

  @override
  String get onboarding_welcome_title => 'Bot Creator\'a Hoş Geldiniz';

  @override
  String get option_add_choice => 'Seçim Ekle';

  @override
  String get option_add_localizations => 'Yerelleştirme Ekle';

  @override
  String get option_choice_delete_confirm =>
      'Bu seçim kaldırılacak. Devam edilsin mi?';

  @override
  String get option_choice_delete_title => 'Seçimi sil';

  @override
  String get option_choice_name => 'Seçim Adı';

  @override
  String option_choice_number(int index) {
    return 'Seçim $index';
  }

  @override
  String get option_choice_value => 'Seçim Değeri';

  @override
  String option_default_name(int index) {
    return 'Seçenek $index';
  }

  @override
  String get option_delete_argument_confirm =>
      'Bu argüman kaldırılacak. Devam edilsin mi?';

  @override
  String get option_delete_argument_title => 'Argümanı sil';

  @override
  String get option_delete_choice_confirm =>
      'Bu seçim kaldırılacak. Devam edilsin mi?';

  @override
  String get option_delete_choice_title => 'Seçeneği sil';

  @override
  String get option_delete_confirm =>
      'Bu seçenek kaldırılacak. Devam edilsin mi?';

  @override
  String get option_delete_localization_confirm =>
      'Bu yerelleştirme girişi kaldırılacak. Devam edilsin mi?';

  @override
  String get option_delete_localization_title => 'Yerelleştirmeyi sil';

  @override
  String get option_delete_title => 'Seçeneği sil';

  @override
  String get option_desc_required => 'Lütfen seçenek için bir açıklama girin';

  @override
  String option_label_number(int index) {
    return 'Etiket $index';
  }

  @override
  String get option_localized_description => 'Yerelleştirilmiş Açıklama';

  @override
  String get option_localized_name => 'Yerelleştirilmiş Ad';

  @override
  String get option_max_value => 'Maksimum Değer';

  @override
  String get option_min_value => 'Minimum Değer';

  @override
  String get option_name_duplicate => 'Bu ad bu seviyede zaten kullanılıyor';

  @override
  String get option_name_invalid_chars =>
      'Seçenek adları 1-32 küçük harf karakter olmalıdır. İzin verilenler: harfler, rakamlar, tire, alt çizgi ve kesme işareti.';

  @override
  String get option_name_invalid_start =>
      'Seçenek adı desteklenmeyen bir karakterle başlıyor';

  @override
  String get option_name_max_length =>
      'Seçenek adı en fazla 32 karakter uzunluğunda olmalıdır';

  @override
  String get option_name_required => 'Lütfen seçenek için bir ad girin';

  @override
  String get option_select_language => 'Dil Seç';

  @override
  String option_static_label_n(int index) {
    return 'Etiket $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Değer $index';
  }

  @override
  String get option_subcommand_options => 'Alt Komut Seçenekleri';

  @override
  String get option_subcommands => 'Alt Komutlar';

  @override
  String get option_type_attachment => 'Ek';

  @override
  String get option_type_boolean => 'Mantıksal (Boolean)';

  @override
  String get option_type_channel => 'Kanal';

  @override
  String get option_type_integer => 'Tam Sayı';

  @override
  String get option_type_mentionable => 'Bahsedilebilir';

  @override
  String get option_type_number => 'Sayı';

  @override
  String get option_type_role => 'Rol';

  @override
  String get option_type_string => 'Metin';

  @override
  String get option_type_subcommand => 'Alt Komut';

  @override
  String get option_type_subcommand_group => 'Alt Komut Grubu';

  @override
  String get option_type_unknown => 'Bilinmeyen';

  @override
  String get option_type_user => 'Kullanıcı';

  @override
  String option_value_number(int index) {
    return 'Değer $index';
  }

  @override
  String get premium_active_desc =>
      'Desteğiniz için teşekkür ederiz! Tüm reklamlar devre dışı bırakıldı.';

  @override
  String get premium_active_title => 'Premium aktif';

  @override
  String get premium_card_button => 'Planları gör';

  @override
  String get premium_locked_hint =>
      'Hesabın ücretsiz planda: abonelik mobil uygulamadan etkinleştirilir (bu cihazda reklam ve satın alma gösterilmez).';

  @override
  String get premium_card_desc =>
      'Tüm reklamları kaldırmak ve botlarınızı herhangi bir pop-up olmadan anında başlatmak için abone olun.';

  @override
  String get premium_card_title => 'Reklamları Kaldır';

  @override
  String get quick_access_title => 'Hızlı Erişim';

  @override
  String get recovery_delete_bot => 'Botu yerel olarak sil';

  @override
  String get recovery_label => 'Kurtarma';

  @override
  String get recovery_retry_discord => 'Discord bağlantısını tekrar dene';

  @override
  String get recovery_title => 'Kurtarma modu';

  @override
  String reply_active_route(String label) {
    return 'Aktif rota: $label';
  }

  @override
  String get reply_buttons_desc =>
      'Bu mesaja etkileşimli düğmeler veya açılır menüler ekleyin';

  @override
  String get reply_buttons_optional =>
      'Düğmeler ve Seçim Menüleri (isteğe bağlı)';

  @override
  String get reply_choose_type => 'Gönderilecek yanıt türünü seçin';

  @override
  String get reply_command_reply_title => 'Komut Yanıtı';

  @override
  String get reply_configure_workflow => 'Yanıt İş Akışını Yapılandır';

  @override
  String get reply_editor_title => 'Yanıt Ayrıntıları';

  @override
  String get reply_mode_layout => 'Düzen Modu';

  @override
  String get reply_mode_layout_desc =>
      'Discord\'un zengin düzen sistemi — kapsayıcılar, medya, metin ve formlar';

  @override
  String get reply_mode_modal => 'Modal Formu';

  @override
  String get reply_mode_modal_desc =>
      'Metin girişi alanlarına sahip pop-up diyaloğu';

  @override
  String get reply_mode_standard => 'Standart Mesaj';

  @override
  String get reply_mode_standard_desc =>
      'Metin, gömülü mesajlar ve isteğe bağlı düğmeler / seçim menüleri';

  @override
  String get reply_response_text_helper =>
      'Eğik çizgi komutu yanıt metni olarak kullanılır. ((değişken)) sözdizimini destekler.';

  @override
  String get reply_response_text_label => 'Yanıt Metni';

  @override
  String get reply_response_workflow => 'Yanıt İş Akışı';

  @override
  String response_embeds_count(int count) {
    return '$count gömülü mesaj';
  }

  @override
  String get response_interactive_components => 'etkileşimli bileşenler';

  @override
  String get response_mode_layout => 'Düzen modu';

  @override
  String get response_mode_modal => 'Modal formu';

  @override
  String get response_mode_standard => 'Standart mesaj';

  @override
  String get response_visibility_ephemeral => 'geçici (ephemeral)';

  @override
  String get response_visibility_public => 'genel';

  @override
  String get response_workflow_auto_defer => 'Eylemler varsa otomatik ertele';

  @override
  String get response_workflow_auto_defer_desc =>
      'Hızlıca onaylayın, eylemleri yürütün, ardından nihai yanıtı düzenleyin.';

  @override
  String get response_workflow_condition_desc =>
      'Değişken mevcutsa ve boş değilse => THEN metnini kullanın, aksi takdirde ELSE metnini kullanın.';

  @override
  String get response_workflow_conditional_title => 'Koşullu yanıt (MVP)';

  @override
  String get response_workflow_deferred_reply => 'Ertelenmiş yanıt';

  @override
  String get response_workflow_else_text =>
      'ELSE (DEĞİLSE) yanıt metni (isteğe bağlı)';

  @override
  String get response_workflow_enable_condition => 'Koşulu etkinleştir';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Geçici (Yalnızca komut kullanıcısı)';

  @override
  String get response_workflow_error_policy => 'Hata politikası';

  @override
  String get response_workflow_error_policy_desc =>
      'Bir eylem başarısız olduğunda, ertelenen mesajı bir hata ile düzenleyin.';

  @override
  String get response_workflow_mode_component => 'Bileşen';

  @override
  String get response_workflow_mode_modal => 'Modal';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_public => 'Genel';

  @override
  String get response_workflow_revert_tooltip => 'Tüm değişiklikleri geri al';

  @override
  String get response_workflow_then_text =>
      'THEN (O HALDE) yanıt metni (isteğe bağlı)';

  @override
  String get response_workflow_title => 'Yanıt İş Akışı';

  @override
  String get response_workflow_variable_key =>
      'Değişken anahtarı (örn: opts.userId)';

  @override
  String get response_workflow_visibility => 'Görünürlük';

  @override
  String get restore_completed => 'Geri yükleme tamamlandı';

  @override
  String get restore_runtime_db_recommended =>
      'Geri yükleme tamamlandı (SQLite çalışma zamanı geri yüklendi, yeniden başlatma önerilir)';

  @override
  String get review_actions_title => 'Eylemler';

  @override
  String review_description_line(String desc) {
    return 'Açıklama: $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Klasör: $folder';
  }

  @override
  String get review_info_title => 'Bilgi';

  @override
  String get review_legacy_mode => 'Ön ek modu etkin';

  @override
  String get review_local_only => 'Yalnızca yerel komut';

  @override
  String review_name_line(String name) {
    return 'Ad: $name';
  }

  @override
  String get review_name_untitled => '(adsız)';

  @override
  String review_options_count(int count) {
    return '$count seçenek';
  }

  @override
  String get review_reply_title => 'Yanıt';

  @override
  String review_subcommand_routes(int count) {
    return '$count alt komut rotası';
  }

  @override
  String get review_trigger_inputs_title => 'Tetikleyici ve Girişler';

  @override
  String review_type_line(String type) {
    return 'Tür: $type';
  }

  @override
  String get rewarded_start_complete_ad =>
      'Barındırma oturumunuzu başlatmak için lütfen reklamın tamamını izleyin.';

  @override
  String get rewarded_start_continue => 'Devam et';

  @override
  String get rewarded_start_credit_confirmed =>
      'Ödül tanımlandı: barındırma dakikalarınız eklendi.';

  @override
  String get rewarded_credit_syncing_message =>
      'Reklam ödülünüz hâlâ eşitleniyor. Birkaç saniye sonra botu yeniden başlatmayı deneyin.';

  @override
  String get sync_cloud_applied => 'Bulut sürümü başarıyla uygulandı';

  @override
  String sync_diff_local_only_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yalnızca yerel',
      one: '1 yalnızca yerel',
    );
    return '$_temp0';
  }

  @override
  String sync_diff_new_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count yeni',
      one: '+1 yeni',
    );
    return '$_temp0';
  }

  @override
  String sync_diff_updated_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count güncellendi',
      one: '1 güncellendi',
    );
    return '$_temp0';
  }

  @override
  String get bot_stats_metrics_source => 'Ölçüm kaynağı';

  @override
  String get bot_stats_no_bot_selected => 'Bot seçilmedi';

  @override
  String get bot_stats_refresh_now => 'Şimdi yenile';

  @override
  String get bot_stats_source_local => 'Bu cihazda yerel';

  @override
  String get bot_stats_warning_title => 'Uyarı';

  @override
  String bot_start_embedded_runner_failed(String detail) {
    return 'Gömülü JS çalıştırıcısı başlatılamadı. Uygulamayı tamamen yeniden başlatın (hot reload değil).$detail';
  }

  @override
  String get bot_start_sign_in_required =>
      'Bu botu başlatmadan önce Ayarlar\'dan Bot Creator\'a giriş yapın.';

  @override
  String get home_badge_turnkey => 'Anahtar teslim';

  @override
  String home_server_cannot_run_bot(String detail) {
    return 'Bot Creator sunucuları seçildi ve bu botu çalıştıramıyor: $detail. Yerel çalıştırma başlatılmadı — bu sorunu çözdükten sonra yeniden başlatın.';
  }

  @override
  String get home_server_session_unusable =>
      'bu cihazdan kullanılabilir sunucu oturumu yok';

  @override
  String get runner_source_runner => 'Runner';

  @override
  String get command_create_existing_folders => 'Mevcut klasörler';

  @override
  String get common_export => 'Dışa aktar';

  @override
  String get workflows_folder_destination_optional =>
      'Hedef klasör (isteğe bağlı)';

  @override
  String get workflows_import_preview_title =>
      'İş akışı içe aktarma önizlemesi';

  @override
  String get blueprint_close_inspector => 'Denetçiyi kapat';

  @override
  String get blueprint_search_action_hint => 'Bir eylem arayın...';

  @override
  String get common_auto => 'Otomatik';

  @override
  String get common_inline => 'Satır içi';

  @override
  String marketplace_options_count(int count) {
    return 'Seçenekler ($count)';
  }

  @override
  String marketplace_required_config_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yapılandırma',
      one: '1 yapılandırma',
    );
    return '$_temp0';
  }

  @override
  String get option_autocomplete_javascript => 'JavaScript otomatik tamamlama';

  @override
  String option_description_new(int count) {
    return '$count numaralı seçeneğin açıklaması';
  }

  @override
  String variables_sync_failed(String error) {
    return 'Değişken eşitlenemedi: $error';
  }

  @override
  String actions_configured_count(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eylem yapılandırıldı',
      one: '1 eylem yapılandırıldı',
    );
    return '$_temp0';
  }

  @override
  String action_card_else_if(int count) {
    return 'DEĞİLSE $count';
  }

  @override
  String get blueprint_cut_link => 'Bağlantıyı kes';

  @override
  String get blueprint_entry_point_hint =>
      'Giriş noktası tetikleyici düğümü.\nKomut özelliklerinde yapılandırılır.';

  @override
  String get blueprint_mode_label => 'Blueprint';

  @override
  String get blueprint_origin_label => 'Başlangıç (0, 0)';

  @override
  String bot_config_version_commands(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count komut',
      one: '1 komut',
    );
    return '$_temp0';
  }

  @override
  String get bot_config_version_commands_title => 'Bu sürümdeki komutlar:';

  @override
  String bot_config_version_more_count(int count) {
    return '… ve $count tane daha';
  }

  @override
  String bot_config_version_replace_warning(int count) {
    return 'Mevcut $count komutu değiştirecek';
  }

  @override
  String command_delete_discord_failed_local(String error) {
    return 'Discord silme başarısız. Yerel silme uygulandı. $error';
  }

  @override
  String get common_exists => 'Mevcut';

  @override
  String get common_live_badge => 'CANLI';

  @override
  String component_choice_number(int count) {
    return 'Seçenek $count';
  }

  @override
  String get component_ephemeral_hint =>
      'Geçici (yalnızca komutu kullanan görür)';

  @override
  String get debug_persistence_title => 'Kalıcılık hata ayıklama';

  @override
  String element_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count öğe',
      one: '1 öğe',
    );
    return '$_temp0';
  }

  @override
  String embed_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count embed',
      one: '1 embed',
    );
    return '$_temp0';
  }

  @override
  String get emojis_animated_label => 'animasyonlu';

  @override
  String field_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alan',
      one: '1 alan',
    );
    return '$_temp0';
  }

  @override
  String marketplace_actions_count(int count) {
    return 'Eylemler ($count)';
  }

  @override
  String get onb_example_label => 'Örnek:';

  @override
  String get option_autocomplete_js_hint =>
      'En fazla 25 seçenek döndürmek için interaction.respond() ile ad/değer çiftleri kullanın.';

  @override
  String get permission_tap_to_cycle => 'Değiştirmek için dokunun';

  @override
  String get serialization_copy_base64 =>
      'Kompakt Base64 yükünü panoya kopyala';

  @override
  String get settings_ads_debug_desc =>
      'Aracılığı doğrulamak için Ad Inspector\'ı açın ve bağdaştırıcı durumunu (Unity/Google) kaydedin.';

  @override
  String get settings_ads_debug_title => 'Reklam aracılığı hata ayıklama';

  @override
  String settings_detected_engine(String engine) {
    return 'Algılanan motor: $engine';
  }

  @override
  String get variables_emojis_hint =>
      'Kullanılabilir emojiler — eklemek için dokunun';

  @override
  String workflow_event_variables_count(int count) {
    return 'Olay değişkenleri ($count)';
  }

  @override
  String workflow_import_review_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'İçe aktarılacak $count iş akışını gözden geçirin:',
      one: 'İçe aktarılacak 1 iş akışını gözden geçirin:',
    );
    return '$_temp0';
  }

  @override
  String get workflow_rename_variables_hint =>
      'İsteğe bağlı olarak bu iş akışının değişkenlerini yeniden adlandırın.';

  @override
  String component_node_child_run_hint(
    String message,
    String workflow,
    String entry,
    String args,
  ) {
    return '$message \"$workflow\" çalıştırılacak (giriş: $entry, argümanlar: $args).';
  }

  @override
  String workflows_preview_summary(String type, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eylem',
      one: '1 eylem',
    );
    return '$type  •  $_temp0';
  }

  @override
  String get runner_embedded_desync_detail =>
      'Runner süreci çalışıyor ancak uygulama bağlantıyı kaybetti. Ayarlar\'daki Yeniden başlat\'ı kullanın.';

  @override
  String runtime_invalid_bot_id(String error) {
    return 'Bot Creator sunucularında başlatma için geçersiz bot kimliği. Botu eşitleyin/yeniden oluşturun ve tekrar deneyin. Özgün hata: $error';
  }

  @override
  String runtime_invalid_bot_id_details(String detail) {
    return 'Bot Creator sunucularında başlatma için geçersiz bot kimliği. Botu eşitleyin/yeniden oluşturun ve tekrar deneyin. Ayrıntılar: $detail';
  }

  @override
  String get runtime_local_unsupported_ios_configure =>
      'Yerel mod iOS\'ta desteklenmiyor. Bu botu başlatmak için Bot Creator\'ı yapılandırın.';

  @override
  String get runtime_local_unsupported_ios_sign_in =>
      'Yerel mod iOS\'ta desteklenmiyor. Bu botu başlatmadan önce Ayarlar\'dan Bot Creator\'a giriş yapın.';

  @override
  String get runtime_plan_limit =>
      'Planınız bu başlatmaya izin vermiyor. Planınızı değiştirmek için tekliflere bakın.';

  @override
  String runtime_request_failed(String error) {
    return 'Bot Creator sunucularına yapılan istek başarısız oldu: $error';
  }

  @override
  String runtime_servers_not_ready(String error) {
    return 'Bot Creator sunucuları bu bot için henüz hazır değil. Özgün hata: $error';
  }

  @override
  String get runtime_session_expired =>
      'Bot Creator oturumunuz sona erdi. Bu botu başlatmak için Ayarlar\'dan yeniden giriş yapın.';

  @override
  String get runtime_sign_in_required =>
      'Bu botu başlatmadan önce Ayarlar\'dan Bot Creator\'a giriş yapın.';

  @override
  String runtime_startup_failed(String error) {
    return 'Bot Creator sunucularında başlatma başarısız oldu. Özgün hata: $error';
  }

  @override
  String runtime_startup_failed_with_detail(String detail, String error) {
    return 'Bot Creator sunucularında başlatma başarısız oldu. Ayrıntılar: $detail Özgün hata: $error';
  }

  @override
  String runtime_startup_in_progress(String status, String error) {
    return 'Bot Creator sunucularında başlatma hâlâ sürüyor ($status). İşlem kuyrukte veya çalışıyor olabilir. Özgün hata: $error';
  }

  @override
  String runtime_unreachable(String error) {
    return 'Bot Creator sunucularına geçici olarak ulaşılamıyor. Özgün hata: $error';
  }

  @override
  String get sync_cloud_update_applied =>
      'Bulut güncellemesi başarıyla uygulandı';

  @override
  String get sync_conflict_message =>
      'Bu yerel oturum ile Bulut sürümü (Mobil) arasında farklı değişiklikler var. Bu çakışmayı nasıl çözeceğinizi seçin:';

  @override
  String get sync_conflict_title => 'Eşitleme çakışması algılandı';

  @override
  String get sync_in_progress => 'Eşitleme sürüyor...';

  @override
  String get sync_keep_local_description =>
      'Yerel değişikliklerinizi korur ve Bulut\'u güncellemek için gönderir.';

  @override
  String get sync_keep_local_title => 'Yerel sürümü koru (Masaüstü)';

  @override
  String get sync_local_kept => 'Yerel sürüm korundu ve Bulut\'ta güncellendi';

  @override
  String get sync_merge_smart_description =>
      'İki taraftaki tüm eklemeleri korur ve yinelenen bir komutta en yenisini alır.';

  @override
  String get sync_merge_smart_done =>
      'Akıllı birleştirme yapıldı ve Bulut ile eşitlendi';

  @override
  String get sync_merge_smart_title => 'Akıllı birleştirme (Önerilir)';

  @override
  String get sync_synced_with_cloud => 'Bulut sürümüyle eşitlendi';

  @override
  String get sync_take_cloud_description =>
      'Gönderilmemiş yerel değişikliklerin üzerine Bulut sürümünü yazar.';

  @override
  String get sync_take_cloud_title => 'Bulut sürümünü al (Mobil)';

  @override
  String get sync_version_cloud_mobile => 'Bulut Sürümü (Mobil)';

  @override
  String get sync_version_local_desktop => 'Yerel Sürüm (Masaüstü)';

  @override
  String get rewarded_credit_syncing_title => 'Ödül hâlâ eşitleniyor';

  @override
  String get ad_context_failed =>
      'Reklam bağlamı oluşturulamadı (hesap bağlı değil veya bot jetonu yok).';

  @override
  String get ad_history_unavailable => 'Geçmiş alınamadı (API kullanılamıyor)';

  @override
  String get ad_limit_or_cooldown =>
      'Reklam bekleme süresi veya sınırı etkin. Lütfen daha sonra tekrar deneyin.';

  @override
  String get ad_sync_config_failed =>
      'Bot yapılandırması ana API ile eşitlenemedi.';

  @override
  String get rewarded_start_credit_pending =>
      'Reklam bitti. Ödülünüz kontrol ediliyor…';

  @override
  String get rewarded_start_credit_unconfirmed =>
      'Ödül henüz tanımlanmadı. Sunucu birazdan onaylayabilir: dakikaları yenileyerek görebilirsiniz.';

  @override
  String get rewarded_start_message =>
      'Bu barındırma oturumunu başlatmak için bir reklam izlemeniz gerekiyor. Bu, projeyi finanse etmeye yardımcı olur. Premium kullanıcılar bunu atlayabilir.';

  @override
  String get rewarded_start_no_ad_available =>
      'Şu anda uygun reklam yok. Lütfen daha sonra tekrar deneyin.';

  @override
  String get rewarded_start_skip => 'Atla';

  @override
  String get rewarded_start_thanks => 'Desteğiniz için teşekkürler!';

  @override
  String get rewarded_start_title => 'Reklam Gerekli';

  @override
  String get rewarded_start_watch => 'Reklam izle';

  @override
  String get runner_select_source => 'Runner seç';

  @override
  String get runner_source_all => 'Tüm runnerlar';

  @override
  String runner_source_label(String name) {
    return 'Çalıştırıcı: $name';
  }

  @override
  String get runner_source_local => 'Yerel';

  @override
  String get runner_source_manager => 'Bot Creator sunucuları';

  @override
  String get runner_source_manager_unavailable =>
      'Bot Creator sunucularından istatistikleri yüklemek için Ayarlar\'da Bot Creator\'a giriş yapın.';

  @override
  String get runner_source_this_device => 'Bu cihaz';

  @override
  String get save => 'Kaydet';

  @override
  String get scheduler_add_title => 'Program ekle';

  @override
  String get scheduler_add_trigger => 'Tetikleyici ekle';

  @override
  String scheduler_delete_confirm(String label) {
    return '\"$label\" programı silinsin mi?';
  }

  @override
  String get scheduler_delete_title => 'Programı sil';

  @override
  String get scheduler_edit_title => 'Programı düzenle';

  @override
  String get scheduler_empty => 'Henüz planlanmış tetikleyici yok.';

  @override
  String get scheduler_every_minutes => 'Her (dakika)';

  @override
  String get scheduler_invalid_minutes =>
      'Dakika değeri 0\'dan büyük olmalıdır.';

  @override
  String get scheduler_label_field => 'Etiket';

  @override
  String get scheduler_label_hint => 'İsteğe bağlı görüntüleme etiketi';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Zamanlayıcı sınırına ulaşıldı ($limit).';
  }

  @override
  String get scheduler_no_workflows =>
      'Bir program eklemeden önce en az bir iş akışı oluşturun.';

  @override
  String get scheduler_page_title => 'Zamanlayıcı';

  @override
  String scheduler_save_failed(String error) {
    return 'Program kaydedilemedi: $error';
  }

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'İş Akışı: $workflow • Her $minutes dk';
  }

  @override
  String get scheduler_tab => 'Zamanlayıcı';

  @override
  String get scheduler_tab_short => 'Zam';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'Tetikleyiciler: $count$limit';
  }

  @override
  String get scoped_default_value => 'Varsayılan değer';

  @override
  String get scoped_default_value_hint => 'İsteğe bağlı';

  @override
  String scoped_delete_confirm(String key) {
    return '\"$key\" ve saklanan tüm çalışma zamanı verileri silinsin mi?';
  }

  @override
  String get scoped_delete_title => 'Kapsamlı Değişkeni Sil';

  @override
  String get scoped_declare_detected => 'Bu değişkeni bildir';

  @override
  String get scoped_detected_badge => 'Algılandı';

  @override
  String scoped_detected_hint(int count) {
    return 'Bildirilmiş tanım yok · $count kayıtlı değer';
  }

  @override
  String get scoped_detected_tooltip =>
      'Bot verisinde tanımı bildirilmemiş değer. Olduğu gibi gösterilir; hiçbir şey uydurulmaz.';

  @override
  String get scoped_empty => 'Tanımlanmış kapsamlı değişken yok';

  @override
  String get scoped_empty_subtitle =>
      'Kapsamlı değişkenler Discord bağlamı (kullanıcı, sunucu…) başına bir değer saklar. Çalışma zamanında bot tarafından doldurulurlar.';

  @override
  String get scoped_explore_runtime => 'Çalışma zamanı verilerini keşfet';

  @override
  String scoped_ref(String ref) {
    return 'Referans: $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Eski: $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'Tümünü kopyala';

  @override
  String get scoped_runtime_empty =>
      'Çalışma zamanı verisi yok.\nBu anahtar yürütme sırasında bot tarafından doldurulacaktır.';

  @override
  String get scoped_runtime_search => 'ID veya isme göre ara…';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Kapsam: $scope · $count bağlam bulundu';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Çalışma zamanı verisi — \"$key\"';
  }

  @override
  String get scoped_scope => 'Kapsam';

  @override
  String get scoped_scope_help => 'Değişkenin saklandığı varlık seviyesi.';

  @override
  String get scoped_title => 'Kapsamlı Değişkenler';

  @override
  String get scratch_add_block => 'Blok ekle';

  @override
  String get scratch_bdfd_script => 'BDFD Betiği';

  @override
  String get scratch_block_entry_point => 'Komut Tetikleyici';

  @override
  String get scratch_block_metadata => 'Meta Veri';

  @override
  String get scratch_block_required => 'Gerekli';

  @override
  String get scratch_blocks_tab => 'Bloklar';

  @override
  String get scratch_custom_id_filter_desc =>
      'Bu iş akışı, yalnızca tıklanan butonun veya gönderilen modalın Özel Kimliği (Custom ID) bu kimlikle tam olarak eşleştiğinde çalışır.';

  @override
  String get scratch_custom_id_filter_hint => 'örn. buton_kimligim';

  @override
  String get scratch_custom_id_filter_label =>
      'Özel Kimlik filtresi (isteğe bağlı)';

  @override
  String get scratch_dart_script => 'Dart Betiği';

  @override
  String get scratch_entry_event_trigger => 'Etkinlik tetikleyici';

  @override
  String get scratch_entry_function => 'Fonksiyon';

  @override
  String get scratch_entry_interaction => 'Eğik Çizgi Komutu (/)';

  @override
  String get scratch_entry_message => 'Metin Mesajı';

  @override
  String get scratch_entry_point_hint => 'Karalama giriş noktası ipucu';

  @override
  String get scratch_entry_point_label => 'Giriş noktası adı';

  @override
  String get scratch_entry_point_listen => 'Bu komut ne zaman çalışır?';

  @override
  String get scratch_event_category => 'Etkinlik kategorisi';

  @override
  String get scratch_event_name => 'Etkinlik adı';

  @override
  String get scratch_event_variables => 'Etkinlik değişkenleri';

  @override
  String get scratch_execution_mode => 'Komut nasıl oluşturulur?';

  @override
  String get scratch_legacy_config => 'Eski yapılandırma';

  @override
  String get scratch_meta_advanced => 'Gelişmiş ayarlar';

  @override
  String get scratch_meta_desc_hint => 'Komut açıklaması';

  @override
  String get scratch_meta_name_hint => 'Komut adı';

  @override
  String get scratch_meta_type_label => 'Komut türü';

  @override
  String get scratch_meta_type_message => 'Mesaj komutu';

  @override
  String get scratch_meta_type_message_desc =>
      'Mesaj bağlam menüsünden tetiklenir.';

  @override
  String get scratch_meta_type_prefix => 'Ön ek komutu';

  @override
  String get scratch_meta_type_prefix_desc =>
      'Bir metin ön ekiyle tetiklenir (örn. !yardım).';

  @override
  String get scratch_meta_type_slash => 'Eğik çizgi komutu';

  @override
  String get scratch_meta_type_slash_desc =>
      'Discord\'da / yazarak tetiklenir.';

  @override
  String get scratch_meta_type_user => 'Kullanıcı komutu';

  @override
  String get scratch_meta_type_user_desc =>
      'Kullanıcı bağlam menüsünden tetiklenir.';

  @override
  String get scratch_mode_bdfd => 'BDFD Kodu';

  @override
  String get scratch_mode_blocks => 'Görsel (Bloklar)';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_response_block => 'Yanıt';

  @override
  String get scratch_response_components => 'Bileşenler';

  @override
  String get scratch_response_edit => 'Yanıtı düzenle';

  @override
  String get scratch_trigger_tab => 'Tetikleyici';

  @override
  String get scratch_wizard_actions_empty_desc =>
      'Botunuzun ne yapacağını yapılandırmak için aşağıya eylem blokları ekleyin.';

  @override
  String get scratch_wizard_actions_empty_title =>
      'Henüz tanımlanmış eylem yok.';

  @override
  String get scratch_wizard_config_button_instruction =>
      'Bu iş akışını tetikleyecek butonun veya modalın kimliğini yapılandırın.';

  @override
  String get scratch_wizard_folder_hint => 'örn. yonetim';

  @override
  String get scratch_wizard_folder_label => 'Klasör (isteğe bağlı)';

  @override
  String get scratch_wizard_save_details => 'Kaydetme Detayları';

  @override
  String get scratch_wizard_step_actions => 'Adım 3: Eylemler';

  @override
  String get scratch_wizard_step_config => 'Adım 2: Yapılandırma';

  @override
  String get scratch_wizard_step_save => 'Adım 4: Kaydet ve Özet';

  @override
  String get scratch_wizard_step_trigger => 'Adım 1: Tetikleyici Türü';

  @override
  String scratch_wizard_summary_actions_count(int count) {
    return '$count eylem yapılandırıldı';
  }

  @override
  String get scratch_wizard_summary_title => 'İş Akışı Özeti';

  @override
  String scratch_wizard_summary_trigger_button(String id) {
    return 'Buton Tıklaması / Modal (Özel Kimlik: \'$id\')';
  }

  @override
  String scratch_wizard_summary_trigger_event(String event) {
    return 'Etkinlik: $event';
  }

  @override
  String get scratch_wizard_summary_trigger_function =>
      'Genel Fonksiyon / İş Akışı';

  @override
  String get scratch_wizard_trigger_button_desc =>
      'Bir kullanıcı bir butona tıkladığında, seçim menüsü kullandığında veya bir modal gönderdiğinde tetiklenir.';

  @override
  String get scratch_wizard_trigger_button_title => 'Buton veya Mesaj Bileşeni';

  @override
  String get scratch_wizard_trigger_event_desc =>
      'Bir Discord eyleminde tetiklenir (örn. sunucuya üye katılması, mesaj silinmesi, rolün güncellenmesi).';

  @override
  String get scratch_wizard_trigger_event_title => 'Discord Etkinliği';

  @override
  String get scratch_wizard_trigger_function_desc =>
      'İş akışını diğer tetikleyiciler veya entegrasyonlar tarafından çağrılabilen yeniden kullanılabilir bir fonksiyon olarak çalıştırır.';

  @override
  String get scratch_wizard_trigger_function_title =>
      'Fonksiyon / Manuel Tetikleyici';

  @override
  String get scratch_wizard_trigger_instruction =>
      'Bu iş akışını neyin tetikleyeceğini seçin:';

  @override
  String get scratch_wizard_workflow_name_hint => 'örn. buton_yaniti';

  @override
  String get scratch_wizard_workflow_name_label => 'İş Akışı Adı *';

  @override
  String get scratch_workflow_add_argument => 'Argüman ekle';

  @override
  String get scratch_workflow_arguments => 'Argümanlar (Değişkenler)';

  @override
  String get scratch_workflow_metadata => 'İş Akışı Ayarları';

  @override
  String get scratch_workflow_name => 'İş Akışı Adı';

  @override
  String get scratch_workflow_type => 'İş Akışı Türü';

  @override
  String get scratch_workflow_type_event => 'Etkinlik odaklı';

  @override
  String get scratch_workflow_type_general => 'Genel';

  @override
  String get serialization_export_base64_title =>
      'Komutu Base64 olarak dışa aktar';

  @override
  String get serialization_export_json_subtitle =>
      'Okunabilir JSON\'u panoya kopyala';

  @override
  String get serialization_export_json_title => 'Komutu JSON olarak dışa aktar';

  @override
  String get serialization_import_desc =>
      'Bir komut yükü (JSON veya Base64) yapıştırın.';

  @override
  String get serialization_import_title => 'Komutu içe aktar';

  @override
  String get serialization_imported => 'Komut düzenleyiciye aktarıldı.';

  @override
  String get serialization_invalid_format => 'Geçersiz komut yükü formatı.';

  @override
  String get serialization_invalid_structure => 'Geçersiz komut yükü yapısı.';

  @override
  String get settings_account_connect_label =>
      'Discord ile Bot Creator\'a giriş yap';

  @override
  String get settings_account_connected_hint =>
      'Hesap bağlandı. Botlarınız ve verileriniz artık Bot Creator ile senkronize edildi.';

  @override
  String get settings_account_disconnect_label => 'Oturumu kapat';

  @override
  String get settings_account_disconnected_hint =>
      'Bot Creator hesabınız bir bot eklediğinizde otomatik olarak oluşturulur. Ardından bu cihazdaki botlarınızı kurtarmak için Discord ile giriş yapın.';

  @override
  String get settings_account_status_connected => 'Hesap bağlandı';

  @override
  String get settings_account_status_disconnected => 'Giriş yapılmadı';

  @override
  String get mobile_account_required_title => 'Giriş yap';

  @override
  String get mobile_account_required_body =>
      'Discord veya e-posta ile giriş yapın.';

  @override
  String get mobile_account_required_feature_bots =>
      'Botlarınızı buluttan senkronize edin ve geri yükleyin';

  @override
  String get mobile_account_required_feature_hosted =>
      'Barındırılan uygulamaları dağıtın ve yönetin';

  @override
  String get mobile_account_required_feature_recovery =>
      'Yeniden yüklemeden veya yeni telefonda her şeyi kurtarın';

  @override
  String mobile_account_required_failed(String error) {
    return 'Discord girişi başarısız: $error';
  }

  @override
  String get mobile_login_or_divider => 'veya';

  @override
  String get mobile_login_show_email => 'E-posta ile giriş yap';

  @override
  String get mobile_login_hide_email => 'E-posta girişini gizle';

  @override
  String get mobile_login_email_title => 'E-posta ile giriş yap';

  @override
  String get mobile_login_email_hint =>
      'Hesabınıza bağlı e-posta ve şifreyi kullanın.';

  @override
  String get mobile_login_email => 'E-posta';

  @override
  String get mobile_login_password => 'Şifre';

  @override
  String get mobile_login_submit => 'Giriş yap';

  @override
  String get mobile_login_invalid_credentials => 'Geçersiz e-posta veya şifre.';

  @override
  String mobile_login_failed(String error) {
    return 'Giriş başarısız: $error';
  }

  @override
  String get settings_alternative_login_title => 'Alternatif giriş';

  @override
  String get settings_alternative_login_desc =>
      'Discord olmadan giriş yapmak için e-posta ve şifre ekleyin.';

  @override
  String settings_alternative_login_current_email(String email) {
    return 'Mevcut e-posta: $email';
  }

  @override
  String get settings_alternative_login_current_password => 'Mevcut şifre';

  @override
  String get settings_alternative_login_confirm_password => 'Şifreyi onayla';

  @override
  String get settings_alternative_login_update => 'Kimlik bilgilerini güncelle';

  @override
  String get settings_add_credentials => 'Kimlik bilgilerini kaydet';

  @override
  String get settings_alternative_login_missing_fields =>
      'E-posta ve şifre gereklidir.';

  @override
  String get settings_alternative_login_password_mismatch =>
      'Şifreler eşleşmiyor.';

  @override
  String get settings_credentials_saved => 'Alternatif giriş kaydedildi.';

  @override
  String get settings_ads_privacy_loading =>
      'Reklam gizliliği ayarları kontrol ediliyor...';

  @override
  String get settings_ads_privacy_manage =>
      'Reklam gizliliği tercihlerini yönet';

  @override
  String get settings_ads_privacy_not_required =>
      'Reklam gizliliği seçenekleri şu an için gerekli değil';

  @override
  String get settings_ads_privacy_open_error =>
      'Reklam gizliliği seçenekleri açılamadı';

  @override
  String get settings_ads_privacy_opened =>
      'Reklam gizliliği seçenekleri açıldı';

  @override
  String get settings_app_version => 'Uygulama';

  @override
  String get settings_appearance_accent_label => 'Vurgu';

  @override
  String settings_appearance_contrast_ratio(String ratio) {
    return 'Vurgu/yüzey kontrastı: $ratio';
  }

  @override
  String settings_appearance_contrast_warning(String ratio) {
    return 'Düşük kontrast ($ratio): Vurgu arka plandan zor ayrılıyor. Uygulama gerektiğinde bunu uyarlar; daha açık veya koyu bir vurgu okunabilirliği artırır.';
  }

  @override
  String get settings_appearance_custom_badge => 'Özel';

  @override
  String get settings_appearance_custom_title => 'Özel renkler';

  @override
  String get settings_appearance_mode_dark => 'Koyu';

  @override
  String get settings_appearance_mode_light => 'Açık';

  @override
  String get settings_appearance_mode_system => 'Sistem';

  @override
  String get settings_appearance_mode_title => 'Mod';

  @override
  String get settings_appearance_presets_title => 'Hazır temalar';

  @override
  String get settings_appearance_reset => 'Sıfırla';

  @override
  String get settings_appearance_seed_label => 'Ana renk';

  @override
  String get settings_appearance_subtitle =>
      'Bir mod, hazır bir tema veya kendi renklerini seç.';

  @override
  String get settings_appearance_title => 'Görünüm';

  @override
  String get settings_auto_backup_check_loading =>
      'Otomatik yedekleme kontrolü…';

  @override
  String get settings_auto_backup_every_12h => 'Her 12 saatte bir';

  @override
  String get settings_auto_backup_every_24h => 'Her 24 saatte bir';

  @override
  String get settings_auto_backup_every_6h => 'Her 6 saatte bir';

  @override
  String get settings_auto_backup_every_72h => 'Her 72 saatte bir';

  @override
  String get settings_auto_backup_interval => 'Otomatik yedekleme aralığı';

  @override
  String get settings_backup_now => 'Şimdi yedekle';

  @override
  String get settings_backup_restore_desc =>
      'Google Drive ile veri senkronizasyonunuzu yönetin';

  @override
  String get settings_backup_restore_title => 'Yedekle ve Geri Yükle';

  @override
  String get settings_builtin_help => 'Yerleşik eski !yardım komutu';

  @override
  String get settings_builtin_help_subtitle =>
      'Açık geçişli zorunlu özellik. Sadece özel yardım davranışı istiyorsanız devre dışı bırakın.';

  @override
  String get settings_clear_logs => 'Günlükleri temizle';

  @override
  String get settings_cloud_hosting_enabled =>
      'Mobil botlar artık Bot Creator sunucularını kullanıyor.';

  @override
  String get settings_compatibility_desc =>
      'BDFD\'den geçen kullanıcılar için özellik kapsamına hızlı bir bakış.';

  @override
  String get settings_compatibility_functions_category_components =>
      'Bileşenler / Etkileşimler';

  @override
  String get settings_compatibility_functions_category_control =>
      'Kontrol akışı';

  @override
  String get settings_compatibility_functions_category_embeds =>
      'Gömülü mesajlar (Embeds)';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Muhafızlar ve izinler';

  @override
  String get settings_compatibility_functions_category_http =>
      'HTTP yardımcıları';

  @override
  String get settings_compatibility_functions_category_json =>
      'JSON yardımcıları';

  @override
  String get settings_compatibility_functions_category_logging => 'Günlükleme';

  @override
  String get settings_compatibility_functions_category_messages => 'Mesajlar';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'Çalışma zamanı yer tutucuları';

  @override
  String get settings_compatibility_functions_category_threads =>
      'İş parçacıkları (Threads)';

  @override
  String get settings_compatibility_functions_category_variables =>
      'Kapsamlı değişkenler';

  @override
  String settings_compatibility_functions_count(int count) {
    return 'Uyumlu fonksiyonlar: $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'BDFD referans toplamı: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'Bot Creator tarafından desteklenen: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Yalnızca Bot Creator: $count';
  }

  @override
  String settings_compatibility_functions_count_both(int count) {
    return 'Her ikisinde de desteklenen: $count';
  }

  @override
  String settings_compatibility_functions_count_missing(int count) {
    return 'Bot Creator\'da eksik olan: $count';
  }

  @override
  String get settings_compatibility_functions_empty =>
      'Bu bölümde fonksiyon yok.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'Yalnızca BDFD olan girişler, sağlanan BDFD kataloğunda listelenen ancak şu anda Bot Creator\'da uygulanmayan fonksiyonlardır.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Bot Creator uygulaması ile BDFD referans fonksiyonları arasındaki fark görünümü.';

  @override
  String get settings_compatibility_functions_note =>
      'Bu sayfa mevcut uygulama kapsamından oluşturulmuştur ve zamanla büyüyecektir.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Bir fonksiyon arayın (örnek: \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Yalnızca Bot Creator\'da desteklenenler';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Döngü yardımcıları şu anda Bot Creator\'a özgüdür.';

  @override
  String get settings_compatibility_functions_section_both =>
      'Bot Creator ve BDFD\'de desteklenenler';

  @override
  String get settings_compatibility_functions_section_missing =>
      'BDFD\'de mevcut olup Bot Creator\'da eksik olanlar';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Bot Creator BDFD modunda şu anda uygulanan ve kullanılabilen fonksiyonlar.';

  @override
  String get settings_compatibility_functions_title =>
      'Uyumlu BDFD Fonksiyonları';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'BDFD fonksiyon kataloğunun tam kapsamı.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'BDScript fonksiyon eşitliği';

  @override
  String get settings_compatibility_item_events_desc =>
      'En yaygın etkinlikler desteklenir, bazıları çalışma zamanı sınırlıdır.';

  @override
  String get settings_compatibility_item_events_title => 'Etkinlik kapsamı';

  @override
  String get settings_compatibility_item_runner_desc =>
      'Uzak çalıştırıcı (runner) mevcuttur, çoklu çalıştırıcı desteği devam ediyor.';

  @override
  String get settings_compatibility_item_runner_title => 'Runner mimarisi';

  @override
  String get settings_compatibility_item_variables_desc =>
      'Dinamik değişkenler ve şablon yardımcıları desteklenir.';

  @override
  String get settings_compatibility_item_variables_title =>
      'Çalışma zamanı değişkenleri ve şablonları';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Görsel komut ve yanıt iş akışları mevcuttur.';

  @override
  String get settings_compatibility_item_workflows_title =>
      'İş akışı oluşturucu';

  @override
  String get settings_compatibility_note =>
      'Bu özet kasıtlı olarak genel düzeydedir ve sürümlerle birlikte gelişecektir.';

  @override
  String get settings_compatibility_open_functions =>
      'Uyumlu fonksiyonları görüntüle';

  @override
  String get settings_compatibility_status_missing => 'Eksik';

  @override
  String get settings_compatibility_status_partial => 'Kısmi';

  @override
  String get settings_compatibility_status_supported => 'Destekleniyor';

  @override
  String get settings_compatibility_title => 'BDFD uyumluluk özeti';

  @override
  String get settings_data_operations_title => 'Veri İşlemleri';

  @override
  String get settings_debug_desc =>
      'Yerel tercihleri sıfırlayın veya test için kurulumu yeniden oynatın.';

  @override
  String get settings_debug_premium_bypass => 'Premium atlama';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Abonelik olmadan tüm Premium özellikleri açın (yalnızca hata ayıklama).';

  @override
  String get settings_debug_title => 'Hata ayıklama araçları';

  @override
  String get settings_diagnostics_copied => 'Tanılama panoya kopyalandı';

  @override
  String get settings_diagnostics_copy_all => 'Tüm günlükleri kopyala';

  @override
  String get settings_diagnostics_dialog_title => 'Başlangıç Tanılama';

  @override
  String get settings_diagnostics_empty => 'Henüz uygulama günlüğü yok.';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Yalnızca uygulama tanılama günlüklerini gösterir (bot günlükleri hariçtir).';

  @override
  String get settings_diagnostics_page_title => 'Uygulama Günlükleri';

  @override
  String get settings_diagnostics_refresh => 'Günlükleri yenile';

  @override
  String get settings_diagnostics_section_title => 'Tanılama';

  @override
  String get settings_discord_rpc_authenticating =>
      'Discord ile kimlik doğrulanıyor…';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Yetkilendirme kodu önbelleğe alındı; jeton değişimini bitirmek için tekrar deneyin';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Yetkilendirme kodu alındı';

  @override
  String get settings_discord_rpc_authorize => 'Yetkilendir';

  @override
  String get settings_discord_rpc_authorizing =>
      'Discord yetkilendirmesi bekleniyor…';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label =>
      'OAuth aracı URL\'si (gelişmiş, isteğe bağlı)';

  @override
  String get settings_discord_rpc_broker_required =>
      'Genel istemci akışı için İstemci ID\'si yeterlidir; aracı URL\'si ve istemci sırrı isteğe bağlı geri dönüşlerdir';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Bu ID Bot Creator\'da sabittir ve ayarlardan değiştirilemez.';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'Discord uygulama istemci ID\'si gerekli';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Yerel olarak işlenen gizli istemci akışı için isteğe bağlı gelişmiş geri dönüş.';

  @override
  String get settings_discord_rpc_client_secret_hint => 'İstemci sırrı';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Discord uygulama istemci sırrı (isteğe bağlı)';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Yetkilendirmeyi tamamla';

  @override
  String get settings_discord_rpc_connect => 'Varlığı yenile';

  @override
  String get settings_discord_rpc_connected => 'Varlık Discord\'a gönderildi';

  @override
  String get settings_discord_rpc_connecting => 'Discord\'a bağlanılıyor…';

  @override
  String get settings_discord_rpc_desc =>
      'Bot Creator masaüstü etkinliğini yerel Discord istemcisinde yayınlayın. Bot Creator her zaman yerleşik Discord uygulamasını kullanır ve etkinleştirildiğinde SET_ACTIVITY\'yi doğrudan yerel IPC üzerinden gönderir.';

  @override
  String get settings_discord_rpc_disabled => 'Devre dışı';

  @override
  String get settings_discord_rpc_disconnect => 'IPC\'yi kapat';

  @override
  String get settings_discord_rpc_disconnected => 'IPC kapatıldı';

  @override
  String get settings_discord_rpc_enable =>
      'Discord Zengin Varlık özelliğini etkinleştir';

  @override
  String get settings_discord_rpc_enable_first =>
      'Önce Discord Zengin Varlık özelliğini etkinleştirin';

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'IPC uç noktası: $endpoint';
  }

  @override
  String get settings_discord_rpc_error => 'Discord RPC hatası';

  @override
  String get settings_discord_rpc_exchanging_code =>
      'OAuth değişimi tamamlanıyor…';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'Yerel Discord IPC bağlandı; henüz OAuth HTTP isteği gönderilmedi, yetkilendirme hala gerekli';

  @override
  String get settings_discord_rpc_ipc_open => 'Yerel IPC zaten açık';

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'Son hata: $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization =>
      'Yetkilendirme gerekli';

  @override
  String get settings_discord_rpc_not_configured => 'İstemci ID\'si gerekli';

  @override
  String get settings_discord_rpc_open_ipc => 'Yerel IPC\'yi aç';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Zengin Varlık yalnızca masaüstünde kullanılabilir';

  @override
  String get settings_discord_rpc_save => 'Ayarları kaydet';

  @override
  String get settings_discord_rpc_saved =>
      'Discord Zengin Varlık ayarları kaydedildi';

  @override
  String get settings_discord_rpc_title =>
      'Discord Zengin Varlık (Rich Presence)';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'Discord taşıması henüz bu platformda desteklenmiyor';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Yetkili kullanıcı: $user';
  }

  @override
  String get settings_drive_connect => 'Google Drive\'a Bağlan';

  @override
  String get settings_drive_connect_loading => 'Google Drive\'a bağlanılıyor…';

  @override
  String get settings_drive_connected => 'Google Drive\'a bağlandı';

  @override
  String get settings_drive_desc =>
      'Verilerinizi senkronize etmek için Google Drive hesabınızı bağlayın';

  @override
  String get settings_drive_disconnect => 'Bağlantıyı Kes';

  @override
  String get settings_drive_disconnect_loading => 'Bağlantı kesiliyor…';

  @override
  String get settings_drive_disconnected => 'Google Drive bağlantısı kesildi';

  @override
  String get settings_drive_status_connected => 'Bağlı';

  @override
  String get settings_drive_title => 'Google Drive Bağlantısı';

  @override
  String get settings_enable_auto_backup => 'Otomatik yedeklemeyi etkinleştir';

  @override
  String get settings_enable_auto_backup_desc =>
      'Zamanı geldiğinde otomatik olarak sürümlü anlık görüntüler oluşturun.';

  @override
  String get settings_execution_mode_desc =>
      'Bu platformda, Bot Creator botlarınızı asla barındırmaz. Kendi barındırdığınız çalıştırıcınızı kullanabilir veya botları yerel olarak yürütebilirsiniz.';

  @override
  String get settings_execution_mode_local_active =>
      'Botlar artık yerel olarak başlatılıyor. Çalıştırıcı ayarları saklı kalır ve her zaman yeniden etkinleştirilebilir.';

  @override
  String get settings_execution_mode_no_runner =>
      'Henüz bir çalıştırıcı yapılandırılmadı. Uygulama, bir tane ekleyene kadar yerel modda kalır.';

  @override
  String get settings_execution_mode_runner_priority =>
      'Kendi barındırdığınız çalıştırıcı tercih edilir. Eğer yapılandırılmış bir çalıştırıcı yoksa, uygulama yerel moda geri döner.';

  @override
  String get settings_execution_mode_title => 'Yürütme modu';

  @override
  String get settings_execution_mode_use_runner =>
      'Kendi barındırdığınız çalıştırıcıyı (runner) kullanın';

  @override
  String get settings_export => 'Dışa Aktar';

  @override
  String get settings_runner_type_label => 'Çalıştırıcı türü';

  @override
  String get settings_export_app_data => 'Uygulama Verilerini Dışa Aktar';

  @override
  String get settings_export_loading => 'Dışa aktarılıyor…';

  @override
  String get settings_import => 'İçe Aktar';

  @override
  String get settings_import_app_data => 'Uygulama Verilerini İçe Aktar';

  @override
  String get settings_import_loading => 'İçe aktarılıyor…';

  @override
  String get settings_language_desc =>
      'Uygulama tarafından kullanılan dili seçin.';

  @override
  String get settings_language_system => 'Otomatik (cihaz)';

  @override
  String get settings_language_title => 'Dil';

  @override
  String get settings_language_updated => 'Dil güncellendi';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'Son otomatik yedekleme: $date';
  }

  @override
  String get settings_last_auto_backup_never =>
      'Son otomatik yedekleme: hiç yok';

  @override
  String get settings_legacy_prefix => 'Eski komut ön eki';

  @override
  String get settings_legacy_prefix_helper =>
      'Şablonları ve kapsamlı değişkenleri destekler (bc_ isteğe bağlı). Örnek: ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? veya ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc =>
      'Verilerinizin nasıl işlendiğini ve saklandığını inceleyin.';

  @override
  String get settings_legal_title => 'Yasal';

  @override
  String get settings_local_hosting_enabled =>
      'Mobil botlar artık barındırma için cihazınızı kullanıyor.';

  @override
  String get settings_logs_cleared => 'Tanılama günlüğü temizlendi';

  @override
  String get settings_main_api_auth_failed =>
      'Bot Creator Sunucu oturumu geçersiz veya süresi dolmuş';

  @override
  String get settings_main_api_check => 'Bot Creator Sunucusunu Kontrol Et';

  @override
  String get settings_main_api_clear => 'Temizle';

  @override
  String get settings_main_api_cleared =>
      'Bot Creator Sunucu ayarları temizlendi';

  @override
  String get settings_main_api_connect_discord => 'Discord hesabını bağla';

  @override
  String get settings_main_api_connected =>
      'Bot Creator Sunucusu erişilebilir ✓';

  @override
  String get settings_main_api_connected_discord => 'Discord hesabı bağlandı';

  @override
  String settings_main_api_connected_user(String user) {
    return '$user olarak bağlandı';
  }

  @override
  String get settings_main_api_desc =>
      'Bot Creator\'ı Bot Creator Sunucunuza bağlayın ve Discord ile giriş yapın. Discord istemci sırrı arka uçta kalmalıdır.';

  @override
  String get settings_main_api_desktop_only =>
      'Bot Creator Sunucusu üzerinden Discord girişi yalnızca masaüstünde mevcuttur.';

  @override
  String get settings_main_api_disconnect => 'Hesabın bağlantısını kes';

  @override
  String get settings_main_api_not_configured =>
      'Bot Creator Sunucu URL\'si gerekli';

  @override
  String get settings_main_api_save => 'Bot Creator Sunucusunu Kaydet';

  @override
  String get settings_main_api_saved =>
      'Bot Creator Sunucu ayarları kaydedildi';

  @override
  String get settings_main_api_session_connected => 'Discord oturumu aktif';

  @override
  String get settings_main_api_session_disconnected =>
      'Discord oturumu kesildi';

  @override
  String get settings_main_api_session_expired =>
      'Discord oturumunun süresi doldu';

  @override
  String get settings_main_api_title => 'Bot Creator Sunucusu';

  @override
  String get settings_main_api_unreachable => 'Bot Creator Sunucusu erişilemez';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_url_required =>
      'Bot Creator Sunucu URL\'si gerekli';

  @override
  String get settings_main_api_user_unknown => 'Discord kullanıcısı';

  @override
  String get settings_manual_snapshot_label => 'Manuel anlık görüntü';

  @override
  String get settings_member_badge => 'ÜYE';

  @override
  String get settings_notifications_desc =>
      'Hangi push bildirim türlerini almak istediğinizi seçin.';

  @override
  String get settings_notifications_title => 'Bildirimler';

  @override
  String get settings_notifications_topic_billing => 'Faturalandırma';

  @override
  String get settings_notifications_topic_billing_desc =>
      'Abonelik yenileme hatırlatıcıları ve ödeme onayları.';

  @override
  String get settings_notifications_topic_botAlerts => 'Bot Uyarıları';

  @override
  String get settings_notifications_topic_botAlerts_desc =>
      'Botlarınız çevrimdışı olduğunda veya hatalarla karşılaştığında uyarılar.';

  @override
  String get settings_notifications_topic_broadcast => 'Duyurular';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'Bot Creator\'dan önemli duyurular ve haberler.';

  @override
  String get settings_notifications_topic_updates => 'Güncellemeler';

  @override
  String get settings_notifications_topic_updates_desc =>
      'Yeni özellikler, uygulama güncellemeleri ve değişiklik günlüğü özetleri.';

  @override
  String get settings_open_ad_inspector => 'Reklam Denetçisini Aç';

  @override
  String get settings_oss_licenses => 'Açık Kaynak Lisansları';

  @override
  String get settings_owner_badge => 'SAHİP';

  @override
  String get settings_owner_fallback => 'Sahip';

  @override
  String get settings_personal_owner_fallback => 'Kişisel Kullanıcı';

  @override
  String get settings_personal_owner_id_label => 'Sahip Kimliği: ';

  @override
  String get settings_personal_owner_label => 'Sahip: ';

  @override
  String get settings_personal_ownership => 'Kişisel Sahiplik';

  @override
  String get settings_preferences_reset_done => 'Tercihler sıfırlandı';

  @override
  String get settings_privacy_policy => 'Gizlilik Politikası';

  @override
  String get settings_raw_json_tile => 'Ham JSON Görüntüle (RAW JSON)';

  @override
  String get settings_recovery_title => 'Kurtarma Pro';

  @override
  String get settings_replay_onboarding => 'Kurulumu yeniden oynat';

  @override
  String get settings_replay_onboarding_desc =>
      'Kurulumu sıfırlayın ve şimdi tekrar başlatın.';

  @override
  String get settings_reset_preferences => 'Tercihleri sıfırla';

  @override
  String get settings_reset_preferences_desc =>
      'Tema, dil ve kurulum ilerlemesini sıfırlayın.';

  @override
  String get settings_restore_snapshot => 'Bu Anlık Görüntüyü Geri Yükle';

  @override
  String get settings_run_auto_backup_now =>
      'Otomatik yedeklemeyi şimdi çalıştır';

  @override
  String get settings_run_diagnostics => 'Tanılamayı Çalıştır';

  @override
  String settings_runner_active(String url) {
    return 'Aktif Runner API: $url';
  }

  @override
  String get settings_runner_auth_failed => 'Runner API jetonunu reddetti';

  @override
  String get settings_runner_check => 'Bağlantıyı kontrol et';

  @override
  String get settings_runner_clear => 'Temizle';

  @override
  String get settings_runner_cleared => 'Runner ayarları temizlendi';

  @override
  String get settings_runner_connected => 'Runner erişilebilir ✓';

  @override
  String get settings_runner_connecting => 'Bağlantı kontrol ediliyor…';

  @override
  String get settings_runner_desc =>
      'Uygulamayı bir Bot Creator Runner\'a bağlayın. Uzak çalıştırıcılar güvenilir ağlarda kalmalı ve bir taşıyıcı jeton (bearer token) kullanmalıdır.';

  @override
  String get settings_runner_use_remote => 'Uzak çalıştırıcı kullan';

  @override
  String get settings_runner_use_remote_desc =>
      'Uzak bir Bot Creator Runner\'a bağlanın. Kapalı bırakırsanız botlar bu cihazda yerel olarak çalışır.';

  @override
  String get settings_runner_disable_temp =>
      'Runner\'ı geçici olarak devre dışı bırak';

  @override
  String get settings_runner_disable_temp_desc =>
      'Runner ayarlarını koru ancak yeniden etkinleştirilene kadar yerel modu zorla.';

  @override
  String get settings_runner_disconnected => 'Runner bağlantısı kesildi';

  @override
  String get settings_runner_not_connected => 'Bağlı değil';

  @override
  String get settings_runner_reenabled => 'Runner yeniden etkinleştirildi';

  @override
  String get settings_runner_save => 'Ayarları kaydet';

  @override
  String get settings_runner_saved => 'Runner ayarları kaydedildi';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner geçici olarak devre dışı (yerel mod aktif)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner geçici olarak devre dışı bırakıldı';

  @override
  String get settings_runner_title => 'Runner API';

  @override
  String get settings_runner_token_hint =>
      'Taşıyıcı jeton (localhost üzerinde isteğe bağlı)';

  @override
  String get settings_runner_token_label => 'Runner API jetonu';

  @override
  String get settings_runner_unreachable => 'Runner erişilemez';

  @override
  String get settings_runner_url_clear => 'Temizle';

  @override
  String get settings_runner_url_cleared => 'Runner URL\'si temizlendi';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_url_save => 'URL\'yi Kaydet';

  @override
  String get settings_runner_url_saved => 'Runner URL\'si kaydedildi';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String get settings_embedded_runner_title => 'Gömülü JS Runner';

  @override
  String settings_embedded_runner_download_progress(
    String received,
    String total,
  ) {
    return '$received / $total';
  }

  @override
  String settings_embedded_runner_download_indeterminate(String received) {
    return '$received indirildi';
  }

  @override
  String get settings_embedded_runner_restart => 'Yeniden başlat';

  @override
  String get settings_embedded_runner_restart_success =>
      'Gömülü JS runner yeniden başlatıldı';

  @override
  String get settings_embedded_runner_restart_failed =>
      'Gömülü JS runner yeniden başlatılamadı';

  @override
  String get settings_embedded_runner_redownload => 'Yeniden indir';

  @override
  String get settings_embedded_runner_redownload_success =>
      'Gömülü JS runner yeniden indirildi';

  @override
  String get settings_embedded_runner_redownload_failed =>
      'Gömülü JS runner yeniden indirilemedi';

  @override
  String get settings_embedded_runner_open_log => 'Günlüğü aç';

  @override
  String settings_embedded_runner_binary_info(String size, String path) {
    return 'Binary: $size · $path';
  }

  @override
  String get settings_embedded_runner_status_running => 'Çalışıyor';

  @override
  String get settings_embedded_runner_status_stopped => 'Başlatılmadı';

  @override
  String get settings_embedded_runner_status_failed => 'Başarısız';

  @override
  String get settings_embedded_runner_status_downloading => 'İndiriliyor…';

  @override
  String settings_embedded_runner_running_at(String url) {
    return '$url üzerinde çalışıyor';
  }

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Uygulamalar: $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Bu anlık görüntüdeki uygulamalar';

  @override
  String get settings_snapshot_create_loading => 'Anlık görüntü oluşturuluyor…';

  @override
  String settings_snapshot_created_at(String date) {
    return 'Oluşturulma: $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'Anlık görüntü oluşturuldu: $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'Anlık görüntü siliniyor…';

  @override
  String get settings_snapshot_deleted => 'Anlık görüntü silindi';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Dosyalar: $count • Boyut: $size';
  }

  @override
  String settings_snapshot_id(String id) {
    return 'ID: $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'Etiket: $label';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date • $count dosya • $size';
  }

  @override
  String get settings_snapshot_no_metadata => 'Uygulama meta verisi yok.';

  @override
  String get settings_snapshot_preview_title => 'Anlık Görüntü Önizleme';

  @override
  String get settings_snapshot_restore_loading =>
      'Anlık görüntü geri yükleniyor…';

  @override
  String get settings_snapshots_delete_all => 'Tüm anlık görüntüleri sil';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return '$count anlık görüntü kalıcı olarak silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count anlık görüntü silindi.';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'Tüm anlık görüntüler siliniyor…';

  @override
  String get settings_snapshots_delete_all_title => 'Tüm anlık görüntüleri sil';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return '\"$label\" kalıcı olarak silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get settings_snapshots_delete_select_desc =>
      'Kaldırılacak anlık görüntüyü seçin (önce en eski).';

  @override
  String get settings_snapshots_delete_select_title =>
      'Bir anlık görüntüyü sil';

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Seçili bir anlık görüntüyü sil';

  @override
  String get settings_snapshots_empty => 'Henüz anlık görüntü bulunamadı.';

  @override
  String get settings_snapshots_refresh => 'Anlık görüntüleri yenile';

  @override
  String get settings_snapshots_refresh_loading =>
      'Anlık görüntüler yenileniyor…';

  @override
  String get settings_snapshots_title => 'Anlık Görüntüler';

  @override
  String get settings_solo_pill => 'SOLO';

  @override
  String get settings_startup_mode_cloud_desc =>
      'Android ve iOS\'ta önerilir. Günlükler, istatistikler ve başlatma Bot Creator üzerinden gerçekleşir.';

  @override
  String get settings_startup_mode_desc =>
      'Botlarınızın Bot Creator sunucularında mı yoksa yerel olarak bu cihazda mı başlatılacağını seçin.';

  @override
  String get settings_startup_mode_ios_unavailable =>
      'Yerel mod iOS\'ta hala kullanılamıyor.';

  @override
  String get settings_startup_mode_ios_warning =>
      'iOS\'ta yerel mod desteklenmez. Botlar her zaman Bot Creator sunucularını kullanır.';

  @override
  String get settings_startup_mode_local_desc =>
      'Botlar artık bu cihazda yerel olarak başlatılıyor.';

  @override
  String get settings_startup_mode_local_warning =>
      'Yerel mod, hata ayıklama veya belirli ihtiyaçlar için tasarlanmış gelişmiş bir seçenektir. Normal kullanım için Bot Creator sunucularını etkin tutun.';

  @override
  String get settings_startup_mode_title => 'Bot başlatma modu';

  @override
  String get settings_startup_mode_use_cloud =>
      'Bot Creator sunucularını kullan';

  @override
  String get settings_status_remove_confirm =>
      'Bu durum girişi kaldırılacak. Devam edilsin mi?';

  @override
  String get settings_tab => 'Ayarlar';

  @override
  String get settings_team_id_label => 'Ekip Kimliği: ';

  @override
  String settings_team_members_label(int count) {
    return 'Ekip Üyeleri ($count)';
  }

  @override
  String get settings_team_name_label => 'Ekip Adı: ';

  @override
  String get settings_team_owner_label => 'Ekip Lideri';

  @override
  String get settings_team_ownership => 'Ekip Sahipliği';

  @override
  String get settings_team_pill => 'EKİP';

  @override
  String get settings_version_title => 'Sürüm';

  @override
  String get settings_view_startup_logs => 'Başlangıç günlüklerini görüntüle';

  @override
  String get startup_copy_diagnostics => 'Tanılamaları kopyala';

  @override
  String get startup_diagnostics_copied => 'Tanılamalar panoya kopyalandı';

  @override
  String get startup_error_title => 'Başlangıç Hatası';

  @override
  String get startup_failed_message => 'Bot Creator bu cihazda başlatılamadı.';

  @override
  String get startup_refresh_diagnostics => 'Tanılamaları yenile';

  @override
  String get subscription_active_annual => 'Premium — Yıllık';

  @override
  String get subscription_active_label => 'Aktif plan:';

  @override
  String get subscription_active_monthly => 'Premium — Aylık';

  @override
  String get subscription_annual_title => 'Yıllık';

  @override
  String get subscription_benefit_fast_start =>
      'Botlar anında başlar, pop-up yok';

  @override
  String get subscription_benefit_no_ads =>
      'Uygulamanın hiçbir yerinde reklam yok';

  @override
  String get subscription_benefit_support =>
      'Bağımsız geliştirmeyi destekleyin';

  @override
  String get subscription_error =>
      'Satın alma tamamlanamadı. Lütfen tekrar deneyin.';

  @override
  String get subscription_error_product_unavailable =>
      'Bu plan şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get subscription_error_purchase_start_failed =>
      'Satın alma başlatılamadı. Lütfen tekrar deneyin.';

  @override
  String get subscription_error_store_unavailable =>
      'Uygulama Mağazası şu anda kullanılamıyor. Lütfen biraz sonra tekrar deneyin.';

  @override
  String get subscription_feature_analytics_desc =>
      'Hata oranı, gecikme yüzdelikleri ve dil içgörülerine erişin.';

  @override
  String get subscription_feature_analytics_title => 'Gelişmiş analitik';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Tam bir yeniden başlatma gerektiğinde botu otomatik olarak yeniden başlatın.';

  @override
  String get subscription_feature_auto_restart_title =>
      'Otomatik yeniden başlatma';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Yükü shard işçileri arasında dağıtarak büyük botları ölçeklendirin.';

  @override
  String get subscription_feature_auto_sharding_title => 'Otomatik sharding';

  @override
  String get subscription_feature_coming_soon => 'Yakında';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Hata ayıklama için komut eylemlerini adım adım kaydedin ve tekrar oynatın.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Görsel hata ayıklama tekrarı';

  @override
  String get subscription_feature_instant_start_desc =>
      'Botları ödüllü reklam kesintisi olmadan hemen başlatın.';

  @override
  String get subscription_feature_hosted_apps_title =>
      'Barindirilan uygulamalar';

  @override
  String get subscription_feature_hosted_apps_desc =>
      'Docker konteynerlerini sinirsiz barindirin — reklam yok.';

  @override
  String get subscription_feature_instant_start_title => 'Anında başlatma';

  @override
  String get subscription_feature_lavalink_desc =>
      'Play music and audio in Discord voice channels using Lavalink.';

  @override
  String get subscription_feature_lavalink_title => 'Lavalink audio support';

  @override
  String get subscription_feature_no_ads_desc =>
      'Uygulama deneyimi boyunca tüm reklam yerleşimlerini kaldırın.';

  @override
  String get subscription_feature_no_ads_title => 'Reklam yok';

  @override
  String get subscription_feature_scheduler_desc =>
      'İş akışlarını her X dakikada bir otomatik olarak çalıştırın (10 taneye kadar aktif).';

  @override
  String get subscription_feature_scheduler_title =>
      'Zamanlayıcı tetikleyicileri';

  @override
  String get subscription_feature_webhooks_desc =>
      'Güvenli webhook uç noktaları oluşturun ve çağrıları iş akışlarına yönlendirin.';

  @override
  String get subscription_feature_webhooks_title => 'Gelen webhooklar';

  @override
  String get subscription_manage => 'Aboneliği yönet';

  @override
  String get subscriptions_hub_title => 'Abonelikler';

  @override
  String get subscriptions_hub_subtitle =>
      'Bot Premium ve barındırılan uygulama planlarınızı görüntüleyin ve yönetin.';

  @override
  String get subscriptions_hub_open_settings => 'Abonelikler ve faturalandırma';

  @override
  String get subscriptions_hub_bot_premium_section => 'Bot Premium';

  @override
  String get subscriptions_hub_bot_premium_desc =>
      'Reklamları kaldırın ve Discord botlarınız için premium özelliklerin kilidini açın.';

  @override
  String get subscriptions_hub_hosted_section => 'Barındırılan uygulamalar';

  @override
  String get subscriptions_hub_hosted_desc =>
      'Reklam izlemeden bulutta Docker konteynerleri çalıştırın.';

  @override
  String get subscriptions_hub_status_active => 'Aktif';

  @override
  String get subscriptions_hub_status_inactive => 'Abone değil';

  @override
  String get subscriptions_hub_subscribe => 'Abone ol';

  @override
  String get subscriptions_hub_summary_both =>
      'Bot Premium ve barındırılan uygulamalar aktif';

  @override
  String get subscriptions_hub_summary_bot_only => 'Bot Premium aktif';

  @override
  String get subscriptions_hub_summary_hosted_only =>
      'Barındırılan uygulamalar aktif';

  @override
  String get subscriptions_hub_summary_none => 'Aktif abonelik yok';

  @override
  String subscriptions_hub_expires_at(String date, String time) {
    return '$date $time tarihine kadar yenilenir';
  }

  @override
  String get subscriptions_hub_permanent => 'Kalıcı (son kullanma tarihi yok)';

  @override
  String get subscriptions_hub_unlimited_bots => 'Sınırsız bot';

  @override
  String get subscriptions_hub_managed_by_server =>
      'Sunucu tarafından yönetiliyor';

  @override
  String get plan_limit_own_bots_title =>
      'Kendi botlarınız planınıza dahil değil';

  @override
  String get plan_limit_own_bots_desc =>
      'Planınız yalnızca hazır (turnkey) botlara erişim sağlar. Bu botu başlatmak için kendi botlarınızı içeren bir plana geçin.';

  @override
  String get plan_limit_bot_quota_title =>
      'Aynı anda çalışan bot sınırına ulaşıldı';

  @override
  String get plan_limit_bot_quota_desc =>
      'Planınız aynı anda çalışabilecek bot sayısını sınırlar. Bir botu durdurun veya üst bir plana geçin.';

  @override
  String plan_limit_bot_quota_ad_funded_desc(int count) {
    return 'Planınız aynı anda $count bot çalıştırır. Bu bot bunlara ek: reklam izleyerek kazanılan barındırma süresiyle çalışır ve süre bitince durur.';
  }

  @override
  String get plan_limit_quota_continue_ad => 'Reklamla finanse edilerek başlat';

  @override
  String get plan_limit_turnkey_title => 'Hazır botlar planınıza dahil değil';

  @override
  String get plan_limit_turnkey_desc =>
      'Planınız hazır botları ve barındırılan uygulamaları içermiyor. Bunları içeren bir plan seçin.';

  @override
  String get plan_limit_turnkey_quota_title => 'Hazır bot sınırına ulaşıldı';

  @override
  String get plan_limit_turnkey_quota_desc =>
      'Planınız aynı anda çalışabilecek hazır bot sayısını sınırlar. Birini durdurun veya üst bir plana geçin.';

  @override
  String get plan_limit_view_offers => 'Planları gör';

  @override
  String get subscription_upgrade_annual => 'Yıllık plana yükselt';

  @override
  String get subscription_upgrade_two_apps => '2 konteynere yükselt';

  @override
  String get subscription_manage_cancel_hint =>
      'İptal etmek veya faturalandırmayı değiştirmek için Aboneliği yönet\'i kullanın — App Store veya Google Play açılır.';

  @override
  String get subscription_monthly_title => 'Aylık';

  @override
  String get subscription_not_available_on_platform =>
      'Abonelikler şu anda yalnızca mobilde mevcuttur.';

  @override
  String get subscription_per_month => 'aylık';

  @override
  String get subscription_per_year => 'yıllık';

  @override
  String get subscription_plan_desc =>
      'Reklamları kaldırın ve tüm mevcut ve gelecek premium özelliklere erişim kazanın.';

  @override
  String get subscription_plan_label => 'Premium Temel';

  @override
  String get subscription_privacy => 'Gizlilik politikası';

  @override
  String get subscription_restore => 'Satın almaları geri yükle';

  @override
  String get subscription_restore_not_found => 'Aktif abonelik bulunamadı.';

  @override
  String get subscription_restored => 'Abonelik başarıyla geri yüklendi!';

  @override
  String subscription_save_badge(int percent) {
    return '%$percent TASARRUF ET';
  }

  @override
  String get subscription_subtitle =>
      'Tüm premium özelliklerin kilidini açmak için bir plan seçin.';

  @override
  String get subscription_success =>
      'Premium\'a hoş geldiniz! Tüm reklamlar kaldırıldı.';

  @override
  String get subscription_terms => 'Kullanım şartları';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_unavailable_platform => 'Bu platformda mevcut değil.';

  @override
  String get support_card_desc =>
      'Bir soru, bir hata, bir öneri? Ekibimiz ve topluluğumuzla sohbete gelin.';

  @override
  String get support_card_title => 'Destek ve Topluluk';

  @override
  String get support_discord_badge => 'Resmi destek';

  @override
  String get team_tab => 'Team';

  @override
  String get team_tab_short => 'Team';

  @override
  String get team_chat_title => 'Team & chat';

  @override
  String get team_chat_empty =>
      'No messages yet. Start the conversation with your team.';

  @override
  String get team_chat_input_hint => 'Write a message...';

  @override
  String get team_permissions_title => 'Permissions';

  @override
  String get team_chat_send => 'Send';

  @override
  String get team_chat_load_error => 'The team chat could not be loaded.';

  @override
  String get team_chat_send_error =>
      'Message not sent. Check your connection and try again.';

  @override
  String get team_collaborators_title => 'Collaborators';

  @override
  String get team_collaborators_empty =>
      'No collaborator yet. Add someone by their Discord user ID.';

  @override
  String get team_add_by_discord_id => 'Add by Discord user ID';

  @override
  String get team_add_discord_id_label => 'Discord user ID';

  @override
  String get team_add_error => 'The collaborator could not be added.';

  @override
  String get team_remove => 'Remove';

  @override
  String team_remove_confirm(String name) {
    return 'Remove $name from this bot\'s team? They will immediately lose access to the bot and to its chat.';
  }

  @override
  String get team_remove_error => 'The collaborator could not be removed.';

  @override
  String get team_not_in_portal_warning =>
      'This Discord user ID is not part of your application\'s team in the Discord Developer Portal. You can still add them: this bot will simply not show up in their portal team.';

  @override
  String get team_permission_edit_commands => 'Edit commands';

  @override
  String get team_permission_start_stop => 'Start and stop the bot';

  @override
  String get team_permission_claim_ads => 'Claim ad rewards';

  @override
  String get team_permission_invite => 'Invite the bot to servers';

  @override
  String get team_permission_view_chat => 'Read and write in the team chat';

  @override
  String get team_portal_section_title =>
      'Discord Developer Portal team (read-only)';

  @override
  String get team_unavailable =>
      'The team chat needs a connection to the Bot Creator server.';

  @override
  String get team_owner_badge => 'OWNER';

  @override
  String get home_section_my_bots => 'MY BOTS';

  @override
  String get home_section_shared_with_me => 'SHARED WITH ME';

  @override
  String get support_join_discord => 'Discord sunucusuna katıl';

  @override
  String get template_fun_description =>
      'Yazı tura, anketler ve sihirli 8-top.';

  @override
  String get template_fun_name => 'Eğlence Botu';

  @override
  String template_gallery_already_exists(String name) {
    return '\"$name\" komutu zaten mevcut ve atlandı.';
  }

  @override
  String get template_gallery_apply => 'Bu şablonu kullan';

  @override
  String template_gallery_apply_error(String error) {
    return 'Şablon uygulanamadı: $error';
  }

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return 'Şablondan $count komut ve $wCount iş akışı eklendi.';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count komut';
  }

  @override
  String get template_gallery_empty => 'Kullanılabilir şablon yok.';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return '$name için kaldırılacak bir şey yok.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Bu şablondaki tüm komutları ve iş akışlarını kaldırmak istediğinizden emin misiniz?';

  @override
  String get template_gallery_remove_title => 'Şablonu Kaldır';

  @override
  String get template_gallery_removed =>
      'Şablon komutları ve iş akışları kaldırıldı.';

  @override
  String get template_gallery_subtitle =>
      'Hazır bir şablonla botunuzu hızlıca başlatın.';

  @override
  String get template_gallery_sync_warning =>
      'Komutlar yerel olarak kaydedildi. Onları Discord\'a kaydetmek için botunuzu başlatın.';

  @override
  String get template_gallery_title => 'Şablonlar';

  @override
  String template_gallery_workflows_count(int count) {
    return '$count iş akışı';
  }

  @override
  String get template_moderation_description =>
      'Üyeleri yasaklayın, atın, susturun ve mesajları temizleyin.';

  @override
  String get template_moderation_name => 'Moderasyon Botu';

  @override
  String get template_utility_description =>
      'Ping, avatar bakma ve bot-konusur komutları.';

  @override
  String get template_utility_name => 'Araç Botu';

  @override
  String get template_welcome_description =>
      'Yeni üyeleri selamlayın, merhaba deyin ve sunucu bilgisini gösterin.';

  @override
  String get template_welcome_name => 'Karşılama Botu';

  @override
  String unit_day(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gün',
      one: '1 gün',
      zero: '0 gün',
    );
    return '$_temp0';
  }

  @override
  String unit_hour(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat',
      one: '1 saat',
      zero: '0 saat',
    );
    return '$_temp0';
  }

  @override
  String unit_minute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dakika',
      one: '1 dakika',
      zero: '0 dakika',
    );
    return '$_temp0';
  }

  @override
  String unit_month(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ay',
      one: '1 ay',
      zero: '0 ay',
    );
    return '$_temp0';
  }

  @override
  String get unit_short_month => 'Ay';

  @override
  String get unit_short_day => 'Gün';

  @override
  String get unit_short_hour => 'Saat';

  @override
  String get unit_short_minute => 'Dak';

  @override
  String get validation_awaited_callback_format =>
      'Beklenen geri arama \$awaitedCommand[ad;filtre] veya \$awaitedCommandError[ad] kullanmalıdır.';

  @override
  String validation_awaited_callback_length(int max) {
    return 'Beklenen geri arama tetikleyicisi en fazla $max karakter uzunluğunda olmalıdır';
  }

  @override
  String get validation_awaited_callback_local_only =>
      'Beklenen geri aramalar yalnızca yerel bir Ön Ek Komutu gerektirir.';

  @override
  String get validation_command_name_invalid_chars =>
      'Slash adları 1-32 küçük harf karakter olmalıdır. İzin verilenler: harfler, rakamlar, tire, alt çizgi ve kesme işareti.';

  @override
  String validation_command_name_length(int max) {
    return 'Komut adı en fazla $max karakter uzunluğunda olmalıdır';
  }

  @override
  String get validation_command_name_must_be_lowercase =>
      'Slash adları küçük harf varyantı varsa küçük harf kullanmalıdır.';

  @override
  String validation_command_payload_too_large(int current, int max) {
    return 'Bu slash komutu Discord\'un $max karakter sınırını aşıyor ($current kullanıldı). Adları, açıklamaları, seçenekleri veya seçimleri kısaltın.';
  }

  @override
  String get validation_command_name_no_ampersand =>
      'Komut adı ve (&) işareti ile başlayamaz';

  @override
  String get validation_command_name_no_at =>
      'Komut adı et (@) işareti ile başlayamaz';

  @override
  String get validation_command_name_no_exclamation =>
      'Komut adı ünlem işareti ile başlayamaz';

  @override
  String get validation_command_name_no_hash =>
      'Komut adı kare (#) işareti ile başlayamaz';

  @override
  String get validation_command_name_no_percent =>
      'Komut adı yüzde (%) işareti ile başlayamaz';

  @override
  String get validation_command_name_no_slash =>
      'Komut adı eğik çizgi ile başlayamaz';

  @override
  String get validation_command_name_no_spaces => 'Komut adı boşluk içeremez';

  @override
  String get validation_command_name_no_underscore =>
      'Komut adı alt çizgi ile başlayamaz';

  @override
  String get validation_command_name_required => 'Lütfen bir komut adı girin';

  @override
  String get validation_interaction_no_response =>
      'Etkileşim komutları en az bir yanıt eylemi içermelidir (Mesajla yanıtla, Bileşen V2 veya Modal).';

  @override
  String get validation_interaction_no_response_short => 'Yanıt eylemi yok';

  @override
  String get validation_invalid_permissions =>
      'Geçersiz varsayılan üye izinleri bit alanı. Pozitif bir tam sayı kullanın veya boş bırakın.';

  @override
  String get validation_legacy_chat_input_only =>
      'Ön ek modu yalnızca sohbet girişi (chat input) komutları için kullanılabilir.';

  @override
  String get validation_legacy_only_new_or_local =>
      'Yalnızca eski mod, sadece yeni komutlar veya mevcut yerel komutlar için kullanılabilir.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Yalnızca yerel komutlar için ön ek modunun etkinleştirilmesi gerekir.';

  @override
  String get validation_modal_not_legacy =>
      'Modal yanıtları eski komut modunda desteklenmez.';

  @override
  String get validation_option_description_required =>
      'Her seçeneğin bir açıklaması olmalıdır.';

  @override
  String get validation_option_group_only_subcommands =>
      'Bir SubCommandGroup yalnızca SubCommand seçenekleri içerebilir.';

  @override
  String get validation_option_group_top_level_only =>
      'SubCommandGroup\'a yalnızca üst düzeyde izin verilir.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'SubCommand ve SubCommandGroup seçimler tanımlayamaz.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'SubCommand ve SubCommandGroup minimum/maksimum değerler tanımlayamaz.';

  @override
  String get validation_option_hierarchy_not_required =>
      'SubCommand ve SubCommandGroup gerekli olarak işaretlenemez.';

  @override
  String get validation_option_leaf_no_nested =>
      'Normal seçenekler iç içe geçmiş seçenekler içeremez.';

  @override
  String get validation_option_max_entries =>
      'Her seçenek seviyesi en fazla 25 girişi destekler.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Aynı seviyede yinelenen seçenek adı \"$name\".';
  }

  @override
  String get validation_option_name_must_be_lowercase =>
      'Seçenek adları küçük harf varyantı varsa küçük harf kullanmalıdır.';

  @override
  String get validation_option_required_before_optional =>
      'Zorunlu seçenekler isteğe bağlı seçeneklerden önce listelenmelidir.';

  @override
  String get validation_option_name_required =>
      'Her seçeneğin bir adı olmalıdır.';

  @override
  String get validation_option_no_mix_top_level =>
      'Üst düzey seçenekler, alt komutları/grupları normal seçeneklerle karıştıramaz.';

  @override
  String get validation_option_subcommand_depth =>
      'Alt komut yuvalama derinliği Discord sınırlarını aşıyor.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Bir SubCommand iç içe geçmiş SubCommand veya SubCommandGroup içeremez.';

  @override
  String get variable_autocomplete_numeric_title => 'Dinamik sayısal öneriler';

  @override
  String get variable_autocomplete_title =>
      'Kullanılabilir değişkenler — eklemek için dokunun';

  @override
  String get variable_category_author => 'Yazar';

  @override
  String get variable_category_bot => 'Bot';

  @override
  String get variable_category_channel => 'Kanal';

  @override
  String get variable_category_context => 'Bağlam';

  @override
  String get variable_category_functions => 'Fonksiyonlar';

  @override
  String get variable_category_guild => 'Sunucu';

  @override
  String get variable_category_interaction => 'Etkileşim';

  @override
  String get variable_category_member => 'Üye';

  @override
  String get variable_category_message => 'Mesaj';

  @override
  String get variable_category_other => 'Diğer';

  @override
  String get variable_category_temp => 'Geçici';

  @override
  String get variable_category_user => 'Kullanıcı';

  @override
  String get webhooks_actions => 'Eylemler';

  @override
  String get webhooks_add_action => 'Webhook ekle';

  @override
  String get webhooks_add_title => 'Gelen webhook ekle';

  @override
  String get webhooks_copied => 'Tam webhook URL\'si kopyalandı.';

  @override
  String get webhooks_copy_path => 'Yolu kopyala';

  @override
  String get webhooks_copy_secret => 'Sırrı kopyala';

  @override
  String get webhooks_copy_url => 'URL\'yi kopyala';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhooklar: $count$limit';
  }

  @override
  String webhooks_delete_confirm(String label) {
    return '\"$label\" silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get webhooks_delete_confirm_no_label => 'Bu işlem geri alınamaz.';

  @override
  String get webhooks_delete_title => 'Gelen webhook silinsin mi?';

  @override
  String get webhooks_edit_title => 'Gelen webhook\'u düzenle';

  @override
  String get webhooks_empty => 'Henüz gelen webhook yok.';

  @override
  String get webhooks_generate => 'Oluştur';

  @override
  String get webhooks_invalid_runner_url => 'Runner URL\'si geçersiz.';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Gelen webhook sınırına ulaşıldı ($limit).';
  }

  @override
  String get webhooks_missing_data => 'Webhook yolu veya sırrı eksik.';

  @override
  String get webhooks_no_workflows =>
      'Bir gelen webhook eklemeden önce en az bir iş akışı oluşturun.';

  @override
  String get webhooks_page_title => 'Gelen Webhooklar';

  @override
  String get webhooks_path_copied => 'Yol kopyalandı.';

  @override
  String get webhooks_path_exists =>
      'Bu yol zaten mevcut. Başka bir tane seçin.';

  @override
  String get webhooks_path_hint => 'siparisler/yeni';

  @override
  String get webhooks_path_label => 'Yol';

  @override
  String get webhooks_runner_url_required =>
      'Tam webhook URL\'sini kopyalamak için önce bir Runner URL\'si yapılandırın.';

  @override
  String webhooks_save_failed(String error) {
    return 'Gelen webhook kaydedilemedi: $error';
  }

  @override
  String get webhooks_secret_copied => 'Sır kopyalandı.';

  @override
  String get webhooks_secret_label => 'Webhook sırrı';

  @override
  String get webhooks_target_label => 'İş akışı hedefi';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'İş Akışı: $workflow';
  }

  @override
  String get wizard_advanced_trigger => 'Gelişmiş tetikleyici ayarları';

  @override
  String get wizard_apply_quick_start => 'Hızlı başlangıcı taslağa uygula';

  @override
  String get wizard_bdfd_mode_enabled => 'BDFD betik modu etkin';

  @override
  String get wizard_code_advanced => 'Kod / Gelişmiş';

  @override
  String get wizard_command_body => 'Komut gövdesi';

  @override
  String get wizard_create_command => 'Komut oluştur';

  @override
  String get wizard_dart_mode_enabled => 'Dart betik modu etkin';

  @override
  String get wizard_edit_reply => 'Yanıt ayrıntılarını düzenle';

  @override
  String get wizard_legacy_options_subtitle =>
      'Eski komut seçenekleri ve yalnızca yerel davranış';

  @override
  String get wizard_quick_start_applied =>
      'Hızlı başlangıç komut taslağına uygulandı.';

  @override
  String get wizard_quick_start_subtitle =>
      'Başlangıç noktası olarak eski basit oluşturucuyu kullanın, ardından paylaşılan taslağa uygulayın.';

  @override
  String get wizard_quick_starts => 'Hızlı başlangıçlar';

  @override
  String get wizard_reply_summary => 'Yanıt özeti';

  @override
  String get wizard_save_command => 'Komutu kaydet';

  @override
  String get wizard_step_actions => 'Eylemler';

  @override
  String get wizard_step_infos => 'Bilgiler';

  @override
  String get wizard_step_reply => 'Yanıt';

  @override
  String get wizard_step_review => 'İncele';

  @override
  String get wizard_step_trigger_inputs => 'Tetikleyici ve Girişler';

  @override
  String get wizard_visual_mode_enabled => 'Görsel iş akışı modu etkin';

  @override
  String get workflow_argument_hint =>
      'İş akışı argümanı (\$arg üzerinden erişilebilir)';

  @override
  String get workflow_arguments_section => 'İş Akışı Argümanları';

  @override
  String get workflow_auto_defer => 'Otomatik ertele';

  @override
  String get workflow_auto_defer_actions => 'Eylemler varsa otomatik ertele';

  @override
  String get workflow_bdfd_editor_desc =>
      'Bu iş akışı yanıtı için tam BDFD kodunu yazın. Tanılamalar canlı olarak görüntülenir.';

  @override
  String get workflow_bdfd_editor_title => 'BDFD Betik Düzenleyici';

  @override
  String get workflow_condition_off => 'Koşul kapalı';

  @override
  String get workflow_condition_off_upper => 'Koşul KAPALI';

  @override
  String get workflow_condition_on => 'Koşul açık';

  @override
  String get workflow_condition_on_upper => 'Koşul AÇIK';

  @override
  String get workflow_dart_editor_desc =>
      'Bu iş akışı yanıtı için tam Dart kodunu yazın. Tanılamalar canlı olarak görüntülenir.';

  @override
  String get workflow_dart_editor_title => 'Dart Betik Düzenleyici';

  @override
  String workflow_edit_call_args(int count) {
    return 'Çağrı Argümanlarını Düzenle ($count)';
  }

  @override
  String get workflow_entry_point => 'Giriş Noktası';

  @override
  String get workflow_entry_point_helper =>
      'Boş olduğunda iş akışı giriş noktasına varsayılan olarak ayarlanır';

  @override
  String get workflow_entry_point_optional => 'Giriş Noktası (isteğe bağlı)';

  @override
  String get workflow_hint_name => 'örn. form_gonderimini_isle';

  @override
  String get workflow_manual => 'Manuel';

  @override
  String get workflow_mode_bdfd => 'BDFD Betiği';

  @override
  String get workflow_mode_bdfd_note =>
      'Tüm iş akışınızı tek bir BDFD betiği olarak yazın. Betik gerçek zamanlı olarak derlenir ve doğrulanır.';

  @override
  String get workflow_mode_dart => 'Dart Doğrudan';

  @override
  String get workflow_mode_dart_note =>
      'İş akışınızı Dart dilinde yazın. Hataları erkenden yakalamak için düzenleme sırasında tanılamalar güncellenir.';

  @override
  String get workflow_mode_desc =>
      'Görsel bir eylem oluşturucu veya tam bir BDFD betik düzenleyicisi arasında seçim yapın.';

  @override
  String get workflow_mode_title => 'İş akışı modu';

  @override
  String get workflow_mode_visual => 'Görsel';

  @override
  String get workflow_mode_visual_note =>
      'Kart düzenleyici ile tek tek eylemler ekleyerek iş akışınızı görsel olarak oluşturun.';

  @override
  String get workflow_no_auto_defer => 'Otomatik erteleme yok';

  @override
  String get workflow_no_workflow_note =>
      'Not: Herhangi bir iş akışı seçilmezse, bu modalı göndermek hiçbir şey yapmaz.';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'Gönderildiğinde \"$name\" iş akışı çalışacak (giriş: $entry, arg: $args).';
  }

  @override
  String get workflow_root_json_error => 'Kök bir JSON nesnesi olmalıdır';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return '\"$name\" iş akışı kaydedildi ($count eylem).';
  }

  @override
  String get workflow_set_call_args => 'Çağrı Argümanlarını Ayarla';

  @override
  String get workflow_visibility_ephemeral => 'Geçici (Ephemeral)';

  @override
  String get workflow_visibility_public => 'Genel';

  @override
  String get workflows_add_arg => 'Argüman ekle';

  @override
  String get workflows_arg_default => 'Varsayılan değer';

  @override
  String get workflows_arg_hint =>
      'Argümanlar ((arg.name)) ve ((workflow.arg.name)) olarak çalışma zamanı değişkenleri haline gelir.';

  @override
  String get workflows_arg_name => 'Ad';

  @override
  String get workflows_arg_required_short => 'Ger';

  @override
  String get workflows_arguments => 'Argümanlar';

  @override
  String get workflows_continue => 'Devam Et';

  @override
  String get workflows_copy_done_base64 =>
      'İş akışları Base64 olarak kopyalandı.';

  @override
  String get workflows_copy_done_json => 'İş akışları JSON olarak kopyalandı.';

  @override
  String get workflows_copy_none => 'Kopyalanacak iş akışı yok.';

  @override
  String get workflows_create => 'İş Akışı Oluştur';

  @override
  String get workflows_create_subtitle =>
      'Birkaç tıkta bot eylemlerini ve etkinliklerini otomatikleştirin';

  @override
  String get workflows_create_event => 'Etkinlik Oluştur';

  @override
  String get workflows_create_event_subtitle =>
      'Discord mesajlarına, üye katılımlarına ve etkinliklere yanıt verin';

  @override
  String workflows_delete_confirm(String name) {
    return '\"$name\" silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get workflows_delete_title => 'İş akışını sil';

  @override
  String get workflows_docs_tooltip => 'Belgelendirme merkezini aç';

  @override
  String get workflows_edit => 'İş Akışını Düzenle';

  @override
  String get workflows_empty => 'Henüz iş akışı yok';

  @override
  String get workflows_entry_point => 'Varsayılan Giriş Noktası';

  @override
  String get workflows_entry_point_hint =>
      'Arayan kişi bunu geçersiz kılmazsa kullanılır';

  @override
  String get workflows_event_available_vars => 'Kullanılabilir değişkenler';

  @override
  String get workflows_event_category => 'Etkinlik kategorisi';

  @override
  String get workflows_event_category_channels => 'Kanallar';

  @override
  String get workflows_event_category_invites => 'Davetler';

  @override
  String get workflows_event_category_members => 'Üyeler';

  @override
  String get workflows_event_category_messages => 'Mesajlar';

  @override
  String get workflows_event_channel_update => 'Kanal Güncelleme';

  @override
  String get workflows_event_channel_update_desc =>
      'Bir kanal güncellendiğinde tetiklenir.';

  @override
  String get workflows_event_hint =>
      'Bu iş akışını tetiklemesi gereken Discord etkinliğini seçin.';

  @override
  String get workflows_event_invite_create => 'Davet Oluşturma';

  @override
  String get workflows_event_invite_create_desc =>
      'Bir davet oluşturulduğunda tetiklenir.';

  @override
  String get workflows_event_member_join => 'Üye Katılımı';

  @override
  String get workflows_event_member_join_desc =>
      'Sunucuya yeni bir üye katıldığında tetiklenir.';

  @override
  String get workflows_event_member_remove => 'Üye Ayrılması';

  @override
  String get workflows_event_member_remove_desc =>
      'Bir üye sunucudan ayrıldığında veya çıkarıldığında tetiklenir.';

  @override
  String get workflows_event_message_create => 'Mesaj Oluşturma';

  @override
  String get workflows_event_message_create_desc =>
      'Yeni bir mesaj oluşturulduğunda tetiklenir.';

  @override
  String get workflows_event_message_delete => 'Mesaj Silme';

  @override
  String get workflows_event_message_delete_desc =>
      'Bir mesaj silindiğinde tetiklenir.';

  @override
  String get workflows_event_message_update => 'Mesaj Güncelleme';

  @override
  String get workflows_event_message_update_desc =>
      'Mevcut bir mesaj düzenlendiğinde tetiklenir.';

  @override
  String workflows_event_preview(String event) {
    return 'Dinlenen: $event';
  }

  @override
  String get workflows_event_section => 'Etkinlik İş Akışları';

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count eylem • Dinlenen: $event';
  }

  @override
  String get workflows_export_base64 => 'Base64 olarak kopyala';

  @override
  String get workflows_export_base64_desc => 'Hızlı paylaşım için kompakt.';

  @override
  String get workflows_export_json => 'JSON olarak kopyala';

  @override
  String get workflows_export_json_desc => 'Okunabilir ve düzenlemesi kolay.';

  @override
  String get workflows_export_tooltip => 'İş akışlarını kopyala';

  @override
  String get workflows_folder_hint => 'İsteğe bağlı klasör adı';

  @override
  String get workflows_folder_label => 'Klasör';

  @override
  String get workflows_general_section => 'Genel İş Akışları';

  @override
  String get workflows_import_action => 'İçe Aktar';

  @override
  String get workflows_import_desc =>
      'Bot Creator\'dan dışa aktarılan bir JSON yükü veya Base64(JSON) yapıştırın.';

  @override
  String workflows_import_done(int count) {
    return '$count iş akışı içe aktarıldı.';
  }

  @override
  String get workflows_import_empty => 'İçe aktarılacak veri yok.';

  @override
  String get workflows_import_input_hint =>
      'JSON veya Base64\'ü buraya yapıştırın...';

  @override
  String get workflows_import_invalid_format =>
      'Geçersiz format. JSON veya Base64(JSON) kullanın.';

  @override
  String get workflows_import_no_valid => 'Geçerli iş akışı bulunamadı.';

  @override
  String get workflows_import_overwrite => 'Ad zaten mevcutsa değiştir';

  @override
  String get workflows_import_title => 'İş akışlarını içe aktar';

  @override
  String get workflows_import_tooltip => 'İş akışlarını içe aktar';

  @override
  String get workflows_js_event_available_context_copy_hint =>
      'Komut dosyanıza kopyalamak için dokunun';

  @override
  String workflows_js_event_available_context_copied(String name) {
    return '$name kopyalandı';
  }

  @override
  String get workflows_js_event_available_context_sparse_note =>
      'Bu olayın ilk argümanı message/interaction/member/channel/guild olarak bağlanmaz. client ile variables/db kullanın veya tam yük için Discord.js belgelerine bakın.';

  @override
  String get workflows_js_event_available_context_subtitle =>
      'Bu global değişkenler bu olay için betiğinize enjekte edilir. ((message.content)) değil, discord.js özelliklerini kullanın (örn. message.author.username).';

  @override
  String get workflows_listen_for => 'Şunu dinle';

  @override
  String get workflows_move_to_folder => 'Klasöre taşı';

  @override
  String get workflows_name => 'İş Akışı Adı';

  @override
  String get workflows_new_folder_hint => 'Yeni klasör adı';

  @override
  String get workflows_no_match => 'Mevcut filtrelerle eşleşen iş akışı yok.';

  @override
  String get workflows_no_matches => 'Mevcut filtrelerle eşleşen iş akışı yok.';

  @override
  String get workflows_remove_from_folder => 'Klasörden kaldır';

  @override
  String get workflows_search_hint => 'İş akışlarında ara...';

  @override
  String workflows_subtitle(int count, String entry, String args) {
    return '$count eylem • giriş: $entry • arg: $args';
  }

  @override
  String get workflows_tab => 'İş Akışları';

  @override
  String get workflows_tab_short => 'Akış';

  @override
  String get workflows_title => 'İş Akışları';

  @override
  String get workflows_type_badge_event => 'Etkinlik';

  @override
  String get workflows_type_badge_general => 'Genel';

  @override
  String get workflows_type_event => 'Etkinlik iş akışı';

  @override
  String get workflows_type_event_desc =>
      'Discord bir etkinlik yayınladığında otomatik olarak tepki verir.';

  @override
  String get workflows_type_general => 'Genel iş akışı';

  @override
  String get workflows_type_general_desc =>
      'Komutlardan, düğmelerden, modallardan veya diğer iş akışlarından çağrılan yeniden kullanılabilir mantık.';

  @override
  String get workflows_type_title => 'İş akışı türü';

  @override
  String get settings_sync_title => 'Senkronizasyon';

  @override
  String get settings_sync_force_title => 'Komut Senkronizasyonunu Zorla';

  @override
  String get settings_sync_force_desc =>
      'Discord\'da eksik olan komutları yeniden oluşturur ve Bot Creator\'da artık tanımlı olmayanları siler.';

  @override
  String get settings_sync_force_button => 'Discord ile Eşitle';

  @override
  String get settings_sync_force_dialog_title => 'Senkronizasyonu Zorla';

  @override
  String get settings_sync_force_dialog_desc =>
      'Discord\'da eksik olan komutlar yeniden oluşturulacak, Bot Creator\'da artık tanımlı olmayan komutlar silinecek. Devam edilsin mi?';

  @override
  String get settings_sync_force_dialog_confirm => 'Zorla Eşitle';

  @override
  String settings_sync_force_success_counts(
    int created,
    int relinked,
    int deleted,
  ) {
    return 'Eşitleme tamamlandı: Discord\'da $created yeniden oluşturuldu, $relinked yeniden bağlandı, $deleted silindi.';
  }

  @override
  String get settings_sync_force_no_local_commands =>
      'Kaydedilecek yerel komut yok: Discord\'da hiçbir şey değiştirilmedi (boş bir eşitleme tüm komutlarınızı silerdi).';

  @override
  String settings_sync_force_error(Object error) {
    return 'Zorunlu senkronizasyon başarısız oldu: $error';
  }

  @override
  String get settings_runtime_engine_switch_dialog_title =>
      'Çalışma zamanı motoru değiştirilsin mi?';

  @override
  String get settings_runtime_engine_switch_dialog_desc =>
      'Bu yıkıcı bir işlemdir.\n\n• Yerel veriler silinmeden önce yapılandırmanız buluta yedeklenir.\n• Değişiklik yalnızca botu yeniden başlattıktan sonra geçerli olur.\n• Tüm yerel komutlar, iş akışları ve zamanlanmış tetikleyiciler kaldırılacak.\n• Discord\'a kayıtlı tüm komutlar da silinecek.\n\nHer şeyi Sürüm Geçmişi\'nden geri yükleyebilirsiniz (yerel olarak otomatik geri yükleme).';

  @override
  String get settings_runtime_engine_switch_dialog_confirm => 'Motoru değiştir';

  @override
  String get settings_runtime_engine_switch_success =>
      'Çalışma zamanı motoru güncellendi. Hazır olduğunuzda botu yeniden başlatın.';

  @override
  String settings_runtime_engine_switch_error(String error) {
    return 'Çalışma zamanı motoru değiştirilemedi: $error';
  }

  @override
  String get settings_runtime_engine_switch_empty_payload =>
      'Geçiş iptal edildi: yeni yapılandırma boş olurdu (komut, olay, webhook veya değişken yok). Yerel komutlarınız ve iş akışlarınız değiştirilmedi.';

  @override
  String get app_create_select_type_title => 'Uygulama Türünü Seçin';

  @override
  String get app_create_select_type_desc =>
      'Başlamak için oluşturmak istediğiniz uygulama türünü seçin.';

  @override
  String get app_create_type_discord => 'Discord Botu';

  @override
  String get app_create_type_discord_desc =>
      'Eylemler, olaylar ve dinamik tuval panelleri ile özelleştirilebilir bir Discord botu oluşturun ve çalıştırın.';

  @override
  String get app_create_type_hosted => 'Hazır Bot';

  @override
  String get app_create_type_hosted_desc =>
      '7/24 barındırılan kullanıma hazır bir botu (müzik, moderasyon, araçlar...) saniyeler içinde dağıtın.';

  @override
  String get app_create_coming_soon => 'Çok yakında';

  @override
  String get app_create_sample_title => 'Örnek komut oluştur';

  @override
  String app_create_sample_desc(String botName) {
    return '$botName için örnek bir /ping komutu eklemek ister misiniz? \"Pong!\" ile yanıt verir ve Bot Creator\'un nasıl çalıştığını öğrenmek için harika bir başlangıç noktasıdır.';
  }

  @override
  String get app_create_sample_skip => 'Atla';

  @override
  String get app_create_sample_confirm => 'Örnek /ping ekle';

  @override
  String get app_create_sample_success => '/ping komutu başarıyla oluşturuldu';

  @override
  String get commands_empty_title => 'İlk komutunu oluştur!';

  @override
  String get commands_empty_description =>
      'Bir komut, biri Discord\'da /birşey yazdığında botunun yanıt vermesini sağlar.';

  @override
  String get commands_empty_create_button => 'Komut oluştur';

  @override
  String get commands_empty_marketplace_link =>
      'Veya bir Marketplace şablonuyla başla';

  @override
  String get command_created_success_title => 'Komutun hazır!';

  @override
  String get command_created_success_subtitle => 'Şimdi ne yapmak istiyorsun?';

  @override
  String get command_created_start_bot => 'Botumu başlat';

  @override
  String get command_created_start_bot_hint =>
      'Botunun Giriş sekmesini aç ve çevrimiçi yapmak için Başlat\'a dokun.';

  @override
  String get command_created_invite => 'Bir sunucuya davet et';

  @override
  String get command_created_invite_error => 'Davet bağlantısı açılamadı.';

  @override
  String get command_created_create_another => 'Başka bir komut oluştur';

  @override
  String get command_created_close => 'Kapat';

  @override
  String get beginner_mode_label => 'Başlangıç modu';

  @override
  String get beginner_mode_on_hint => 'Sadece temel sekmeler gösteriliyor';

  @override
  String get beginner_mode_off_hint => 'Tüm özellikler gösteriliyor';

  @override
  String get commands_empty_sample_ping => 'Örnek /ping komutu ekle';

  @override
  String get command_created_sample_success =>
      '/ping komutu oluşturuldu! \"Pong!\" diye yanıt verir.';

  @override
  String get onboarding_create_now => 'Botu şimdi oluştur';

  @override
  String get onboarding_command_now => 'İlk komutunu oluştur';

  @override
  String get container_list_title => 'Hazır Botlar';

  @override
  String get container_list_session_missing => 'Oturum kullanılamıyor';

  @override
  String get container_list_session_hint => 'Lütfen önce hesabınıza bağlanın.';

  @override
  String get container_list_error => 'Botlar yüklenirken başarısız oldu';

  @override
  String get container_list_retry => 'Tekrar Dene';

  @override
  String get container_list_empty => 'Hazır bot yok';

  @override
  String get container_list_empty_hint =>
      '1 tıkla ilk kullanıma hazır botunuzu dağıtın.';

  @override
  String get container_list_deploy_btn => 'Hazır Bot Dağıt';

  @override
  String get container_list_unsupported_badge => 'Desteklenmiyor';

  @override
  String get container_list_expired => 'Süresi doldu';

  @override
  String container_list_expiry_minutes(int minutes) {
    return '$minutes dakika kaldı';
  }

  @override
  String container_list_expiry_hours(int hours, int minutes) {
    return '$hours saat $minutes dakika kaldı';
  }

  @override
  String container_list_expiry_days(int days, int hours) {
    return '$days gün $hours saat kaldı';
  }

  @override
  String get container_deploy_title => 'Hazır Bot Dağıt';

  @override
  String get container_deploy_template_section => 'Kullanıma Hazır Şablon';

  @override
  String get container_deploy_managed_hosting => '7/24 Yönetilen Barındırma';

  @override
  String get container_deploy_bot_config_section =>
      'Discord Bot Yapılandırması';

  @override
  String get container_deploy_paste_token_hint =>
      'Discord bot belirtecini (token) buraya yapıştırın';

  @override
  String get container_deploy_env_fields_section => 'Ortam değişkenleri';

  @override
  String get container_deploy_env_server_provided =>
      'Sunucu tarafından sağlanır';

  @override
  String container_deploy_env_field_required(String field) {
    return '$field alanı zorunludur.';
  }

  @override
  String get container_deploy_discord_prereqs => 'Discord Ön Koşulları';

  @override
  String get container_deploy_launch_btn => 'Hazır Botu Başlat';

  @override
  String get container_deploy_image_label => 'Görüntü';

  @override
  String get container_deploy_image_hint =>
      'Etiketli Docker görüntüsü (örn. ghcr.io/albertgmz/beatdock:latest)';

  @override
  String get container_deploy_template_label => 'Şablon';

  @override
  String get container_deploy_template_easy_music => 'Kolay Müzik Botu';

  @override
  String get container_deploy_template_custom => 'Özel görüntü';

  @override
  String get container_deploy_easy_music_hint =>
      'Yalnızca Discord bot jetonunuz gerekir. Herkese açık Lavalink sunucularını kullanır — kayıt defteri girişi, API anahtarı veya ekstra kurulum yok.';

  @override
  String get container_deploy_pick_bot => 'Mevcut bir bot kullan';

  @override
  String get container_deploy_pick_bot_manual => 'Jetonu elle gir';

  @override
  String get container_deploy_bot_token_hint =>
      'Discord Geliştirici Portalı\'nda bir bot oluşturun, Message Content Intent\'i etkinleştirin ve sunucunuza davet edin.';

  @override
  String get container_deploy_bot_token_required =>
      'Discord bot jetonu gereklidir';

  @override
  String get container_deploy_image_required => 'Görüntü gereklidir';

  @override
  String get container_deploy_cpu_label => 'CPU (milis)';

  @override
  String get container_deploy_cpu_min => 'Min 128';

  @override
  String get container_deploy_memory_label => 'Bellek (MB)';

  @override
  String get container_deploy_memory_min => 'Min 128 MB';

  @override
  String get container_deploy_storage_label => 'Depolama (GB)';

  @override
  String get container_deploy_storage_min => 'Min 1 GB';

  @override
  String get container_deploy_ttl_label => 'TTL (dakika)';

  @override
  String get container_deploy_ttl_min => 'Min 1 dakika';

  @override
  String get container_deploy_env_label => 'Ortam Degiskenleri';

  @override
  String get container_deploy_env_key_hint => 'ANAHTAR';

  @override
  String get container_deploy_env_value_hint => 'deger';

  @override
  String get container_deploy_submit => 'Dagit';

  @override
  String get container_deploy_submitting => 'Dagitiliyor...';

  @override
  String get container_deploy_not_auth => 'Kimlik dogrulanmadi';

  @override
  String container_deploy_success(String containerId) {
    return '$containerId dagitiliyor...';
  }

  @override
  String get container_deploy_submitted_starting =>
      'Hosted app submitted — starting up now...';

  @override
  String container_deploy_failed(String error) {
    return 'Dagitim basarisiz: $error';
  }

  @override
  String container_deploy_token_invalid(String error) {
    return 'Geçersiz Discord bot belirteci: $error';
  }

  @override
  String get container_deploy_blocked_container_limit =>
      'You\'ve reached your hosted app limit. Delete or stop an existing hosted app to free up a slot before deploying another.';

  @override
  String get container_deploy_blocked_no_minutes =>
      'You\'re out of free hosting minutes. Watch a rewarded ad to unlock more minutes, or go Premium for unlimited hosting.';

  @override
  String get container_deploy_blocked_cloud_disabled =>
      'Bu sunucuda bulut barındırma etkin değil: uzaktan dağıtım kullanılamıyor. Botu yerel olarak veya kendi runner\'ın üzerinden çalıştır.';

  @override
  String get container_deploy_blocked_eligibility_error =>
      'Couldn\'t check whether you can deploy right now.';

  @override
  String container_deploy_ad_slot_full(int granted) {
    return '+$granted hosting minutes earned, but your container slot is still full. Delete or stop an existing hosted app to deploy a new one.';
  }

  @override
  String get container_detail_state => 'Durum';

  @override
  String get container_detail_expires => 'Bitis';

  @override
  String get container_detail_extend_ttl => 'TTL Uzat';

  @override
  String get container_detail_stop_title => 'Kapsayiciyi Durdur';

  @override
  String get container_detail_stop_confirm =>
      'Bu, kapsayiciyi sonlandiracak ve verileri kaybolacaktir.';

  @override
  String get container_detail_stop_btn => 'Durdur';

  @override
  String get container_detail_stopped_ok => 'Kapsayici durduruldu';

  @override
  String get container_detail_start_btn => 'Başlat';

  @override
  String get container_detail_starting => 'Başlatılıyor...';

  @override
  String get container_detail_started_ok => 'Konteyner başlatılıyor';

  @override
  String get container_detail_open => 'Ayrıntılar';

  @override
  String get container_detail_delete_title => 'Konteyneri sil';

  @override
  String get container_detail_delete_confirm =>
      'Bu, konteyneri veritabanından ve buluttan kalıcı olarak siler. Geri alınamaz.';

  @override
  String get container_detail_delete_btn => 'Sil';

  @override
  String get container_detail_deleted_ok => 'Konteyner silindi';

  @override
  String get container_detail_stopped_hint =>
      'Bu konteyner kapatıldı. Ortam değişkenlerini yeniden girmeden yeniden başlatabilirsiniz.';

  @override
  String get container_detail_update_resources => 'Kaynaklari Güncelle';

  @override
  String get container_detail_update_btn => 'Güncelle';

  @override
  String get container_detail_updated_ok => 'Kaynaklar güncellendi';

  @override
  String get container_detail_extend_hint => 'Eklenecek dakika';

  @override
  String get container_detail_extend_btn => 'Uzat';

  @override
  String get container_detail_extended_ok => 'TTL uzatildi';

  @override
  String get container_detail_console => 'Konsol';

  @override
  String container_logs_errors_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hata',
      one: '1 hata',
      zero: 'Hata yok',
    );
    return '$_temp0';
  }

  @override
  String get container_detail_deploying => 'Kapsayici dagitiliyor...';

  @override
  String container_detail_status_stopped(String state) {
    return 'Bu kapsayici $state.';
  }

  @override
  String get container_detail_not_connected => 'Bagli degil';

  @override
  String get container_detail_console_connecting => 'Baglaniyor...';

  @override
  String get container_detail_console_closed => '--- Baglanti kapatildi ---';

  @override
  String get container_detail_console_hint => 'Bir komut yazin...';

  @override
  String container_detail_failed(String error) {
    return 'Basarisiz: $error';
  }

  @override
  String get container_state_running => 'Çalisiyor';

  @override
  String get container_state_pending => 'Beklemede';

  @override
  String get container_state_provisioning => 'Provisioning';

  @override
  String get container_state_stopped => 'Durduruldu';

  @override
  String get container_state_stopping => 'Durduruluyor';

  @override
  String get container_state_failed => 'Basarisiz';

  @override
  String get container_health_image_pull_failed =>
      'Couldn\'t pull the container image. Check that the image name and tag are correct and that any required registry credentials are set.';

  @override
  String get container_health_crash_loop =>
      'The container keeps crashing shortly after starting. Check your environment variables and logs.';

  @override
  String get container_health_starting => 'Still starting up...';

  @override
  String get container_hosted_subtitle =>
      'Kullanıma hazır botları (müzik vb.) 1 tıkla dağıtın';

  @override
  String get container_premium_badge => 'Premium';

  @override
  String container_detail_title(String id) {
    return 'Bot $id';
  }

  @override
  String get container_list_premium_host_anytime_tooltip =>
      'Premium — istediğiniz zaman barındırın';

  @override
  String get container_list_premium_host_anytime_fab =>
      'İstediğiniz zaman barındırın';

  @override
  String get container_list_free_limit_reached =>
      'Ücretsiz limit doldu (1 bot). Daha fazlası için abone olun.';

  @override
  String get container_hosted_premium_host_anytime =>
      'İstediğiniz zaman barındırın';

  @override
  String get container_hosted_premium_host_anytime_compact =>
      'Abone ol — istediğiniz zaman barındırın';

  @override
  String get container_hosted_premium_desc =>
      'Hazır botları 7/24 sınırsız barındırın — reklam yok. Abonelik gerekir.';

  @override
  String get container_hosted_premium_view_btn => 'Planları gör';

  @override
  String get hosted_app_subscription_title => 'Hazır Botlar';

  @override
  String get hosted_app_subscription_subtitle =>
      'Kullanıma hazır botları bulutta kesintisiz 7/24 barındırın.';

  @override
  String get hosted_app_subscription_benefit_unlimited =>
      'Sınırsız barındırma süresi';

  @override
  String get hosted_app_subscription_benefit_no_ads => 'Ödüllü reklam gerekmez';

  @override
  String get hosted_app_subscription_one_app_title => '1 barındırılan bot';

  @override
  String get hosted_app_subscription_one_app_desc =>
      'İstediğiniz zaman 1 hazır bot barındırın';

  @override
  String get hosted_app_subscription_two_app_title => '2 barındırılan bot';

  @override
  String get hosted_app_subscription_two_app_desc =>
      'En fazla iki hazır bot barındırın';

  @override
  String get hosted_app_subscription_recommended => 'En iyi deger';

  @override
  String get container_hosted_free_title =>
      'Ucretsiz barindirma (en fazla 1 konteyner)';

  @override
  String container_hosted_expires_at(String dateTime) {
    return 'Bitis: $dateTime';
  }

  @override
  String container_hosted_topup_ad_hint(int reward) {
    return 'Bu konteynere $reward dk eklemek icin reklam izleyin (birikir).';
  }

  @override
  String container_hosted_at_limit_open_detail(int active, int max) {
    return 'Konteyner aktif ($active/$max). Reklamla uzatmak icin acin.';
  }

  @override
  String container_hosted_minutes_available(int minutes) {
    return '$minutes dk barindirma kullanilabilir (birikir).';
  }

  @override
  String get container_hosted_resume_with_time =>
      'Bu konteynerde hâlâ barındırma süreniz var. Devam etmek için Başlat\'a dokunun.';

  @override
  String container_hosted_watch_ad_earn(int reward) {
    return '$reward dk barindirma kazanmak icin reklam izleyin.';
  }

  @override
  String container_hosted_ad_button(int reward) {
    return 'Reklam +$reward dk';
  }

  @override
  String container_hosted_balance_after_ad(int minutes) {
    return 'Son reklamdan sonra bakiye: $minutes dk';
  }

  @override
  String container_deploy_ad_unlock_success(int granted, int balance) {
    return '+$granted dk barindirma (toplam: $balance dk).';
  }

  @override
  String container_deploy_ad_unlock_failed(String error) {
    return 'Acma basarisiz: $error';
  }

  @override
  String get container_deploy_requires_premium_or_ad =>
      'Konteyner dagitmak icin Premium abonelik veya odullu reklam gerekli.';

  @override
  String get container_deploy_premium_account => 'Premium hesap';

  @override
  String container_deploy_premium_containers(int max, int active) {
    return 'En fazla $max aktif konteyner ($active/$max).';
  }

  @override
  String get container_deploy_ephemeral_storage =>
      'Gecici depolama (kalici birim yok)';

  @override
  String get container_deploy_private_image => 'Özel görüntü';

  @override
  String get container_deploy_private_image_hint =>
      'Özel görüntüleri çekmek için kayıt defteri kimlik bilgilerini girin (örn. GHCR).';

  @override
  String get container_deploy_use_custom_credentials =>
      'Özel kimlik bilgileri kullan';

  @override
  String get container_deploy_registry_profile =>
      'Kayıtlı kayıt defteri profili';

  @override
  String get container_deploy_registry_profile_none => 'Profil seç';

  @override
  String container_deploy_registry_detected(String host) {
    return 'Kayıt defteri: $host';
  }

  @override
  String get container_deploy_save_registry_auth =>
      'Kimlik bilgilerini yeniden kullanım için kaydet';

  @override
  String get container_deploy_registry_auth_required =>
      'Özel görüntüler için kullanıcı adı ve şifre gereklidir.';

  @override
  String get container_deploy_registry_profile_required =>
      'Kayıtlı bir kayıt defteri profili seçin veya özel kimlik bilgileri kullanın.';

  @override
  String get registry_credentials_title => 'Kayıt defteri kimlik bilgileri';

  @override
  String get registry_credentials_add => 'Kimlik bilgisi ekle';

  @override
  String get registry_credentials_edit => 'Kimlik bilgilerini düzenle';

  @override
  String get registry_credentials_manage =>
      'Kayıt defteri kimlik bilgilerini yönet';

  @override
  String get registry_credentials_empty =>
      'Henüz kayıtlı kayıt defteri kimlik bilgisi yok.';

  @override
  String get registry_credentials_label => 'Etiket';

  @override
  String get registry_credentials_label_required => 'Etiket gereklidir';

  @override
  String get registry_credentials_host => 'Kayıt defteri ana bilgisayarı';

  @override
  String get registry_credentials_host_required =>
      'Kayıt defteri ana bilgisayarı gereklidir';

  @override
  String get registry_credentials_username => 'Kullanıcı adı';

  @override
  String get registry_credentials_username_required =>
      'Kullanıcı adı gereklidir';

  @override
  String get registry_credentials_password => 'Şifre veya jeton';

  @override
  String get registry_credentials_password_required =>
      'Şifre veya jeton gereklidir';

  @override
  String get registry_credentials_password_hint =>
      'Kişisel erişim jetonu veya kayıt defteri şifresi';

  @override
  String get registry_credentials_password_edit_hint =>
      'Mevcut şifreyi korumak için boş bırakın';

  @override
  String get registry_credentials_ghcr_hint =>
      'GHCR için read:packages kapsamına sahip bir GitHub PAT kullanın.';

  @override
  String get registry_credentials_delete_title =>
      'Kimlik bilgileri silinsin mi?';

  @override
  String registry_credentials_delete_body(String label) {
    return '\"$label\" silinsin mi? Bu işlem geri alınamaz.';
  }

  @override
  String get registry_credentials_deleted =>
      'Kayıt defteri kimlik bilgileri silindi';

  @override
  String registry_credentials_delete_failed(String error) {
    return 'Kimlik bilgileri silinemedi: $error';
  }

  @override
  String registry_credentials_save_failed(String error) {
    return 'Kimlik bilgileri kaydedilemedi: $error';
  }

  @override
  String container_detail_private_registry(String host, String username) {
    return 'Özel kayıt defteri: $host · $username';
  }

  @override
  String container_detail_topup_applied(int minutes) {
    return 'Bu konteynere +$minutes dk eklendi.';
  }

  @override
  String container_detail_topup_credited(int minutes) {
    return '+$minutes dk yuklendi.';
  }

  @override
  String container_detail_apply_stored_minutes(int minutes) {
    return 'Kayitli $minutes dk uygula';
  }

  @override
  String container_detail_minutes_applied(int minutes) {
    return '$minutes dk uygulandi.';
  }

  @override
  String get docs_hub_title => 'Dokumantasyon';

  @override
  String get docs_tab_guide => 'Rehber';

  @override
  String get docs_tab_bot_creator => 'Bot Creator Docs';

  @override
  String get docs_tab_discordjs => 'discord.js';

  @override
  String get docs_webview_error => 'Dokumantasyon yuklenemedi';

  @override
  String get docs_webview_unavailable =>
      'In-app documentation preview is not available on this device. Open the docs in your browser instead.';

  @override
  String get docs_open_in_browser => 'Tarayicida ac';

  @override
  String get docs_reload => 'Yeniden yukle';

  @override
  String get common_duplicate => 'Çoğalt';

  @override
  String get commands_batch_select => 'Toplu seçim';

  @override
  String commands_selected_count(int count) {
    return '$count seçili';
  }

  @override
  String get image_editor_title => 'Görüntü Düzenleyici';

  @override
  String get image_editor_add_operation => 'İşlem ekle';

  @override
  String get image_editor_add_layer => 'Katman ekle';

  @override
  String get image_editor_operations => 'İşlemler';

  @override
  String get image_editor_op_container => 'Kapsayıcı / Çerçeve';

  @override
  String get image_editor_op_progress_bar => 'İlerleme çubuğu';

  @override
  String get image_editor_op_composite_image => 'Görüntüyü birleştir';

  @override
  String get image_editor_op_set_pixel => 'Piksel ayarla';

  @override
  String get image_editor_op_invert => 'Renkleri ters çevir';

  @override
  String get image_editor_op_grayscale => 'Gri tonlamaya dönüştür';

  @override
  String get image_editor_op_rotate => 'Tuvali döndür';

  @override
  String get image_editor_zoom_in => 'Yakınlaştır';

  @override
  String get image_editor_zoom_out => 'Uzaklaştır';

  @override
  String get image_editor_zoom_fit => 'Ekrana sığdır';

  @override
  String get image_editor_undo => 'Geri al';

  @override
  String get image_editor_redo => 'Yinele';

  @override
  String get image_editor_canvas => 'Tuval';

  @override
  String get image_editor_width => 'Genişlik';

  @override
  String get image_editor_height => 'Yükseklik';

  @override
  String get image_editor_properties => 'Özellikler';

  @override
  String get image_editor_visible => 'Görünür';

  @override
  String get image_editor_opacity => 'Opaklık';

  @override
  String image_editor_ops_summary(int count, int hidden) {
    return '$count işlem, $hidden gizli';
  }

  @override
  String image_editor_empty_hint(String op) {
    return 'Başlamak için bir \"$op\" işlemi ekleyin';
  }

  @override
  String get image_editor_tap_to_edit => 'Düzenlemek için dokunun';

  @override
  String get image_editor_no_operations => 'Henüz işlem yok';

  @override
  String get image_editor_select_operation =>
      'Özelliklerini düzenlemek için bir işlem seçin';

  @override
  String get image_editor_insert_variable => 'Değişken ekle';

  @override
  String get image_editor_variable_label => 'Değişken';

  @override
  String get image_editor_variable_hint =>
      'Filtrelemek için yazın veya aşağıdaki öneriye dokunun';

  @override
  String get image_editor_insert => 'Ekle';

  @override
  String get image_editor_pick_image => 'Resim dosyası seç';

  @override
  String get image_editor_color_picker => 'Renk seçici';

  @override
  String get image_editor_hue => 'Ton';

  @override
  String get image_editor_saturation => 'Doygunluk';

  @override
  String get image_editor_no_url => 'URL yok';

  @override
  String get image_editor_unknown => 'Bilinmiyor';

  @override
  String get image_editor_field_text => 'Metin';

  @override
  String get image_editor_field_font_size => 'Yazı boyutu';

  @override
  String get image_editor_field_max_width => 'Maks. genişlik';

  @override
  String get image_editor_field_text_align => 'Metin hizası';

  @override
  String get image_editor_field_blend => 'Karışım';

  @override
  String get image_editor_field_fill => 'Doldur';

  @override
  String get image_editor_field_radius => 'Yarıçap';

  @override
  String get image_editor_field_thickness => 'Kalınlık';

  @override
  String get image_editor_field_shape => 'Şekil';

  @override
  String get image_editor_field_percentage => 'Yüzde';

  @override
  String get image_editor_field_bar_color => 'Çubuk rengi';

  @override
  String get image_editor_field_track_color => 'Hat rengi';

  @override
  String get image_editor_field_text_color => 'Metin rengi';

  @override
  String get image_editor_field_border_width => 'Kenarlık genişliği';

  @override
  String get image_editor_field_border_radius => 'Kenarlık yarıçapı';

  @override
  String get image_editor_field_orientation => 'Yön';

  @override
  String get image_editor_field_angle => 'Açı (derece)';

  @override
  String get image_editor_field_container => 'Kapsayıcı';

  @override
  String get image_editor_field_background_color => 'Arka plan rengi';

  @override
  String get image_editor_hint_auto_size => 'otomatik (özgün boyut)';

  @override
  String get image_editor_hint_optional_background => 'isteğe bağlı arka plan';

  @override
  String get image_editor_hint_parent_container => 'üst kapsayıcı adı';

  @override
  String get image_editor_hint_container_width =>
      'hizalama için kapsayıcı genişliği';

  @override
  String get action_card_duration => 'Süre';

  @override
  String get action_card_error_message => 'Hata Mesajı';

  @override
  String get action_card_jump_to => 'Şuraya atla';

  @override
  String get action_card_maximum => 'Maksimum';

  @override
  String get action_card_minimum => 'Minimum';

  @override
  String get action_card_skip_count => 'Atlanacak sayı';

  @override
  String get action_edit_request => 'İsteği düzenle';

  @override
  String get action_error_jump => 'Eyleme Atla';

  @override
  String get action_error_skip => 'N eylemi atla';

  @override
  String get component_max_length => 'Maksimum Uzunluk';

  @override
  String get component_min_length => 'Minimum Uzunluk';

  @override
  String get http_request_header_name => 'Başlık adı';

  @override
  String get http_request_json_body => 'JSON Gövdesi';

  @override
  String get http_request_section_body => 'Gövde';

  @override
  String get http_request_section_headers => 'Başlıklar';

  @override
  String get http_request_section_request => 'İstek';

  @override
  String get http_request_text_body => 'Metin Gövdesi';

  @override
  String marketplace_summary_commands(int count) {
    return '$count komut';
  }

  @override
  String marketplace_summary_variables(int count, int required) {
    return '$count değişken ($required gerekli)';
  }

  @override
  String marketplace_summary_workflows(int count) {
    return '$count iş akışı';
  }

  @override
  String get modal_builder_configure_submit_actions =>
      'Gönderme Eylemlerini Yapılandır';

  @override
  String get modal_builder_edit_submit_actions =>
      'Gönderme Eylemlerini Düzenle';

  @override
  String get modal_builder_identity => 'Kimlik';

  @override
  String get modal_builder_submit_actions => 'Gönderme Eylemleri';

  @override
  String get announcement_see_more => 'Daha fazla bilgi';

  @override
  String get announcement_dismiss => 'Kapat';

  @override
  String get announcement_acknowledge => 'Anladım';

  @override
  String get announcement_later => 'Daha sonra';

  @override
  String get announcement_link_open_failed => 'Bağlantı açılamadı.';

  @override
  String get container_invite_btn => 'Botu davet et';

  @override
  String get container_invite_busy => 'Davet ediliyor...';

  @override
  String get container_invite_unavailable =>
      'Bu uygulamanın botu tanımlanamadı: token yok veya iptal edilmiş. Dağıtımı yeniden başlatın.';

  @override
  String get container_invite_failed =>
      'Davet gönderilemedi: bağlantınızı kontrol edip yeniden deneyin.';

  @override
  String get container_invite_open_failed => 'Davet bağlantısı açılamadı.';

  @override
  String get bot_payload_refused_local_kept =>
      'Gönderim reddedildi: Gönderilecek yapılandırma boştu (komut, olay, webhook veya değişken yok). Hiçbir şey gönderilmedi ve yerel yapılandırmanız olduğu gibi kaldı — düzenlemeye devam edebilirsiniz.';

  @override
  String get bot_config_overshrink_title =>
      'Bu küçültülmüş yapılandırmayı göndermek istediğinizden emin misiniz?';

  @override
  String get bot_config_overshrink_body =>
      'Bu botun yapılandırmasının büyük bölümünü sildiniz. Henüz hiçbir şey gönderilmedi: sunucu hâlâ önceki sürümü çalıştırıyor ve yerel yapılandırmanız olduğu gibi duruyor.';

  @override
  String get bot_config_overshrink_send_anyway => 'Yine de gönder';

  @override
  String get bot_config_overshrink_keep_local => 'Yerel kalsın, gönderme';

  @override
  String get command_history_title => 'Bu komutun sürüm geçmişi';

  @override
  String get command_history_empty =>
      'Bu komut için henüz hiç sürüm kaydedilmedi. Sürümler kaydettikten sonra burada görünür.';

  @override
  String get command_history_restore => 'Geri yükle';

  @override
  String command_history_version_meta(Object author, Object date, num size) {
    String _temp0 = intl.Intl.pluralLogic(
      size,
      locale: localeName,
      other: '$size bayt',
      one: '1 bayt',
    );
    return '$author · $date · $_temp0';
  }

  @override
  String get command_history_conflict =>
      'Bu sürüm geri yüklenmedi: siz yükledikten sonra komut sunucuda değişti. Hiçbir yere yazılmadı — gerçekten üzerine yazmak için sunucudaki sürümü yeniden yükleyin.';

  @override
  String get command_history_conflict_reload =>
      'Sunucudaki sürümü yeniden yükle ve üzerine yaz';

  @override
  String get command_history_unavailable_no_v2 =>
      'Bu bot için geçmiş kullanılamıyor: sunucu henüz granular /api/v2 API\'sini sunmuyor, bu yüzden hiçbir sürüm listelenemez veya geri yüklenemez. Bu boş bir geçmiş değil.';

  @override
  String get command_history_unavailable_offline =>
      'Sürüm listesi alınamadı (çevrimdışı veya sunucuya ulaşılamıyor). Sürümler bu cihazda hiç saklanmaz, bu yüzden liste sunucudan alınmalıdır.';

  @override
  String get command_history_restore_confirm =>
      'Bu sürüm geri yüklensin mi? Sunucuda bulunan mevcut içerik bu sürümün içeriğiyle değiştirilecek. Geri yükleme işlemi yeni bir sürüm olarak kaydedilir, böylece geri alınabilir kalır.';

  @override
  String get menu_file => 'Dosya';

  @override
  String get menu_new_bot => 'Yeni bot';

  @override
  String get menu_close_window => 'Pencereyi kapat';

  @override
  String get menu_edit => 'Düzen';

  @override
  String get menu_undo => 'Geri al';

  @override
  String get menu_redo => 'Yinele';

  @override
  String get menu_cut => 'Kes';

  @override
  String get menu_copy => 'Kopyala';

  @override
  String get menu_paste => 'Yapıştır';

  @override
  String get menu_select_all => 'Tümünü seç';

  @override
  String get menu_view => 'Görünüm';

  @override
  String get menu_theme => 'Tema';

  @override
  String get menu_window => 'Pencere';

  @override
  String get menu_help => 'Yardım';

  @override
  String get menu_preferences => 'Tercihler…';

  @override
  String get menu_website => 'Web sitesi';

  @override
  String bot_config_versions_restore_error_detail(String reason) {
    return 'Sürüm geri yüklenemedi: $reason';
  }

  @override
  String get bot_config_versions_restore_refused =>
      'Sunucu geri yüklemeyi onaylamadı. Hiçbir şey geri yüklenmedi.';

  @override
  String bot_config_versions_restore_local_failed(String reason) {
    return 'Sürüm sunucuda geri yüklendi ancak yerel uygulama başarısız oldu: $reason';
  }

  @override
  String get import_engine_title => 'Çalışma zamanı motoru';

  @override
  String get import_engine_missing =>
      'Bu ZIP bir motor belirtmiyor. Bu botun kullanacağı motoru seçin:';

  @override
  String import_engine_declared(String engine) {
    return 'ZIP tarafından belirtilen motor: $engine';
  }

  @override
  String import_engine_will_switch(String from, String to) {
    return 'Bot bir sonraki yeniden başlatmada $from yerine $to kullanacak.';
  }

  @override
  String get import_engine_dart_label => 'Bot Creator (Dart / bloklar)';

  @override
  String get import_engine_javascript_label => 'JavaScript (runner-js)';

  @override
  String get bot_config_versions_restore_too_small =>
      'Sunucu bu sürümü reddetti: yapılandırmayı oluşturamayacak kadar küçük — geri yüklemek botu boşaltır. Daha dolu bir sürüm seçin.';

  @override
  String get bot_config_versions_force_restore_title =>
      'Bu sürüm boyutuna rağmen geri yüklensin mi?';

  @override
  String get bot_config_versions_force_restore_body =>
      'Sunucu bunu yapılandırma için çok küçük buluyor ve kendi başına uygulamıyor. Geri yükleme istenen bir geri dönüştür: zorlayabilirsin.';

  @override
  String get bot_config_versions_force_restore_confirm => 'Yine de geri yükle';

  @override
  String get bot_config_versions_force_restore_keep => 'Mevcut sürümü koru';

  @override
  String get bot_config_versions_restore_too_small_unforced =>
      'Sunucu hâlâ reddediyor: manager bu sürüm için zorunlu geri yüklemeyi kabul etmeli.';

  @override
  String get ai_credits_title => 'Yapay Zeka Kredileri';

  @override
  String get ai_credits_unavailable =>
      'Yapay zeka kredileri kullanılamıyor. Tekrar deneyin.';

  @override
  String get ai_credits_origin_kofi => 'Ko-fi satın alımı';

  @override
  String get ai_credits_origin_apple => 'Apple satın alımı';

  @override
  String get ai_credits_origin_google => 'Google satın alımı';

  @override
  String get ai_credits_origin_roulette => 'Çark ödülü';

  @override
  String get ai_credits_origin_admin_grant => 'Yönetici tahsisi';

  @override
  String get ai_credits_origin_admin_correction => 'Yönetici düzeltmesi';

  @override
  String get ai_credits_origin_copilot => 'Yapay zeka kullanımı';

  @override
  String get ai_credits_ad_pending =>
      'Reklam doğrulaması bekleniyor. Bakiyenizi yenileyin.';

  @override
  String get ai_credits_ad_unavailable =>
      'Reklam kullanılamıyor veya doğrulanmadı.';

  @override
  String get ai_credits_spin_failed =>
      'Sonuç alınamadı. Bu çevirmeyi kurtarmak için tekrar deneyin.';

  @override
  String get ai_credits_wallet_card_title => 'Yapay Zeka Cüzdanınız';

  @override
  String get ai_credits_available => 'Kullanılabilir yapay zeka kredileri';

  @override
  String get ai_credits_label_total => 'Toplam';

  @override
  String get ai_credits_label_reserved => 'Ayrılmış';

  @override
  String get ai_credits_spending_blocked => 'Yapay zeka harcamaları engellendi';

  @override
  String get ai_credits_label_purchased => 'Satın Alımlar';

  @override
  String get ai_credits_label_rewarded => 'Çark';

  @override
  String get ai_credits_label_granted => 'Tahsisler';

  @override
  String ai_credits_spins_available(int count) {
    return '$count kullanılabilir çevirme';
  }

  @override
  String get ai_credits_usage_hint =>
      'Kullanım, mesajlarınıza ve gerçekleştirilen işlemlere bağlıdır.';

  @override
  String get ai_credits_daily_ad_limit_hint =>
      'Günde en fazla 3 reklam (UTC). Bonus ve kullanılmayan çevirmeler saklanır.';

  @override
  String ai_credits_result_spins(int count) {
    return '+$count çevirme!';
  }

  @override
  String ai_credits_result_credits(String count) {
    return '+$count kredi!';
  }

  @override
  String get ai_credits_button_spin => 'Çarkı çevir';

  @override
  String ai_credits_button_watch_ad(int remaining) {
    return 'Reklam izle (+1 çevirme) — $remaining kaldı';
  }

  @override
  String get ai_credits_history_title => 'Kredi geçmişi';

  @override
  String get ai_credits_history_empty => 'Hareket yok.';

  @override
  String get ai_credits_reference => 'Referans';

  @override
  String get ai_credits_open_conversation => 'Sohbeti aç';

  @override
  String get ai_credits_previous => 'Önceki';

  @override
  String get ai_credits_next => 'Sonraki';

  @override
  String get copilot_title => 'Yapay Zeka Yardımcısı';

  @override
  String get copilot_compact_label => 'YZ';

  @override
  String get copilot_err_tool_round_limit =>
      'Yapay zeka yeni bilgi edinmeden aynı işlemleri tekrarladı. Başka bir yaklaşım denemek için talimat gönderin.';

  @override
  String get copilot_err_context_limit =>
      'Bağlam çok uzun. Bir özet ile yeni bir sohbette devam edin.';

  @override
  String get copilot_err_spending_blocked =>
      'Bu hesap için yapay zeka harcamaları engellendi.';

  @override
  String get copilot_err_revision_conflict =>
      'Sohbet başka bir cihazda değişti. Yenileyin.';

  @override
  String get copilot_err_action_claimed =>
      'Bir eylem onay veya çözüm bekliyor.';

  @override
  String get copilot_err_insufficient_balance =>
      'Bu isteği ve bağlamını ayırmak için yetersiz bakiye.';

  @override
  String get copilot_err_unauthorized =>
      'Yardımcıyı kullanmak için oturum açın.';

  @override
  String get copilot_err_not_found => 'Sohbete veya bota erişilemiyor.';

  @override
  String get copilot_err_unavailable =>
      'Yönetici üzerinde yardımcı kullanılamıyor.';

  @override
  String get copilot_err_request_failed =>
      'İstek tamamlanamadı. Durumunu kurtarmak için yenileyin.';

  @override
  String get copilot_approve_dialog_title => 'Yardımcı eylemini onayla';

  @override
  String get copilot_bot_label => 'Bot';

  @override
  String get copilot_remote_manager => 'Uzak Yönetici';

  @override
  String get copilot_this_device => 'Bu cihaz';

  @override
  String get copilot_action_details_title => 'Eylem ayrıntıları';

  @override
  String get copilot_cancel => 'İptal';

  @override
  String get copilot_execute => 'Çalıştır';

  @override
  String get copilot_tool_start_bot => 'Botu başlat';

  @override
  String get copilot_tool_stop_bot => 'Botu durdur';

  @override
  String get copilot_tool_create_command => 'Komut oluştur';

  @override
  String get copilot_tool_update_command => 'Komutu güncelle';

  @override
  String get copilot_tool_library_search => 'Komut kitaplığında ara';

  @override
  String get copilot_tool_create_from_library =>
      'Kitaplıktaki komuttan oluştur';

  @override
  String get copilot_tool_patch_command => 'Komut betiğini düzenle';

  @override
  String get copilot_library_title => 'Komut kitaplığı';

  @override
  String get copilot_library_contribute => 'Test edilmiş komutlarımı paylaş';

  @override
  String get copilot_library_hint =>
      'Asistanın sizin için oluşturduğu ve testi geçen komutlar, herkesin daha hızlı ve daha ucuz yanıt almasına yardımcı olan ortak bir kitaplığa eklenebilir. Discord kimlikleri, gizli bilgiler ve kimliğiniz önceden kaldırılır. Bunu istediğiniz zaman kapatabilirsiniz; hesabınızı silmek katkılarınızı da siler.';

  @override
  String get copilot_action_library => 'Komut kitaplığı';

  @override
  String get copilot_tool_read_docs => 'Belgeleri oku';

  @override
  String get copilot_tool_inspect_bot => 'Botu incele';

  @override
  String get copilot_rename_title => 'Yeniden Adlandır';

  @override
  String get copilot_save => 'Kaydet';

  @override
  String get copilot_export_dialog_title => 'Sohbeti dışa aktar';

  @override
  String get copilot_delete_confirm_title => 'Sohbet silinsin mi?';

  @override
  String get copilot_delete_confirm_body =>
      'İçerik silinecektir. Kredi hareketleri korunacaktır.';

  @override
  String get copilot_delete => 'Sil';

  @override
  String get copilot_continue_summary_title => 'Özet ile devam et';

  @override
  String get copilot_continue_summary_body =>
      'Özet, yapay zeka kredisi tüketir (girdi + çıktı). En son mesajlar bağlam sınırları içinde özetlenecektir. Orijinal sohbet korunacaktır.';

  @override
  String get copilot_create_continuation => 'Devamını oluştur';

  @override
  String get copilot_mcp_local_title => 'Yerel MCP bağlantısı';

  @override
  String get copilot_mcp_approval_note =>
      'Değişiklikler burada onay gerektirir.';

  @override
  String get copilot_close => 'Kapat';

  @override
  String get copilot_history_tooltip => 'Geçmiş';

  @override
  String get copilot_new_discussion => 'Yeni sohbet';

  @override
  String get copilot_options_tooltip => 'Seçenekler';

  @override
  String get copilot_action_refresh => 'Yenile';

  @override
  String get copilot_action_credits => 'Yapay Zeka Kredileri';

  @override
  String get copilot_action_mcp_connection => 'MCP bağlantısı';

  @override
  String get copilot_action_archive => 'Arşivle / geri yükle';

  @override
  String get copilot_action_export => 'Markdown olarak dışa aktar';

  @override
  String get copilot_action_continue => 'Özet ile devam et';

  @override
  String get copilot_action_recover_response => 'Yanıtı kurtar';

  @override
  String get copilot_action_retry => 'İsteği yeniden dene';

  @override
  String get copilot_global_discussion => 'Genel sohbet';

  @override
  String get copilot_location_local => 'Yerel';

  @override
  String get copilot_location_remote => 'Uzak';

  @override
  String get copilot_available => 'Kullanılabilir';

  @override
  String get copilot_reserved => 'Ayrılmış';

  @override
  String get copilot_total => 'Toplam';

  @override
  String get copilot_welcome_title => 'Botunuz için bir yardım eli mi lazım?';

  @override
  String get copilot_welcome_subtitle =>
      'Bir fikir keşfedin, bir komutu kontrol edin veya bir değişiklik hazırlayın. Kontrol her zaman sizde.';

  @override
  String get copilot_suggestion_check_title => 'Botumu kontrol et';

  @override
  String get copilot_suggestion_check_prompt =>
      'Botumun durumunu kontrol et ve sonraki adımları öner.';

  @override
  String get copilot_suggestion_command_title => 'Bir komut oluştur';

  @override
  String get copilot_suggestion_command_prompt =>
      'Botum için yeni bir komut hazırlamama yardım et.';

  @override
  String get copilot_suggestion_feature_title => 'Bir özelliği anla';

  @override
  String get copilot_suggestion_feature_prompt =>
      'Bot Creator özelliklerini nasıl kullanacağımı açıkla.';

  @override
  String get copilot_history_section_title => 'Sohbete devam et';

  @override
  String get copilot_role_you => 'Siz';

  @override
  String get copilot_role_assistant => 'Yardımcı';

  @override
  String get copilot_generating => 'Oluşturuluyor…';

  @override
  String get copilot_copy_message => 'Mesajı kopyala';

  @override
  String copilot_credits_in_discussion(String count) {
    return 'Bu sohbette $count yapay zeka kredisi kullanıldı';
  }

  @override
  String get copilot_input_hint => 'Mesajınız';

  @override
  String get copilot_send => 'Gönder';

  @override
  String get copilot_status_approval_required => 'Onay gerekli';

  @override
  String get copilot_status_ready_to_inspect => 'İncelemeye hazır';

  @override
  String get copilot_status_executing => 'Çalıştırılıyor';

  @override
  String get copilot_status_succeeded => 'Başarılı';

  @override
  String get copilot_status_declined => 'Reddedildi';

  @override
  String get copilot_status_unconfirmed =>
      'Çalıştırma doğrulanmadı — botu inceleyin';

  @override
  String get copilot_status_failed => 'Başarısız';

  @override
  String get copilot_technical_details => 'Teknik ayrıntılar';

  @override
  String get copilot_approve => 'Onayla';

  @override
  String get copilot_inspect => 'İncele';

  @override
  String get copilot_decline => 'Reddet';

  @override
  String get copilot_close_without_replay => 'Tekrar çalıştırmadan kapat';

  @override
  String get copilot_close_unconfirmed_warning =>
      'Sonucu bilinmeyen bu eylemi kapatmadan önce botu kontrol edin.';

  @override
  String get copilot_close_action => 'Kapat';

  @override
  String get copilot_history_sheet_title => 'Sohbet geçmişi';

  @override
  String get copilot_search_title_hint => 'Başlık ara';

  @override
  String get copilot_filter_by_bot => 'Bota göre filtrele';

  @override
  String get copilot_all_bots => 'Tüm botlar';

  @override
  String get copilot_archives => 'Arşivler';

  @override
  String get copilot_no_conversations => 'Sohbet yok.';

  @override
  String get copilot_badge_global => 'Genel';

  @override
  String get copilot_load_more => 'Daha fazla yükle';

  @override
  String get copilot_copy_code => 'Kodu kopyala';

  @override
  String get copilot_tool_options => 'Komut argümanlarını düzenle';

  @override
  String get copilot_tool_settings => 'Komut ayarlarını düzenle';

  @override
  String get copilot_tool_create_workflow => 'Otomasyon oluştur';

  @override
  String get copilot_tool_update_workflow => 'Otomasyonu düzenle';

  @override
  String get copilot_tool_presence => 'Durumu ve etkinliği değiştir';

  @override
  String get copilot_tool_profile => 'Bot adını değiştir';

  @override
  String get copilot_tool_variable => 'Değişken kaydet';

  @override
  String get copilot_tool_schedule => 'Otomasyon zamanla';

  @override
  String get copilot_tool_webhook => 'Harici tetikleyici yapılandır';

  @override
  String get settings_text_size_title => 'Metin boyutu';

  @override
  String get settings_text_size_description =>
      'Uygulamanın metin boyutunu cihazınızın metin ayarına göre değiştirir.';

  @override
  String get settings_text_size_preview =>
      'Önizleme: komutlarınız, iş akışlarınız ve konuşmalarınız.';

  @override
  String get settings_text_size_reset => 'Metin boyutunu sıfırla';

  @override
  String get bot_config_versions_cloud_checkpoints => 'Bulut kayıt noktaları';

  @override
  String get bot_config_versions_checkpoint_hint =>
      'Gönderme veya çekme sırasında tam bir bulut sürümü kaydedilir. Geri yükleme de bir güvenlik kopyası saklar.';

  @override
  String get bot_config_versions_remote_authority =>
      'Bulut sürümü yerel yapılandırmanın yerini alır. Bulutta bulunmayan komutlar ve iş akışları yerelden kaldırılır.';

  @override
  String get history_preview => 'İçeriği görüntüle';

  @override
  String get history_delete_confirm =>
      'Bu kayıtlı sürüm kalıcı olarak silinsin mi? Geçerli yapılandırma değişmeden kalır.';

  @override
  String get history_action_failed =>
      'Bu geçmiş işlemi tamamlanamadı. Lütfen tekrar deneyin.';

  @override
  String get bot_create_title => 'Bot oluştur';

  @override
  String get bot_create_description =>
      'Discord botunu bağla ve nasıl oluşturacağını seç.';

  @override
  String get bot_create_visual_title => 'Bloklar & BDFD';

  @override
  String get bot_create_visual_description =>
      'Görsel eylemler veya BDFD betikleriyle oluştur.';

  @override
  String get bot_create_javascript_description =>
      'Botunu Discord.js ile JavaScript kullanarak programla.';

  @override
  String get editor_section_creation => 'Oluşturma';

  @override
  String get editor_section_automation => 'Otomasyon';

  @override
  String get editor_section_management => 'Yönetim';

  @override
  String get bot_create_mode => 'Oluşturma modu';

  @override
  String get bot_home_hosting_title => 'Barındırma';

  @override
  String get bot_home_logs_filter_label => 'Günlükleri filtrele';

  @override
  String get bot_home_logs_filter_info => 'Bilgi';

  @override
  String get bot_home_logs_filter_errors => 'Hatalar';

  @override
  String bot_home_commands_see_all(int count) {
    return '$count öğenin tümünü gör';
  }

  @override
  String bot_home_actions_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count eylem',
      one: '1 eylem',
    );
    return '$_temp0';
  }

  @override
  String get home_title_my_bots => 'Botlarım';

  @override
  String get home_more_actions => 'Diğer eylemler';

  @override
  String get home_getting_started => 'Başlarken';

  @override
  String get modules_group_create => 'Oluşturma';

  @override
  String get modules_group_automation => 'Otomasyon';

  @override
  String get modules_group_management => 'Yönetim';

  @override
  String get modules_desc_workflows =>
      'Eylemlerini ve olaylarını otomatikleştir';

  @override
  String get modules_desc_globals => 'Tüm komutlar arasında paylaşılır';

  @override
  String get modules_desc_emojis => 'Botun uygulama emojileri';

  @override
  String get modules_desc_scheduler => 'Her X dakikada bir workflow çalıştırır';

  @override
  String get modules_desc_webhooks =>
      'Bir workflow\'a yönlendirilen HTTP çağrıları';

  @override
  String get modules_desc_team => 'Ortaklar ve ekip sohbeti';

  @override
  String get modules_desc_guilds => 'Botun bulunduğu sunucular';

  @override
  String get option_section_identity => 'Kimlik';

  @override
  String get option_section_type => 'Değer türü';

  @override
  String get option_section_behavior => 'Davranış';

  @override
  String get option_translations => 'Çeviriler';

  @override
  String get option_delete_action => 'Seçeneği sil';

  @override
  String get option_preview_title => 'Discord\'da önizleme';

  @override
  String get option_preview_legend =>
      'Mor alt çizgi: zorunlu · gri: isteğe bağlı';

  @override
  String option_choices_count(int count) {
    return '$count seçenek';
  }
}
