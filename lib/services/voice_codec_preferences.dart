import 'package:shared_preferences/shared_preferences.dart';
import '../utils/voice_message_parser.dart';

class VoiceCodecPreferences {
  static const String _codecKey = 'voice_codec';
  static const VoiceCodecKind defaultCodec = VoiceCodecKind.codec2;

  static Future<VoiceCodecKind> getCodec() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_codecKey);
    return VoiceCodecKind.values.firstWhere(
      (codec) => codec.name == raw,
      orElse: () => defaultCodec,
    );
  }

  static Future<void> setCodec(VoiceCodecKind codec) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codecKey, codec.name);
  }
}
