// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.system;
  bool _useMaterial3 = true;

  AppTheme get currentTheme => _currentTheme;
  bool get useMaterial3 => _useMaterial3;

  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeMode.light;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.system:
        return ThemeMode.system;
    }
  }

  ThemeProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('app_theme') ?? 'system';
    final useMaterial3 = prefs.getBool('use_material3') ?? true;

    _currentTheme = AppTheme.values.firstWhere(
      (theme) => theme.toString() == 'AppTheme.$themeString',
      orElse: () => AppTheme.system,
    );
    _useMaterial3 = useMaterial3;

    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme', theme.toString().split('.').last);
    notifyListeners();
  }

  Future<void> toggleMaterial3() async {
    _useMaterial3 = !_useMaterial3;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_material3', _useMaterial3);
    notifyListeners();
  }

  String getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.system:
        return 'System';
    }
  }

  IconData getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.system:
        return Icons.settings_brightness;
    }
  }
}
