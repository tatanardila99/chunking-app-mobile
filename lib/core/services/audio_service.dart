
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class AudioService {
  // Singleton Pattern
  static final AudioService instance = AudioService._init();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isSttInitialized = false;

  AudioService._init() {
    _initTts();
  }

  // --- CONFIGURACIÓN TTS (VOZ DE LA APP) ---
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5); // 0.5 es una velocidad pedagógica buena
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Configuración específica para iOS para que el audio no se corte en silencio
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      ]);
    } catch (e) {
      debugPrint("Error inicializando TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _tts.stop(); // Detener si algo estaba sonando
      await _tts.speak(text);
    } catch (e) {
      debugPrint("Error reproduciendo TTS: $e");
    }
  }

  Future<void> stopTts() async {
    await _tts.stop();
  }

  // --- CONFIGURACIÓN STT (RECONOCIMIENTO DE VOZ) ---
  Future<bool> initStt() async {
    if (!_isSttInitialized) {
      try {
        _isSttInitialized = await _stt.initialize(
          onStatus: (status) => debugPrint('STT Status: $status'),
          onError:
              (errorNotification) =>
                  debugPrint('STT Error: $errorNotification'),
        );
      } catch (e) {
        debugPrint("Error inicializando STT: $e");
      }
    }
    return _isSttInitialized;
  }

  Future<void> startListening({required Function(String) onResult}) async {
    bool available = await initStt();
    if (available) {
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult || result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        localeId: "en_US", // Forzamos inglés para practicar
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      );
    } else {
      debugPrint("El reconocimiento de voz no está disponible.");
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
