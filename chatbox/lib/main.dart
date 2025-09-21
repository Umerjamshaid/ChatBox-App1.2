// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'services/stream_chat_service.dart';
import 'services/auth_service.dart';
import 'services/error_handler.dart';
import 'services/storage_service.dart';
import 'services/scheduled_message_service.dart';
import 'providers/theme_provider.dart';
import 'services/backup_service.dart';
import 'services/translation_service.dart';
import 'services/speech_service.dart';
import 'services/encryption_service.dart';
import 'services/emoji_service.dart';
import 'services/shortcuts_service.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/debug_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/settings/language_settings_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/blocked_users_screen.dart';
import 'screens/settings/backup_settings_screen.dart';
import 'screens/settings/translation_settings_screen.dart';
import 'screens/settings/speech_settings_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'widgets/connection_wrapper.dart';
import 'screens/test_connection_screen.dart';

// Static flag to track Firebase initialization state
bool _firebaseInitialized = false;

Future<void> _initializeFirebase() async {
  debugPrint('Firebase initialization: Starting...');
  debugPrint('Firebase apps count before init: ${Firebase.apps.length}');

  // Initialize Firebase only once using static flag
  if (!_firebaseInitialized) {
    try {
      debugPrint('Firebase initialization: Calling initializeApp...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _firebaseInitialized = true;
      debugPrint('Firebase initialized successfully');
      debugPrint('Firebase apps count after init: ${Firebase.apps.length}');
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint(
          'Firebase already initialized (duplicate-app), continuing...',
        );
        _firebaseInitialized = true; // Mark as initialized even on duplicate
        debugPrint('Firebase apps count on duplicate: ${Firebase.apps.length}');
      } else {
        debugPrint('Firebase initialization error: ${e.code} - ${e.message}');
        // Don't rethrow - allow app to continue with limited functionality
      }
    } catch (e) {
      debugPrint('Unexpected Firebase error: $e');
      // Don't rethrow - allow app to continue
    }
  } else {
    debugPrint(
      'Firebase already initialized (static flag), skipping initialization',
    );
    debugPrint('Firebase apps count: ${Firebase.apps.length}');
  }

  debugPrint('Firebase initialization: Complete');
}

void main() async {
  debugPrint('ChatBox: Starting application...');
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with comprehensive error handling
  await _initializeFirebase();

  debugPrint('ChatBox: Running app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Services
        Provider<StreamChatService>(create: (_) => StreamChatService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<ErrorHandler>(create: (_) => ErrorHandler()),
        // Scheduled Message Service (async initialization)
        FutureProvider<ScheduledMessageService?>(
          create: (_) async {
            final prefs = await SharedPreferences.getInstance();
            final service = ScheduledMessageService(prefs);
            service.startScheduler(); // Start the background scheduler
            return service;
          },
          initialData: null,
        ),
        // Theme Provider
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        // Backup Service
        Provider<BackupService>(create: (_) => BackupService()),
        // Translation Service (async initialization)
        FutureProvider<TranslationService?>(
          create: (_) async {
            final prefs = await SharedPreferences.getInstance();
            return TranslationService(prefs);
          },
          initialData: null,
        ),
        // Speech Service (async initialization)
        FutureProvider<SpeechService?>(
          create: (_) async {
            final prefs = await SharedPreferences.getInstance();
            final service = SpeechService(prefs);
            await service.initialize();
            return service;
          },
          initialData: null,
        ),
        // Encryption Service
        FutureProvider<EncryptionService?>(
          create: (_) async {
            final prefs = await SharedPreferences.getInstance();
            return EncryptionService(prefs);
          },
          initialData: null,
        ),
        // Emoji Service
        FutureProvider<EmojiService?>(
          create: (_) async {
            final prefs = await SharedPreferences.getInstance();
            return EmojiService(prefs);
          },
          initialData: null,
        ),
        // Shortcuts Service
        FutureProvider<ShortcutsService?>(
          create: (_) async {
            final prefs = await SharedPreferences.getInstance();
            return ShortcutsService(prefs);
          },
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        theme: ThemeData(
          primaryColor: AppConstants.primaryColor,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppConstants.primaryColor,
            primary: AppConstants.primaryColor,
            secondary: AppConstants.secondaryColor,
            background: AppConstants.backgroundColor,
            surface: AppConstants.surfaceColor,
          ),
          fontFamily: 'Inter',
          appBarTheme: const AppBarTheme(
            backgroundColor: AppConstants.surfaceColor,
            foregroundColor: AppConstants.textColor,
            elevation: 0.5,
            centerTitle: true,
          ),
          scaffoldBackgroundColor: AppConstants.backgroundColor,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const MainNavigation(),
          '/debug': (context) => const DebugScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/privacy_settings': (context) => const PrivacySettingsScreen(),
          '/notification_settings': (context) =>
              const NotificationSettingsScreen(),
          '/theme_settings': (context) => const ThemeSettingsScreen(),
          '/language_settings': (context) => const LanguageSettingsScreen(),
          '/account_settings': (context) => const AccountSettingsScreen(),
          '/blocked_users': (context) => const BlockedUsersScreen(),
          '/backup_settings': (context) => const BackupSettingsScreen(),
          '/translation_settings': (context) =>
              const TranslationSettingsScreen(),
          '/speech_settings': (context) => const SpeechSettingsScreen(),
          '/test_connection': (context) => const TestConnectionScreen(),
        },
        onUnknownRoute: (settings) {
          debugPrint('Unknown route: ${settings.name}');
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        },
        builder: (context, child) {
          try {
            final streamService = Provider.of<StreamChatService>(
              context,
              listen: false,
            );
            return StreamChat(
              client: streamService.client,
              child: ConnectionWrapper(child: child ?? const SizedBox.shrink()),
            );
          } catch (e) {
            debugPrint('StreamChat initialization error: $e');
            // Return child without StreamChat wrapper if initialization fails
            return ConnectionWrapper(child: child ?? const SizedBox.shrink());
          }
        },
      ),
    );
  }
}
