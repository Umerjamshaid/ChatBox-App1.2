// lib/services/speech_service.dart
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechService {
  static const String _voiceEnabledKey = 'voice_enabled';
  static const String _speechEnabledKey = 'speech_enabled';
  static const String _voiceLanguageKey = 'voice_language';
  static const String _speechLanguageKey = 'speech_language';

  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final SharedPreferences _prefs;

  bool _isInitialized = false;
  bool _isListening = false;

  SpeechService(this._prefs);

  // Getters for settings
  bool get voiceEnabled => _prefs.getBool(_voiceEnabledKey) ?? true;
  bool get speechEnabled => _prefs.getBool(_speechEnabledKey) ?? true;
  String get voiceLanguage => _prefs.getString(_voiceLanguageKey) ?? 'en-US';
  String get speechLanguage => _prefs.getString(_speechLanguageKey) ?? 'en-US';

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize speech to text
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'notListening') {
            _isListening = false;
          }
        },
        onError: (error) {
          print('Speech recognition error: $error');
          _isListening = false;
        },
      );

      // Initialize text to speech
      await _flutterTts.setLanguage(voiceLanguage);
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Set completion handler
      _flutterTts.setCompletionHandler(() {
        print('Text-to-speech completed');
      });

      // Set error handler
      _flutterTts.setErrorHandler((error) {
        print('Text-to-speech error: $error');
      });
    } catch (e) {
      print('Speech service initialization failed: $e');
      _isInitialized = false;
    }
  }

  // Settings methods
  Future<void> setVoiceEnabled(bool enabled) async {
    await _prefs.setBool(_voiceEnabledKey, enabled);
  }

  Future<void> setSpeechEnabled(bool enabled) async {
    await _prefs.setBool(_speechEnabledKey, enabled);
  }

  Future<void> setVoiceLanguage(String language) async {
    await _prefs.setString(_voiceLanguageKey, language);
    await _flutterTts.setLanguage(language);
  }

  Future<void> setSpeechLanguage(String language) async {
    await _prefs.setString(_speechLanguageKey, language);
  }

  // Speech to text methods
  Future<bool> startListening({
    required Function(String) onResult,
    Function(String)? onPartialResult,
    Duration listenDuration = const Duration(seconds: 30),
  }) async {
    if (!_isInitialized || !speechEnabled || _isListening) {
      return false;
    }

    try {
      _isListening = await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          } else if (onPartialResult != null) {
            onPartialResult(result.recognizedWords);
          }
        },
        listenFor: listenDuration,
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: speechLanguage,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      );

      return _isListening;
    } catch (e) {
      print('Failed to start listening: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  Future<void> cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      _isListening = false;
    }
  }

  // Text to speech methods
  Future<void> speak(String text) async {
    if (!voiceEnabled || !_isInitialized) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('Failed to speak text: $e');
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('Failed to stop speaking: $e');
    }
  }

  Future<void> pauseSpeaking() async {
    try {
      await _flutterTts.pause();
    } catch (e) {
      print('Failed to pause speaking: $e');
    }
  }

  Future<void> resumeSpeaking() async {
    try {
      // FlutterTts doesn't have a resume method, use speak again if needed
      // This is a limitation of the current TTS implementation
      print('Resume speaking not supported by current TTS implementation');
    } catch (e) {
      print('Failed to resume speaking: $e');
    }
  }

  // Get available languages
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _speechToText.locales();
      return languages.map((locale) => locale.localeId).toList();
    } catch (e) {
      print('Failed to get available languages: $e');
      return ['en-US'];
    }
  }

  Future<List<String>> getAvailableVoiceLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages.whereType<String>().toList();
    } catch (e) {
      print('Failed to get available voice languages: $e');
      return ['en-US'];
    }
  }

  // Check permissions
  Future<bool> hasSpeechPermission() async {
    return await _speechToText.hasPermission;
  }

  // Cleanup
  void dispose() {
    stopListening();
    stopSpeaking();
  }
}
