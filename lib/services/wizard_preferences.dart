import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage welcome wizard preferences and state
class WizardPreferences {
  static const String _wizardCompletedKey = 'wizard_completed';
  static const String _wizardVersionKey = 'wizard_version';
  static const int _currentWizardVersion = 1;

  /// Check if the welcome wizard has been completed
  static Future<bool> isWizardCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_wizardCompletedKey) ?? false;
    final version = prefs.getInt(_wizardVersionKey) ?? 0;

    // Re-show wizard if version has changed (for major updates)
    return completed && version >= _currentWizardVersion;
  }

  /// Mark the welcome wizard as completed
  static Future<void> setWizardCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wizardCompletedKey, completed);

    if (completed) {
      // Store current version when wizard is completed
      await prefs.setInt(_wizardVersionKey, _currentWizardVersion);
    }
  }

  /// Get the wizard version last shown to the user
  static Future<int> getWizardVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_wizardVersionKey) ?? 0;
  }

  /// Reset wizard state (useful for testing or re-showing tutorial)
  static Future<void> resetWizard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_wizardCompletedKey, false);
    await prefs.setInt(_wizardVersionKey, 0);
  }
}
