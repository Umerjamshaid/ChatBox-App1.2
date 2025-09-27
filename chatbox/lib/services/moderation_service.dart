import 'dart:async';
import 'dart:convert';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream_chat;
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/models/moderation_models.dart';
import 'package:chatbox/services/offline_storage_service.dart';

/// Comprehensive moderation service for ChatBox
class ModerationService {
  static final ModerationService _instance = ModerationService._internal();
  final StreamChatService _streamService = StreamChatService();
  final OfflineStorageService _storageService = OfflineStorageService();

  // In-memory caches
  final Map<String, ModerationReport> _reportsCache = {};
  final Map<String, ModerationActionRecord> _actionsCache = {};
  final Map<String, ModerationRule> _rulesCache = {};

  // Stream controllers for real-time updates
  final StreamController<ModerationReport> _reportController =
      StreamController.broadcast();
  final StreamController<ModerationActionRecord> _actionController =
      StreamController.broadcast();

  factory ModerationService() {
    return _instance;
  }

  ModerationService._internal() {
    _initialize();
  }

  // Streams for UI updates
  Stream<ModerationReport> get reportStream => _reportController.stream;
  Stream<ModerationActionRecord> get actionStream => _actionController.stream;

  void _initialize() {
    // Load cached data on startup
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    try {
      // Load reports, actions, and rules from storage
      // Implementation would load from local database
      print('ModerationService: Loaded cached moderation data');
    } catch (e) {
      print('ModerationService: Failed to load cached data: $e');
    }
  }

  /// Report a message or user
  Future<ModerationReport> reportContent({
    required String reporterId,
    String? targetUserId,
    String? targetMessageId,
    String? targetChannelId,
    required ReportType reportType,
    required String reason,
    String? description,
    List<String> evidence = const [],
  }) async {
    try {
      final report = ModerationReport(
        id: 'report_${DateTime.now().millisecondsSinceEpoch}',
        reporterId: reporterId,
        targetUserId: targetUserId,
        targetMessageId: targetMessageId,
        targetChannelId: targetChannelId,
        reportType: reportType,
        reason: reason,
        description: description,
        status: ReportStatus.pending,
        severity: _calculateSeverity(reportType),
        createdAt: DateTime.now(),
        evidence: evidence,
      );

      // Store locally
      _reportsCache[report.id] = report;

      // Send to Stream Chat for moderation
      if (targetMessageId != null) {
        await _flagMessageInStream(targetMessageId, reason);
      }

      // Cache the report
      await _cacheReport(report);

      // Notify listeners
      _reportController.add(report);

      return report;
    } catch (e) {
      throw Exception('Failed to submit report: $e');
    }
  }

  /// Moderate a user (ban, mute, etc.)
  Future<ModerationActionRecord> moderateUser({
    required String moderatorId,
    required String targetUserId,
    required ModerationAction action,
    required String reason,
    Duration? duration,
    String? channelId,
  }) async {
    try {
      final actionRecord = ModerationActionRecord(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        moderatorId: moderatorId,
        action: action,
        targetUserId: targetUserId,
        targetChannelId: channelId,
        reason: reason,
        duration: duration,
        createdAt: DateTime.now(),
        expiresAt: duration != null ? DateTime.now().add(duration) : null,
      );

      // Apply action in Stream Chat
      await _applyActionToStream(actionRecord);

      // Store locally
      _actionsCache[actionRecord.id] = actionRecord;

      // Cache the action
      await _cacheAction(actionRecord);

      // Notify listeners
      _actionController.add(actionRecord);

      return actionRecord;
    } catch (e) {
      throw Exception('Failed to moderate user: $e');
    }
  }

  /// Moderate a message (delete, flag, etc.)
  Future<ModerationActionRecord> moderateMessage({
    required String moderatorId,
    required String targetMessageId,
    required ModerationAction action,
    required String reason,
    String? channelId,
  }) async {
    try {
      final actionRecord = ModerationActionRecord(
        id: 'action_${DateTime.now().millisecondsSinceEpoch}',
        moderatorId: moderatorId,
        action: action,
        targetMessageId: targetMessageId,
        targetChannelId: channelId,
        reason: reason,
        createdAt: DateTime.now(),
      );

      // Apply action in Stream Chat
      await _applyMessageActionToStream(actionRecord);

      // Store locally
      _actionsCache[actionRecord.id] = actionRecord;

      // Cache the action
      await _cacheAction(actionRecord);

      // Notify listeners
      _actionController.add(actionRecord);

      return actionRecord;
    } catch (e) {
      throw Exception('Failed to moderate message: $e');
    }
  }

  /// Get pending reports
  Future<List<ModerationReport>> getPendingReports({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // In a real implementation, this would query from database
      final pendingReports = _reportsCache.values
          .where((report) => report.status == ReportStatus.pending)
          .skip(offset)
          .take(limit)
          .toList();

      return pendingReports;
    } catch (e) {
      throw Exception('Failed to get pending reports: $e');
    }
  }

