// lib/services/scheduled_message_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/models/scheduled_message.dart';

class ScheduledMessageService {
  static const String _scheduledMessagesKey = 'scheduled_messages';
  final SharedPreferences _prefs;

  ScheduledMessageService(this._prefs);

  // Timer for checking scheduled messages
  Timer? _schedulerTimer;

  void startScheduler() {
    // Check every minute for messages to send
    _schedulerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndSendScheduledMessages();
    });
  }

  void stopScheduler() {
    _schedulerTimer?.cancel();
    _schedulerTimer = null;
  }

  Future<List<ScheduledMessage>> getScheduledMessages() async {
    try {
      final messagesJson = _prefs.getString(_scheduledMessagesKey);
      if (messagesJson == null) return [];

      final messagesList = jsonDecode(messagesJson) as List;
      return messagesList
          .map((msg) => ScheduledMessage.fromJson(msg))
          .where((msg) => !msg.isSent) // Only return unsent messages
          .toList();
    } catch (e) {
      print('Error loading scheduled messages: $e');
      return [];
    }
  }

  Future<List<ScheduledMessage>> getAllScheduledMessages() async {
    try {
      final messagesJson = _prefs.getString(_scheduledMessagesKey);
      if (messagesJson == null) return [];

      final messagesList = jsonDecode(messagesJson) as List;
      return messagesList.map((msg) => ScheduledMessage.fromJson(msg)).toList();
    } catch (e) {
      print('Error loading all scheduled messages: $e');
      return [];
    }
  }

  Future<void> scheduleMessage({
    required String channelId,
    required String text,
    required DateTime scheduledTime,
    List<Attachment> attachments = const [],
    required String userId,
  }) async {
    final message = ScheduledMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      channelId: channelId,
      text: text,
      attachments: attachments,
      scheduledTime: scheduledTime,
      createdAt: DateTime.now(),
      createdBy: userId,
    );

    final messages = await getAllScheduledMessages();
    messages.add(message);

    final messagesJson = messages.map((msg) => msg.toJson()).toList();
    await _prefs.setString(_scheduledMessagesKey, jsonEncode(messagesJson));
  }

  Future<void> cancelScheduledMessage(String messageId) async {
    final messages = await getAllScheduledMessages();
    messages.removeWhere((msg) => msg.id == messageId);

    final messagesJson = messages.map((msg) => msg.toJson()).toList();
    await _prefs.setString(_scheduledMessagesKey, jsonEncode(messagesJson));
  }

  Future<void> _checkAndSendScheduledMessages() async {
    final now = DateTime.now();
    final messages = await getAllScheduledMessages();

    for (final message in messages) {
      if (!message.isSent && message.scheduledTime.isBefore(now)) {
        await _sendScheduledMessage(message);
      }
    }
  }

  Future<void> _sendScheduledMessage(ScheduledMessage scheduledMessage) async {
    try {
      // Get StreamChat client - this would need to be injected or accessed differently
      // For now, we'll mark as sent but in a real implementation you'd send via StreamChat
      print('Sending scheduled message: ${scheduledMessage.text}');

      // Update the message as sent
      await _markMessageAsSent(scheduledMessage.id);

      // In a real implementation, you would:
      // final client = StreamChat.of(context).client;
      // final channel = client.channel('messaging', id: scheduledMessage.channelId);
      // await channel.sendMessage(Message(
      //   text: scheduledMessage.text,
      //   attachments: scheduledMessage.attachments,
      // ));
    } catch (e) {
      print('Failed to send scheduled message: $e');
      await _markMessageAsFailed(scheduledMessage.id, e.toString());
    }
  }

  Future<void> _markMessageAsSent(String messageId) async {
    await _updateMessageStatus(messageId, isSent: true, sentAt: DateTime.now());
  }

  Future<void> _markMessageAsFailed(String messageId, String reason) async {
    await _updateMessageStatus(messageId, failureReason: reason);
  }

  Future<void> _updateMessageStatus(
    String messageId, {
    bool? isSent,
    DateTime? sentAt,
    String? failureReason,
  }) async {
    final messages = await getAllScheduledMessages();
    final index = messages.indexWhere((msg) => msg.id == messageId);

    if (index >= 0) {
      messages[index] = messages[index].copyWith(
        isSent: isSent,
        sentAt: sentAt,
        failureReason: failureReason,
      );

      final messagesJson = messages.map((msg) => msg.toJson()).toList();
      await _prefs.setString(_scheduledMessagesKey, jsonEncode(messagesJson));
    }
  }

  Future<int> getPendingMessageCount() async {
    final messages = await getScheduledMessages();
    return messages.length;
  }

  Future<List<ScheduledMessage>> getMessagesForChannel(String channelId) async {
    final messages = await getAllScheduledMessages();
    return messages.where((msg) => msg.channelId == channelId).toList();
  }
}
