// lib/services/search_service.dart
import 'dart:convert';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/services/stream_chat_service.dart';

enum SearchType { messages, users, channels, all }

enum MessageType { text, image, video, file, location, contact, all }

class SearchFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? senderId;
  final MessageType messageType;
  final String? channelId; // For channel-specific search
  final int limit;
  final int offset;

  const SearchFilters({
    this.startDate,
    this.endDate,
    this.senderId,
    this.messageType = MessageType.all,
    this.channelId,
    this.limit = 50,
    this.offset = 0,
  });

  SearchFilters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    String? senderId,
    MessageType? messageType,
    String? channelId,
    int? limit,
    int? offset,
  }) {
    return SearchFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      channelId: channelId ?? this.channelId,
      limit: limit ?? this.limit,
      offset: offset ?? this.offset,
    );
  }
}

class SearchResult {
  final List<Message> messages;
  final List<User> users;
  final List<Channel> channels;
  final bool hasMore;
  final int totalCount;

  const SearchResult({
    this.messages = const [],
    this.users = const [],
    this.channels = const [],
    this.hasMore = false,
    this.totalCount = 0,
  });

  SearchResult copyWith({
    List<Message>? messages,
    List<User>? users,
    List<Channel>? channels,
    bool? hasMore,
    int? totalCount,
  }) {
    return SearchResult(
      messages: messages ?? this.messages,
      users: users ?? this.users,
      channels: channels ?? this.channels,
      hasMore: hasMore ?? this.hasMore,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class SavedSearch {
  final String id;
  final String query;
  final SearchType type;
  final SearchFilters filters;
  final DateTime createdAt;
  final int useCount;

  const SavedSearch({
    required this.id,
    required this.query,
    required this.type,
    required this.filters,
    required this.createdAt,
    this.useCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'type': type.toString(),
      'filters': {
        'startDate': filters.startDate?.toIso8601String(),
        'endDate': filters.endDate?.toIso8601String(),
        'senderId': filters.senderId,
        'messageType': filters.messageType.toString(),
        'channelId': filters.channelId,
        'limit': filters.limit,
        'offset': filters.offset,
      },
      'createdAt': createdAt.toIso8601String(),
      'useCount': useCount,
    };
  }

  factory SavedSearch.fromJson(Map<String, dynamic> json) {
    return SavedSearch(
      id: json['id'],
      query: json['query'],
      type: SearchType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SearchType.all,
      ),
      filters: SearchFilters(
        startDate: json['filters']['startDate'] != null
            ? DateTime.parse(json['filters']['startDate'])
            : null,
        endDate: json['filters']['endDate'] != null
            ? DateTime.parse(json['filters']['endDate'])
            : null,
        senderId: json['filters']['senderId'],
        messageType: MessageType.values.firstWhere(
          (e) => e.toString() == json['filters']['messageType'],
          orElse: () => MessageType.all,
        ),
        channelId: json['filters']['channelId'],
        limit: json['filters']['limit'] ?? 50,
        offset: json['filters']['offset'] ?? 0,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      useCount: json['useCount'] ?? 0,
    );
  }
}

class SearchService {
  static const String _searchHistoryKey = 'search_history';
  static const String _savedSearchesKey = 'saved_searches';

  final StreamChatService _streamService = StreamChatService();
  final SharedPreferences _prefs;

  SearchService(this._prefs);

  // Global search across messages, users, and channels
  Future<SearchResult> globalSearch(
    String query,
    SearchType type, {
    SearchFilters filters = const SearchFilters(),
  }) async {
    await _streamService.ensureConnected();

    final results = SearchResult();

    try {
      if (type == SearchType.all || type == SearchType.messages) {
        final messages = await _searchMessages(query, filters);
        results.messages.addAll(messages);
      }

      if (type == SearchType.all || type == SearchType.users) {
        final users = await _searchUsers(query);
        results.users.addAll(users);
      }

      if (type == SearchType.all || type == SearchType.channels) {
        final channels = await _searchChannels(query);
        results.channels.addAll(channels);
      }

      // Save to search history
      await _saveToHistory(query, type, filters);
    } catch (e) {
      print('Search error: $e');
      // Return partial results if available
    }

    return results;
  }

  // Search messages with filters
  Future<List<Message>> _searchMessages(
    String query,
    SearchFilters filters,
  ) async {
    try {
      List<Channel> channelsToSearch = [];

      if (filters.channelId != null) {
        // Search in specific channel
        try {
          final channel = _streamService.client.channel(
            'messaging', // Assuming messaging type, but should be dynamic
            id: filters.channelId!,
          );
          await channel.watch(); // Ensure channel is loaded
          channelsToSearch = [channel];
        } catch (e) {
          print('Error accessing channel ${filters.channelId}: $e');
          return [];
        }
      } else {
        // Search in all channels the user has access to
        final channelsResponse = _streamService.client.queryChannels();
        channelsToSearch = await channelsResponse.first;
      }

      List<Message> allMessages = [];

      for (final channel in channelsToSearch) {
        try {
          // Get channel state which includes recent messages
          final state = await channel.watch();
          final messages = state.messages ?? [];

          // Filter messages based on our criteria
          final filteredMessages = messages.where((message) {
            // Text search
            if (query.isNotEmpty) {
              final text = message.text?.toLowerCase() ?? '';
              if (!text.contains(query.toLowerCase())) {
                return false;
              }
            }

            // Date filters
            if (filters.startDate != null &&
                message.createdAt.isBefore(filters.startDate!)) {
              return false;
            }
            if (filters.endDate != null &&
                message.createdAt.isAfter(filters.endDate!)) {
              return false;
            }

            // Sender filter
            if (filters.senderId != null &&
                message.user?.id != filters.senderId) {
              return false;
            }

            // Message type filter
            if (filters.messageType != MessageType.all) {
              final hasMatchingAttachment =
                  message.attachments.any((attachment) {
                    switch (filters.messageType) {
                      case MessageType.image:
                        return attachment.type == 'image';
                      case MessageType.video:
                        return attachment.type == 'video';
                      case MessageType.file:
                        return attachment.type == 'file' ||
                            attachment.type == 'audio';
                      case MessageType.location:
                        return attachment.type == 'location';
                      case MessageType.contact:
                        return attachment.type == 'contact';
                      default:
                        return false;
                    }
                  }) ??
                  false;

              if (!hasMatchingAttachment) {
                return false;
              }
            }

            return true;
          }).toList();

          allMessages.addAll(filteredMessages);
        } catch (e) {
          // Skip channels we can't access
          continue;
        }
      }

      // Sort by creation date (newest first) and limit results
      allMessages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return allMessages.take(filters.limit).toList();
    } catch (e) {
      print('Message search error: $e');
      return [];
    }
  }

  // Search users
  Future<List<User>> _searchUsers(String query) async {
    try {
      if (query.isEmpty) return [];

      // Query users from StreamChat
      final usersResponse = await _streamService.client.queryUsers(
        filter: Filter.autoComplete('name', query),
        sort: [const SortOption('name')],
        pagination: const PaginationParams(limit: 20),
      );

      return usersResponse.users;
    } catch (e) {
      print('User search error: $e');
      return [];
    }
  }

  // Search channels
  Future<List<Channel>> _searchChannels(String query) async {
    try {
      // Get all channels and filter by name
      final channelsResponse = _streamService.client.queryChannels();
      final channels = await channelsResponse.first;

      if (query.isEmpty) {
        return channels.take(20).toList();
      }

      // Filter channels by name
      final filteredChannels = channels.where((channel) {
        final channelName = channel.name?.toLowerCase() ?? '';
        return channelName.contains(query.toLowerCase());
      }).toList();

      return filteredChannels.take(20).toList();
    } catch (e) {
      print('Channel search error: $e');
      return [];
    }
  }

  // Search history management
  Future<void> _saveToHistory(
    String query,
    SearchType type,
    SearchFilters filters,
  ) async {
    try {
      final history = await getSearchHistory();
      final existingIndex = history.indexWhere(
        (item) => item.query == query && item.type == type,
      );

      if (existingIndex >= 0) {
        // Update existing entry
        final updatedItem = history[existingIndex].copyWith(
          useCount: history[existingIndex].useCount + 1,
        );
        history[existingIndex] = updatedItem;
      } else {
        // Add new entry
        history.insert(
          0,
          SearchHistoryItem(
            query: query,
            type: type,
            filters: filters,
            timestamp: DateTime.now(),
          ),
        );

        // Keep only last 50 entries
        if (history.length > 50) {
          history.removeRange(50, history.length);
        }
      }

      final historyJson = history.map((item) => item.toJson()).toList();
      await _prefs.setString(_searchHistoryKey, jsonEncode(historyJson));
    } catch (e) {
      print('Error saving search history: $e');
    }
  }

  Future<List<SearchHistoryItem>> getSearchHistory() async {
    try {
      final historyJson = _prefs.getString(_searchHistoryKey);
      if (historyJson == null) return [];

      final historyList = jsonDecode(historyJson) as List;
      return historyList
          .map((item) => SearchHistoryItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading search history: $e');
      return [];
    }
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_searchHistoryKey);
  }

  // Saved searches management
  Future<void> saveSearch(
    String query,
    SearchType type,
    SearchFilters filters,
  ) async {
    try {
      final savedSearches = await getSavedSearches();
      final id = DateTime.now().millisecondsSinceEpoch.toString();

      savedSearches.add(
        SavedSearch(
          id: id,
          query: query,
          type: type,
          filters: filters,
          createdAt: DateTime.now(),
        ),
      );

      final searchesJson = savedSearches
          .map((search) => search.toJson())
          .toList();
      await _prefs.setString(_savedSearchesKey, jsonEncode(searchesJson));
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  Future<List<SavedSearch>> getSavedSearches() async {
    try {
      final searchesJson = _prefs.getString(_savedSearchesKey);
      if (searchesJson == null) return [];

      final searchesList = jsonDecode(searchesJson) as List;
      return searchesList.map((item) => SavedSearch.fromJson(item)).toList();
    } catch (e) {
      print('Error loading saved searches: $e');
      return [];
    }
  }

  Future<void> deleteSavedSearch(String searchId) async {
    try {
      final savedSearches = await getSavedSearches();
      savedSearches.removeWhere((search) => search.id == searchId);

      final searchesJson = savedSearches
          .map((search) => search.toJson())
          .toList();
      await _prefs.setString(_savedSearchesKey, jsonEncode(searchesJson));
    } catch (e) {
      print('Error deleting saved search: $e');
    }
  }

  Future<void> updateSavedSearch(SavedSearch search) async {
    try {
      final savedSearches = await getSavedSearches();
      final index = savedSearches.indexWhere((s) => s.id == search.id);

      if (index >= 0) {
        savedSearches[index] = search;
        final searchesJson = savedSearches.map((s) => s.toJson()).toList();
        await _prefs.setString(_savedSearchesKey, jsonEncode(searchesJson));
      }
    } catch (e) {
      print('Error updating saved search: $e');
    }
  }

  // User discovery and friend suggestions
  Future<List<User>> getSuggestedUsers({int limit = 10}) async {
    try {
      // Get users from channels the current user is in
      final channelsResponse = _streamService.client.queryChannels();
      final channels = await channelsResponse.first;

      Set<String> suggestedUserIds = {};

      for (final channel in channels.take(5)) {
        // Limit to first 5 channels
        try {
          final members = await channel.queryMembers();
          for (final member in members.members) {
            if (member.userId != _streamService.client.state.currentUser?.id) {
              suggestedUserIds.add(member.userId!);
            }
          }
        } catch (e) {
          continue;
        }
      }

      // Get user details for suggested users
      if (suggestedUserIds.isEmpty) return [];

      final usersResponse = await _streamService.client.queryUsers(
        filter: Filter.in_('id', suggestedUserIds.toList()),
        pagination: PaginationParams(limit: limit),
      );

      return usersResponse.users;
    } catch (e) {
      print('Error getting suggested users: $e');
      return [];
    }
  }

  // Discover new users (not in contacts)
  Future<List<User>> discoverUsers({String? query, int limit = 20}) async {
    try {
      final filter = query != null && query.isNotEmpty
          ? Filter.and([
              Filter.autoComplete('name', query),
              Filter.notEqual(
                'id',
                _streamService.client.state.currentUser?.id ?? '',
              ),
            ])
          : Filter.notEqual(
              'id',
              _streamService.client.state.currentUser?.id ?? '',
            );

      final usersResponse = await _streamService.client.queryUsers(
        filter: filter,
        sort: [const SortOption('name')],
        pagination: PaginationParams(limit: limit),
      );

      return usersResponse.users;
    } catch (e) {
      print('Error discovering users: $e');
      return [];
    }
  }

  // Find nearby users (requires location data in user metadata)
  Future<List<User>> findNearbyUsers(
    double latitude,
    double longitude,
    double radiusKm, {
    int limit = 20,
  }) async {
    try {
      // This would require users to have location data stored in their metadata
      // For now, return empty list as location-based user discovery needs backend support
      // In a real implementation, you would query users with location within radius
      return [];
    } catch (e) {
      print('Error finding nearby users: $e');
      return [];
    }
  }
}

class SearchHistoryItem {
  final String query;
  final SearchType type;
  final SearchFilters filters;
  final DateTime timestamp;
  final int useCount;

  const SearchHistoryItem({
    required this.query,
    required this.type,
    required this.filters,
    required this.timestamp,
    this.useCount = 1,
  });

  SearchHistoryItem copyWith({
    String? query,
    SearchType? type,
    SearchFilters? filters,
    DateTime? timestamp,
    int? useCount,
  }) {
    return SearchHistoryItem(
      query: query ?? this.query,
      type: type ?? this.type,
      filters: filters ?? this.filters,
      timestamp: timestamp ?? this.timestamp,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'type': type.toString(),
      'filters': {
        'startDate': filters.startDate?.toIso8601String(),
        'endDate': filters.endDate?.toIso8601String(),
        'senderId': filters.senderId,
        'messageType': filters.messageType.toString(),
        'channelId': filters.channelId,
        'limit': filters.limit,
        'offset': filters.offset,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      query: json['query'],
      type: SearchType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => SearchType.all,
      ),
      filters: SearchFilters(
        startDate: json['filters']['startDate'] != null
            ? DateTime.parse(json['filters']['startDate'])
            : null,
        endDate: json['filters']['endDate'] != null
            ? DateTime.parse(json['filters']['endDate'])
            : null,
        senderId: json['filters']['senderId'],
        messageType: MessageType.values.firstWhere(
          (e) => e.toString() == json['filters']['messageType'],
          orElse: () => MessageType.all,
        ),
        channelId: json['filters']['channelId'],
        limit: json['filters']['limit'] ?? 50,
        offset: json['filters']['offset'] ?? 0,
      ),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
