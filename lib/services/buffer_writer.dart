import 'dart:typed_data';
import 'dart:convert';

/// Buffer writer for creating MeshCore protocol binary data
class BufferWriter {
  final List<int> _buffer = [];

  /// Get current buffer length
  int get length => _buffer.length;

  /// Write a single byte (uint8)
  void writeByte(int value) {
    if (value < 0 || value > 255) {
      throw ArgumentError('Byte value must be between 0 and 255');
    }
    _buffer.add(value);
  }

  /// Write a signed byte (int8)
  void writeInt8(int value) {
    if (value < -128 || value > 127) {
      throw ArgumentError('Int8 value must be between -128 and 127');
    }
    _buffer.add(value < 0 ? value + 256 : value);
  }

  /// Write unsigned 16-bit integer (little-endian)
  void writeUInt16LE(int value) {
    if (value < 0 || value > 65535) {
      throw ArgumentError('UInt16 value must be between 0 and 65535');
    }
    _buffer.add(value & 0xFF);
    _buffer.add((value >> 8) & 0xFF);
  }

  /// Write signed 16-bit integer (little-endian)
  void writeInt16LE(int value) {
    if (value < -32768 || value > 32767) {
      throw ArgumentError('Int16 value must be between -32768 and 32767');
    }
    final unsigned = value < 0 ? value + 65536 : value;
    writeUInt16LE(unsigned);
  }

  /// Write unsigned 32-bit integer (little-endian)
  void writeUInt32LE(int value) {
    if (value < 0 || value > 4294967295) {
      throw ArgumentError('UInt32 value must be between 0 and 4294967295');
    }
    _buffer.add(value & 0xFF);
    _buffer.add((value >> 8) & 0xFF);
    _buffer.add((value >> 16) & 0xFF);
    _buffer.add((value >> 24) & 0xFF);
  }

  /// Write signed 32-bit integer (little-endian)
  void writeInt32LE(int value) {
    if (value < -2147483648 || value > 2147483647) {
      throw ArgumentError('Int32 value must be between -2147483648 and 2147483647');
    }
    final unsigned = value < 0 ? value + 4294967296 : value;
    writeUInt32LE(unsigned);
  }

  /// Write bytes from Uint8List
  void writeBytes(Uint8List bytes) {
    _buffer.addAll(bytes);
  }

  /// Write bytes from List<int>
  void writeBytesFromList(List<int> bytes) {
    _buffer.addAll(bytes);
  }

  /// Write null-terminated string (C-string) with fixed length
  /// Pads with zeros if string is shorter than maxLength
  void writeCString(String str, int maxLength) {
    final bytes = utf8.encode(str);

    // Ensure we don't exceed max length
    final length = bytes.length < maxLength ? bytes.length : maxLength;

    // Write string bytes
    for (int i = 0; i < length; i++) {
      _buffer.add(bytes[i]);
    }

    // Pad with zeros
    for (int i = length; i < maxLength; i++) {
      _buffer.add(0);
    }
  }

  /// Write length-prefixed string
  void writeString(String str) {
    final bytes = utf8.encode(str);
    _buffer.addAll(bytes);
  }

  /// Write string with length prefix (1 byte)
  void writeLengthPrefixedString(String str) {
    final bytes = utf8.encode(str);
    if (bytes.length > 255) {
      throw ArgumentError('String too long for length-prefixed format (max 255 bytes)');
    }
    writeByte(bytes.length);
    _buffer.addAll(bytes);
  }

  /// Get buffer as Uint8List
  Uint8List toBytes() {
    return Uint8List.fromList(_buffer);
  }

  /// Clear the buffer
  void clear() {
    _buffer.clear();
  }

  /// Get buffer as hex string (for debugging)
  String toHexString() {
    return _buffer.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
  }

  @override
  String toString() {
    return 'BufferWriter(length: $length, hex: ${toHexString()})';
  }
}
