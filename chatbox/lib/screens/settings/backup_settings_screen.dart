// lib/screens/settings/backup_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/providers/theme_provider.dart';
import 'package:chatbox/services/backup_service.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  late BackupService _backupService;
  bool _isLoading = false;
  List<Map<String, dynamic>> _backups = [];

  @override
  void initState() {
    super.initState();
    _backupService = BackupService();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    if (_backupService.isSignedIn) {
      setState(() => _isLoading = true);
      try {
        final backups = await _backupService.listBackups();
        setState(() => _backups = backups);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load backups: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore'), elevation: 0),
      body: ListView(
        children: [
          // Google Drive Sign In Section
          _buildSectionHeader('Google Drive'),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _backupService.isSignedIn
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  size: 48,
                  color: _backupService.isSignedIn
                      ? AppColors.primary
                      : AppColors.grey600,
                ),
                const SizedBox(height: 16),
                Text(
                  _backupService.isSignedIn
                      ? 'Connected to Google Drive'
                      : 'Connect to Google Drive for backups',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _backupService.isSignedIn ? _signOut : _signIn,
                  icon: Icon(
                    _backupService.isSignedIn ? Icons.logout : Icons.login,
                  ),
                  label: Text(
                    _backupService.isSignedIn ? 'Sign Out' : 'Sign In',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _backupService.isSignedIn
                        ? AppColors.danger
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Backup Section
          if (_backupService.isSignedIn) ...[
            _buildSectionHeader('Create Backup'),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createBackup,
                icon: const Icon(Icons.backup),
                label: const Text('Create Backup Now'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

            // Existing Backups Section
            _buildSectionHeader('Backup History'),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_backups.isEmpty)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.backup_outlined,
                      size: 48,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No backups found',
                      style: TextStyle(fontSize: 16, color: AppColors.grey600),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create your first backup to get started',
                      style: TextStyle(fontSize: 14, color: AppColors.grey600),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._backups.map((backup) => _buildBackupItem(backup)),
          ],

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
                  'Backup Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Backups include your messages, settings, and media files\n'
                  '• Data is encrypted before uploading to Google Drive\n'
                  '• You can restore backups on any device with ChatBox\n'
                  '• Automatic backups can be scheduled in the future',
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

  Widget _buildBackupItem(Map<String, dynamic> backup) {
    final createdDate = DateTime.parse(backup['createdTime']);
    final sizeInMB = (backup['size'] ?? 0) / (1024 * 1024);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.backup, color: AppColors.primary),
        title: Text(
          'Backup ${createdDate.day}/${createdDate.month}/${createdDate.year}',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${createdDate.hour}:${createdDate.minute.toString().padLeft(2, '0')} • ${sizeInMB.toStringAsFixed(1)} MB',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'restore':
                _restoreBackup(backup['id']);
                break;
              case 'delete':
                _deleteBackup(backup['id']);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'restore', child: Text('Restore')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final success = await _backupService.signInWithGoogle();
      if (success) {
        await _loadBackups();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Google Drive'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect to Google Drive')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _backupService.signOut();
    setState(() => _backups = []);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signed out from Google Drive')),
    );
  }

  Future<void> _createBackup() async {
    setState(() => _isLoading = true);
    try {
      final client = StreamChat.of(context).client;
      final themeProvider = context.read<ThemeProvider>();

      await _backupService.createBackup(
        client: client,
        themeProvider: themeProvider,
      );

      await _loadBackups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Text(
          'This will restore your settings and data from the backup. '
          'Current data may be overwritten. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final client = StreamChat.of(context).client;
      final themeProvider = context.read<ThemeProvider>();

      final success = await _backupService.restoreBackup(
        backupId,
        client,
        themeProvider,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup restored successfully')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup restore failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Restore failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBackup(String backupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Backup'),
        content: const Text('Are you sure you want to delete this backup?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final success = await _backupService.deleteBackup(backupId);
      if (success) {
        await _loadBackups();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete backup')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
