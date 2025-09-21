// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppMessage _$AppMessageFromJson(Map<String, dynamic> json) => AppMessage(
  id: json['id'] as String,
  text: json['text'] as String,
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  userImage: json['userImage'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  status: json['status'] as String,
  channelId: json['channelId'] as String?,
  reactions: (json['reactions'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
);

Map<String, dynamic> _$AppMessageToJson(AppMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'userId': instance.userId,
      'userName': instance.userName,
      'userImage': instance.userImage,
      'createdAt': instance.createdAt.toIso8601String(),
      'status': instance.status,
      'channelId': instance.channelId,
      'reactions': instance.reactions,
    };
