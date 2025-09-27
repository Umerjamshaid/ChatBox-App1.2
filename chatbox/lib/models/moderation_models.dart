import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Moderation-related models and enums for ChatBox

/// Types of reports that can be made
enum ReportType {
  harassment,
  spam,
  inappropriate,
  hateSpeech,
  violence,
  nudity,
  copyright,
  other,
}

/// Severity levels for moderation actions
enum ModerationSeverity { low, medium, high, critical }

/// Types of moderation actions
enum ModerationAction { none, flag, mute, ban, shadowBan, delete, quarantine }

/// User roles in moderation system
enum ModerationRole { user, moderator, admin, superAdmin }

/// Status of a moderation report
enum ReportStatus { pending, underReview, resolved, dismissed }

/// Types of automated moderation rules
enum ModerationRuleType {
  keywordFilter,
  spamDetection,
  rateLimit,
  contentFilter,
  userBehavior,
}

/// Report model for messages and users
class ModerationReport {
  final String id;
  final String reporterId;
  final String? targetUserId;
  final String? targetMessageId;
  final String? targetChannelId;
  final ReportType reportType;
  final String reason;
  final String? description;
  final ReportStatus status;
  final ModerationSeverity severity;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolutionNotes;
  final List<String> evidence; // URLs or message IDs

  const ModerationReport({
    required this.id,
    required this.reporterId,
    this.targetUserId,
    this.targetMessageId,
    this.targetChannelId,
    required this.reportType,
    required this.reason,
    this.description,
    required this.status,
    required this.severity,
    required this.createdAt,
    this.resolvedAt,
    this.resolvedBy,
    this.resolutionNotes,
    this.evidence = const [],
  });

