// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/services/auth_service.dart';
import 'package:chatbox/constants/app_constants.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final connectionStatus = authService.getConnectionStatus();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatBox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Connection Status',
            onPressed: () {
              // Force rebuild to refresh status
              (context as Element).markNeedsBuild();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Welcome to ChatBox!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Connection Status Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔗 Connection Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusRow(
                      'Firebase User',
                      connectionStatus['firebaseUser'] ?? 'Not connected',
                    ),
                    _buildStatusRow(
                      'Firebase Initialized',
                      connectionStatus['firebaseInitialized']
                          ? '✅ Yes'
                          : '❌ No',
                    ),
                    _buildStatusRow(
                      'GetStream Connected',
                      connectionStatus['streamConnected'] ? '✅ Yes' : '❌ No',
                    ),
                    _buildStatusRow(
                      'GetStream User',
                      connectionStatus['streamUser'] ?? 'Not connected',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // API Configuration Status
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔑 API Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildStatusRow('API Key', 'h3bkh4ayyxaz'),
                    _buildStatusRow(
                      'API Secret',
                      AppConstants.streamApiSecret ==
                              'your-getstream-api-secret-here'
                          ? '❌ Not configured'
                          : '✅ Configured',
                    ),
                    _buildStatusRow(
                      'Token Type',
                      AppConstants.streamApiSecret ==
                              'your-getstream-api-secret-here'
                          ? 'Dev Token'
                          : 'JWT Token',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            if (!connectionStatus['streamConnected'])
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚠️ Connection Issues',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'To fix GetStream connection:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Get your GetStream API Secret from your dashboard',
                      ),
                      const Text(
                        '2. Replace "your-getstream-api-secret-here" in app_constants.dart',
                      ),
                      const Text('3. Restart the app'),
                      const SizedBox(height: 10),
                      const Text(
                        'Currently using development tokens as fallback.',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Test Chat Button
            if (connectionStatus['streamConnected'])
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to chat screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Chat functionality coming soon!'),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text('Start Chatting'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: TextStyle(
              color: value == 'Not connected' || value == 'No'
                  ? Colors.red
                  : Colors.green,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
