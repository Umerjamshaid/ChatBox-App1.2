// lib/models/presence_models.dart
import 'package:chatbox/models/user_model.dart';

/// User presence status
enum PresenceStatus { online, offline, away, busy }

/// User presence information
class UserPresence {
  final String userId;
  final PresenceStatus status;
  final DateTime? lastSeen;
  final bool isOnline;
  final String? statusMessage;

  const UserPresence({
    required this.userId,
    required this.status,
    this.lastSeen,
    this.isOnline = false,
    this.statusMessage,
  });

  /// Create from UserStatus enum
  factory UserPresence.fromUserStatus(String userId, UserStatus status) {
    return UserPresence(
      userId: userId,
      status: _convertUserStatusToPresenceStatus(status),
      isOnline: status == UserStatus.online,
      lastSeen: status == UserStatus.offline ? DateTime.now() : null,
    );
  }

  static PresenceStatus _convertUserStatusToPresenceStatus(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return PresenceStatus.online;
      case UserStatus.offline:
        return PresenceStatus.offline;
      case UserStatus.away:
        return PresenceStatus.away;
      case UserStatus.busy:
        return PresenceStatus.busy;
    }
  }

  /// Copy with method
  UserPresence copyWith({
    String? userId,
    PresenceStatus? status,
    DateTime? lastSeen,
    bool? isOnline,
    String? statusMessage,
  }) {
    return UserPresence(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status.toString(),
      'lastSeen': lastSeen?.toIso8601String(),
      'isOnline': isOnline,
      'statusMessage': statusMessage,
    };
  }

  /// Create from JSON
  factory UserPresence.fromJson(Map<String, dynamic> json) {
    PresenceStatus status = PresenceStatus.offline;
    try {
      status = PresenceStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => PresenceStatus.offline,
      );
    } catch (e) {
      status = PresenceStatus.offline;
    }

    return UserPresence(
      userId: json['userId'],
      status: status,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      isOnline: json['isOnline'] ?? false,
      statusMessage: json['statusMessage'],
    );
  }

  @override
  String toString() {
    return 'UserPresence(userId: $userId, status: $status, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPresence &&
        other.userId == userId &&
        other.status == status &&
        other.isOnline == isOnline;
  }

  @override
  int get hashCode => userId.hashCode ^ status.hashCode ^ isOnline.hashCode;
}

/// Typing indicator information
class TypingIndicator {
  final String userId;
  final String userName;
  final String channelId;
  final DateTime timestamp;

  const TypingIndicator({
    required this.userId,
    required this.userName,
    required this.channelId,
    required this.timestamp,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'channelId': channelId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create from JSON
  factory TypingIndicator.fromJson(Map<String, dynamic> json) {
    return TypingIndicator(
      userId: json['userId'],
      userName: json['userName'],
      channelId: json['channelId'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  @override
  String toString() {
    return 'TypingIndicator(userName: $userName, channelId: $channelId)';
  }
}
