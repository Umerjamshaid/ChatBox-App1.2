// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/services/auth_service.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/token_service.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/constants/colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate immediately
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Small delay to show splash
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final streamService = Provider.of<StreamChatService>(
        context,
        listen: false,
      );

      final isLoggedIn = await authService.isUserLoggedIn();

      if (isLoggedIn) {
        // Try to connect to GetStream, but don't wait for it
        try {
          final currentUser = await authService.getCurrentChatUser();
          if (currentUser != null) {
            final token = await TokenService.generateToken(currentUser.id);
            streamService.connectUser(
              currentUser.id,
              token,
              name: currentUser.name,
            );
            authService.updateUserStatus(UserStatus.online);
          }
        } catch (e) {
          // Ignore GetStream errors for now
        }

        // Navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // Navigate to login
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      // On any error, go to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ChatBox',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect • Chat • Share',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
