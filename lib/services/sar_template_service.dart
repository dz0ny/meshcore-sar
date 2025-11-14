import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sar_template.dart';
import '../utils/sar_message_parser.dart';

/// SAR Template Service - Manages SAR templates with persistence
class SarTemplateService extends ChangeNotifier {
  static final SarTemplateService _instance = SarTemplateService._internal();
  factory SarTemplateService() => _instance;
  SarTemplateService._internal();

  static const String _storageKey = 'sar_templates';
  List<SarTemplate> _templates = [];
  bool _initialized = false;

  /// Get all templates
  List<SarTemplate> get templates => List.unmodifiable(_templates);

  /// Get default templates
  List<SarTemplate> get defaultTemplates =>
      _templates.where((t) => t.isDefault).toList();

  /// Get custom templates
  List<SarTemplate> get customTemplates =>
      _templates.where((t) => !t.isDefault).toList();

  /// Check if initialized
  bool get isInitialized => _initialized;

  /// Initialize service and load templates
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        // Load saved templates
        final List<dynamic> jsonList = json.decode(jsonString);
        _templates = jsonList.map((json) => SarTemplate.fromJson(json)).toList();

        // Ensure defaults exist (in case user deleted them or version upgrade)
        _ensureDefaultTemplates();
      } else {
        // First time - initialize with defaults
        _templates = SarTemplate.defaults;
        await _saveToStorage();
      }

      _initialized = true;
      notifyListeners();
      debugPrint('SarTemplateService initialized with ${_templates.length} templates');
    } catch (e) {
      debugPrint('Error initializing SAR templates: $e');
      // Fallback to defaults on error
      _templates = SarTemplate.defaults;
      _initialized = true;
      notifyListeners();
    }
  }

  /// Ensure default templates exist
  void _ensureDefaultTemplates() {
    final defaults = SarTemplate.defaults;
    final existingDefaultIds = _templates.where((t) => t.isDefault).map((t) => t.id).toSet();

    // Add missing defaults
    for (final defaultTemplate in defaults) {
      if (!existingDefaultIds.contains(defaultTemplate.id)) {
        _templates.insert(0, defaultTemplate);
      }
    }
  }

  /// Save templates to storage
  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _templates.map((t) => t.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await prefs.setString(_storageKey, jsonString);
      debugPrint('Saved ${_templates.length} SAR templates to storage');
    } catch (e) {
      debugPrint('Error saving SAR templates: $e');
      rethrow;
    }
  }

  /// Add new template
  Future<void> addTemplate(SarTemplate template) async {
    _templates.add(template);
    await _saveToStorage();
    notifyListeners();
    debugPrint('Added SAR template: ${template.name}');
  }

  /// Update existing template
  Future<void> updateTemplate(String id, SarTemplate updatedTemplate) async {
    final index = _templates.indexWhere((t) => t.id == id);
    if (index != -1) {
      _templates[index] = updatedTemplate;
      await _saveToStorage();
      notifyListeners();
      debugPrint('Updated SAR template: ${updatedTemplate.name}');
    } else {
      throw Exception('Template with id $id not found');
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String id) async {
    final template = _templates.firstWhere((t) => t.id == id);
    _templates.removeWhere((t) => t.id == id);
    await _saveToStorage();
    notifyListeners();
    debugPrint('Deleted SAR template: ${template.name}');
  }

  /// Get template by ID
  SarTemplate? getTemplateById(String id) {
    try {
      return _templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Import templates from clipboard
  /// Expects SAR message format (one per line):
  /// S:🧑:0,0:Person found
  /// S:🔥:0,0:Active fire
  Future<int> importFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData == null || clipboardData.text == null || clipboardData.text!.trim().isEmpty) {
        throw Exception('Clipboard is empty');
      }

      return importFromText(clipboardData.text!);
    } catch (e) {
      debugPrint('Error importing from clipboard: $e');
      rethrow;
    }
  }

  /// Import templates from text (SAR message format)
  Future<int> importFromText(String text) async {
    try {
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      int importedCount = 0;
      final List<String> errors = [];

      for (final line in lines) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('S:')) {
          errors.add('Invalid format: $trimmed');
          continue;
        }

        // Validate with parser
        if (!SarMessageParser.isValidFormat(trimmed)) {
          final error = SarMessageParser.getFormatError(trimmed);
          errors.add(error ?? 'Invalid SAR message format');
          continue;
        }

        try {
          final template = SarTemplate.fromSarMessage(trimmed);

          // Check for duplicates (same emoji + name)
          final isDuplicate = _templates.any((t) =>
            t.emoji == template.emoji && t.name == template.name
          );

          if (!isDuplicate) {
            _templates.add(template);
            importedCount++;
          }
        } catch (e) {
          errors.add('Error parsing line: $trimmed - $e');
        }
      }

      if (importedCount > 0) {
        await _saveToStorage();
        notifyListeners();
      }

      if (errors.isNotEmpty) {
        debugPrint('Import errors: ${errors.join(', ')}');
      }

      debugPrint('Imported $importedCount SAR templates');
      return importedCount;
    } catch (e) {
      debugPrint('Error importing templates: $e');
      rethrow;
    }
  }

  /// Export all templates to clipboard (SAR message format)
  Future<void> exportToClipboard() async {
    try {
      final sarMessages = _templates.map((t) => t.toSarMessage()).join('\n');
      await Clipboard.setData(ClipboardData(text: sarMessages));
      debugPrint('Exported ${_templates.length} templates to clipboard');
    } catch (e) {
      debugPrint('Error exporting to clipboard: $e');
      rethrow;
    }
  }

  /// Export templates to text (SAR message format)
  String exportToText() {
    return _templates.map((t) => t.toSarMessage()).join('\n');
  }

  /// Reset to default templates
  Future<void> resetToDefaults() async {
    _templates = SarTemplate.defaults;
    await _saveToStorage();
    notifyListeners();
    debugPrint('Reset to default SAR templates');
  }

  /// Clear all templates (including defaults)
  Future<void> clearAll() async {
    _templates.clear();
    await _saveToStorage();
    notifyListeners();
    debugPrint('Cleared all SAR templates');
  }

  /// Get count of templates
  int get templateCount => _templates.length;

  /// Check if template exists
  bool hasTemplate(String id) {
    return _templates.any((t) => t.id == id);
  }
}
