// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/models/scheduled_message.dart';
import 'package:chatbox/providers/theme_provider.dart';

class BackupData {
  final List<Map<String, dynamic>> messages;
  final List<Map<String, dynamic>> channels;
  final Map<String, dynamic> userSettings;
  final List<Map<String, dynamic>> scheduledMessages;
  final String backupDate;
  final String version;

  BackupData({
    required this.messages,
    required this.channels,
    required this.userSettings,
    required this.scheduledMessages,
    required this.backupDate,
    required this.version,
  });

  Map<String, dynamic> toJson() {
    return {
      'messages': messages,
      'channels': channels,
      'userSettings': userSettings,
      'scheduledMessages': scheduledMessages,
      'backupDate': backupDate,
      'version': version,
    };
  }

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      messages: List<Map<String, dynamic>>.from(json['messages'] ?? []),
      channels: List<Map<String, dynamic>>.from(json['channels'] ?? []),
      userSettings: Map<String, dynamic>.from(json['userSettings'] ?? {}),
      scheduledMessages: List<Map<String, dynamic>>.from(
        json['scheduledMessages'] ?? [],
      ),
      backupDate: json['backupDate'] ?? '',
      version: json['version'] ?? '1.0.0',
    );
  }
}

class BackupService {
  static const String _backupFolderName = 'ChatBox_Backups';
  static const String _encryptionKey =
      'your-32-character-encryption-key-here'; // In production, use proper key management

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  drive.DriveApi? _driveApi;
  bool _isSignedIn = false;

  bool get isSignedIn => _isSignedIn;

  Future<bool> signInWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        final authHeaders = await account.authHeaders;
        final authenticateClient = auth.authenticatedClient(
          http.Client(),
          auth.AccessCredentials(
            auth.AccessToken(
              'Bearer',
              authHeaders['Authorization']!.split(' ').last,
              DateTime.now().add(const Duration(hours: 1)),
            ),
            null, // No refresh token for now
            [drive.DriveApi.driveFileScope],
          ),
        );

