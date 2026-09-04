import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/message_contact_location.dart';
import '../l10n/app_localizations.dart';

/// Generates sample data for testing/demo purposes
class SampleDataGenerator {
  static final Random _random = Random();

  static MessageContactLocation _sampleSnapshot({
    required LatLng location,
    required DateTime receivedAt,
    required String source,
  }) {
    return MessageContactLocation(
      location: location,
      source: source,
      capturedAt: receivedAt,
      sourceTimestamp: receivedAt.subtract(const Duration(minutes: 2)),
    );
  }

  static LatLng _randomNearbyLocation(LatLng center, double spread) {
    final latOffset = (_random.nextDouble() - 0.5) * spread;
    final lonOffset = (_random.nextDouble() - 0.5) * spread;
    return LatLng(center.latitude + latOffset, center.longitude + lonOffset);
  }

  static SampleMessageBatch generateAllMessages({
    required LatLng centerLocation,
    required AppLocalizations l10n,
    int foundPersonCount = 2,
    int fireCount = 1,
    int stagingCount = 1,
    int objectCount = 1,
    int generalChannelMessages = 8,
    int emergencyChannelMessages = 5,
  }) {
    final sarBatch = generateSarMarkerMessages(
      centerLocation: centerLocation,
      l10n: l10n,
      foundPersonCount: foundPersonCount,
      fireCount: fireCount,
      stagingCount: stagingCount,
      objectCount: objectCount,
    );
    final channelBatch = generateChannelMessages(
      centerLocation: centerLocation,
      l10n: l10n,
      generalChannelMessages: generalChannelMessages,
      emergencyChannelMessages: emergencyChannelMessages,
    );

    return SampleMessageBatch(
      messages: [...sarBatch.messages, ...channelBatch.messages],
      contactLocations: {
        ...sarBatch.contactLocations,
        ...channelBatch.contactLocations,
      },
    );
  }

  /// Generate sample contacts around a center location
  static List<Contact> generateContacts({
    required LatLng centerLocation,
    required AppLocalizations l10n,
    int teamMemberCount = 5,
    int channelCount = 2,
  }) {
    final contacts = <Contact>[];
    final now = DateTime.now();

    final teamNames = [
      '👮${l10n.samplePoliceLead}',
      '🚁${l10n.sampleDroneOperator}',
      '🧑🏻‍🚒${l10n.sampleFirefighterAlpha}',
      '🧑‍⚕️${l10n.sampleMedicCharlie}',
      '📡${l10n.sampleCommandDelta}',
      '🚒${l10n.sampleFireEngine}',
      '👨‍✈️${l10n.sampleAirSupport}',
      '🧑‍💼${l10n.sampleBaseCoordinator}',
    ];

    final channelNames = [
      l10n.general,
      l10n.channelEmergency,
      l10n.channelCoordination,
      l10n.channelUpdates,
    ];

    // Generate team members (chat contacts)
    for (int i = 0; i < teamMemberCount && i < teamNames.length; i++) {
      // Generate location within ~1km radius
      final latOffset = (_random.nextDouble() - 0.5) * 0.02; // ~1km
      final lonOffset = (_random.nextDouble() - 0.5) * 0.02;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      // Generate random public key
      final publicKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Random battery 20-100%
      final battery = 20 + _random.nextInt(81);

      // Random temperature 15-35°C
      final temp = 15.0 + _random.nextDouble() * 20.0;

      final telemetry = ContactTelemetry(
        gpsLocation: LatLng(lat, lon),
        batteryPercentage: battery.toDouble(),
        batteryMilliVolts: 3000.0 + (battery / 100.0) * 1200.0,
        temperature: temp,
        timestamp: now.subtract(Duration(minutes: _random.nextInt(10))),
      );

      final contact = Contact(
        publicKey: publicKey,
        type: ContactType.chat,
        flags: 0,
        outPathLen: 1,
        outPath: Uint8List(32),
        advName: teamNames[i],
        lastAdvert: now.millisecondsSinceEpoch ~/ 1000,
        advLat: (lat * 1e6).toInt(),
        advLon: (lon * 1e6).toInt(),
        lastMod: now.millisecondsSinceEpoch ~/ 1000,
        telemetry: telemetry,
      );

      contacts.add(contact);
    }

    // Generate channels/rooms
    for (int i = 0; i < channelCount && i < channelNames.length; i++) {
      // Generate random public key
      final publicKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Channel index stored in outPath[0]
      final outPath = Uint8List(32);
      outPath[0] = i; // Channel index

      final channel = Contact(
        publicKey: publicKey,
        type: ContactType.room,
        flags: 0,
        outPathLen: 1,
        outPath: outPath,
        advName: channelNames[i],
        lastAdvert: now.millisecondsSinceEpoch ~/ 1000,
        advLat: 0, // Channels don't have location
        advLon: 0,
        lastMod: now.millisecondsSinceEpoch ~/ 1000,
      );

      contacts.add(channel);
    }

    return contacts;
  }

