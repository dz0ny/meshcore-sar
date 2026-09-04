import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshcore_sar_app/models/contact.dart';
import 'package:meshcore_sar_app/models/path_selection.dart';
import 'package:meshcore_sar_app/services/path_history_service.dart';

Contact _buildContact({
  required int seed,
  List<int> pathBytes = const [],
  int hopCount = 0,
  int hashSize = 1,
}) {
  final encoded = pathBytes.isEmpty ? -1 : ((hashSize - 1) << 6) | (hopCount & 0x3F);
  final outPath = Uint8List(ContactRouteCodec.maxPathBytes);
  if (pathBytes.isNotEmpty) {
    outPath.setRange(0, pathBytes.length, pathBytes);
  }

  return Contact(
    publicKey: Uint8List.fromList(List<int>.generate(32, (i) => i + seed)),
    type: ContactType.chat,
    flags: 0,
    outPathLen: encoded == -1 ? -1 : ContactRouteCodec.toSignedDescriptor(encoded),
    outPath: encoded == -1 ? Uint8List(0) : outPath,
    advName: 'Contact $seed',
    lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    advLat: 0,
    advLon: 0,
    lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('manual route override persists across reloads', () async {
    final contact = _buildContact(seed: 1);
    final service = PathHistoryService();
    await service.initialize();
    await service.setManualSelectionFor(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directCurrent,
        pathBytes: Uint8List.fromList([0xAA, 0xBB]),
        hopCount: 2,
        hashSize: 1,
      ),
    );

    final reloaded = PathHistoryService();
    final selection = await reloaded.getManualSelectionForContact(contact);

    expect(selection, isNotNull);
    expect(selection!.mode, PathSelectionMode.directCurrent);
    expect(selection.canonicalPath, 'AA,BB');
  });

  test('selection uses stored manual route before contact route', () async {
    final contact = _buildContact(
      seed: 2,
      pathBytes: const [0x11, 0x22],
      hopCount: 2,
      hashSize: 1,
    );
    final service = PathHistoryService();
    await service.initialize();
    await service.setManualSelectionFor(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directCurrent,
        pathBytes: Uint8List.fromList([0xAA, 0xBB]),
        hopCount: 2,
        hashSize: 1,
      ),
    );

    final selection = await service.getSelectionForContact(contact);

    expect(selection.mode, PathSelectionMode.directCurrent);
    expect(selection.canonicalPath, 'AA,BB');
  });

  test('selection falls back to the current contact route', () async {
    final contact = _buildContact(
      seed: 3,
      pathBytes: const [0x10, 0x20, 0x30],
      hopCount: 1,
      hashSize: 3,
    );
    final service = PathHistoryService();

    final selection = await service.getSelectionForContact(contact);

    expect(selection.mode, PathSelectionMode.directCurrent);
    expect(selection.canonicalPath, '102030');
    expect(selection.hashSize, 3);
    expect(selection.hopCount, 1);
  });

  test('selection falls back to flood when no route exists', () async {
    final contact = _buildContact(seed: 4);
    final service = PathHistoryService();

    final selection = await service.getSelectionForContact(contact);

    expect(selection.mode, PathSelectionMode.flood);
    expect(selection.pathBytes, isEmpty);
  });

  test('clearing manual route falls back to the contact route', () async {
    final contact = _buildContact(
      seed: 5,
      pathBytes: const [0x01, 0x02],
      hopCount: 2,
      hashSize: 1,
    );
    final service = PathHistoryService();
    await service.initialize();
    await service.setManualSelectionFor(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directCurrent,
        pathBytes: Uint8List.fromList([0xAA, 0xBB]),
        hopCount: 2,
        hashSize: 1,
      ),
    );

    await service.clearManualRouteFor(contact.publicKeyHex);
    final selection = await service.getSelectionForContact(contact);

    expect(selection.mode, PathSelectionMode.directCurrent);
    expect(selection.canonicalPath, '01,02');
  });

  test('initialize removes legacy path history storage', () async {
    final contact = Contact(
      publicKey: Uint8List.fromList([
        0xAB,
        0xC1,
        0x23,
        ...List<int>.filled(29, 0),
      ]),
      type: ContactType.chat,
      flags: 0,
      outPathLen: -1,
      outPath: Uint8List(0),
      advName: 'Legacy Contact',
      lastAdvert: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      advLat: 0,
      advLon: 0,
      lastMod: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    SharedPreferences.setMockInitialValues({
      'contact_path_history_v2': '{"abc123":{"direct_paths":[]}}',
      'contact_manual_path_overrides_v1': jsonEncode({
        contact.publicKeyHex: {
          'pathBytes': [0xAA, 0xBB],
          'hopCount': 2,
          'hashSize': 1,
        },
      }),
    });
    final service = PathHistoryService();

    await service.initialize();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('contact_path_history_v2'), isFalse);
    final selection = await service.getManualSelectionForContact(contact);
    expect(selection, isNotNull);
    expect(selection!.canonicalPath, 'AA,BB');
  });
}
