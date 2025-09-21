// lib/models/channel_models.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/channel_types.dart' as channel_types;

/// User roles in channels
class ChannelRoles {
  static const String owner = 'owner';
  static const String admin = 'admin';
  static const String moderator = 'moderator';
  static const String member = 'member';
  static const String guest = 'guest';

  static List<String> get all => [owner, admin, moderator, member, guest];

  static String getDisplayName(String role) {
    switch (role) {
      case owner:
        return 'Owner';
      case admin:
        return 'Admin';
      case moderator:
        return 'Moderator';
      case member:
        return 'Member';
      case guest:
        return 'Guest';
      default:
        return 'Member';
    }
  }

  static int getPriority(String role) {
    switch (role) {
      case owner:
        return 5;
      case admin:
        return 4;
      case moderator:
        return 3;
      case member:
        return 2;
      case guest:
        return 1;
      default:
        return 2;
    }
  }
}

/// Channel permissions for different roles
class ChannelPermissions {
  final String role;
  final bool canSendMessage;
  final bool canEditMessage;
  final bool canDeleteMessage;
  final bool canAddMembers;
  final bool canRemoveMembers;
  final bool canChangeSettings;
  final bool canDeleteChannel;
  final bool canPinMessages;
  final bool canModerate;

  const ChannelPermissions({
    required this.role,
    required this.canSendMessage,
    required this.canEditMessage,
    required this.canDeleteMessage,
    required this.canAddMembers,
    required this.canRemoveMembers,
    required this.canChangeSettings,
    required this.canDeleteChannel,
    required this.canPinMessages,
    required this.canModerate,
  });

  factory ChannelPermissions.forRole(String role) {
    switch (role) {
      case ChannelRoles.owner:
        return const ChannelPermissions(
          role: ChannelRoles.owner,
          canSendMessage: true,
          canEditMessage: true,
          canDeleteMessage: true,
          canAddMembers: true,
          canRemoveMembers: true,
          canChangeSettings: true,
          canDeleteChannel: true,
          canPinMessages: true,
          canModerate: true,
        );

      case ChannelRoles.admin:
        return const ChannelPermissions(
          role: ChannelRoles.admin,
          canSendMessage: true,
          canEditMessage: true,
          canDeleteMessage: true,
          canAddMembers: true,
          canRemoveMembers: true,
          canChangeSettings: true,
          canDeleteChannel: false,
          canPinMessages: true,
          canModerate: true,
        );

      case ChannelRoles.moderator:
        return const ChannelPermissions(
          role: ChannelRoles.moderator,
          canSendMessage: true,
          canEditMessage: true,
          canDeleteMessage: true,
          canAddMembers: false,
          canRemoveMembers: false,
          canChangeSettings: false,
          canDeleteChannel: false,
          canPinMessages: true,
          canModerate: true,
        );

      case ChannelRoles.member:
        return const ChannelPermissions(
          role: ChannelRoles.member,
          canSendMessage: true,
          canEditMessage: true,
          canDeleteMessage: false,
          canAddMembers: false,
          canRemoveMembers: false,
          canChangeSettings: false,
          canDeleteChannel: false,
          canPinMessages: false,
          canModerate: false,
        );

      case ChannelRoles.guest:
        return const ChannelPermissions(
          role: ChannelRoles.guest,
          canSendMessage: false,
          canEditMessage: false,
          canDeleteMessage: false,
          canAddMembers: false,
          canRemoveMembers: false,
          canChangeSettings: false,
          canDeleteChannel: false,
          canPinMessages: false,
          canModerate: false,
        );

      default:
        return const ChannelPermissions(
          role: ChannelRoles.member,
          canSendMessage: true,
          canEditMessage: true,
          canDeleteMessage: false,
          canAddMembers: false,
          canRemoveMembers: false,
          canChangeSettings: false,
          canDeleteChannel: false,
          canPinMessages: false,
          canModerate: false,
        );
    }
  }
}

/// Extended Channel model with metadata
class ChatChannel {
  final Channel originalChannel;
  final String type;
  final String? description;
  final String? avatar;
  final List<String> tags;
  final Map<String, String> memberRoles;
  final bool isArchived;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int maxMembers;
  final Map<String, dynamic> settings;

  const ChatChannel({
    required this.originalChannel,
    required this.type,
    this.description,
    this.avatar,
    required this.tags,
    required this.memberRoles,
    required this.isArchived,
    required this.isPublic,
    this.createdAt,
    this.updatedAt,
    required this.maxMembers,
    required this.settings,
  });

