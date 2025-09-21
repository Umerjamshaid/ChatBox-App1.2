// lib/services/emoji_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class CustomEmoji {
  final String id;
  final String name;
  final String imagePath;
  final DateTime createdAt;
  final String category;

  CustomEmoji({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'category': category,
    };
  }

  factory CustomEmoji.fromJson(Map<String, dynamic> json) {
    return CustomEmoji(
      id: json['id'],
      name: json['name'],
      imagePath: json['imagePath'],
      createdAt: DateTime.parse(json['createdAt']),
      category: json['category'] ?? 'custom',
    );
  }
}

class EmojiPack {
  final String id;
  final String name;
  final String description;
  final List<CustomEmoji> emojis;
  final bool isBuiltIn;

  EmojiPack({
    required this.id,
    required this.name,
    required this.description,
    required this.emojis,
    this.isBuiltIn = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emojis': emojis.map((e) => e.toJson()).toList(),
      'isBuiltIn': isBuiltIn,
    };
  }

  factory EmojiPack.fromJson(Map<String, dynamic> json) {
    return EmojiPack(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      emojis: (json['emojis'] as List)
          .map((e) => CustomEmoji.fromJson(e))
          .toList(),
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }
}

class EmojiService {
  static const String _customEmojisKey = 'custom_emojis';
  static const String _emojiPacksKey = 'emoji_packs';
  static const String _recentEmojisKey = 'recent_emojis';

  final SharedPreferences _prefs;

  EmojiService(this._prefs);

  // Built-in emoji categories
  static const Map<String, List<String>> builtInEmojis = {
    'smileys': ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇'],
    'hearts': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔'],
    'gestures': ['👍', '👎', '👌', '✌️', '🤞', '👏', '🙌', '🤝', '🙏', '✋'],
    'animals': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯'],
    'food': ['🍎', '🍊', '🍋', '🍌', '🍉', '🍇', '🍓', '🍈', '🍒', '🍑'],
    'activities': ['⚽', '🏀', '🏈', '⚾', '🎾', '🏐', '🏉', '🎱', '🏓', '🏸'],
  };

  // Get all available emojis (built-in + custom)
  Map<String, List<String>> getAllEmojis() {
    final allEmojis = Map<String, List<String>>.from(builtInEmojis);

    // Add custom emojis
    final customEmojis = getCustomEmojis();
    if (customEmojis.isNotEmpty) {
      allEmojis['custom'] = customEmojis.map((e) => e.name).toList();
    }

    return allEmojis;
  }

  // Custom emoji management
  List<CustomEmoji> getCustomEmojis() {
    try {
      final emojisJson = _prefs.getString(_customEmojisKey);
      if (emojisJson == null) return [];

      final emojisList = jsonDecode(emojisJson) as List;
      return emojisList.map((e) => CustomEmoji.fromJson(e)).toList();
    } catch (e) {
      print('Error loading custom emojis: $e');
      return [];
    }
  }

  Future<void> addCustomEmoji(CustomEmoji emoji) async {
    final customEmojis = getCustomEmojis();
    customEmojis.add(emoji);

    final emojisJson = jsonEncode(customEmojis.map((e) => e.toJson()).toList());
    await _prefs.setString(_customEmojisKey, emojisJson);
  }

  Future<void> removeCustomEmoji(String emojiId) async {
    final customEmojis = getCustomEmojis();
    customEmojis.removeWhere((e) => e.id == emojiId);

    // Also delete the image file
    final emojiToRemove = customEmojis.firstWhere((e) => e.id == emojiId);
    try {
      final file = File(emojiToRemove.imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting emoji file: $e');
    }

    final emojisJson = jsonEncode(customEmojis.map((e) => e.toJson()).toList());
    await _prefs.setString(_customEmojisKey, emojisJson);
  }

  // Emoji packs management
  List<EmojiPack> getEmojiPacks() {
    try {
      final packsJson = _prefs.getString(_emojiPacksKey);
      if (packsJson == null) return _getDefaultPacks();

      final packsList = jsonDecode(packsJson) as List;
      final packs = packsList.map((p) => EmojiPack.fromJson(p)).toList();

      // Add default packs if not present
      final defaultPacks = _getDefaultPacks();
      for (final defaultPack in defaultPacks) {
        if (!packs.any((p) => p.id == defaultPack.id)) {
          packs.add(defaultPack);
        }
      }

      return packs;
    } catch (e) {
      print('Error loading emoji packs: $e');
      return _getDefaultPacks();
    }
  }

  List<EmojiPack> _getDefaultPacks() {
    return [
      EmojiPack(
        id: 'built_in',
        name: 'Built-in Emojis',
        description: 'Standard emoji collection',
        emojis: [],
        isBuiltIn: true,
      ),
      EmojiPack(
        id: 'recent',
        name: 'Recently Used',
        description: 'Your recently used emojis',
        emojis: [],
        isBuiltIn: true,
      ),
    ];
  }

  Future<void> createEmojiPack(EmojiPack pack) async {
    final packs = getEmojiPacks();
    packs.add(pack);

    final packsJson = jsonEncode(packs.map((p) => p.toJson()).toList());
    await _prefs.setString(_emojiPacksKey, packsJson);
  }

  Future<void> deleteEmojiPack(String packId) async {
    final packs = getEmojiPacks();
    packs.removeWhere((p) => p.id == packId);

    final packsJson = jsonEncode(packs.map((p) => p.toJson()).toList());
    await _prefs.setString(_emojiPacksKey, packsJson);
  }

  // Recent emojis
  List<String> getRecentEmojis() {
    try {
      final recentJson = _prefs.getString(_recentEmojisKey);
      if (recentJson == null) return [];

      return List<String>.from(jsonDecode(recentJson));
    } catch (e) {
      print('Error loading recent emojis: $e');
      return [];
    }
  }

  Future<void> addToRecentEmojis(String emoji) async {
    final recent = getRecentEmojis();

    // Remove if already exists
    recent.remove(emoji);

    // Add to beginning
    recent.insert(0, emoji);

    // Keep only last 20
    if (recent.length > 20) {
      recent.removeRange(20, recent.length);
    }

    await _prefs.setString(_recentEmojisKey, jsonEncode(recent));
  }

  // File management
  Future<String> saveEmojiImage(File imageFile, String emojiName) async {
    final directory = await getApplicationDocumentsDirectory();
    final emojiDir = Directory('${directory.path}/emojis');

    if (!await emojiDir.exists()) {
      await emojiDir.create(recursive: true);
    }

    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$emojiName.png';
    final savedFile = await imageFile.copy('${emojiDir.path}/$fileName');

    return savedFile.path;
  }

  // Search emojis
  List<String> searchEmojis(String query) {
    if (query.isEmpty) return [];

    final allEmojis = <String>[];

    // Search built-in emojis
    for (final category in builtInEmojis.values) {
      allEmojis.addAll(category);
    }

    // Search custom emojis
    final customEmojis = getCustomEmojis();
    allEmojis.addAll(customEmojis.map((e) => e.name));

    return allEmojis
        .where((emoji) => emoji.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get emoji by name
  CustomEmoji? getCustomEmojiByName(String name) {
    final customEmojis = getCustomEmojis();
    return customEmojis.firstWhere((e) => e.name == name);
  }
}
