// lib/services/encryption_service.dart
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EncryptionService {
  static const String _encryptionEnabledKey = 'encryption_enabled';
  static const String _encryptionKeyKey = 'encryption_key';

  final SharedPreferences _prefs;
  encrypt.Key? _key;
  encrypt.Encrypter? _encrypter;

  EncryptionService(this._prefs) {
    _initializeEncryption();
  }

  bool get encryptionEnabled => _prefs.getBool(_encryptionEnabledKey) ?? true;

  Future<void> _initializeEncryption() async {
    String keyString = _prefs.getString(_encryptionKeyKey) ?? '';

    if (keyString.isEmpty) {
      // Generate a new key
      _key = encrypt.Key.fromSecureRandom(32);
      keyString = base64Encode(_key!.bytes);
      await _prefs.setString(_encryptionKeyKey, keyString);
    } else {
      _key = encrypt.Key.fromBase64(keyString);
    }

    _encrypter = encrypt.Encrypter(encrypt.AES(_key!));
  }

  Future<void> setEncryptionEnabled(bool enabled) async {
    await _prefs.setBool(_encryptionEnabledKey, enabled);
  }

  String encryptMessage(String message) {
    if (!encryptionEnabled || _encrypter == null) {
      return message; // Return unencrypted if disabled
    }

    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(message, iv: iv);
      // Store IV with encrypted data
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Encryption failed: $e');
      return message;
    }
  }

  String decryptMessage(String encryptedMessage) {
    if (!encryptionEnabled || _encrypter == null) {
      return encryptedMessage; // Return as-is if disabled
    }

    try {
      final parts = encryptedMessage.split(':');
      if (parts.length != 2) {
        return encryptedMessage; // Not encrypted format
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final decrypted = _encrypter!.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      print('Decryption failed: $e');
      return encryptedMessage;
    }
  }

  bool isMessageEncrypted(String message) {
    return message.contains(':') && message.split(':').length == 2;
  }

  // Get encryption status for UI display
  Map<String, dynamic> getEncryptionStatus() {
    return {
      'enabled': encryptionEnabled,
      'keyGenerated': _key != null,
      'algorithm': 'AES-256',
    };
  }

  // Generate new encryption key (for security)
  Future<void> regenerateKey() async {
    _key = encrypt.Key.fromSecureRandom(32);
    final keyString = base64Encode(_key!.bytes);
    await _prefs.setString(_encryptionKeyKey, keyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(_key!));
  }
}
