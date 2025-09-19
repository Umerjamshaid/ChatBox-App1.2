// lib/models/message_models.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Custom message types for ChatBox
class MessageTypes {
  static const String text = 'text';
  static const String image = 'image';
  static const String video = 'video';
  static const String file = 'file';
  static const String location = 'location';
  static const String contact = 'contact';
  static const String voiceNote = 'voice_note';
  static const String poll = 'poll';
  static const String system = 'system';
}

/// Custom message attachment types
class AttachmentTypes {
  static const String location = 'location';
  static const String contact = 'contact';
  static const String voiceNote = 'voice_note';
  static const String poll = 'poll';
}

/// Extended Message model with custom fields
class ChatMessage {
  final Message originalMessage;
  final MessageType messageType;
  final List<ChatAttachment> customAttachments;
  final List<MessageReaction> reactions;
  final int replyCount;
  final bool isEdited;
  final DateTime? editedAt;

  const ChatMessage({
    required this.originalMessage,
    required this.messageType,
    required this.customAttachments,
    required this.reactions,
    required this.replyCount,
    this.isEdited = false,
    this.editedAt,
  });

  // Create from GetStream Message
  factory ChatMessage.fromStreamMessage(Message message) {
    final messageType = _determineMessageType(message);
    final customAttachments = _parseCustomAttachments(
      message.attachments ?? [],
    );

    return ChatMessage(
      originalMessage: message,
      messageType: messageType,
      customAttachments: customAttachments,
      reactions:
          message.reactionCounts?.entries
              .map(
                (entry) => MessageReaction(
                  type: entry.key,
                  count: entry.value,
                  userIds:
                      (message.reactionScores?[entry.key] as List<dynamic>?)
                          ?.cast<String>() ??
                      [],
                ),
              )
              .toList() ??
          [],
      replyCount: message.replyCount ?? 0,
      isEdited:
          message.updatedAt != null &&
          message.updatedAt!.isAfter(message.createdAt),
      editedAt: message.updatedAt,
    );
  }

  static MessageType _determineMessageType(Message message) {
    if (message.attachments?.isNotEmpty == true) {
      final attachment = message.attachments!.first;
      switch (attachment.type) {
        case 'image':
          return MessageType.image;
        case 'video':
          return MessageType.video;
        case 'file':
          return MessageType.file;
        case AttachmentTypes.location:
          return MessageType.location;
        case AttachmentTypes.contact:
          return MessageType.contact;
        case AttachmentTypes.voiceNote:
          return MessageType.voiceNote;
        case AttachmentTypes.poll:
          return MessageType.poll;
        default:
          return MessageType.text;
      }
    }

    if (message.type == 'system') {
      return MessageType.system;
    }

    return MessageType.text;
  }

  static List<ChatAttachment> _parseCustomAttachments(
    List<Attachment> attachments,
  ) {
    return attachments.map((attachment) {
      switch (attachment.type) {
        case AttachmentTypes.location:
          return LocationAttachment.fromAttachment(attachment);
        case AttachmentTypes.contact:
          return ContactAttachment.fromAttachment(attachment);
        case AttachmentTypes.voiceNote:
          return VoiceNoteAttachment.fromAttachment(attachment);
        case AttachmentTypes.poll:
          return PollAttachment.fromAttachment(attachment);
        default:
          return ChatAttachment.fromAttachment(attachment);
      }
    }).toList();
  }
}

/// Message type enum
enum MessageType {
  text,
  image,
  video,
  file,
  location,
  contact,
  voiceNote,
  poll,
  system,
}

/// Base attachment class
abstract class ChatAttachment {
  final String type;
  final String? title;
  final String? description;
  final Map<String, dynamic>? extraData;

  const ChatAttachment({
    required this.type,
    this.title,
    this.description,
    this.extraData,
  });

  factory ChatAttachment.fromAttachment(Attachment attachment) {
    return GenericAttachment(
      type: attachment.type ?? 'unknown',
      title: attachment.title,
      description: attachment.text,
      extraData: attachment.extraData,
    );
  }
}

/// Generic attachment for unknown types
class GenericAttachment extends ChatAttachment {
  const GenericAttachment({
    required super.type,
    super.title,
    super.description,
    super.extraData,
  });
}

/// Location attachment
class LocationAttachment extends ChatAttachment {
  final double latitude;
  final double longitude;
  final String? address;
  final String? placeName;

  const LocationAttachment({
    required this.latitude,
    required this.longitude,
    this.address,
    this.placeName,
    super.title,
    super.description,
    super.extraData,
  }) : super(type: AttachmentTypes.location);

