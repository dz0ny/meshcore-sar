import 'dart:typed_data';

/// Extension on Uint8List to provide comparison functionality for public keys.
///
/// This extension is used to compare MeshCore public keys (32 bytes) or their
/// prefixes (6 bytes) across the application.
extension Uint8ListComparison on Uint8List {
  /// Compares this Uint8List with another for exact equality.
  ///
  /// Returns true if both lists have the same length and identical bytes.
  bool matches(Uint8List other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}
