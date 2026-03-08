// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Mesajlar';

  @override
  String get contacts => 'Kişiler';

  @override
  String get map => 'Harita';

  @override
  String get settings => 'Ayarlar';

  @override
  String get connect => 'Bağlan';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get noDevicesFound => 'Cihaz bulunamadı';

  @override
  String get scanAgain => 'Tekrar tara';

  @override
  String get tapToConnect => 'Bağlanmak için dokunun';

  @override
  String get deviceNotConnected => 'Cihaz bağlı değil';

  @override
  String get locationPermissionDenied => 'Konum izni reddedildi';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Konum izni kalıcı olarak reddedildi. Lütfen Ayarlar bölümünden etkinleştirin.';

  @override
  String get locationPermissionRequired =>
      'GPS takibi ve ekip koordinasyonu için konum izni gereklidir. Daha sonra Ayarlar bölümünden etkinleştirebilirsiniz.';

  @override
  String get locationServicesDisabled =>
      'Konum servisleri kapalı. Lütfen Ayarlar bölümünden etkinleştirin.';

  @override
  String get failedToGetGpsLocation => 'GPS konumu alınamadı';

  @override
  String failedToAdvertise(String error) {
    return 'Yayın başarısız: $error';
  }

  @override
  String get cancelReconnection => 'Yeniden bağlanmayı iptal et';

  @override
  String get general => 'Genel';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Tema seç';

  @override
  String get light => 'Açık';

  @override
  String get dark => 'Koyu';

  @override
  String get blueLightTheme => 'Mavi açık tema';

  @override
  String get blueDarkTheme => 'Mavi koyu tema';

  @override
  String get sarRed => 'SAR Kırmızı';

  @override
  String get alertEmergencyMode => 'Uyarı/Acil durum modu';

  @override
  String get sarGreen => 'SAR Yeşil';

  @override
  String get safeAllClearMode => 'Güvenli/Tamam modu';

  @override
  String get autoSystem => 'Otomatik (Sistem)';

  @override
  String get followSystemTheme => 'Sistem temasını takip et';

  @override
  String get showRxTxIndicators => 'RX/TX göstergelerini göster';

  @override
  String get displayPacketActivity =>
      'Üst çubukta paket etkinliği göstergelerini göster';

  @override
  String get disableMap => 'Haritayı devre dışı bırak';

  @override
  String get disableMapDescription =>
      'Pil kullanımını azaltmak için harita sekmesini gizle';

  @override
  String get language => 'Dil';

  @override
  String get chooseLanguage => 'Dil seç';

  @override
  String get save => 'Kaydet';

  @override
  String get cancel => 'İptal';

  @override
  String get close => 'Kapat';

  @override
  String get about => 'Hakkında';

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get appName => 'Uygulama adı';

  @override
  String get aboutMeshCoreSar => 'About MeshCore SAR';

  @override
  String get aboutDescription =>
      'A Search & Rescue application designed for emergency response teams. Features include:\n\n• BLE mesh networking for device-to-device communication\n• Offline maps with multiple layer options\n• Real-time team member tracking\n• SAR tactical markers (found person, fire, staging)\n• Contact management and messaging\n• GPS tracking with compass heading\n• Map tile caching for offline use';

  @override
  String get technologiesUsed => 'Technologies Used:';

  @override
  String get technologiesList =>
      '• Flutter for cross-platform development\n• BLE (Bluetooth Low Energy) for mesh networking\n• OpenStreetMap for mapping\n• Provider for state management\n• SharedPreferences for local storage';

  @override
  String get moreInfo => 'Daha fazla bilgi';

  @override
  String get packageName => 'Package Name';

  @override
  String get sampleData => 'Örnek veriler';

  @override
  String get sampleDataDescription =>
      'Load or clear sample contacts, channel messages, and SAR markers for testing';

  @override
  String get loadSampleData => 'Örnek verileri yükle';

  @override
  String get clearAllData => 'Tüm verileri temizle';

  @override
  String get clearAllDataConfirmTitle => 'Tüm verileri temizle';

  @override
  String get clearAllDataConfirmMessage =>
      'Bu işlem tüm kişileri ve SAR işaretlerini temizleyecek. Emin misiniz?';

  @override
  String get clear => 'Temizle';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Loaded $teamCount team members, $channelCount channels, $sarCount SAR markers, $messageCount messages';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Örnek veriler yüklenemedi: $error';
  }

  @override
  String get allDataCleared => 'Tüm veriler temizlendi';

  @override
  String get failedToStartBackgroundTracking =>
      'Failed to start background tracking. Check permissions and BLE connection.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Location broadcast: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'The default pin for devices without a screen is 123456. Trouble pairing? Forget the bluetooth device in system settings.';

  @override
  String get noMessagesYet => 'Henüz mesaj yok';

  @override
  String get pullDownToSync => 'Mesajları senkronize etmek için aşağı çekin';

  @override
  String get deleteContact => 'Kişiyi sil';

  @override
  String get delete => 'Sil';

  @override
  String get viewOnMap => 'Haritada görüntüle';

  @override
  String get refresh => 'Yenile';

  @override
  String get resetPath => 'Reset Path (Re-route)';

  @override
  String get publicKeyCopied => 'Genel anahtar panoya kopyalandı';

  @override
  String copiedToClipboard(String label) {
    return '$label panoya kopyalandı';
  }

  @override
  String get pleaseEnterPassword => 'Lütfen bir parola girin';

  @override
  String failedToSyncContacts(String error) {
    return 'Kişiler senkronize edilemedi: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Giriş başarılı! Oda mesajları bekleniyor...';

  @override
  String get loginFailed => 'Giriş başarısız - yanlış parola';

  @override
  String loggingIn(String roomName) {
    return '$roomName odasına giriş yapılıyor...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Giriş gönderilemedi: $error';
  }

  @override
  String get lowLocationAccuracy => 'Düşük konum doğruluğu';

  @override
  String get continue_ => 'Devam et';

  @override
  String get sendSarMarker => 'SAR işareti gönder';

  @override
  String get deleteDrawing => 'Çizimi sil';

  @override
  String get drawingTools => 'Çizim araçları';

  @override
  String get drawLine => 'Çizgi çiz';

  @override
  String get drawLineDesc => 'Harita üzerinde serbest çizgi çiz';

  @override
  String get drawRectangle => 'Dikdörtgen çiz';

  @override
  String get drawRectangleDesc => 'Harita üzerinde dikdörtgen alan çiz';

  @override
  String get measureDistance => 'Mesafe ölç';

  @override
  String get measureDistanceDesc => 'Ölçmek için iki noktaya uzun basın';

  @override
  String get clearMeasurement => 'Ölçümü temizle';

  @override
  String distanceLabel(String distance) {
    return 'Mesafe: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Long press for second point';

  @override
  String get longPressToStartMeasurement => 'Long press to set first point';

  @override
  String get longPressToStartNewMeasurement =>
      'Long press to start new measurement';

  @override
  String get shareDrawings => 'Çizimleri paylaş';

  @override
  String get clearAllDrawings => 'Tüm çizimleri temizle';

  @override
  String get completeLine => 'Complete Line';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Broadcast $count drawing$plural to team';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Remove all $count drawing$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Delete all $count drawing$plural from the map?';
  }

  @override
  String get drawing => 'Çizim';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Share $count Drawing$plural';
  }

  @override
  String get showReceivedDrawings => 'Alınan çizimleri göster';

  @override
  String get showingAllDrawings => 'Tüm çizimler gösteriliyor';

  @override
  String get showingOnlyYourDrawings =>
      'Yalnızca sizin çizimleriniz gösteriliyor';

  @override
  String get showSarMarkers => 'SAR işaretlerini göster';

  @override
  String get showingSarMarkers => 'SAR işaretleri gösteriliyor';

  @override
  String get hidingSarMarkers => 'SAR işaretleri gizleniyor';

  @override
  String get clearAll => 'Tümünü temizle';

  @override
  String get publicChannel => 'Genel kanal';

  @override
  String get broadcastToAll => 'Broadcast to all nearby nodes (ephemeral)';

  @override
  String get storedPermanently => 'Odada kalıcı olarak saklanır';

  @override
  String get notConnectedToDevice => 'Cihaza bağlı değil';

  @override
  String get typeYourMessage => 'Mesajınızı yazın...';

  @override
  String get quickLocationMarker => 'Hızlı konum işareti';

  @override
  String get markerType => 'İşaret türü';

  @override
  String get sendTo => 'Gönder';

  @override
  String get noDestinationsAvailable => 'Kullanılabilir hedef yok.';

  @override
  String get selectDestination => 'Hedef seçin...';

  @override
  String get ephemeralBroadcastInfo =>
      'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.';

  @override
  String get persistentRoomInfo =>
      'Persistent: Stored immutably in room. Synced automatically and preserved offline.';

  @override
  String get location => 'Konum';

  @override
  String get fromMap => 'Haritadan';

  @override
  String get gettingLocation => 'Konum alınıyor...';

  @override
  String get locationError => 'Konum hatası';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get refreshLocation => 'Konumu yenile';

  @override
  String accuracyMeters(int accuracy) {
    return 'Doğruluk: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notlar (isteğe bağlı)';

  @override
  String get addAdditionalInformation => 'Ek bilgi ekleyin...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Location accuracy is ±${accuracy}m. This may not be accurate enough for SAR operations.\n\nContinue anyway?';
  }

  @override
  String get loginToRoom => 'Odaya giriş yap';

  @override
  String get enterPasswordInfo =>
      'Enter the password to access this room. The password will be saved for future use.';

  @override
  String get password => 'Parola';

  @override
  String get enterRoomPassword => 'Oda parolasını girin';

  @override
  String get loggingInDots => 'Giriş yapılıyor...';

  @override
  String get login => 'Giriş yap';

  @override
  String failedToAddRoom(String error) {
    return 'Failed to add room to device: $error\n\nThe room may not have advertised yet.\nTry waiting for the room to broadcast.';
  }

  @override
  String get direct => 'Doğrudan';

  @override
  String get flood => 'Flood';

  @override
  String get loggedIn => 'Giriş yapıldı';

  @override
  String get noGpsData => 'GPS verisi yok';

  @override
  String get distance => 'Mesafe';

  @override
  String directPingTimeout(String name) {
    return 'Direct ping timeout - retrying $name with flooding...';
  }

  @override
  String pingFailed(String name) {
    return '$name için ping başarısız - yanıt alınamadı';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis will remove the contact from both the app and the companion radio device.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Kişi kaldırılamadı: $error';
  }

  @override
  String get type => 'Tür';

  @override
  String get publicKey => 'Genel anahtar';

  @override
  String get lastSeen => 'Son görülme';

  @override
  String get roomStatus => 'Oda durumu';

  @override
  String get loginStatus => 'Giriş durumu';

  @override
  String get notLoggedIn => 'Giriş yapılmadı';

  @override
  String get adminAccess => 'Yönetici erişimi';

  @override
  String get yes => 'Evet';

  @override
  String get no => 'Hayır';

  @override
  String get permissions => 'İzinler';

  @override
  String get passwordSaved => 'Parola kaydedildi';

  @override
  String get locationColon => 'Konum:';

  @override
  String get telemetry => 'Telemetri';

  @override
  String get voltage => 'Voltaj';

  @override
  String get battery => 'Pil';

  @override
  String get temperature => 'Sıcaklık';

  @override
  String get humidity => 'Nem';

  @override
  String get pressure => 'Basınç';

  @override
  String get gpsTelemetry => 'GPS (telemetri)';

  @override
  String get updated => 'Güncellendi';

  @override
  String pathResetInfo(String name) {
    return 'Path reset for $name. Next message will find a new route.';
  }

  @override
  String get reLoginToRoom => 'Odaya yeniden giriş yap';

  @override
  String get heading => 'Yön';

  @override
  String get elevation => 'Rakım';

  @override
  String get accuracy => 'Doğruluk';

  @override
  String get bearing => 'İstikamet';

  @override
  String get direction => 'Yön';

  @override
  String get filterMarkers => 'İşaretleri filtrele';

  @override
  String get filterMarkersTooltip => 'Filter markers';

  @override
  String get contactsFilter => 'Kişiler';

  @override
  String get repeatersFilter => 'Tekrarlayıcılar';

  @override
  String get sarMarkers => 'SAR işaretleri';

  @override
  String get foundPerson => 'Bulunan kişi';

  @override
  String get fire => 'Yangın';

  @override
  String get stagingArea => 'Toplanma alanı';

  @override
  String get showAll => 'Tümünü göster';

  @override
  String get locationUnavailable => 'Konum kullanılamıyor';

  @override
  String get ahead => 'ileride';

  @override
  String degreesRight(int degrees) {
    return '$degrees° sağda';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° solda';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'Henüz kişi yok';

  @override
  String get connectToDeviceToLoadContacts =>
      'Kişileri yüklemek için bir cihaza bağlanın';

  @override
  String get teamMembers => 'Ekip üyeleri';

  @override
  String get repeaters => 'Tekrarlayıcılar';

  @override
  String get rooms => 'Odalar';

  @override
  String get channels => 'Kanallar';

  @override
  String get selectMapLayer => 'Harita katmanını seç';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Uydu';

  @override
  String get googleHybrid => 'Google Hibrit';

  @override
  String get googleRoadmap => 'Google Yol Haritası';

  @override
  String get googleTerrain => 'Google Arazi';

  @override
  String get dragToPosition => 'Konuma sürükle';

  @override
  String get createSarMarker => 'SAR işareti oluştur';

  @override
  String get compass => 'Pusula';

  @override
  String get navigationAndContacts => 'Navigasyon ve kişiler';

  @override
  String get sarAlert => 'SAR ALARMI';

  @override
  String get textCopiedToClipboard => 'Metin panoya kopyalandı';

  @override
  String get cannotReplySenderMissing =>
      'Cannot reply: sender information missing';

  @override
  String get cannotReplyContactNotFound => 'Cannot reply: contact not found';

  @override
  String get copyText => 'Metni kopyala';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templateSaved => 'Template saved successfully';

  @override
  String get templateAlreadyExists => 'Template with this emoji already exists';

  @override
  String get deleteMessage => 'Mesajı sil';

  @override
  String get deleteMessageConfirmation =>
      'Bu mesajı silmek istediğinizden emin misiniz?';

  @override
  String get shareLocation => 'Konumu paylaş';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nCoordinates: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'SAR konumu';

  @override
  String get justNow => 'Az önce';

  @override
  String minutesAgo(int minutes) {
    return '$minutes dk önce';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours sa önce';
  }

  @override
  String daysAgo(int days) {
    return '$days g önce';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds sn önce';
  }

  @override
  String get sending => 'Gönderiliyor...';

  @override
  String get sent => 'Gönderildi';

  @override
  String get delivered => 'Teslim edildi';

  @override
  String deliveredWithTime(int time) {
    return 'Teslim edildi (${time}ms)';
  }

  @override
  String get failed => 'Başarısız';

  @override
  String get broadcast => 'Yayın';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Delivered to $delivered/$total contacts';
  }

  @override
  String get allDelivered => 'All delivered';

  @override
  String get recipientDetails => 'Recipient Details';

  @override
  String get pending => 'Bekliyor';

  @override
  String get sarMarkerFoundPerson => 'Found Person';

  @override
  String get sarMarkerFire => 'Fire Location';

  @override
  String get sarMarkerStagingArea => 'Staging Area';

  @override
  String get sarMarkerObject => 'Object Found';

  @override
  String get from => 'Kimden';

  @override
  String get coordinates => 'Koordinatlar';

  @override
  String get tapToViewOnMap => 'Haritada görüntülemek için dokunun';

  @override
  String get radioSettings => 'Radyo ayarları';

  @override
  String get frequencyMHz => 'Frekans (MHz)';

  @override
  String get frequencyExample => 'e.g., 869.618';

  @override
  String get bandwidth => 'Bant genişliği';

  @override
  String get spreadingFactor => 'Yayılma faktörü';

  @override
  String get codingRate => 'Kodlama oranı';

  @override
  String get txPowerDbm => 'TX gücü (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Maks: $power dBm';
  }

  @override
  String get you => 'Siz';

  @override
  String exportFailed(String error) {
    return 'Dışa aktarma başarısız: $error';
  }

  @override
  String importFailed(String error) {
    return 'İçe aktarma başarısız: $error';
  }

  @override
  String get unknown => 'Bilinmiyor';

  @override
  String get onlineLayers => 'Çevrimiçi katmanlar';

  @override
  String get locationTrail => 'Konum izi';

  @override
  String get showTrailOnMap => 'İzi haritada göster';

  @override
  String get trailVisible => 'İz haritada görünüyor';

  @override
  String get trailHiddenRecording => 'İz gizli (kayıt devam ediyor)';

  @override
  String get duration => 'Süre';

  @override
  String get points => 'Noktalar';

  @override
  String get clearTrail => 'İzi temizle';

  @override
  String get clearTrailQuestion => 'İz temizlensin mi?';

  @override
  String get clearTrailConfirmation =>
      'Are you sure you want to clear the current location trail? This action cannot be undone.';

  @override
  String get noTrailRecorded => 'Henüz iz kaydedilmedi';

  @override
  String get startTrackingToRecord =>
      'İzi kaydetmek için konum takibini başlatın';

  @override
  String get trailControls => 'İz kontrolleri';

  @override
  String get contactTrails => 'Kişi izleri';

  @override
  String get showAllContactTrails => 'Tüm kişi izlerini göster';

  @override
  String get noContactsWithLocationHistory => 'Konum geçmişi olan kişi yok';

  @override
  String showingTrailsForContacts(int count) {
    return 'Showing trails for $count contacts';
  }

  @override
  String get individualContactTrails => 'Individual Contact Trails';

  @override
  String get deviceInformation => 'Cihaz bilgileri';

  @override
  String get bleName => 'BLE adı';

  @override
  String get meshName => 'Mesh adı';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get model => 'Model';

  @override
  String get version => 'Sürüm';

  @override
  String get buildDate => 'Derleme tarihi';

  @override
  String get firmware => 'Bellenim';

  @override
  String get maxContacts => 'Maks kişi';

  @override
  String get maxChannels => 'Maks kanal';

  @override
  String get publicInfo => 'Genel bilgiler';

  @override
  String get meshNetworkName => 'Mesh ağ adı';

  @override
  String get nameBroadcastInMesh => 'Name broadcast in mesh advertisements';

  @override
  String get telemetryAndLocationSharing => 'Telemetri ve konum paylaşımı';

  @override
  String get lat => 'Enl.';

  @override
  String get lon => 'Boyl.';

  @override
  String get useCurrentLocation => 'Geçerli konumu kullan';

  @override
  String get noneUnknown => 'Yok/Bilinmiyor';

  @override
  String get chatNode => 'Sohbet düğümü';

  @override
  String get repeater => 'Tekrarlayıcı';

  @override
  String get roomChannel => 'Oda/Kanal';

  @override
  String typeNumber(int number) {
    return 'Type $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Copied $label to clipboard';
  }

  @override
  String failedToSave(String error) {
    return 'Kaydetme başarısız: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Konum alınamadı: $error';
  }

  @override
  String get sarTemplates => 'SAR şablonları';

  @override
  String get manageSarTemplates => 'Manage cursor on target templates';

  @override
  String get addTemplate => 'Şablon ekle';

  @override
  String get editTemplate => 'Şablonu düzenle';

  @override
  String get deleteTemplate => 'Şablonu sil';

  @override
  String get templateName => 'Şablon adı';

  @override
  String get templateNameHint => 'örn. Bulunan kişi';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji gerekli';

  @override
  String get nameRequired => 'Ad gerekli';

  @override
  String get templateDescription => 'Açıklama (isteğe bağlı)';

  @override
  String get templateDescriptionHint => 'Ek bağlam ekleyin...';

  @override
  String get templateColor => 'Renk';

  @override
  String get previewFormat => 'Önizleme (SAR mesaj biçimi)';

  @override
  String get importFromClipboard => 'İçe aktar';

  @override
  String get exportToClipboard => 'Dışa aktar';

  @override
  String deleteTemplateConfirmation(String name) {
    return '“$name” şablonu silinsin mi?';
  }

  @override
  String get templateAdded => 'Şablon eklendi';

  @override
  String get templateUpdated => 'Şablon güncellendi';

  @override
  String get templateDeleted => 'Şablon silindi';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count templates',
      one: 'Imported 1 template',
      zero: 'No templates imported',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Exported $count templates to clipboard',
      one: 'Exported 1 template to clipboard',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Varsayılanlara sıfırla';

  @override
  String get resetToDefaultsConfirmation =>
      'This will delete all custom templates and restore the 4 default templates. Continue?';

  @override
  String get reset => 'Sıfırla';

  @override
  String get resetComplete => 'Şablonlar varsayılana sıfırlandı';

  @override
  String get noTemplates => 'Kullanılabilir şablon yok';

  @override
  String get tapAddToCreate =>
      'İlk şablonunuzu oluşturmak için + işaretine dokunun';

  @override
  String get ok => 'Tamam';

  @override
  String get permissionsSection => 'İzinler';

  @override
  String get locationPermission => 'Konum izni';

  @override
  String get checking => 'Kontrol ediliyor...';

  @override
  String get locationPermissionGrantedAlways => 'Verildi (Her zaman)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Verildi (Kullanım sırasında)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Reddedildi - istemek için dokunun';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Kalıcı olarak reddedildi - ayarları aç';

  @override
  String get locationPermissionDialogContent =>
      'Location permission is permanently denied. Please enable it in your device settings to use GPS tracking and location sharing features.';

  @override
  String get openSettings => 'Ayarları aç';

  @override
  String get locationPermissionGranted => 'Konum izni verildi!';

  @override
  String get locationPermissionRequiredForGps =>
      'GPS takibi ve konum paylaşımı için konum izni gereklidir.';

  @override
  String get locationPermissionAlreadyGranted => 'Konum izni zaten verilmiş.';

  @override
  String get sarNavyBlue => 'SAR Navy Blue';

  @override
  String get sarNavyBlueDescription => 'Professional/Operations Mode';

  @override
  String get selectRecipient => 'Alıcı seç';

  @override
  String get broadcastToAllNearby => 'Broadcast to all nearby';

  @override
  String get searchRecipients => 'Alıcı ara...';

  @override
  String get noContactsFound => 'Kişi bulunamadı';

  @override
  String get noRoomsFound => 'Oda bulunamadı';

  @override
  String get noRecipientsAvailable => 'Kullanılabilir alıcı yok';

  @override
  String get noChannelsFound => 'Kanal bulunamadı';

  @override
  String get newMessage => 'Yeni mesaj';

  @override
  String get channel => 'Kanal';

  @override
  String get samplePoliceLead => 'Police Lead';

  @override
  String get sampleDroneOperator => 'Drone Operator';

  @override
  String get sampleFirefighterAlpha => 'Firefighter';

  @override
  String get sampleMedicCharlie => 'Medic';

  @override
  String get sampleCommandDelta => 'Command';

  @override
  String get sampleFireEngine => 'Fire Engine';

  @override
  String get sampleAirSupport => 'Air Support';

  @override
  String get sampleBaseCoordinator => 'Base Coordinator';

  @override
  String get channelEmergency => 'Acil durum';

  @override
  String get channelCoordination => 'Koordinasyon';

  @override
  String get channelUpdates => 'Güncellemeler';

  @override
  String get sampleTeamMember => 'Sample Team Member';

  @override
  String get sampleScout => 'Sample Scout';

  @override
  String get sampleBase => 'Sample Base';

  @override
  String get sampleSearcher => 'Sample Searcher';

  @override
  String get sampleObjectBackpack => ' Backpack found - blue color';

  @override
  String get sampleObjectVehicle => ' Vehicle abandoned - check for owner';

  @override
  String get sampleObjectCamping => ' Camping equipment discovered';

  @override
  String get sampleObjectTrailMarker => ' Trail marker found off-path';

  @override
  String get sampleMsgAllTeamsCheckIn => 'All teams check in';

  @override
  String get sampleMsgWeatherUpdate => 'Weather update: Clear skies, temp 18°C';

  @override
  String get sampleMsgBaseCamp => 'Base camp established at staging area';

  @override
  String get sampleMsgTeamAlpha => 'Team moving to sector 2';

  @override
  String get sampleMsgRadioCheck => 'Radio check - all stations respond';

  @override
  String get sampleMsgWaterSupply => 'Water supply available at checkpoint 3';

  @override
  String get sampleMsgTeamBravo => 'Team reporting: sector 1 clear';

  @override
  String get sampleMsgEtaRallyPoint => 'ETA to rally point: 15 minutes';

  @override
  String get sampleMsgSupplyDrop => 'Supply drop confirmed for 14:00';

  @override
  String get sampleMsgDroneSurvey => 'Drone survey completed - no findings';

  @override
  String get sampleMsgTeamCharlie => 'Team requesting backup';

  @override
  String get sampleMsgRadioDiscipline => 'All units: maintain radio discipline';

  @override
  String get sampleMsgUrgentMedical =>
      'URGENT: Medical assistance needed at sector 4';

  @override
  String get sampleMsgAdultMale => ' Adult male, conscious';

  @override
  String get sampleMsgFireSpotted => 'Fire spotted - coordinates incoming';

  @override
  String get sampleMsgSpreadingRapidly => ' Spreading rapidly!';

  @override
  String get sampleMsgPriorityHelicopter => 'PRIORITY: Need helicopter support';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Medical team en route to your location';

  @override
  String get sampleMsgEvacHelicopter => 'Evac helicopter ETA 10 minutes';

  @override
  String get sampleMsgEmergencyResolved => 'Emergency resolved - all clear';

  @override
  String get sampleMsgEmergencyStagingArea => ' Emergency staging area';

  @override
  String get sampleMsgEmergencyServices =>
      'Emergency services notified and responding';

  @override
  String get sampleAlphaTeamLead => 'Team Lead';

  @override
  String get sampleBravoScout => 'Scout';

  @override
  String get sampleCharlieMedic => 'Medic';

  @override
  String get sampleDeltaNavigator => 'Navigator';

  @override
  String get sampleEchoSupport => 'Support';

  @override
  String get sampleBaseCommand => 'Base Command';

  @override
  String get sampleFieldCoordinator => 'Field Coordinator';

  @override
  String get sampleMedicalTeam => 'Medical Team';

  @override
  String get mapDrawing => 'Harita çizimi';

  @override
  String get navigateToDrawing => 'Navigate to Drawing';

  @override
  String get copyCoordinates => 'Koordinatları kopyala';

  @override
  String get hideFromMap => 'Haritadan gizle';

  @override
  String get lineDrawing => 'Çizgi çizimi';

  @override
  String get rectangleDrawing => 'Dikdörtgen çizimi';

  @override
  String get manualCoordinates => 'Manuel koordinatlar';

  @override
  String get enterCoordinatesManually => 'Koordinatları manuel girin';

  @override
  String get latitudeLabel => 'Enlem';

  @override
  String get longitudeLabel => 'Boylam';

  @override
  String get exampleCoordinates => 'Example: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Çizimi paylaş';

  @override
  String get shareWithAllNearbyDevices => 'Yakındaki tüm cihazlarla paylaş';

  @override
  String get shareToRoom => 'Odaya paylaş';

  @override
  String get sendToPersistentStorage => 'Kalıcı oda depolamasına gönder';

  @override
  String get deleteDrawingConfirm =>
      'Are you sure you want to delete this drawing?';

  @override
  String get drawingDeleted => 'Çizim silindi';

  @override
  String yourDrawingsCount(int count) {
    return 'Your Drawings ($count)';
  }

  @override
  String get shared => 'Paylaşıldı';

  @override
  String get line => 'Çizgi';

  @override
  String get rectangle => 'Dikdörtgen';

  @override
  String get updateAvailable => 'Güncelleme mevcut';

  @override
  String get currentVersion => 'Geçerli';

  @override
  String get latestVersion => 'En son';

  @override
  String get downloadUpdate => 'İndir';

  @override
  String get updateLater => 'Daha sonra';

  @override
  String get cadastralParcels => 'Cadastral Parcels';

  @override
  String get forestRoads => 'Forest Roads';

  @override
  String get wmsOverlays => 'WMS Overlays';

  @override
  String get hikingTrails => 'Hiking Trails';

  @override
  String get mainRoads => 'Main Roads';

  @override
  String get houseNumbers => 'House Numbers';

  @override
  String get fireHazardZones => 'Fire Hazard Zones';

  @override
  String get historicalFires => 'Historical Fires';

  @override
  String get firebreaks => 'Firebreaks';

  @override
  String get krasFireZones => 'Kras Fire Zones';

  @override
  String get placeNames => 'Place Names';

  @override
  String get municipalityBorders => 'Municipality Borders';

  @override
  String get topographicMap => 'Topographic Map 1:25000';

  @override
  String get recentMessages => 'Son mesajlar';

  @override
  String get addChannel => 'Kanal ekle';

  @override
  String get channelName => 'Kanal adı';

  @override
  String get channelNameHint => 'örn. Kurtarma Ekibi Alfa';

  @override
  String get channelSecret => 'Kanal sırrı';

  @override
  String get channelSecretHint => 'Bu kanal için paylaşılan parola';

  @override
  String get channelSecretHelp =>
      'This secret must be shared with all team members who need access to this channel';

  @override
  String get channelTypesInfo =>
      'Hash channels (#team): Secret auto-generated from name. Same name = same channel across devices.\n\nPrivate channels: Use explicit secret. Only those with the secret can join.';

  @override
  String get hashChannelInfo =>
      'Hash channel: Secret will be auto-generated from the channel name. Anyone using the same name will join the same channel.';

  @override
  String get channelNameRequired => 'Kanal adı gerekli';

  @override
  String get channelNameTooLong => 'Channel name must be 31 characters or less';

  @override
  String get channelSecretRequired => 'Kanal sırrı gerekli';

  @override
  String get channelSecretTooLong =>
      'Channel secret must be 32 characters or less';

  @override
  String get invalidAsciiCharacters =>
      'Yalnızca ASCII karakterlere izin verilir';

  @override
  String get channelCreatedSuccessfully => 'Kanal başarıyla oluşturuldu';

  @override
  String channelCreationFailed(String error) {
    return 'Kanal oluşturulamadı: $error';
  }

  @override
  String get deleteChannel => 'Kanalı sil';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Are you sure you want to delete channel \"$channelName\"? This action cannot be undone.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanal başarıyla silindi';

  @override
  String channelDeletionFailed(String error) {
    return 'Kanal silinemedi: $error';
  }

  @override
  String get createChannel => 'Kanal oluştur';

  @override
  String get wizardBack => 'Geri';

  @override
  String get wizardSkip => 'Atla';

  @override
  String get wizardNext => 'İleri';

  @override
  String get wizardGetStarted => 'Başla';

  @override
  String get wizardWelcomeTitle => 'MeshCore SAR uygulamasına hoş geldiniz';

  @override
  String get wizardWelcomeDescription =>
      'A powerful off-grid communication tool for search and rescue operations. Connect with your team using mesh radio technology when traditional networks are unavailable.';

  @override
  String get wizardConnectingTitle => 'Radyonuza bağlanma';

  @override
  String get wizardConnectingDescription =>
      'Connect your smartphone to a MeshCore radio device via Bluetooth to start communicating off-grid.';

  @override
  String get wizardConnectingFeature1 => 'Scan for nearby MeshCore devices';

  @override
  String get wizardConnectingFeature2 => 'Pair with your radio via Bluetooth';

  @override
  String get wizardConnectingFeature3 =>
      'Works completely offline - no internet required';

  @override
  String get wizardChannelTitle => 'Kanallar';

  @override
  String get wizardChannelDescription =>
      'Broadcast messages to everyone on a channel, perfect for team-wide announcements and coordination.';

  @override
  String get wizardChannelFeature1 =>
      'Public Channel for general team communication';

  @override
  String get wizardChannelFeature2 =>
      'Create custom channels for specific groups';

  @override
  String get wizardChannelFeature3 =>
      'Messages are automatically relayed by the mesh';

  @override
  String get wizardContactsTitle => 'Kişiler';

  @override
  String get wizardContactsDescription =>
      'Your team members appear automatically as they join the mesh network. Send them direct messages or view their location.';

  @override
  String get wizardContactsFeature1 => 'Contacts discovered automatically';

  @override
  String get wizardContactsFeature2 => 'Send private direct messages';

  @override
  String get wizardContactsFeature3 => 'View battery level and last seen time';

  @override
  String get wizardMapTitle => 'Harita ve konum';

  @override
  String get wizardMapDescription =>
      'Track your team in real-time and mark important locations for search and rescue operations.';

  @override
  String get wizardMapFeature1 =>
      'SAR markers for found persons, fires, and staging areas';

  @override
  String get wizardMapFeature2 => 'Real-time GPS tracking of team members';

  @override
  String get wizardMapFeature3 => 'Download offline maps for remote areas';

  @override
  String get wizardMapFeature4 => 'Draw shapes and share tactical information';

  @override
  String get viewWelcomeTutorial => 'Karşılama eğitimini görüntüle';

  @override
  String get allTeamContacts => 'Tüm ekip kişileri';

  @override
  String directMessagesInfo(int count) {
    return 'Direct messages with ACKs. Sent to $count team members.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR marker sent to $count contacts';
  }

  @override
  String get noContactsAvailable => 'Ekip kişisi yok';

  @override
  String get reply => 'Yanıtla';

  @override
  String get technicalDetails => 'Teknik ayrıntılar';

  @override
  String get messageTechnicalDetails => 'Message technical details';

  @override
  String get linkQuality => 'Link quality';

  @override
  String get delivery => 'Delivery';

  @override
  String get status => 'Durum';

  @override
  String get expectedAckTag => 'Expected ACK tag';

  @override
  String get roundTrip => 'Round-trip';

  @override
  String get retryAttempt => 'Retry attempt';

  @override
  String get floodFallback => 'Flood fallback';

  @override
  String get identity => 'Identity';

  @override
  String get messageId => 'Message ID';

  @override
  String get sender => 'Sender';

  @override
  String get senderKey => 'Sender key';

  @override
  String get recipient => 'Recipient';

  @override
  String get recipientKey => 'Recipient key';

  @override
  String get voice => 'Ses';

  @override
  String get voiceId => 'Voice ID';

  @override
  String get envelope => 'Envelope';

  @override
  String get sessionProgress => 'Session progress';

  @override
  String get complete => 'Tamamlandı';

  @override
  String get rawDump => 'Raw dump';

  @override
  String get cannotRetryMissingRecipient =>
      'Cannot retry: recipient information missing';

  @override
  String get voiceUnavailable => 'Ses şu anda kullanılamıyor';

  @override
  String get requestingVoice => 'Requesting voice';
}