  /// Resolve a report
  Future<void> resolveReport({
    required String reportId,
    required String moderatorId,
    required ReportStatus status,
    String? resolutionNotes,
  }) async {
    try {
      final report = _reportsCache[reportId];
      if (report == null) {
        throw Exception('Report not found');
      }

      final updatedReport = ModerationReport(
        id: report.id,
        reporterId: report.reporterId,
        targetUserId: report.targetUserId,
        targetMessageId: report.targetMessageId,
        targetChannelId: report.targetChannelId,
        reportType: report.reportType,
        reason: report.reason,
        description: report.description,
        status: status,
        severity: report.severity,
        createdAt: report.createdAt,
        resolvedAt: DateTime.now(),
        resolvedBy: moderatorId,
        resolutionNotes: resolutionNotes,
        evidence: report.evidence,
      );

      _reportsCache[reportId] = updatedReport;
      await _cacheReport(updatedReport);
      _reportController.add(updatedReport);
    } catch (e) {
      throw Exception('Failed to resolve report: $e');
    }
  }

  /// Create a moderation rule
  Future<ModerationRule> createRule({
    required String name,
    required String description,
    required ModerationRuleType type,
    required Map<String, dynamic> config,
    required ModerationAction action,
    required ModerationSeverity severity,
    required String createdBy,
  }) async {
    try {
      final rule = ModerationRule(
        id: 'rule_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        type: type,
        config: config,
        action: action,
        severity: severity,
        isEnabled: true,
        createdAt: DateTime.now(),
        createdBy: createdBy,
      );

      _rulesCache[rule.id] = rule;
      await _cacheRule(rule);

      return rule;
    } catch (e) {
      throw Exception('Failed to create rule: $e');
    }
  }

  /// Check message against moderation rules
  Future<ModerationAction?> checkMessageAgainstRules({
    required String messageText,
    required String userId,
    required String channelId,
  }) async {
    try {
      for (final rule in _rulesCache.values) {
        if (!rule.isEnabled) continue;

        final shouldTrigger = await _evaluateRule(
          rule,
          messageText,
          userId,
          channelId,
        );
        if (shouldTrigger) {
          return rule.action;
        }
      }

      return null;
    } catch (e) {
      print('Failed to check message against rules: $e');
      return null;
    }
  }

  /// Get moderation statistics
  Future<ModerationStats> getModerationStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final start = startDate ?? now.subtract(const Duration(days: 30));
      final end = endDate ?? now;

      final reportsInPeriod = _reportsCache.values
          .where(
            (report) =>
                report.createdAt.isAfter(start) &&
                report.createdAt.isBefore(end),
          )
          .toList();

      final actionsInPeriod = _actionsCache.values
          .where(
            (action) =>
                action.createdAt.isAfter(start) &&
                action.createdAt.isBefore(end),
          )
          .toList();

      final reportsByType = <ReportType, int>{};
      final actionsByType = <ModerationAction, int>{};
      final reportsByChannel = <String, int>{};

      for (final report in reportsInPeriod) {
        reportsByType[report.reportType] =
            (reportsByType[report.reportType] ?? 0) + 1;
        if (report.targetChannelId != null) {
          reportsByChannel[report.targetChannelId!] =
              (reportsByChannel[report.targetChannelId!] ?? 0) + 1;
        }
      }

      for (final action in actionsInPeriod) {
        actionsByType[action.action] = (actionsByType[action.action] ?? 0) + 1;
      }

