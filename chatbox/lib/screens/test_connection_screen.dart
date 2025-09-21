// lib/screens/test_connection_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/constants/colors.dart';

class TestConnectionScreen extends StatelessWidget {
  const TestConnectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final streamService = Provider.of<StreamChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: streamService.isConnected
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.danger.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  streamService.isConnected ? Icons.check_circle : Icons.error,
                  size: 60,
                  color: streamService.isConnected
                      ? AppColors.success
                      : AppColors.danger,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Connection Status',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                streamService.isConnected ? 'Connected' : 'Not Connected',
                style: TextStyle(
                  fontSize: 18,
                  color: streamService.isConnected
                      ? AppColors.success
                      : AppColors.danger,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (streamService.currentUser != null) ...[
                Text(
                  'User: ${streamService.currentUser!.name ?? streamService.currentUser!.id}',
                  style: TextStyle(fontSize: 14, color: AppColors.grey600),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${streamService.currentUser!.id}',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await streamService.ensureConnected();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Connection verified successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Connection failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Test Connection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Back to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
