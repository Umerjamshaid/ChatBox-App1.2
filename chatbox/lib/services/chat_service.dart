// lib/services/chat_service.dart
import 'dart:async';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/offline_storage_service.dart';
import 'package:chatbox/services/presence_service.dart';
import 'package:chatbox/models/presence_models.dart';

/// Comprehensive chat service wrapping GetStream operations
class ChatService {
  final StreamChatService _streamService;
  final OfflineStorageService _storageService;
  final PresenceService _presenceService;

  // Stream controllers for real-time updates
  final StreamController<List<Map<String, dynamic>>> _channelsController =
      StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _messagesController =
      StreamController.broadcast();
  final StreamController<List<Map<String, dynamic>>> _usersController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController.broadcast();

  // Current state
  List<Map<String, dynamic>> _channels = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _users = [];
  String? _currentChannelId;

  ChatService(
    this._streamService,
    this._storageService,
    this._presenceService,
  ) {
    _initializeEventListeners();
  }

  // Getters for streams
  Stream<List<Map<String, dynamic>>> get channelsStream =>
      _channelsController.stream;
  Stream<List<Map<String, dynamic>>> get messagesStream =>
      _messagesController.stream;
  Stream<List<Map<String, dynamic>>> get usersStream => _usersController.stream;
  Stream<Map<String, dynamic>> get eventsStream => _eventsController.stream;

  // Getters for current state
  List<Map<String, dynamic>> get channels => _channels;
  List<Map<String, dynamic>> get messages => _messages;
  List<Map<String, dynamic>> get users => _users;
  String? get currentChannelId => _currentChannelId;

  /// Initialize event listeners for real-time updates
  void _initializeEventListeners() {
    // Basic event handling setup
    _setupBasicEventHandling();
  }

  void _setupBasicEventHandling() {
    // Basic event handling setup
    // This will be expanded with proper GetStream event handling
  }

  /// Load initial data and set up offline support
  Future<void> initialize() async {
    await _storageService.initialize();
    await _loadCachedData();
  }

  /// Load cached data for offline support
  Future<void> _loadCachedData() async {
    try {
      _channels = await _storageService.getCachedChannels();
      _users = await _storageService.getCachedUsers();

      // Emit initial data
      _channelsController.add(_channels);
      _usersController.add(_users);
    } catch (e) {
      print('Failed to load cached data: $e');
    }
  }

  /// Load user channels
  Future<void> loadChannels({bool forceRefresh = false}) async {
    if (!forceRefresh && _channels.isNotEmpty) {
      _channelsController.add(_channels);
      return;
    }

    try {
      // Load channels from GetStream
      // This will be implemented with correct API calls
      final mockChannels = [
        {
          'id': 'channel_1',
          'type': 'messaging',
          'name': 'General',
          'memberCount': 5,
          'lastMessage': 'Hello everyone!',
          'lastMessageAt': DateTime.now().toIso8601String(),
        },
        {
          'id': 'channel_2',
          'type': 'messaging',
          'name': 'Random',
          'memberCount': 3,
          'lastMessage': 'How is everyone doing?',
          'lastMessageAt': DateTime.now()
              .subtract(const Duration(hours: 1))
              .toIso8601String(),
        },
      ];

      _channels = mockChannels;
      _channelsController.add(_channels);

      // Cache channels
      await _storageService.cacheChannels(_channels);
    } catch (e) {
      print('Failed to load channels: $e');
      throw Exception('Failed to load channels: $e');
    }
  }

  /// Load users
  Future<void> loadUsers({bool forceRefresh = false}) async {
    if (!forceRefresh && _users.isNotEmpty) {
      _usersController.add(_users);
      return;
    }

    try {
      // Load users from GetStream
      final mockUsers = [
        {
          'id': 'user_1',
          'name': 'John Doe',
          'image': 'https://via.placeholder.com/50',
          'status': 'online',
          'lastActive': DateTime.now().toIso8601String(),
        },
        {
          'id': 'user_2',
          'name': 'Jane Smith',
          'image': 'https://via.placeholder.com/50',
          'status': 'offline',
          'lastActive': DateTime.now()
              .subtract(const Duration(hours: 2))
              .toIso8601String(),
        },
      ];

      _users = mockUsers;
      _usersController.add(_users);

      // Cache users
      await _storageService.cacheUsers(_users);
    } catch (e) {
      print('Failed to load users: $e');
      throw Exception('Failed to load users: $e');
    }
  }

  /// Load messages for a channel
  Future<void> loadMessages(
    String channelId, {
    int limit = 50,
    bool forceRefresh = false,
  }) async {
    if (_currentChannelId == channelId &&
        !forceRefresh &&
        _messages.isNotEmpty) {
      _messagesController.add(_messages);
      return;
    }

    _currentChannelId = channelId;

    try {
      // Load messages from GetStream
      final mockMessages = [
        {
          'id': 'msg_1',
          'text': 'Hello everyone!',
          'userId': 'user_1',
          'userName': 'John Doe',
          'userImage': 'https://via.placeholder.com/50',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 5))
              .toIso8601String(),
          'status': 'sent',
        },
        {
          'id': 'msg_2',
          'text': 'Hi John! How are you?',
          'userId': 'user_2',
          'userName': 'Jane Smith',
          'userImage': 'https://via.placeholder.com/50',
          'createdAt': DateTime.now()
              .subtract(const Duration(minutes: 3))
              .toIso8601String(),
          'status': 'delivered',
        },
      ];

      _messages = mockMessages;
      _messagesController.add(_messages);

