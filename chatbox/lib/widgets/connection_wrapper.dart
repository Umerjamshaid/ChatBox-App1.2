// lib/widgets/connection_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatbox/services/auth_service.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/token_service.dart';
import 'package:chatbox/constants/colors.dart';

class ConnectionWrapper extends StatefulWidget {
  final Widget child;

  const ConnectionWrapper({super.key, required this.child});

  @override
  State<ConnectionWrapper> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends State<ConnectionWrapper> {
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // Connection will be checked when auth state changes
  }

  Future<void> _checkConnection() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final streamService = Provider.of<StreamChatService>(
      context,
      listen: false,
    );

    final firebaseUser = authService.getCurrentUser();

    if (firebaseUser != null && !streamService.isConnected) {
      setState(() => _isConnecting = true);

      try {
        print(
          'ConnectionWrapper: Generating token for user ${firebaseUser.uid}',
        );
        final token = await TokenService.generateToken(firebaseUser.uid);
        print(
          'ConnectionWrapper: Token generated, connecting to StreamChat...',
        );

        await streamService.connectUser(
          firebaseUser.uid,
          token,
          name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          image: firebaseUser.photoURL,
        );

        print('ConnectionWrapper: Successfully connected to StreamChat');
      } catch (e) {
        print('ConnectionWrapper: Failed to reconnect: $e');
        // Show error but don't crash the app
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connection failed: $e'),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: _checkConnection,
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final streamService = Provider.of<StreamChatService>(context);

    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;

        // If user is not authenticated, don't show connection wrapper
        if (user == null) {
          return widget.child;
        }

        // If user is authenticated but not connected, try to connect
        if (!streamService.isConnected && !_isConnecting) {
          // Start connection process
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkConnection();
          });
        }

        // Show connecting screen while connecting
        if (_isConnecting) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.chat, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connecting to chat service...',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                ],
              ),
            ),
          );
        }

        // Show connection lost screen if authenticated but not connected
        if (!streamService.isConnected) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.wifi_off,
                      size: 40,
                      color: AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Connection lost',
                    style: TextStyle(
                      fontSize: 20,
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to connect to chat service',
                    style: TextStyle(fontSize: 14, color: AppColors.grey600),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _checkConnection,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated and connected, show the child
        return widget.child;
      },
    );
  }
}
