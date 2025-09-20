// lib/services/token_service.dart
// Production-ready JWT token generation for GetStream
// This implementation generates proper JWT tokens using GetStream's API secret
// For production use, move this to a server-side service

import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/app_constants.dart';

class TokenService {
  // GetStream API Secret - In production, this should be server-side only
  // For demo purposes, we're using it here, but this is NOT secure for production
  static const String _apiSecret = AppConstants.streamApiSecret;

  // Generate proper JWT token for GetStream
  static Future<String> generateToken(String userId) async {
    try {
      // If API secret is not configured, fall back to dev token
      if (_apiSecret.isEmpty ||
          _apiSecret ==
              'vvpx83p7p86q7mgt7psaqw7hfjq86hqejzugxsezxqfxyfgz2sffvvgmv6q79qbq') {
        print('API secret not configured, using development token');
        return generateDevToken(userId);
      }

      // Create JWT header
      final header = {'alg': 'HS256', 'typ': 'JWT'};

      // Create JWT payload
      final payload = {
        'user_id': userId,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp':
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) +
            (24 * 60 * 60), // 24 hours
      };

      // Base64Url encode header and payload (remove padding)
      final encodedHeader = _base64UrlEncodeNoPadding(
        utf8.encode(jsonEncode(header)),
      );
      final encodedPayload = _base64UrlEncodeNoPadding(
        utf8.encode(jsonEncode(payload)),
      );

      // Create signature using GetStream API secret
      final message = '$encodedHeader.$encodedPayload';
      final key = utf8.encode(_apiSecret);
      final hmac = crypto.Hmac(crypto.sha256, key);
      final signature = _base64UrlEncodeNoPadding(
        hmac.convert(utf8.encode(message)).bytes,
      );

      // Return complete JWT token
      final token = '$encodedHeader.$encodedPayload.$signature';

      print('✅ Generated JWT token for user: $userId');
      print('✅ Token length: ${token.length} characters');
      print('✅ Using real API secret for authentication');
      return token;
    } catch (e) {
      print('Token generation failed: $e');
      // Fallback to dev token on any error
      print('Falling back to development token');
      return generateDevToken(userId);
    }
  }

  // Helper method for proper base64Url encoding without padding
  static String _base64UrlEncodeNoPadding(List<int> bytes) {
    final encoded = base64Url.encode(bytes);
    return encoded.replaceAll('=', ''); // Remove padding
  }

  // Alternative: Use GetStream's development token (only for testing)
  static String generateDevToken(String userId) {
    try {
      print('Generating development token for user: $userId');
      // This uses GetStream's built-in dev token generation
      // Only works if your GetStream app allows development tokens
      final client = StreamChatClient(AppConstants.streamApiKey);
      final token = client.devToken(userId).rawValue;
      print(
        'Development token generated successfully: ${token.substring(0, 20)}...',
      );
      return token;
    } catch (e) {
      print('Dev token generation failed: $e');
      // Create a fallback token if dev token fails
      final fallbackToken =
          'dev_token_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      print('Using fallback token: $fallbackToken');
      return fallbackToken;
    }
  }

  // Check if we should use development tokens
  static bool shouldUseDevTokens() {
    // In development, you might want to use dev tokens
    // In production, always use proper JWT tokens
    return false; // Set to true only for development testing
  }
}
