// lib/services/qr_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chatbox/models/user_model.dart';

class QRService {
  // Generate QR code data for user profile
  static String generateUserQRData(ChatUser user) {
    final qrData = {
      'type': 'chatbox_user',
      'userId': user.id,
      'name': user.name,
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
    };

    return jsonEncode(qrData);
  }

  // Parse QR code data
  static Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      // Validate QR code format
      if (data['type'] != 'chatbox_user' || !data.containsKey('userId')) {
        return null;
      }

      return data;
    } catch (e) {
      return null;
    }
  }

  // Share user profile via various methods
  static Future<void> shareUserProfile(ChatUser user) async {
    final qrData = generateUserQRData(user);
    final shareText =
        '''
Join me on ChatBox!

👤 ${user.name ?? 'ChatBox User'}
🔗 User ID: ${user.id}

Scan the QR code or use this link to add me as a friend.
''';

    try {
      await Share.share(shareText, subject: 'Join me on ChatBox!');
    } catch (e) {
      throw Exception('Failed to share profile: $e');
    }
  }

  // Generate invite link
  static String generateInviteLink(String userId) {
    // In a real app, this would be your app's deep link
    return 'https://chatbox.app/invite/$userId';
  }

  // Share invite link
  static Future<void> shareInviteLink(ChatUser user) async {
    final inviteLink = generateInviteLink(user.id);
    final shareText =
        '''
🎉 You're invited to join ChatBox!

Join ${user.name ?? 'me'} and start chatting!

📱 Download ChatBox: [App Store/Google Play Link]
🔗 Invite Link: $inviteLink

Use code: ${user.id.substring(0, 8).toUpperCase()} for bonus features!
''';

    try {
      await Share.share(shareText, subject: 'Join ChatBox with me!');
    } catch (e) {
      throw Exception('Failed to share invite link: $e');
    }
  }

  // Create QR code widget
  static Widget generateQRCode(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      backgroundColor: const Color(0xFFFFFFFF),
      foregroundColor: const Color(0xFF000000),
    );
  }

  // Validate QR code data
  static bool isValidChatBoxQR(String qrData) {
    final parsed = parseQRData(qrData);
    return parsed != null && parsed['type'] == 'chatbox_user';
  }

  // Extract user ID from QR code
  static String? extractUserIdFromQR(String qrData) {
    final parsed = parseQRData(qrData);
    return parsed?['userId'] as String?;
  }
}
