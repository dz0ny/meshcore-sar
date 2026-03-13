import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshcore_sar_app/services/mesh_map_nodes_service.dart';
import 'package:meshcore_sar_app/utils/trace_node_resolver.dart';

void main() {
  test(
    'prefers closest local repeater over online fallback for shared prefix',
    () {
      final localNear = _node(
        name: 'Near Local',
        publicKey: 'aa1100',
        latitude: 46.05,
        longitude: 14.50,
      );
      final localFar = _node(
        name: 'Far Local',
        publicKey: 'aa2200',
        latitude: 46.40,
        longitude: 14.90,
      );
      final online = _node(
        name: 'Online',
        publicKey: 'aa3300',
        latitude: 46.06,
        longitude: 14.51,
      );

      final resolved = TraceNodeResolver.resolveBest(
        nodes: [localNear, localFar, online],
        localPublicKeys: {localNear.publicKey, localFar.publicKey},
        prefixHex: 'aa',
        referenceA: const LatLng(46.0, 14.5),
        referenceB: const LatLng(46.1, 14.5),
      );

      expect(resolved.node?.name, 'Near Local');
      expect(resolved.usedOnlineFallback, isFalse);
      expect(resolved.matchCount, 2);
      expect(resolved.matchSummary, '2 local matches');
    },
  );

  test('falls back to online node only when local match is missing', () {
    final online = _node(
      name: 'Online Only',
      publicKey: 'bb1100',
      latitude: 46.06,
      longitude: 14.51,
    );

    final resolved = TraceNodeResolver.resolveBest(
      nodes: [online],
      localPublicKeys: const {},
      prefixHex: 'bb',
      referenceA: const LatLng(46.0, 14.5),
      referenceB: const LatLng(46.1, 14.5),
    );

    expect(resolved.node?.name, 'Online Only');
    expect(resolved.usedOnlineFallback, isTrue);
    expect(resolved.matchCount, 1);
  });

  test('cycles through ambiguous local prefix matches', () {
    final first = _node(
      name: 'First Match',
      publicKey: 'cc1100',
      latitude: 46.08,
      longitude: 14.52,
    );
    final second = _node(
      name: 'Second Match',
      publicKey: 'cc11ff',
      latitude: 46.09,
      longitude: 14.53,
    );

    final resolved = TraceNodeResolver.resolveBest(
      nodes: [second, first],
      localPublicKeys: {first.publicKey, second.publicKey},
      prefixHex: 'cc11',
    );

    expect(resolved.matchCount, 2);
    expect(resolved.canCycle, isTrue);
    expect(resolved.node?.name, 'Second Match');
    expect(resolved.cycle().node?.name, 'First Match');
    expect(resolved.cycle().cycle().node?.name, 'Second Match');
  });

  test('aligns ambiguous hops to the closest continuous path', () {
    final start = _node(
      name: 'Start',
      publicKey: 'start00',
      latitude: 46.000,
      longitude: 14.000,
    );
    final end = _node(
      name: 'End',
      publicKey: 'end000',
      latitude: 46.300,
      longitude: 14.300,
    );
    final hop1Near = _node(
      name: 'Hop 1 Near',
      publicKey: 'aa1100',
      latitude: 46.100,
      longitude: 14.100,
    );
    final hop1Far = _node(
      name: 'Hop 1 Far',
      publicKey: 'aa11ff',
      latitude: 46.250,
      longitude: 14.000,
    );
    final hop2Near = _node(
      name: 'Hop 2 Near',
      publicKey: 'bb2200',
      latitude: 46.200,
      longitude: 14.200,
    );
    final hop2Far = _node(
      name: 'Hop 2 Far',
      publicKey: 'bb22ff',
      latitude: 46.050,
      longitude: 14.280,
    );

    final aligned = TraceNodeResolver.alignPathSelections(
      nodes: [
        TraceNodeResolver.resolveBest(
          nodes: [hop1Far, hop1Near],
          localPublicKeys: {hop1Near.publicKey, hop1Far.publicKey},
          prefixHex: 'aa11',
        ),
        TraceNodeResolver.resolveBest(
          nodes: [hop2Far, hop2Near],
          localPublicKeys: {hop2Near.publicKey, hop2Far.publicKey},
          prefixHex: 'bb22',
        ),
      ],
      startNode: start,
      endNode: end,
    );

    expect(aligned[0].node?.name, 'Hop 1 Near');
    expect(aligned[1].node?.name, 'Hop 2 Near');
  });
}

MeshMapNode _node({
  required String name,
  required String publicKey,
  required double latitude,
  required double longitude,
}) {
  return MeshMapNode(
    type: 1,
    name: name,
    publicKey: publicKey,
    latitude: latitude,
    longitude: longitude,
    updatedAtMs: 1,
  );
}
