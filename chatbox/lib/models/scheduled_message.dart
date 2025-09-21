// lib/models/scheduled_message.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ScheduledMessage {
  final String id;
  final String channelId;
  final String text;
  final List<Attachment> attachments;
  final DateTime scheduledTime;
  final DateTime createdAt;
  final String createdBy;
  final bool isSent;
  final DateTime? sentAt;
  final String? failureReason;

  const ScheduledMessage({
    required this.id,
    required this.channelId,
    required this.text,
    required this.attachments,
    required this.scheduledTime,
    required this.createdAt,
    required this.createdBy,
    this.isSent = false,
    this.sentAt,
    this.failureReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'channelId': channelId,
      'text': text,
      'attachments': attachments.map((a) => a.toJson()).toList(),
      'scheduledTime': scheduledTime.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isSent': isSent,
      'sentAt': sentAt?.toIso8601String(),
      'failureReason': failureReason,
    };
  }

  factory ScheduledMessage.fromJson(Map<String, dynamic> json) {
    return ScheduledMessage(
      id: json['id'],
      channelId: json['channelId'],
      text: json['text'],
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((a) => Attachment.fromJson(a))
              .toList() ??
          [],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      isSent: json['isSent'] ?? false,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      failureReason: json['failureReason'],
    );
  }

  ScheduledMessage copyWith({
    String? id,
    String? channelId,
    String? text,
    List<Attachment>? attachments,
    DateTime? scheduledTime,
    DateTime? createdAt,
    String? createdBy,
    bool? isSent,
    DateTime? sentAt,
    String? failureReason,
  }) {
    return ScheduledMessage(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      text: text ?? this.text,
      attachments: attachments ?? this.attachments,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isSent: isSent ?? this.isSent,
      sentAt: sentAt ?? this.sentAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }
}
