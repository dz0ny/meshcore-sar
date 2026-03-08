// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MeshCore SAR';

  @override
  String get messages => 'Mensagens';

  @override
  String get contacts => 'Contatos';

  @override
  String get map => 'Mapa';

  @override
  String get settings => 'Configurações';

  @override
  String get connect => 'Conectar';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get noDevicesFound => 'Nenhum dispositivo encontrado';

  @override
  String get scanAgain => 'Escanear novamente';

  @override
  String get tapToConnect => 'Toque para conectar';

  @override
  String get deviceNotConnected => 'Dispositivo não conectado';

  @override
  String get locationPermissionDenied => 'Permissão de localização negada';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Permissão de localização negada permanentemente. Ative-a em Configurações.';

  @override
  String get locationPermissionRequired =>
      'A permissão de localização é necessária para rastreamento GPS e coordenação da equipe. Você pode ativá-la depois em Configurações.';

  @override
  String get locationServicesDisabled =>
      'Os serviços de localização estão desativados. Ative-os em Configurações.';

  @override
  String get failedToGetGpsLocation => 'Falha ao obter localização GPS';

  @override
  String failedToAdvertise(String error) {
    return 'Falha ao anunciar: $error';
  }

  @override
  String get cancelReconnection => 'Cancelar reconexão';

  @override
  String get general => 'Geral';

  @override
  String get theme => 'Tema';

  @override
  String get chooseTheme => 'Escolher tema';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Escuro';

  @override
  String get blueLightTheme => 'Tema azul claro';

  @override
  String get blueDarkTheme => 'Tema azul escuro';

  @override
  String get sarRed => 'SAR Vermelho';

  @override
  String get alertEmergencyMode => 'Modo de alerta/emergência';

  @override
  String get sarGreen => 'SAR Verde';

  @override
  String get safeAllClearMode => 'Modo seguro/tudo limpo';

  @override
  String get autoSystem => 'Automático (Sistema)';

  @override
  String get followSystemTheme => 'Seguir tema do sistema';

  @override
  String get showRxTxIndicators => 'Mostrar indicadores RX/TX';

  @override
  String get displayPacketActivity =>
      'Exibir indicadores de atividade de pacotes na barra superior';

  @override
  String get disableMap => 'Desativar mapa';

  @override
  String get disableMapDescription =>
      'Ocultar a aba de mapa para reduzir o uso de bateria';

  @override
  String get language => 'Idioma';

  @override
  String get chooseLanguage => 'Escolher idioma';

  @override
  String get save => 'Salvar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Fechar';

  @override
  String get about => 'Sobre';

  @override
  String get appVersion => 'Versão do app';

  @override
  String get appName => 'Nome do app';

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
  String get moreInfo => 'Mais informações';

  @override
  String get packageName => 'Package Name';

  @override
  String get sampleData => 'Dados de exemplo';

  @override
  String get sampleDataDescription =>
      'Carregar ou limpar contatos, mensagens de canal e marcadores SAR de exemplo para testes';

  @override
  String get loadSampleData => 'Carregar dados de exemplo';

  @override
  String get clearAllData => 'Limpar todos os dados';

  @override
  String get clearAllDataConfirmTitle => 'Limpar todos os dados';

  @override
  String get clearAllDataConfirmMessage =>
      'Isso limpará todos os contatos e marcadores SAR. Tem certeza?';

  @override
  String get clear => 'Limpar';

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
    return 'Falha ao carregar dados de exemplo: $error';
  }

  @override
  String get allDataCleared => 'Todos os dados foram limpos';

  @override
  String get failedToStartBackgroundTracking =>
      'Falha ao iniciar rastreamento em segundo plano. Verifique permissões e conexão BLE.';

  @override
  String locationBroadcast(String latitude, String longitude) {
    return 'Transmissão de localização: $latitude, $longitude';
  }

  @override
  String get defaultPinInfo =>
      'The default pin for devices without a screen is 123456. Trouble pairing? Forget the bluetooth device in system settings.';

  @override
  String get noMessagesYet => 'Ainda não há mensagens';

  @override
  String get pullDownToSync => 'Puxe para baixo para sincronizar mensagens';

  @override
  String get deleteContact => 'Excluir contato';

  @override
  String get delete => 'Excluir';

  @override
  String get viewOnMap => 'Ver no mapa';

  @override
  String get refresh => 'Atualizar';

  @override
  String get resetPath => 'Redefinir rota';

  @override
  String get publicKeyCopied =>
      'Chave pública copiada para a área de transferência';

  @override
  String copiedToClipboard(String label) {
    return '$label copiado para a área de transferência';
  }

  @override
  String get pleaseEnterPassword => 'Digite uma senha';

  @override
  String failedToSyncContacts(String error) {
    return 'Falha ao sincronizar contatos: $error';
  }

  @override
  String get loggedInSuccessfully =>
      'Login realizado com sucesso! Aguardando mensagens da sala...';

  @override
  String get loginFailed => 'Falha no login - senha incorreta';

  @override
  String loggingIn(String roomName) {
    return 'Entrando em $roomName...';
  }

  @override
  String failedToSendLogin(String error) {
    return 'Falha ao enviar login: $error';
  }

  @override
  String get lowLocationAccuracy => 'Baixa precisão de localização';

  @override
  String get continue_ => 'Continuar';

  @override
  String get sendSarMarker => 'Enviar marcador SAR';

  @override
  String get deleteDrawing => 'Excluir desenho';

  @override
  String get drawingTools => 'Ferramentas de desenho';

  @override
  String get drawLine => 'Desenhar linha';

  @override
  String get drawLineDesc => 'Desenhar uma linha livre no mapa';

  @override
  String get drawRectangle => 'Desenhar retângulo';

  @override
  String get drawRectangleDesc => 'Desenhar uma área retangular no mapa';

  @override
  String get measureDistance => 'Medir distância';

  @override
  String get measureDistanceDesc =>
      'Pressione longamente dois pontos para medir';

  @override
  String get clearMeasurement => 'Limpar medição';

  @override
  String distanceLabel(String distance) {
    return 'Distância: $distance';
  }

  @override
  String get longPressForSecondPoint =>
      'Pressione longamente para o segundo ponto';

  @override
  String get longPressToStartMeasurement =>
      'Pressione longamente para definir o primeiro ponto';

  @override
  String get longPressToStartNewMeasurement =>
      'Long press to start new measurement';

  @override
  String get shareDrawings => 'Compartilhar desenhos';

  @override
  String get clearAllDrawings => 'Limpar todos os desenhos';

  @override
  String get completeLine => 'Concluir linha';

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
  String get drawing => 'Desenho';

  @override
  String shareDrawingsCount(int count, String plural) {
    return 'Share $count Drawing$plural';
  }

  @override
  String get showReceivedDrawings => 'Mostrar desenhos recebidos';

  @override
  String get showingAllDrawings => 'Mostrando todos os desenhos';

  @override
  String get showingOnlyYourDrawings => 'Mostrando apenas seus desenhos';

  @override
  String get showSarMarkers => 'Mostrar marcadores SAR';

  @override
  String get showingSarMarkers => 'Mostrando marcadores SAR';

  @override
  String get hidingSarMarkers => 'Ocultando marcadores SAR';

  @override
  String get clearAll => 'Limpar tudo';

  @override
  String get publicChannel => 'Canal público';

  @override
  String get broadcastToAll => 'Transmitir para todos os nós próximos';

  @override
  String get storedPermanently => 'Armazenado permanentemente na sala';

  @override
  String get notConnectedToDevice => 'Não conectado ao dispositivo';

  @override
  String get typeYourMessage => 'Digite sua mensagem...';

  @override
  String get quickLocationMarker => 'Marcador rápido de localização';

  @override
  String get markerType => 'Tipo de marcador';

  @override
  String get sendTo => 'Enviar para';

  @override
  String get noDestinationsAvailable => 'Nenhum destino disponível.';

  @override
  String get selectDestination => 'Selecione o destino...';

  @override
  String get ephemeralBroadcastInfo =>
      'Ephemeral: Broadcast over-the-air only. Not stored - nodes must be online.';

  @override
  String get persistentRoomInfo =>
      'Persistent: Stored immutably in room. Synced automatically and preserved offline.';

  @override
  String get location => 'Localização';

  @override
  String get fromMap => 'Do mapa';

  @override
  String get gettingLocation => 'Obtendo localização...';

  @override
  String get locationError => 'Erro de localização';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get refreshLocation => 'Atualizar localização';

  @override
  String accuracyMeters(int accuracy) {
    return 'Precisão: ±${accuracy}m';
  }

  @override
  String get notesOptional => 'Notas (opcional)';

  @override
  String get addAdditionalInformation => 'Adicionar informações extras...';

  @override
  String lowAccuracyWarning(int accuracy) {
    return 'Location accuracy is ±${accuracy}m. This may not be accurate enough for SAR operations.\n\nContinue anyway?';
  }

  @override
  String get loginToRoom => 'Entrar na sala';

  @override
  String get enterPasswordInfo =>
      'Enter the password to access this room. The password will be saved for future use.';

  @override
  String get password => 'Senha';

  @override
  String get enterRoomPassword => 'Digite a senha da sala';

  @override
  String get loggingInDots => 'Entrando...';

  @override
  String get login => 'Entrar';

  @override
  String failedToAddRoom(String error) {
    return 'Failed to add room to device: $error\n\nThe room may not have advertised yet.\nTry waiting for the room to broadcast.';
  }

  @override
  String get direct => 'Direto';

  @override
  String get flood => 'Inundação';

  @override
  String get loggedIn => 'Conectado';

  @override
  String get noGpsData => 'Sem dados GPS';

  @override
  String get distance => 'Distância';

  @override
  String directPingTimeout(String name) {
    return 'Direct ping timeout - retrying $name with flooding...';
  }

  @override
  String pingFailed(String name) {
    return 'Falha no ping para $name - nenhuma resposta recebida';
  }

  @override
  String deleteContactConfirmation(String name) {
    return 'Are you sure you want to delete \"$name\"?\n\nThis will remove the contact from both the app and the companion radio device.';
  }

  @override
  String failedToRemoveContact(String error) {
    return 'Falha ao remover contato: $error';
  }

  @override
  String get type => 'Tipo';

  @override
  String get publicKey => 'Chave pública';

  @override
  String get lastSeen => 'Visto por último';

  @override
  String get roomStatus => 'Status da sala';

  @override
  String get loginStatus => 'Status do login';

  @override
  String get notLoggedIn => 'Não conectado';

  @override
  String get adminAccess => 'Acesso de administrador';

  @override
  String get yes => 'Sim';

  @override
  String get no => 'Não';

  @override
  String get permissions => 'Permissões';

  @override
  String get passwordSaved => 'Senha salva';

  @override
  String get locationColon => 'Localização:';

  @override
  String get telemetry => 'Telemetria';

  @override
  String get voltage => 'Voltagem';

  @override
  String get battery => 'Bateria';

  @override
  String get temperature => 'Temperatura';

  @override
  String get humidity => 'Umidade';

  @override
  String get pressure => 'Pressão';

  @override
  String get gpsTelemetry => 'GPS (telemetria)';

  @override
  String get updated => 'Atualizado';

  @override
  String pathResetInfo(String name) {
    return 'Path reset for $name. Next message will find a new route.';
  }

  @override
  String get reLoginToRoom => 'Entrar novamente na sala';

  @override
  String get heading => 'Direção';

  @override
  String get elevation => 'Elevação';

  @override
  String get accuracy => 'Precisão';

  @override
  String get bearing => 'Rumo';

  @override
  String get direction => 'Direção';

  @override
  String get filterMarkers => 'Filtrar marcadores';

  @override
  String get filterMarkersTooltip => 'Filter markers';

  @override
  String get contactsFilter => 'Contatos';

  @override
  String get repeatersFilter => 'Repetidores';

  @override
  String get sarMarkers => 'Marcadores SAR';

  @override
  String get foundPerson => 'Pessoa encontrada';

  @override
  String get fire => 'Incêndio';

  @override
  String get stagingArea => 'Área de apoio';

  @override
  String get showAll => 'Mostrar tudo';

  @override
  String get locationUnavailable => 'Localização indisponível';

  @override
  String get ahead => 'à frente';

  @override
  String degreesRight(int degrees) {
    return '$degrees° à direita';
  }

  @override
  String degreesLeft(int degrees) {
    return '$degrees° à esquerda';
  }

  @override
  String latLonFormat(String latitude, String longitude) {
    return 'Lat: $latitude Lon: $longitude';
  }

  @override
  String get noContactsYet => 'Ainda não há contatos';

  @override
  String get connectToDeviceToLoadContacts =>
      'Conecte-se a um dispositivo para carregar contatos';

  @override
  String get teamMembers => 'Membros da equipe';

  @override
  String get repeaters => 'Repetidores';

  @override
  String get rooms => 'Salas';

  @override
  String get channels => 'Canais';

  @override
  String get selectMapLayer => 'Selecionar camada do mapa';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get openTopoMap => 'OpenTopoMap';

  @override
  String get esriSatellite => 'Satélite ESRI';

  @override
  String get googleHybrid => 'Google Híbrido';

  @override
  String get googleRoadmap => 'Google Mapa';

  @override
  String get googleTerrain => 'Google Terreno';

  @override
  String get dragToPosition => 'Arraste para a posição';

  @override
  String get createSarMarker => 'Criar marcador SAR';

  @override
  String get compass => 'Bússola';

  @override
  String get navigationAndContacts => 'Navegação e contatos';

  @override
  String get sarAlert => 'ALERTA SAR';

  @override
  String get textCopiedToClipboard =>
      'Texto copiado para a área de transferência';

  @override
  String get cannotReplySenderMissing =>
      'Cannot reply: sender information missing';

  @override
  String get cannotReplyContactNotFound => 'Cannot reply: contact not found';

  @override
  String get copyText => 'Copiar texto';

  @override
  String get saveAsTemplate => 'Save as Template';

  @override
  String get templateSaved => 'Template saved successfully';

  @override
  String get templateAlreadyExists => 'Template with this emoji already exists';

  @override
  String get deleteMessage => 'Excluir mensagem';

  @override
  String get deleteMessageConfirmation =>
      'Tem certeza de que deseja excluir esta mensagem?';

  @override
  String get shareLocation => 'Compartilhar localização';

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
  String get sarLocationShare => 'Localização SAR';

  @override
  String get justNow => 'Agora mesmo';

  @override
  String minutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String hoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String daysAgo(int days) {
    return 'há $days d';
  }

  @override
  String secondsAgo(int seconds) {
    return 'há $seconds s';
  }

  @override
  String get sending => 'Enviando...';

  @override
  String get sent => 'Enviado';

  @override
  String get delivered => 'Entregue';

  @override
  String deliveredWithTime(int time) {
    return 'Entregue (${time}ms)';
  }

  @override
  String get failed => 'Falhou';

  @override
  String get broadcast => 'Transmitir';

  @override
  String deliveredToContacts(int delivered, int total) {
    return 'Delivered to $delivered/$total contacts';
  }

  @override
  String get allDelivered => 'All delivered';

  @override
  String get recipientDetails => 'Recipient Details';

  @override
  String get pending => 'Pendente';

  @override
  String get sarMarkerFoundPerson => 'Found Person';

  @override
  String get sarMarkerFire => 'Fire Location';

  @override
  String get sarMarkerStagingArea => 'Staging Area';

  @override
  String get sarMarkerObject => 'Object Found';

  @override
  String get from => 'De';

  @override
  String get coordinates => 'Coordenadas';

  @override
  String get tapToViewOnMap => 'Toque para ver no mapa';

  @override
  String get radioSettings => 'Configurações do rádio';

  @override
  String get frequencyMHz => 'Frequência (MHz)';

  @override
  String get frequencyExample => 'e.g., 869.618';

  @override
  String get bandwidth => 'Largura de banda';

  @override
  String get spreadingFactor => 'Fator de espalhamento';

  @override
  String get codingRate => 'Taxa de codificação';

  @override
  String get txPowerDbm => 'Potência TX (dBm)';

  @override
  String maxPowerDbm(int power) {
    return 'Máx: $power dBm';
  }

  @override
  String get you => 'Você';

  @override
  String exportFailed(String error) {
    return 'Falha na exportação: $error';
  }

  @override
  String importFailed(String error) {
    return 'Falha na importação: $error';
  }

  @override
  String get unknown => 'Desconhecido';

  @override
  String get onlineLayers => 'Camadas online';

  @override
  String get locationTrail => 'Trilha de localização';

  @override
  String get showTrailOnMap => 'Mostrar trilha no mapa';

  @override
  String get trailVisible => 'A trilha está visível no mapa';

  @override
  String get trailHiddenRecording => 'A trilha está oculta (ainda gravando)';

  @override
  String get duration => 'Duração';

  @override
  String get points => 'Pontos';

  @override
  String get clearTrail => 'Limpar trilha';

  @override
  String get clearTrailQuestion => 'Limpar trilha?';

  @override
  String get clearTrailConfirmation =>
      'Tem certeza de que deseja limpar a trilha de localização atual?';

  @override
  String get noTrailRecorded => 'Nenhuma trilha gravada ainda';

  @override
  String get startTrackingToRecord =>
      'Inicie o rastreamento de localização para gravar sua trilha';

  @override
  String get trailControls => 'Controles da trilha';

  @override
  String get contactTrails => 'Trilhas dos contatos';

  @override
  String get showAllContactTrails => 'Mostrar todas as trilhas dos contatos';

  @override
  String get noContactsWithLocationHistory =>
      'Nenhum contato com histórico de localização';

  @override
  String showingTrailsForContacts(int count) {
    return 'Showing trails for $count contacts';
  }

  @override
  String get individualContactTrails => 'Trilhas individuais dos contatos';

  @override
  String get deviceInformation => 'Informações do dispositivo';

  @override
  String get bleName => 'Nome BLE';

  @override
  String get meshName => 'Nome da mesh';

  @override
  String get notSet => 'Não definido';

  @override
  String get model => 'Modelo';

  @override
  String get version => 'Versão';

  @override
  String get buildDate => 'Data de build';

  @override
  String get firmware => 'Firmware';

  @override
  String get maxContacts => 'Máx. de contatos';

  @override
  String get maxChannels => 'Máx. de canais';

  @override
  String get publicInfo => 'Informações públicas';

  @override
  String get meshNetworkName => 'Nome da rede mesh';

  @override
  String get nameBroadcastInMesh => 'Nome transmitido nos anúncios mesh';

  @override
  String get telemetryAndLocationSharing =>
      'Telemetria e compartilhamento de localização';

  @override
  String get lat => 'Lat';

  @override
  String get lon => 'Lon';

  @override
  String get useCurrentLocation => 'Usar localização atual';

  @override
  String get noneUnknown => 'Nenhum/Desconhecido';

  @override
  String get chatNode => 'Nó de chat';

  @override
  String get repeater => 'Repetidor';

  @override
  String get roomChannel => 'Sala/Canal';

  @override
  String typeNumber(int number) {
    return 'Type $number';
  }

  @override
  String copiedToClipboardShort(String label) {
    return '$label copiado para a área de transferência';
  }

  @override
  String failedToSave(String error) {
    return 'Falha ao salvar: $error';
  }

  @override
  String failedToGetLocation(String error) {
    return 'Falha ao obter localização: $error';
  }

  @override
  String get sarTemplates => 'Modelos SAR';

  @override
  String get manageSarTemplates => 'Manage cursor on target templates';

  @override
  String get addTemplate => 'Adicionar modelo';

  @override
  String get editTemplate => 'Editar modelo';

  @override
  String get deleteTemplate => 'Excluir modelo';

  @override
  String get templateName => 'Nome do modelo';

  @override
  String get templateNameHint => 'ex.: Pessoa encontrada';

  @override
  String get templateEmoji => 'Emoji';

  @override
  String get emojiRequired => 'Emoji é obrigatório';

  @override
  String get nameRequired => 'Nome é obrigatório';

  @override
  String get templateDescription => 'Descrição (opcional)';

  @override
  String get templateDescriptionHint => 'Adicionar contexto extra...';

  @override
  String get templateColor => 'Cor';

  @override
  String get previewFormat => 'Pré-visualização (formato de mensagem SAR)';

  @override
  String get importFromClipboard => 'Importar';

  @override
  String get exportToClipboard => 'Exportar';

  @override
  String deleteTemplateConfirmation(String name) {
    return 'Excluir o modelo “$name”?';
  }

  @override
  String get templateAdded => 'Modelo adicionado';

  @override
  String get templateUpdated => 'Modelo atualizado';

  @override
  String get templateDeleted => 'Modelo excluído';

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
  String get resetToDefaults => 'Restaurar padrão';

  @override
  String get resetToDefaultsConfirmation =>
      'Isso excluirá todos os modelos personalizados e restaurará os 4 modelos padrão. Continuar?';

  @override
  String get reset => 'Redefinir';

  @override
  String get resetComplete => 'Modelos redefinidos para o padrão';

  @override
  String get noTemplates => 'Nenhum modelo disponível';

  @override
  String get tapAddToCreate => 'Toque em + para criar seu primeiro modelo';

  @override
  String get ok => 'OK';

  @override
  String get permissionsSection => 'Permissões';

  @override
  String get locationPermission => 'Permissão de localização';

  @override
  String get checking => 'Verificando...';

  @override
  String get locationPermissionGrantedAlways => 'Concedida (Sempre)';

  @override
  String get locationPermissionGrantedWhileInUse => 'Concedida (Durante o uso)';

  @override
  String get locationPermissionDeniedTapToRequest =>
      'Negada - toque para solicitar';

  @override
  String get locationPermissionPermanentlyDeniedOpenSettings =>
      'Negada permanentemente - abrir configurações';

  @override
  String get locationPermissionDialogContent =>
      'A permissão de localização foi negada permanentemente. Ative-a nas configurações do dispositivo.';

  @override
  String get openSettings => 'Abrir configurações';

  @override
  String get locationPermissionGranted => 'Permissão de localização concedida!';

  @override
  String get locationPermissionRequiredForGps =>
      'A permissão de localização é necessária para rastreamento GPS e compartilhamento de localização.';

  @override
  String get locationPermissionAlreadyGranted =>
      'A permissão de localização já foi concedida.';

  @override
  String get sarNavyBlue => 'SAR Azul Marinho';

  @override
  String get sarNavyBlueDescription => 'Modo profissional/operações';

  @override
  String get selectRecipient => 'Selecionar destinatário';

  @override
  String get broadcastToAllNearby => 'Transmitir para todos os próximos';

  @override
  String get searchRecipients => 'Pesquisar destinatários...';

  @override
  String get noContactsFound => 'Nenhum contato encontrado';

  @override
  String get noRoomsFound => 'Nenhuma sala encontrada';

  @override
  String get noRecipientsAvailable => 'Nenhum destinatário disponível';

  @override
  String get noChannelsFound => 'Nenhum canal encontrado';

  @override
  String get newMessage => 'Nova mensagem';

  @override
  String get channel => 'Canal';

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
  String get channelEmergency => 'Emergência';

  @override
  String get channelCoordination => 'Coordenação';

  @override
  String get channelUpdates => 'Atualizações';

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
  String get mapDrawing => 'Desenho do mapa';

  @override
  String get navigateToDrawing => 'Navigate to Drawing';

  @override
  String get copyCoordinates => 'Copiar coordenadas';

  @override
  String get hideFromMap => 'Ocultar do mapa';

  @override
  String get lineDrawing => 'Desenho de linha';

  @override
  String get rectangleDrawing => 'Desenho de retângulo';

  @override
  String get manualCoordinates => 'Coordenadas manuais';

  @override
  String get enterCoordinatesManually => 'Inserir coordenadas manualmente';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get exampleCoordinates => 'Example: 46.0569, 14.5058';

  @override
  String get shareDrawing => 'Compartilhar desenho';

  @override
  String get shareWithAllNearbyDevices =>
      'Compartilhar com todos os dispositivos próximos';

  @override
  String get shareToRoom => 'Compartilhar na sala';

  @override
  String get sendToPersistentStorage =>
      'Enviar para armazenamento persistente da sala';

  @override
  String get deleteDrawingConfirm =>
      'Tem certeza de que deseja excluir este desenho?';

  @override
  String get drawingDeleted => 'Desenho excluído';

  @override
  String yourDrawingsCount(int count) {
    return 'Your Drawings ($count)';
  }

  @override
  String get shared => 'Compartilhado';

  @override
  String get line => 'Linha';

  @override
  String get rectangle => 'Retângulo';

  @override
  String get updateAvailable => 'Atualização disponível';

  @override
  String get currentVersion => 'Atual';

  @override
  String get latestVersion => 'Mais recente';

  @override
  String get downloadUpdate => 'Baixar';

  @override
  String get updateLater => 'Mais tarde';

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
  String get recentMessages => 'Mensagens recentes';

  @override
  String get addChannel => 'Adicionar canal';

  @override
  String get channelName => 'Nome do canal';

  @override
  String get channelNameHint => 'ex.: Equipe de Resgate Alfa';

  @override
  String get channelSecret => 'Segredo do canal';

  @override
  String get channelSecretHint => 'Senha compartilhada para este canal';

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
  String get channelNameRequired => 'O nome do canal é obrigatório';

  @override
  String get channelNameTooLong => 'Channel name must be 31 characters or less';

  @override
  String get channelSecretRequired => 'O segredo do canal é obrigatório';

  @override
  String get channelSecretTooLong =>
      'Channel secret must be 32 characters or less';

  @override
  String get invalidAsciiCharacters =>
      'Somente caracteres ASCII são permitidos';

  @override
  String get channelCreatedSuccessfully => 'Canal criado com sucesso';

  @override
  String channelCreationFailed(String error) {
    return 'Falha ao criar canal: $error';
  }

  @override
  String get deleteChannel => 'Excluir canal';

  @override
  String deleteChannelConfirmation(String channelName) {
    return 'Are you sure you want to delete channel \"$channelName\"? This action cannot be undone.';
  }

  @override
  String get channelDeletedSuccessfully => 'Canal excluído com sucesso';

  @override
  String channelDeletionFailed(String error) {
    return 'Falha ao excluir canal: $error';
  }

  @override
  String get createChannel => 'Criar canal';

  @override
  String get wizardBack => 'Voltar';

  @override
  String get wizardSkip => 'Pular';

  @override
  String get wizardNext => 'Próximo';

  @override
  String get wizardGetStarted => 'Começar';

  @override
  String get wizardWelcomeTitle => 'Bem-vindo ao MeshCore SAR';

  @override
  String get wizardWelcomeDescription =>
      'A powerful off-grid communication tool for search and rescue operations. Connect with your team using mesh radio technology when traditional networks are unavailable.';

  @override
  String get wizardConnectingTitle => 'Conectando ao seu rádio';

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
  String get wizardChannelTitle => 'Canais';

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
  String get wizardContactsTitle => 'Contatos';

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
  String get wizardMapTitle => 'Mapa e localização';

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
  String get viewWelcomeTutorial => 'Ver tutorial de boas-vindas';

  @override
  String get allTeamContacts => 'Todos os contatos da equipe';

  @override
  String directMessagesInfo(int count) {
    return 'Direct messages with ACKs. Sent to $count team members.';
  }

  @override
  String sarMarkerSentToContacts(int count) {
    return 'SAR marker sent to $count contacts';
  }

  @override
  String get noContactsAvailable => 'Nenhum contato da equipe disponível';

  @override
  String get reply => 'Responder';

  @override
  String get technicalDetails => 'Detalhes técnicos';

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
  String get voice => 'Voz';

  @override
  String get voiceId => 'Voice ID';

  @override
  String get envelope => 'Envelope';

  @override
  String get sessionProgress => 'Session progress';

  @override
  String get complete => 'Concluído';

  @override
  String get rawDump => 'Raw dump';

  @override
  String get cannotRetryMissingRecipient =>
      'Cannot retry: recipient information missing';

  @override
  String get voiceUnavailable => 'A voz não está disponível no momento';

  @override
  String get requestingVoice => 'Requesting voice';
}
