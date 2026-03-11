import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Plays decoded mono PCM samples by writing a WAV file
/// to the system temp directory and using [AudioPlayer].
class VoicePlayerService {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _events = StreamController<void>.broadcast();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _fallbackTicker;
  DateTime? _playbackStartedAt;

  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  Duration get duration => _duration;
  Stream<void> get events => _events.stream;

  VoicePlayerService() {
    _player.onPlayerStateChanged.listen((state) {
      debugPrint('🔊 [VoicePlayer] state → $state');
      _isPlaying = state == PlayerState.playing;
      if (_isPlaying) {
        _startFallbackTicker();
      } else {
        _stopFallbackTicker();
      }
      _events.add(null);
    });
    _player.onLog.listen((msg) => debugPrint('🔊 [VoicePlayer] log: $msg'));
    _player.onPositionChanged.listen((position) {
      _position = position;
      _events.add(null);
    });
    _player.onDurationChanged.listen((duration) {
      _duration = duration;
      _events.add(null);
    });
    _player.onPlayerComplete.listen((_) {
      _isPlaying = false;
      _position = _duration;
      _stopFallbackTicker();
      _events.add(null);
    });
  }

  Future<void> play(Int16List pcmSamples, {required int sampleRateHz}) async {
    debugPrint('🔊 [VoicePlayer] play() called, ${pcmSamples.length} samples');
    if (_isPlaying) await stop();
    _position = Duration.zero;
    _duration = Duration(
      milliseconds: (pcmSamples.length * 1000) ~/ sampleRateHz,
    );
    _playbackStartedAt = DateTime.now();
    _events.add(null);

    final wavBytes = _buildWav(pcmSamples, sampleRate: sampleRateHz);
    final tmpDir = await getTemporaryDirectory();
    final file = File('${tmpDir.path}/vc_voice.wav');
    await file.writeAsBytes(wavBytes);
    debugPrint(
      '🔊 [VoicePlayer] WAV written: ${wavBytes.length} bytes → ${file.path}',
    );

    try {
      _isPlaying = true;
      _startFallbackTicker();
      _events.add(null);
      await _player.play(DeviceFileSource(file.path));
      debugPrint('🔊 [VoicePlayer] play() returned (audio playing)');
    } catch (e, st) {
      debugPrint('❌ [VoicePlayer] play() error: $e\n$st');
      _isPlaying = false;
      _stopFallbackTicker();
      _events.add(null);
    }
  }

  Future<void> stop() async {
    debugPrint('🔊 [VoicePlayer] stop()');
    await _player.stop();
    _isPlaying = false;
    _position = Duration.zero;
    _playbackStartedAt = null;
    _stopFallbackTicker();
    _events.add(null);
  }

  void dispose() {
    _stopFallbackTicker();
    _events.close();
    _player.dispose();
  }

  void _startFallbackTicker() {
    if (_fallbackTicker != null) return;
    _fallbackTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isPlaying || _duration.inMilliseconds <= 0) return;
      final startedAt = _playbackStartedAt;
      if (startedAt == null) return;
      final elapsed = DateTime.now().difference(startedAt);
      final clamped = elapsed > _duration ? _duration : elapsed;
      if (clamped > _position) {
        _position = clamped;
        _events.add(null);
      }
    });
  }

  void _stopFallbackTicker() {
    _fallbackTicker?.cancel();
    _fallbackTicker = null;
  }

  // ── WAV file builder ─────────────────────────────────────────────────────

  /// Constructs a minimal WAV (RIFF/PCM) file from Int16 mono samples.
  static Uint8List _buildWav(Int16List samples, {required int sampleRate}) {
    const int numChannels = 1;
    const int bitsPerSample = 16;
    const int audioFormat = 1; // PCM

    final dataSize = samples.length * 2; // 2 bytes per Int16 sample
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final totalSize = 36 + dataSize;

    final buf = ByteData(44 + dataSize);
    var offset = 0;

    void writeStr(String s) {
      for (final c in s.codeUnits) {
        buf.setUint8(offset++, c);
      }
    }

    void writeU32(int v) {
      buf.setUint32(offset, v, Endian.little);
      offset += 4;
    }

    void writeU16(int v) {
      buf.setUint16(offset, v, Endian.little);
      offset += 2;
    }

    writeStr('RIFF');
    writeU32(totalSize);
    writeStr('WAVE');
    writeStr('fmt ');
    writeU32(16); // subchunk1 size
    writeU16(audioFormat); // 1 = PCM
    writeU16(numChannels);
    writeU32(sampleRate);
    writeU32(byteRate);
    writeU16(blockAlign);
    writeU16(bitsPerSample);
    writeStr('data');
    writeU32(dataSize);

    // PCM sample data (little-endian Int16)
    for (final s in samples) {
      buf.setInt16(offset, s, Endian.little);
      offset += 2;
    }

    return buf.buffer.asUint8List();
  }
}
