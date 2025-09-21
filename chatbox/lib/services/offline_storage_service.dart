// lib/services/offline_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline storage service for caching chat data
class OfflineStorageService {
  static const String _channelsKey = 'cached_channels';
  static const String _messagesKey = 'cached_messages';
  static const String _usersKey = 'cached_users';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _queuedMessagesKey = 'queued_messages';
  static const int _maxChunkSize = 500000; // 500KB per chunk

  static final OfflineStorageService _instance =
      OfflineStorageService._internal();
  late final SharedPreferences _prefs;

  factory OfflineStorageService() {
    return _instance;
  }

  OfflineStorageService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Cache channels as simple data
  Future<void> cacheChannels(List<Map<String, dynamic>> channels) async {
    final startTime = DateTime.now();
    try {
      final jsonData = jsonEncode(channels);
      if (jsonData.length > _maxChunkSize) {
        await _storeInChunks(_channelsKey, jsonData);
      } else {
        await _prefs.setString(_channelsKey, jsonData);
        await _clearChunks(_channelsKey);
      }
      await _updateLastSync();
      final duration = DateTime.now().difference(startTime);
      print(
        'Cached ${channels.length} channels in ${duration.inMilliseconds}ms',
      );
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      print('Failed to cache channels after ${duration.inMilliseconds}ms: $e');
      throw Exception('Failed to cache channels: $e');
    }
  }

  // Get cached channels
  Future<List<Map<String, dynamic>>> getCachedChannels() async {
    try {
      String? jsonData = _prefs.getString(_channelsKey);
      if (jsonData == null) {
        jsonData = await _readFromChunks(_channelsKey);
      }
      if (jsonData == null) return [];

      final channelData = jsonDecode(jsonData) as List<dynamic>;
      return channelData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Failed to get cached channels: $e');
      return [];
    }
  }

  // Cache messages for a channel
  Future<void> cacheMessages(
    String channelId,
    List<Map<String, dynamic>> messages,
  ) async {
    try {
      final existingData = _prefs.getString(_messagesKey) ?? '{}';
      final allMessages = jsonDecode(existingData) as Map<String, dynamic>;

      allMessages[channelId] = messages;

      final jsonData = jsonEncode(allMessages);
      if (jsonData.length > _maxChunkSize) {
        await _storeInChunks(_messagesKey, jsonData);
      } else {
        await _prefs.setString(_messagesKey, jsonData);
        await _clearChunks(_messagesKey); // Clear any existing chunks
      }
    } catch (e) {
      throw Exception('Failed to cache messages for channel $channelId: $e');
    }
  }

  // Get cached messages for a channel
  Future<List<Map<String, dynamic>>> getCachedMessages(String channelId) async {
    try {
      String? jsonData = _prefs.getString(_messagesKey);
      if (jsonData == null) {
        jsonData = await _readFromChunks(_messagesKey);
      }
      if (jsonData == null) return [];

      final allMessages = jsonDecode(jsonData) as Map<String, dynamic>;
      final channelMessages = allMessages[channelId] as List<dynamic>? ?? [];

      return channelMessages.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Failed to get cached messages for channel $channelId: $e');
      return [];
    }
  }

  // Cache user data
  Future<void> cacheUsers(List<Map<String, dynamic>> users) async {
    try {
      final jsonData = jsonEncode(users);
      await _prefs.setString(_usersKey, jsonData);
    } catch (e) {
      throw Exception('Failed to cache users: $e');
    }
  }

  // Get cached users
  Future<List<Map<String, dynamic>>> getCachedUsers() async {
    try {
      final jsonData = _prefs.getString(_usersKey);
      if (jsonData == null) return [];

      final userData = jsonDecode(jsonData) as List<dynamic>;
      return userData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Failed to get cached users: $e');
      return [];
    }
  }

