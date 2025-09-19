// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'services/stream_chat_service.dart';
import 'services/auth_service.dart';
import 'services/error_handler.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/debug_screen.dart';
import 'providers/theme_provider.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/privacy_settings_screen.dart';
import 'screens/settings/notification_settings_screen.dart';
import 'screens/settings/theme_settings_screen.dart';
import 'screens/settings/language_settings_screen.dart';
import 'screens/settings/account_settings_screen.dart';
import 'screens/settings/blocked_users_screen.dart';

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
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/debug': (context) => const DebugScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/privacy_settings': (context) => const PrivacySettingsScreen(),
          '/notification_settings': (context) =>
              const NotificationSettingsScreen(),
          '/theme_settings': (context) => const ThemeSettingsScreen(),
          '/language_settings': (context) => const LanguageSettingsScreen(),
          '/account_settings': (context) => const AccountSettingsScreen(),
          '/blocked_users': (context) => const BlockedUsersScreen(),
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
            return StreamChat(client: streamService.client, child: child);
          } catch (e) {
            debugPrint('StreamChat initialization error: $e');
            // Return child without StreamChat wrapper if initialization fails
            return child ?? const SizedBox.shrink();
          }
        },
      ),
    );
  }
}
