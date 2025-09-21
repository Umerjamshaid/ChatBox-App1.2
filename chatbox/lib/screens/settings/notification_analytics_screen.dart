// lib/screens/settings/notification_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/notification_service.dart';

class NotificationAnalyticsScreen extends StatefulWidget {
  const NotificationAnalyticsScreen({super.key});

  @override
  State<NotificationAnalyticsScreen> createState() =>
      _NotificationAnalyticsScreenState();
}

class _NotificationAnalyticsScreenState
    extends State<NotificationAnalyticsScreen> {
  late NotificationService _notificationService;
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    // In a real implementation, you'd get this from the service
    // For now, we'll simulate some data
    setState(() {
      _analytics = {
        'totalSent': 45,
        'totalOpened': 32,
        'openRate': 0.71,
        'categoryStats': {'messages': 28, 'mentions': 12, 'groups': 5},
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Analytics'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall Stats
          _buildSectionHeader('Overall Statistics'),
          _buildStatCard(
            'Total Notifications Sent',
            _analytics['totalSent']?.toString() ?? '0',
            Icons.send,
          ),
          _buildStatCard(
            'Notifications Opened',
            _analytics['totalOpened']?.toString() ?? '0',
            Icons.visibility,
          ),
          _buildStatCard(
            'Open Rate',
            '${((_analytics['openRate'] as double? ?? 0) * 100).toStringAsFixed(1)}%',
            Icons.trending_up,
          ),

          const SizedBox(height: 24),

          // Category Breakdown
          _buildSectionHeader('By Category'),
          if (_analytics['categoryStats'] != null) ...[
            ...(_analytics['categoryStats'] as Map<String, dynamic>).entries
                .map(
                  (entry) =>
                      _buildCategoryStat(entry.key, entry.value.toString()),
                ),
          ],

          const SizedBox(height: 24),

          // Reset Analytics
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton.icon(
              onPressed: _resetAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Analytics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 14, color: AppColors.grey600),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStat(String category, String count) {
    return ListTile(
      leading: Icon(
        category == 'messages'
            ? Icons.message
            : category == 'mentions'
            ? Icons.alternate_email
            : Icons.group,
        color: AppColors.primary,
      ),
      title: Text(
        category.substring(0, 1).toUpperCase() + category.substring(1),
      ),
      trailing: Text(
        count,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  void _resetAnalytics() {
    // In a real implementation, this would reset the analytics data
    setState(() {
      _analytics = {
        'totalSent': 0,
        'totalOpened': 0,
        'openRate': 0.0,
        'categoryStats': {'messages': 0, 'mentions': 0, 'groups': 0},
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics reset successfully')),
    );
  }
}
