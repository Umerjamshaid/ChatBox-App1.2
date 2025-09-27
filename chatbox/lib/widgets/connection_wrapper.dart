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

class _ConnectionWrapperState extends State<ConnectionWrapper>
    with WidgetsBindingObserver {
  bool _isConnecting = false;
  bool _wasOffline = false;
  DateTime? _lastConnectionAttempt;
  static const Duration _connectionCooldown = Duration(
    seconds: 30,
  ); // Prevent excessive reconnection attempts
  late Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _setupConnectivityMonitoring();
    WidgetsBinding.instance.addObserver(this);
    // Connection will be checked when auth state changes
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final streamService = Provider.of<StreamChatService>(
      context,
      listen: false,
    );

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // App is going to background or being terminated
        // Don't disconnect here as it might cause issues with push notifications
        break;
      case AppLifecycleState.resumed:
        // App came back to foreground
        // Only check connection if we haven't attempted recently
        if (_lastConnectionAttempt == null ||
            DateTime.now().difference(_lastConnectionAttempt!) >
                _connectionCooldown) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkConnection();
          });
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Handle other states if needed
        break;
    }
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

      // Only attempt connection if cooldown has passed
      if (_lastConnectionAttempt == null ||
          DateTime.now().difference(_lastConnectionAttempt!) >
              _connectionCooldown) {
        await _checkConnection();
      }

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
    print('ConnectionWrapper: _checkConnection called');
    final authService = Provider.of<AuthService>(context, listen: false);
    final streamService = Provider.of<StreamChatService>(
      context,
      listen: false,
    );

    final firebaseUser = authService.getCurrentUser();
    print(
      'ConnectionWrapper: Firebase user: ${firebaseUser?.uid}, Stream connected: ${streamService.isConnected}',
    );

    // Check if we're already connecting or if connection attempt was too recent
    if (_isConnecting ||
        firebaseUser == null ||
        streamService.isConnected ||
        (_lastConnectionAttempt != null &&
            DateTime.now().difference(_lastConnectionAttempt!) <
                _connectionCooldown)) {
      print(
        'ConnectionWrapper: Skipping connection attempt - conditions not met',
      );
      return;
    }

    _lastConnectionAttempt = DateTime.now();
    setState(() => _isConnecting = true);

    try {
      print('ConnectionWrapper: Generating token for user ${firebaseUser.uid}');
      final token = await TokenService.generateToken(firebaseUser.uid);
      print('ConnectionWrapper: Token generated, connecting to StreamChat...');

      await streamService.connectUser(
        firebaseUser.uid,
        token,
        name: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
        image: firebaseUser.photoURL,
      );

      print('ConnectionWrapper: Successfully connected to StreamChat');
      print(
        'ConnectionWrapper: Stream service isConnected: ${streamService.isConnected}',
      );
      _lastConnectionAttempt = null; // Reset on success
    } catch (e) {
      print('ConnectionWrapper: Failed to reconnect: $e');

      // Extract user-friendly error message
      String errorMessage = 'Connection failed';
      bool isRateLimited = false;

      if (e.toString().contains('Too many requests') ||
          e.toString().contains('429') ||
          e.toString().contains('rate limit')) {
        errorMessage =
            'Too many connection attempts. Please wait before retrying.';
        isRateLimited = true;
        // Extend cooldown for rate limiting
        _lastConnectionAttempt = DateTime.now().add(const Duration(minutes: 2));
      } else if (e.toString().contains('already exist')) {
        errorMessage =
            'Multiple devices connected. This is normal for multi-device usage.';
        // Don't show error for multi-device connections
        return;
      } else if (e.toString().contains('already getting connected')) {
        errorMessage = 'Already connecting. Please wait.';
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage = 'Network error. Check your connection.';
      }

      // Only show error snackbar for non-multi-device issues
      if (mounted &&
          !isRateLimited &&
          !e.toString().contains('already exist')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            action: SnackBarAction(label: 'Retry', onPressed: _checkConnection),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
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

        // If user is authenticated but not connected, try to connect (with cooldown)
        if (!streamService.isConnected &&
            !_isConnecting &&
            (_lastConnectionAttempt == null ||
                DateTime.now().difference(_lastConnectionAttempt!) >
                    _connectionCooldown)) {
          print(
            'ConnectionWrapper: User authenticated but not connected, starting connection...',
          );
          // Start connection process
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkConnection();
          });
        } else if (streamService.isConnected) {
          print('ConnectionWrapper: User is connected, showing chat interface');
        } else if (_isConnecting) {
          print(
            'ConnectionWrapper: Currently connecting, showing connecting screen',
          );
        } else {
          print(
            'ConnectionWrapper: Connection cooldown active or other condition preventing connection',
          );
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