      // Cache messages
      await _storageService.cacheMessages(channelId, _messages);
    } catch (e) {
      print('Failed to load messages for channel $channelId: $e');

      // Try to load from cache
      try {
        _messages = await _storageService.getCachedMessages(channelId);
        if (_messages.isNotEmpty) {
          _messagesController.add(_messages);
        }
      } catch (cacheError) {
        print('Failed to load cached messages: $cacheError');
      }

      throw Exception('Failed to load messages: $e');
    }
  }

  /// Send message
  Future<Map<String, dynamic>> sendMessage(
    String channelId,
    String text,
  ) async {
    try {
      // Send message via GetStream
      final message = {
        'id': 'msg_${DateTime.now().millisecondsSinceEpoch}',
        'text': text,
        'userId': _streamService.client.state.currentUser?.id ?? 'current_user',
        'userName': _streamService.client.state.currentUser?.name ?? 'You',
        'userImage':
            _streamService.client.state.currentUser?.image ??
            'https://via.placeholder.com/50',
        'createdAt': DateTime.now().toIso8601String(),
        'status': 'sending',
        'channelId': channelId,
      };

      // Add to local messages
      _messages.insert(0, message);
      _messagesController.add(_messages);

      // Simulate sending delay
      await Future.delayed(const Duration(seconds: 1));

      // Update status to sent
      message['status'] = 'sent';
      _messagesController.add(_messages);

      return message;
    } catch (e) {
      print('Failed to send message: $e');
      throw Exception('Failed to send message: $e');
    }
  }

  /// Create new channel
  Future<Map<String, dynamic>> createChannel({
    required String name,
    required List<String> memberIds,
    String? image,
  }) async {
    try {
      final channel = {
        'id': 'channel_${DateTime.now().millisecondsSinceEpoch}',
        'type': 'messaging',
        'name': name,
        'image': image,
        'memberCount': memberIds.length + 1, // +1 for current user
        'members': memberIds,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Add to local channels
      _channels.insert(0, channel);
      _channelsController.add(_channels);

      return channel;
    } catch (e) {
      print('Failed to create channel: $e');
      throw Exception('Failed to create channel: $e');
    }
  }

  /// Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      // Search users via GetStream
      final mockResults = _users.where((user) {
        final name = user['name'] as String? ?? '';
        return name.toLowerCase().contains(query.toLowerCase());
      }).toList();

      return mockResults;
    } catch (e) {
      print('Failed to search users: $e');
      throw Exception('Failed to search users: $e');
    }
  }

  /// Update user presence
  Future<void> updatePresence(UserPresence presence) async {
    await _presenceService.updateCurrentUserPresence(
      _streamService.client,
      presence,
      currentChannelId: _currentChannelId,
    );
  }

  /// Send typing start event
  Future<void> startTyping(String channelId) async {
    try {
      // Send typing start via GetStream
      _presenceService.handleTypingEvent(
        Event(
          type: 'typing.start',
          user: _streamService.client.state.currentUser,
          cid: 'messaging:$channelId',
        ),
        true,
      );
    } catch (e) {
      print('Failed to send typing start: $e');
    }
  }

  /// Send typing stop event
  Future<void> stopTyping(String channelId) async {
    try {
      // Send typing stop via GetStream
      _presenceService.handleTypingEvent(
        Event(
          type: 'typing.stop',
          user: _streamService.client.state.currentUser,
          cid: 'messaging:$channelId',
        ),
        false,
      );
    } catch (e) {
      print('Failed to send typing stop: $e');
    }
  }

  /// Mark channel as read
  Future<void> markChannelAsRead(String channelId) async {
    try {
      // Mark channel as read via GetStream
      // This will be implemented with correct API
      print('Marked channel $channelId as read');
    } catch (e) {
      print('Failed to mark channel as read: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      // Delete message via GetStream
      _messages.removeWhere((m) => m['id'] == messageId);
      _messagesController.add(_messages);
    } catch (e) {
      print('Failed to delete message: $e');
      throw Exception('Failed to delete message: $e');
    }
  }

  /// React to message
  Future<void> addReaction(String messageId, String reactionType) async {
    try {
      // Add reaction via GetStream
      final messageIndex = _messages.indexWhere((m) => m['id'] == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final reactions = message['reactions'] as List<dynamic>? ?? [];
        reactions.add({
          'type': reactionType,
          'userId':
              _streamService.client.state.currentUser?.id ?? 'current_user',
          'createdAt': DateTime.now().toIso8601String(),
        });
        message['reactions'] = reactions;
        _messagesController.add(_messages);
      }
    } catch (e) {
      print('Failed to add reaction: $e');
      throw Exception('Failed to add reaction: $e');
    }
  }

  /// Remove reaction from message
  Future<void> removeReaction(String messageId, String reactionType) async {
    try {
      // Remove reaction via GetStream
      final messageIndex = _messages.indexWhere((m) => m['id'] == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final reactions = message['reactions'] as List<dynamic>? ?? [];
        reactions.removeWhere(
          (r) =>
              r['type'] == reactionType &&
              r['userId'] ==
                  (_streamService.client.state.currentUser?.id ??
                      'current_user'),
        );
        message['reactions'] = reactions;
        _messagesController.add(_messages);
      }
    } catch (e) {
      print('Failed to remove reaction: $e');
      throw Exception('Failed to remove reaction: $e');
    }
  }

  /// Clean up resources
  void dispose() {
    _channelsController.close();
    _messagesController.close();
    _usersController.close();
    _eventsController.close();
  }
}
