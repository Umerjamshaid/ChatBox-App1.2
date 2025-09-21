// lib/screens/settings/notification_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/screens/settings/notification_analytics_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _messageNotifications = true;
  bool _groupNotifications = true;
  bool _mentionNotifications = true;
  bool _callNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _notificationSound = 'default';
  bool _dndEnabled = false;
  TimeOfDay? _dndStartTime;
  TimeOfDay? _dndEndTime;
  bool _showMessagePreview = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _messageNotifications = prefs.getBool('message_notifications') ?? true;
      _groupNotifications = prefs.getBool('group_notifications') ?? true;
      _mentionNotifications = prefs.getBool('mention_notifications') ?? true;
      _callNotifications = prefs.getBool('call_notifications') ?? true;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;
      _notificationSound = prefs.getString('notification_sound') ?? 'default';
      _dndEnabled = prefs.getBool('dnd_enabled') ?? false;
      _showMessagePreview = prefs.getBool('show_message_preview') ?? true;

      final dndStart = prefs.getString('dnd_start_time');
      final dndEnd = prefs.getString('dnd_end_time');

      if (dndStart != null) {
        final parts = dndStart.split(':');
        _dndStartTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      if (dndEnd != null) {
        final parts = dndEnd.split(':');
        _dndEndTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
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
      appBar: AppBar(title: const Text('Notification Settings'), elevation: 0),
      body: ListView(
        children: [
          // General Notifications Section
          _buildSectionHeader('General'),
          _buildSwitchTile(
            title: 'Push Notifications',
            subtitle: 'Receive notifications on your device',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() => _pushNotifications = value);
              _saveSetting('push_notifications', value);
            },
          ),

          const Divider(),

          // Message Notifications Section
          _buildSectionHeader('Messages'),
          _buildSwitchTile(
            title: 'Message Notifications',
            subtitle: 'Get notified for new messages',
            value: _messageNotifications,
            onChanged: (value) {
              setState(() => _messageNotifications = value);
              _saveSetting('message_notifications', value);
            },
          ),
          _buildSwitchTile(
            title: 'Group Notifications',
            subtitle: 'Get notified for group messages',
            value: _groupNotifications,
            onChanged: (value) {
              setState(() => _groupNotifications = value);
              _saveSetting('group_notifications', value);
            },
          ),
          _buildSwitchTile(
            title: '@Mentions',
            subtitle: 'Get notified when mentioned',
            value: _mentionNotifications,
            onChanged: (value) {
              setState(() => _mentionNotifications = value);
              _saveSetting('mention_notifications', value);
            },
          ),

          const Divider(),

          // Call Notifications Section
          _buildSectionHeader('Calls'),
          _buildSwitchTile(
            title: 'Call Notifications',
            subtitle: 'Get notified for incoming calls',
            value: _callNotifications,
            onChanged: (value) {
              setState(() => _callNotifications = value);
              _saveSetting('call_notifications', value);
            },
          ),

          const Divider(),

          // Sound & Vibration Section
          _buildSectionHeader('Sound & Vibration'),
          _buildSwitchTile(
            title: 'Sound',
            subtitle: 'Play notification sounds',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSetting('sound_enabled', value);
            },
          ),
          if (_soundEnabled) ...[
            ListTile(
              title: const Text('Notification Sound'),
              subtitle: Text(_getSoundName(_notificationSound)),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showSoundSelectionDialog,
            ),
          ],
          _buildSwitchTile(
            title: 'Vibration',
            subtitle: 'Vibrate for notifications',
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveSetting('vibration_enabled', value);
            },
          ),

          const Divider(),

          // Advanced Settings Section
          _buildSectionHeader('Advanced'),
          _buildSwitchTile(
            title: 'Do Not Disturb',
            subtitle: 'Silence notifications during specified hours',
            value: _dndEnabled,
            onChanged: (value) {
              setState(() => _dndEnabled = value);
              _saveSetting('dnd_enabled', value);
            },
          ),

          if (_dndEnabled) ...[
            ListTile(
              title: const Text('Quiet Hours Start'),
              subtitle: Text(_dndStartTime?.format(context) ?? 'Not set'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(true),
            ),
            ListTile(
              title: const Text('Quiet Hours End'),
              subtitle: Text(_dndEndTime?.format(context) ?? 'Not set'),
              trailing: const Icon(Icons.access_time),
              onTap: () => _selectTime(false),
            ),
          ],

          _buildSwitchTile(
            title: 'Message Preview',
            subtitle: 'Show message content in notifications',
            value: _showMessagePreview,
            onChanged: (value) {
              setState(() => _showMessagePreview = value);
              _saveSetting('show_message_preview', value);
            },
          ),

          ListTile(
            title: const Text('Notification Analytics'),
            subtitle: const Text(
              'View notification delivery and engagement stats',
            ),
            trailing: const Icon(Icons.analytics),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationAnalyticsScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Test Notification Section
          Container(
            margin: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

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
                  'Notification Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can customize when and how you receive notifications. Some notifications may still appear based on your device settings.',
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

  String _getSoundName(String soundKey) {
    switch (soundKey) {
      case 'default':
        return 'Default';
      case 'bell':
        return 'Bell';
      case 'chime':
        return 'Chime';
      case 'gentle':
        return 'Gentle';
      default:
        return 'Default';
    }
  }

  void _showSoundSelectionDialog() {
    final sounds = ['default', 'bell', 'chime', 'gentle'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sounds.map((sound) {
            return RadioListTile<String>(
              title: Text(_getSoundName(sound)),
              value: sound,
              groupValue: _notificationSound,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _notificationSound = value);
                  _saveSetting('notification_sound', value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
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

  void _testNotification() {
    // TODO: Send a test notification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test notification sent!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_dndStartTime ?? const TimeOfDay(hour: 22, minute: 0))
          : (_dndEndTime ?? const TimeOfDay(hour: 8, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _dndStartTime = picked;
          _saveSetting('dnd_start_time', '${picked.hour}:${picked.minute}');
        } else {
          _dndEndTime = picked;
          _saveSetting('dnd_end_time', '${picked.hour}:${picked.minute}');
        }
      });
    }
  }
}
