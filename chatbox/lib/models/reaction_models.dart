// lib/models/reaction_models.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Message reaction types
class ReactionTypes {
  static const String like = 'like';
  static const String love = 'love';
  static const String laugh = 'laugh';
  static const String angry = 'angry';
  static const String sad = 'sad';
  static const String wow = 'wow';
  static const String thumbsUp = 'thumbs_up';
  static const String thumbsDown = 'thumbs_down';

  static List<String> get all => [
    like,
    love,
    laugh,
    angry,
    sad,
    wow,
    thumbsUp,
    thumbsDown,
  ];

  static String getEmoji(String type) {
    switch (type) {
      case like:
        return '👍';
      case love:
        return '❤️';
      case laugh:
        return '😂';
      case angry:
        return '😠';
      case sad:
        return '😢';
      case wow:
        return '😮';
      case thumbsUp:
        return '👍';
      case thumbsDown:
        return '👎';
      default:
        return '👍';
    }
  }

  static String getDisplayName(String type) {
    switch (type) {
      case like:
        return 'Like';
      case love:
        return 'Love';
      case laugh:
        return 'Laugh';
      case angry:
        return 'Angry';
      case sad:
        return 'Sad';
      case wow:
        return 'Wow';
      case thumbsUp:
        return 'Thumbs Up';
      case thumbsDown:
        return 'Thumbs Down';
      default:
        return 'Like';
    }
  }
}

/// Extended reaction model
class ChatReaction {
  final Reaction originalReaction;
  final String type;
  final String userId;
  final String? userName;
  final String? userImage;
  final DateTime createdAt;
  final Map<String, dynamic>? extraData;

  const ChatReaction({
    required this.originalReaction,
    required this.type,
    required this.userId,
    this.userName,
    this.userImage,
    required this.createdAt,
    this.extraData,
  });

  factory ChatReaction.fromReaction(Reaction reaction) {
    return ChatReaction(
      originalReaction: reaction,
      type: reaction.type ?? ReactionTypes.like,
      userId: reaction.userId ?? '',
      userName: reaction.user?.name,
      userImage: reaction.user?.image,
      createdAt: reaction.createdAt ?? DateTime.now(),
      extraData: reaction.extraData,
    );
  }

  String get emoji => ReactionTypes.getEmoji(type);
  String get displayName => ReactionTypes.getDisplayName(type);
}

/// Reaction summary for a message
class MessageReactionSummary {
  final String type;
  final int count;
  final List<String> userIds;
  final List<String> userNames;
  final bool hasCurrentUser;

  const MessageReactionSummary({
    required this.type,
    required this.count,
    required this.userIds,
    required this.userNames,
    required this.hasCurrentUser,
  });

  factory MessageReactionSummary.fromReactionCounts(
    String type,
    Map<String, dynamic> reactionData,
    String currentUserId,
  ) {
    final userIds =
        (reactionData['userIds'] as List<dynamic>?)?.cast<String>() ?? [];
    final userNames =
        (reactionData['userNames'] as List<dynamic>?)?.cast<String>() ?? [];

    return MessageReactionSummary(
      type: type,
      count: reactionData['count'] as int? ?? 0,
      userIds: userIds,
      userNames: userNames,
      hasCurrentUser: userIds.contains(currentUserId),
    );
  }

  String get emoji => ReactionTypes.getEmoji(type);
  String get displayName => ReactionTypes.getDisplayName(type);

  String getTooltipText(String currentUserId) {
    if (count == 0) return '';

    final names = userNames.take(3).join(', ');
    final remaining = count - 3;

    if (remaining > 0) {
      return '$names and $remaining others reacted with $displayName';
    } else {
      return '$names reacted with $displayName';
    }
  }
}

/// Thread reply model
class ThreadReply {
  final Message originalMessage;
  final String parentMessageId;
  final int replyCount;
  final List<String> participantIds;
  final DateTime lastReplyAt;
  final bool isResolved;

  const ThreadReply({
    required this.originalMessage,
    required this.parentMessageId,
    required this.replyCount,
    required this.participantIds,
    required this.lastReplyAt,
    required this.isResolved,
  });

