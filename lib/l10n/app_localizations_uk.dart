// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Повідомлення';

  @override
  String get contacts => 'Контакти';

  @override
  String get map => 'Мапа';

  @override
  String get settings => 'Налаштування';

  @override
  String get connect => 'Підключити';

  @override
  String get disconnect => 'Відключити';

  @override
  String get noDevicesFound => 'Пристроїв не знайдено';

  @override
  String get scanAgain => 'Сканувати знову';

  @override
  String get tapToConnect => 'Торкніться, щоб підключитися';

  @override
  String get deviceNotConnected => 'Пристрій не підключено';

  @override
  String get locationPermissionDenied => 'Доступ до геолокації відхилено';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Please enable in Settings.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for GPS tracking and team coordination. You can enable it later in Settings.';

  @override
  String get locationServicesDisabled =>
      'Служби геолокації вимкнені. Увімкніть їх у Налаштуваннях.';

  @override
  String get failedToGetGpsLocation => 'Не вдалося отримати GPS-координати';

  @override
  String failedToAdvertise(String error) {
    return 'Failed to advertise: $error';
  }

  @override
  String get cancelReconnection => 'Скасувати повторне підключення';

  @override
  String get general => 'Загальні';

  @override
  String get theme => 'Тема';

  @override
  String get chooseTheme => 'Вибрати тему';

  @override
  String get light => 'Світла';

  @override
  String get dark => 'Темна';

  @override
  String get blueLightTheme => 'Blue light theme';

  @override
  String get blueDarkTheme => 'Blue dark theme';

  @override
  String get sarRed => 'SAR Red';

  @override
  String get alertEmergencyMode => 'Alert/Emergency mode';

  @override
  String get sarGreen => 'SAR Green';

  @override
  String get safeAllClearMode => 'Safe/All Clear mode';

  @override
  String get autoSystem => 'Auto (System)';

  @override
  String get followSystemTheme => 'Follow system theme';

  @override
  String get showRxTxIndicators => 'Show RX/TX Indicators';

  @override
  String get displayPacketActivity =>
      'Display packet activity indicators in top bar';

  @override
  String get disableMap => 'Disable Map';

  @override
  String get disableMapDescription =>
      'Hide the map tab to reduce battery usage';

  @override
  String get language => 'Мова';

  @override
  String get chooseLanguage => 'Вибрати мову';

  @override
  String get save => 'Зберегти';

  @override
  String get cancel => 'Скасувати';

  @override
  String get close => 'Закрити';

  @override
  String get about => 'Про програму';

  @override
  String get appVersion => 'App Version';

  @override
  String get appName => 'App Name';

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
  String get moreInfo => 'More Info';

  @override
  String get packageName => 'Package Name';

  @override
  String get sampleData => 'Тестові дані';

  @override
  String get sampleDataDescription =>
      'Load or clear sample contacts, channel messages, and SAR markers for testing';

  @override
  String get loadSampleData => 'Завантажити тестові дані';

  @override
  String get clearAllData => 'Очистити всі дані';

  @override
  String get clearAllDataConfirmTitle => 'Clear All Data';

  @override
  String get clearAllDataConfirmMessage =>
      'This will clear all contacts and SAR markers. Are you sure?';

  @override
  String get clear => 'Очистити';

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
    return 'Failed to load sample data: $error';
  }

  @override
  String get allDataCleared => 'All data cleared';

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
  String get noMessagesYet => 'Повідомлень ще немає';

  @override
  String get pullDownToSync =>
      'Потягніть вниз, щоб синхронізувати повідомлення';

  @override
  String get deleteContact => 'Видалити контакт';

  @override
  String get delete => 'Видалити';

  @override
  String get viewOnMap => 'Показати на мапі';

  @override
  String get refresh => 'Оновити';

  @override
  String get resetPath => 'Reset Path (Re-route)';

  @override
  String get publicKeyCopied => 'Public key copied to clipboard';

  @override
  String copiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get pleaseEnterPassword => 'Будь ласка, введіть пароль';

  @override
  String failedToSyncContacts(String error) {
    return 'Failed to sync contacts: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Вхід виконано успішно! Очікування повідомлень кімнати...';

  @override
  String get loginFailed => 'Помилка входу - неправильний пароль';

  @override
  String loggingIn(String roomName) {
    return 'Вхід до $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Failed to send login: $error';
  }

  @override
  String get lowLocationAccuracy => 'Низька точність геолокації';

  @override
  String get continue_ => 'Продовжити';

  @override
  String get sendSarMarker => 'Надіслати маркер SAR';

  @override
  String get deleteDrawing => 'Видалити рисунок';

  @override
  String get drawingTools => 'Інструменти малювання';

  @override
  String get drawLine => 'Намалювати лінію';

  @override
  String get drawLineDesc => 'Draw a freehand line on the map';

  @override
  String get drawRectangle => 'Намалювати прямокутник';

  @override
  String get drawRectangleDesc => 'Draw a rectangular area on the map';

  @override
  String get measureDistance => 'Виміряти відстань';

  @override
  String get measureDistanceDesc => 'Long press two points to measure';

  @override
  String get clearMeasurement => 'Очистити вимірювання';

  @override
  String distanceLabel(String distance) {
    return 'Distance: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Long press for second point';

  @override
  String get longPressToStartMeasurement => 'Long press to set first point';

  @override
  String get longPressToStartNewMeasurement =>
      'Long press to start new measurement';

  @override
  String get shareDrawings => 'Поділитися рисунками';

  @override
  String get clearAllDrawings => 'Очистити всі рисунки';

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
  String get drawing => 'Рисунок';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Share $count Drawing$plural';
  }

  @override
  String get showReceivedDrawings => 'Показати отримані рисунки';

  @override
  String get showingAllDrawings => 'Showing all drawings';

  @override
  String get showingOnlyYourDrawings => 'Showing only your drawings';

  @override
  String get showSarMarkers => 'Показати маркери SAR';

  @override
  String get showingSarMarkers => 'Showing SAR markers';

  @override
  String get hidingSarMarkers => 'Hiding SAR markers';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get publicChannel => 'Публічний канал';

  @override
  String get broadcastToAll => 'Broadcast to all nearby nodes (ephemeral)';

  @override
  String get storedPermanently => 'Stored permanently in room';

  @override
  String get notConnectedToDevice => 'Не підключено до пристрою';

  @override
  String get typeYourMessage => 'Введіть повідомлення...';

  @override
  String get quickLocationMarker => 'Швидкий маркер місця';

  @override
  String get markerType => 'Тип маркера';

  @override
  String get sendTo => 'Надіслати до';

  @override
  String get noDestinationsAvailable => 'No destinations available.';

  @override
  String get selectDestination => 'Виберіть отримувача...';

  @override
  String get ephemeralBroadcastInfo =>
      'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.';

  @override
  String get persistentRoomInfo =>
      'Persistent: Stored immutably in room. Synced automatically and preserved offline.';

  @override
  String get location => 'Місцезнаходження';

  @override
  String get fromMap => 'From Map';

  @override
  String get gettingLocation => 'Отримання місцезнаходження...';

  @override
  String get locationError => 'Помилка геолокації';

  @override
  String get retry => 'Повторити';

  @override
  String get refreshLocation => 'Оновити місцезнаходження';

  @override
  String accuracyMeters(int accuracy) {
    return 'Accuracy: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Нотатки (необов’язково)';

  @override
  String get addAdditionalInformation => 'Add additional information...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Location accuracy is ±${accuracy}m. This may not be accurate enough for SAR operations.\n\nContinue anyway?';
  }

  @override
  String get loginToRoom => 'Увійти до кімнати';

  @override
  String get enterPasswordInfo =>
      'Enter the password to access this room. The password will be saved for future use.';

  @override
  String get password => 'Пароль';

  @override
  String get enterRoomPassword => 'Введіть пароль кімнати';

  @override
  String get loggingInDots => 'Вхід...';

  @override
  String get login => 'Увійти';

  @override
  String failedToAddRoom(String error) {
    return 'Failed to add room to device: $error\n\nThe room may not have advertised yet.\nTry waiting for the room to broadcast.';
  }

  @override
  String get direct => 'Напряму';

  @override
  String get flood => 'Flood';

  @override
  String get loggedIn => 'Увійшли';

  @override
  String get noGpsData => 'Немає GPS-даних';

  @override
  String get distance => 'Відстань';

  @override
  String directPingTimeout(String name) {
    return 'Direct ping timeout - retrying $name with flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping failed to $name - no response received';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis will remove the contact from both the app and the companion radio device.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Failed to remove contact: $error';
  }

  @override
  String get type => 'Тип';

  @override
  String get publicKey => 'Публічний ключ';

  @override
  String get lastSeen => 'Востаннє бачили';

  @override
  String get roomStatus => 'Стан кімнати';

  @override
  String get loginStatus => 'Стан входу';

  @override
  String get notLoggedIn => 'Не увійшли';

  @override
  String get adminAccess => 'Admin Access';

  @override
  String get yes => 'Так';

  @override
  String get no => 'Ні';

  @override
  String get permissions => 'Дозволи';

  @override
  String get passwordSaved => 'Password Saved';

  @override
  String get locationColon => 'Location:';

  @override
  String get telemetry => 'Телеметрія';

  @override
  String get voltage => 'Напруга';

  @override
  String get battery => 'Батарея';

  @override
  String get temperature => 'Температура';

  @override
  String get humidity => 'Вологість';

  @override
  String get pressure => 'Тиск';

  @override
  String get gpsTelemetry => 'GPS (Telemetry)';

  @override
  String get updated => 'Оновлено';

  @override
  String pathResetInfo(String name) {
    return 'Path reset for $name. Next message will find a new route.';
  }

  @override
  String get reLoginToRoom => 'Re-Login to Room';

  @override
  String get heading => 'Напрямок';

  @override
  String get elevation => 'Висота';

  @override
  String get accuracy => 'Точність';

  @override
  String get bearing => 'Пеленг';

  @override
  String get direction => 'Напрямок';

  @override
  String get filterMarkers => 'Фільтрувати маркери';

  @override
  String get filterMarkersTooltip => 'Filter markers';

  @override
  String get contactsFilter => 'Контакти';

  @override
  String get repeatersFilter => 'Ретранслятори';

  @override
  String get sarMarkers => 'Маркери SAR';

  @override
  String get foundPerson => 'Знайдена людина';

  @override
  String get fire => 'Пожежа';

  @override
  String get stagingArea => 'Зона збору';

  @override
  String get showAll => 'Показати все';

  @override
  String get locationUnavailable => 'Місцезнаходження недоступне';

  @override
  String get ahead => 'ahead';

  @override
  String degreesRight(int degrees) {
    return '$degrees° right';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° left';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'Контактів ще немає';

  @override
  String get connectToDeviceToLoadContacts =>
      'Connect to a device to load contacts';

  @override
  String get teamMembers => 'Члени команди';

  @override
  String get repeaters => 'Ретранслятори';

  @override
  String get rooms => 'Кімнати';

  @override
  String get channels => 'Канали';

  @override
  String get selectMapLayer => 'Вибрати шар мапи';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI Супутник';

  @override
  String get googleHybrid => 'Google Гібрид';

  @override
  String get googleRoadmap => 'Google Дорожня карта';

  @override
  String get googleTerrain => 'Google Рельєф';

  @override
  String get dragToPosition => 'Drag to Position';

  @override
  String get createSarMarker => 'Створити маркер SAR';

  @override
  String get compass => 'Компас';

  @override
  String get navigationAndContacts => 'Navigation & Contacts';

  @override
  String get sarAlert => 'ТРИВОГА SAR';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get cannotReplySenderMissing =>
      'Cannot reply: sender information missing';

  @override
  String get cannotReplyContactNotFound => 'Cannot reply: contact not found';

  @override
  String get copyText => 'Копіювати текст';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templateSaved => 'Template saved successfully';

  @override
  String get templateAlreadyExists => 'Template with this emoji already exists';

  @override
  String get deleteMessage => 'Видалити повідомлення';

  @override
  String get deleteMessageConfirmation =>
      'Are you sure you want to delete this message?';

  @override
  String get shareLocation => 'Поділитися місцезнаходженням';

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
  String get sarLocationShare => 'SAR Location';

  @override
  String get justNow => 'Щойно';

  @override
  String minutesAgo(int minutes) {
    return '$minutes хв тому';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours год тому';
  }

  @override
  String daysAgo(int days) {
    return '$days дн тому';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds с тому';
  }

  @override
  String get sending => 'Надсилання...';

  @override
  String get sent => 'Надіслано';

  @override
  String get delivered => 'Доставлено';

  @override
  String deliveredWithTime(int time) {
    return 'Delivered (${time}ms)';
  }

  @override
  String get failed => 'Помилка';

  @override
  String get broadcast => 'Трансляція';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Delivered to $delivered/$total contacts';
  }

  @override
  String get allDelivered => 'All delivered';

  @override
  String get recipientDetails => 'Recipient Details';

  @override
  String get pending => 'Очікує';

  @override
  String get sarMarkerFoundPerson => 'Found Person';

  @override
  String get sarMarkerFire => 'Fire Location';

  @override
  String get sarMarkerStagingArea => 'Staging Area';

  @override
  String get sarMarkerObject => 'Object Found';

  @override
  String get from => 'Від';

  @override
  String get coordinates => 'Координати';

  @override
  String get tapToViewOnMap => 'Торкніться, щоб переглянути на мапі';

  @override
  String get radioSettings => 'Налаштування радіо';

  @override
  String get frequencyMHz => 'Частота (MHz)';

  @override
  String get frequencyExample => 'e.g., 869.618';

  @override
  String get bandwidth => 'Ширина смуги';

  @override
  String get spreadingFactor => 'Коефіцієнт розширення';

  @override
  String get codingRate => 'Швидкість кодування';

  @override
  String get txPowerDbm => 'Потужність TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Макс: $power dBm';
  }

  @override
  String get you => 'Ви';

  @override
  String exportFailed(String error) {
    return 'Помилка експорту: $error';
  }

  @override
  String importFailed(String error) {
    return 'Помилка імпорту: $error';
  }

  @override
  String get unknown => 'Невідомо';

  @override
  String get onlineLayers => 'Онлайн-шари';

  @override
  String get locationTrail => 'Слід місцезнаходження';

  @override
  String get showTrailOnMap => 'Показати слід на мапі';

  @override
  String get trailVisible => 'Trail is visible on the map';

  @override
  String get trailHiddenRecording => 'Trail is hidden (still recording)';

  @override
  String get duration => 'Тривалість';

  @override
  String get points => 'Точки';

  @override
  String get clearTrail => 'Очистити слід';

  @override
  String get clearTrailQuestion => 'Clear Trail?';

  @override
  String get clearTrailConfirmation =>
      'Are you sure you want to clear the current location trail? This action cannot be undone.';

  @override
  String get noTrailRecorded => 'Слід ще не записано';

  @override
  String get startTrackingToRecord =>
      'Start location tracking to record your trail';

  @override
  String get trailControls => 'Керування слідом';

  @override
  String get contactTrails => 'Сліди контактів';

  @override
  String get showAllContactTrails => 'Show All Contact Trails';

  @override
  String get noContactsWithLocationHistory =>
      'No contacts with location history';

  @override
  String showingTrailsForContacts(int count) {
    return 'Showing trails for $count contacts';
  }

  @override
  String get individualContactTrails => 'Individual Contact Trails';

  @override
  String get deviceInformation => 'Інформація про пристрій';

  @override
  String get bleName => 'Назва BLE';

  @override
  String get meshName => 'Назва mesh';

  @override
  String get notSet => 'Не задано';

  @override
  String get model => 'Модель';

  @override
  String get version => 'Версія';

  @override
  String get buildDate => 'Дата збірки';

  @override
  String get firmware => 'Прошивка';

  @override
  String get maxContacts => 'Макс. контактів';

  @override
  String get maxChannels => 'Макс. каналів';

  @override
  String get publicInfo => 'Public Info';

  @override
  String get meshNetworkName => 'Mesh Network Name';

  @override
  String get nameBroadcastInMesh => 'Name broadcast in mesh advertisements';

  @override
  String get telemetryAndLocationSharing => 'Telemetry & Location Sharing';

  @override
  String get lat => 'Шир.';

  @override
  String get lon => 'Довг.';

  @override
  String get useCurrentLocation => 'Використати поточне місцезнаходження';

  @override
  String get noneUnknown => 'None/Unknown';

  @override
  String get chatNode => 'Chat Node';

  @override
  String get repeater => 'Ретранслятор';

  @override
  String get roomChannel => 'Room/Channel';

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
    return 'Failed to save: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Failed to get location: $error';
  }

  @override
  String get sarTemplates => 'Шаблони SAR';

  @override
  String get manageSarTemplates => 'Manage cursor on target templates';

  @override
  String get addTemplate => 'Додати шаблон';

  @override
  String get editTemplate => 'Редагувати шаблон';

  @override
  String get deleteTemplate => 'Видалити шаблон';

  @override
  String get templateName => 'Назва шаблону';

  @override
  String get templateNameHint => 'напр. Знайдена людина';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji обов’язковий';

  @override
  String get nameRequired => 'Назва обов’язкова';

  @override
  String get templateDescription => 'Опис (необов’язково)';

  @override
  String get templateDescriptionHint => 'Додайте додатковий контекст...';

  @override
  String get templateColor => 'Колір';

  @override
  String get previewFormat => 'Попередній перегляд (формат повідомлення SAR)';

  @override
  String get importFromClipboard => 'Імпорт';

  @override
  String get exportToClipboard => 'Експорт';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Delete template \'$name\'?';
  }

  @override
  String get templateAdded => 'Шаблон додано';

  @override
  String get templateUpdated => 'Шаблон оновлено';

  @override
  String get templateDeleted => 'Шаблон видалено';

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
  String get resetToDefaults => 'Скинути до стандартних';

  @override
  String get resetToDefaultsConfirmation =>
      'This will delete all custom templates and restore the 4 default templates. Continue?';

  @override
  String get reset => 'Скинути';

  @override
  String get resetComplete => 'Templates reset to defaults';

  @override
  String get noTemplates => 'Немає доступних шаблонів';

  @override
  String get tapAddToCreate => 'Торкніться +, щоб створити перший шаблон';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Дозволи';

  @override
  String get locationPermission => 'Дозвіл на геолокацію';

  @override
  String get checking => 'Перевірка...';

  @override
  String get locationPermissionGrantedAlways => 'Granted (Always)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Granted (While In Use)';

  @override
  String get locationPermissionDeniedTapToRequest => 'Denied - Tap to request';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Permanently Denied - Open Settings';

  @override
  String get locationPermissionDialogContent =>
      'Location permission is permanently denied. Please enable it in your device settings to use GPS tracking and location sharing features.';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get locationPermissionGranted => 'Дозвіл на геолокацію надано!';

  @override
  String get locationPermissionRequiredForGps =>
      'Location permission is required for GPS tracking and location sharing.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Location permission is already granted.';

  @override
  String get sarNavyBlue => 'SAR Navy Blue';

  @override
  String get sarNavyBlueDescription => 'Professional/Operations Mode';

  @override
  String get selectRecipient => 'Вибрати отримувача';

  @override
  String get broadcastToAllNearby => 'Broadcast to all nearby';

  @override
  String get searchRecipients => 'Пошук отримувачів...';

  @override
  String get noContactsFound => 'Контактів не знайдено';

  @override
  String get noRoomsFound => 'Кімнат не знайдено';

  @override
  String get noRecipientsAvailable => 'Немає доступних отримувачів';

  @override
  String get noChannelsFound => 'Каналів не знайдено';

  @override
  String get newMessage => 'Нове повідомлення';

  @override
  String get channel => 'Канал';

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
  String get channelEmergency => 'Надзвичайна ситуація';

  @override
  String get channelCoordination => 'Координація';

  @override
  String get channelUpdates => 'Оновлення';

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
  String get mapDrawing => 'Рисунок на мапі';

  @override
  String get navigateToDrawing => 'Navigate to Drawing';

  @override
  String get copyCoordinates => 'Копіювати координати';

  @override
  String get hideFromMap => 'Приховати з мапи';

  @override
  String get lineDrawing => 'Лінійний рисунок';

  @override
  String get rectangleDrawing => 'Рисунок прямокутника';

  @override
  String get manualCoordinates => 'Ручні координати';

  @override
  String get enterCoordinatesManually => 'Введіть координати вручну';

  @override
  String get latitudeLabel => 'Широта';

  @override
  String get longitudeLabel => 'Довгота';

  @override
  String get exampleCoordinates => 'Example: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Поділитися рисунком';

  @override
  String get shareWithAllNearbyDevices => 'Share with all nearby devices';

  @override
  String get shareToRoom => 'Share to Room';

  @override
  String get sendToPersistentStorage => 'Send to persistent room storage';

  @override
  String get deleteDrawingConfirm =>
      'Are you sure you want to delete this drawing?';

  @override
  String get drawingDeleted => 'Drawing deleted';

  @override
  String yourDrawingsCount(int count) {
    return 'Your Drawings ($count)';
  }

  @override
  String get shared => 'Shared';

  @override
  String get line => 'Лінія';

  @override
  String get rectangle => 'Прямокутник';

  @override
  String get updateAvailable => 'Доступне оновлення';

  @override
  String get currentVersion => 'Поточна';

  @override
  String get latestVersion => 'Остання';

  @override
  String get downloadUpdate => 'Завантажити';

  @override
  String get updateLater => 'Пізніше';

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
  String get recentMessages => 'Останні повідомлення';

  @override
  String get addChannel => 'Додати канал';

  @override
  String get channelName => 'Назва каналу';

  @override
  String get channelNameHint => 'напр. Рятувальна команда Альфа';

  @override
  String get channelSecret => 'Секрет каналу';

  @override
  String get channelSecretHint => 'Спільний пароль для цього каналу';

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
  String get channelNameRequired => 'Channel name is required';

  @override
  String get channelNameTooLong => 'Channel name must be 31 characters or less';

  @override
  String get channelSecretRequired => 'Channel secret is required';

  @override
  String get channelSecretTooLong =>
      'Channel secret must be 32 characters or less';

  @override
  String get invalidAsciiCharacters => 'Only ASCII characters are allowed';

  @override
  String get channelCreatedSuccessfully => 'Channel created successfully';

  @override
  String channelCreationFailed(String error) {
    return 'Failed to create channel: $error';
  }

  @override
  String get deleteChannel => 'Delete Channel';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Are you sure you want to delete channel \"$channelName\"? This action cannot be undone.';
  }

  @override
  String get channelDeletedSuccessfully => 'Channel deleted successfully';

  @override
  String channelDeletionFailed(String error) {
    return 'Failed to delete channel: $error';
  }

  @override
  String get createChannel => 'Створити канал';

  @override
  String get wizardBack => 'Назад';

  @override
  String get wizardSkip => 'Пропустити';

  @override
  String get wizardNext => 'Далі';

  @override
  String get wizardGetStarted => 'Почати';

  @override
  String get wizardWelcomeTitle => 'Ласкаво просимо до MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'A powerful off-grid communication tool for search and rescue operations. Connect with your team using mesh radio technology when traditional networks are unavailable.';

  @override
  String get wizardConnectingTitle => 'Підключення до радіо';

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
  String get wizardChannelTitle => 'Канали';

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
  String get wizardContactsTitle => 'Контакти';

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
  String get wizardMapTitle => 'Мапа та місцезнаходження';

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
  String get viewWelcomeTutorial => 'Переглянути вступний посібник';

  @override
  String get allTeamContacts => 'Усі контакти команди';

  @override
  String directMessagesInfo(int count) {
    return 'Direct messages with ACKs. Sent to $count team members.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR marker sent to $count contacts';
  }

  @override
  String get noContactsAvailable => 'Немає доступних контактів команди';

  @override
  String get reply => 'Відповісти';

  @override
  String get technicalDetails => 'Технічні деталі';

  @override
  String get messageTechnicalDetails => 'Message technical details';

  @override
  String get linkQuality => 'Link quality';

  @override
  String get delivery => 'Delivery';

  @override
  String get status => 'Статус';

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
  String get voice => 'Голос';

  @override
  String get voiceId => 'Voice ID';

  @override
  String get envelope => 'Envelope';

  @override
  String get sessionProgress => 'Session progress';

  @override
  String get complete => 'Завершено';

  @override
  String get rawDump => 'Raw dump';

  @override
  String get cannotRetryMissingRecipient =>
      'Cannot retry: recipient information missing';

  @override
  String get voiceUnavailable => 'Голос зараз недоступний';

  @override
  String get requestingVoice => 'Requesting voice';
}
