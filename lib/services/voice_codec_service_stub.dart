import 'dart:typed_data';
import '../utils/voice_message_parser.dart';

enum Codec2Mode {
  mode3200(0),
  mode2400(1),
  mode1600(2),
  mode1400(3),
  mode1300(4),
  mode1200(5),
  mode700c(8);

  const Codec2Mode(this.c2ModeId);
  final int c2ModeId;

  int get framesPerSecond => (this == mode3200 || this == mode2400) ? 50 : 25;
  int get samplesPerFrame => 8000 ~/ framesPerSecond;

  int get bytesPerSecond {
    switch (this) {
      case mode3200:
        return 400;
      case mode700c:
        return 100;
      case mode1200:
        return 150;
      case mode1300:
        return 175;
      case mode1400:
        return 175;
      case mode1600:
        return 200;
      case mode2400:
        return 300;
    }
  }

  static const int _maxBytesPerPacket = 160;

  int get packetDurationMs {
    final bytesPerFrame = bytesPerSecond / framesPerSecond;
    final framesPerPacket = (_maxBytesPerPacket / bytesPerFrame).floor();
    return (framesPerPacket * 1000 ~/ framesPerSecond);
  }
}

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

VoicePacketMode voiceModeForBandwidth(int radioBandwidthHz) {
  if (radioBandwidthHz <= 62500) return VoicePacketMode.mode700c;
  if (radioBandwidthHz <= 125000) return VoicePacketMode.mode1200;
  return VoicePacketMode.mode1300;
}

class VoiceCodecService {
  Future<Uint8List> encode(Int16List pcm, VoicePacketMode mode) =>
      Future.error(UnsupportedError('Voice not supported on web'));

  Future<Int16List> decode(Uint8List codec2Bytes, VoicePacketMode mode) =>
      Future.error(UnsupportedError('Voice not supported on web'));

  Future<Int16List> decodePackets(
    List<VoicePacket?> packets,
    VoicePacketMode mode,
  ) => Future.error(UnsupportedError('Voice not supported on web'));
}
