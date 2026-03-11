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
      'Dostęp do lokalizacji został trwale zablokowany. Włącz go w Ustawieniach.';

  @override
  String get locationPermissionRequired =>
      'Dostęp do lokalizacji jest wymagany do śledzenia GPS i koordynacji zespołu. Możesz go włączyć później w Ustawieniach.';

  @override
  String get locationServicesDisabled =>
      'Usługi lokalizacji są wyłączone. Włącz je w Ustawieniach.';

  @override
  String get failedToGetGpsLocation => 'Nie udało się pobrać lokalizacji GPS';

  @override
  String failedToAdvertise(String error) {
    return 'Nie udało się rozgłosić: $error';
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
  String get blueLightTheme => 'Niebieski jasny motyw';

  @override
  String get blueDarkTheme => 'Niebieski ciemny motyw';

  @override
  String get sarRed => 'SAR Czerwony';

  @override
  String get alertEmergencyMode => 'Tryb alarmowy/awaryjny';

  @override
  String get sarGreen => 'SAR Zielony';

  @override
  String get safeAllClearMode => 'Tryb bezpieczny/wszystko jasne';

  @override
  String get autoSystem => 'Automatyczny (system)';

  @override
  String get followSystemTheme => 'Dopasuj do motywu systemowego';

  @override
  String get showRxTxIndicators => 'Pokaż wskaźniki RX/TX';

  @override
  String get displayPacketActivity =>
      'Wyświetlaj wskaźniki aktywności pakietów na górnym pasku';

  @override
  String get disableMap => 'Wyłącz mapę';

  @override
  String get disableMapDescription =>
      'Ukryj kartę mapy, aby zmniejszyć zużycie baterii';

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
  String get appVersion => 'Wersja aplikacji';

  @override
  String get appName => 'Nazwa aplikacji';

  @override
  String get aboutMeshCoreSar => 'O MeshCore SAR';

  @override
  String get aboutDescription =>
      'Aplikacja poszukiwawczo-ratownicza zaprojektowana dla zespołów reagowania kryzysowego. Funkcje obejmują:\n\n• Sieć BLE mesh do komunikacji urządzenie-urządzenie\n• Mapy offline z wieloma warstwami\n• Śledzenie członków zespołu w czasie rzeczywistym\n• Taktyczne znaczniki SAR (odnaleziona osoba, pożar, strefa zbiórki)\n• Zarządzanie kontaktami i wiadomościami\n• Śledzenie GPS z kompasem\n• Buforowanie kafelków mapy do użytku offline';

  @override
  String get technologiesUsed => 'Użyte technologie:';

  @override
  String get technologiesList =>
      '• Flutter do rozwoju wieloplatformowego\n• BLE (Bluetooth Low Energy) do sieci mesh\n• OpenStreetMap do map\n• Provider do zarządzania stanem\n• SharedPreferences do pamięci lokalnej';

  @override
  String get moreInfo => 'Więcej informacji';

  @override
  String get packageName => 'Nazwa pakietu';

  @override
  String get sampleData => 'Dane przykładowe';

  @override
  String get sampleDataDescription =>
      'Wczytaj lub wyczyść przykładowe kontakty, wiadomości kanałów i znaczniki SAR do testów';

  @override
  String get loadSampleData => 'Wczytaj dane przykładowe';

  @override
  String get clearAllData => 'Wyczyść wszystkie dane';

  @override
  String get clearAllDataConfirmTitle => 'Wyczyść wszystkie dane';

  @override
  String get clearAllDataConfirmMessage =>
      'To wyczyści wszystkie kontakty i znaczniki SAR. Czy na pewno?';

  @override
  String get clear => 'Wyczyść';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return 'Wczytano $teamCount członków zespołu, $channelCount kanałów, $sarCount znaczników SAR, $messageCount wiadomości';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Nie udało się wczytać danych przykładowych: $error';
  }

  @override
  String get allDataCleared => 'Wszystkie dane wyczyszczono';

  @override
  String get failedToStartBackgroundTracking =>
      'Nie udało się uruchomić śledzenia w tle. Sprawdź uprawnienia i połączenie BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Nadawanie lokalizacji: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Domyślny PIN dla urządzeń bez ekranu to 123456. Problem z parowaniem? Zapomnij urządzenie Bluetooth w ustawieniach systemu.';

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
  String get resetPath => 'Resetuj trasę (wyznacz ponownie)';

  @override
  String get publicKeyCopied => 'Klucz publiczny skopiowano do schowka';

  @override
  String copiedToClipboard(String label) {
    return 'Skopiowano $label do schowka';
  }

  @override
  String get pleaseEnterPassword => 'Wprowadź hasło';

  @override
  String failedToSyncContacts(String error) {
    return 'Nie udało się zsynchronizować kontaktów: $error';
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
    return 'Nie udało się wysłać logowania: $error';
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
  String get drawLineDesc => 'Narysuj odręczną linię na mapie';

  @override
  String get drawRectangle => 'Rysuj prostokąt';

  @override
  String get drawRectangleDesc => 'Narysuj prostokątny obszar na mapie';

  @override
  String get measureDistance => 'Mierz odległość';

  @override
  String get measureDistanceDesc => 'Przytrzymaj dwa punkty, aby zmierzyć';

  @override
  String get clearMeasurement => 'Wyczyść pomiar';

  @override
  String distanceLabel(String distance) {
    return 'Odległość: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Przytrzymaj dla drugiego punktu';

  @override
  String get longPressToStartMeasurement =>
      'Przytrzymaj, aby ustawić pierwszy punkt';

  @override
  String get longPressToStartNewMeasurement =>
      'Przytrzymaj, aby rozpocząć nowy pomiar';

  @override
  String get shareDrawings => 'Udostępnij rysunki';

  @override
  String get clearAllDrawings => 'Wyczyść wszystkie rysunki';

  @override
  String get completeLine => 'Zakończ linię';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return 'Nadaj $count rysunek$plural do zespołu';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Usuń wszystkie $count rysunek$plural';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Usunąć wszystkie $count rysunek$plural z mapy?';
  }

  @override
  String get drawing => 'Rysunek';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Udostępnij $count rysunek$plural';
  }

  @override
  String get showReceivedDrawings => 'Pokaż odebrane rysunki';

  @override
  String get showingAllDrawings => 'Pokazywane są wszystkie rysunki';

  @override
  String get showingOnlyYourDrawings => 'Pokazywane są tylko twoje rysunki';

  @override
  String get showSarMarkers => 'Pokaż znaczniki SAR';

  @override
  String get showingSarMarkers => 'Pokazywane są znaczniki SAR';

  @override
  String get hidingSarMarkers => 'Ukrywanie znaczników SAR';

  @override
  String get clearAll => 'Wyczyść wszystko';

  @override
  String get publicChannel => 'Kanał publiczny';

  @override
  String get broadcastToAll =>
      'Nadaj do wszystkich pobliskich węzłów (tymczasowo)';

  @override
  String get storedPermanently => 'Przechowywane na stałe w pokoju';

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
  String get noDestinationsAvailable => 'Brak dostępnych odbiorców.';

  @override
  String get selectDestination => 'Wybierz odbiorcę...';

  @override
  String get ephemeralBroadcastInfo =>
      'Tymczasowe: nadawane tylko drogą radiową. Nie jest zapisywane - węzły muszą być online.';

  @override
  String get persistentRoomInfo =>
      'Trwałe: zapisywane niezmiennie w pokoju. Synchronizowane automatycznie i zachowywane offline.';

  @override
  String get location => 'Lokalizacja';

  @override
  String get fromMap => 'Z mapy';

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
    return 'Dokładność: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notatki (opcjonalnie)';

  @override
  String get addAdditionalInformation => 'Dodaj dodatkowe informacje...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Dokładność lokalizacji wynosi ±${accuracy}m. To może nie być wystarczająco dokładne dla działań SAR.\n\nKontynuować mimo to?';
  }

  @override
  String get loginToRoom => 'Zaloguj do pokoju';

  @override
  String get enterPasswordInfo =>
      'Wprowadź hasło, aby uzyskać dostęp do tego pokoju. Hasło zostanie zapisane na przyszłość.';

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
    return 'Nie udało się dodać pokoju do urządzenia: $error\n\nPokój mógł jeszcze nie rozpocząć nadawania.\nSpróbuj poczekać, aż pokój zacznie nadawać.';
  }

  @override
  String get direct => 'Bezpośrednie';

  @override
  String get flood => 'Rozgłoszeniowo';

  @override
  String get loggedIn => 'Zalogowano';

  @override
  String get noGpsData => 'Brak danych GPS';

  @override
  String get distance => 'Odległość';

  @override
  String directPingTimeout(String name) {
    return 'Przekroczono czas bezpośredniego ping - ponawianie dla $name przez flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping do $name nie powiódł się - nie otrzymano odpowiedzi';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Czy na pewno chcesz usunąć „$name”?\n\nTo usunie kontakt zarówno z aplikacji, jak i z towarzyszącego urządzenia radiowego.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Nie udało się usunąć kontaktu: $error';
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
  String get adminAccess => 'Dostęp administratora';

  @override
  String get yes => 'Tak';

  @override
  String get no => 'Nie';

  @override
  String get permissions => 'Uprawnienia';

  @override
  String get passwordSaved => 'Hasło zapisano';

  @override
  String get locationColon => 'Lokalizacja:';

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
  String get gpsTelemetry => 'GPS (telemetria)';

  @override
  String get updated => 'Zaktualizowano';

  @override
  String pathResetInfo(String name) {
    return 'Trasa dla $name została zresetowana. Następna wiadomość znajdzie nową trasę.';
  }

  @override
  String get reLoginToRoom => 'Zaloguj ponownie do pokoju';

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
  String get filterMarkersTooltip => 'Filtruj znaczniki';

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
  String get ahead => 'przed tobą';

  @override
  String degreesRight(int degrees) {
    return '$degrees° w prawo';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° w lewo';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Szer.: $latitude Dł.: $longitude';
  }

  @override
  String get noContactsYet => 'Brak kontaktów';

  @override
  String get connectToDeviceToLoadContacts =>
      'Połącz się z urządzeniem, aby wczytać kontakty';

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
  String get dragToPosition => 'Przeciągnij do pozycji';

  @override
  String get createSarMarker => 'Utwórz znacznik SAR';

  @override
  String get compass => 'Kompas';

  @override
  String get navigationAndContacts => 'Nawigacja i kontakty';

  @override
  String get sarAlert => 'ALERT SAR';

  @override
  String get textCopiedToClipboard => 'Tekst skopiowano do schowka';

  @override
  String get cannotReplySenderMissing =>
      'Nie można odpowiedzieć: brak informacji o nadawcy';

  @override
  String get cannotReplyContactNotFound =>
      'Nie można odpowiedzieć: nie znaleziono kontaktu';

  @override
  String get copyText => 'Kopiuj tekst';

  @override
  String get saveAsTemplate => 'Zapisz jako szablon';

  @override
  String get templateSaved => 'Szablon zapisano pomyślnie';

  @override
  String get templateAlreadyExists => 'Szablon z tym emoji już istnieje';

  @override
  String get deleteMessage => 'Usuń wiadomość';

  @override
  String get deleteMessageConfirmation =>
      'Czy na pewno chcesz usunąć tę wiadomość?';

  @override
  String get shareLocation => 'Udostępnij lokalizację';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nWspółrzędne: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'Lokalizacja SAR';

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
    return 'Dostarczono (${time}ms)';
  }

  @override
  String get failed => 'Niepowodzenie';

  @override
  String get broadcast => 'Nadawanie';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Dostarczono do $delivered/$total kontaktów';
  }

  @override
  String get allDelivered => 'Wszystko dostarczono';

  @override
  String get recipientDetails => 'Szczegóły odbiorcy';

  @override
  String get pending => 'Oczekujące';

  @override
  String get sarMarkerFoundPerson => 'Odnaleziona osoba';

  @override
  String get sarMarkerFire => 'Miejsce pożaru';

  @override
  String get sarMarkerStagingArea => 'Strefa zbiórki';

  @override
  String get sarMarkerObject => 'Odnaleziony obiekt';

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
  String get frequencyExample => 'np. 869.618';

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
  String get trailVisible => 'Ślad jest widoczny na mapie';

  @override
  String get trailHiddenRecording => 'Ślad jest ukryty (nadal nagrywany)';

  @override
  String get duration => 'Czas trwania';

  @override
  String get points => 'Punkty';

  @override
  String get clearTrail => 'Wyczyść ślad';

  @override
  String get clearTrailQuestion => 'Wyczyścić ślad?';

  @override
  String get clearTrailConfirmation =>
      'Czy na pewno chcesz wyczyścić bieżący ślad lokalizacji? Tego działania nie można cofnąć.';

  @override
  String get noTrailRecorded => 'Brak zapisanego śladu';

  @override
  String get startTrackingToRecord =>
      'Rozpocznij śledzenie lokalizacji, aby zapisać ślad';

  @override
  String get trailControls => 'Sterowanie śladem';

  @override
  String get contactTrails => 'Ślady kontaktów';

  @override
  String get showAllContactTrails => 'Pokaż wszystkie ślady kontaktów';

  @override
  String get noContactsWithLocationHistory =>
      'Brak kontaktów z historią lokalizacji';

  @override
  String showingTrailsForContacts(int count) {
    return 'Pokazywane są ślady dla $count kontaktów';
  }

  @override
  String get individualContactTrails => 'Indywidualne ślady kontaktów';

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
  String get publicInfo => 'Informacje publiczne';

  @override
  String get meshNetworkName => 'Nazwa sieci mesh';

  @override
  String get nameBroadcastInMesh => 'Nazwa nadawana w ogłoszeniach mesh';

  @override
  String get telemetryAndLocationSharing =>
      'Telemetria i udostępnianie lokalizacji';

  @override
  String get lat => 'Szer.';

  @override
  String get lon => 'Dł.';

  @override
  String get useCurrentLocation => 'Użyj bieżącej lokalizacji';

  @override
  String get noneUnknown => 'Brak/Nieznane';

  @override
  String get chatNode => 'Węzeł czatu';

  @override
  String get repeater => 'Przekaźnik';

  @override
  String get roomChannel => 'Pokój/Kanał';

  @override
  String typeNumber(int number) {
    return 'Typ $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return 'Skopiowano $label do schowka';
  }

  @override
  String failedToSave(String error) {
    return 'Nie udało się zapisać: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Nie udało się pobrać lokalizacji: $error';
  }

  @override
  String get sarTemplates => 'Szablony SAR';

  @override
  String get manageSarTemplates => 'Zarządzaj szablonami SAR';

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
    return 'Usunąć szablon „$name”?';
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
      other: 'Zaimportowano $count szablonów',
      one: 'Zaimportowano 1 szablon',
      zero: 'Nie zaimportowano szablonów',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Wyeksportowano $count szablonów do schowka',
      one: 'Wyeksportowano 1 szablon do schowka',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Przywróć domyślne';

  @override
  String get resetToDefaultsConfirmation =>
      'To usunie wszystkie własne szablony i przywróci 4 domyślne szablony. Kontynuować?';

  @override
  String get reset => 'Resetuj';

  @override
  String get resetComplete => 'Szablony przywrócono do domyślnych';

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
  String get locationPermissionGrantedAlways => 'Przyznano (zawsze)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Przyznano (podczas użycia)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Odrzucono - dotknij, aby poprosić';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Trwale odrzucono - otwórz ustawienia';

  @override
  String get locationPermissionDialogContent =>
      'Dostęp do lokalizacji został trwale odrzucony. Włącz go w ustawieniach urządzenia, aby używać GPS i udostępniania lokalizacji.';

  @override
  String get openSettings => 'Otwórz ustawienia';

  @override
  String get locationPermissionGranted => 'Przyznano uprawnienie lokalizacji!';

  @override
  String get locationPermissionRequiredForGps =>
      'Dostęp do lokalizacji jest wymagany do śledzenia GPS i udostępniania lokalizacji.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Dostęp do lokalizacji został już przyznany.';

  @override
  String get sarNavyBlue => 'SAR Granatowy';

  @override
  String get sarNavyBlueDescription => 'Tryb profesjonalny/operacyjny';

  @override
  String get selectRecipient => 'Wybierz odbiorcę';

  @override
  String get broadcastToAllNearby => 'Nadaj do wszystkich w pobliżu';

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
  String get samplePoliceLead => 'Dowódca policji';

  @override
  String get sampleDroneOperator => 'Operator drona';

  @override
  String get sampleFirefighterAlpha => 'Strażak';

  @override
  String get sampleMedicCharlie => 'Ratownik medyczny';

  @override
  String get sampleCommandDelta => 'Dowództwo';

  @override
  String get sampleFireEngine => 'Wóz strażacki';

  @override
  String get sampleAirSupport => 'Wsparcie lotnicze';

  @override
  String get sampleBaseCoordinator => 'Koordynator bazy';

  @override
  String get channelEmergency => 'Alarmowy';

  @override
  String get channelCoordination => 'Koordynacja';

  @override
  String get channelUpdates => 'Aktualizacje';

  @override
  String get sampleTeamMember => 'Przykładowy członek zespołu';

  @override
  String get sampleScout => 'Przykładowy zwiadowca';

  @override
  String get sampleBase => 'Przykładowa baza';

  @override
  String get sampleSearcher => 'Przykładowy poszukiwacz';

  @override
  String get sampleObjectBackpack => ' Znaleziono plecak - kolor niebieski';

  @override
  String get sampleObjectVehicle => ' Porzucony pojazd - sprawdzić właściciela';

  @override
  String get sampleObjectCamping => ' Znaleziono sprzęt kempingowy';

  @override
  String get sampleObjectTrailMarker =>
      ' Znaleziono znacznik szlaku poza trasą';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Wszystkie zespoły - meldunek';

  @override
  String get sampleMsgWeatherUpdate =>
      'Aktualizacja pogody: bezchmurnie, temp. 18°C';

  @override
  String get sampleMsgBaseCamp => 'Bazę założono w strefie zbiórki';

  @override
  String get sampleMsgTeamAlpha => 'Zespół przemieszcza się do sektora 2';

  @override
  String get sampleMsgRadioCheck =>
      'Kontrola radiowa - wszystkie stacje proszone o odpowiedź';

  @override
  String get sampleMsgWaterSupply => 'Woda dostępna w punkcie kontrolnym 3';

  @override
  String get sampleMsgTeamBravo => 'Zespół melduje: sektor 1 czysty';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Szacowany czas dotarcia do punktu zbiórki: 15 minut';

  @override
  String get sampleMsgSupplyDrop => 'Zrzut zaopatrzenia potwierdzony na 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Rozpoznanie dronem zakończone - brak wyników';

  @override
  String get sampleMsgTeamCharlie => 'Zespół prosi o wsparcie';

  @override
  String get sampleMsgRadioDiscipline =>
      'Wszystkie jednostki: zachować dyscyplinę radiową';

  @override
  String get sampleMsgUrgentMedical =>
      'PILNE: potrzebna pomoc medyczna w sektorze 4';

  @override
  String get sampleMsgAdultMale => ' Dorosły mężczyzna, przytomny';

  @override
  String get sampleMsgFireSpotted => 'Wykryto pożar - współrzędne w drodze';

  @override
  String get sampleMsgSpreadingRapidly => ' Szybko się rozprzestrzenia!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORYTET: potrzebne wsparcie śmigłowca';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Zespół medyczny jest w drodze do twojej lokalizacji';

  @override
  String get sampleMsgEvacHelicopter => 'ETA śmigłowca ewakuacyjnego 10 minut';

  @override
  String get sampleMsgEmergencyResolved =>
      'Sytuacja opanowana - wszystko jasne';

  @override
  String get sampleMsgEmergencyStagingArea => ' Strefa zbiórki awaryjnej';

  @override
  String get sampleMsgEmergencyServices =>
      'Służby ratunkowe zostały powiadomione i jadą na miejsce';

  @override
  String get sampleAlphaTeamLead => 'Lider zespołu';

  @override
  String get sampleBravoScout => 'Zwiadowca';

  @override
  String get sampleCharlieMedic => 'Ratownik medyczny';

  @override
  String get sampleDeltaNavigator => 'Nawigator';

  @override
  String get sampleEchoSupport => 'Wsparcie';

  @override
  String get sampleBaseCommand => 'Dowództwo bazy';

  @override
  String get sampleFieldCoordinator => 'Koordynator terenowy';

  @override
  String get sampleMedicalTeam => 'Zespół medyczny';

  @override
  String get mapDrawing => 'Rysunek mapy';

  @override
  String get navigateToDrawing => 'Nawiguj do rysunku';

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
  String get exampleCoordinates => 'Przykład: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Udostępnij rysunek';

  @override
  String get shareWithAllNearbyDevices =>
      'Udostępnij wszystkim pobliskim urządzeniom';

  @override
  String get shareToRoom => 'Udostępnij do pokoju';

  @override
  String get sendToPersistentStorage => 'Wyślij do trwałego magazynu pokoju';

  @override
  String get deleteDrawingConfirm => 'Czy na pewno chcesz usunąć ten rysunek?';

  @override
  String get drawingDeleted => 'Rysunek usunięto';

  @override
  String yourDrawingsCount(int count) {
    return 'Twoje rysunki ($count)';
  }

  @override
  String get shared => 'Udostępniono';

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
  String get cadastralParcels => 'Działki katastralne';

  @override
  String get forestRoads => 'Drogi leśne';

  @override
  String get wmsOverlays => 'Nakładki WMS';

  @override
  String get hikingTrails => 'Szlaki piesze';

  @override
  String get mainRoads => 'Drogi główne';

  @override
  String get houseNumbers => 'Numery budynków';

  @override
  String get fireHazardZones => 'Strefy zagrożenia pożarowego';

  @override
  String get historicalFires => 'Historyczne pożary';

  @override
  String get firebreaks => 'Pasy przeciwpożarowe';

  @override
  String get krasFireZones => 'Strefy pożarowe Krasu';

  @override
  String get placeNames => 'Nazwy miejsc';

  @override
  String get municipalityBorders => 'Granice gmin';

  @override
  String get topographicMap => 'Mapa topograficzna 1:25000';

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
      'Ten sekret musi być współdzielony ze wszystkimi członkami zespołu, którzy potrzebują dostępu do tego kanału';

  @override
  String get channelTypesInfo =>
      'Kanały hash (#team): sekret jest generowany automatycznie z nazwy. Ta sama nazwa = ten sam kanał na wszystkich urządzeniach.\n\nKanały prywatne: użyj jawnego sekretu. Dołączyć mogą tylko osoby znające sekret.';

  @override
  String get hashChannelInfo =>
      'Kanał hash: sekret zostanie wygenerowany automatycznie z nazwy kanału. Każdy używający tej samej nazwy dołączy do tego samego kanału.';

  @override
  String get channelNameRequired => 'Nazwa kanału jest wymagana';

  @override
  String get channelNameTooLong =>
      'Nazwa kanału może mieć maksymalnie 31 znaków';

  @override
  String get channelSecretRequired => 'Sekret kanału jest wymagany';

  @override
  String get channelSecretTooLong =>
      'Sekret kanału może mieć maksymalnie 32 znaki';

  @override
  String get invalidAsciiCharacters => 'Dozwolone są tylko znaki ASCII';

  @override
  String get channelCreatedSuccessfully => 'Kanał utworzono pomyślnie';

  @override
  String channelCreationFailed(String error) {
    return 'Nie udało się utworzyć kanału: $error';
  }

  @override
  String get deleteChannel => 'Usuń kanał';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Czy na pewno chcesz usunąć kanał „$channelName”? Tej operacji nie można cofnąć.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanał usunięto pomyślnie';

  @override
  String channelDeletionFailed(String error) {
    return 'Nie udało się usunąć kanału: $error';
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
      'Potężne narzędzie komunikacji poza siecią do operacji poszukiwawczo-ratowniczych. Połącz się ze swoim zespołem przy użyciu technologii radia mesh, gdy tradycyjne sieci są niedostępne.';

  @override
  String get wizardConnectingTitle => 'Łączenie z radiem';

  @override
  String get wizardConnectingDescription =>
      'Połącz smartfon z urządzeniem radiowym MeshCore przez Bluetooth, aby rozpocząć komunikację poza siecią.';

  @override
  String get wizardConnectingFeature1 => 'Skanuj pobliskie urządzenia MeshCore';

  @override
  String get wizardConnectingFeature2 => 'Sparuj radio przez Bluetooth';

  @override
  String get wizardConnectingFeature3 =>
      'Działa całkowicie offline - internet nie jest wymagany';

  @override
  String get wizardChannelTitle => 'Kanały';

  @override
  String get wizardChannelDescription =>
      'Nadawaj wiadomości do wszystkich na kanale, idealne do ogłoszeń i koordynacji całego zespołu.';

  @override
  String get wizardChannelFeature1 =>
      'Kanał publiczny do ogólnej komunikacji zespołu';

  @override
  String get wizardChannelFeature2 =>
      'Twórz własne kanały dla konkretnych grup';

  @override
  String get wizardChannelFeature3 =>
      'Wiadomości są automatycznie przekazywane przez mesh';

  @override
  String get wizardContactsTitle => 'Kontakty';

  @override
  String get wizardContactsDescription =>
      'Członkowie zespołu pojawiają się automatycznie, gdy dołączają do sieci mesh. Wyślij im wiadomość bezpośrednią lub zobacz ich lokalizację.';

  @override
  String get wizardContactsFeature1 => 'Kontakty wykrywane automatycznie';

  @override
  String get wizardContactsFeature2 =>
      'Wysyłaj prywatne wiadomości bezpośrednie';

  @override
  String get wizardContactsFeature3 =>
      'Podgląd poziomu baterii i czasu ostatniej aktywności';

  @override
  String get wizardMapTitle => 'Mapa i lokalizacja';

  @override
  String get wizardMapDescription =>
      'Śledź swój zespół w czasie rzeczywistym i oznaczaj ważne lokalizacje dla działań poszukiwawczo-ratowniczych.';

  @override
  String get wizardMapFeature1 =>
      'Znaczniki SAR dla odnalezionych osób, pożarów i stref zbiórki';

  @override
  String get wizardMapFeature2 =>
      'Śledzenie GPS członków zespołu w czasie rzeczywistym';

  @override
  String get wizardMapFeature3 =>
      'Pobieraj mapy offline dla odległych obszarów';

  @override
  String get wizardMapFeature4 =>
      'Rysuj kształty i udostępniaj informacje taktyczne';

  @override
  String get viewWelcomeTutorial => 'Pokaż samouczek powitalny';

  @override
  String get allTeamContacts => 'Wszystkie kontakty zespołu';

  @override
  String directMessagesInfo(int count) {
    return 'Wiadomości bezpośrednie z ACK. Wysłano do $count członków zespołu.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'Znacznik SAR wysłano do $count kontaktów';
  }

  @override
  String get noContactsAvailable => 'Brak kontaktów zespołu';

  @override
  String get reply => 'Odpowiedz';

  @override
  String get technicalDetails => 'Szczegóły techniczne';

  @override
  String get messageTechnicalDetails => 'Szczegóły techniczne wiadomości';

  @override
  String get linkQuality => 'Jakość łącza';

  @override
  String get delivery => 'Dostarczenie';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Oczekiwany znacznik ACK';

  @override
  String get roundTrip => 'Czas podróży w obie strony';

  @override
  String get retryAttempt => 'Próba ponowienia';

  @override
  String get floodFallback => 'Awaryjny flooding';

  @override
  String get identity => 'Tożsamość';

  @override
  String get messageId => 'ID wiadomości';

  @override
  String get sender => 'Nadawca';

  @override
  String get senderKey => 'Klucz nadawcy';

  @override
  String get recipient => 'Odbiorca';

  @override
  String get recipientKey => 'Klucz odbiorcy';

  @override
  String get voice => 'Głos';

  @override
  String get voiceId => 'ID głosu';

  @override
  String get envelope => 'Koperta';

  @override
  String get sessionProgress => 'Postęp sesji';

  @override
  String get complete => 'Zakończono';

  @override
  String get rawDump => 'Surowy zrzut';

  @override
  String get cannotRetryMissingRecipient =>
      'Nie można ponowić: brak informacji o odbiorcy';

  @override
  String get voiceUnavailable => 'Głos jest obecnie niedostępny';

  @override
  String get requestingVoice => 'Pobieranie głosu';

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
