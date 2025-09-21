// lib/screens/settings/speech_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/speech_service.dart';

class SpeechSettingsScreen extends StatefulWidget {
  const SpeechSettingsScreen({super.key});

  @override
  State<SpeechSettingsScreen> createState() => _SpeechSettingsScreenState();
}

class _SpeechSettingsScreenState extends State<SpeechSettingsScreen> {
  late SpeechService _speechService;
  bool _isLoading = true;
  bool _voiceEnabled = true;
  bool _speechEnabled = true;
  String _voiceLanguage = 'en-US';
  String _speechLanguage = 'en-US';
  List<String> _availableVoiceLanguages = [];
  List<String> _availableSpeechLanguages = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final speechService = context.read<SpeechService?>();
    if (speechService != null) {
      setState(() {
        _speechService = speechService;
        _voiceEnabled = _speechService.voiceEnabled;
        _speechEnabled = _speechService.speechEnabled;
        _voiceLanguage = _speechService.voiceLanguage;
        _speechLanguage = _speechService.speechLanguage;
        _isLoading = false;
      });

      // Load available languages
      _availableVoiceLanguages = await _speechService
          .getAvailableVoiceLanguages();
      _availableSpeechLanguages = await _speechService.getAvailableLanguages();

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Speech Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Speech Settings'), elevation: 0),
      body: ListView(
        children: [
          // Voice Features
          _buildSectionHeader('Voice Features'),

          // Text-to-Speech Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              title: const Text('Text-to-Speech'),
              subtitle: const Text('Read messages aloud'),
              value: _voiceEnabled,
              onChanged: (value) async {
                setState(() => _voiceEnabled = value);
                await _speechService.setVoiceEnabled(value);
              },
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Speech-to-Text Toggle
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: SwitchListTile(
              title: const Text('Speech-to-Text'),
              subtitle: const Text('Convert speech to text input'),
              value: _speechEnabled,
              onChanged: (value) async {
                setState(() => _speechEnabled = value);
                await _speechService.setSpeechEnabled(value);
              },
            ),
          ),

          // Language Settings
          _buildSectionHeader('Language Settings'),

          // Voice Language
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: const Text('Voice Language'),
              subtitle: Text(_getLanguageDisplayName(_voiceLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(true),
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Speech Recognition Language
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: const Text('Speech Recognition Language'),
              subtitle: Text(_getLanguageDisplayName(_speechLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(false),
            ),
          ),

          // Test Features
          _buildSectionHeader('Test Features'),

          // Test Speech-to-Text
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _testSpeechToText,
              icon: const Icon(Icons.mic),
              label: const Text('Test Speech-to-Text'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Test Text-to-Speech
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _testTextToSpeech(),
              icon: const Icon(Icons.volume_up),
              label: const Text('Test Text-to-Speech'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // Permissions
          _buildSectionHeader('Permissions'),

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Microphone Permission',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Speech-to-text requires microphone access. '
                  'Make sure to grant microphone permission in your device settings.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<bool>(
                  future: _speechService.hasSpeechPermission(),
                  builder: (context, snapshot) {
                    final hasPermission = snapshot.data ?? false;
                    return Row(
                      children: [
                        Icon(
                          hasPermission ? Icons.check_circle : Icons.error,
                          color: hasPermission ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasPermission
                              ? 'Microphone permission granted'
                              : 'Microphone permission required',
                          style: TextStyle(
                            color: hasPermission ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Information
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Speech Features Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Text-to-speech reads incoming messages aloud\n'
                  '• Speech-to-text converts your voice to text input\n'
                  '• Language settings affect both recognition and synthesis\n'
                  '• Quality depends on your device and network connection\n'
                  '• Some languages may have limited support',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getLanguageDisplayName(String code) {
    // Simple language name mapping - in a real app, you'd use a proper language library
    final languageNames = {
      'en-US': 'English (US)',
      'en-GB': 'English (UK)',
      'es-ES': 'Spanish (Spain)',
      'es-US': 'Spanish (US)',
      'fr-FR': 'French (France)',
      'de-DE': 'German (Germany)',
      'it-IT': 'Italian (Italy)',
      'pt-BR': 'Portuguese (Brazil)',
      'pt-PT': 'Portuguese (Portugal)',
      'ru-RU': 'Russian (Russia)',
      'ja-JP': 'Japanese (Japan)',
      'ko-KR': 'Korean (Korea)',
      'zh-CN': 'Chinese (Simplified)',
      'zh-TW': 'Chinese (Traditional)',
      'ar-SA': 'Arabic (Saudi Arabia)',
      'hi-IN': 'Hindi (India)',
    };

    return languageNames[code] ?? code;
  }

  void _showLanguagePicker(bool isVoice) {
    final languages = isVoice
        ? _availableVoiceLanguages
        : _availableSpeechLanguages;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isVoice ? 'Voice Language' : 'Speech Recognition Language',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: languages.length,
                itemBuilder: (context, index) {
                  final code = languages[index];
                  final isSelected = isVoice
                      ? code == _voiceLanguage
                      : code == _speechLanguage;

                  return ListTile(
                    title: Text(_getLanguageDisplayName(code)),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      if (isVoice) {
                        setState(() => _voiceLanguage = code);
                        await _speechService.setVoiceLanguage(code);
                      } else {
                        setState(() => _speechLanguage = code);
                        await _speechService.setSpeechLanguage(code);
                      }
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testSpeechToText() async {
    final result = await _speechService.startListening(
      onResult: (text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Recognized: $text')));
      },
      listenDuration: const Duration(seconds: 5),
    );

    if (!result) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Speech recognition not available')),
      );
    }
  }

  Future<void> _testTextToSpeech() async {
    const testText = 'Hello! This is a test of text-to-speech functionality.';
    await _speechService.speak(testText);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Playing test speech...')));
  }
}
