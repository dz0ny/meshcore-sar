import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import '../models/path_selection.dart';

class _ManualPathSelectionRecord {
  final List<int> pathBytes;
  final int hopCount;
  final int hashSize;

  const _ManualPathSelectionRecord({
    required this.pathBytes,
    required this.hopCount,
    required this.hashSize,
  });

  factory _ManualPathSelectionRecord.fromJson(Map<String, dynamic> json) {
    final pathBytes = (json['pathBytes'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<int>()
        .toList();
    return _ManualPathSelectionRecord(
      pathBytes: pathBytes,
      hopCount: json['hopCount'] as int? ?? 0,
      hashSize: json['hashSize'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'pathBytes': pathBytes,
    'hopCount': hopCount,
    'hashSize': hashSize,
  };

  PathSelection toSelection() => PathSelection(
    mode: PathSelectionMode.directCurrent,
    pathBytes: Uint8List.fromList(pathBytes),
    hopCount: hopCount,
    hashSize: hashSize,
  );
}

class PathHistoryService {
  static const String _legacyStorageKey = 'contact_path_history_v2';
  static const String _manualRouteStorageKey =
      'contact_manual_path_overrides_v1';

  final Map<String, _ManualPathSelectionRecord> _manualSelections = {};
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyStorageKey);

    final manualRaw = prefs.getString(_manualRouteStorageKey);
    try {
      if (manualRaw != null && manualRaw.isNotEmpty) {
        final decoded = jsonDecode(manualRaw);
        if (decoded is Map<String, dynamic>) {
          for (final entry in decoded.entries) {
            final value = entry.value;
            if (value is Map<String, dynamic>) {
              _manualSelections[entry.key] =
                  _ManualPathSelectionRecord.fromJson(value);
            }
          }
        }
      }
    } catch (error) {
      debugPrint(
        '⚠️ [PathHistoryService] Failed to load manual routes: $error',
      );
    }

    _isLoaded = true;
  }

  Future<PathSelection> getSelectionForContact(Contact contact) async {
    await initialize();
    final manualSelection = _manualSelections[contact.publicKeyHex];
    if (manualSelection != null) {
      return manualSelection.toSelection();
    }

    final route = ContactRouteCodec.fromContact(contact);
    if (route == null) {
      return PathSelection.flood();
    }

    return PathSelection(
      mode: PathSelectionMode.directCurrent,
      pathBytes: Uint8List.fromList(route.pathBytes),
      hopCount: route.hopCount,
      hashSize: route.hashSize,
    );
  }

  Future<void> setManualRouteForContact(
    Contact contact,
    ParsedContactRoute route,
  ) async {
    await setManualSelectionFor(
      contact.publicKeyHex,
      PathSelection(
        mode: PathSelectionMode.directCurrent,
        pathBytes: Uint8List.fromList(route.pathBytes),
        hopCount: route.hopCount,
        hashSize: route.hashSize,
      ),
    );
  }

  Future<void> setManualSelectionFor(
    String contactPublicKeyHex,
    PathSelection selection,
  ) async {
    await initialize();
    _manualSelections[contactPublicKeyHex] = _ManualPathSelectionRecord(
      pathBytes: selection.pathBytes.toList(),
      hopCount: selection.hopCount,
      hashSize: selection.hashSize,
    );
    await _persistManualSelections();
  }

  Future<PathSelection?> getManualSelectionForContact(Contact contact) async {
    await initialize();
    return _manualSelections[contact.publicKeyHex]?.toSelection();
  }

  Future<void> clearManualRouteFor(String contactPublicKeyHex) async {
    await initialize();
    _manualSelections.remove(contactPublicKeyHex);
    await _persistManualSelections();
  }

  Future<void> _persistManualSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final manualPayload = <String, dynamic>{};
    for (final entry in _manualSelections.entries) {
      manualPayload[entry.key] = entry.value.toJson();
    }
    await prefs.setString(_manualRouteStorageKey, jsonEncode(manualPayload));
  }
}
