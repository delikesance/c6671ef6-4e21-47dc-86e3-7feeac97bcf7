// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class StudioLocalizationsTr extends StudioLocalizations {
  StudioLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navDocs => 'Dokumantasyon';

  @override
  String get navHosting => 'Hazır Botlar';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get navBack => 'Geri';

  @override
  String get navCommands => 'Komutlar';

  @override
  String get navCommandsShort => 'Komut';

  @override
  String get navCopilot => 'Yapay Zeka Yardımcısı';

  @override
  String get navFlows => 'Akış';

  @override
  String get navVars => 'Değiş';

  @override
  String get navSched => 'Zam';

  @override
  String get navHooks => 'Gelen webhooklar';

  @override
  String get navEmojis => 'Emoji';

  @override
  String get navTeam => 'Team';

  @override
  String get navGuilds => 'Sunucular';

  @override
  String get navDashboard => 'Panel';

  @override
  String get navReplay => 'Hata Ayıklayıcı Tekrarı';

  @override
  String get navModules => 'Modules';

  @override
  String get navBeginner => 'Başlangıç modu';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesSearch => 'Ara';

  @override
  String get modulesGroupCreate => 'Oluşturma';

  @override
  String get modulesGroupAutomation => 'Otomasyon';

  @override
  String get modulesGroupManagement => 'Yönetim';

  @override
  String get modulesGroupTools => 'Tools';

  @override
  String get modulesWorkflows => 'İş Akışları';

  @override
  String get modulesVariables => 'Genel Değişkenler';

  @override
  String get modulesEmojis => 'Emojiler';

  @override
  String get modulesScheduler => 'Zamanlayıcı';

  @override
  String get modulesDescWorkflows => 'Eylemlerini ve olaylarını otomatikleştir';

  @override
  String get modulesDescVariables => 'Tüm komutlar arasında paylaşılır';

  @override
  String get modulesDescEmojis => 'Botun uygulama emojileri';

  @override
  String get modulesDescScheduler => 'Her X dakikada bir workflow çalıştırır';

  @override
  String get modulesDescHooks => 'Bir workflow\'a yönlendirilen HTTP çağrıları';

  @override
  String get modulesDescTeam => 'Ortaklar ve ekip sohbeti';

  @override
  String get modulesDescGuilds => 'Botun bulunduğu sunucular';

  @override
  String get modulesDescDashboard => 'Command usage over 24 h, 7 d, 30 d';

  @override
  String get modulesDescReplay => 'Komut çalıştırmalarının adım adım tekrarı';

  @override
  String get modulesDescCopilot => 'Assistant to build your commands';

  @override
  String get beginnerOnHint => 'Sadece temel sekmeler gösteriliyor';

  @override
  String get beginnerOffHint => 'Tüm özellikler gösteriliyor';

  @override
  String get commonRetry => 'Tekrar Dene';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonCancel => 'İptal';

  @override
  String get commonRefresh => 'Yenile';

  @override
  String get statusOnline => 'Çevrimiçi';

  @override
  String get statusStopped => 'Durduruldu';

  @override
  String get loadError => 'Yükleme hatası';

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
  String get loginDiscord => 'Discord ile bağlan';

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
  String get accountSignOut => 'Oturumu kapat';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get languageSystem => 'Sistem';

  @override
  String get botsOverline => 'My projects';

  @override
  String get botsTitle => 'Botlarım';

  @override
  String get botsCreate => 'Bot oluştur';

  @override
  String get botsManage => 'Yönet';

  @override
  String get botStop => 'Durdur';

  @override
  String get botStart => 'Botu Başlat';

  @override
  String get botsEmptyTitle => 'Henüz uygulamanız yok.';

  @override
  String get botsEmptyHint =>
      '“Bot oluştur” düğmesiyle ilk botunu oluştur: burada görünecek.';

  @override
  String get hostingIncludedTitle => 'Barındırma dahil';

  @override
  String get hostingIncludedValue => 'Aboneliğinle sınırsız';

  @override
  String get hostingRemainingTitle => 'Kalan süre';

  @override
  String get hostingExpired => 'Barındırma süresi doldu';

  @override
  String get hostingSessionActive => 'Aktif oturum';

  @override
  String get hostingSessionActiveOnline => 'Aktif oturum (çevrimiçi)';

  @override
  String get hostingPreservedTitle => 'Süre korunuyor';

  @override
  String hostingReserve(String time) {
    return 'Reserve: $time';
  }

  @override
  String get hostingReserveAvailable => 'Yedek süre (duraklatıldı)';

  @override
  String get hostingPreservedDetail => 'Bot durdurulduğu sürece süre korunur.';

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
  String get createBotSamplePing => 'Örnek /ping komutu ekle';

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
  String get commandsSearch => 'Komutlarda ara...';

  @override
  String get commandsEmpty =>
      'No commands yet. Create one from the Bot Creator app.';

  @override
  String get commandsNoMatch => 'Mevcut filtrelerle eşleşen komut yok.';

  @override
  String get premiumHint =>
      'Your account is on the free plan: subscriptions are activated from the mobile app (Studio shows no ads or purchases).';

  @override
  String get featureSchedulerTitle => 'Zamanlayıcı tetikleyicileri';

  @override
  String get featureSchedulerDesc =>
      'İş akışlarını her X dakikada bir otomatik olarak çalıştırın (10 taneye kadar aktif).';

  @override
  String get featureAnalyticsTitle => 'Premium analitik';

  @override
  String get featureAnalyticsDesc =>
      'Hata oranı, gecikme yüzdelikleri ve dil içgörülerinin kilidini açın.';

  @override
  String get featureHooksTitle => 'Gelen webhooklar';

  @override
  String get featureHooksDesc =>
      'Güvenli webhook uç noktaları oluşturun ve çağrıları iş akışlarına yönlendirin.';

  @override
  String get featureReplayTitle => 'Görsel hata ayıklama tekrarı';

  @override
  String get featureReplayDesc =>
      'Hata ayıklama için komut eylemlerini adım adım kaydedin ve tekrar oynatın.';

  @override
  String get commonSaved => 'Kaydedildi';

  @override
  String get commonAdd => 'Ekle';

  @override
  String get deleteIrreversible => 'Bu işlem kalıcıdır.';

  @override
  String deleteNamedTitle(String name) {
    return '“$name” silinsin mi?';
  }

  @override
  String get commandNew => 'Yeni komut';

  @override
  String get commandSaved => 'Komut kaydedildi.';

  @override
  String get commandChangedElsewhere =>
      'Bu bot başka bir yerde (uygulama veya başka bir oturum) değiştirildi. Kaydetmeden önce komutu yeniden yükleyin.';

  @override
  String get scriptEdit => 'Betiği düzenle';

  @override
  String get commandTriggerHybrid => 'Slash + metin mesajı';

  @override
  String get workflowNew => 'Yeni iş akışı';

  @override
  String get workflowsEmpty =>
      'İş akışı yok. Bir eylem dizisini yeniden kullanmak veya bir olaya tepki vermek için bir tane oluşturun.';

  @override
  String get workflowSaved => 'İş akışı kaydedildi.';

  @override
  String get workflowDeleteBody =>
      'Bu iş akışını çağıran komutlar artık çalıştıracak bir şey bulamaz.';

  @override
  String get workflowTypeGeneral => 'Genel (bir komut tarafından çağrılır)';

  @override
  String get workflowCategory => 'Kategori';

  @override
  String workflowScriptNotice(String mode) {
    return 'Bu iş akışı $mode ile yazılmış: Studio yalnızca görsel iş akışlarını düzenler. Olduğu gibi kayıtlı kalır.';
  }

  @override
  String get variablesGlobalSubtitle => 'Tüm bot için hatırlanan veriler.';

  @override
  String get variablesScopedHint =>
      'Bir tanım varsayılan değeri belirler; ardından her sunucu, kanal veya üye kendi değerini tutar.';

  @override
  String get variableScopedRemoveNote =>
      'Tanım kaldırılır; önceden kaydedilmiş değerler silinmez.';

  @override
  String get copilotNoCredits =>
      'Yapay zeka kredisi yetersiz. Mobil uygulamadan yükleyin.';

  @override
  String get copilotChatTooLong =>
      'Bu sohbet çok uzun: yeni bir tane başlatın.';

  @override
  String get copilotUnavailable => 'Yardımcı şu anda kullanılamıyor.';

  @override
  String get copilotGenerationFailed => 'Oluşturma başarısız oldu.';

  @override
  String get copilotDeleteChat => 'Sohbeti sil';

  @override
  String copilotWants(String tool) {
    return 'Yardımcı şunu yapmak istiyor: $tool';
  }

  @override
  String get dashboardRuns => 'Yürütmeler';

  @override
  String get dashboardSinceStart => 'Başlangıçtan beri';

  @override
  String get dashboardLatencyP50P95 => 'Gecikme P50 / P95';

  @override
  String get dashboardActivity => 'Etkinlik';

  @override
  String get dashboardLanguages => 'Diller';

  @override
  String get dashboardNoRuns => 'Bu dönemde yürütme yok.';

  @override
  String get dashboardNoActivity => 'Bu dönemde etkinlik yok.';

  @override
  String get dashboardOneExecution => '1 yürütme';

  @override
  String dashboardAgoDays(int days) {
    return '$days gün önce';
  }

  @override
  String dashboardAgoHours(int hours) {
    return '$hours sa. önce';
  }

  @override
  String dashboardErrorRateOf(String rate) {
    return '%$rate hata';
  }

  @override
  String dashboardLatencyPercentiles(int p50, int p95) {
    return 'P50 $p50 ms · P95 $p95 ms';
  }

  @override
  String get dashboardLatencyNone => 'gecikme —';

  @override
  String get botStopFailed => 'Bot durdurulamadı';

  @override
  String get botStartFailed => 'Bot başlatılamadı';

  @override
  String get refusalNoFreeTimeTitle => 'Barındırma süresi doldu';

  @override
  String get refusalNoFreeTimeBody =>
      'Bu botun ücretsiz barındırma süresi kalmadı. Süre kazanmak için mobil uygulamadan bir reklam izleyin veya Premium\'a geçin. Studio reklam veya satın alma sunmaz.';

  @override
  String get authSessionExpired =>
      'Oturum süresi doldu. Lütfen yeniden oturum açın.';

  @override
  String authDiscordRefused(String reason) {
    return 'Discord girişi reddedildi ($reason).';
  }

  @override
  String get authInvalidResponse =>
      'Geçersiz giriş yanıtı. Lütfen tekrar deneyin.';

  @override
  String get validationCommandNameFormat =>
      'Geçersiz ad: yalnızca küçük harf, rakam, “-” ve “_”; boşluk yok.';

  @override
  String validationDescriptionTooLong(int max) {
    return 'Açıklama en fazla $max karakter olabilir.';
  }

  @override
  String get validationWorkflowNameRequired => 'İş akışı adı gereklidir.';

  @override
  String validationWorkflowNameTooLong(int max) {
    return 'Ad en fazla $max karakter olabilir.';
  }

  @override
  String validationWorkflowTooManyBlocks(int max) {
    return 'İş akışı başına en fazla $max blok.';
  }

  @override
  String validationOptionNameInvalid(String name) {
    return '“$name” seçeneği: küçük harf, rakam, “-” ve “_”, en fazla 32 karakter.';
  }

  @override
  String validationOptionDescription(String name) {
    return '“$name” seçeneği: açıklama gerekli (en fazla 100 karakter).';
  }

  @override
  String validationOptionRequiredOrder(String name) {
    return 'Zorunlu seçenekler isteğe bağlı olanlardan önce gelmelidir (“$name”).';
  }

  @override
  String get schedulerPremiumOnly =>
      'Zamanlayıcı yalnızca Premium hesaplara özeldir. Abonelik uygulamada yönetilir.';

  @override
  String get webhooksPremiumOnly =>
      'Gelen webhook\'lar yalnızca Premium hesaplara özeldir. Abonelik uygulamada yönetilir.';

  @override
  String get overviewEngine => 'Çalışma ortamı';

  @override
  String get overviewLive => 'Canlı';
}
