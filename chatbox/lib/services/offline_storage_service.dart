// lib/services/offline_storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Offline storage service for caching chat data
class OfflineStorageService {
  static const String _channelsKey = 'cached_channels';
  static const String _messagesKey = 'cached_messages';
  static const String _usersKey = 'cached_users';
  static const String _lastSyncKey = 'last_sync_timestamp';

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
    try {
      final jsonData = jsonEncode(channels);
      await _prefs.setString(_channelsKey, jsonData);
      await _updateLastSync();
    } catch (e) {
      print('Failed to cache channels: $e');
    }
  }

  // Get cached channels
  Future<List<Map<String, dynamic>>> getCachedChannels() async {
    try {
      final jsonData = _prefs.getString(_channelsKey);
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
      await _prefs.setString(_messagesKey, jsonData);
    } catch (e) {
      print('Failed to cache messages for channel $channelId: $e');
    }
  }

  // Get cached messages for a channel
  Future<List<Map<String, dynamic>>> getCachedMessages(String channelId) async {
    try {
      final jsonData = _prefs.getString(_messagesKey);
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
      print('Failed to cache users: $e');
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

      stats['total'] = stats.values.fold(0, (sum, size) => sum + size);
    } catch (e) {
      print('Failed to get cache stats: $e');
    }

    return stats;
  }
}
