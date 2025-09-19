// lib/services/presence_service.dart
import 'dart:async';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/models/presence_models.dart';

/// Service for managing user presence and typing indicators
class PresenceService {
  final Map<String, Timer> _typingTimers = {};
  final Map<String, StreamController<bool>> _typingControllers = {};
  final Map<String, StreamController<UserPresence>> _presenceControllers = {};

  /// Start typing indicator for a channel
  Future<void> startTyping(StreamChatClient client, String channelId) async {
    try {
      // Send typing start event
      final channel = client.channel('messaging', id: channelId);
      // Note: The actual typing API may vary based on GetStream SDK version
      // This is a simplified implementation

      // Set up typing timer
      _typingTimers[channelId]?.cancel();
      _typingTimers[channelId] = Timer(const Duration(seconds: 3), () {
        stopTyping(client, channelId);
      });

      // Notify listeners
      _typingControllers[channelId]?.add(true);
    } catch (e) {
      print('Failed to start typing: $e');
    }
  }

  /// Stop typing indicator for a channel
  Future<void> stopTyping(StreamChatClient client, String channelId) async {
    try {
      // Send typing stop event
      final channel = client.channel('messaging', id: channelId);
      // Note: The actual typing API may vary based on GetStream SDK version
      // This is a simplified implementation

      // Cancel timer
      _typingTimers[channelId]?.cancel();
      _typingTimers.remove(channelId);

      // Notify listeners
      _typingControllers[channelId]?.add(false);
    } catch (e) {
      print('Failed to stop typing: $e');
    }
  }

  /// Update current user presence
  Future<void> updateCurrentUserPresence(
    StreamChatClient client,
    UserPresence presence, {
    String? currentChannelId,
  }) async {
    try {
      final currentUser = client.state.currentUser;
      if (currentUser == null) return;

      // Update user presence in GetStream
      final updatedUser = currentUser.copyWith(
        extraData: {
          ...currentUser.extraData,
          'status': presence.status.toString(),
          'lastSeen': presence.lastSeen?.toIso8601String(),
          'isOnline': presence.isOnline,
        },
      );

      await client.updateUser(updatedUser);

      // Notify listeners
      _presenceControllers[currentUser.id]?.add(presence);
    } catch (e) {
      print('Failed to update presence: $e');
    }
  }

  /// Handle typing event from GetStream
  void handleTypingEvent(Event event, bool isTyping) {
    final channelId = event.cid?.split(':').last;
    if (channelId != null) {
      _typingControllers[channelId]?.add(isTyping);
    }
  }

  /// Get typing stream for a channel
  Stream<bool> getTypingStream(String channelId) {
    if (!_typingControllers.containsKey(channelId)) {
      _typingControllers[channelId] = StreamController<bool>.broadcast();
    }
    return _typingControllers[channelId]!.stream;
  }

  /// Get presence stream for a user
  Stream<UserPresence> getPresenceStream(String userId) {
    if (!_presenceControllers.containsKey(userId)) {
      _presenceControllers[userId] = StreamController<UserPresence>.broadcast();
    }
    return _presenceControllers[userId]!.stream;
  }

  /// Clean up resources
  void dispose() {
    // Cancel all timers
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    _typingTimers.clear();

    // Close all controllers
    for (final controller in _typingControllers.values) {
      controller.close();
    }
    _typingControllers.clear();

    for (final controller in _presenceControllers.values) {
      controller.close();
    }
    _presenceControllers.clear();
  }
}
