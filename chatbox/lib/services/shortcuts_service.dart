// lib/services/shortcuts_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class QuickAction {
  final String id;
  final String name;
  final String action;
  final String? icon;
  final Map<String, dynamic> parameters;

  QuickAction({
    required this.id,
    required this.name,
    required this.action,
    this.icon,
    this.parameters = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'action': action,
      'icon': icon,
      'parameters': parameters,
    };
  }

  factory QuickAction.fromJson(Map<String, dynamic> json) {
    return QuickAction(
      id: json['id'],
      name: json['name'],
      action: json['action'],
      icon: json['icon'],
      parameters: Map<String, dynamic>.from(json['parameters'] ?? {}),
    );
  }
}

class QuickReply {
  final String id;
  final String text;
  final String category;
  final int useCount;

  QuickReply({
    required this.id,
    required this.text,
    required this.category,
    this.useCount = 0,
  });

  QuickReply copyWith({
    String? id,
    String? text,
    String? category,
    int? useCount,
  }) {
    return QuickReply(
      id: id ?? this.id,
      text: text ?? this.text,
      category: category ?? this.category,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'category': category, 'useCount': useCount};
  }

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['id'],
      text: json['text'],
      category: json['category'] ?? 'general',
      useCount: json['useCount'] ?? 0,
    );
  }
}

class ShortcutsService {
  static const String _quickActionsKey = 'quick_actions';
  static const String _quickRepliesKey = 'quick_replies';
  static const String _swipeGesturesKey = 'swipe_gestures';
  static const String _keyboardShortcutsKey = 'keyboard_shortcuts';

  final SharedPreferences _prefs;

  ShortcutsService(this._prefs);

  // Default quick actions
  static final List<QuickAction> defaultQuickActions = [
    QuickAction(id: 'reply', name: 'Reply', action: 'reply', icon: 'reply'),
    QuickAction(
      id: 'forward',
      name: 'Forward',
      action: 'forward',
      icon: 'forward',
    ),
    QuickAction(id: 'copy', name: 'Copy Text', action: 'copy', icon: 'copy'),
    QuickAction(id: 'delete', name: 'Delete', action: 'delete', icon: 'delete'),
    QuickAction(
      id: 'schedule',
      name: 'Schedule Message',
      action: 'schedule',
      icon: 'schedule',
    ),
  ];

  // Default quick replies
  static final List<QuickReply> defaultQuickReplies = [
    QuickReply(id: 'thanks', text: 'Thank you!', category: 'polite'),
    QuickReply(id: 'ok', text: 'Okay', category: 'general'),
    QuickReply(id: 'yes', text: 'Yes', category: 'general'),
    QuickReply(id: 'no', text: 'No', category: 'general'),
    QuickReply(id: 'later', text: 'Talk to you later!', category: 'goodbye'),
    QuickReply(id: 'busy', text: 'I\'m busy right now', category: 'status'),
    QuickReply(
      id: 'call',
      text: 'Can we talk on call?',
      category: 'communication',
    ),
  ];

  // Quick Actions Management
  List<QuickAction> getQuickActions() {
    try {
      final actionsJson = _prefs.getString(_quickActionsKey);
      if (actionsJson == null) return defaultQuickActions;

      final actionsList = jsonDecode(actionsJson) as List;
      return actionsList.map((a) => QuickAction.fromJson(a)).toList();
    } catch (e) {
      print('Error loading quick actions: $e');
      return defaultQuickActions;
    }
  }

  Future<void> saveQuickActions(List<QuickAction> actions) async {
    final actionsJson = jsonEncode(actions.map((a) => a.toJson()).toList());
    await _prefs.setString(_quickActionsKey, actionsJson);
  }

  Future<void> addQuickAction(QuickAction action) async {
    final actions = getQuickActions();
    actions.add(action);
    await saveQuickActions(actions);
  }

  Future<void> removeQuickAction(String actionId) async {
    final actions = getQuickActions();
    actions.removeWhere((a) => a.id == actionId);
    await saveQuickActions(actions);
  }

  // Quick Replies Management
  List<QuickReply> getQuickReplies() {
    try {
      final repliesJson = _prefs.getString(_quickRepliesKey);
      if (repliesJson == null) return defaultQuickReplies;

      final repliesList = jsonDecode(repliesJson) as List;
      final replies = repliesList.map((r) => QuickReply.fromJson(r)).toList();

      // Add defaults if not present
      for (final defaultReply in defaultQuickReplies) {
        if (!replies.any((r) => r.id == defaultReply.id)) {
          replies.add(defaultReply);
        }
      }

      return replies;
    } catch (e) {
      print('Error loading quick replies: $e');
      return defaultQuickReplies;
    }
  }

