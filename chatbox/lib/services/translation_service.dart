// lib/services/translation_service.dart
import 'package:translator/translator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TranslationService {
  static const String _sourceLanguageKey = 'translation_source_language';
  static const String _targetLanguageKey = 'translation_target_language';
  static const String _autoTranslateKey = 'auto_translate_enabled';

  final GoogleTranslator _translator = GoogleTranslator();
  final SharedPreferences _prefs;

  TranslationService(this._prefs);

  // Supported languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'ru': 'Russian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'tr': 'Turkish',
    'nl': 'Dutch',
    'sv': 'Swedish',
    'da': 'Danish',
    'no': 'Norwegian',
    'fi': 'Finnish',
    'pl': 'Polish',
    'cs': 'Czech',
    'hu': 'Hungarian',
    'ro': 'Romanian',
    'bg': 'Bulgarian',
    'hr': 'Croatian',
    'sl': 'Slovenian',
    'sk': 'Slovak',
    'et': 'Estonian',
    'lv': 'Latvian',
    'lt': 'Lithuanian',
    'el': 'Greek',
    'he': 'Hebrew',
    'th': 'Thai',
    'vi': 'Vietnamese',
    'id': 'Indonesian',
    'ms': 'Malay',
    'tl': 'Filipino',
  };

  String get sourceLanguage => _prefs.getString(_sourceLanguageKey) ?? 'auto';
  String get targetLanguage => _prefs.getString(_targetLanguageKey) ?? 'en';
  bool get autoTranslateEnabled => _prefs.getBool(_autoTranslateKey) ?? false;

  Future<void> setSourceLanguage(String language) async {
    await _prefs.setString(_sourceLanguageKey, language);
  }

  Future<void> setTargetLanguage(String language) async {
    await _prefs.setString(_targetLanguageKey, language);
  }

  Future<void> setAutoTranslate(bool enabled) async {
    await _prefs.setBool(_autoTranslateKey, enabled);
  }

  Future<String> translateText(String text, {String? from, String? to}) async {
    try {
      final sourceLang = from ?? sourceLanguage;
      final targetLang = to ?? targetLanguage;

      if (sourceLang == targetLang ||
          sourceLang == 'auto' && targetLang == 'en') {
        return text; // No translation needed
      }

      final translation = await _translator.translate(
        text,
        from: sourceLang == 'auto' ? 'auto' : sourceLang,
        to: targetLang,
      );

      return translation.text;
    } catch (e) {
      print('Translation failed: $e');
      return text; // Return original text on error
    }
  }

  Future<String> detectLanguage(String text) async {
    try {
      final detection = await _translator.translate(text, to: 'en');
      return detection.sourceLanguage.code;
    } catch (e) {
      print('Language detection failed: $e');
      return 'en'; // Default to English
    }
  }

  // Get language name from code
  String getLanguageName(String code) {
    return supportedLanguages[code] ?? 'Unknown';
  }

  // Check if text needs translation
  bool shouldTranslate(String text, {String? detectedLanguage}) {
    if (!autoTranslateEnabled) return false;

    final source = detectedLanguage ?? sourceLanguage;
    final target = targetLanguage;

    return source != target && source != 'auto';
  }
}
