import 'package:speech_to_text/speech_to_text.dart';

abstract interface class VoiceService {
  Future<bool> initialize();
  Future<void> startListening({
    required String localeId,
    required void Function(String recognizedWords) onResult,
  });
  Future<void> stopListening();
}

/// On-device speech-to-text supporting Tamil (`ta_IN`) and English (`en_IN`).
class DeviceVoiceService implements VoiceService {
  DeviceVoiceService({SpeechToText? stt}) : _stt = stt ?? SpeechToText();

  final SpeechToText _stt;
  bool _initialized = false;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _stt.initialize();
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<void> startListening({
    required String localeId,
    required void Function(String recognizedWords) onResult,
  }) async {
    final ok = await initialize();
    if (!ok) return;
    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(localeId: localeId),
    );
  }

  @override
  Future<void> stopListening() async {
    if (_stt.isListening) {
      await _stt.stop();
    }
  }
}
