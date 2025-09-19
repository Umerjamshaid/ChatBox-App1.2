// lib/screens/settings/language_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatbox/constants/colors.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'en'; // Default to English

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English', 'flag': '🇺🇸'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español', 'flag': '🇪🇸'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français', 'flag': '🇫🇷'},
    {'code': 'de', 'name': 'German', 'nativeName': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italian', 'nativeName': 'Italiano', 'flag': '🇮🇹'},
    {
      'code': 'pt',
      'name': 'Portuguese',
      'nativeName': 'Português',
      'flag': '🇵🇹',
    },
    {'code': 'ru', 'name': 'Russian', 'nativeName': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': 'Japanese', 'nativeName': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': 'Korean', 'nativeName': '한국어', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': 'Chinese', 'nativeName': '中文', 'flag': '🇨🇳'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية', 'flag': '🇸🇦'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _loadLanguagePreference();
  }

  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'en';
    });
  }

  Future<void> _saveLanguagePreference(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Language'), elevation: 0),
      body: ListView(
        children: [
          // Current Language Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Text(
                  _getCurrentLanguageFlag(),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Language',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _getCurrentLanguageName(),
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),

          // Language List Section
          _buildSectionHeader('Available Languages'),
          ..._languages.map((language) => _buildLanguageTile(language)),

          const SizedBox(height: 32),

          // Information Section
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
                  'Language Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your preferred language for the app interface. '
                  'Some features may require restarting the app to apply changes completely.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grey600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Restart Notice
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.warning),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Restart the app to apply language changes completely.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurface,
                      height: 1.4,
                    ),
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

  Widget _buildLanguageTile(Map<String, String> language) {
    final isSelected = language['code'] == _selectedLanguage;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.grey300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Text(language['flag']!, style: const TextStyle(fontSize: 24)),
        title: Text(
          language['name']!,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          language['nativeName']!,
          style: TextStyle(fontSize: 14, color: AppColors.grey600),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppColors.primary)
            : null,
        onTap: () {
          setState(() => _selectedLanguage = language['code']!);
          _saveLanguagePreference(language['code']!);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Language changed to ${language['name']}'),
              action: SnackBarAction(
                label: 'Restart',
                onPressed: () {
                  // TODO: Implement app restart
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Restart functionality coming soon!'),
                    ),
                  );
                },
              ),
            ),
          );
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getCurrentLanguageFlag() {
    final language = _languages.firstWhere(
      (lang) => lang['code'] == _selectedLanguage,
      orElse: () => _languages[0],
    );
    return language['flag']!;
  }

  String _getCurrentLanguageName() {
    final language = _languages.firstWhere(
      (lang) => lang['code'] == _selectedLanguage,
      orElse: () => _languages[0],
    );
    return language['name']!;
  }
}
