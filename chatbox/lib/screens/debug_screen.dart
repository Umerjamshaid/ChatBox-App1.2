// lib/screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/auth_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic> _connectionStatus = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() => _isLoading = true);

    try {
      final streamService = Provider.of<StreamChatService>(
        context,
        listen: false,
      );
      final authService = Provider.of<AuthService>(context, listen: false);

      // Check basic connection status
      final status = {
        'client_initialized':
            true, // Client is always initialized if we get here
        'user_connected': streamService.client.state.currentUser != null,
        'current_user_id': streamService.client.state.currentUser?.id ?? 'None',
        'current_user_name':
            streamService.client.state.currentUser?.name ?? 'None',
        'api_key': 'Configured in app_constants.dart',
        'ws_connection': streamService.client.wsConnectionStatus.name,
        'firebase_user': authService.getCurrentUser()?.email ?? 'Not logged in',
        'is_user_logged_in': await authService.isUserLoggedIn(),
      };

      setState(() {
        _connectionStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _connectionStatus = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GetStream Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkConnection,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 20),
                  _buildTroubleshootingGuide(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusItem(
              'Client Initialized',
              _connectionStatus['client_initialized'] ?? false,
            ),
            _buildStatusItem(
              'User Connected',
              _connectionStatus['user_connected'] ?? false,
            ),
            _buildStatusItem(
              'Firebase User Logged In',
              _connectionStatus['is_user_logged_in'] ?? false,
            ),
            const Divider(),
            _buildInfoItem(
              'API Key',
              _connectionStatus['api_key'] ?? 'Unknown',
            ),
            _buildInfoItem(
              'User ID',
              _connectionStatus['current_user_id'] ?? 'Unknown',
            ),
            _buildInfoItem(
              'User Name',
              _connectionStatus['current_user_name'] ?? 'Unknown',
            ),
            _buildInfoItem(
              'Firebase User',
              _connectionStatus['firebase_user'] ?? 'Unknown',
            ),
            _buildInfoItem(
              'WS Connection',
              _connectionStatus['ws_connection'] ?? 'Unknown',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.error,
            color: status ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingGuide() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Troubleshooting Guide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTroubleshootingItem(
              'API Key Issue',
              'Check that the API key in app_constants.dart matches your GetStream dashboard',
            ),
            _buildTroubleshootingItem(
              'User Not Connected',
              'Make sure you are logged in and the authentication flow is working',
            ),
            _buildTroubleshootingItem(
              'Network Issues',
              'Verify your internet connection and check if GetStream servers are accessible',
            ),
            _buildTroubleshootingItem(
              'Firebase Auth',
              'Ensure Firebase authentication is working properly',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkConnection,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }
}
