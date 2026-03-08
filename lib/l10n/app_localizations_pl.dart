// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Wiadomości';

  @override
  String get contacts => 'Kontakty';

  @override
  String get map => 'Mapa';

  @override
  String get settings => 'Ustawienia';

  @override
  String get connect => 'Połącz';

  @override
  String get disconnect => 'Rozłącz';

  @override
  String get noDevicesFound => 'Nie znaleziono urządzeń';

  @override
  String get scanAgain => 'Skanuj ponownie';

  @override
  String get tapToConnect => 'Dotknij, aby połączyć';

  @override
  String get deviceNotConnected => 'Urządzenie nie jest połączone';

  @override
  String get locationPermissionDenied => 'Odmówiono dostępu do lokalizacji';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission permanently denied. Please enable in Settings.';

  @override
  String get locationPermissionRequired =>
      'Location permission is required for GPS tracking and team coordination. You can enable it later in Settings.';

  @override
  String get locationServicesDisabled =>
      'Usługi lokalizacji są wyłączone. Włącz je w Ustawieniach.';

  @override
  String get failedToGetGpsLocation => 'Nie udało się pobrać lokalizacji GPS';

  @override
  String failedToAdvertise(String error) {
    return 'Failed to advertise: $error';
  }

  @override
  String get cancelReconnection => 'Anuluj ponowne łączenie';

  @override
  String get general => 'Ogólne';

  @override
  String get theme => 'Motyw';

  @override
  String get chooseTheme => 'Wybierz motyw';

  @override
  String get light => 'Jasny';

  @override
  String get dark => 'Ciemny';

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
  String get language => 'Język';

  @override
  String get chooseLanguage => 'Wybierz język';

  @override
  String get save => 'Zapisz';

  @override
  String get cancel => 'Anuluj';

  @override
  String get close => 'Zamknij';

  @override
  String get about => 'Informacje';

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
  String get sampleData => 'Dane przykładowe';

  @override
  String get sampleDataDescription =>
      'Load or clear sample contacts, channel messages, and SAR markers for testing';

  @override
  String get loadSampleData => 'Wczytaj dane przykładowe';

  @override
  String get clearAllData => 'Wyczyść wszystkie dane';

  @override
  String get clearAllDataConfirmTitle => 'Clear All Data';

  @override
  String get clearAllDataConfirmMessage =>
      'This will clear all contacts and SAR markers. Are you sure?';

  @override
  String get clear => 'Wyczyść';

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
  String get noMessagesYet => 'Brak wiadomości';

  @override
  String get pullDownToSync =>
      'Przeciągnij w dół, aby zsynchronizować wiadomości';

  @override
  String get deleteContact => 'Usuń kontakt';

  @override
  String get delete => 'Usuń';

  @override
  String get viewOnMap => 'Pokaż na mapie';

  @override
  String get refresh => 'Odśwież';

  @override
  String get resetPath => 'Reset Path (Re-route)';

  @override
  String get publicKeyCopied => 'Public key copied to clipboard';

  @override
  String copiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get pleaseEnterPassword => 'Wprowadź hasło';

  @override
  String failedToSyncContacts(String error) {
    return 'Failed to sync contacts: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Zalogowano pomyślnie! Oczekiwanie na wiadomości z pokoju...';

  @override
  String get loginFailed => 'Logowanie nie powiodło się - nieprawidłowe hasło';

  @override
  String loggingIn(String roomName) {
    return 'Logowanie do $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Failed to send login: $error';
  }

  @override
  String get lowLocationAccuracy => 'Niska dokładność lokalizacji';

  @override
  String get continue_ => 'Kontynuuj';

  @override
  String get sendSarMarker => 'Wyślij znacznik SAR';

  @override
  String get deleteDrawing => 'Usuń rysunek';

  @override
  String get drawingTools => 'Narzędzia rysowania';

  @override
  String get drawLine => 'Rysuj linię';

  @override
  String get drawLineDesc => 'Draw a freehand line on the map';

  @override
  String get drawRectangle => 'Rysuj prostokąt';

  @override
  String get drawRectangleDesc => 'Draw a rectangular area on the map';

  @override
  String get measureDistance => 'Mierz odległość';

  @override
  String get measureDistanceDesc => 'Long press two points to measure';

  @override
  String get clearMeasurement => 'Wyczyść pomiar';

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
  String get shareDrawings => 'Udostępnij rysunki';

  @override
  String get clearAllDrawings => 'Wyczyść wszystkie rysunki';

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
  String get drawing => 'Rysunek';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Share $count Drawing$plural';
  }

  @override
  String get showReceivedDrawings => 'Pokaż odebrane rysunki';

  @override
  String get showingAllDrawings => 'Showing all drawings';

  @override
  String get showingOnlyYourDrawings => 'Showing only your drawings';

  @override
  String get showSarMarkers => 'Pokaż znaczniki SAR';

  @override
  String get showingSarMarkers => 'Showing SAR markers';

  @override
  String get hidingSarMarkers => 'Hiding SAR markers';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get publicChannel => 'Kanał publiczny';

  @override
  String get broadcastToAll => 'Broadcast to all nearby nodes (ephemeral)';

  @override
  String get storedPermanently => 'Stored permanently in room';

  @override
  String get notConnectedToDevice => 'Brak połączenia z urządzeniem';

  @override
  String get typeYourMessage => 'Wpisz wiadomość...';

  @override
  String get quickLocationMarker => 'Szybki znacznik lokalizacji';

  @override
  String get markerType => 'Typ znacznika';

  @override
  String get sendTo => 'Wyślij do';

  @override
  String get noDestinationsAvailable => 'No destinations available.';

  @override
  String get selectDestination => 'Wybierz odbiorcę...';

  @override
  String get ephemeralBroadcastInfo =>
      'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.';

  @override
  String get persistentRoomInfo =>
      'Persistent: Stored immutably in room. Synced automatically and preserved offline.';

  @override
  String get location => 'Lokalizacja';

  @override
  String get fromMap => 'From Map';

  @override
  String get gettingLocation => 'Pobieranie lokalizacji...';

  @override
  String get locationError => 'Błąd lokalizacji';

  @override
  String get retry => 'Ponów';

  @override
  String get refreshLocation => 'Odśwież lokalizację';

  @override
  String accuracyMeters(int accuracy) {
    return 'Accuracy: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notatki (opcjonalnie)';

  @override
  String get addAdditionalInformation => 'Add additional information...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Location accuracy is ±${accuracy}m. This may not be accurate enough for SAR operations.\n\nContinue anyway?';
  }

  @override
  String get loginToRoom => 'Zaloguj do pokoju';

  @override
  String get enterPasswordInfo =>
      'Enter the password to access this room. The password will be saved for future use.';

  @override
  String get password => 'Hasło';

  @override
  String get enterRoomPassword => 'Wpisz hasło pokoju';

  @override
  String get loggingInDots => 'Logowanie...';

  @override
  String get login => 'Zaloguj';

  @override
  String failedToAddRoom(String error) {
    return 'Failed to add room to device: $error\n\nThe room may not have advertised yet.\nTry waiting for the room to broadcast.';
  }

  @override
  String get direct => 'Bezpośrednie';

  @override
  String get flood => 'Flood';

  @override
  String get loggedIn => 'Zalogowano';

  @override
  String get noGpsData => 'Brak danych GPS';

  @override
  String get distance => 'Odległość';

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
  String get type => 'Typ';

  @override
  String get publicKey => 'Klucz publiczny';

  @override
  String get lastSeen => 'Ostatnio widziany';

  @override
  String get roomStatus => 'Status pokoju';

  @override
  String get loginStatus => 'Status logowania';

  @override
  String get notLoggedIn => 'Niezalogowany';

  @override
  String get adminAccess => 'Admin Access';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get permissions => 'Uprawnienia';

  @override
  String get passwordSaved => 'Password Saved';

  @override
  String get locationColon => 'Location:';

  @override
  String get telemetry => 'Telemetria';

  @override
  String get voltage => 'Napięcie';

  @override
  String get battery => 'Bateria';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Wilgotność';

  @override
  String get pressure => 'Ciśnienie';

  @override
  String get gpsTelemetry => 'GPS (Telemetry)';

  @override
  String get updated => 'Zaktualizowano';

  @override
  String pathResetInfo(String name) {
    return 'Path reset for $name. Next message will find a new route.';
  }

  @override
  String get reLoginToRoom => 'Re-Login to Room';

  @override
  String get heading => 'Kierunek';

  @override
  String get elevation => 'Wysokość';

  @override
  String get accuracy => 'Dokładność';

  @override
  String get bearing => 'Namiar';

  @override
  String get direction => 'Kierunek';

  @override
  String get filterMarkers => 'Filtruj znaczniki';

  @override
  String get filterMarkersTooltip => 'Filter markers';

  @override
  String get contactsFilter => 'Kontakty';

  @override
  String get repeatersFilter => 'Przekaźniki';

  @override
  String get sarMarkers => 'Znaczniki SAR';

  @override
  String get foundPerson => 'Odnaleziona osoba';

  @override
  String get fire => 'Pożar';

  @override
  String get stagingArea => 'Punkt zbiórki';

  @override
  String get showAll => 'Pokaż wszystko';

  @override
  String get locationUnavailable => 'Lokalizacja niedostępna';

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
  String get noContactsYet => 'Brak kontaktów';

  @override
  String get connectToDeviceToLoadContacts =>
      'Connect to a device to load contacts';

  @override
  String get teamMembers => 'Członkowie zespołu';

  @override
  String get repeaters => 'Przekaźniki';

  @override
  String get rooms => 'Pokoje';

  @override
  String get channels => 'Kanały';

  @override
  String get selectMapLayer => 'Wybierz warstwę mapy';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Satelita ESRI';

  @override
  String get googleHybrid => 'Google Hybrydowa';

  @override
  String get googleRoadmap => 'Google Drogowa';

  @override
  String get googleTerrain => 'Google Teren';

  @override
  String get dragToPosition => 'Drag to Position';

  @override
  String get createSarMarker => 'Utwórz znacznik SAR';

  @override
  String get compass => 'Kompas';

  @override
  String get navigationAndContacts => 'Navigation & Contacts';

  @override
  String get sarAlert => 'ALERT SAR';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get cannotReplySenderMissing =>
      'Cannot reply: sender information missing';

  @override
  String get cannotReplyContactNotFound => 'Cannot reply: contact not found';

  @override
  String get copyText => 'Kopiuj tekst';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templateSaved => 'Template saved successfully';

  @override
  String get templateAlreadyExists => 'Template with this emoji already exists';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get deleteMessageConfirmation =>
      'Are you sure you want to delete this message?';

  @override
  String get shareLocation => 'Udostępnij lokalizację';

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
  String get justNow => 'Przed chwilą';

  @override
  String minutesAgo(int minutes) {
    return '$minutes min temu';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours godz. temu';
  }

  @override
  String daysAgo(int days) {
    return '$days dni temu';
  }

  @override
  String secondsAgo(int seconds) {
    return '$seconds sek. temu';
  }

  @override
  String get sending => 'Wysyłanie...';

  @override
  String get sent => 'Wysłano';

  @override
  String get delivered => 'Dostarczono';

  @override
  String deliveredWithTime(int time) {
    return 'Delivered (${time}ms)';
  }

  @override
  String get failed => 'Niepowodzenie';

  @override
  String get broadcast => 'Nadawanie';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Delivered to $delivered/$total contacts';
  }

  @override
  String get allDelivered => 'All delivered';

  @override
  String get recipientDetails => 'Recipient Details';

  @override
  String get pending => 'Oczekujące';

  @override
  String get sarMarkerFoundPerson => 'Found Person';

  @override
  String get sarMarkerFire => 'Fire Location';

  @override
  String get sarMarkerStagingArea => 'Staging Area';

  @override
  String get sarMarkerObject => 'Object Found';

  @override
  String get from => 'Od';

  @override
  String get coordinates => 'Współrzędne';

  @override
  String get tapToViewOnMap => 'Dotknij, aby zobaczyć na mapie';

  @override
  String get radioSettings => 'Ustawienia radia';

  @override
  String get frequencyMHz => 'Częstotliwość (MHz)';

  @override
  String get frequencyExample => 'e.g., 869.618';

  @override
  String get bandwidth => 'Szerokość pasma';

  @override
  String get spreadingFactor => 'Współczynnik rozpraszania';

  @override
  String get codingRate => 'Szybkość kodowania';

  @override
  String get txPowerDbm => 'Moc TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Maks: $power dBm';
  }

  @override
  String get you => 'Ty';

  @override
  String exportFailed(String error) {
    return 'Eksport nie powiódł się: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import nie powiódł się: $error';
  }

  @override
  String get unknown => 'Nieznane';

  @override
  String get onlineLayers => 'Warstwy online';

  @override
  String get locationTrail => 'Ślad lokalizacji';

  @override
  String get showTrailOnMap => 'Pokaż ślad na mapie';

  @override
  String get trailVisible => 'Trail is visible on the map';

  @override
  String get trailHiddenRecording => 'Trail is hidden (still recording)';

  @override
  String get duration => 'Czas trwania';

  @override
  String get points => 'Punkty';

  @override
  String get clearTrail => 'Wyczyść ślad';

  @override
  String get clearTrailQuestion => 'Clear Trail?';

  @override
  String get clearTrailConfirmation =>
      'Are you sure you want to clear the current location trail? This action cannot be undone.';

  @override
  String get noTrailRecorded => 'Brak zapisanego śladu';

  @override
  String get startTrackingToRecord =>
      'Start location tracking to record your trail';

  @override
  String get trailControls => 'Sterowanie śladem';

  @override
  String get contactTrails => 'Ślady kontaktów';

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
  String get deviceInformation => 'Informacje o urządzeniu';

  @override
  String get bleName => 'Nazwa BLE';

  @override
  String get meshName => 'Nazwa mesh';

  @override
  String get notSet => 'Nie ustawiono';

  @override
  String get model => 'Model';

  @override
  String get version => 'Wersja';

  @override
  String get buildDate => 'Data kompilacji';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Maks. kontaktów';

  @override
  String get maxChannels => 'Maks. kanałów';

  @override
  String get publicInfo => 'Public Info';

  @override
  String get meshNetworkName => 'Mesh Network Name';

  @override
  String get nameBroadcastInMesh => 'Name broadcast in mesh advertisements';

  @override
  String get telemetryAndLocationSharing => 'Telemetry & Location Sharing';

  @override
  String get lat => 'Szer.';

  @override
  String get lon => 'Dł.';

  @override
  String get useCurrentLocation => 'Użyj bieżącej lokalizacji';

  @override
  String get noneUnknown => 'None/Unknown';

  @override
  String get chatNode => 'Chat Node';

  @override
  String get repeater => 'Przekaźnik';

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
  String get sarTemplates => 'Szablony SAR';

  @override
  String get manageSarTemplates => 'Manage cursor on target templates';

  @override
  String get addTemplate => 'Dodaj szablon';

  @override
  String get editTemplate => 'Edytuj szablon';

  @override
  String get deleteTemplate => 'Usuń szablon';

  @override
  String get templateName => 'Nazwa szablonu';

  @override
  String get templateNameHint => 'np. Odnaleziona osoba';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji jest wymagane';

  @override
  String get nameRequired => 'Nazwa jest wymagana';

  @override
  String get templateDescription => 'Opis (opcjonalnie)';

  @override
  String get templateDescriptionHint => 'Dodaj dodatkowy kontekst...';

  @override
  String get templateColor => 'Kolor';

  @override
  String get previewFormat => 'Podgląd (format wiadomości SAR)';

  @override
  String get importFromClipboard => 'Importuj';

  @override
  String get exportToClipboard => 'Eksportuj';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Delete template \'$name\'?';
  }

  @override
  String get templateAdded => 'Dodano szablon';

  @override
  String get templateUpdated => 'Zaktualizowano szablon';

  @override
  String get templateDeleted => 'Usunięto szablon';

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
  String get resetToDefaults => 'Przywróć domyślne';

  @override
  String get resetToDefaultsConfirmation =>
      'This will delete all custom templates and restore the 4 default templates. Continue?';

  @override
  String get reset => 'Resetuj';

  @override
  String get resetComplete => 'Templates reset to defaults';

  @override
  String get noTemplates => 'Brak dostępnych szablonów';

  @override
  String get tapAddToCreate => 'Dotknij +, aby utworzyć pierwszy szablon';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Uprawnienia';

  @override
  String get locationPermission => 'Uprawnienie lokalizacji';

  @override
  String get checking => 'Sprawdzanie...';

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
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get locationPermissionGranted => 'Przyznano uprawnienie lokalizacji!';

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
  String get selectRecipient => 'Wybierz odbiorcę';

  @override
  String get broadcastToAllNearby => 'Broadcast to all nearby';

  @override
  String get searchRecipients => 'Szukaj odbiorców...';

  @override
  String get noContactsFound => 'Nie znaleziono kontaktów';

  @override
  String get noRoomsFound => 'Nie znaleziono pokoi';

  @override
  String get noRecipientsAvailable => 'Brak dostępnych odbiorców';

  @override
  String get noChannelsFound => 'Nie znaleziono kanałów';

  @override
  String get newMessage => 'Nowa wiadomość';

  @override
  String get channel => 'Kanał';

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
  String get channelEmergency => 'Alarmowy';

  @override
  String get channelCoordination => 'Koordynacja';

  @override
  String get channelUpdates => 'Aktualizacje';

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
  String get mapDrawing => 'Rysunek mapy';

  @override
  String get navigateToDrawing => 'Navigate to Drawing';

  @override
  String get copyCoordinates => 'Kopiuj współrzędne';

  @override
  String get hideFromMap => 'Ukryj na mapie';

  @override
  String get lineDrawing => 'Rysunek linii';

  @override
  String get rectangleDrawing => 'Rysunek prostokąta';

  @override
  String get manualCoordinates => 'Współrzędne ręczne';

  @override
  String get enterCoordinatesManually => 'Wprowadź współrzędne ręcznie';

  @override
  String get latitudeLabel => 'Szerokość geograficzna';

  @override
  String get longitudeLabel => 'Długość geograficzna';

  @override
  String get exampleCoordinates => 'Example: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Udostępnij rysunek';

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
  String get line => 'Linia';

  @override
  String get rectangle => 'Prostokąt';

  @override
  String get updateAvailable => 'Dostępna aktualizacja';

  @override
  String get currentVersion => 'Bieżąca';

  @override
  String get latestVersion => 'Najnowsza';

  @override
  String get downloadUpdate => 'Pobierz';

  @override
  String get updateLater => 'Później';

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
  String get recentMessages => 'Ostatnie wiadomości';

  @override
  String get addChannel => 'Dodaj kanał';

  @override
  String get channelName => 'Nazwa kanału';

  @override
  String get channelNameHint => 'np. Zespół Ratunkowy Alfa';

  @override
  String get channelSecret => 'Sekret kanału';

  @override
  String get channelSecretHint => 'Wspólne hasło dla tego kanału';

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
  String get createChannel => 'Utwórz kanał';

  @override
  String get wizardBack => 'Wstecz';

  @override
  String get wizardSkip => 'Pomiń';

  @override
  String get wizardNext => 'Dalej';

  @override
  String get wizardGetStarted => 'Zaczynaj';

  @override
  String get wizardWelcomeTitle => 'Witamy w MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'A powerful off-grid communication tool for search and rescue operations. Connect with your team using mesh radio technology when traditional networks are unavailable.';

  @override
  String get wizardConnectingTitle => 'Łączenie z radiem';

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
  String get wizardChannelTitle => 'Kanały';

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
  String get wizardContactsTitle => 'Kontakty';

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
  String get wizardMapTitle => 'Mapa i lokalizacja';

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
  String get viewWelcomeTutorial => 'Pokaż samouczek powitalny';

  @override
  String get allTeamContacts => 'Wszystkie kontakty zespołu';

  @override
  String directMessagesInfo(int count) {
    return 'Direct messages with ACKs. Sent to $count team members.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR marker sent to $count contacts';
  }

  @override
  String get noContactsAvailable => 'Brak kontaktów zespołu';

  @override
  String get reply => 'Odpowiedz';

  @override
  String get technicalDetails => 'Szczegóły techniczne';

  @override
  String get messageTechnicalDetails => 'Message technical details';

  @override
  String get linkQuality => 'Link quality';

  @override
  String get delivery => 'Delivery';

  @override
  String get status => 'Status';

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
  String get voice => 'Głos';

  @override
  String get voiceId => 'Voice ID';

  @override
  String get envelope => 'Envelope';

  @override
  String get sessionProgress => 'Session progress';

  @override
  String get complete => 'Zakończono';

  @override
  String get rawDump => 'Raw dump';

  @override
  String get cannotRetryMissingRecipient =>
      'Cannot retry: recipient information missing';

  @override
  String get voiceUnavailable => 'Głos jest obecnie niedostępny';

  @override
  String get requestingVoice => 'Requesting voice';
}
