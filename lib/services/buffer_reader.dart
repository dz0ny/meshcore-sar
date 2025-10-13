import 'dart:typed_data';
import 'dart:convert';

/// Buffer reader for parsing MeshCore protocol binary data
class BufferReader {
  final Uint8List _buffer;
  int _offset = 0;

  BufferReader(this._buffer);

  /// Get remaining bytes count
  int get remainingBytesCount => _buffer.length - _offset;

  /// Check if there are bytes remaining
  bool get hasRemaining => _offset < _buffer.length;

  /// Get current offset
  int get offset => _offset;

  /// Set offset
  set offset(int value) => _offset = value;

  /// Read a single byte (uint8)
  int readByte() {
    if (_offset >= _buffer.length) {
      throw Exception('Buffer overflow: attempting to read beyond buffer length');
    }
    return _buffer[_offset++];
  }

  /// Read a signed byte (int8)
  int readInt8() {
    final value = readByte();
    return value > 127 ? value - 256 : value;
  }

  /// Read unsigned 16-bit integer (little-endian)
  int readUInt16LE() {
    if (_offset + 2 > _buffer.length) {
      throw Exception('Buffer overflow: attempting to read beyond buffer length');
    }
    final value = _buffer[_offset] | (_buffer[_offset + 1] << 8);
    _offset += 2;
    return value;
  }

  /// Read signed 16-bit integer (little-endian)
  int readInt16LE() {
    final value = readUInt16LE();
    return value > 32767 ? value - 65536 : value;
  }

  /// Read unsigned 32-bit integer (little-endian)
  int readUInt32LE() {
    if (_offset + 4 > _buffer.length) {
      throw Exception('Buffer overflow: attempting to read beyond buffer length');
    }
    final value = _buffer[_offset] |
        (_buffer[_offset + 1] << 8) |
        (_buffer[_offset + 2] << 16) |
        (_buffer[_offset + 3] << 24);
    _offset += 4;
    return value;
  }

  /// Read signed 32-bit integer (little-endian)
  int readInt32LE() {
    final value = readUInt32LE();
    return value > 2147483647 ? value - 4294967296 : value;
  }

  /// Read a fixed number of bytes
  Uint8List readBytes(int length) {
    if (_offset + length > _buffer.length) {
      throw Exception('Buffer overflow: attempting to read beyond buffer length');
    }
    final bytes = _buffer.sublist(_offset, _offset + length);
    _offset += length;
    return bytes;
  }

  /// Read remaining bytes
  Uint8List readRemainingBytes() {
    final bytes = _buffer.sublist(_offset);
    _offset = _buffer.length;
    return bytes;
  }

  /// Read null-terminated string (C-string) with max length
  String readCString(int maxLength) {
    if (_offset + maxLength > _buffer.length) {
      throw Exception('Buffer overflow: attempting to read beyond buffer length');
    }

    final bytes = _buffer.sublist(_offset, _offset + maxLength);
    _offset += maxLength;

    // Find null terminator
    int nullIndex = bytes.indexOf(0);
    if (nullIndex == -1) {
      nullIndex = maxLength;
    }

    // Decode string up to null terminator
    return utf8.decode(bytes.sublist(0, nullIndex));
  }

  /// Read length-prefixed string (remaining bytes as UTF-8)
  String readString() {
    final bytes = readRemainingBytes();
    return utf8.decode(bytes);
  }

  /// Peek at next byte without advancing offset
  int peekByte() {
    if (_offset >= _buffer.length) {
      throw Exception('Buffer overflow: attempting to peek beyond buffer length');
    }
    return _buffer[_offset];
  }

  /// Skip bytes
  void skip(int count) {
    if (_offset + count > _buffer.length) {
      throw Exception('Buffer overflow: attempting to skip beyond buffer length');
    }
    _offset += count;
  }

  /// Reset offset to beginning
  void reset() {
    _offset = 0;
  }

  @override
  String toString() {
    return 'BufferReader(length: ${_buffer.length}, offset: $_offset, remaining: $remainingBytesCount)';
  }
}
