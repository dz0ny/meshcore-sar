import 'dart:typed_data';

import '../models/contact.dart';

class DecodedLogRxRoute {
  final int payloadType;
  final List<int> pathHashes;

  const DecodedLogRxRoute({
    required this.payloadType,
    required this.pathHashes,
  });

  int? get originalSenderHash => pathHashes.isEmpty ? null : pathHashes.first;
}

class ResolvedNodeHash {
  final int hash;
  final String label;
  final bool isOwnNode;
  final bool isUniqueMatch;
  final int matchCount;

  const ResolvedNodeHash({
    required this.hash,
    required this.label,
    required this.isOwnNode,
    required this.isUniqueMatch,
    required this.matchCount,
  });

  String get hexLabel => '0x${hash.toRadixString(16).padLeft(2, '0')}';
}

class LogRxRouteDecoder {
  const LogRxRouteDecoder._();

  static DecodedLogRxRoute? decode(Uint8List rawData) {
    if (rawData.length < 5 || rawData[0] != 0x88) return null;

    final rawPacketData = rawData.sublist(3);
    if (rawPacketData.length < 2) return null;

    final header = rawPacketData[0];
    final routeType = header & 0x03;
    final payloadType = (header >> 2) & 0x0F;

    var index = 1;
    if (routeType == 0x00 || routeType == 0x03) {
      if (rawPacketData.length < index + 5) return null;
      index += 4;
    }

    if (rawPacketData.length <= index) return null;
    final pathLen = rawPacketData[index++];
    if (rawPacketData.length < index + pathLen) return null;

    return DecodedLogRxRoute(
      payloadType: payloadType,
      pathHashes: rawPacketData.sublist(index, index + pathLen),
    );
  }

  static ResolvedNodeHash resolveHash(
    int hash, {
    required Iterable<Contact> contacts,
    Uint8List? ownPublicKey,
    String? ownName,
  }) {
    final ownHash = ownPublicKey != null && ownPublicKey.isNotEmpty
        ? ownPublicKey.first
        : null;
    if (ownHash == hash) {
      final ownLabel = (ownName != null && ownName.trim().isNotEmpty)
          ? '$ownName (you)'
          : 'You';
      return ResolvedNodeHash(
        hash: hash,
        label: ownLabel,
        isOwnNode: true,
        isUniqueMatch: true,
        matchCount: 1,
      );
    }

    final matches = contacts.where((contact) {
      return contact.publicKey.isNotEmpty && contact.publicKey.first == hash;
    }).toList();

    if (matches.isEmpty) {
      return ResolvedNodeHash(
        hash: hash,
        label: 'Unknown',
        isOwnNode: false,
        isUniqueMatch: false,
        matchCount: 0,
      );
    }

    if (matches.length == 1) {
      return ResolvedNodeHash(
        hash: hash,
        label: matches.first.displayName,
        isOwnNode: false,
        isUniqueMatch: true,
        matchCount: 1,
      );
    }

    final candidateNames = matches
        .map((contact) => contact.displayName)
        .where((name) => name.trim().isNotEmpty)
        .take(2)
        .join(', ');
    final extraCount = matches.length - 2;
    final label = candidateNames.isEmpty
        ? '${matches.length} contacts'
        : extraCount > 0
        ? '$candidateNames +$extraCount'
        : candidateNames;
    return ResolvedNodeHash(
      hash: hash,
      label: label,
      isOwnNode: false,
      isUniqueMatch: false,
      matchCount: matches.length,
    );
  }
}