  // Clear all cached data
  Future<void> clearCache() async {
    await _prefs.remove(_channelsKey);
    await _prefs.remove(_messagesKey);
    await _clearChunks(_messagesKey);
    await _prefs.remove(_usersKey);
    await _prefs.remove(_lastSyncKey);
  }

  // Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getString(_lastSyncKey);
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Check if cache is stale
  bool isCacheStale(Duration maxAge) {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > maxAge;
  }

  Future<void> _updateLastSync() async {
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  // Queue message for offline sending
  Future<void> queueMessage(Map<String, dynamic> message) async {
    try {
      final existingQueue = await getQueuedMessages();
      existingQueue.add(message);
      final jsonData = jsonEncode(existingQueue);
      await _prefs.setString(_queuedMessagesKey, jsonData);
    } catch (e) {
      throw Exception('Failed to queue message: $e');
    }
  }

  // Get queued messages
  Future<List<Map<String, dynamic>>> getQueuedMessages() async {
    try {
      final jsonData = _prefs.getString(_queuedMessagesKey);
      if (jsonData == null) return [];

      final messageData = jsonDecode(jsonData) as List<dynamic>;
      return messageData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Failed to get queued messages: $e');
      return [];
    }
  }

  // Remove message from queue (after successful sending)
  Future<void> removeQueuedMessage(String messageId) async {
    try {
      final queue = await getQueuedMessages();
      queue.removeWhere((msg) => msg['id'] == messageId);
      final jsonData = jsonEncode(queue);
      await _prefs.setString(_queuedMessagesKey, jsonData);
    } catch (e) {
      throw Exception('Failed to remove queued message: $e');
    }
  }

  // Clear all queued messages
  Future<void> clearMessageQueue() async {
    await _prefs.remove(_queuedMessagesKey);
  }

  // Get cache size estimate
  Future<Map<String, int>> getCacheStats() async {
    final stats = <String, int>{};

    try {
      final channelsData = _prefs.getString(_channelsKey);
      stats['channels'] = channelsData?.length ?? 0;

      final messagesData = _prefs.getString(_messagesKey);
      stats['messages'] = messagesData?.length ?? 0;

      final usersData = _prefs.getString(_usersKey);
      stats['users'] = usersData?.length ?? 0;

      final queuedMessagesData = _prefs.getString(_queuedMessagesKey);
      stats['queued_messages'] = queuedMessagesData?.length ?? 0;

      stats['total'] = stats.values.fold(0, (sum, size) => sum + size);
    } catch (e) {
      print('Failed to get cache stats: $e');
    }

    return stats;
  }

  // Helper methods for chunked storage
  Future<void> _storeInChunks(String baseKey, String data) async {
    final chunks = <String>[];
    for (var i = 0; i < data.length; i += _maxChunkSize) {
      chunks.add(
        data.substring(
          i,
          i + _maxChunkSize > data.length ? data.length : i + _maxChunkSize,
        ),
      );
    }

    // Store number of chunks
    await _prefs.setInt('${baseKey}_chunks', chunks.length);

    // Store each chunk
    for (var i = 0; i < chunks.length; i++) {
      await _prefs.setString('${baseKey}_chunk_$i', chunks[i]);
    }
  }

  Future<String?> _readFromChunks(String baseKey) async {
    final chunkCount = _prefs.getInt('${baseKey}_chunks');
    if (chunkCount == null) return null;

    final chunks = <String>[];
    for (var i = 0; i < chunkCount; i++) {
      final chunk = _prefs.getString('${baseKey}_chunk_$i');
      if (chunk == null) return null;
      chunks.add(chunk);
    }

    return chunks.join();
  }

  Future<void> _clearChunks(String baseKey) async {
    final chunkCount = _prefs.getInt('${baseKey}_chunks');
    if (chunkCount != null) {
      for (var i = 0; i < chunkCount; i++) {
        await _prefs.remove('${baseKey}_chunk_$i');
      }
      await _prefs.remove('${baseKey}_chunks');
    }
  }
}
