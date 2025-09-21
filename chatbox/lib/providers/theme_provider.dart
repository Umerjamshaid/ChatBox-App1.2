// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatTheme {
  final String id;
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final String? wallpaperUrl;
  final bool isDark;

  const ChatTheme({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    this.wallpaperUrl,
    this.isDark = false,
  });

  // Predefined themes
  static const ChatTheme light = ChatTheme(
    id: 'light',
    name: 'Light',
    primaryColor: Color(0xFF007AFF),
    secondaryColor: Color(0xFF5856D6),
    backgroundColor: Color(0xFFE5E5EA),
    surfaceColor: Colors.white,
    textColor: Color(0xFF000000),
    isDark: false,
  );

  static const ChatTheme dark = ChatTheme(
    id: 'dark',
    name: 'Dark',
    primaryColor: Color(0xFF007AFF),
    secondaryColor: Color(0xFF5856D6),
    backgroundColor: Color(0xFF000000),
    surfaceColor: Color(0xFF1C1C1E),
    textColor: Color(0xFFFFFFFF),
    isDark: true,
  );

  static const ChatTheme blue = ChatTheme(
    id: 'blue',
    name: 'Blue Ocean',
    primaryColor: Color(0xFF0066CC),
    secondaryColor: Color(0xFF00A3CC),
    backgroundColor: Color(0xFFE6F3FF),
    surfaceColor: Colors.white,
    textColor: Color(0xFF003366),
    isDark: false,
  );

  static const ChatTheme purple = ChatTheme(
    id: 'purple',
    name: 'Purple Dream',
    primaryColor: Color(0xFF8B5CF6),
    secondaryColor: Color(0xFFA855F7),
    backgroundColor: Color(0xFFF3E8FF),
    surfaceColor: Colors.white,
    textColor: Color(0xFF581C87),
    isDark: false,
  );

  static const ChatTheme green = ChatTheme(
    id: 'green',
    name: 'Forest Green',
    primaryColor: Color(0xFF059669),
    secondaryColor: Color(0xFF10B981),
    backgroundColor: Color(0xFFECFDF5),
    surfaceColor: Colors.white,
    textColor: Color(0xFF064E3B),
    isDark: false,
  );

  static List<ChatTheme> get predefinedThemes => [
    light,
    dark,
    blue,
    purple,
    green,
  ];
}

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  static const String _wallpaperKey = 'chat_wallpaper';

  ChatTheme _currentTheme = ChatTheme.light;
  String? _wallpaperUrl;

  ChatTheme get currentTheme => _currentTheme;
  String? get wallpaperUrl => _wallpaperUrl;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(_themeKey) ?? 'light';
    final wallpaper = prefs.getString(_wallpaperKey);

    _currentTheme = ChatTheme.predefinedThemes.firstWhere(
      (theme) => theme.id == themeId,
      orElse: () => ChatTheme.light,
    );

    _wallpaperUrl = wallpaper;
    notifyListeners();
  }

  Future<void> setTheme(ChatTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.id);
    notifyListeners();
  }

  Future<void> setWallpaper(String? url) async {
    _wallpaperUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null) {
      await prefs.setString(_wallpaperKey, url);
    } else {
      await prefs.remove(_wallpaperKey);
    }
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _currentTheme = ChatTheme.light;
    _wallpaperUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, 'light');
    await prefs.remove(_wallpaperKey);
    notifyListeners();
  }

  ThemeData getThemeData() {
    return ThemeData(
      primaryColor: _currentTheme.primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentTheme.primaryColor,
        brightness: _currentTheme.isDark ? Brightness.dark : Brightness.light,
        primary: _currentTheme.primaryColor,
        secondary: _currentTheme.secondaryColor,
        background: _currentTheme.backgroundColor,
        surface: _currentTheme.surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: _currentTheme.textColor,
        onSurface: _currentTheme.textColor,
      ),
      scaffoldBackgroundColor: _currentTheme.backgroundColor,
      appBarTheme: AppBarTheme(
        backgroundColor: _currentTheme.surfaceColor,
        foregroundColor: _currentTheme.textColor,
        elevation: 0,
      ),
      cardColor: _currentTheme.surfaceColor,
      dialogBackgroundColor: _currentTheme.surfaceColor,
      fontFamily: 'Inter',
      useMaterial3: true,
    );
  }
}
