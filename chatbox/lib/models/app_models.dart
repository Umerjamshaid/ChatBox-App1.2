/// App-specific models for type safety
import 'package:json_annotation/json_annotation.dart';

part 'app_models.g.dart';

@JsonSerializable()
class AppMessage {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final String? userImage;
  final DateTime createdAt;
  String status;
  final String? channelId;
  final List<Map<String, dynamic>>? reactions;

  AppMessage({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    this.userImage,
    required this.createdAt,
    required this.status,
    this.channelId,
    this.reactions,
  });

  factory AppMessage.fromJson(Map<String, dynamic> json) =>
      _$AppMessageFromJson(json);
  Map<String, dynamic> toJson() => _$AppMessageToJson(this);
}

class AppChannel {
  final String id;
  final String type;
  final String name;
  final String? image;
  final int memberCount;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final List<String>? members;

  const AppChannel({
    required this.id,
    required this.type,
    required this.name,
    this.image,
    required this.memberCount,
    this.lastMessage,
    this.lastMessageAt,
    this.members,
  });

  factory AppChannel.fromMap(Map<String, dynamic> map) {
    return AppChannel(
      id: map['id'] as String,
      type: map['type'] as String,
      name: map['name'] as String,
      image: map['image'] as String?,
      memberCount: map['memberCount'] as int,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: map['lastMessageAt'] != null
          ? DateTime.parse(map['lastMessageAt'] as String)
          : null,
      members: (map['members'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'image': image,
      'memberCount': memberCount,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'members': members,
    };
  }
}

class AppUser {
  final String id;
  final String name;
  final String? image;
  final String status;
  final DateTime? lastActive;

  const AppUser({
    required this.id,
    required this.name,
    this.image,
    required this.status,
    this.lastActive,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      image: map['image'] as String?,
      status: map['status'] as String,
      lastActive: map['lastActive'] != null
          ? DateTime.parse(map['lastActive'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'status': status,
      'lastActive': lastActive?.toIso8601String(),
    };
  }
}