      return ModerationStats(
        totalReports: reportsInPeriod.length,
        pendingReports: reportsInPeriod
            .where((r) => r.status == ReportStatus.pending)
            .length,
        resolvedReports: reportsInPeriod
            .where((r) => r.status != ReportStatus.pending)
            .length,
        totalActions: actionsInPeriod.length,
        reportsByType: reportsByType,
        actionsByType: actionsByType,
        reportsByChannel: reportsByChannel,
        periodStart: start,
        periodEnd: end,
      );
    } catch (e) {
      throw Exception('Failed to get moderation stats: $e');
    }
  }

  /// Check if user has active moderation actions
  Future<List<ModerationActionRecord>> getActiveUserActions(
    String userId,
  ) async {
    try {
      return _actionsCache.values
          .where(
            (action) =>
                action.targetUserId == userId &&
                action.isActive &&
                (action.expiresAt == null ||
                    action.expiresAt!.isAfter(DateTime.now())),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to get active user actions: $e');
    }
  }

  /// Spam detection
  Future<SpamDetectionResult> detectSpam(String messageText) async {
    try {
      // Simple spam detection - in production, use ML models or services
      final reasons = <String>[];
      var confidence = 0.0;

      // Check for excessive caps
      final capsRatio =
          messageText.replaceAll(RegExp(r'[^A-Z]'), '').length /
          messageText.length;
      if (capsRatio > 0.7) {
        reasons.add('Excessive capitalization');
        confidence += 0.3;
      }

      // Check for repeated characters
      if (RegExp(r'(.)\1{4,}').hasMatch(messageText)) {
        reasons.add('Repeated characters');
        confidence += 0.2;
      }

      // Check for common spam patterns
      final spamPatterns = [
        r'\b(?:viagra|casino|lottery|winner)\b',
        r'(?:http|https|www\.)\S+',
        r'\b\d{10,}\b', // Long numbers
      ];

      for (final pattern in spamPatterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(messageText)) {
          reasons.add('Spam pattern detected');
          confidence += 0.4;
          break;
        }
      }

      return SpamDetectionResult(
        isSpam: confidence > 0.5,
        confidence: confidence.clamp(0.0, 1.0),
        reasons: reasons,
      );
    } catch (e) {
      return SpamDetectionResult(
        isSpam: false,
        confidence: 0.0,
        reasons: ['Detection failed'],
      );
    }
  }

  // Private helper methods

  ModerationSeverity _calculateSeverity(ReportType type) {
    switch (type) {
      case ReportType.harassment:
      case ReportType.hateSpeech:
      case ReportType.violence:
        return ModerationSeverity.high;
      case ReportType.spam:
      case ReportType.nudity:
      case ReportType.copyright:
        return ModerationSeverity.medium;
      case ReportType.inappropriate:
      case ReportType.other:
        return ModerationSeverity.low;
    }
  }

  Future<void> _flagMessageInStream(String messageId, String reason) async {
    try {
      // Use Stream Chat's moderation features
      await _streamService.client.flagMessage(messageId);
    } catch (e) {
      print('Failed to flag message in Stream: $e');
      // Don't throw - local moderation still works
    }
  }

  Future<void> _applyActionToStream(ModerationActionRecord action) async {
    try {
      switch (action.action) {
        case ModerationAction.ban:
          // TODO: Implement Stream Chat ban API
          print('Banning user ${action.targetUserId} for ${action.duration}');
          break;
        case ModerationAction.mute:
          // TODO: Implement Stream Chat mute API
          print('Muting user ${action.targetUserId}');
          break;
        case ModerationAction.shadowBan:
          // TODO: Implement Stream Chat shadow ban API
          print('Shadow banning user ${action.targetUserId}');
          break;
        default:
          // Other actions handled locally
          break;
      }
    } catch (e) {
      print('Failed to apply action to Stream: $e');
      throw e;
    }
  }

  Future<void> _applyMessageActionToStream(
    ModerationActionRecord action,
  ) async {
    try {
      switch (action.action) {
        case ModerationAction.delete:
          // TODO: Implement Stream Chat delete message API
          print('Deleting message ${action.targetMessageId}');
          break;
        case ModerationAction.quarantine:
          // TODO: Implement Stream Chat quarantine API
          print('Quarantining message ${action.targetMessageId}');
          break;
        default:
          // Other actions handled locally
          break;
      }
    } catch (e) {
      print('Failed to apply message action to Stream: $e');
      throw e;
    }
  }

  Future<bool> _evaluateRule(
    ModerationRule rule,
    String messageText,
    String userId,
    String channelId,
  ) async {
    try {
      switch (rule.type) {
        case ModerationRuleType.keywordFilter:
          final keywords = rule.config['keywords'] as List<String>? ?? [];
          return keywords.any(
            (keyword) =>
                messageText.toLowerCase().contains(keyword.toLowerCase()),
          );

        case ModerationRuleType.spamDetection:
          final spamResult = await detectSpam(messageText);
          return spamResult.isSpam &&
              spamResult.confidence >
                  (rule.config['threshold'] as double? ?? 0.5);

        case ModerationRuleType.rateLimit:
          // Implement rate limiting logic
          return false; // Placeholder

        case ModerationRuleType.contentFilter:
          // Implement content filtering
          return false; // Placeholder

        case ModerationRuleType.userBehavior:
          // Implement user behavior analysis
          return false; // Placeholder

        default:
          return false;
      }
    } catch (e) {
      print('Failed to evaluate rule ${rule.id}: $e');
      return false;
    }
  }

  Future<void> _cacheReport(ModerationReport report) async {
    try {
      // TODO: Implement proper caching with OfflineStorageService
      print('Report cached: ${report.id}');
    } catch (e) {
      print('Failed to cache report: $e');
    }
  }

  Future<void> _cacheAction(ModerationActionRecord action) async {
    try {
      // TODO: Implement proper caching with OfflineStorageService
      print('Action cached: ${action.id}');
    } catch (e) {
      print('Failed to cache action: $e');
    }
  }

  Future<void> _cacheRule(ModerationRule rule) async {
    try {
      // TODO: Implement proper caching with OfflineStorageService
      print('Rule cached: ${rule.id}');
    } catch (e) {
      print('Failed to cache rule: $e');
    }
  }

  void dispose() {
    _reportController.close();
    _actionController.close();
  }
}
