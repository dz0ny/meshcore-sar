import 'package:flutter/material.dart';
import '../models/contact.dart';

/// Service for assigning consistent colors to contact trails
/// Uses emoji-based semantic mapping with deterministic hash fallback
class TrailColorService {
  // 64-color pastel palette optimized for visibility on all map types
  // Organized by hue families for better distribution
  // Avoids red/orange/yellow spectrum to prevent confusion with fire markers
  // Avoids pure blue (#2196F3) which is reserved for user trail
  static final List<Color> _colorPalette = [
    // Pinks & Light Corals (8)
    const Color(0xFFFFB6C1), // Light Pink
    const Color(0xFFFF7F7F), // Coral
    const Color(0xFFFFC0CB), // Pink
    const Color(0xFFFFB3BA), // Pastel Pink
    const Color(0xFFFF9AA2), // Light Coral
    const Color(0xFFFFDAE9), // Pale Pink
    const Color(0xFFFAA0B8), // Pastel Rose
    const Color(0xFFFF8FA3), // Salmon Pink

    // Purples & Plums (8)
    const Color(0xFFE6E6FA), // Lavender
    const Color(0xFFDDA0DD), // Plum
    const Color(0xFFD8BFD8), // Thistle
    const Color(0xFFDDA5E9), // Pastel Purple
    const Color(0xFFE0BBE4), // Mauve
    const Color(0xFFC5A3E0), // Light Purple
    const Color(0xFFB19CD9), // Medium Lavender
    const Color(0xFFAF9FCD), // Wisteria

    // Blues & Sky (12)
    const Color(0xFF87CEEB), // Sky Blue
    const Color(0xFFB0E0E6), // Powder Blue
    const Color(0xFFADD8E6), // Light Blue
    const Color(0xFF87CEFA), // Light Sky Blue
    const Color(0xFFB0C4DE), // Light Steel Blue
    const Color(0xFF9BB8D3), // Pastel Blue
    const Color(0xFF89CFF0), // Baby Blue
    const Color(0xFFA2C8EC), // Columbia Blue
    const Color(0xFF7FB3D5), // Pale Blue
    const Color(0xFF6A9FB5), // Air Force Blue
    const Color(0xFF8DB4D2), // Soft Blue
    const Color(0xFF7BA5C9), // Light Denim

    // Cyans & Teals (8)
    const Color(0xFF5F9EA0), // Cadet Blue
    const Color(0xFF7FFFD4), // Aquamarine
    const Color(0xFF98D8C8), // Mint
    const Color(0xFF82E0D5), // Pale Cyan
    const Color(0xFF8FD8D8), // Light Teal
    const Color(0xFF81C0BB), // Cadet Teal
    const Color(0xFF72B0A8), // Medium Teal
    const Color(0xFF6FA09E), // Soft Teal

    // Greens & Mints (8)
    const Color(0xFF90EE90), // Light Green
    const Color(0xFF98D8B4), // Celadon
    const Color(0xFFA8E4A0), // Granny Smith
    const Color(0xFFB2E8B2), // Tea Green
    const Color(0xFF9FD8AF), // Eton Blue
    const Color(0xFF8FC49F), // Pastel Green
    const Color(0xFF7EB693), // Cambridge Blue
    const Color(0xFF73A685), // Russian Green

    // Beiges & Tans (12)
    const Color(0xFFD2B48C), // Tan
    const Color(0xFFDEB887), // Burlywood
    const Color(0xFFE0D8B0), // Beige
    const Color(0xFFFFDAB9), // Peach
    const Color(0xFFFFE4B5), // Moccasin
    const Color(0xFFFFF8DC), // Cornsilk
    const Color(0xFFE8D5C4), // Champagne
    const Color(0xFFD4C5B9), // Dust
    const Color(0xFFC9B8A9), // Khaki
    const Color(0xFFBCAA99), // Cashmere
    const Color(0xFFB09B87), // Taupe
    const Color(0xFFA58F7A), // Mocha

    // Grays & Silvers (8)
    const Color(0xFFD3D3D3), // Light Gray
    const Color(0xFFC0C0C0), // Silver
    const Color(0xFFBCBCBC), // Bright Gray
    const Color(0xFFB2B2B2), // Medium Gray
    const Color(0xFFA9A9A9), // Dark Gray
    const Color(0xFF9E9E9E), // Gray
    const Color(0xFF8E8E8E), // Taupe Gray
    const Color(0xFF7E7E7E), // Granite
  ];

