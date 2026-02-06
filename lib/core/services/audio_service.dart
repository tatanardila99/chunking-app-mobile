import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService instance = AudioService._init();

  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  bool _isSttInitialized = false;

  AudioService._init() {
    _initTts();
  }

  // --- TTS (HABLAR) ---
  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5); // Velocidad pedagógica
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Configuración iOS para evitar cortes
      await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
      ]);
    } catch (e) {
      debugPrint("Error TTS: $e");
    }
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint("Error hablando: $e");
    }
  }

  Future<void> stopTts() async {
    await _tts.stop();
  }

  // --- STT (ESCUCHAR) ---
  Future<bool> initStt() async {
    if (!_isSttInitialized) {
      try {
        _isSttInitialized = await _stt.initialize(
          onStatus: (status) => debugPrint('STT Status: $status'),
          onError: (error) => debugPrint('STT Error: $error'),
        );
      } catch (e) {
        debugPrint("Error Init STT: $e");
      }
    }
    return _isSttInitialized;
  }

  // AHORA DEVUELVE TEXTO Y SI ES EL FINAL
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
  }) async {
    bool available = await initStt();
    if (available) {
      await _stt.listen(
        onResult: (result) {
          // Enviamos el texto reconocido y la bandera de si terminó
          onResult(result.recognizedWords, result.finalResult);
        },
        localeId: "en_US",
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 2), // Si calla 2 seg, se asume final
        partialResults: true,
        cancelOnError: true,
      );
    } else {
      debugPrint("STT no disponible");
    }
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  bool get isListening => _stt.isListening;
}
