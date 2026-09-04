import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/contact.dart';

class ResolvedContactRoutePlan {
  final List<String> tokens;
  final List<Contact> selectedContacts;
  final String summary;

  const ResolvedContactRoutePlan({
    required this.tokens,
    required this.selectedContacts,
    required this.summary,
  });

  String get canonicalText => tokens.join(',');
}

class ContactRouteResolver {
  static const Distance _distance = Distance();

  const ContactRouteResolver._();

  static ResolvedContactRoutePlan? resolveAutomaticRoute({
    required LatLng senderLocation,
    required Contact recipient,
    required List<Contact> availableContacts,
    required int hashSize,
  }) {
    final recipientLocation = recipient.displayLocation;
    if (recipientLocation == null) return null;

    final repeaters = availableContacts
        .where(
          (contact) =>
              contact.isRepeater &&
              contact.displayLocation != null &&
              contact.publicKeyHex != recipient.publicKeyHex,
        )
        .toList();
    if (repeaters.isEmpty) return null;

    final recipientLatLng = LatLng(
      recipientLocation.latitude,
      recipientLocation.longitude,
    );

    final routedCandidates =
        repeaters
            .where(
              (contact) =>
                  contact.routeHasPath && contact.routeHashSize == hashSize,
            )
            .toList()
          ..sort(
            (a, b) =>
                _scoreKnownRouteRepeater(
                  senderLocation: senderLocation,
                  recipientLocation: recipientLatLng,
                  repeater: a,
                  availableContacts: repeaters,
                  hashSize: hashSize,
                ).compareTo(
                  _scoreKnownRouteRepeater(
                    senderLocation: senderLocation,
                    recipientLocation: recipientLatLng,
                    repeater: b,
                    availableContacts: repeaters,
                    hashSize: hashSize,
                  ),
                ),
          );

    if (routedCandidates.isNotEmpty) {
      final anchor = routedCandidates.first;
      final tokens = <String>[
        ...anchor.routeCanonicalText
            .split(',')
            .where((token) => token.isNotEmpty)
            .map((token) => token.toUpperCase()),
        _tokenFor(anchor, hashSize),
      ];
      final selectedContacts = _matchContactsForTokens(
        tokens,
        availableContacts: repeaters,
      );
      return ResolvedContactRoutePlan(
        tokens: _dedupeTokens(tokens),
        selectedContacts: selectedContacts,
        summary: 'Resolved via known repeater route',
      );
    }

    final corridorRepeaters = List<Contact>.from(repeaters)
      ..sort((a, b) {
        final progressA = _progressAlongSegment(
          point: LatLng(
            a.displayLocation!.latitude,
            a.displayLocation!.longitude,
          ),
          start: senderLocation,
          end: recipientLatLng,
        );
        final progressB = _progressAlongSegment(
          point: LatLng(
            b.displayLocation!.latitude,
            b.displayLocation!.longitude,
          ),
          start: senderLocation,
          end: recipientLatLng,
        );
        final progressCompare = progressA.compareTo(progressB);
        if (progressCompare != 0) return progressCompare;
        return _scoreRepeater(
          senderLocation: senderLocation,
          recipientLocation: recipientLatLng,
          repeater: a,
        ).compareTo(
          _scoreRepeater(
            senderLocation: senderLocation,
            recipientLocation: recipientLatLng,
            repeater: b,
          ),
        );
      });

    final selected = <Contact>[];
    var currentPoint = senderLocation;
    var currentDistanceToRecipient = _distance.as(
      LengthUnit.Meter,
      senderLocation,
      recipientLatLng,
    );
    final maxCorridorDistance = math.max(
      1500.0,
      currentDistanceToRecipient * 0.22,
    );

    for (final repeater in corridorRepeaters) {
      if (selected.length >= 4) break;
      final repeaterPoint = LatLng(
        repeater.displayLocation!.latitude,
        repeater.displayLocation!.longitude,
      );
      final distanceToSegment = _distanceToSegmentMeters(
        repeaterPoint,
        senderLocation,
        recipientLatLng,
      );
      if (distanceToSegment > maxCorridorDistance) {
        continue;
      }

      final nextDistanceToRecipient = _distance.as(
        LengthUnit.Meter,
        repeaterPoint,
        recipientLatLng,
      );
      if (nextDistanceToRecipient >= currentDistanceToRecipient - 300) {
        continue;
      }

      final distanceFromCurrent = _distance.as(
        LengthUnit.Meter,
        currentPoint,
        repeaterPoint,
      );
      if (distanceFromCurrent < 100) {
        continue;
      }

      selected.add(repeater);
      currentPoint = repeaterPoint;
      currentDistanceToRecipient = nextDistanceToRecipient;

      if (currentDistanceToRecipient < 2500) {
        break;
      }
    }

    if (selected.isEmpty) {
      return null;
    }

    return ResolvedContactRoutePlan(
      tokens: selected.map((contact) => _tokenFor(contact, hashSize)).toList(),
      selectedContacts: selected,
      summary: 'Resolved from repeater locations',
    );
  }

