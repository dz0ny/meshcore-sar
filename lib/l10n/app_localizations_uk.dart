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
      'Дозвіл на геолокацію назавжди відхилено. Увімкніть його в Налаштуваннях.';

  @override
  String get locationPermissionRequired =>
      'Для GPS-відстеження та координації команди потрібен дозвіл на геолокацію. Ви можете ввімкнути його пізніше в Налаштуваннях.';

  @override
  String get locationServicesDisabled =>
      'Служби геолокації вимкнені. Увімкніть їх у Налаштуваннях.';

  @override
  String get failedToGetGpsLocation => 'Не вдалося отримати GPS-координати';

  @override
  String failedToAdvertise(String error) {
    return 'Не вдалося транслювати: $error';
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
  String get blueLightTheme => 'Світло-синя тема';

  @override
  String get blueDarkTheme => 'Темно-синя тема';

  @override
  String get sarRed => 'SAR Червоний';

  @override
  String get alertEmergencyMode => 'Режим тривоги/надзвичайної ситуації';

  @override
  String get sarGreen => 'SAR Зелений';

  @override
  String get safeAllClearMode => 'Безпечний режим/усе чисто';

  @override
  String get autoSystem => 'Авто (система)';

  @override
  String get followSystemTheme => 'Слідувати системній темі';

  @override
  String get showRxTxIndicators => 'Показувати індикатори RX/TX';

  @override
  String get displayPacketActivity =>
      'Показувати індикатори активності пакетів у верхній панелі';

  @override
  String get disableMap => 'Вимкнути мапу';

  @override
  String get disableMapDescription =>
      'Приховати вкладку мапи для зменшення споживання батареї';

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
  String get appVersion => 'Версія застосунку';

  @override
  String get appName => 'Назва застосунку';

  @override
  String get aboutMeshCoreSar => 'Про MeshCore SAR';

  @override
  String get aboutDescription =>
      'Застосунок для пошуку та рятування, створений для команд екстреного реагування. Можливості:\n\n• BLE mesh-мережа для зв’язку між пристроями\n• Офлайн-мапи з кількома шарами\n• Відстеження членів команди в реальному часі\n• Тактичні маркери SAR (знайдена людина, пожежа, зона збору)\n• Керування контактами та повідомленнями\n• GPS-відстеження з компасом\n• Кешування тайлів мапи для офлайн-використання';

  @override
  String get technologiesUsed => 'Використані технології:';

  @override
  String get technologiesList =>
      '• Flutter для кросплатформної розробки\n• BLE (Bluetooth Low Energy) для mesh-мережі\n• OpenStreetMap для мап\n• Provider для керування станом\n• SharedPreferences для локального зберігання';

  @override
  String get moreInfo => 'Більше інформації';

  @override
  String get packageName => 'Назва пакета';

  @override
  String get sampleData => 'Тестові дані';

  @override
  String get sampleDataDescription =>
      'Завантажити або очистити тестові контакти, повідомлення каналів і маркери SAR для перевірки';

  @override
  String get loadSampleData => 'Завантажити тестові дані';

  @override
  String get clearAllData => 'Очистити всі дані';

  @override
  String get clearAllDataConfirmTitle => 'Очистити всі дані';

  @override
  String get clearAllDataConfirmMessage =>
      'Це очистить усі контакти та маркери SAR. Ви впевнені?';

  @override
  String get clear => 'Очистити';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Завантажено $teamCount членів команди, $channelCount каналів, $sarCount маркерів SAR, $messageCount повідомлень';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Не вдалося завантажити тестові дані: $error';
  }

  @override
  String get allDataCleared => 'Усі дані очищено';

  @override
  String get failedToStartBackgroundTracking =>
      'Не вдалося запустити фонове відстеження. Перевірте дозволи та BLE-з’єднання.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Трансляція місцезнаходження: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Стандартний PIN для пристроїв без екрана - 123456. Проблеми зі сполученням? Видаліть Bluetooth-пристрій у системних налаштуваннях.';

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
  String get resetPath => 'Скинути маршрут (побудувати заново)';

  @override
  String get publicKeyCopied => 'Публічний ключ скопійовано в буфер обміну';

  @override
  String copiedToClipboard(String label) {
    return '$label скопійовано в буфер обміну';
  }

  @override
  String get pleaseEnterPassword => 'Будь ласка, введіть пароль';

  @override
  String failedToSyncContacts(String error) {
    return 'Не вдалося синхронізувати контакти: $error';
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
    return 'Не вдалося надіслати вхід: $error';
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
  String get drawLineDesc => 'Намалювати довільну лінію на мапі';

  @override
  String get drawRectangle => 'Намалювати прямокутник';

  @override
  String get drawRectangleDesc => 'Намалювати прямокутну область на мапі';

  @override
  String get measureDistance => 'Виміряти відстань';

  @override
  String get measureDistanceDesc => 'Затисніть дві точки, щоб виміряти';

  @override
  String get clearMeasurement => 'Очистити вимірювання';

  @override
  String distanceLabel(String distance) {
    return 'Відстань: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Затисніть для другої точки';

  @override
  String get longPressToStartMeasurement =>
      'Затисніть, щоб встановити першу точку';

  @override
  String get longPressToStartNewMeasurement =>
      'Затисніть, щоб почати нове вимірювання';

  @override
  String get shareDrawings => 'Поділитися рисунками';

  @override
  String get clearAllDrawings => 'Очистити всі рисунки';

  @override
  String get completeLine => 'Завершити лінію';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Транслювати $count рисунок$plural команді';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Видалити всі $count рисунок$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Видалити всі $count рисунок$plural з мапи?';
  }

  @override
  String get drawing => 'Рисунок';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Поділитися $count рисунок$plural';
  }

  @override
  String get showReceivedDrawings => 'Показати отримані рисунки';

  @override
  String get showingAllDrawings => 'Показуються всі рисунки';

  @override
  String get showingOnlyYourDrawings => 'Показуються лише ваші рисунки';

  @override
  String get showSarMarkers => 'Показати маркери SAR';

  @override
  String get showingSarMarkers => 'Показуються маркери SAR';

  @override
  String get hidingSarMarkers => 'Приховування маркерів SAR';

  @override
  String get clearAll => 'Очистити все';

  @override
  String get publicChannel => 'Публічний канал';

  @override
  String get broadcastToAll => 'Транслювати всім сусіднім вузлам (тимчасово)';

  @override
  String get storedPermanently => 'Постійно збережено в кімнаті';

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
  String get noDestinationsAvailable => 'Немає доступних отримувачів.';

  @override
  String get selectDestination => 'Виберіть отримувача...';

  @override
  String get ephemeralBroadcastInfo =>
      'Тимчасове: транслюється лише по радіо. Не зберігається - вузли мають бути онлайн.';

  @override
  String get persistentRoomInfo =>
      'Постійне: незмінно зберігається в кімнаті. Автоматично синхронізується і зберігається офлайн.';

  @override
  String get location => 'Місцезнаходження';

  @override
  String get fromMap => 'З мапи';

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
    return 'Точність: ±$accuracyм';
  }

  @override
  String get notesOptional => 'Нотатки (необов’язково)';

  @override
  String get addAdditionalInformation => 'Додайте додаткову інформацію...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Точність місцезнаходження становить ±$accuracyм. Це може бути недостатньо точно для операцій SAR.\n\nПродовжити все одно?';
  }

  @override
  String get loginToRoom => 'Увійти до кімнати';

  @override
  String get enterPasswordInfo =>
      'Введіть пароль для доступу до цієї кімнати. Пароль буде збережено для подальшого використання.';

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
    return 'Не вдалося додати кімнату до пристрою: $error\n\nМожливо, кімната ще не почала трансляцію.\nСпробуйте зачекати, поки вона почне транслюватися.';
  }

  @override
  String get direct => 'Напряму';

  @override
  String get flood => 'Широкомовно';

  @override
  String get loggedIn => 'Увійшли';

  @override
  String get noGpsData => 'Немає GPS-даних';

  @override
  String get distance => 'Відстань';

  @override
  String directPingTimeout(String name) {
    return 'Час очікування прямого ping вичерпано - повторна спроба для $name через flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping до $name не вдався - відповіді не отримано';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Ви впевнені, що хочете видалити \"$name\"?\n\nЦе видалить контакт і з застосунку, і з пов’язаного радіопристрою.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Не вдалося видалити контакт: $error';
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
  String get adminAccess => 'Доступ адміністратора';

  @override
  String get yes => 'Так';

  @override
  String get no => 'Ні';

  @override
  String get permissions => 'Дозволи';

  @override
  String get passwordSaved => 'Пароль збережено';

  @override
  String get locationColon => 'Місцезнаходження:';

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
  String get gpsTelemetry => 'GPS (телеметрія)';

  @override
  String get updated => 'Оновлено';

  @override
  String pathResetInfo(String name) {
    return 'Маршрут для $name скинуто. Наступне повідомлення знайде новий маршрут.';
  }

  @override
  String get reLoginToRoom => 'Повторно увійти до кімнати';

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
  String get filterMarkersTooltip => 'Фільтрувати маркери';

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
  String get ahead => 'попереду';

  @override
  String degreesRight(int degrees) {
    return '$degrees° праворуч';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° ліворуч';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Шир.: $latitude Довг.: $longitude';
  }

  @override
  String get noContactsYet => 'Контактів ще немає';

  @override
  String get connectToDeviceToLoadContacts =>
      'Підключіться до пристрою, щоб завантажити контакти';

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
  String get dragToPosition => 'Перетягніть у позицію';

  @override
  String get createSarMarker => 'Створити маркер SAR';

  @override
  String get compass => 'Компас';

  @override
  String get navigationAndContacts => 'Навігація та контакти';

  @override
  String get sarAlert => 'ТРИВОГА SAR';

  @override
  String get textCopiedToClipboard => 'Текст скопійовано в буфер обміну';

  @override
  String get cannotReplySenderMissing =>
      'Неможливо відповісти: відсутня інформація про відправника';

  @override
  String get cannotReplyContactNotFound =>
      'Неможливо відповісти: контакт не знайдено';

  @override
  String get copyText => 'Копіювати текст';

  @override
  String get saveAsTemplate => 'Зберегти як шаблон';

  @override
  String get templateSaved => 'Шаблон успішно збережено';

  @override
  String get templateAlreadyExists => 'Шаблон із цим emoji уже існує';

  @override
  String get deleteMessage => 'Видалити повідомлення';

  @override
  String get deleteMessageConfirmation =>
      'Ви впевнені, що хочете видалити це повідомлення?';

  @override
  String get shareLocation => 'Поділитися місцезнаходженням';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nКоординати: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Місцезнаходження SAR';

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
    return 'Доставлено (${time}ms)';
  }

  @override
  String get failed => 'Помилка';

  @override
  String get broadcast => 'Трансляція';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Доставлено $delivered/$total контактам';
  }

  @override
  String get allDelivered => 'Усе доставлено';

  @override
  String get recipientDetails => 'Деталі отримувача';

  @override
  String get pending => 'Очікує';

  @override
  String get sarMarkerFoundPerson => 'Знайдена людина';

  @override
  String get sarMarkerFire => 'Місце пожежі';

  @override
  String get sarMarkerStagingArea => 'Зона збору';

  @override
  String get sarMarkerObject => 'Знайдений об’єкт';

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
  String get frequencyExample => 'напр., 869.618';

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
  String get trailVisible => 'Слід видно на мапі';

  @override
  String get trailHiddenRecording => 'Слід прихований (запис триває)';

  @override
  String get duration => 'Тривалість';

  @override
  String get points => 'Точки';

  @override
  String get clearTrail => 'Очистити слід';

  @override
  String get clearTrailQuestion => 'Очистити слід?';

  @override
  String get clearTrailConfirmation =>
      'Ви впевнені, що хочете очистити поточний слід місцезнаходження? Цю дію не можна скасувати.';

  @override
  String get noTrailRecorded => 'Слід ще не записано';

  @override
  String get startTrackingToRecord =>
      'Почніть відстеження місцезнаходження, щоб записати слід';

  @override
  String get trailControls => 'Керування слідом';

  @override
  String get contactTrails => 'Сліди контактів';

  @override
  String get showAllContactTrails => 'Показати всі сліди контактів';

  @override
  String get noContactsWithLocationHistory =>
      'Немає контактів з історією місцезнаходження';

  @override
  String showingTrailsForContacts(int count) {
    return 'Показуються сліди для $count контактів';
  }

  @override
  String get individualContactTrails => 'Окремі сліди контактів';

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
  String get publicInfo => 'Публічна інформація';

  @override
  String get meshNetworkName => 'Назва mesh-мережі';

  @override
  String get nameBroadcastInMesh => 'Ім’я, що транслюється в mesh-оголошеннях';

  @override
  String get telemetryAndLocationSharing =>
      'Телеметрія та поширення місцезнаходження';

  @override
  String get lat => 'Шир.';

  @override
  String get lon => 'Довг.';

  @override
  String get useCurrentLocation => 'Використати поточне місцезнаходження';

  @override
  String get noneUnknown => 'Немає/Невідомо';

  @override
  String get chatNode => 'Вузол чату';

  @override
  String get repeater => 'Ретранслятор';

  @override
  String get roomChannel => 'Кімната/Канал';

  @override
  String typeNumber(int number) {
    return 'Тип $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label скопійовано в буфер обміну';
  }

  @override
  String failedToSave(String error) {
    return 'Не вдалося зберегти: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Не вдалося отримати місцезнаходження: $error';
  }

  @override
  String get sarTemplates => 'Шаблони SAR';

  @override
  String get manageSarTemplates => 'Керувати шаблонами SAR';

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
    return 'Видалити шаблон \"$name\"?';
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
      other: 'Імпортовано $count шаблонів',
      one: 'Імпортовано 1 шаблон',
      zero: 'Шаблони не імпортовано',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Експортовано $count шаблонів у буфер обміну',
      one: 'Експортовано 1 шаблон у буфер обміну',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Скинути до стандартних';

  @override
  String get resetToDefaultsConfirmation =>
      'Це видалить усі користувацькі шаблони та відновить 4 стандартні шаблони. Продовжити?';

  @override
  String get reset => 'Скинути';

  @override
  String get resetComplete => 'Шаблони скинуто до стандартних';

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
  String get locationPermissionGrantedAlways => 'Надано (Завжди)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Надано (Під час використання)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Відхилено - торкніться, щоб запросити';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Назавжди відхилено - відкрити налаштування';

  @override
  String get locationPermissionDialogContent =>
      'Дозвіл на геолокацію назавжди відхилено. Увімкніть його в налаштуваннях пристрою, щоб використовувати GPS та поширення місцезнаходження.';

  @override
  String get openSettings => 'Відкрити налаштування';

  @override
  String get locationPermissionGranted => 'Дозвіл на геолокацію надано!';

  @override
  String get locationPermissionRequiredForGps =>
      'Для GPS-відстеження та поширення місцезнаходження потрібен дозвіл на геолокацію.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Дозвіл на геолокацію вже надано.';

  @override
  String get sarNavyBlue => 'SAR Темно-синій';

  @override
  String get sarNavyBlueDescription => 'Професійний/операційний режим';

  @override
  String get selectRecipient => 'Вибрати отримувача';

  @override
  String get broadcastToAllNearby => 'Транслювати всім поблизу';

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
  String get samplePoliceLead => 'Керівник поліції';

  @override
  String get sampleDroneOperator => 'Оператор дрона';

  @override
  String get sampleFirefighterAlpha => 'Пожежник';

  @override
  String get sampleMedicCharlie => 'Медик';

  @override
  String get sampleCommandDelta => 'Командування';

  @override
  String get sampleFireEngine => 'Пожежна машина';

  @override
  String get sampleAirSupport => 'Повітряна підтримка';

  @override
  String get sampleBaseCoordinator => 'Координатор бази';

  @override
  String get channelEmergency => 'Надзвичайна ситуація';

  @override
  String get channelCoordination => 'Координація';

  @override
  String get channelUpdates => 'Оновлення';

  @override
  String get sampleTeamMember => 'Тестовий член команди';

  @override
  String get sampleScout => 'Тестовий розвідник';

  @override
  String get sampleBase => 'Тестова база';

  @override
  String get sampleSearcher => 'Тестовий пошуковець';

  @override
  String get sampleObjectBackpack => ' Знайдено рюкзак - синього кольору';

  @override
  String get sampleObjectVehicle =>
      ' Покинутий транспорт - перевірити власника';

  @override
  String get sampleObjectCamping => ' Знайдено туристичне спорядження';

  @override
  String get sampleObjectTrailMarker =>
      ' Знайдено маркер стежки поза маршрутом';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Усі команди - дайте відмітку';

  @override
  String get sampleMsgWeatherUpdate =>
      'Оновлення погоди: ясно, температура 18°C';

  @override
  String get sampleMsgBaseCamp => 'Базовий табір розгорнуто в зоні збору';

  @override
  String get sampleMsgTeamAlpha => 'Команда рухається до сектора 2';

  @override
  String get sampleMsgRadioCheck =>
      'Перевірка радіо - усім станціям відповісти';

  @override
  String get sampleMsgWaterSupply =>
      'Запас води доступний на контрольній точці 3';

  @override
  String get sampleMsgTeamBravo => 'Команда доповідає: сектор 1 чистий';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Орієнтовний час до точки збору: 15 хвилин';

  @override
  String get sampleMsgSupplyDrop => 'Скидання постачання підтверджено на 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Обстеження дроном завершено - результатів немає';

  @override
  String get sampleMsgTeamCharlie => 'Команда просить підкріплення';

  @override
  String get sampleMsgRadioDiscipline =>
      'Усім підрозділам: дотримуйтеся радіодисципліни';

  @override
  String get sampleMsgUrgentMedical =>
      'ТЕРМІНОВО: потрібна медична допомога в секторі 4';

  @override
  String get sampleMsgAdultMale => ' Дорослий чоловік, при свідомості';

  @override
  String get sampleMsgFireSpotted => 'Помічено пожежу - координати надходять';

  @override
  String get sampleMsgSpreadingRapidly => ' Швидко поширюється!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'ПРІОРИТЕТ: потрібна підтримка гелікоптера';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Медична команда прямує до вашого місця';

  @override
  String get sampleMsgEvacHelicopter =>
      'ETA евакуаційного гелікоптера 10 хвилин';

  @override
  String get sampleMsgEmergencyResolved =>
      'Надзвичайну ситуацію вирішено - все чисто';

  @override
  String get sampleMsgEmergencyStagingArea => ' Аварійна зона збору';

  @override
  String get sampleMsgEmergencyServices =>
      'Екстрені служби повідомлені та вже реагують';

  @override
  String get sampleAlphaTeamLead => 'Керівник команди';

  @override
  String get sampleBravoScout => 'Розвідник';

  @override
  String get sampleCharlieMedic => 'Медик';

  @override
  String get sampleDeltaNavigator => 'Навігатор';

  @override
  String get sampleEchoSupport => 'Підтримка';

  @override
  String get sampleBaseCommand => 'Командування бази';

  @override
  String get sampleFieldCoordinator => 'Польовий координатор';

  @override
  String get sampleMedicalTeam => 'Медична команда';

  @override
  String get mapDrawing => 'Рисунок на мапі';

  @override
  String get navigateToDrawing => 'Перейти до рисунка';

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
  String get exampleCoordinates => 'Приклад: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Поділитися рисунком';

  @override
  String get shareWithAllNearbyDevices =>
      'Поділитися з усіма пристроями поблизу';

  @override
  String get shareToRoom => 'Поділитися в кімнату';

  @override
  String get sendToPersistentStorage => 'Надіслати в постійне сховище кімнати';

  @override
  String get deleteDrawingConfirm =>
      'Ви впевнені, що хочете видалити цей рисунок?';

  @override
  String get drawingDeleted => 'Рисунок видалено';

  @override
  String yourDrawingsCount(int count) {
    return 'Ваші рисунки ($count)';
  }

  @override
  String get shared => 'Спільний';

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
  String get cadastralParcels => 'Кадастрові ділянки';

  @override
  String get forestRoads => 'Лісові дороги';

  @override
  String get wmsOverlays => 'Накладки WMS';

  @override
  String get hikingTrails => 'Пішохідні стежки';

  @override
  String get mainRoads => 'Основні дороги';

  @override
  String get houseNumbers => 'Номери будинків';

  @override
  String get fireHazardZones => 'Зони пожежної небезпеки';

  @override
  String get historicalFires => 'Історичні пожежі';

  @override
  String get firebreaks => 'Протипожежні смуги';

  @override
  String get krasFireZones => 'Пожежні зони Красу';

  @override
  String get placeNames => 'Назви місць';

  @override
  String get municipalityBorders => 'Межі громад';

  @override
  String get topographicMap => 'Топографічна мапа 1:25000';

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
      'Цей секрет має бути спільним для всіх членів команди, яким потрібен доступ до цього каналу';

  @override
  String get channelTypesInfo =>
      'Hash-канали (#team): секрет автоматично генерується з назви. Однакова назва = той самий канал на всіх пристроях.\n\nПриватні канали: використовуйте явний секрет. Приєднатися можуть лише ті, хто його знає.';

  @override
  String get hashChannelInfo =>
      'Hash-канал: секрет буде автоматично згенерований з назви каналу. Кожен, хто використовує ту саму назву, приєднається до того самого каналу.';

  @override
  String get channelNameRequired => 'Назва каналу обов’язкова';

  @override
  String get channelNameTooLong =>
      'Назва каналу має бути не довшою за 31 символ';

  @override
  String get channelSecretRequired => 'Секрет каналу обов’язковий';

  @override
  String get channelSecretTooLong =>
      'Секрет каналу має бути не довшим за 32 символи';

  @override
  String get invalidAsciiCharacters => 'Дозволені лише символи ASCII';

  @override
  String get channelCreatedSuccessfully => 'Канал успішно створено';

  @override
  String channelCreationFailed(String error) {
    return 'Не вдалося створити канал: $error';
  }

  @override
  String get deleteChannel => 'Видалити канал';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Ви впевнені, що хочете видалити канал \"$channelName\"? Цю дію не можна скасувати.';
  }

  @override
  String get channelDeletedSuccessfully => 'Канал успішно видалено';

  @override
  String channelDeletionFailed(String error) {
    return 'Не вдалося видалити канал: $error';
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
      'Потужний інструмент офлайн-комунікації для операцій пошуку та рятування. Зв’язуйтеся зі своєю командою за допомогою mesh-радіо, коли традиційні мережі недоступні.';

  @override
  String get wizardConnectingTitle => 'Підключення до радіо';

  @override
  String get wizardConnectingDescription =>
      'Підключіть смартфон до радіопристрою MeshCore через Bluetooth, щоб почати спілкування поза мережею.';

  @override
  String get wizardConnectingFeature1 => 'Скануйте сусідні пристрої MeshCore';

  @override
  String get wizardConnectingFeature2 =>
      'Сполучіть свій радіопристрій через Bluetooth';

  @override
  String get wizardConnectingFeature3 =>
      'Працює повністю офлайн - інтернет не потрібен';

  @override
  String get wizardChannelTitle => 'Канали';

  @override
  String get wizardChannelDescription =>
      'Транслюйте повідомлення всім у каналі - ідеально для загальнокомандних оголошень і координації.';

  @override
  String get wizardChannelFeature1 =>
      'Публічний канал для загального спілкування команди';

  @override
  String get wizardChannelFeature2 =>
      'Створюйте власні канали для окремих груп';

  @override
  String get wizardChannelFeature3 =>
      'Повідомлення автоматично ретранслюються mesh-мережею';

  @override
  String get wizardContactsTitle => 'Контакти';

  @override
  String get wizardContactsDescription =>
      'Члени вашої команди з’являються автоматично, коли приєднуються до mesh-мережі. Надсилайте їм прямі повідомлення або переглядайте їхнє місцезнаходження.';

  @override
  String get wizardContactsFeature1 => 'Контакти виявляються автоматично';

  @override
  String get wizardContactsFeature2 => 'Надсилайте приватні прямі повідомлення';

  @override
  String get wizardContactsFeature3 =>
      'Переглядайте рівень батареї та час останньої появи';

  @override
  String get wizardMapTitle => 'Мапа та місцезнаходження';

  @override
  String get wizardMapDescription =>
      'Відстежуйте команду в реальному часі та позначайте важливі місця для операцій пошуку та рятування.';

  @override
  String get wizardMapFeature1 =>
      'Маркери SAR для знайдених людей, пожеж і зон збору';

  @override
  String get wizardMapFeature2 =>
      'GPS-відстеження членів команди в реальному часі';

  @override
  String get wizardMapFeature3 =>
      'Завантажуйте офлайн-мапи для віддалених районів';

  @override
  String get wizardMapFeature4 =>
      'Малюйте фігури та діліться тактичною інформацією';

  @override
  String get viewWelcomeTutorial => 'Переглянути вступний посібник';

  @override
  String get allTeamContacts => 'Усі контакти команди';

  @override
  String directMessagesInfo(int count) {
    return 'Прямі повідомлення з ACK. Надіслано $count членам команди.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Маркер SAR надіслано $count контактам';
  }

  @override
  String get noContactsAvailable => 'Немає доступних контактів команди';

  @override
  String get reply => 'Відповісти';

  @override
  String get technicalDetails => 'Технічні деталі';

  @override
  String get messageTechnicalDetails => 'Технічні деталі повідомлення';

  @override
  String get linkQuality => 'Якість зв’язку';

  @override
  String get delivery => 'Доставка';

  @override
  String get status => 'Статус';

  @override
  String get expectedAckTag => 'Очікуваний тег ACK';

  @override
  String get roundTrip => 'Час в обидва боки';

  @override
  String get retryAttempt => 'Спроба повтору';

  @override
  String get floodFallback => 'Резервний flooding';

  @override
  String get identity => 'Ідентичність';

  @override
  String get messageId => 'ID повідомлення';

  @override
  String get sender => 'Відправник';

  @override
  String get senderKey => 'Ключ відправника';

  @override
  String get recipient => 'Отримувач';

  @override
  String get recipientKey => 'Ключ отримувача';

  @override
  String get voice => 'Голос';

  @override
  String get voiceId => 'ID голосу';

  @override
  String get envelope => 'Конверт';

  @override
  String get sessionProgress => 'Прогрес сеансу';

  @override
  String get complete => 'Завершено';

  @override
  String get rawDump => 'Сирий дамп';

  @override
  String get cannotRetryMissingRecipient =>
      'Неможливо повторити: відсутня інформація про отримувача';

  @override
  String get voiceUnavailable => 'Голос зараз недоступний';

  @override
  String get requestingVoice => 'Запит голосу';

  @override
  String get device => 'device';

  @override
  String get change => 'Change';

  @override
  String get wizardOverviewDescription =>
      'This app combines MeshCore messaging, SAR field updates, mapping, and device tools in one place.';

  @override
  String get wizardOverviewFeature1 =>
      'Send direct, room, and channel messages from the main Messages tab.';

  @override
  String get wizardOverviewFeature2 =>
      'Share SAR markers, map drawings, voice clips, and images over the mesh.';

  @override
  String get wizardOverviewFeature3 =>
      'Connect over BLE or TCP, then manage the companion radio from inside the app.';

  @override
  String get wizardMessagingTitle => 'Messaging and Field Reports';

  @override
  String get wizardMessagingDescription =>
      'Messages are more than plain text here. The app already supports several operational payloads and transfer workflows.';

  @override
  String get wizardMessagingFeature1 =>
      'Send direct messages, room posts, and channel traffic from one composer.';

  @override
  String get wizardMessagingFeature2 =>
      'Create SAR updates and reusable SAR templates for common field reports.';

  @override
  String get wizardMessagingFeature3 =>
      'Transfer voice sessions and images, with progress and airtime estimates in the UI.';

  @override
  String get wizardConnectDeviceTitle => 'Connect device';

  @override
  String get wizardConnectDeviceDescription =>
      'Connect your MeshCore radio, choose a name, and apply a radio preset before continuing.';

  @override
  String get wizardSetupBadge => 'Setup';

  @override
  String get wizardOverviewBadge => 'Overview';

  @override
  String wizardConnectedToDevice(String deviceName) {
    return 'Connected to $deviceName';
  }

  @override
  String get wizardNoDeviceConnected => 'No device connected yet';

  @override
  String get wizardSkipForNow => 'Skip for now';

  @override
  String get wizardDeviceNameLabel => 'Device name';

  @override
  String get wizardDeviceNameHelp =>
      'This name is advertised to other MeshCore users.';

  @override
  String get wizardConfigRegionLabel => 'Config region';

  @override
  String get wizardConfigRegionHelp =>
      'Uses the full official MeshCore preset list. Default is EU/UK (Narrow).';

  @override
  String get wizardPresetNote1 =>
      'Make sure the selected preset matches your local radio regulations.';

  @override
  String get wizardPresetNote2 =>
      'The list matches the official MeshCore config tool preset feed.';

  @override
  String get wizardPresetNote3 =>
      'EU/UK (Narrow) stays selected by default for onboarding.';

  @override
  String get wizardSaving => 'Saving...';

  @override
  String get wizardSaveAndContinue => 'Save and continue';

  @override
  String get wizardEnterDeviceName => 'Enter a device name before continuing.';

  @override
  String wizardDeviceSetupSaved(String deviceName, String presetName) {
    return 'Saved $deviceName with $presetName.';
  }

  @override
  String get wizardNetworkTitle => 'Contacts, Rooms, and Repeaters';

  @override
  String get wizardNetworkDescription =>
      'The Contacts tab organizes the network you discover and the routes you learn over time.';

  @override
  String get wizardNetworkFeature1 =>
      'Review team members, repeaters, rooms, channels, and pending adverts in one list.';

  @override
  String get wizardNetworkFeature2 =>
      'Use smart ping, room login, learned paths, and route reset tools when connectivity gets messy.';

  @override
  String get wizardNetworkFeature3 =>
      'Create channels and manage network destinations without leaving the app.';

  @override
  String get wizardMapOpsTitle => 'Map, Trails, and Shared Geometry';

  @override
  String get wizardMapOpsDescription =>
      'The app map is tied directly into messaging, tracking, and SAR overlays instead of being a separate viewer.';

  @override
  String get wizardMapOpsFeature1 =>
      'Track your own position, teammate locations, and movement trails on the map.';

  @override
  String get wizardMapOpsFeature2 =>
      'Open drawings from messages, preview them inline, and remove them from the map when needed.';

  @override
  String get wizardMapOpsFeature3 =>
      'Use repeater map views and shared overlays to understand network reach in the field.';

  @override
  String get wizardToolsTitle => 'Tools Beyond Messaging';

  @override
  String get wizardToolsDescription =>
      'There is more here than the four main tabs. The app also includes configuration, diagnostics, and optional sensor workflows.';

  @override
  String get wizardToolsFeature1 =>
      'Open device config to change radio settings, telemetry, TX power, and companion details.';

  @override
  String get wizardToolsFeature2 =>
      'Enable the Sensors tab when you want watched sensor dashboards and quick refresh actions.';

  @override
  String get wizardToolsFeature3 =>
      'Use packet logs, spectrum scan, and developer diagnostics when troubleshooting the mesh.';

  @override
  String get contactInSensors => 'In Sensors';

  @override
  String get contactAddToSensors => 'Add to Sensors';

  @override
  String get contactSetPath => 'Set path';

  @override
  String contactAddedToSensors(String contactName) {
    return '$contactName added to Sensors';
  }

  @override
  String contactFailedToClearRoute(String error) {
    return 'Failed to clear route: $error';
  }

  @override
  String get contactRouteCleared => 'Route cleared';

  @override
  String contactRouteSet(String route) {
    return 'Route set: $route';
  }

  @override
  String contactFailedToSetRoute(String error) {
    return 'Failed to set route: $error';
  }
}