  /// Generate sample SAR markers around a center location
  static SampleMessageBatch generateSarMarkerMessages({
    required LatLng centerLocation,
    required AppLocalizations l10n,
    int foundPersonCount = 2,
    int fireCount = 1,
    int stagingCount = 1,
    int objectCount = 1,
  }) {
    final messages = <Message>[];
    final contactLocations = <String, MessageContactLocation>{};
    final now = DateTime.now();
    int messageId = 1;

    // Generate found person markers
    for (int i = 0; i < foundPersonCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 10 + i * 5));
      final message = Message(
        id: 'sample_fp_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:🧑:${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarGpsCoordinates: LatLng(lat, lon),
        sarCustomEmoji: '🧑',
        senderName: l10n.sampleTeamMember,
      );
      messages.add(message);
      contactLocations[message.id] = _sampleSnapshot(
        location: _randomNearbyLocation(message.sarGpsCoordinates!, 0.006),
        receivedAt: timestamp,
        source: 'telemetry',
      );
      messageId++;
    }

    // Generate fire markers
    for (int i = 0; i < fireCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 20 + i * 5));
      final message = Message(
        id: 'sample_fire_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:🔥:${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarGpsCoordinates: LatLng(lat, lon),
        sarCustomEmoji: '🔥',
        senderName: l10n.sampleScout,
      );
      messages.add(message);
      contactLocations[message.id] = _sampleSnapshot(
        location: _randomNearbyLocation(message.sarGpsCoordinates!, 0.008),
        receivedAt: timestamp,
        source: 'advert',
      );
      messageId++;
    }

    // Generate staging area markers
    for (int i = 0; i < stagingCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 30 + i * 5));
      final message = Message(
        id: 'sample_staging_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: 'S:🏕️:${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarGpsCoordinates: LatLng(lat, lon),
        sarCustomEmoji: '🏕️',
        senderName: l10n.sampleBase,
      );
      messages.add(message);
      contactLocations[message.id] = _sampleSnapshot(
        location: _randomNearbyLocation(message.sarGpsCoordinates!, 0.01),
        receivedAt: timestamp,
        source: 'advert',
      );
      messageId++;
    }

    // Generate object markers
    for (int i = 0; i < objectCount; i++) {
      final latOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lonOffset = (_random.nextDouble() - 0.5) * 0.015;
      final lat = centerLocation.latitude + latOffset;
      final lon = centerLocation.longitude + lonOffset;

      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      final timestamp = now.subtract(Duration(minutes: 40 + i * 5));
      final notes = [
        l10n.sampleObjectBackpack,
        l10n.sampleObjectVehicle,
        l10n.sampleObjectCamping,
        l10n.sampleObjectTrailMarker,
      ];

      final message = Message(
        id: 'sample_object_$messageId',
        messageType: MessageType.contact,
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text:
            'S:📦:${lat.toStringAsFixed(5)},${lon.toStringAsFixed(5)}${notes[i % notes.length]}',
        receivedAt: timestamp,
        isSarMarker: true,
        sarGpsCoordinates: LatLng(lat, lon),
        sarCustomEmoji: '📦',
        senderName: l10n.sampleSearcher,
      );
      messages.add(message);
      contactLocations[message.id] = _sampleSnapshot(
        location: _randomNearbyLocation(message.sarGpsCoordinates!, 0.007),
        receivedAt: timestamp,
        source: 'telemetry',
      );
      messageId++;
    }

    return SampleMessageBatch(
      messages: messages,
      contactLocations: contactLocations,
    );
  }

  /// Generate sample map drawings
  static List<dynamic> generateDrawings({
    required LatLng centerLocation,
    required AppLocalizations l10n,
  }) {
    final drawings = <dynamic>[];
    final now = DateTime.now();

    // Generate a line drawing (e.g., search path)
    final linePoints = <LatLng>[
      LatLng(centerLocation.latitude + 0.002, centerLocation.longitude - 0.003),
      LatLng(centerLocation.latitude + 0.004, centerLocation.longitude - 0.002),
      LatLng(centerLocation.latitude + 0.005, centerLocation.longitude + 0.001),
      LatLng(centerLocation.latitude + 0.003, centerLocation.longitude + 0.003),
    ];

    drawings.add({
      'type': 'line',
      'id': 'sample_line_${now.millisecondsSinceEpoch}',
      'color': Colors.blue.toARGB32(),
      'createdAt': now.subtract(const Duration(minutes: 15)).toIso8601String(),
      'points': linePoints
          .map((p) => {'lat': p.latitude, 'lon': p.longitude})
          .toList(),
      'sender': l10n.sampleTeamMember,
    });

    // Generate a rectangle drawing (e.g., search area)
    drawings.add({
      'type': 'rectangle',
      'id': 'sample_rect_${now.millisecondsSinceEpoch + 1}',
      'color': Colors.red.toARGB32(),
      'createdAt': now.subtract(const Duration(minutes: 10)).toIso8601String(),
      'topLeft': {
        'lat': centerLocation.latitude - 0.003,
        'lon': centerLocation.longitude - 0.004,
      },
      'bottomRight': {
        'lat': centerLocation.latitude - 0.001,
        'lon': centerLocation.longitude - 0.001,
      },
      'sender': l10n.sampleScout,
    });

    return drawings;
  }

  /// Generate sample channel messages for public channels
  static SampleMessageBatch generateChannelMessages({
    LatLng? centerLocation,
    required AppLocalizations l10n,
    int generalChannelMessages = 8,
    int emergencyChannelMessages = 5,
  }) {
    // Use provided location or default to Ljubljana, Slovenia
    final center = centerLocation ?? const LatLng(46.0569, 14.5058);
    final messages = <Message>[];
    final contactLocations = <String, MessageContactLocation>{};
    final now = DateTime.now();
    int messageId = 1000; // Start with high ID to avoid conflicts

    // Sample messages for General channel (index 0)
    final generalMessages = [
      l10n.sampleMsgAllTeamsCheckIn,
      l10n.sampleMsgWeatherUpdate,
      l10n.sampleMsgBaseCamp,
      l10n.sampleMsgTeamAlpha,
      l10n.sampleMsgRadioCheck,
      l10n.sampleMsgWaterSupply,
      l10n.sampleMsgTeamBravo,
      l10n.sampleMsgEtaRallyPoint,
      l10n.sampleMsgSupplyDrop,
      l10n.sampleMsgDroneSurvey,
      l10n.sampleMsgTeamCharlie,
      l10n.sampleMsgRadioDiscipline,
    ];

    // Sample messages for Emergency channel (index 1)
    // Mix regular messages and SAR markers
    final emergencyMessages = [
      l10n.sampleMsgUrgentMedical,
      'S:🧑:${center.latitude.toStringAsFixed(5)},${(center.longitude + 0.005).toStringAsFixed(5)}${l10n.sampleMsgAdultMale}',
      l10n.sampleMsgFireSpotted,
      'S:🔥:${(center.latitude + 0.008).toStringAsFixed(5)},${(center.longitude + 0.003).toStringAsFixed(5)}${l10n.sampleMsgSpreadingRapidly}',
      l10n.sampleMsgPriorityHelicopter,
      l10n.sampleMsgMedicalTeamEnRoute,
      l10n.sampleMsgEvacHelicopter,
      l10n.sampleMsgEmergencyResolved,
      'S:🏕️:${(center.latitude - 0.002).toStringAsFixed(5)},${(center.longitude - 0.004).toStringAsFixed(5)}${l10n.sampleMsgEmergencyStagingArea}',
      l10n.sampleMsgEmergencyServices,
    ];

    final teamNames = [
      l10n.sampleAlphaTeamLead,
      l10n.sampleBravoScout,
      l10n.sampleCharlieMedic,
      l10n.sampleDeltaNavigator,
      l10n.sampleEchoSupport,
      l10n.sampleBaseCommand,
      l10n.sampleFieldCoordinator,
      l10n.sampleMedicalTeam,
    ];

    // Generate General channel messages
    for (
      int i = 0;
      i < generalChannelMessages && i < generalMessages.length;
      i++
    ) {
      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Messages spread over the last 2 hours
      final minutesAgo = 120 - (i * 15) - _random.nextInt(10);
      final timestamp = now.subtract(Duration(minutes: minutesAgo));

      final message = Message(
        id: 'sample_general_$messageId',
        messageType: MessageType.channel,
        channelIdx: 0, // General channel
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: generalMessages[i],
        receivedAt: timestamp,
        senderName: teamNames[_random.nextInt(teamNames.length)],
      );
      messages.add(message);
      contactLocations[message.id] = _sampleSnapshot(
        location: _randomNearbyLocation(center, 0.018),
        receivedAt: timestamp,
        source: i.isEven ? 'telemetry' : 'advert',
      );
      messageId++;
    }

    // Generate Emergency channel messages
    for (
      int i = 0;
      i < emergencyChannelMessages && i < emergencyMessages.length;
      i++
    ) {
      final senderKey = Uint8List.fromList(
        List.generate(32, (_) => _random.nextInt(256)),
      );

      // Emergency messages more recent (last hour)
      final minutesAgo = 60 - (i * 10) - _random.nextInt(5);
      final timestamp = now.subtract(Duration(minutes: minutesAgo));

      final message = Message(
        id: 'sample_emergency_$messageId',
        messageType: MessageType.channel,
        channelIdx: 1, // Emergency channel
        senderPublicKeyPrefix: senderKey.sublist(0, 6),
        pathLen: 1,
        textType: MessageTextType.plain,
        senderTimestamp: timestamp.millisecondsSinceEpoch ~/ 1000,
        text: emergencyMessages[i],
        receivedAt: timestamp,
        senderName: teamNames[_random.nextInt(teamNames.length)],
      );
      messages.add(message);
      contactLocations[message.id] = _sampleSnapshot(
        location: _randomNearbyLocation(center, 0.012),
        receivedAt: timestamp,
        source: i.isEven ? 'advert' : 'telemetry',
      );
      messageId++;
    }

    return SampleMessageBatch(
      messages: messages,
      contactLocations: contactLocations,
    );
  }
}

class SampleMessageBatch {
  final List<Message> messages;
  final Map<String, MessageContactLocation> contactLocations;

  const SampleMessageBatch({
    required this.messages,
    required this.contactLocations,
  });
}