  static List<Contact> _matchContactsForTokens(
    List<String> tokens, {
    required List<Contact> availableContacts,
  }) {
    final matches = <Contact>[];
    final seen = <String>{};
    for (final token in tokens) {
      final match = availableContacts
          .where(
            (contact) => contact.publicKeyHex.toUpperCase().startsWith(token),
          )
          .firstOrNull;
      if (match != null && seen.add(match.publicKeyHex)) {
        matches.add(match);
      }
    }
    return matches;
  }

  static List<String> _dedupeTokens(List<String> tokens) {
    final result = <String>[];
    for (final token in tokens) {
      if (result.isEmpty || result.last != token) {
        result.add(token);
      }
    }
    return result;
  }

  static String _tokenFor(Contact contact, int hashSize) {
    final hex = contact.publicKeyHex.toUpperCase();
    final length = hashSize * 2;
    return hex.length < length ? hex : hex.substring(0, length);
  }

  static double _scoreRepeater({
    required LatLng senderLocation,
    required LatLng recipientLocation,
    required Contact repeater,
  }) {
    final point = LatLng(
      repeater.displayLocation!.latitude,
      repeater.displayLocation!.longitude,
    );
    final toRecipient = _distance.as(
      LengthUnit.Meter,
      point,
      recipientLocation,
    );
    final corridor = _distanceToSegmentMeters(
      point,
      senderLocation,
      recipientLocation,
    );
    return (toRecipient * 0.75) + (corridor * 0.25);
  }

  static double _scoreKnownRouteRepeater({
    required LatLng senderLocation,
    required LatLng recipientLocation,
    required Contact repeater,
    required List<Contact> availableContacts,
    required int hashSize,
  }) {
    final baseScore = _scoreRepeater(
      senderLocation: senderLocation,
      recipientLocation: recipientLocation,
      repeater: repeater,
    );
    final repeaterPoint = LatLng(
      repeater.displayLocation!.latitude,
      repeater.displayLocation!.longitude,
    );

    final chainContacts = repeater.routeCanonicalText
        .split(',')
        .where((token) => token.isNotEmpty)
        .map(
          (token) => availableContacts
              .where(
                (contact) =>
                    contact.displayLocation != null &&
                    contact.publicKeyHex.toUpperCase().startsWith(
                      token.toUpperCase(),
                    ),
              )
              .firstOrNull,
        )
        .whereType<Contact>()
        .toList();

    final chainEnd = chainContacts.isNotEmpty
        ? LatLng(
            chainContacts.last.displayLocation!.latitude,
            chainContacts.last.displayLocation!.longitude,
          )
        : senderLocation;
    final chainGap = _distance.as(LengthUnit.Meter, chainEnd, repeaterPoint);
    final senderGap = _distance.as(
      LengthUnit.Meter,
      senderLocation,
      repeaterPoint,
    );

    return (chainGap * 0.55) + (baseScore * 0.35) + (senderGap * 0.10);
  }

  static double _progressAlongSegment({
    required LatLng point,
    required LatLng start,
    required LatLng end,
  }) {
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    final lengthSquared = (dx * dx) + (dy * dy);
    if (lengthSquared == 0) return 0;
    return (((point.longitude - start.longitude) * dx) +
            ((point.latitude - start.latitude) * dy)) /
        lengthSquared;
  }

  static double _distanceToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final ax = a.longitude;
    final ay = a.latitude;
    final bx = b.longitude;
    final by = b.latitude;
    final px = p.longitude;
    final py = p.latitude;

    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;
    final ab2 = abx * abx + aby * aby;
    if (ab2 == 0) {
      return _distance.as(LengthUnit.Meter, a, p);
    }
    var t = (apx * abx + apy * aby) / ab2;
    t = t.clamp(0.0, 1.0);
    final closest = LatLng(ay + aby * t, ax + abx * t);
    return _distance.as(LengthUnit.Meter, closest, p);
  }
}
