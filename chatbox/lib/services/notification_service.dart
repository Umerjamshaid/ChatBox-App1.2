// lib/services/notification_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/call_service.dart';

// Background task callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Perform background refresh
    // This would typically check for new messages and update local storage
    return Future.value(true);
  });
}

class NotificationService {
  final StreamChatService _streamService;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription? _messageSubscription;
  StreamSubscription? _openedAppSubscription;

  // Notification settings
  bool _isDndEnabled = false;
  TimeOfDay? _dndStartTime;
  TimeOfDay? _dndEndTime;
  bool _showMessagePreview = true;
  String _notificationSound = 'default';
  bool _vibrationEnabled = true;

  // Analytics tracking
  int _notificationsSent = 0;
  int _notificationsOpened = 0;
  Map<String, int> _categoryStats = {};

  NotificationService(this._streamService);

  /// Initialize push notifications
  Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();

    // Load settings
    await _loadSettings();

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

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel messagesChannel =
        AndroidNotificationChannel(
          'messages',
          'Messages',
          description: 'New messages from chats',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

    const AndroidNotificationChannel mentionsChannel =
        AndroidNotificationChannel(
          'mentions',
          'Mentions',
          description: '@mentions and replies',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: true,
        );

    const AndroidNotificationChannel groupsChannel = AndroidNotificationChannel(
      'groups',
      'Group Updates',
      description: 'Group messages and updates',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    const AndroidNotificationChannel callsChannel = AndroidNotificationChannel(
      'calls',
      'Calls',
      description: 'Incoming calls and call notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
      enableLights: true,
      ledColor: const Color(0xFF00FF00),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(messagesChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(mentionsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(groupsChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(callsChannel);
  }

  /// Load notification settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isDndEnabled = prefs.getBool('dnd_enabled') ?? false;
    _showMessagePreview = prefs.getBool('show_message_preview') ?? true;
    _notificationSound = prefs.getString('notification_sound') ?? 'default';
    _vibrationEnabled = prefs.getBool('vibration_enabled') ?? true;

    final dndStart = prefs.getString('dnd_start_time');
    final dndEnd = prefs.getString('dnd_end_time');

    if (dndStart != null) {
      final parts = dndStart.split(':');
      _dndStartTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    if (dndEnd != null) {
      final parts = dndEnd.split(':');
      _dndEndTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    final actionId = response.actionId;

    if (payload != null) {
      if (actionId == 'reply') {
        // Handle reply action
        _handleReplyAction(payload);
      } else if (actionId == 'mark_read') {
        // Handle mark as read action
        _handleMarkAsReadAction(payload);
      } else if (actionId == 'accept_call') {
        // Handle accept call action
        _handleAcceptCallAction(payload);
      } else if (actionId == 'decline_call') {
        // Handle decline call action
        _handleDeclineCallAction(payload);
      } else if (payload.startsWith('call:')) {
        // Handle call notification tap
        _handleCallNotificationTap(payload);
      } else if (payload.startsWith('missed_call:')) {
        // Handle missed call notification tap
        _handleMissedCallNotificationTap(payload);
      } else {
        // Regular tap - navigate to channel
        _navigateToChannel(payload);
        trackNotificationOpened();
      }
    }
  }

  /// Handle reply action from notification
  void _handleReplyAction(String channelId) {
    // In a real implementation, this would open a reply input
    // For now, just navigate to the channel
    _navigateToChannel(channelId);
    print('Reply action triggered for channel: $channelId');
  }

  /// Handle mark as read action from notification
  void _handleMarkAsReadAction(String channelId) {
    // Mark channel as read in GetStream
    // This would typically call the StreamChatService to mark as read
    print('Mark as read action triggered for channel: $channelId');
  }

  /// Handle accept call action from notification
  void _handleAcceptCallAction(String payload) {
    // Parse call payload: call:callId:callerId:callerName:callType
    final parts = payload.split(':');
    if (parts.length >= 5 && parts[0] == 'call') {
      final callId = parts[1];
      final callerId = parts[2];
      final callerName = parts[3];
      final callType = parts[4];

      // Navigate to call screen and accept the call
      _navigateToCallScreen(
        callId,
        callerId,
        callerName,
        callType,
        accept: true,
      );
      print('Accept call action triggered for call: $callId');
    }
  }

  /// Handle decline call action from notification
  void _handleDeclineCallAction(String payload) {
    // Parse call payload: call:callId:callerId:callerName:callType
    final parts = payload.split(':');
    if (parts.length >= 5 && parts[0] == 'call') {
      final callId = parts[1];
      final callerId = parts[2];
      final callerName = parts[3];
      final callType = parts[4];

      // Decline the call and show missed call notification
      _declineCall(callId, callerId, callerName, callType);
      print('Decline call action triggered for call: $callId');
    }
  }

  /// Handle call notification tap
  void _handleCallNotificationTap(String payload) {
    // Parse call payload: call:callId:callerId:callerName:callType
    final parts = payload.split(':');
    if (parts.length >= 5 && parts[0] == 'call') {
      final callId = parts[1];
      final callerId = parts[2];
      final callerName = parts[3];
      final callType = parts[4];

      // Navigate to call screen
      _navigateToCallScreen(
        callId,
        callerId,
        callerName,
        callType,
        accept: false,
      );
      print('Call notification tapped for call: $callId');
    }
  }

  /// Handle missed call notification tap
  void _handleMissedCallNotificationTap(String payload) {
    // Parse missed call payload: missed_call:callerId:callerName:callType
    final parts = payload.split(':');
    if (parts.length >= 4 && parts[0] == 'missed_call') {
      final callerId = parts[1];
      final callerName = parts[2];
      final callType = parts[3];

      // Navigate to call history or start new call
      _navigateToCallHistory();
      print('Missed call notification tapped for: $callerName');
    }
  }

  /// Check if current time is within quiet hours
  bool _isInQuietHours() {
    if (!_isDndEnabled || _dndStartTime == null || _dndEndTime == null) {
      return false;
    }

    final now = TimeOfDay.now();
    final start = _dndStartTime!;
    final end = _dndEndTime!;

    if (start.hour < end.hour ||
        (start.hour == end.hour && start.minute < end.minute)) {
      // Same day range
      return (now.hour > start.hour ||
              (now.hour == start.hour && now.minute >= start.minute)) &&
          (now.hour < end.hour ||
              (now.hour == end.hour && now.minute <= end.minute));
    } else {
      // Overnight range
      return now.hour > start.hour ||
          (now.hour == start.hour && now.minute >= start.minute) ||
          now.hour < end.hour ||
          (now.hour == end.hour && now.minute <= end.minute);
    }
  }

  /// Get notification sound
  AndroidNotificationSound? _getNotificationSound() {
    if (!_vibrationEnabled) return null;

    // For now, return null to use default sound
    // In a real implementation, you would return custom sound files
    return null;
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

      // Determine notification category
      String category = 'messages';
      if (messageText?.contains('@') ?? false) {
        category = 'mentions';
      } else if (streamData['channel_type'] == 'group' ||
          channelId.contains('!members')) {
        category = 'groups';
      }

      // Show local notification
      _showLocalNotification(
        title: senderName ?? 'New Message',
        body: _showMessagePreview
            ? (messageText ?? 'You have a new message')
            : 'New message',
        channelId: channelId,
        payload: channelId,
        category: category,
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
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? channelId,
    String? payload,
    String category = 'messages',
  }) async {
    // Check if DND is enabled
    if (_isDndEnabled && _isInQuietHours()) {
      print('Skipping notification due to DND mode');
      return;
    }

    // Check per-chat settings if channelId provided
    if (channelId != null) {
      final chatSettings = await getChatNotificationSettings(channelId);
      if (!(chatSettings['enabled'] as bool)) {
        return; // Notifications disabled for this chat
      }
    }

    // Determine notification channel
    String channelIdToUse = 'messages';
    if (category == 'mentions') {
      channelIdToUse = 'mentions';
    } else if (category == 'groups') {
      channelIdToUse = 'groups';
    }

    // Get chat-specific settings
    bool usePreview = _showMessagePreview;
    bool useVibration = _vibrationEnabled;
    if (channelId != null) {
      final chatSettings = await getChatNotificationSettings(channelId);
      usePreview = chatSettings['preview'] ?? _showMessagePreview;
      useVibration = chatSettings['vibration'] ?? _vibrationEnabled;
    }

    // Action buttons for Android
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction('reply', 'Reply'),
      const AndroidNotificationAction('mark_read', 'Mark as Read'),
    ];

    // Prepare notification details
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          channelIdToUse,
          category == 'messages'
              ? 'Messages'
              : category == 'mentions'
              ? 'Mentions'
              : 'Group Updates',
          channelDescription: 'Chat notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: useVibration,
          enableVibration: useVibration,
          sound: _getNotificationSound(),
          styleInformation: usePreview
              ? BigTextStyleInformation(body)
              : DefaultStyleInformation(true, true),
          actions: actions,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _localNotifications.show(
      notificationId,
      title,
      usePreview ? body : 'New message',
      details,
      payload: payload ?? channelId,
    );

    // Track analytics
    trackNotificationSent(category);
  }

  /// Navigate to channel
  void _navigateToChannel(String channelId) {
    // In a real implementation, you would use a navigation service
    // or emit an event to navigate to the channel
    print('Navigating to channel: $channelId');
  }

  /// Navigate to call screen
  void _navigateToCallScreen(
    String callId,
    String callerId,
    String callerName,
    String callType, {
    required bool accept,
  }) {
    // In a real implementation, you would use a navigation service
    // or emit an event to navigate to the call screen
    print('Navigating to call screen: $callId, accept: $accept');
  }

  /// Decline call
  void _declineCall(
    String callId,
    String callerId,
    String callerName,
    String callType,
  ) {
    // In a real implementation, you would call the call service to decline
    // and show a missed call notification
    print('Declining call: $callId');
  }

  /// Navigate to call history
  void _navigateToCallHistory() {
    // In a real implementation, you would navigate to the call history screen
    print('Navigating to call history');
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

  /// Show incoming call notification
  Future<void> showIncomingCallNotification({
    required String callerId,
    required String callerName,
    required CallType callType,
    required String callId,
  }) async {
    // Action buttons for call notification
    final List<AndroidNotificationAction> actions = [
      const AndroidNotificationAction(
        'accept_call',
        'Accept',
        showsUserInterface: true,
      ),
      const AndroidNotificationAction('decline_call', 'Decline'),
    ];

    // Prepare notification details
    final AndroidNotificationDetails
    androidDetails = AndroidNotificationDetails(
      'calls',
      'Calls',
      channelDescription: 'Incoming calls',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      sound: _getNotificationSound(),
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      actions: actions,
      styleInformation: BigTextStyleInformation(
        '${callType == CallType.video ? 'Video' : 'Voice'} call from $callerName',
      ),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = 'incoming_call_$callId'.hashCode;

    await _localNotifications.show(
      notificationId,
      callerName,
      '${callType == CallType.video ? 'Video' : 'Voice'} call',
      details,
      payload: 'call:$callId:$callerId:$callerName:${callType.name}',
    );
  }

  /// Cancel incoming call notification
  Future<void> cancelIncomingCallNotification(String callId) async {
    final notificationId = 'incoming_call_$callId'.hashCode;
    await _localNotifications.cancel(notificationId);
  }

  /// Show missed call notification
  Future<void> showMissedCallNotification({
    required String callerId,
    required String callerName,
    required CallType callType,
  }) async {
    await _showLocalNotification(
      title: 'Missed ${callType == CallType.video ? 'Video' : 'Voice'} Call',
      body: 'You missed a call from $callerName',
      category: 'calls',
      payload: 'missed_call:$callerId:$callerName:${callType.name}',
    );
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

  /// Set Do Not Disturb mode
  Future<void> setDndMode(
    bool enabled, {
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _isDndEnabled = enabled;
    if (enabled) {
      _dndStartTime = startTime;
      _dndEndTime = endTime;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dnd_enabled', enabled);
    if (startTime != null) {
      await prefs.setString(
        'dnd_start_time',
        '${startTime.hour}:${startTime.minute}',
      );
    }
    if (endTime != null) {
      await prefs.setString(
        'dnd_end_time',
        '${endTime.hour}:${endTime.minute}',
      );
    }
  }

  /// Set message preview preference
  Future<void> setMessagePreview(bool enabled) async {
    _showMessagePreview = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('show_message_preview', enabled);
  }

  /// Set notification sound
  Future<void> setNotificationSound(String sound) async {
    _notificationSound = sound;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification_sound', sound);
  }

  /// Set vibration enabled
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration_enabled', enabled);
  }

  /// Get current DND settings
  Map<String, dynamic> getDndSettings() {
    return {
      'enabled': _isDndEnabled,
      'startTime': _dndStartTime,
      'endTime': _dndEndTime,
    };
  }

  /// Get current custom notification settings
  Map<String, dynamic> getCustomNotificationSettings() {
    return {
      'showMessagePreview': _showMessagePreview,
      'notificationSound': _notificationSound,
      'vibrationEnabled': _vibrationEnabled,
    };
  }

  /// Set per-chat notification settings
  Future<void> setChatNotificationSettings(
    String channelId, {
    bool? enabled,
    String? sound,
    bool? vibration,
    bool? preview,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_settings_$channelId';

    Map<String, dynamic> settings = {};
    if (enabled != null) settings['enabled'] = enabled;
    if (sound != null) settings['sound'] = sound;
    if (vibration != null) settings['vibration'] = vibration;
    if (preview != null) settings['preview'] = preview;

    await prefs.setString(key, settings.toString());
  }

  /// Get per-chat notification settings
  Future<Map<String, dynamic>> getChatNotificationSettings(
    String channelId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_settings_$channelId';
    final settingsStr = prefs.getString(key);

    if (settingsStr == null) {
      return {
        'enabled': true,
        'sound': _notificationSound,
        'vibration': _vibrationEnabled,
        'preview': _showMessagePreview,
      };
    }

    // Parse settings (simplified parsing)
    return {
      'enabled': true,
      'sound': _notificationSound,
      'vibration': _vibrationEnabled,
      'preview': _showMessagePreview,
    };
  }

  /// Initialize background refresh
  Future<void> initializeBackgroundRefresh() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    await Workmanager().registerPeriodicTask(
      'chat_refresh',
      'refresh_chat_data',
      frequency: const Duration(minutes: 15),
    );
  }

  /// Track notification analytics
  void trackNotificationSent(String category) {
    _notificationsSent++;
    _categoryStats[category] = (_categoryStats[category] ?? 0) + 1;
  }

  void trackNotificationOpened() {
    _notificationsOpened++;
  }

  /// Get analytics data
  Map<String, dynamic> getAnalytics() {
    return {
      'totalSent': _notificationsSent,
      'totalOpened': _notificationsOpened,
      'openRate': _notificationsSent > 0
          ? _notificationsOpened / _notificationsSent
          : 0.0,
      'categoryStats': _categoryStats,
    };
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
