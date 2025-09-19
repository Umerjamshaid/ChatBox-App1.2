// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/constants/app_constants.dart';

class NotificationService {
  final StreamChatService _streamService;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _openedAppSubscription;

  NotificationService(this._streamService);

  /// Initialize push notifications
  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermission();

    // Get FCM token
    final fcmToken = await _firebaseMessaging.getToken();
    if (fcmToken != null) {
      await _registerDeviceToken(fcmToken);
    }

    // Listen for token updates
    _firebaseMessaging.onTokenRefresh.listen(_registerDeviceToken);

    // Handle incoming messages
    _setupMessageHandlers();

    // Handle notification taps when app is in background
    _setupNotificationTapHandler();
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Register device token with GetStream
  Future<void> _registerDeviceToken(String token) async {
    try {
      // Register device token with GetStream
      // Using the correct API based on GetStream Flutter SDK
      await _streamService.client.addDevice(token, PushProvider.firebase);

      print('Device token registered with GetStream: $token');
    } catch (e) {
      print('Failed to register device token: $e');
    }
  }

  /// Set up message handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );

    // Handle messages when app is opened from notification
    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleNotificationTap,
    );
  }

  /// Set up notification tap handler
  void _setupNotificationTapHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.notification?.title}');

    final data = message.data;
    if (data.containsKey('stream_chat')) {
      _handleStreamChatNotification(data);
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.notification?.title}');

    final data = message.data;
    if (data.containsKey('stream_chat')) {
      _handleStreamChatNotificationTap(data);
    }
  }

  /// Handle GetStream chat notifications
  void _handleStreamChatNotification(Map<String, dynamic> data) {
    try {
      final streamData = jsonDecode(data['stream_chat']);
      final eventType = streamData['type'];
      final channelId = streamData['channel_id'];
      final messageText = streamData['message']?['text'];
      final senderName = streamData['user']?['name'];

      // Show local notification or update UI
      _showLocalNotification(
        title: senderName ?? 'New Message',
        body: messageText ?? 'You have a new message',
        channelId: channelId,
      );
    } catch (e) {
      print('Failed to handle Stream chat notification: $e');
    }
  }

  /// Handle GetStream chat notification tap
  void _handleStreamChatNotificationTap(Map<String, dynamic> data) {
    try {
      final streamData = jsonDecode(data['stream_chat']);
      final channelId = streamData['channel_id'];

      // Navigate to the channel
      _navigateToChannel(channelId);
    } catch (e) {
      print('Failed to handle Stream chat notification tap: $e');
    }
  }

  /// Show local notification
  void _showLocalNotification({
    required String title,
    required String body,
    String? channelId,
  }) {
    // In a real implementation, you would use flutter_local_notifications
    // or another local notification package
    print('Showing local notification: $title - $body');
  }

  /// Navigate to channel
  void _navigateToChannel(String channelId) {
    // In a real implementation, you would use a navigation service
    // or emit an event to navigate to the channel
    print('Navigating to channel: $channelId');
  }

  /// Send test notification
  Future<void> sendTestNotification({
    required String title,
    required String body,
    String? channelId,
  }) async {
    // This would be used for testing notifications
    _showLocalNotification(title: title, body: body, channelId: channelId);
  }

  /// Get notification settings
  Future<NotificationSettings> getNotificationSettings() async {
    return await _firebaseMessaging.getNotificationSettings();
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Delete FCM token
  Future<void> deleteFCMToken() async {
    await _firebaseMessaging.deleteToken();
  }

  /// Handle notification settings change
  Future<void> handleNotificationSettingsChange(bool enabled) async {
    if (enabled) {
      await _requestPermission();
      final token = await getFCMToken();
      if (token != null) {
        await _registerDeviceToken(token);
      }
    } else {
      await deleteFCMToken();
    }
  }

  /// Clean up resources
  void dispose() {
    _messageSubscription?.cancel();
    _openedAppSubscription?.cancel();
  }
}

/// Notification payload structure for GetStream
class StreamChatNotificationPayload {
  final String type;
  final String channelId;
  final String channelType;
  final Map<String, dynamic>? message;
  final Map<String, dynamic>? user;

  StreamChatNotificationPayload({
    required this.type,
    required this.channelId,
    required this.channelType,
    this.message,
    this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'channel_id': channelId,
      'channel_type': channelType,
      'message': message,
      'user': user,
    };
  }

  factory StreamChatNotificationPayload.fromJson(Map<String, dynamic> json) {
    return StreamChatNotificationPayload(
      type: json['type'],
      channelId: json['channel_id'],
      channelType: json['channel_type'],
      message: json['message'],
      user: json['user'],
    );
  }
}
