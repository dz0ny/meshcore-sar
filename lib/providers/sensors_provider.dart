import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact.dart';
import 'connection_provider.dart';
import 'contacts_provider.dart';

enum SensorRefreshState { idle, refreshing, success, timeout, unavailable }

class SensorsProvider with ChangeNotifier {
  static const String _watchedSensorsKey = 'watched_sensor_keys';
  static const String _visibleSensorMetricsKey = 'visible_sensor_metrics';
  static const String _fieldSpanKey = 'sensor_field_spans';
  static const Set<String> _defaultVisibleFields = <String>{
    'voltage',
    'battery',
    'temperature',
    'humidity',
    'pressure',
    'gps',
  };

  final List<String> _watchedSensorKeys = <String>[];
  final Map<String, SensorRefreshState> _refreshStates =
      <String, SensorRefreshState>{};
  final Map<String, Set<String>> _visibleFieldsBySensor =
      <String, Set<String>>{};
  final Map<String, Map<String, int>> _fieldSpansBySensor =
      <String, Map<String, int>>{};
  bool _isLoaded = false;
  bool _isRefreshingAll = false;

  SensorsProvider() {
    unawaited(_loadWatchedSensors());
  }

  List<String> get watchedSensorKeys => List.unmodifiable(_watchedSensorKeys);
  bool get isLoaded => _isLoaded;
  bool get isRefreshingAll => _isRefreshingAll;

  SensorRefreshState stateFor(String publicKeyHex) =>
      _refreshStates[publicKeyHex] ?? SensorRefreshState.idle;

