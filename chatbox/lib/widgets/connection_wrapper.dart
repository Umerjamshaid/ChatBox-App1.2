// lib/widgets/connection_wrapper.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chatbox/services/auth_service.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/token_service.dart';
import 'package:chatbox/services/chat_service.dart';
import 'package:chatbox/constants/colors.dart';

class ConnectionWrapper extends StatefulWidget {
  final Widget child;

  const ConnectionWrapper({super.key, required this.child});

  @override
  State<ConnectionWrapper> createState() => _ConnectionWrapperState();
}

class _ConnectionWrapperState extends State<ConnectionWrapper> {
  bool _isConnecting = false;
  bool _wasOffline = false;
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _setupConnectivityMonitoring();
    // Connection will be checked when auth state changes
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _setupConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final result = results.isNotEmpty
          ? results.first
          : ConnectivityResult.none;
      final isOnline = result != ConnectivityResult.none;

      if (isOnline && _wasOffline) {
        // Came back online, trigger sync
        _wasOffline = false;
        await _syncWhenOnline();
      } else if (!isOnline) {
        _wasOffline = true;
      }
    });
  }

  Future<void> _syncWhenOnline() async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.processQueuedMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Synced offline messages'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Failed to sync when coming online: $e');
    }
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

        // Always show the child widget, even when not connected
        // Add an offline indicator banner if not connected
        return Stack(
          children: [
            widget.child,
            if (!streamService.isConnected)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: AppColors.danger,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for network...',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _checkConnection,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
