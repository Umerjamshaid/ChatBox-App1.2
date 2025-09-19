// lib/screens/settings/blocked_users_screen.dart
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  // Mock data - in a real app, this would come from a service
  final List<Map<String, dynamic>> _blockedUsers = [
    {
      'id': '1',
      'name': 'John Doe',
      'email': 'john@example.com',
      'blockedDate': DateTime.now().subtract(const Duration(days: 5)),
      'avatar': null,
    },
    {
      'id': '2',
      'name': 'Jane Smith',
      'email': 'jane@example.com',
      'blockedDate': DateTime.now().subtract(const Duration(days: 12)),
      'avatar': null,
    },
    {
      'id': '3',
      'name': 'Bob Johnson',
      'email': 'bob@example.com',
      'blockedDate': DateTime.now().subtract(const Duration(days: 1)),
      'avatar': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users'), elevation: 0),
      body: _blockedUsers.isEmpty
          ? _buildEmptyState()
          : _buildBlockedUsersList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No blocked users',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Users you block will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return ListView(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${_blockedUsers.length} blocked user${_blockedUsers.length == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Blocked users list
        ..._blockedUsers.map((user) => _buildBlockedUserTile(user)),

        const SizedBox(height: 32),

        // Information section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Blocking',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Blocked users cannot send you messages, see your online status, '
                'or add you to groups. You can unblock them at any time.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.grey600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBlockedUserTile(Map<String, dynamic> user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.grey200,
          backgroundImage: user['avatar'] != null
              ? NetworkImage(user['avatar'])
              : null,
          child: user['avatar'] == null
              ? Text(
                  user['name'].substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: AppColors.grey600,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                )
              : null,
        ),
        title: Text(
          user['name'],
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user['email'],
              style: TextStyle(fontSize: 14, color: AppColors.grey600),
            ),
            const SizedBox(height: 4),
            Text(
              'Blocked ${_formatBlockedDate(user['blockedDate'])}',
              style: TextStyle(fontSize: 12, color: AppColors.grey500),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _unblockUser(user),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Unblock'),
        ),
      ),
    );
  }

  String _formatBlockedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    }
  }

  void _unblockUser(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock ${user['name']}? '
          'They will be able to send you messages and see your online status again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _blockedUsers.remove(user);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user['name']} has been unblocked')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
