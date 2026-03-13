import 'package:latlong2/latlong.dart';

import '../services/mesh_map_nodes_service.dart';

class ResolvedTraceNode {
  final List<MeshMapNode> candidates;
  final int matchCount;
  final bool usedOnlineFallback;
  final int selectedIndex;

  const ResolvedTraceNode({
    required this.candidates,
    required this.matchCount,
    required this.usedOnlineFallback,
    this.selectedIndex = 0,
  });

  MeshMapNode? get node =>
      candidates.isEmpty ? null : candidates[selectedIndex];
  bool get hasMatch => node != null;
  bool get isAmbiguous => matchCount > 1;
  bool get canCycle => candidates.length > 1;

  String? get matchSummary {
    if (matchCount <= 1) return null;
    final source = usedOnlineFallback ? 'online' : 'local';
    return '$matchCount $source matches';
  }

  String? get cycleSummary =>
      canCycle ? 'tap to cycle ${selectedIndex + 1}/$matchCount' : null;

  ResolvedTraceNode cycle() {
    if (!canCycle) return this;
    return ResolvedTraceNode(
      candidates: candidates,
      matchCount: matchCount,
      usedOnlineFallback: usedOnlineFallback,
      selectedIndex: (selectedIndex + 1) % candidates.length,
    );
  }
}

class TraceNodeResolver {
  static const Distance _distance = Distance();

  const TraceNodeResolver._();

  static ResolvedTraceNode resolveBest({
    required List<MeshMapNode> nodes,
    required Set<String> localPublicKeys,
    required String? prefixHex,
    LatLng? referenceA,
    LatLng? referenceB,
    String? preferredPrefix,
  }) {
    if (prefixHex == null || prefixHex.isEmpty) {
      return const ResolvedTraceNode(
        candidates: <MeshMapNode>[],
        matchCount: 0,
        usedOnlineFallback: false,
      );
    }

    final allMatches = nodes
        .where((n) => n.publicKey.startsWith(prefixHex))
        .toList();
    if (allMatches.isEmpty) {
      return const ResolvedTraceNode(
        candidates: <MeshMapNode>[],
        matchCount: 0,
        usedOnlineFallback: false,
      );
    }

    final localMatches = allMatches
        .where((node) => localPublicKeys.contains(node.publicKey))
        .toList();
    var pool = localMatches.isNotEmpty ? localMatches : allMatches;
    final usedOnlineFallback = localMatches.isEmpty;

    if (preferredPrefix != null && preferredPrefix.isNotEmpty) {
      final preferredMatches = pool
          .where((node) => node.publicKey.startsWith(preferredPrefix))
          .toList();
      if (preferredMatches.isNotEmpty) {
        pool = preferredMatches;
      }
    }

    pool.sort((a, b) {
      final distanceCompare =
          _scoreNode(
            a,
            referenceA: referenceA,
            referenceB: referenceB,
          ).compareTo(
            _scoreNode(b, referenceA: referenceA, referenceB: referenceB),
          );
      if (distanceCompare != 0) return distanceCompare;
      return b.updatedAtMs.compareTo(a.updatedAtMs);
    });

    return ResolvedTraceNode(
      candidates: List<MeshMapNode>.unmodifiable(pool),
      matchCount: pool.length,
      usedOnlineFallback: usedOnlineFallback,
    );
  }

  static List<ResolvedTraceNode> alignPathSelections({
    required List<ResolvedTraceNode> nodes,
    MeshMapNode? startNode,
    MeshMapNode? endNode,
  }) {
    if (nodes.isEmpty || nodes.any((node) => node.candidates.isEmpty)) {
      return nodes;
    }

    final candidateCosts = List.generate(
      nodes.length,
      (_) => <double>[],
      growable: false,
    );
    final previousChoice = List.generate(
      nodes.length,
      (_) => <int>[],
      growable: false,
    );

    for (var i = 0; i < nodes.length; i++) {
      final currentCandidates = nodes[i].candidates;
      candidateCosts[i] = List<double>.filled(
        currentCandidates.length,
        double.infinity,
      );
      previousChoice[i] = List<int>.filled(currentCandidates.length, -1);

      for (var j = 0; j < currentCandidates.length; j++) {
        final current = currentCandidates[j];
        if (i == 0) {
          candidateCosts[i][j] = startNode == null
              ? 0
              : _distanceBetweenNodes(startNode, current);
          continue;
        }

        final previousCandidates = nodes[i - 1].candidates;
        for (var k = 0; k < previousCandidates.length; k++) {
          final candidateCost =
              candidateCosts[i - 1][k] +
              _distanceBetweenNodes(previousCandidates[k], current);
          if (candidateCost < candidateCosts[i][j]) {
            candidateCosts[i][j] = candidateCost;
            previousChoice[i][j] = k;
          }
        }
      }
    }

    var bestLastIndex = 0;
    var bestLastCost = double.infinity;
    final lastCandidates = nodes.last.candidates;
    for (var i = 0; i < lastCandidates.length; i++) {
      final endCost = endNode == null
          ? 0
          : _distanceBetweenNodes(lastCandidates[i], endNode);
      final totalCost = candidateCosts.last[i] + endCost;
      if (totalCost < bestLastCost) {
        bestLastCost = totalCost;
        bestLastIndex = i;
      }
    }

    final selectedIndices = List<int>.filled(nodes.length, 0);
    selectedIndices[nodes.length - 1] = bestLastIndex;
    for (var i = nodes.length - 1; i > 0; i--) {
      selectedIndices[i - 1] = previousChoice[i][selectedIndices[i]];
    }

    return List<ResolvedTraceNode>.generate(nodes.length, (index) {
      final resolved = nodes[index];
      return ResolvedTraceNode(
        candidates: resolved.candidates,
        matchCount: resolved.matchCount,
        usedOnlineFallback: resolved.usedOnlineFallback,
        selectedIndex: selectedIndices[index],
      );
    }, growable: false);
  }

  static double _scoreNode(
    MeshMapNode node, {
    LatLng? referenceA,
    LatLng? referenceB,
  }) {
    final point = LatLng(node.latitude, node.longitude);
    if (referenceA != null && referenceB != null) {
      return _distanceToSegmentMeters(point, referenceA, referenceB);
    }
    if (referenceA != null) {
      return _distance.as(LengthUnit.Meter, point, referenceA);
    }
    if (referenceB != null) {
      return _distance.as(LengthUnit.Meter, point, referenceB);
    }
    return double.maxFinite;
  }

  static double _distanceBetweenNodes(MeshMapNode a, MeshMapNode b) {
    return _distance.as(
      LengthUnit.Meter,
      LatLng(a.latitude, a.longitude),
      LatLng(b.latitude, b.longitude),
    );
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
