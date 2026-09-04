import 'dart:typed_data';
import 'package:codec2_flutter/codec2_flutter.dart';
import 'package:flutter/foundation.dart';
import '../utils/voice_message_parser.dart';

Codec2Mode codec2ModeFor(VoicePacketMode pktMode) {
  switch (pktMode) {
    case VoicePacketMode.mode3200:
      return Codec2Mode.mode3200;
    case VoicePacketMode.mode1600:
      return Codec2Mode.mode1600;
    case VoicePacketMode.mode1400:
      return Codec2Mode.mode1400;
    case VoicePacketMode.mode700c:
      return Codec2Mode.mode700c;
    case VoicePacketMode.mode1200:
      return Codec2Mode.mode1200;
    case VoicePacketMode.mode1300:
      return Codec2Mode.mode1300;
    case VoicePacketMode.mode2400:
      return Codec2Mode.mode2400;
  }
}

/// Selects the [VoicePacketMode] best suited for a given LoRa radio bandwidth.
///
/// Call with [radioBandwidthHz] from the device's radio params
/// (e.g. 125000 for 125 kHz).
VoicePacketMode voiceModeForBandwidth(int radioBandwidthHz) {
  if (radioBandwidthHz <= 62500) return VoicePacketMode.mode700c;
  if (radioBandwidthHz <= 125000) return VoicePacketMode.mode1200;
  return VoicePacketMode.mode1300;
}

/// High-level codec service that provides async Codec2 encode/decode
/// executed in a background isolate so the UI thread is never blocked.
class VoiceCodecService {
  void _ensureCodec2Supported() {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      throw UnsupportedError('Codec2 is enabled only on iOS and Android.');
    }
  }

  Future<Uint8List> encode(Int16List pcm, VoicePacketMode mode) {
    _ensureCodec2Supported();
    return Codec2.encodeInIsolate(pcm, codec2ModeFor(mode));
  }

  Future<Int16List> decode(Uint8List codec2Bytes, VoicePacketMode mode) {
    _ensureCodec2Supported();
    return Codec2.decodeInIsolate(codec2Bytes, codec2ModeFor(mode));
  }

  /// Decode and concatenate multiple [packets] into a single PCM Int16List.
  /// Packets with null/missing entries are substituted with silence.
  Future<Int16List> decodePackets(
    List<VoicePacket?> packets,
    VoicePacketMode mode,
  ) async {
    _ensureCodec2Supported();
    final all = <Int16List>[];
    for (final pkt in packets) {
      if (pkt == null || pkt.codec2Data.isEmpty) {
        all.add(Int16List(mode.samplesPerPacket));
      } else {
        all.add(await decode(pkt.codec2Data, mode));
      }
    }
    final total = all.fold<int>(0, (sum, l) => sum + l.length);
    final result = Int16List(total);
    var offset = 0;
    for (final chunk in all) {
      result.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return result;
  }
}