  // Emoji to color mapping for SAR roles
  // Uses pastel semantic colors for high visibility on maps
  // Avoids red/orange/yellow to prevent confusion with fire markers
  static final Map<String, Color> _emojiColorMap = {
    // Emergency Services - Firefighters
    '🚒': Color(0xFFFF7F7F), // Fire engine → Coral
    '🧑‍🚒': Color(0xFFFF7F7F), // Firefighter → Coral
    '👨‍🚒': Color(0xFFFF7F7F), // Firefighter → Coral
    '👩‍🚒': Color(0xFFFF7F7F), // Firefighter → Coral
    '🔥': Color(0xFFFFB6C1), // Fire → Light Pink

    // Emergency Services - Medical
    '🚑': Color(0xFF7FFFD4), // Ambulance → Mint (medical cross)
    '👨‍⚕️': Color(0xFF7FFFD4), // Health worker → Mint
    '👩‍⚕️': Color(0xFF7FFFD4), // Health worker → Mint
    '🧑‍⚕️': Color(0xFF7FFFD4), // Health worker → Mint
    '⚕️': Color(0xFF7FFFD4), // Medical symbol → Mint

    // Emergency Services - Police
    '👮': Color(0xFF87CEEB), // Police → Light Blue
    '👮‍♂️': Color(0xFF87CEEB), // Police → Light Blue
    '👮‍♀️': Color(0xFF87CEEB), // Police → Light Blue
    '🚔': Color(0xFF87CEEB), // Police car → Light Blue

    // Emergency Services - Aviation
    '🧑‍✈️': Color(0xFFB0E0E6), // Pilot → Sky Blue
    '👨‍✈️': Color(0xFFB0E0E6), // Pilot → Sky Blue
    '👩‍✈️': Color(0xFFB0E0E6), // Pilot → Sky Blue
    '🚁': Color(0xFFE6E6FA), // Helicopter → Lavender

    // SAR Roles - Mountain/Alpine
    '🏔️': Color(0xFFD2B48C), // Mountain → Tan
    '⛰️': Color(0xFFD2B48C), // Mountain → Tan
    '🧗': Color(0xFFD2B48C), // Climber → Tan
    '🧗‍♂️': Color(0xFFD2B48C), // Climber → Tan
    '🧗‍♀️': Color(0xFFD2B48C), // Climber → Tan
    '🥾': Color(0xFFDEB887), // Hiking boot → Burlywood

    // SAR Roles - K9 Unit
    '🐕': Color(0xFFFFDAB9), // Dog → Peach
    '🐶': Color(0xFFFFDAB9), // Dog → Peach
    '🦮': Color(0xFFFFDAB9), // Service dog → Peach

    // SAR Roles - Water Rescue
    '🚤': Color(0xFF87CEEB), // Speedboat → Sky Blue
    '⛵': Color(0xFF87CEEB), // Sailboat → Sky Blue
    '🏊': Color(0xFF5F9EA0), // Swimmer → Cadet Blue
    '🏊‍♂️': Color(0xFF5F9EA0), // Swimmer → Cadet Blue
    '🏊‍♀️': Color(0xFF5F9EA0), // Swimmer → Cadet Blue

    // Team Roles - Leadership
    '🎯': Color(0xFFFFB6C1), // Target → Light Pink (team leader)
    '⭐': Color(0xFFFFE4B5), // Star → Moccasin (coordinator)
    '👑': Color(0xFFFFE4B5), // Crown → Moccasin (leader)

    // Team Roles - Communication
    '📡': Color(0xFF5F9EA0), // Satellite → Cadet Blue (radio/comms)
    '📻': Color(0xFF5F9EA0), // Radio → Cadet Blue
    '📞': Color(0xFF5F9EA0), // Phone → Cadet Blue

    // Team Roles - Navigation
    '🗺️': Color(0xFF87CEEB), // Map → Sky Blue (navigator)
    '🧭': Color(0xFF87CEEB), // Compass → Sky Blue
    '📍': Color(0xFFFF7F7F), // Pin → Coral (location marker)

    // Team Roles - Documentation
    '📷': Color(0xFFDDA0DD), // Camera → Plum
    '📹': Color(0xFFDDA0DD), // Video camera → Plum
    '📝': Color(0xFFE0E0A0), // Note → Khaki (scribe)

    // Equipment
    '🔦': Color(0xFFFFE4B5), // Flashlight → Moccasin
    '⚡': Color(0xFFFFE4B5), // Lightning → Moccasin (power/energy)
    '🔋': Color(0xFF7FFFD4), // Battery → Mint
    '🎒': Color(0xFFDEB887), // Backpack → Burlywood

    // Generic Person Icons
    '👤': Color(0xFFD3D3D3), // Silhouette → Light Gray
    '🧑': Color(0xFFD3D3D3), // Person → Light Gray
    '👨': Color(0xFFD3D3D3), // Man → Light Gray
    '👩': Color(0xFFD3D3D3), // Woman → Light Gray
    '👥': Color(0xFFC0C0C0), // People → Silver
  };

  /// Get trail color for a contact
  /// Priority: Emoji mapping > Name hash > Default
  /// Returns fully opaque color - alpha transparency applied by caller
  static Color getTrailColor(Contact contact) {
    // 1. Try emoji-based color mapping
    if (contact.roleEmoji != null) {
      final emojiColor = _emojiColorMap[contact.roleEmoji];
      if (emojiColor != null) {
        return emojiColor;
      }
    }

    // 2. Deterministic color based on display name
    // Use display name (without emoji) for consistent hashing
    final name = contact.displayName.isNotEmpty
        ? contact.displayName
        : contact.publicKeyHex;

    final hash = _hashString(name);
    final colorIndex = hash % _colorPalette.length; // 0-63

    return _colorPalette[colorIndex];
  }

  /// Simple string hash function (DJB2 algorithm)
  /// Same algorithm used for echo detection in the app
  static int _hashString(String str) {
    int hash = 5381;
    for (int i = 0; i < str.length; i++) {
      hash = ((hash << 5) + hash) + str.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF; // Keep 32-bit
    }
    return hash.abs();
  }

  /// Get all unique colors currently in use by contacts with trails
  static List<Color> getActiveColors(List<Contact> contacts) {
    final colors = <Color>{};
    for (final contact in contacts) {
      if (contact.advertHistory.length >= 2) {
        colors.add(getTrailColor(contact));
      }
    }
    return colors.toList();
  }

  /// Check if a color is from emoji mapping (semantic) vs hash-based
  static bool isSemanticColor(Contact contact) {
    if (contact.roleEmoji == null) return false;
    return _emojiColorMap.containsKey(contact.roleEmoji);
  }
}
