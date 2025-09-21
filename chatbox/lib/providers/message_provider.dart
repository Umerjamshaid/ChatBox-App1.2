// lib/providers/message_provider.dart
import 'package:flutter/foundation.dart';
import 'package:chatbox/services/chat_service.dart';

class MessageProvider with ChangeNotifier {
  final ChatService _chatService;

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String? _currentChannelId;
  bool _hasMoreMessages = true;
  int _currentPage = 0;
  final int _messagesPerPage = 50;

  MessageProvider(this._chatService) {
    _initialize();
  }

  // Getters
  List<Map<String, dynamic>> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  String? get currentChannelId => _currentChannelId;
  bool get hasMoreMessages => _hasMoreMessages;
  int get messageCount => _messages.length;

  void _initialize() {
    // Listen to message updates from ChatService
    _chatService.messagesStream.listen((messages) {
      _messages = messages;
      _error = null;
      notifyListeners();
    });
  }

  /// Load messages for a channel
  Future<void> loadMessages(
    String channelId, {
    bool forceRefresh = false,
  }) async {
    if (_isLoading || (_currentChannelId == channelId && !forceRefresh)) return;

    _isLoading = true;
    _error = null;
    _currentChannelId = channelId;
    _currentPage = 0;
    _hasMoreMessages = true;
    notifyListeners();

    try {
      await _chatService.loadMessages(
        channelId,
        limit: _messagesPerPage,
        forceRefresh: forceRefresh,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more messages (pagination)
  Future<void> loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages || _currentChannelId == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      // In a real implementation, this would load the next page
      // For now, we'll simulate loading more messages
      await Future.delayed(const Duration(seconds: 1));

      // Check if we have more messages
      if (_currentPage >= 3) {
        // Simulate end of messages
        _hasMoreMessages = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Send a message
  Future<Map<String, dynamic>?> sendMessage(String text) async {
    if (_currentChannelId == null) return null;

    try {
      final message = await _chatService.sendMessage(_currentChannelId!, text);
      return message;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _chatService.deleteMessage(messageId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Add reaction to message
  Future<bool> addReaction(String messageId, String reactionType) async {
    try {
      await _chatService.addReaction(messageId, reactionType);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Remove reaction from message
  Future<bool> removeReaction(String messageId, String reactionType) async {
    try {
      await _chatService.removeReaction(messageId, reactionType);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Start typing
  Future<void> startTyping() async {
    if (_currentChannelId != null) {
      await _chatService.startTyping(_currentChannelId!);
    }
  }

  /// Stop typing
  Future<void> stopTyping() async {
    if (_currentChannelId != null) {
      await _chatService.stopTyping(_currentChannelId!);
    }
  }

  /// Get message by ID
  Map<String, dynamic>? getMessageById(String messageId) {
    return _messages.firstWhere(
      (message) => message['id'] == messageId,
      orElse: () => {},
    );
  }

  /// Get messages for current channel
  List<Map<String, dynamic>> getCurrentChannelMessages() {
    if (_currentChannelId == null) return [];
    return _messages
        .where((message) => message['channelId'] == _currentChannelId)
        .toList();
  }

  /// Get unread message count for a channel
  int getUnreadCount(String channelId) {
    return _messages
        .where(
          (message) =>
              message['channelId'] == channelId &&
              message['status'] != 'read' &&
              message['userId'] != _chatService.currentChannelId,
        ) // Not from current user
        .length;
  }

  /// Mark all messages as read
  Future<void> markAllAsRead() async {
    if (_currentChannelId == null) return;

    try {
      for (var message in _messages) {
        if (message['channelId'] == _currentChannelId &&
            message['status'] != 'read') {
          message['status'] = 'read';
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Clear messages for current channel
  void clearMessages() {
    _messages.clear();
    _currentPage = 0;
    _hasMoreMessages = true;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh messages
  Future<void> refresh() async {
    if (_currentChannelId != null) {
      await loadMessages(_currentChannelId!, forceRefresh: true);
    }
  }
}
