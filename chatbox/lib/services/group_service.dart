// lib/services/group_service.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/services/stream_chat_service.dart';

enum MemberRole { admin, moderator, member }

enum GroupPrivacy { public, private }

class GroupMember {
  final String userId;
  final String? name;
  final String? image;
  final MemberRole role;
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    this.name,
    this.image,
    this.role = MemberRole.member,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory GroupMember.fromUser(
    ChatUser user, {
    MemberRole role = MemberRole.member,
  }) {
    return GroupMember(
      userId: user.id,
      name: user.name,
      image: user.image,
      role: role,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'image': image,
      'role': role.toString(),
      'joinedAt': joinedAt.toIso8601String(),
    };
  }

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    MemberRole role = MemberRole.member;
    try {
      role = MemberRole.values.firstWhere(
        (e) => e.toString() == json['role'],
        orElse: () => MemberRole.member,
      );
    } catch (e) {
      role = MemberRole.member;
    }

    return GroupMember(
      userId: json['userId'],
      name: json['name'],
      image: json['image'],
      role: role,
      joinedAt: DateTime.parse(json['joinedAt']),
    );
  }
}

class GroupChat {
  final String id;
  final String name;
  final String? description;
  final String? image;
  final String createdBy;
  final List<GroupMember> members;
  final GroupPrivacy privacy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isBroadcast;
  final String? inviteLink;

