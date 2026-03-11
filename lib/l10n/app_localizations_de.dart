// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Nachrichten';

  @override
  String get contacts => 'Kontakte';

  @override
  String get map => 'Karte';

  @override
  String get settings => 'Einstellungen';

  @override
  String get connect => 'Verbinden';

  @override
  String get disconnect => 'Trennen';

  @override
  String get noDevicesFound => 'Keine Geräte gefunden';

  @override
  String get scanAgain => 'Erneut scannen';

  @override
  String get tapToConnect => 'Zum Verbinden tippen';

  @override
  String get deviceNotConnected => 'Gerät nicht verbunden';

  @override
  String get locationPermissionDenied => 'Standortberechtigung verweigert';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Standortberechtigung dauerhaft verweigert. Bitte in den Einstellungen aktivieren.';

  @override
  String get locationPermissionRequired =>
      'Die Standortberechtigung ist für GPS-Tracking und Teamkoordination erforderlich. Sie können sie später in den Einstellungen aktivieren.';

  @override
  String get locationServicesDisabled =>
      'Standortdienste sind deaktiviert. Bitte aktivieren Sie sie in den Einstellungen.';

  @override
  String get failedToGetGpsLocation =>
      'GPS-Position konnte nicht abgerufen werden';

  @override
  String failedToAdvertise(String error) {
    return 'Senden fehlgeschlagen: $error';
  }

  @override
  String get cancelReconnection => 'Wiederverbindung abbrechen';

  @override
  String get general => 'Allgemein';

  @override
  String get theme => 'Design';

  @override
  String get chooseTheme => 'Design auswählen';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get blueLightTheme => 'Blaues helles Design';

  @override
  String get blueDarkTheme => 'Blaues dunkles Design';

  @override
  String get sarRed => 'SAR Rot';

  @override
  String get alertEmergencyMode => 'Alarm-/Notfallmodus';

  @override
  String get sarGreen => 'SAR Grün';

  @override
  String get safeAllClearMode => 'Sicher/Entwarnung-Modus';

  @override
  String get autoSystem => 'Automatisch (System)';

  @override
  String get followSystemTheme => 'System-Design folgen';

  @override
  String get showRxTxIndicators => 'RX/TX-Indikatoren anzeigen';

  @override
  String get displayPacketActivity =>
      'Paketaktivitätsindikatoren in der oberen Leiste anzeigen';

  @override
  String get disableMap => 'Karte deaktivieren';

  @override
  String get disableMapDescription =>
      'Karten-Tab ausblenden, um Akku zu sparen';

  @override
  String get language => 'Sprache';

  @override
  String get chooseLanguage => 'Sprache auswählen';

  @override
  String get save => 'Speichern';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get about => 'Über';

  @override
  String get appVersion => 'App-Version';

  @override
  String get appName => 'App-Name';

  @override
  String get aboutMeshCoreSar => 'Über MeshCore SAR';

  @override
  String get aboutDescription =>
      'Eine Such- und Rettungsanwendung für Notfallteams. Funktionen umfassen:\n\n• BLE-Mesh-Netzwerk für Gerät-zu-Gerät-Kommunikation\n• Offline-Karten mit mehreren Ebenenoptionen\n• Echtzeit-Teammitgliederverfolgung\n• SAR-Taktikmarkierungen (Person gefunden, Feuer, Sammelpunkt)\n• Kontaktverwaltung und Nachrichtenübermittlung\n• GPS-Tracking mit Kompass-Kurs\n• Karten-Tile-Caching für Offline-Nutzung';

  @override
  String get technologiesUsed => 'Verwendete Technologien:';

  @override
  String get technologiesList =>
      '• Flutter für plattformübergreifende Entwicklung\n• BLE (Bluetooth Low Energy) für Mesh-Netzwerk\n• OpenStreetMap für Kartendarstellung\n• Provider für Zustandsverwaltung\n• SharedPreferences für lokale Speicherung';

  @override
  String get moreInfo => 'Mehr Info';

  @override
  String get packageName => 'Paketname';

  @override
  String get sampleData => 'Beispieldaten';

  @override
  String get sampleDataDescription =>
      'Laden oder löschen Sie Beispielkontakte, Kanalnachrichten und SAR-Markierungen zum Testen';

  @override
  String get loadSampleData => 'Beispieldaten laden';

  @override
  String get clearAllData => 'Alle Daten löschen';

  @override
  String get clearAllDataConfirmTitle => 'Alle Daten löschen';

  @override
  String get clearAllDataConfirmMessage =>
      'Dadurch werden alle Kontakte und SAR-Markierungen gelöscht. Sind Sie sicher?';

  @override
  String get clear => 'Löschen';

  @override
  String loadedSampleData(
    int teamCount,
    int channelCount,
    int sarCount,
    int messageCount,
  ) {
    return '$teamCount Teammitglieder, $channelCount Kanäle, $sarCount SAR-Markierungen, $messageCount Nachrichten geladen';
  }

  @override
  String failedToLoadSampleData(String error) {
    return 'Fehler beim Laden der Beispieldaten: $error';
  }

  @override
  String get allDataCleared => 'Alle Daten gelöscht';

  @override
  String get failedToStartBackgroundTracking =>
      'Hintergrund-Tracking konnte nicht gestartet werden. Überprüfen Sie Berechtigungen und BLE-Verbindung.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Standortübertragung: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'Die Standard-PIN für Geräte ohne Bildschirm ist 123456. Probleme beim Koppeln? Vergessen Sie das Bluetooth-Gerät in den Systemeinstellungen.';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get pullDownToSync =>
      'Nach unten ziehen, um Nachrichten zu synchronisieren';

  @override
  String get deleteContact => 'Kontakt löschen';

  @override
  String get delete => 'Löschen';

  @override
  String get viewOnMap => 'Auf Karte anzeigen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get resetPath => 'Pfad zurücksetzen (Umleitung)';

  @override
  String get publicKeyCopied =>
      'Öffentlicher Schlüssel in die Zwischenablage kopiert';

  @override
  String copiedToClipboard(String label) {
    return '$label in die Zwischenablage kopiert';
  }

  @override
  String get pleaseEnterPassword => 'Bitte geben Sie ein Passwort ein';

  @override
  String failedToSyncContacts(String error) {
    return 'Kontaktsynchronisation fehlgeschlagen: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Erfolgreich angemeldet! Warte auf Raumnachrichten...';

  @override
  String get loginFailed => 'Anmeldung fehlgeschlagen - falsches Passwort';

  @override
  String loggingIn(String roomName) {
    return 'Anmeldung bei $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Anmeldung senden fehlgeschlagen: $error';
  }

  @override
  String get lowLocationAccuracy => 'Niedrige Standortgenauigkeit';

  @override
  String get continue_ => 'Fortfahren';

  @override
  String get sendSarMarker => 'SAR-Markierung senden';

  @override
  String get deleteDrawing => 'Zeichnung löschen';

  @override
  String get drawingTools => 'Zeichenwerkzeuge';

  @override
  String get drawLine => 'Linie zeichnen';

  @override
  String get drawLineDesc => 'Freihandlinie auf der Karte zeichnen';

  @override
  String get drawRectangle => 'Rechteck zeichnen';

  @override
  String get drawRectangleDesc => 'Rechteckigen Bereich auf der Karte zeichnen';

  @override
  String get measureDistance => 'Entfernung messen';

  @override
  String get measureDistanceDesc => 'Zwei Punkte lang drücken zum Messen';

  @override
  String get clearMeasurement => 'Messung löschen';

  @override
  String distanceLabel(String distance) {
    return 'Entfernung: $distance';
  }

  @override
  String get longPressForSecondPoint => 'Langer Druck für zweiten Punkt';

  @override
  String get longPressToStartMeasurement => 'Langer Druck für ersten Punkt';

  @override
  String get longPressToStartNewMeasurement => 'Langer Druck für neue Messung';

  @override
  String get shareDrawings => 'Zeichnungen teilen';

  @override
  String get clearAllDrawings => 'Alle Zeichnungen löschen';

  @override
  String get completeLine => 'Linie fertigstellen';

  @override
  String broadcastDrawingsToTeam(int count, String plural) {
    return '$count Zeichnung$plural an Team senden';
  }

  @override
  String removeAllDrawings(int count, String plural) {
    return 'Alle $count Zeichnung$plural entfernen';
  }

  @override
  String deleteAllDrawingsConfirm(int count, String plural) {
    return 'Alle $count Zeichnung$plural von der Karte löschen?';
  }

  @override
  String get drawing => 'Zeichnung';

  @override
  String shareDrawingsCount(int count, String plural) {
    return '$count Zeichnung$plural teilen';
  }

  @override
  String get showReceivedDrawings => 'Empfangene Zeichnungen anzeigen';

  @override
  String get showingAllDrawings => 'Alle Zeichnungen werden angezeigt';

  @override
  String get showingOnlyYourDrawings => 'Nur Ihre Zeichnungen werden angezeigt';

  @override
  String get showSarMarkers => 'SAR-Markierungen anzeigen';

  @override
  String get showingSarMarkers => 'SAR-Markierungen werden angezeigt';

  @override
  String get hidingSarMarkers => 'SAR-Markierungen ausgeblendet';

  @override
  String get clearAll => 'Alle löschen';

  @override
  String get publicChannel => 'Öffentlicher Kanal';

  @override
  String get broadcastToAll => 'An alle Knoten in der Nähe senden (temporär)';

  @override
  String get storedPermanently => 'Dauerhaft im Raum gespeichert';

  @override
  String get notConnectedToDevice => 'Nicht mit Gerät verbunden';

  @override
  String get typeYourMessage => 'Geben Sie Ihre Nachricht ein...';

  @override
  String get quickLocationMarker => 'Schnelle Standortmarkierung';

  @override
  String get markerType => 'Markierungstyp';

  @override
  String get sendTo => 'Senden an';

  @override
  String get noDestinationsAvailable => 'Keine Ziele verfügbar.';

  @override
  String get selectDestination => 'Ziel auswählen...';

  @override
  String get ephemeralBroadcastInfo =>
      'Temporär: Nur Over-the-Air-Übertragung. Nicht gespeichert - Knoten müssen online sein.';

  @override
  String get persistentRoomInfo =>
      'Dauerhaft: Unveränderlich im Raum gespeichert. Automatisch synchronisiert und offline gespeichert.';

  @override
  String get location => 'Standort';

  @override
  String get fromMap => 'Von Karte';

  @override
  String get gettingLocation => 'Standort wird abgerufen...';

  @override
  String get locationError => 'Standortfehler';

  @override
  String get retry => 'Wiederholen';

  @override
  String get refreshLocation => 'Standort aktualisieren';

  @override
  String accuracyMeters(int accuracy) {
    return 'Genauigkeit: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get addAdditionalInformation =>
      'Zusätzliche Informationen hinzufügen...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Standortgenauigkeit beträgt ±${accuracy}m. Dies ist möglicherweise nicht genau genug für SAR-Operationen.\n\nTrotzdem fortfahren?';
  }

  @override
  String get loginToRoom => 'Bei Raum anmelden';

  @override
  String get enterPasswordInfo =>
      'Geben Sie das Passwort ein, um auf diesen Raum zuzugreifen. Das Passwort wird für die zukünftige Verwendung gespeichert.';

  @override
  String get password => 'Passwort';

  @override
  String get enterRoomPassword => 'Raumpasswort eingeben';

  @override
  String get loggingInDots => 'Anmeldung läuft...';

  @override
  String get login => 'Anmelden';

  @override
  String failedToAddRoom(String error) {
    return 'Fehler beim Hinzufügen des Raums zum Gerät: $error\n\nDer Raum hat möglicherweise noch nicht gesendet.\nVersuchen Sie zu warten, bis der Raum sendet.';
  }

  @override
  String get direct => 'Direkt';

  @override
  String get flood => 'Flut';

  @override
  String get loggedIn => 'Angemeldet';

  @override
  String get noGpsData => 'Keine GPS-Daten';

  @override
  String get distance => 'Entfernung';

  @override
  String directPingTimeout(String name) {
    return 'Direkter Ping-Timeout - wiederhole $name mit Flutung...';
  }

  @override
  String pingFailed(String name) {
    return 'Ping fehlgeschlagen an $name - keine Antwort erhalten';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten?\n\nDies entfernt den Kontakt sowohl aus der App als auch vom Begleitfunkgerät.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Fehler beim Entfernen des Kontakts: $error';
  }

  @override
  String get type => 'Typ';

  @override
  String get publicKey => 'Öffentlicher Schlüssel';

  @override
  String get lastSeen => 'Zuletzt gesehen';

  @override
  String get roomStatus => 'Raumstatus';

  @override
  String get loginStatus => 'Anmeldestatus';

  @override
  String get notLoggedIn => 'Nicht angemeldet';

  @override
  String get adminAccess => 'Admin-Zugriff';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nein';

  @override
  String get permissions => 'Berechtigungen';

  @override
  String get passwordSaved => 'Passwort gespeichert';

  @override
  String get locationColon => 'Standort:';

  @override
  String get telemetry => 'Telemetrie';

  @override
  String get voltage => 'Spannung';

  @override
  String get battery => 'Batterie';

  @override
  String get temperature => 'Temperatur';

  @override
  String get humidity => 'Luftfeuchtigkeit';

  @override
  String get pressure => 'Druck';

  @override
  String get gpsTelemetry => 'GPS (Telemetrie)';

  @override
  String get updated => 'Aktualisiert';

  @override
  String pathResetInfo(String name) {
    return 'Pfad zurückgesetzt für $name. Nächste Nachricht findet eine neue Route.';
  }

  @override
  String get reLoginToRoom => 'Erneut bei Raum anmelden';

  @override
  String get heading => 'Kurs';

  @override
  String get elevation => 'Höhe';

  @override
  String get accuracy => 'Genauigkeit';

  @override
  String get bearing => 'Peilung';

  @override
  String get direction => 'Richtung';

  @override
  String get filterMarkers => 'Markierungen filtern';

  @override
  String get filterMarkersTooltip => 'Markierungen filtern';

  @override
  String get contactsFilter => 'Kontakte';

  @override
  String get repeatersFilter => 'Repeater';

  @override
  String get sarMarkers => 'SAR-Markierungen';

  @override
  String get foundPerson => 'Person gefunden';

  @override
  String get fire => 'Feuer';

  @override
  String get stagingArea => 'Sammelpunkt';

  @override
  String get showAll => 'Alle anzeigen';

  @override
  String get locationUnavailable => 'Standort nicht verfügbar';

  @override
  String get ahead => 'voraus';

  @override
  String degreesRight(int degrees) {
    return '$degrees° rechts';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° links';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Breite: $latitude Lange: $longitude';
  }

  @override
  String get noContactsYet => 'Noch keine Kontakte';

  @override
  String get connectToDeviceToLoadContacts =>
      'Mit einem Gerät verbinden, um Kontakte zu laden';

  @override
  String get teamMembers => 'Teammitglieder';

  @override
  String get repeaters => 'Repeater';

  @override
  String get rooms => 'Räume';

  @override
  String get channels => 'Kanäle';

  @override
  String get selectMapLayer => 'Kartenebene auswählen';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'ESRI-Satellit';

  @override
  String get googleHybrid => 'Google Hybrid';

  @override
  String get googleRoadmap => 'Google Straßenkarte';

  @override
  String get googleTerrain => 'Google Gelände';

  @override
  String get dragToPosition => 'Zur Position ziehen';

  @override
  String get createSarMarker => 'SAR-Markierung erstellen';

  @override
  String get compass => 'Kompass';

  @override
  String get navigationAndContacts => 'Navigation & Kontakte';

  @override
  String get sarAlert => 'SAR-ALARM';

  @override
  String get textCopiedToClipboard => 'Text in Zwischenablage kopiert';

  @override
  String get cannotReplySenderMissing =>
      'Antwort nicht möglich: Absenderinformationen fehlen';

  @override
  String get cannotReplyContactNotFound =>
      'Antwort nicht möglich: Kontakt nicht gefunden';

  @override
  String get copyText => 'Text kopieren';

  @override
  String get saveAsTemplate => 'Als Vorlage speichern';

  @override
  String get templateSaved => 'Vorlage erfolgreich gespeichert';

  @override
  String get templateAlreadyExists =>
      'Vorlage mit diesem Emoji existiert bereits';

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deleteMessageConfirmation =>
      'Möchten Sie diese Nachricht wirklich löschen?';

  @override
  String get shareLocation => 'Standort teilen';

  @override
  String shareLocationText(
    String markerInfo,
    String lat,
    String lon,
    String url,
  ) {
    return '$markerInfo\n\nKoordinaten: $lat, $lon\n\nGoogle Maps: $url';
  }

  @override
  String get sarLocationShare => 'SAR Standort';

  @override
  String get justNow => 'Gerade eben';

  @override
  String minutesAgo(int minutes) {
    return 'vor ${minutes}m';
  }

  @override
  String hoursAgo(int hours) {
    return 'vor ${hours}h';
  }

  @override
  String daysAgo(int days) {
    return 'vor ${days}d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'vor ${seconds}s';
  }

  @override
  String get sending => 'Wird gesendet...';

  @override
  String get sent => 'Gesendet';

  @override
  String get delivered => 'Zugestellt';

  @override
  String deliveredWithTime(int time) {
    return 'Zugestellt (${time}ms)';
  }

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get broadcast => 'Rundspruch';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Zugestellt an $delivered/$total Kontakte';
  }

  @override
  String get allDelivered => 'Alle zugestellt';

  @override
  String get recipientDetails => 'Empfängerdetails';

  @override
  String get pending => 'Ausstehend';

  @override
  String get sarMarkerFoundPerson => 'Person gefunden';

  @override
  String get sarMarkerFire => 'Feuerstandort';

  @override
  String get sarMarkerStagingArea => 'Sammelpunkt';

  @override
  String get sarMarkerObject => 'Objekt gefunden';

  @override
  String get from => 'Von';

  @override
  String get coordinates => 'Koordinaten';

  @override
  String get tapToViewOnMap => 'Tippen, um auf der Karte anzuzeigen';

  @override
  String get radioSettings => 'Funkeinstellungen';

  @override
  String get frequencyMHz => 'Frequenz (MHz)';

  @override
  String get frequencyExample => 'z.B. 869.618';

  @override
  String get bandwidth => 'Bandbreite';

  @override
  String get spreadingFactor => 'Spreading-Faktor';

  @override
  String get codingRate => 'Codierungsrate';

  @override
  String get txPowerDbm => 'TX-Leistung (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Max.: $power dBm';
  }

  @override
  String get you => 'Du';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get unknown => 'Unbekannt';

  @override
  String get onlineLayers => 'Online-Ebenen';

  @override
  String get locationTrail => 'Standortverlauf';

  @override
  String get showTrailOnMap => 'Verlauf auf Karte anzeigen';

  @override
  String get trailVisible => 'Verlauf ist auf der Karte sichtbar';

  @override
  String get trailHiddenRecording =>
      'Verlauf ist ausgeblendet (Aufzeichnung läuft noch)';

  @override
  String get duration => 'Dauer';

  @override
  String get points => 'Punkte';

  @override
  String get clearTrail => 'Verlauf löschen';

  @override
  String get clearTrailQuestion => 'Verlauf löschen?';

  @override
  String get clearTrailConfirmation =>
      'Sind Sie sicher, dass Sie den aktuellen Standortverlauf löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get noTrailRecorded => 'Noch kein Verlauf aufgezeichnet';

  @override
  String get startTrackingToRecord =>
      'Standort-Tracking starten, um Ihren Verlauf aufzuzeichnen';

  @override
  String get trailControls => 'Verlaufssteuerung';

  @override
  String get contactTrails => 'Kontaktverläufe';

  @override
  String get showAllContactTrails => 'Alle Kontaktverläufe anzeigen';

  @override
  String get noContactsWithLocationHistory =>
      'Keine Kontakte mit Standortverlauf';

  @override
  String showingTrailsForContacts(int count) {
    return 'Verläufe für $count Kontakte anzeigen';
  }

  @override
  String get individualContactTrails => 'Einzelne Kontaktverläufe';

  @override
  String get deviceInformation => 'Geräteinformationen';

  @override
  String get bleName => 'BLE-Name';

  @override
  String get meshName => 'Mesh-Name';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get model => 'Modell';

  @override
  String get version => 'Version';

  @override
  String get buildDate => 'Build-Datum';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Max. Kontakte';

  @override
  String get maxChannels => 'Max. Kanäle';

  @override
  String get publicInfo => 'Öffentliche Informationen';

  @override
  String get meshNetworkName => 'Mesh-Netzwerkname';

  @override
  String get nameBroadcastInMesh =>
      'Name, der in Mesh-Sendungen übertragen wird';

  @override
  String get telemetryAndLocationSharing => 'Telemetrie & Standortfreigabe';

  @override
  String get lat => 'Breite';

  @override
  String get lon => 'Lange';

  @override
  String get useCurrentLocation => 'Aktuellen Standort verwenden';

  @override
  String get noneUnknown => 'Keine/Unbekannt';

  @override
  String get chatNode => 'Chat-Knoten';

  @override
  String get repeater => 'Relais';

  @override
  String get roomChannel => 'Raum/Kanal';

  @override
  String typeNumber(int number) {
    return 'Typ $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label in Zwischenablage kopiert';
  }

  @override
  String failedToSave(String error) {
    return 'Fehler beim Speichern: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Fehler beim Abrufen des Standorts: $error';
  }

  @override
  String get sarTemplates => 'SAR-Vorlagen';

  @override
  String get manageSarTemplates => 'SAR-Vorlagen verwalten';

  @override
  String get addTemplate => 'Vorlage hinzufügen';

  @override
  String get editTemplate => 'Vorlage bearbeiten';

  @override
  String get deleteTemplate => 'Vorlage löschen';

  @override
  String get templateName => 'Vorlagenname';

  @override
  String get templateNameHint => 'z. B. Gefundene Person';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji ist erforderlich';

  @override
  String get nameRequired => 'Name ist erforderlich';

  @override
  String get templateDescription => 'Beschreibung (optional)';

  @override
  String get templateDescriptionHint => 'Zusatzlichen Kontext hinzufugen...';

  @override
  String get templateColor => 'Farbe';

  @override
  String get previewFormat => 'Vorschau (SAR-Nachrichtenformat)';

  @override
  String get importFromClipboard => 'Importieren';

  @override
  String get exportToClipboard => 'Exportieren';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Vorlage \'$name\' loschen?';
  }

  @override
  String get templateAdded => 'Vorlage hinzugefugt';

  @override
  String get templateUpdated => 'Vorlage aktualisiert';

  @override
  String get templateDeleted => 'Vorlage geloscht';

  @override
  String templatesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorlagen importiert',
      one: '1 Vorlage importiert',
      zero: 'Keine Vorlagen importiert',
    );
    return '$_temp0';
  }

  @override
  String templatesExported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Vorlagen in die Zwischenablage exportiert',
      one: '1 Vorlage in die Zwischenablage exportiert',
    );
    return '$_temp0';
  }

  @override
  String get resetToDefaults => 'Auf Standard zurücksetzen';

  @override
  String get resetToDefaultsConfirmation =>
      'Dadurch werden alle benutzerdefinierten Vorlagen gelöscht und die 4 Standardvorlagen wiederhergestellt. Fortfahren?';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get resetComplete => 'Vorlagen auf Standard zurückgesetzt';

  @override
  String get noTemplates => 'Keine Vorlagen verfugbar';

  @override
  String get tapAddToCreate =>
      'Tippen Sie auf +, um Ihre erste Vorlage zu erstellen';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Berechtigungen';

  @override
  String get locationPermission => 'Standortberechtigung';

  @override
  String get checking => 'Überprüfen...';

  @override
  String get locationPermissionGrantedAlways => 'Erteilt (Immer)';

  @override
  String get locationPermissionGrantedWhileInUse =>
      'Erteilt (Während der Nutzung)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Verweigert - Tippen zum Anfragen';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Dauerhaft verweigert - Einstellungen öffnen';

  @override
  String get locationPermissionDialogContent =>
      'Die Standortberechtigung wurde dauerhaft verweigert. Bitte aktivieren Sie sie in Ihren Geräteeinstellungen, um GPS-Tracking und Standortfreigabe zu nutzen.';

  @override
  String get openSettings => 'Einstellungen öffnen';

  @override
  String get locationPermissionGranted => 'Standortberechtigung erteilt!';

  @override
  String get locationPermissionRequiredForGps =>
      'Die Standortberechtigung ist erforderlich für GPS-Tracking und Standortfreigabe.';

  @override
  String get locationPermissionAlreadyGranted =>
      'Die Standortberechtigung wurde bereits erteilt.';

  @override
  String get sarNavyBlue => 'SAR Navy Blau';

  @override
  String get sarNavyBlueDescription => 'Professionell/Einsatzmodus';

  @override
  String get selectRecipient => 'Empfänger auswählen';

  @override
  String get broadcastToAllNearby => 'An alle in der Nähe senden';

  @override
  String get searchRecipients => 'Empfänger suchen...';

  @override
  String get noContactsFound => 'Keine Kontakte gefunden';

  @override
  String get noRoomsFound => 'Keine Räume gefunden';

  @override
  String get noRecipientsAvailable => 'Keine Empfänger verfügbar';

  @override
  String get noChannelsFound => 'Keine Kanäle gefunden';

  @override
  String get newMessage => 'Neue Nachricht';

  @override
  String get channel => 'Kanal';

  @override
  String get samplePoliceLead => 'Polizeiführer';

  @override
  String get sampleDroneOperator => 'Drohnenbediener';

  @override
  String get sampleFirefighterAlpha => 'Feuerwehrmann';

  @override
  String get sampleMedicCharlie => 'Sanitäter';

  @override
  String get sampleCommandDelta => 'Kommando';

  @override
  String get sampleFireEngine => 'Feuerwehrfahrzeug';

  @override
  String get sampleAirSupport => 'Luftunterstützung';

  @override
  String get sampleBaseCoordinator => 'Basiskoordinator';

  @override
  String get channelEmergency => 'Notfall';

  @override
  String get channelCoordination => 'Koordination';

  @override
  String get channelUpdates => 'Aktualisierungen';

  @override
  String get sampleTeamMember => 'Beispiel-Teammitglied';

  @override
  String get sampleScout => 'Beispiel-Späher';

  @override
  String get sampleBase => 'Beispiel-Basis';

  @override
  String get sampleSearcher => 'Beispiel-Sucher';

  @override
  String get sampleObjectBackpack => ' Rucksack gefunden - blaue Farbe';

  @override
  String get sampleObjectVehicle => ' Fahrzeug verlassen - Besitzer prüfen';

  @override
  String get sampleObjectCamping => ' Campingausrüstung entdeckt';

  @override
  String get sampleObjectTrailMarker =>
      ' Wegmarkierung abseits des Pfades gefunden';

  @override
  String get sampleMsgAllTeamsCheckIn => 'Alle Teams melden';

  @override
  String get sampleMsgWeatherUpdate =>
      'Wetterupdate: Klarer Himmel, Temp. 18°C';

  @override
  String get sampleMsgBaseCamp => 'Basislager am Sammelplatz eingerichtet';

  @override
  String get sampleMsgTeamAlpha => 'Team bewegt sich zu Sektor 2';

  @override
  String get sampleMsgRadioCheck => 'Funkcheck - alle Stationen antworten';

  @override
  String get sampleMsgWaterSupply =>
      'Wasserversorgung verfügbar an Kontrollpunkt 3';

  @override
  String get sampleMsgTeamBravo => 'Team meldet: Sektor 1 frei';

  @override
  String get sampleMsgEtaRallyPoint =>
      'Ankunftszeit am Sammelpunkt: 15 Minuten';

  @override
  String get sampleMsgSupplyDrop => 'Versorgungsabwurf bestätigt für 14:00';

  @override
  String get sampleMsgDroneSurvey =>
      'Drohnenüberwachung abgeschlossen - keine Funde';

  @override
  String get sampleMsgTeamCharlie => 'Team fordert Unterstützung an';

  @override
  String get sampleMsgRadioDiscipline =>
      'An alle Einheiten: Funkdisziplin wahren';

  @override
  String get sampleMsgUrgentMedical =>
      'DRINGEND: Medizinische Hilfe benötigt in Sektor 4';

  @override
  String get sampleMsgAdultMale => ' Erwachsener Mann, bei Bewusstsein';

  @override
  String get sampleMsgFireSpotted => 'Feuer gesichtet - Koordinaten folgen';

  @override
  String get sampleMsgSpreadingRapidly => ' Breitet sich schnell aus!';

  @override
  String get sampleMsgPriorityHelicopter =>
      'PRIORITÄT: Brauche Hubschrauberunterstützung';

  @override
  String get sampleMsgMedicalTeamEnRoute =>
      'Medizinisches Team auf dem Weg zu Ihrem Standort';

  @override
  String get sampleMsgEvacHelicopter =>
      'Evakuierungshubschrauber ETA 10 Minuten';

  @override
  String get sampleMsgEmergencyResolved => 'Notfall behoben - alles klar';

  @override
  String get sampleMsgEmergencyStagingArea => ' Notfall-Sammelplatz';

  @override
  String get sampleMsgEmergencyServices =>
      'Rettungsdienste benachrichtigt und auf dem Weg';

  @override
  String get sampleAlphaTeamLead => 'Team-Leiter';

  @override
  String get sampleBravoScout => 'Späher';

  @override
  String get sampleCharlieMedic => 'Sanitäter';

  @override
  String get sampleDeltaNavigator => 'Navigator';

  @override
  String get sampleEchoSupport => 'Unterstützung';

  @override
  String get sampleBaseCommand => 'Basis-Kommando';

  @override
  String get sampleFieldCoordinator => 'Feldkoordinator';

  @override
  String get sampleMedicalTeam => 'Medizinisches Team';

  @override
  String get mapDrawing => 'Kartenzeichnung';

  @override
  String get navigateToDrawing => 'Zur Zeichnung navigieren';

  @override
  String get copyCoordinates => 'Koordinaten kopieren';

  @override
  String get hideFromMap => 'Von Karte ausblenden';

  @override
  String get lineDrawing => 'Linie';

  @override
  String get rectangleDrawing => 'Rechteck';

  @override
  String get manualCoordinates => 'Manuelle Koordinaten';

  @override
  String get enterCoordinatesManually => 'Koordinaten manuell eingeben';

  @override
  String get latitudeLabel => 'Breitengrad';

  @override
  String get longitudeLabel => 'Längengrad';

  @override
  String get exampleCoordinates => 'Beispiel: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Zeichnung teilen';

  @override
  String get shareWithAllNearbyDevices =>
      'Mit allen Geräten in der Nähe teilen';

  @override
  String get shareToRoom => 'In Raum teilen';

  @override
  String get sendToPersistentStorage => 'An persistenten Raum-Speicher senden';

  @override
  String get deleteDrawingConfirm =>
      'Möchten Sie diese Zeichnung wirklich löschen?';

  @override
  String get drawingDeleted => 'Zeichnung gelöscht';

  @override
  String yourDrawingsCount(int count) {
    return 'Ihre Zeichnungen ($count)';
  }

  @override
  String get shared => 'Geteilt';

  @override
  String get line => 'Linie';

  @override
  String get rectangle => 'Rechteck';

  @override
  String get updateAvailable => 'Update Verfügbar';

  @override
  String get currentVersion => 'Aktuell';

  @override
  String get latestVersion => 'Neueste';

  @override
  String get downloadUpdate => 'Herunterladen';

  @override
  String get updateLater => 'Später';

  @override
  String get cadastralParcels => 'Katasterparzellen';

  @override
  String get forestRoads => 'Waldwege';

  @override
  String get wmsOverlays => 'WMS Überlagerungen';

  @override
  String get hikingTrails => 'Wanderwege';

  @override
  String get mainRoads => 'Hauptstraßen';

  @override
  String get houseNumbers => 'Hausnummern';

  @override
  String get fireHazardZones => 'Brandgefährdungszonen';

  @override
  String get historicalFires => 'Historische Brände';

  @override
  String get firebreaks => 'Brandschneisen';

  @override
  String get krasFireZones => 'Kras-Brandzonen';

  @override
  String get placeNames => 'Ortsnamen';

  @override
  String get municipalityBorders => 'Gemeindegrenzen';

  @override
  String get topographicMap => 'Topographische Karte 1:25000';

  @override
  String get recentMessages => 'Aktuelle Nachrichten';

  @override
  String get addChannel => 'Kanal hinzufügen';

  @override
  String get channelName => 'Kanalname';

  @override
  String get channelNameHint => 'z.B. Rettungsteam Alpha';

  @override
  String get channelSecret => 'Kanal-Passwort';

  @override
  String get channelSecretHint => 'Gemeinsames Passwort für diesen Kanal';

  @override
  String get channelSecretHelp =>
      'Dieses Passwort muss mit allen Teammitgliedern geteilt werden, die Zugriff auf diesen Kanal benötigen';

  @override
  String get channelTypesInfo =>
      'Hash-Kanäle (#team): Passwort automatisch aus dem Namen generiert. Gleicher Name = gleicher Kanal auf allen Geräten.\n\nPrivate Kanäle: Verwenden Sie ein explizites Passwort. Nur diejenigen mit dem Passwort können beitreten.';

  @override
  String get hashChannelInfo =>
      'Hash-Kanal: Das Passwort wird automatisch aus dem Kanalnamen generiert. Jeder, der denselben Namen verwendet, wird demselben Kanal beitreten.';

  @override
  String get channelNameRequired => 'Kanalname ist erforderlich';

  @override
  String get channelNameTooLong =>
      'Kanalname darf maximal 31 Zeichen lang sein';

  @override
  String get channelSecretRequired => 'Kanal-Passwort ist erforderlich';

  @override
  String get channelSecretTooLong =>
      'Kanal-Passwort darf maximal 32 Zeichen lang sein';

  @override
  String get invalidAsciiCharacters => 'Nur ASCII-Zeichen sind erlaubt';

  @override
  String get channelCreatedSuccessfully => 'Kanal erfolgreich erstellt';

  @override
  String channelCreationFailed(String error) {
    return 'Kanal konnte nicht erstellt werden: $error';
  }

  @override
  String get deleteChannel => 'Kanal löschen';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Sind Sie sicher, dass Sie den Kanal \"$channelName\" löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get channelDeletedSuccessfully => 'Kanal erfolgreich gelöscht';

  @override
  String channelDeletionFailed(String error) {
    return 'Kanal konnte nicht gelöscht werden: $error';
  }

  @override
  String get createChannel => 'Kanal erstellen';

  @override
  String get wizardBack => 'Zurück';

  @override
  String get wizardSkip => 'Überspringen';

  @override
  String get wizardNext => 'Weiter';

  @override
  String get wizardGetStarted => 'Loslegen';

  @override
  String get wizardWelcomeTitle => 'Willkommen bei MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'Ein leistungsstarkes Offline-Kommunikationstool für Such- und Rettungseinsätze. Verbinden Sie sich mit Ihrem Team über Mesh-Funktechnologie, wenn herkömmliche Netzwerke nicht verfügbar sind.';

  @override
  String get wizardConnectingTitle => 'Verbindung zum Radio';

  @override
  String get wizardConnectingDescription =>
      'Verbinden Sie Ihr Smartphone über Bluetooth mit einem MeshCore-Funkgerät, um offline zu kommunizieren.';

  @override
  String get wizardConnectingFeature1 =>
      'Nach MeshCore-Geräten in der Nähe suchen';

  @override
  String get wizardConnectingFeature2 =>
      'Mit Ihrem Funkgerät über Bluetooth koppeln';

  @override
  String get wizardConnectingFeature3 =>
      'Funktioniert vollständig offline - kein Internet erforderlich';

  @override
  String get wizardChannelTitle => 'Kanäle';

  @override
  String get wizardChannelDescription =>
      'Senden Sie Nachrichten an alle auf einem Kanal, perfekt für teamweite Ankündigungen und Koordination.';

  @override
  String get wizardChannelFeature1 =>
      'Öffentlicher Kanal für allgemeine Teamkommunikation';

  @override
  String get wizardChannelFeature2 =>
      'Erstellen Sie benutzerdefinierte Kanäle für bestimmte Gruppen';

  @override
  String get wizardChannelFeature3 =>
      'Nachrichten werden automatisch über das Mesh weitergeleitet';

  @override
  String get wizardContactsTitle => 'Kontakte';

  @override
  String get wizardContactsDescription =>
      'Ihre Teammitglieder erscheinen automatisch, wenn sie dem Mesh-Netzwerk beitreten. Senden Sie ihnen direkte Nachrichten oder sehen Sie ihren Standort.';

  @override
  String get wizardContactsFeature1 => 'Kontakte werden automatisch erkannt';

  @override
  String get wizardContactsFeature2 => 'Private Direktnachrichten senden';

  @override
  String get wizardContactsFeature3 =>
      'Batteriestand und letzte Aktivität anzeigen';

  @override
  String get wizardMapTitle => 'Karte & Standort';

  @override
  String get wizardMapDescription =>
      'Verfolgen Sie Ihr Team in Echtzeit und markieren Sie wichtige Standorte für Such- und Rettungseinsätze.';

  @override
  String get wizardMapFeature1 =>
      'SAR-Markierungen für gefundene Personen, Feuer und Sammelstellen';

  @override
  String get wizardMapFeature2 =>
      'GPS-Verfolgung von Teammitgliedern in Echtzeit';

  @override
  String get wizardMapFeature3 =>
      'Offline-Karten für entlegene Gebiete herunterladen';

  @override
  String get wizardMapFeature4 =>
      'Formen zeichnen und taktische Informationen teilen';

  @override
  String get viewWelcomeTutorial => 'Willkommens-Tutorial ansehen';

  @override
  String get allTeamContacts => 'Alle Team-Kontakte';

  @override
  String directMessagesInfo(int count) {
    return 'Direktnachrichten mit Bestätigungen. An $count Teammitglieder gesendet.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR-Marker an $count Kontakte gesendet';
  }

  @override
  String get noContactsAvailable => 'Keine Team-Kontakte verfügbar';

  @override
  String get reply => 'Antworten';

  @override
  String get technicalDetails => 'Technische Details';

  @override
  String get messageTechnicalDetails => 'Technische Nachrichtendetails';

  @override
  String get linkQuality => 'Verbindungsqualität';

  @override
  String get delivery => 'Zustellung';

  @override
  String get status => 'Status';

  @override
  String get expectedAckTag => 'Erwartetes ACK-Tag';

  @override
  String get roundTrip => 'Roundtrip';

  @override
  String get retryAttempt => 'Wiederholungsversuch';

  @override
  String get floodFallback => 'Flood-Fallback';

  @override
  String get identity => 'Identität';

  @override
  String get messageId => 'Nachrichten-ID';

  @override
  String get sender => 'Absender';

  @override
  String get senderKey => 'Absenderschlüssel';

  @override
  String get recipient => 'Empfänger';

  @override
  String get recipientKey => 'Empfängerschlüssel';

  @override
  String get voice => 'Sprachnachricht';

  @override
  String get voiceId => 'Sprach-ID';

  @override
  String get envelope => 'Umschlag';

  @override
  String get sessionProgress => 'Sitzungsfortschritt';

  @override
  String get complete => 'Vollständig';

  @override
  String get rawDump => 'Rohdaten';

  @override
  String get cannotRetryMissingRecipient =>
      'Wiederholung nicht möglich: Empfängerinformationen fehlen';

  @override
  String get voiceUnavailable => 'Sprachnachricht momentan nicht verfügbar';

  @override
  String get requestingVoice => 'Sprachnachricht wird angefordert';

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