  Future<void> saveQuickReplies(List<QuickReply> replies) async {
    final repliesJson = jsonEncode(replies.map((r) => r.toJson()).toList());
    await _prefs.setString(_quickRepliesKey, repliesJson);
  }

  Future<void> addQuickReply(QuickReply reply) async {
    final replies = getQuickReplies();
    replies.add(reply);
    await saveQuickReplies(replies);
  }

  Future<void> updateQuickReply(QuickReply reply) async {
    final replies = getQuickReplies();
    final index = replies.indexWhere((r) => r.id == reply.id);
    if (index >= 0) {
      replies[index] = reply;
      await saveQuickReplies(replies);
    }
  }

  Future<void> removeQuickReply(String replyId) async {
    final replies = getQuickReplies();
    replies.removeWhere((r) => r.id == replyId);
    await saveQuickReplies(replies);
  }

  Future<void> incrementReplyUsage(String replyId) async {
    final replies = getQuickReplies();
    final index = replies.indexWhere((r) => r.id == replyId);
    if (index >= 0) {
      replies[index] = replies[index].copyWith(
        useCount: replies[index].useCount + 1,
      );
      await saveQuickReplies(replies);
    }
  }

  // Swipe Gestures
  Map<String, String> getSwipeGestures() {
    try {
      final gesturesJson = _prefs.getString(_swipeGesturesKey);
      if (gesturesJson == null) {
        return {
          'swipe_right': 'reply',
          'swipe_left': 'forward',
          'swipe_up': 'copy',
          'swipe_down': 'delete',
        };
      }

      return Map<String, String>.from(jsonDecode(gesturesJson));
    } catch (e) {
      print('Error loading swipe gestures: $e');
      return {};
    }
  }

  Future<void> setSwipeGesture(String gesture, String action) async {
    final gestures = getSwipeGestures();
    gestures[gesture] = action;
    await _prefs.setString(_swipeGesturesKey, jsonEncode(gestures));
  }

  // Keyboard Shortcuts
  Map<String, String> getKeyboardShortcuts() {
    try {
      final shortcutsJson = _prefs.getString(_keyboardShortcutsKey);
      if (shortcutsJson == null) {
        return {
          'ctrl+r': 'reply',
          'ctrl+f': 'forward',
          'ctrl+c': 'copy',
          'ctrl+d': 'delete',
          'ctrl+s': 'schedule',
          'ctrl+e': 'emoji',
        };
      }

      return Map<String, String>.from(jsonDecode(shortcutsJson));
    } catch (e) {
      print('Error loading keyboard shortcuts: $e');
      return {};
    }
  }

  Future<void> setKeyboardShortcut(String key, String action) async {
    final shortcuts = getKeyboardShortcuts();
    shortcuts[key] = action;
    await _prefs.setString(_keyboardShortcutsKey, jsonEncode(shortcuts));
  }

  // Get action by gesture
  String? getActionByGesture(String gesture) {
    final gestures = getSwipeGestures();
    return gestures[gesture];
  }

  // Get action by keyboard shortcut
  String? getActionByShortcut(String shortcut) {
    final shortcuts = getKeyboardShortcuts();
    return shortcuts[shortcut];
  }

  // Get quick replies by category
  List<QuickReply> getQuickRepliesByCategory(String category) {
    final replies = getQuickReplies();
    return replies.where((r) => r.category == category).toList();
  }

  // Get most used quick replies
  List<QuickReply> getMostUsedReplies({int limit = 5}) {
    final replies = getQuickReplies();
    replies.sort((a, b) => b.useCount.compareTo(a.useCount));
    return replies.take(limit).toList();
  }

  // Search quick replies
  List<QuickReply> searchQuickReplies(String query) {
    if (query.isEmpty) return [];

    final replies = getQuickReplies();
    return replies
        .where(
          (reply) =>
              reply.text.toLowerCase().contains(query.toLowerCase()) ||
              reply.category.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    await saveQuickActions(defaultQuickActions);
    await saveQuickReplies(defaultQuickReplies);
    await _prefs.remove(_swipeGesturesKey);
    await _prefs.remove(_keyboardShortcutsKey);
  }
}