  GroupChat({
    required this.id,
    required this.name,
    this.description,
    this.image,
    required this.createdBy,
    required this.members,
    this.privacy = GroupPrivacy.private,
    DateTime? createdAt,
    this.updatedAt,
    this.isBroadcast = false,
    this.inviteLink,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isAdmin => members.any(
    (member) => member.userId == createdBy && member.role == MemberRole.admin,
  );

  bool isUserAdmin(String userId) {
    return members.any(
      (member) => member.userId == userId && member.role == MemberRole.admin,
    );
  }

  bool isUserModerator(String userId) {
    return members.any(
      (member) =>
          member.userId == userId &&
          (member.role == MemberRole.admin ||
              member.role == MemberRole.moderator),
    );
  }

  GroupMember? getMember(String userId) {
    return members.firstWhere(
      (member) => member.userId == userId,
      orElse: () => null as GroupMember,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'createdBy': createdBy,
      'members': members.map((m) => m.toJson()).toList(),
      'privacy': privacy.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isBroadcast': isBroadcast,
      'inviteLink': inviteLink,
    };
  }

  factory GroupChat.fromJson(Map<String, dynamic> json) {
    GroupPrivacy privacy = GroupPrivacy.private;
    try {
      privacy = GroupPrivacy.values.firstWhere(
        (e) => e.toString() == json['privacy'],
        orElse: () => GroupPrivacy.private,
      );
    } catch (e) {
      privacy = GroupPrivacy.private;
    }

    return GroupChat(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      image: json['image'],
      createdBy: json['createdBy'],
      members:
          (json['members'] as List<dynamic>?)
              ?.map((m) => GroupMember.fromJson(m))
              .toList() ??
          [],
      privacy: privacy,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      isBroadcast: json['isBroadcast'] ?? false,
      inviteLink: json['inviteLink'],
    );
  }
}

class GroupService {
  final StreamChatService _streamService = StreamChatService();

  // Create a new group chat
  Future<Channel?> createGroup({
    required String name,
    required List<String> memberIds,
    String? description,
    String? imageUrl,
    GroupPrivacy privacy = GroupPrivacy.private,
    bool isBroadcast = false,
  }) async {
    try {
      final currentUser = _streamService.client.state.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Create group channel
      final channel = _streamService.client.channel(
        'team', // Use 'team' for group chats
        id: 'group_${DateTime.now().millisecondsSinceEpoch}',
        extraData: {
          'name': name,
          'description': description,
          'image': imageUrl,
          'created_by': currentUser.id,
          'privacy': privacy.toString(),
          'is_broadcast': isBroadcast,
          'members': [...memberIds, currentUser.id], // Include creator
        },
      );

      // Add members to the channel
      await channel.addMembers([...memberIds, currentUser.id]);

      return channel;
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  // Add members to group
  Future<void> addMembers(Channel channel, List<String> memberIds) async {
    try {
      await channel.addMembers(memberIds);
    } catch (e) {
      throw Exception('Failed to add members: $e');
    }
  }

  // Remove member from group
  Future<void> removeMember(Channel channel, String memberId) async {
    try {
      await channel.removeMembers([memberId]);
    } catch (e) {
      throw Exception('Failed to remove member: $e');
    }
  }

  // Update group info
  Future<void> updateGroupInfo(
    Channel channel, {
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (description != null) updates['description'] = description;
      if (imageUrl != null) updates['image'] = imageUrl;

      if (updates.isNotEmpty) {
        await channel.update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  // Leave group
  Future<void> leaveGroup(Channel channel) async {
    try {
      final currentUser = _streamService.client.state.currentUser;
      if (currentUser != null) {
        await channel.removeMembers([currentUser.id]);
      }
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  // Delete group (admin only)
  Future<void> deleteGroup(Channel channel) async {
    try {
      await channel.delete();
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  // Generate invite link
  String generateInviteLink(String channelId) {
    // In a real app, this would generate a unique, secure invite link
    return 'chatbox://invite/$channelId';
  }

  // Join group via invite link
  Future<Channel?> joinGroupViaInvite(String inviteLink) async {
    try {
      // Extract channel ID from invite link
      final channelId = inviteLink.split('/').last;

      final channel = _streamService.client.channel('team', id: channelId);
      await channel.watch();

      return channel;
    } catch (e) {
      throw Exception('Failed to join group: $e');
    }
  }

  // Update member role
  Future<void> updateMemberRole(
    Channel channel,
    String memberId,
    MemberRole newRole,
  ) async {
    try {
      // This would typically be done via channel custom data or a backend service
      // For now, we'll store it in channel extraData
      final extraData = channel.extraData ?? {};
      final memberRoles =
          (extraData['member_roles'] as Map<String, dynamic>?) ??
          <String, dynamic>{};

      memberRoles[memberId] = newRole.toString();

      await channel.update({'member_roles': memberRoles});
    } catch (e) {
      throw Exception('Failed to update member role: $e');
    }
  }

  // Get member role
  MemberRole getMemberRole(Channel channel, String memberId) {
    try {
      final extraData = channel.extraData ?? {};
      final memberRoles =
          (extraData['member_roles'] as Map<String, dynamic>?) ??
          <String, dynamic>{};
      final roleStr = memberRoles[memberId] as String?;

      if (roleStr != null) {
        return MemberRole.values.firstWhere(
          (e) => e.toString() == roleStr,
          orElse: () => MemberRole.member,
        );
      }

      // Creator is admin by default
      if (channel.createdBy?.id == memberId) {
        return MemberRole.admin;
      }

      return MemberRole.member;
    } catch (e) {
      return MemberRole.member;
    }
  }

  // Check if user can perform admin actions
  bool canUserPerformAdminAction(Channel channel, String userId) {
    final role = getMemberRole(channel, userId);
    return role == MemberRole.admin || role == MemberRole.moderator;
  }

  // Check if user is admin
  bool isUserAdmin(Channel channel, String userId) {
    final role = getMemberRole(channel, userId);
    return role == MemberRole.admin;
  }

  // Get group statistics
  Map<String, dynamic> getGroupStats(Channel channel) {
    final members = channel.state?.members ?? [];
    final messages = channel.state?.messages ?? [];

    return {
      'memberCount': members.length,
      'messageCount': messages.length,
      'adminCount': members
          .where((m) => isUserAdmin(channel, m.userId!))
          .length,
      'moderatorCount': members
          .where(
            (m) => getMemberRole(channel, m.userId!) == MemberRole.moderator,
          )
          .length,
      'createdAt': channel.createdAt,
      'lastMessageAt': messages.isNotEmpty ? messages.first.createdAt : null,
    };
  }

  // Make channel broadcast (admin only)
  Future<void> makeChannelBroadcast(Channel channel, bool isBroadcast) async {
    try {
      await channel.update({'is_broadcast': isBroadcast});
    } catch (e) {
      throw Exception('Failed to update broadcast setting: $e');
    }
  }

  // Send broadcast message (admin/moderator only)
  Future<void> sendBroadcastMessage(Channel channel, String message) async {
    try {
      await channel.sendMessage(Message(text: '📢 $message'));
    } catch (e) {
      throw Exception('Failed to send broadcast message: $e');
    }
  }
}