  factory ThreadReply.fromMessage(Message message) {
    final extraData = message.extraData ?? {};

    return ThreadReply(
      originalMessage: message,
      parentMessageId: message.parentId ?? '',
      replyCount: message.replyCount ?? 0,
      participantIds: List<String>.from(
        (extraData['participantIds'] as List<dynamic>?) ?? [],
      ),
      lastReplyAt: message.createdAt ?? DateTime.now(),
      isResolved: extraData['isResolved'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toExtraData() {
    return {'participantIds': participantIds, 'isResolved': isResolved};
  }
}

/// Thread summary for display
class ThreadSummary {
  final String parentMessageId;
  final String parentMessageText;
  final String parentMessageUserName;
  final String parentMessageUserImage;
  final int replyCount;
  final int participantCount;
  final DateTime lastReplyAt;
  final List<String> recentParticipants;
  final bool isResolved;

  const ThreadSummary({
    required this.parentMessageId,
    required this.parentMessageText,
    required this.parentMessageUserName,
    required this.parentMessageUserImage,
    required this.replyCount,
    required this.participantCount,
    required this.lastReplyAt,
    required this.recentParticipants,
    required this.isResolved,
  });

  factory ThreadSummary.fromThreadReply(ThreadReply reply) {
    final message = reply.originalMessage;

    return ThreadSummary(
      parentMessageId: reply.parentMessageId,
      parentMessageText: message.text ?? '',
      parentMessageUserName: message.user?.name ?? 'Unknown',
      parentMessageUserImage: message.user?.image ?? '',
      replyCount: reply.replyCount,
      participantCount: reply.participantIds.length,
      lastReplyAt: reply.lastReplyAt,
      recentParticipants: reply.participantIds.take(3).toList(),
      isResolved: reply.isResolved,
    );
  }

  String getReplyCountText() {
    if (replyCount == 0) return 'No replies';
    if (replyCount == 1) return '1 reply';
    return '$replyCount replies';
  }

  String getParticipantText() {
    if (participantCount <= 3) {
      return recentParticipants.join(', ');
    } else {
      final shown = recentParticipants.take(2).join(', ');
      final remaining = participantCount - 2;
      return '$shown and $remaining others';
    }
  }
}

/// Message with reactions and thread info
class MessageWithReactions {
  final Message originalMessage;
  final List<MessageReactionSummary> reactions;
  final ThreadReply? threadReply;
  final bool hasCurrentUserReacted;
  final int totalReactionCount;

  const MessageWithReactions({
    required this.originalMessage,
    required this.reactions,
    this.threadReply,
    required this.hasCurrentUserReacted,
    required this.totalReactionCount,
  });

  factory MessageWithReactions.fromMessage(
    Message message,
    String currentUserId,
  ) {
    final reactions = <MessageReactionSummary>[];
    var totalReactionCount = 0;
    var hasCurrentUserReacted = false;

    if (message.reactionGroups != null) {
      message.reactionGroups!.forEach((type, reactionGroup) {
        final reactionList = reactionGroup as List<Reaction>;
        final count = reactionList.length;
        final userIds = reactionList.map((r) => r.userId ?? '').toList();
        final userNames = reactionList.map((r) => r.user?.name ?? '').toList();

        final reactionData = {
          'count': count,
          'userIds': userIds,
          'userNames': userNames,
        };

        final summary = MessageReactionSummary.fromReactionCounts(
          type,
          reactionData,
          currentUserId,
        );

        reactions.add(summary);
        totalReactionCount += count;

        if (summary.hasCurrentUser) {
          hasCurrentUserReacted = true;
        }
      });
    }

    final threadReply = message.replyCount != null && message.replyCount! > 0
        ? ThreadReply.fromMessage(message)
        : null;

    return MessageWithReactions(
      originalMessage: message,
      reactions: reactions,
      threadReply: threadReply,
      hasCurrentUserReacted: hasCurrentUserReacted,
      totalReactionCount: totalReactionCount,
    );
  }

  bool get hasReactions => reactions.isNotEmpty;
  bool get hasThread => threadReply != null;
  bool get isThreadParent =>
      originalMessage.replyCount != null && originalMessage.replyCount! > 0;
}

/// Reaction picker configuration
class ReactionPickerConfig {
  final List<String> availableReactions;
  final bool showFrequentReactions;
  final int maxRecentReactions;
  final Map<String, int> reactionFrequency;

  const ReactionPickerConfig({
    required this.availableReactions,
    this.showFrequentReactions = true,
    this.maxRecentReactions = 6,
    required this.reactionFrequency,
  });

  factory ReactionPickerConfig.defaultConfig() {
    return ReactionPickerConfig(
      availableReactions: ReactionTypes.all,
      showFrequentReactions: true,
      maxRecentReactions: 6,
      reactionFrequency: {},
    );
  }

  List<String> getFrequentReactions() {
    if (!showFrequentReactions) return [];

    final sortedEntries = reactionFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(maxRecentReactions)
        .map((entry) => entry.key)
        .toList();
  }

  void recordReaction(String type) {
    reactionFrequency[type] = (reactionFrequency[type] ?? 0) + 1;
  }
}