  Future<void> _loadWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_watchedSensorsKey) ?? <String>[];
      final storedMetricsJson = prefs.getString(_visibleSensorMetricsKey);
      final storedSpansJson = prefs.getString(_fieldSpanKey);
      _watchedSensorKeys
        ..clear()
        ..addAll(stored);
      _visibleFieldsBySensor.clear();
      _fieldSpansBySensor.clear();
      if (storedMetricsJson != null && storedMetricsJson.isNotEmpty) {
        final decoded = jsonDecode(storedMetricsJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _visibleFieldsBySensor[entry.key] = (entry.value as List<dynamic>)
              .cast<String>()
              .toSet();
        }
      }
      if (storedSpansJson != null && storedSpansJson.isNotEmpty) {
        final decoded = jsonDecode(storedSpansJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          _fieldSpansBySensor[entry.key] = (entry.value as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, value as int));
        }
      }
      for (final key in _watchedSensorKeys) {
        _visibleFieldsBySensor.putIfAbsent(
          key,
          () => Set<String>.from(_defaultVisibleFields),
        );
        _fieldSpansBySensor.putIfAbsent(key, () => <String, int>{});
      }
    } catch (e) {
      debugPrint('Error loading watched sensors: $e');
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> _persistWatchedSensors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_watchedSensorsKey, _watchedSensorKeys);
    } catch (e) {
      debugPrint('Error saving watched sensors: $e');
    }
  }

  Future<void> _persistVisibleMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = <String, List<String>>{};
      for (final entry in _visibleFieldsBySensor.entries) {
        encoded[entry.key] = entry.value.toList();
      }
      await prefs.setString(_visibleSensorMetricsKey, jsonEncode(encoded));
    } catch (e) {
      debugPrint('Error saving visible sensor metrics: $e');
    }
  }

  Future<void> _persistFieldSpans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fieldSpanKey, jsonEncode(_fieldSpansBySensor));
    } catch (e) {
      debugPrint('Error saving sensor field spans: $e');
    }
  }

  Set<String> visibleFieldsFor(String publicKeyHex) => Set<String>.unmodifiable(
    _visibleFieldsBySensor[publicKeyHex] ?? _defaultVisibleFields,
  );

  bool showsField(String publicKeyHex, String fieldKey) =>
      visibleFieldsFor(publicKeyHex).contains(fieldKey);

  int fieldSpanFor(String publicKeyHex, String fieldKey) {
    final sensorSpans = _fieldSpansBySensor[publicKeyHex];
    final span = sensorSpans?[fieldKey] ?? 1;
    return span == 2 ? 2 : 1;
  }

  Future<void> toggleMetric(
    String publicKeyHex,
    String fieldKey,
    bool visible,
  ) async {
    final visibleFields = _visibleFieldsBySensor.putIfAbsent(
      publicKeyHex,
      () => Set<String>.from(_defaultVisibleFields),
    );
    if (visible) {
      visibleFields.add(fieldKey);
    } else {
      if (visibleFields.length == 1 && visibleFields.contains(fieldKey)) {
        return;
      }
      visibleFields.remove(fieldKey);
    }
    await _persistVisibleMetrics();
    notifyListeners();
  }

  Future<void> setFieldSpan(
    String publicKeyHex,
    String fieldKey,
    int span,
  ) async {
    final sensorSpans = _fieldSpansBySensor.putIfAbsent(
      publicKeyHex,
      () => <String, int>{},
    );
    sensorSpans[fieldKey] = span == 2 ? 2 : 1;
    await _persistFieldSpans();
    notifyListeners();
  }

  bool isWatched(String publicKeyHex) =>
      _watchedSensorKeys.contains(publicKeyHex);

  Future<void> addSensor(Contact contact) async {
    if (!contact.isChat && !contact.isRepeater) {
      return;
    }
    if (_watchedSensorKeys.contains(contact.publicKeyHex)) {
      return;
    }

    _watchedSensorKeys.add(contact.publicKeyHex);
    await _persistWatchedSensors();
    _visibleFieldsBySensor[contact.publicKeyHex] = Set<String>.from(
      _defaultVisibleFields,
    );
    _fieldSpansBySensor[contact.publicKeyHex] = <String, int>{'gps': 2};
    await _persistVisibleMetrics();
    await _persistFieldSpans();
    notifyListeners();
  }

  Future<void> removeSensor(String publicKeyHex) async {
    _watchedSensorKeys.remove(publicKeyHex);
    _refreshStates.remove(publicKeyHex);
    _visibleFieldsBySensor.remove(publicKeyHex);
    _fieldSpansBySensor.remove(publicKeyHex);
    await _persistWatchedSensors();
    await _persistVisibleMetrics();
    await _persistFieldSpans();
    notifyListeners();
  }

  List<Contact> availableCandidates(ContactsProvider contactsProvider) {
    final candidates = <Contact>[
      ...contactsProvider.chatContacts,
      ...contactsProvider.repeaters,
    ];
    candidates.removeWhere((contact) => isWatched(contact.publicKeyHex));
    candidates.sort((a, b) => b.lastSeenTime.compareTo(a.lastSeenTime));
    return candidates;
  }

  Future<void> refreshAll({
    required ContactsProvider contactsProvider,
    required ConnectionProvider connectionProvider,
  }) async {
    if (_isRefreshingAll || _watchedSensorKeys.isEmpty) {
      return;
    }

    _isRefreshingAll = true;
    notifyListeners();

    try {
      for (final key in _watchedSensorKeys) {
        Contact? contact;
        for (final entry in contactsProvider.contacts) {
          if (entry.publicKeyHex == key) {
            contact = entry;
            break;
          }
        }
        if (contact == null) {
          _refreshStates[key] = SensorRefreshState.unavailable;
          notifyListeners();
          continue;
        }

        _refreshStates[key] = SensorRefreshState.refreshing;
        notifyListeners();

        final result = await connectionProvider.smartPing(
          contactPublicKey: contact.publicKey,
          hasPath: contact.hasPath,
        );

        _refreshStates[key] = result.success
            ? SensorRefreshState.success
            : SensorRefreshState.timeout;
        notifyListeners();
      }
    } finally {
      _isRefreshingAll = false;
      notifyListeners();
    }
  }
}