        _driveApi = drive.DriveApi(authenticateClient);
        _isSignedIn = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _driveApi = null;
    _isSignedIn = false;
  }

  Future<String?> createBackup({
    required StreamChatClient client,
    required ThemeProvider themeProvider,
  }) async {
    if (!_isSignedIn || _driveApi == null) {
      throw Exception('Not signed in to Google Drive');
    }

    try {
      // Gather backup data
      final backupData = await _gatherBackupData(client, themeProvider);

      // Convert to JSON
      final jsonData = jsonEncode(backupData.toJson());

      // Encrypt data
      final encryptedData = _encryptData(jsonData);

      // Create archive with media files
      final archiveData = await _createArchive(encryptedData);

      // Upload to Google Drive
      final fileId = await _uploadToDrive(archiveData, backupData.backupDate);

      return fileId;
    } catch (e) {
      print('Backup creation failed: $e');
      rethrow;
    }
  }

  Future<BackupData> _gatherBackupData(
    StreamChatClient client,
    ThemeProvider themeProvider,
  ) async {
    // Get user channels
    final channels = await client.queryChannels().first;

    // Collect messages from all channels
    final allMessages = <Map<String, dynamic>>[];
    final channelData = <Map<String, dynamic>>[];

    for (final channel in channels) {
      // Get channel info
      channelData.add({
        'id': channel.id,
        'name': channel.name,
        'type': channel.type,
        'memberCount': channel.memberCount,
        'createdAt': channel.createdAt?.toIso8601String(),
      });

      // Get messages (last 1000 per channel to avoid too large backups)
      try {
        final messages = await channel.query(
          messagesPagination: const PaginationParams(limit: 1000),
        );

        for (final message in messages.messages ?? []) {
          allMessages.add({
            'id': message.id,
            'text': message.text,
            'userId': message.user?.id,
            'userName': message.user?.name,
            'channelId': channel.id,
            'createdAt': message.createdAt.toIso8601String(),
            'updatedAt': message.updatedAt?.toIso8601String(),
            'type': message.type,
            'attachments':
                message.attachments?.map((a) => a.toJson()).toList() ?? [],
            'parentId': message.parentId,
            'quotedMessageId': message.quotedMessageId,
          });
        }
      } catch (e) {
        print('Failed to get messages for channel ${channel.id}: $e');
      }
    }

    // Get user settings
    final prefs = await SharedPreferences.getInstance();
    final userSettings = {
      'theme': themeProvider.currentTheme.id,
      'wallpaper': themeProvider.wallpaperUrl,
      // Add other user preferences here
    };

    // Get scheduled messages
    final scheduledService = await _getScheduledMessages();

    return BackupData(
      messages: allMessages,
      channels: channelData,
      userSettings: userSettings,
      scheduledMessages: scheduledService,
      backupDate: DateTime.now().toIso8601String(),
      version: '1.0.0',
    );
  }

  Future<List<Map<String, dynamic>>> _getScheduledMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString('scheduled_messages');
      if (messagesJson == null) return [];

      final messagesList = jsonDecode(messagesJson) as List;
      return messagesList.map((msg) => Map<String, dynamic>.from(msg)).toList();
    } catch (e) {
      print('Error getting scheduled messages: $e');
      return [];
    }
  }

  String _encryptData(String data) {
    final key = encrypt.Key.fromUtf8(
      _encryptionKey.padRight(32, '0').substring(0, 32),
    );
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(data, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String _decryptData(String encryptedData) {
    final parts = encryptedData.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);

    final key = encrypt.Key.fromUtf8(
      _encryptionKey.padRight(32, '0').substring(0, 32),
    );
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encrypted, iv: iv);
  }

  Future<List<int>> _createArchive(String data) async {
    final archive = Archive();

    // Add main data file
    final dataBytes = utf8.encode(data);
    archive.addFile(ArchiveFile('backup.json', dataBytes.length, dataBytes));

    // Add media files if they exist locally
    final mediaFiles = await _getLocalMediaFiles();
    for (final mediaFile in mediaFiles) {
      if (await mediaFile.exists()) {
        final bytes = await mediaFile.readAsBytes();
        archive.addFile(
          ArchiveFile(mediaFile.path.split('/').last, bytes.length, bytes),
        );
      }
    }

    return ZipEncoder().encode(archive) ?? [];
  }

  Future<List<File>> _getLocalMediaFiles() async {
    // This would collect local media files that need to be backed up
    // For now, return empty list - implement based on your media storage
    return [];
  }

  Future<String> _uploadToDrive(List<int> data, String backupDate) async {
    // Create or get backup folder
    final folderId = await _getOrCreateBackupFolder();

    // Create file metadata
    final fileName = 'ChatBox_Backup_$backupDate.zip';
    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId];

    // Upload file
    final media = drive.Media(Stream.value(data), data.length);
    final uploadedFile = await _driveApi!.files.create(
      driveFile,
      uploadMedia: media,
    );

    return uploadedFile.id!;
  }

  Future<String> _getOrCreateBackupFolder() async {
    // Check if backup folder exists
    final query =
        "name = '$_backupFolderName' and mimeType = 'application/vnd.google-apps.folder'";
    final folderList = await _driveApi!.files.list(q: query);

    if (folderList.files != null && folderList.files!.isNotEmpty) {
      return folderList.files!.first.id!;
    }

    // Create new folder
    final folder = drive.File()
      ..name = _backupFolderName
      ..mimeType = 'application/vnd.google-apps.folder';

    final createdFolder = await _driveApi!.files.create(folder);
    return createdFolder.id!;
  }

  Future<List<Map<String, dynamic>>> listBackups() async {
    if (!_isSignedIn || _driveApi == null) return [];

    try {
      final folderId = await _getOrCreateBackupFolder();
      final query = "'$folderId' in parents and name contains 'ChatBox_Backup'";
      final files = await _driveApi!.files.list(
        q: query,
        orderBy: 'createdTime desc',
      );

      return files.files?.map((file) {
            return {
              'id': file.id,
              'name': file.name,
              'createdTime': file.createdTime?.toIso8601String(),
              'size': file.size,
            };
          }).toList() ??
          [];
    } catch (e) {
      print('Failed to list backups: $e');
      return [];
    }
  }

  Future<bool> restoreBackup(
    String backupId,
    StreamChatClient client,
    ThemeProvider themeProvider,
  ) async {
    if (!_isSignedIn || _driveApi == null) return false;

    try {
      // Download backup file
      final media =
          await _driveApi!.files.get(
                backupId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media?;
      if (media == null) return false;

      final data = <int>[];
      await for (final chunk in media.stream) {
        data.addAll(chunk);
      }

      // Extract archive
      final archive = ZipDecoder().decodeBytes(data);
      final backupFile = archive.findFile('backup.json');
      if (backupFile == null) return false;

      // Decrypt data
      final encryptedData = utf8.decode(backupFile.content);
      final jsonData = _decryptData(encryptedData);

      // Parse backup data
      final backupData = BackupData.fromJson(jsonDecode(jsonData));

      // Restore data
      await _restoreData(backupData, client, themeProvider);

      return true;
    } catch (e) {
      print('Restore failed: $e');
      return false;
    }
  }

  Future<void> _restoreData(
    BackupData backupData,
    StreamChatClient client,
    ThemeProvider themeProvider,
  ) async {
    // Restore user settings
    if (backupData.userSettings['theme'] != null) {
      final theme = ChatTheme.predefinedThemes.firstWhere(
        (t) => t.id == backupData.userSettings['theme'],
        orElse: () => ChatTheme.light,
      );
      await themeProvider.setTheme(theme);
    }

    if (backupData.userSettings['wallpaper'] != null) {
      await themeProvider.setWallpaper(backupData.userSettings['wallpaper']);
    }

    // Note: Restoring messages and channels would require special handling
    // and coordination with Stream Chat's API. For now, we restore settings only.
    // In a production app, you'd implement proper message/channel restoration.

    print(
      'Backup restored successfully. Note: Messages and channels restoration requires additional implementation.',
    );
  }

  Future<bool> deleteBackup(String backupId) async {
    if (!_isSignedIn || _driveApi == null) return false;

    try {
      await _driveApi!.files.delete(backupId);
      return true;
    } catch (e) {
      print('Failed to delete backup: $e');
      return false;
    }
  }
}
