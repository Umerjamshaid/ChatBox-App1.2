// lib/constants/app_constants.dart
import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'ChatBox';
  static const String streamApiKey = 'h3bkh4ayyxaz'; // ✅ Stream API Key

  // ✅ Firebase configuration (from google-services.json)
  static const Map<String, String> firebaseConfig = {
    'apiKey': 'AIzaSyBxLkhWXJBOfPGdwrlG3I77sPepTavzpHE',
    'appId': '1:940806540627:android:597ba894b64c6b258765a6',
    'messagingSenderId': '940806540627',
    'projectId': 'chatbox-dd7b7',
    'authDomain': 'chatbox-dd7b7.firebaseapp.com',
    'storageBucket': 'chatbox-dd7b7.firebasestorage.app',
  };

  // ✅ GetStream configuration
  // Replace this with your actual GetStream API secret
  static const String streamApiSecret =
      'vvpx83p7p86q7mgt7psaqw7hfjq86hqejzugxsezxqfxyfgz2sffvvgmv6q79qbq'; // Replace with your actual secret

  // App theme colors based on your UI
  static const Color primaryColor = Color(0xFF0066FF);
  static const Color secondaryColor = Color(0xFF6C757D);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF212121);

  // Default user status messages
  static const List<String> defaultStatuses = [
    "Never give up",
    "Be your own hero",
    "Keep working",
    "Make yourself proud",
    "Life is beautiful",
    "Flowers are beautiful",
  ];
}
