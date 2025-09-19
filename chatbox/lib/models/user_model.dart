// lib/models/user_model.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

enum UserStatus { online, offline, away, busy }

class ChatUser {
  final String id;
  final String? name;
  final String? email;
  final String? image;
  final String? bio;
  final UserStatus status;
  final DateTime? lastSeen;
  final DateTime? createdAt;
  final Map<String, dynamic>? extraData;

  const ChatUser({
    required this.id,
    this.name,
    this.email,
    this.image,
    this.bio,
    this.status = UserStatus.offline,
    this.lastSeen,
    this.createdAt,
    this.extraData,
  });

  // Convert to GetStream User object
  User toStreamUser() {
    return User(
      id: id,
      name: name,
      image: image,
      extraData: {
        'email': email,
        'bio': bio,
        'status': status.toString(),
        'lastSeen': lastSeen?.toIso8601String(),
        'createdAt': createdAt?.toIso8601String(),
        ...?extraData,
      },
    );
  }

  // Create from GetStream User object
  factory ChatUser.fromStreamUser(User user) {
    UserStatus status = UserStatus.offline;
    try {
      final statusStr = user.extraData?['status'] as String?;
      if (statusStr != null) {
        status = UserStatus.values.firstWhere(
          (e) => e.toString() == statusStr,
          orElse: () => UserStatus.offline,
        );
      }
    } catch (e) {
      status = UserStatus.offline;
    }

    return ChatUser(
      id: user.id,
      name: user.name,
      image: user.image,
      email: user.extraData?['email'] as String?,
      bio: user.extraData?['bio'] as String?,
      status: status,
      lastSeen: user.extraData?['lastSeen'] != null
          ? DateTime.parse(user.extraData!['lastSeen'] as String)
          : null,
      createdAt: user.extraData?['createdAt'] != null
          ? DateTime.parse(user.extraData!['createdAt'] as String)
          : null,
      extraData: user.extraData as Map<String, dynamic>?,
    );
  }

  // Create from Firebase User
  factory ChatUser.fromFirebaseUser(dynamic firebaseUser) {
    return ChatUser(
      id: firebaseUser.uid,
      name: firebaseUser.displayName,
      email: firebaseUser.email,
      image: firebaseUser.photoURL,
      status: UserStatus.online,
      createdAt: DateTime.now(),
    );
  }

  // Copy with method for updates
  ChatUser copyWith({
    String? id,
    String? name,
    String? email,
    String? image,
    String? bio,
    UserStatus? status,
    DateTime? lastSeen,
    DateTime? createdAt,
    Map<String, dynamic>? extraData,
  }) {
    return ChatUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      image: image ?? this.image,
      bio: bio ?? this.bio,
      status: status ?? this.status,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      extraData: extraData ?? this.extraData,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'bio': bio,
      'status': status.toString(),
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'extraData': extraData,
    };
  }

  // Create from JSON
  factory ChatUser.fromJson(Map<String, dynamic> json) {
    UserStatus status = UserStatus.offline;
    try {
      status = UserStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => UserStatus.offline,
      );
    } catch (e) {
      status = UserStatus.offline;
    }

    return ChatUser(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      image: json['image'],
      bio: json['bio'],
      status: status,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      extraData: json['extraData'],
    );
  }

  @override
  String toString() {
    return 'ChatUser(id: $id, name: $name, email: $email, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
