// lib/screens/settings/privacy_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatbox/constants/colors.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showLastSeen = true;
  bool _showProfilePhoto = true;
  bool _showStatus = true;
  bool _showReadReceipts = false;
  bool _allowGroupInvites = true;
  String _profileVisibility = 'everyone'; // everyone, contacts, nobody

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showLastSeen = prefs.getBool('show_last_seen') ?? true;
      _showProfilePhoto = prefs.getBool('show_profile_photo') ?? true;
      _showStatus = prefs.getBool('show_status') ?? true;
      _showReadReceipts = prefs.getBool('show_read_receipts') ?? false;
      _allowGroupInvites = prefs.getBool('allow_group_invites') ?? true;
      _profileVisibility = prefs.getString('profile_visibility') ?? 'everyone';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings'), elevation: 0),
      body: ListView(
        children: [
          // Profile Privacy Section
          _buildSectionHeader('Profile Privacy'),
          _buildSwitchTile(
            title: 'Show Last Seen',
            subtitle: 'Let others see when you were last active',
            value: _showLastSeen,
            onChanged: (value) {
              setState(() => _showLastSeen = value);
              _saveSetting('show_last_seen', value);
            },
          ),
          _buildSwitchTile(
            title: 'Show Profile Photo',
            subtitle: 'Display your profile photo in chats',
            value: _showProfilePhoto,
            onChanged: (value) {
              setState(() => _showProfilePhoto = value);
              _saveSetting('show_profile_photo', value);
            },
          ),
          _buildSwitchTile(
            title: 'Show Status',
            subtitle: 'Let others see your status message',
            value: _showStatus,
            onChanged: (value) {
              setState(() => _showStatus = value);
              _saveSetting('show_status', value);
            },
          ),

          const Divider(),

          // Chat Privacy Section
          _buildSectionHeader('Chat Privacy'),
          _buildSwitchTile(
            title: 'Read Receipts',
            subtitle: 'Send read receipts for messages',
            value: _showReadReceipts,
            onChanged: (value) {
              setState(() => _showReadReceipts = value);
              _saveSetting('show_read_receipts', value);
            },
          ),

          const Divider(),

          // Groups & Invites Section
          _buildSectionHeader('Groups & Invites'),
          _buildSwitchTile(
            title: 'Allow Group Invites',
            subtitle: 'Let others add you to groups',
            value: _allowGroupInvites,
            onChanged: (value) {
              setState(() => _allowGroupInvites = value);
              _saveSetting('allow_group_invites', value);
            },
          ),

          const Divider(),

          // Profile Visibility Section
          _buildSectionHeader('Profile Visibility'),
          ListTile(
            title: const Text('Who can see my profile'),
            subtitle: Text(_getVisibilityText(_profileVisibility)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showVisibilityDialog,
          ),

          const Divider(),

          // Blocked Users Section
          _buildSectionHeader('Blocked Users'),
          ListTile(
            leading: Icon(Icons.block, color: AppColors.danger),
            title: const Text('Blocked Users'),
            subtitle: const Text('Manage blocked contacts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/blocked_users');
            },
          ),

          const SizedBox(height: 32),

          // Information Section
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
                  'Privacy Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your privacy settings help control what information is visible to other users. Changes may take a few minutes to apply across all your conversations.',
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
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 14, color: AppColors.grey600),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.primary,
    );
  }

  String _getVisibilityText(String visibility) {
    switch (visibility) {
      case 'everyone':
        return 'Everyone';
      case 'contacts':
        return 'My contacts only';
      case 'nobody':
        return 'Nobody';
      default:
        return 'Everyone';
    }
  }

  void _showVisibilityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Visibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Everyone'),
              subtitle: const Text('Anyone can see your profile'),
              value: 'everyone',
              groupValue: _profileVisibility,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _profileVisibility = value);
                  _saveSetting('profile_visibility', value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('My contacts only'),
              subtitle: const Text('Only people in your contacts'),
              value: 'contacts',
              groupValue: _profileVisibility,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _profileVisibility = value);
                  _saveSetting('profile_visibility', value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('Nobody'),
              subtitle: const Text('Hide your profile from everyone'),
              value: 'nobody',
              groupValue: _profileVisibility,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _profileVisibility = value);
                  _saveSetting('profile_visibility', value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