  factory ModerationReport.fromJson(Map<String, dynamic> json) {
    return ModerationReport(
      id: json['id'] as String,
      reporterId: json['reporterId'] as String,
      targetUserId: json['targetUserId'] as String?,
      targetMessageId: json['targetMessageId'] as String?,
      targetChannelId: json['targetChannelId'] as String?,
      reportType: ReportType.values[json['reportType'] as int],
      reason: json['reason'] as String,
      description: json['description'] as String?,
      status: ReportStatus.values[json['status'] as int],
      severity: ModerationSeverity.values[json['severity'] as int],
      createdAt: DateTime.parse(json['createdAt'] as String),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'] as String)
          : null,
      resolvedBy: json['resolvedBy'] as String?,
      resolutionNotes: json['resolutionNotes'] as String?,
      evidence: List<String>.from(json['evidence'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'targetUserId': targetUserId,
      'targetMessageId': targetMessageId,
      'targetChannelId': targetChannelId,
      'reportType': reportType.index,
      'reason': reason,
      'description': description,
      'status': status.index,
      'severity': severity.index,
      'createdAt': createdAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'resolvedBy': resolvedBy,
      'resolutionNotes': resolutionNotes,
      'evidence': evidence,
    };
  }
}

/// Moderation action taken on a user or message
class ModerationActionRecord {
  final String id;
  final String moderatorId;
  final ModerationAction action;
  final String? targetUserId;
  final String? targetMessageId;
  final String? targetChannelId;
  final String reason;
  final Duration? duration; // For temporary actions like mutes/bans
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;

  const ModerationActionRecord({
    required this.id,
    required this.moderatorId,
    required this.action,
    this.targetUserId,
    this.targetMessageId,
    this.targetChannelId,
    required this.reason,
    this.duration,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
  });

  factory ModerationActionRecord.fromJson(Map<String, dynamic> json) {
    return ModerationActionRecord(
      id: json['id'] as String,
      moderatorId: json['moderatorId'] as String,
      action: ModerationAction.values[json['action'] as int],
      targetUserId: json['targetUserId'] as String?,
      targetMessageId: json['targetMessageId'] as String?,
      targetChannelId: json['targetChannelId'] as String?,
      reason: json['reason'] as String,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moderatorId': moderatorId,
      'action': action.index,
      'targetUserId': targetUserId,
      'targetMessageId': targetMessageId,
      'targetChannelId': targetChannelId,
      'reason': reason,
      'duration': duration?.inSeconds,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

/// Automated moderation rule
class ModerationRule {
  final String id;
  final String name;
  final String description;
  final ModerationRuleType type;
  final Map<String, dynamic> config;
  final ModerationAction action;
  final ModerationSeverity severity;
  final bool isEnabled;
  final DateTime createdAt;
  final String createdBy;

  const ModerationRule({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.config,
    required this.action,
    required this.severity,
    required this.isEnabled,
    required this.createdAt,
    required this.createdBy,
  });

  factory ModerationRule.fromJson(Map<String, dynamic> json) {
    return ModerationRule(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: ModerationRuleType.values[json['type'] as int],
      config: json['config'] as Map<String, dynamic>,
      action: ModerationAction.values[json['action'] as int],
      severity: ModerationSeverity.values[json['severity'] as int],
      isEnabled: json['isEnabled'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.index,
      'config': config,
      'action': action.index,
      'severity': severity.index,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }
}

/// Spam detection result
class SpamDetectionResult {
  final bool isSpam;
  final double confidence;
  final List<String> reasons;
  final Map<String, dynamic> metadata;

  const SpamDetectionResult({
    required this.isSpam,
    required this.confidence,
    required this.reasons,
    this.metadata = const {},
  });

  factory SpamDetectionResult.fromJson(Map<String, dynamic> json) {
    return SpamDetectionResult(
      isSpam: json['isSpam'] as bool,
      confidence: (json['confidence'] as num).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSpam': isSpam,
      'confidence': confidence,
      'reasons': reasons,
      'metadata': metadata,
    };
  }
}

/// Moderation statistics and analytics
class ModerationStats {
  final int totalReports;
  final int pendingReports;
  final int resolvedReports;
  final int totalActions;
  final Map<ReportType, int> reportsByType;
  final Map<ModerationAction, int> actionsByType;
  final Map<String, int> reportsByChannel;
  final DateTime periodStart;
  final DateTime periodEnd;

  const ModerationStats({
    required this.totalReports,
    required this.pendingReports,
    required this.resolvedReports,
    required this.totalActions,
    required this.reportsByType,
    required this.actionsByType,
    required this.reportsByChannel,
    required this.periodStart,
    required this.periodEnd,
  });

  factory ModerationStats.fromJson(Map<String, dynamic> json) {
    return ModerationStats(
      totalReports: json['totalReports'] as int,
      pendingReports: json['pendingReports'] as int,
      resolvedReports: json['resolvedReports'] as int,
      totalActions: json['totalActions'] as int,
      reportsByType: Map<ReportType, int>.from(
        (json['reportsByType'] as Map<String, dynamic>).map(
          (key, value) =>
              MapEntry(ReportType.values[int.parse(key)], value as int),
        ),
      ),
      actionsByType: Map<ModerationAction, int>.from(
        (json['actionsByType'] as Map<String, dynamic>).map(
          (key, value) =>
              MapEntry(ModerationAction.values[int.parse(key)], value as int),
        ),
      ),
      reportsByChannel: Map<String, int>.from(
        json['reportsByChannel'] as Map<String, dynamic>,
      ),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalReports': totalReports,
      'pendingReports': pendingReports,
      'resolvedReports': resolvedReports,
      'totalActions': totalActions,
      'reportsByType': reportsByType.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'actionsByType': actionsByType.map(
        (key, value) => MapEntry(key.index.toString(), value),
      ),
      'reportsByChannel': reportsByChannel,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
    };
  }
}

/// Extension methods for enums
extension ReportTypeExtension on ReportType {
  String get displayName {
    switch (this) {
      case ReportType.harassment:
        return 'Harassment';
      case ReportType.spam:
        return 'Spam';
      case ReportType.inappropriate:
        return 'Inappropriate Content';
      case ReportType.hateSpeech:
        return 'Hate Speech';
      case ReportType.violence:
        return 'Violence';
      case ReportType.nudity:
        return 'Nudity';
      case ReportType.copyright:
        return 'Copyright Violation';
      case ReportType.other:
        return 'Other';
    }
  }
}

extension ModerationActionExtension on ModerationAction {
  String get displayName {
    switch (this) {
      case ModerationAction.none:
        return 'No Action';
      case ModerationAction.flag:
        return 'Flag';
      case ModerationAction.mute:
        return 'Mute';
      case ModerationAction.ban:
        return 'Ban';
      case ModerationAction.shadowBan:
        return 'Shadow Ban';
      case ModerationAction.delete:
        return 'Delete';
      case ModerationAction.quarantine:
        return 'Quarantine';
    }
  }
}

extension ModerationRoleExtension on ModerationRole {
  String get displayName {
    switch (this) {
      case ModerationRole.user:
        return 'User';
      case ModerationRole.moderator:
        return 'Moderator';
      case ModerationRole.admin:
        return 'Admin';
      case ModerationRole.superAdmin:
        return 'Super Admin';
    }
  }

  bool get canModerate => this != ModerationRole.user;
  bool get canBan =>
      this == ModerationRole.admin || this == ModerationRole.superAdmin;
  bool get canDelete =>
      this == ModerationRole.admin || this == ModerationRole.superAdmin;
}
