// lib/screens/settings/translation_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/translation_service.dart';

class TranslationSettingsScreen extends StatefulWidget {
  const TranslationSettingsScreen({super.key});

  @override
  State<TranslationSettingsScreen> createState() =>
      _TranslationSettingsScreenState();
}

class _TranslationSettingsScreenState extends State<TranslationSettingsScreen> {
  late TranslationService _translationService;
  bool _isLoading = true;
  String _sourceLanguage = 'auto';
  String _targetLanguage = 'en';
  bool _autoTranslate = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final translationService = context.read<TranslationService?>();
    if (translationService != null) {
      setState(() {
        _translationService = translationService;
        _sourceLanguage = _translationService.sourceLanguage;
        _targetLanguage = _translationService.targetLanguage;
        _autoTranslate = _translationService.autoTranslateEnabled;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Translation Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Translation Settings'), elevation: 0),
      body: ListView(
        children: [
          // Auto Translate Toggle
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Auto Translate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Switch(
                      value: _autoTranslate,
                      onChanged: (value) async {
                        setState(() => _autoTranslate = value);
                        await _translationService.setAutoTranslate(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Automatically translate messages from other languages',
                  style: TextStyle(fontSize: 14, color: AppColors.grey600),
                ),
              ],
            ),
          ),

          // Language Settings
          _buildSectionHeader('Language Settings'),

          // Source Language
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: const Text('Source Language'),
              subtitle: Text(_getLanguageDisplayName(_sourceLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(true),
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Target Language
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: ListTile(
              title: const Text('Target Language'),
              subtitle: Text(_getLanguageDisplayName(_targetLanguage)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguagePicker(false),
            ),
          ),

          // Test Translation
          _buildSectionHeader('Test Translation'),
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
                  'Test your translation settings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _testTranslation,
                  icon: const Icon(Icons.translate),
                  label: const Text('Test Translation'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
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
                  'Translation Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Translations are powered by Google Translate\n'
                  '• Auto-translate works for messages in other languages\n'
                  '• You can manually translate any message by long-pressing it\n'
                  '• Translation quality may vary by language pair',
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
    if (code == 'auto') return 'Auto Detect';
    return _translationService.getLanguageName(code);
  }

  void _showLanguagePicker(bool isSource) {
    final languages = ['auto', ...TranslationService.supportedLanguages.keys];

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
                  isSource ? 'Source Language' : 'Target Language',
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
                  final isSelected = isSource
                      ? code == _sourceLanguage
                      : code == _targetLanguage;

                  return ListTile(
                    title: Text(_getLanguageDisplayName(code)),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      if (isSource) {
                        setState(() => _sourceLanguage = code);
                        await _translationService.setSourceLanguage(code);
                      } else {
                        setState(() => _targetLanguage = code);
                        await _translationService.setTargetLanguage(code);
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

  Future<void> _testTranslation() async {
    const testText = 'Hello, how are you today?';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation Test'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Original: $testText'),
            const SizedBox(height: 16),
            FutureBuilder<String>(
              future: _translationService.translateText(
                testText,
                from: _sourceLanguage,
                to: _targetLanguage,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Translating...');
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else {
                  return Text('Translated: ${snapshot.data}');
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
