import '../models/message.dart';
import 'image_message_parser.dart';
import 'voice_message_parser.dart';

const int _defaultLoRaSf = 10;
const int _defaultLoRaCr = 5;
const int _defaultLoRaBwHz = 250000;
const int _defaultLoRaPreambleSymbols = 8;
const int _defaultLoRaCrcEnabled = 1;
const int _defaultLoRaExplicitHeader = 1;
const double _defaultAirtimeBudgetFactor = 1.0;
const int _meshPacketHeaderBytes = 2;
const int _textFrameBaseBytes = 10;

Duration estimateMessageTransmitDuration(
  Message message, {
  int? radioBw,
  int? radioSf,
  int? radioCr,
}) {
  final imageEnvelope = ImageEnvelope.tryParse(message.text);
  if (imageEnvelope != null) {
    return estimateImageTransmitDuration(
      fragmentCount: imageEnvelope.total,
      sizeBytes: imageEnvelope.sizeBytes,
      pathLen: message.pathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
  }

  final voiceEnvelope = VoiceEnvelope.tryParseText(message.text);
  if (voiceEnvelope != null) {
    return estimateVoiceTransmitDuration(
      mode: voiceEnvelope.mode,
      packetCount: voiceEnvelope.total,
      durationMs: voiceEnvelope.durationMs,
      pathLen: message.pathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
  }

  final voicePacket = VoicePacket.tryParseText(message.text);
  if (voicePacket != null) {
    return estimateVoiceTransmitDuration(
      mode: voicePacket.mode,
      packetCount: voicePacket.total,
      durationMs: voicePacket.durationMs * voicePacket.total,
      pathLen: message.pathLen,
      radioBw: radioBw,
      radioSf: radioSf,
      radioCr: radioCr,
    );
  }

  final normalizedPathLen = _normalizedPathLen(message.pathLen);
  final payloadBytes = _textFrameBaseBytes + message.text.length;
  final hops = normalizedPathLen + 1;
  final airtimeMs = _estimateLoRaAirtimeMs(
    _meshPacketHeaderBytes + normalizedPathLen + payloadBytes,
    radioBw: radioBw,
    radioSf: radioSf,
    radioCr: radioCr,
  );

  return Duration(
    milliseconds: (airtimeMs * (1.0 + _defaultAirtimeBudgetFactor) * hops)
        .round(),
  );
}

int _normalizedPathLen(int pathLen) {
  if (pathLen < 0 || pathLen >= 255) return 0;
  return pathLen.clamp(0, 64).toInt();
}

double _estimateLoRaAirtimeMs(
  int payloadLenBytes, {
  int? radioBw,
  int? radioSf,
  int? radioCr,
}) {
  final sf = _normalizeSf(radioSf);
  final bw = _resolveBandwidthHz(radioBw).toDouble();
  final cr = (_normalizeCr(radioCr) - 4).clamp(1, 4);
  final ih = _defaultLoRaExplicitHeader == 1 ? 0 : 1;
  final de = (sf >= 11 && _defaultLoRaBwHz <= 125000) ? 1 : 0;

  final symbolMs = ((1 << sf) / bw) * 1000.0;
  final preambleMs = (_defaultLoRaPreambleSymbols + 4.25) * symbolMs;

  final num =
      (8 * payloadLenBytes) -
      (4 * sf) +
      28 +
      (16 * _defaultLoRaCrcEnabled) -
      (20 * ih);
  final den = 4 * (sf - (2 * de));
  final payloadSymCoeff = den <= 0 ? 0 : (num / den).ceil();
  final payloadSymbols =
      8 + (payloadSymCoeff < 0 ? 0 : payloadSymCoeff) * (cr + 4);
  final payloadMs = payloadSymbols * symbolMs;

  return preambleMs + payloadMs;
}

int _normalizeSf(int? value) {
  if (value == null) return _defaultLoRaSf;
  if (value >= 5 && value <= 12) return value;
  return _defaultLoRaSf;
}

int _normalizeCr(int? value) {
  if (value == null) return _defaultLoRaCr;
  if (value >= 5 && value <= 8) return value;
  return _defaultLoRaCr;
}

int _resolveBandwidthHz(int? rawBw) {
  if (rawBw == null) return _defaultLoRaBwHz;
  if (rawBw > 1000) return rawBw;
  switch (rawBw) {
    case 0:
      return 7800;
    case 1:
      return 10400;
    case 2:
      return 15600;
    case 3:
      return 20800;
    case 4:
      return 31250;
    case 5:
      return 41700;
    case 6:
      return 62500;
    case 7:
      return 125000;
    case 8:
      return 250000;
    case 9:
      return 500000;
    default:
      return _defaultLoRaBwHz;
  }
}