  // Create from GetStream Channel
  factory ChatChannel.fromStreamChannel(Channel channel) {
    final extraData = channel.extraData ?? {};
    final config = channel_types.ChannelConfig.getConfig(
      channel.type ?? channel_types.ChannelTypes.messaging,
    );

    return ChatChannel(
      originalChannel: channel,
      type: channel.type ?? channel_types.ChannelTypes.messaging,
      description: extraData['description'] as String?,
      avatar: extraData['avatar'] as String?,
      tags: List<String>.from((extraData['tags'] as List<dynamic>?) ?? []),
      memberRoles: Map<String, String>.from(
        (extraData['memberRoles'] as Map<dynamic, dynamic>?) ?? {},
      ),
      isArchived: extraData['isArchived'] as bool? ?? false,
      isPublic: config.isPublic,
      createdAt: extraData['createdAt'] != null
          ? DateTime.parse(extraData['createdAt'] as String)
          : null,
      updatedAt: extraData['updatedAt'] != null
          ? DateTime.parse(extraData['updatedAt'] as String)
          : null,
      maxMembers: config.maxMembers,
      settings: Map<String, dynamic>.from(
        (extraData['settings'] as Map<dynamic, dynamic>?) ??
            config.defaultSettings,
      ),
    );
  }

  // Convert to GetStream Channel extraData
  Map<String, dynamic> toExtraData() {
    return {
      'description': description,
      'avatar': avatar,
      'tags': tags,
      'memberRoles': memberRoles,
      'isArchived': isArchived,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      'settings': settings,
    };
  }

  // Get permissions for a specific user
  ChannelPermissions getPermissionsForUser(String userId) {
    final userRole = memberRoles[userId] ?? ChannelRoles.member;
    return ChannelPermissions.forRole(userRole);
  }

  // Check if user has permission
  bool userHasPermission(String userId, String permission) {
    final permissions = getPermissionsForUser(userId);

    switch (permission) {
      case 'sendMessage':
        return permissions.canSendMessage;
      case 'editMessage':
        return permissions.canEditMessage;
      case 'deleteMessage':
        return permissions.canDeleteMessage;
      case 'addMembers':
        return permissions.canAddMembers;
      case 'removeMembers':
        return permissions.canRemoveMembers;
      case 'changeSettings':
        return permissions.canChangeSettings;
      case 'deleteChannel':
        return permissions.canDeleteChannel;
      case 'pinMessages':
        return permissions.canPinMessages;
      case 'moderate':
        return permissions.canModerate;
      default:
        return false;
    }
  }

  // Get online member count
  int getOnlineMemberCount() {
    return originalChannel.state?.members
            .where((member) => member.user?.online == true)
            .length ??
        0;
  }

  // Get total member count
  int getTotalMemberCount() {
    return originalChannel.memberCount ?? 0;
  }
}

/// Channel member with role information
class ChannelMember {
  final Member originalMember;
  final String role;
  final DateTime? joinedAt;
  final bool isMuted;
  final DateTime? mutedUntil;

  const ChannelMember({
    required this.originalMember,
    required this.role,
    this.joinedAt,
    required this.isMuted,
    this.mutedUntil,
  });

  factory ChannelMember.fromMember(Member member, String role) {
    final extraData = member.extraData ?? {};

    return ChannelMember(
      originalMember: member,
      role: role,
      joinedAt: extraData['joinedAt'] != null
          ? DateTime.parse(extraData['joinedAt'] as String)
          : null,
      isMuted: extraData['isMuted'] as bool? ?? false,
      mutedUntil: extraData['mutedUntil'] != null
          ? DateTime.parse(extraData['mutedUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toExtraData() {
    return {
      'joinedAt': joinedAt?.toIso8601String(),
      'isMuted': isMuted,
      'mutedUntil': mutedUntil?.toIso8601String(),
    };
  }
}

/// Channel invitation
class ChannelInvitation {
  final String channelId;
  final String inviterId;
  final String inviteeId;
  final String role;
  final String status; // pending, accepted, declined, expired
  final DateTime createdAt;
  final DateTime? expiresAt;
  final String? message;

  const ChannelInvitation({
    required this.channelId,
    required this.inviterId,
    required this.inviteeId,
    required this.role,
    required this.status,
    required this.createdAt,
    this.expiresAt,
    this.message,
  });

  factory ChannelInvitation.fromJson(Map<String, dynamic> json) {
    return ChannelInvitation(
      channelId: json['channelId'] as String,
      inviterId: json['inviterId'] as String,
      inviteeId: json['inviteeId'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'channelId': channelId,
      'inviterId': inviterId,
      'inviteeId': inviteeId,
      'role': role,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'message': message,
    };
  }
}