  factory LocationAttachment.fromAttachment(Attachment attachment) {
    return LocationAttachment(
      latitude: (attachment.extraData?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude:
          (attachment.extraData?['longitude'] as num?)?.toDouble() ?? 0.0,
      address: attachment.extraData?['address'] as String?,
      placeName:
          attachment.extraData?['placeName'] as String? ?? attachment.title,
      title: attachment.title,
      description: attachment.text,
      extraData: attachment.extraData,
    );
  }

  Attachment toAttachment() {
    return Attachment(
      type: type,
      title: title ?? placeName ?? 'Location',
      text: description ?? address ?? 'Shared location',
      extraData: {
        ...?extraData,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'placeName': placeName,
      },
    );
  }
}

/// Contact attachment
class ContactAttachment extends ChatAttachment {
  final String contactName;
  final String? phoneNumber;
  final String? email;

  const ContactAttachment({
    required this.contactName,
    this.phoneNumber,
    this.email,
    super.title,
    super.description,
    super.extraData,
  }) : super(type: AttachmentTypes.contact);

  factory ContactAttachment.fromAttachment(Attachment attachment) {
    return ContactAttachment(
      contactName:
          attachment.extraData?['contactName'] as String? ??
          attachment.title ??
          'Contact',
      phoneNumber: attachment.extraData?['phoneNumber'] as String?,
      email: attachment.extraData?['email'] as String?,
      title: attachment.title,
      description: attachment.text,
      extraData: attachment.extraData,
    );
  }

  Attachment toAttachment() {
    return Attachment(
      type: type,
      title: title ?? contactName,
      text: description ?? 'Shared contact',
      extraData: {
        ...?extraData,
        'contactName': contactName,
        'phoneNumber': phoneNumber,
        'email': email,
      },
    );
  }
}

/// Voice note attachment
class VoiceNoteAttachment extends ChatAttachment {
  final String audioUrl;
  final Duration duration;
  final String? waveformData;

  const VoiceNoteAttachment({
    required this.audioUrl,
    required this.duration,
    this.waveformData,
    super.title,
    super.description,
    super.extraData,
  }) : super(type: AttachmentTypes.voiceNote);

  factory VoiceNoteAttachment.fromAttachment(Attachment attachment) {
    return VoiceNoteAttachment(
      audioUrl: attachment.assetUrl ?? attachment.imageUrl ?? '',
      duration: Duration(
        seconds: (attachment.extraData?['duration'] as num?)?.toInt() ?? 0,
      ),
      waveformData: attachment.extraData?['waveformData'] as String?,
      title: attachment.title,
      description: attachment.text,
      extraData: attachment.extraData,
    );
  }

  Attachment toAttachment() {
    return Attachment(
      type: type,
      title: title ?? 'Voice Note',
      text: description ?? 'Voice message',
      assetUrl: audioUrl,
      extraData: {
        ...?extraData,
        'duration': duration.inSeconds,
        'waveformData': waveformData,
      },
    );
  }
}

/// Poll attachment
class PollAttachment extends ChatAttachment {
  final String question;
  final List<PollOption> options;
  final bool isMultipleChoice;
  final bool isAnonymous;
  final DateTime? expiresAt;

  const PollAttachment({
    required this.question,
    required this.options,
    this.isMultipleChoice = false,
    this.isAnonymous = false,
    this.expiresAt,
    super.title,
    super.description,
    super.extraData,
  }) : super(type: AttachmentTypes.poll);

  factory PollAttachment.fromAttachment(Attachment attachment) {
    final optionsData =
        attachment.extraData?['options'] as List<dynamic>? ?? [];
    final options = optionsData
        .map((option) => PollOption.fromJson(option))
        .toList();

    return PollAttachment(
      question:
          attachment.extraData?['question'] as String? ??
          attachment.title ??
          'Poll',
      options: options,
      isMultipleChoice:
          attachment.extraData?['isMultipleChoice'] as bool? ?? false,
      isAnonymous: attachment.extraData?['isAnonymous'] as bool? ?? false,
      expiresAt: attachment.extraData?['expiresAt'] != null
          ? DateTime.parse(attachment.extraData!['expiresAt'] as String)
          : null,
      title: attachment.title,
      description: attachment.text,
      extraData: attachment.extraData,
    );
  }

  Attachment toAttachment() {
    return Attachment(
      type: type,
      title: title ?? question,
      text: description ?? 'Poll',
      extraData: {
        ...?extraData,
        'question': question,
        'options': options.map((option) => option.toJson()).toList(),
        'isMultipleChoice': isMultipleChoice,
        'isAnonymous': isAnonymous,
        'expiresAt': expiresAt?.toIso8601String(),
      },
    );
  }
}

/// Poll option
class PollOption {
  final String id;
  final String text;
  final List<String> votedUserIds;

  const PollOption({
    required this.id,
    required this.text,
    required this.votedUserIds,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      votedUserIds: List<String>.from(json['votedUserIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'votedUserIds': votedUserIds};
  }
}

/// Message reaction
class MessageReaction {
  final String type;
  final int count;
  final List<String> userIds;

  const MessageReaction({
    required this.type,
    required this.count,
    required this.userIds,
  });
}
