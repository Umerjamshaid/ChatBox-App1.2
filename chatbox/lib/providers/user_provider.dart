// lib/providers/user_provider.dart
import 'package:flutter/foundation.dart';
import 'package:chatbox/services/chat_service.dart';
import 'package:chatbox/models/presence_models.dart';

class UserProvider with ChangeNotifier {
  final ChatService _chatService;

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String? _currentUserId;
  UserPresence _currentPresence = const UserPresence(
    userId: '',
    status: PresenceStatus.online,
    isOnline: true,
  );

  UserProvider(this._chatService) {
    _initialize();
  }

  // Getters
  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get currentUserId => _currentUserId;
  UserPresence get currentPresence => _currentPresence;

  Map<String, dynamic>? get currentUser {
    if (_currentUserId == null) return null;
    return _users.firstWhere(
      (user) => user['id'] == _currentUserId,
      orElse: () => {},
    );
  }

  void _initialize() {
    // Listen to user updates from ChatService
    _chatService.usersStream.listen((users) {
      _users = users;
      _error = null;
      notifyListeners();
    });
  }

  /// Load users
  Future<void> loadUsers({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _chatService.loadUsers(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    if (_isSearching || query.isEmpty) return;

    _isSearching = true;
    _error = null;
    notifyListeners();

    try {
      _searchResults = await _chatService.searchUsers(query);
    } catch (e) {
      _error = e.toString();
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  /// Update current user presence
  Future<void> updatePresence(UserPresence presence) async {
    try {
      await _chatService.updatePresence(presence);
      _currentPresence = presence;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Set current user
  void setCurrentUser(String userId) {
    _currentUserId = userId;
    notifyListeners();
  }

  /// Get user by ID
  Map<String, dynamic>? getUserById(String userId) {
    return _users.firstWhere((user) => user['id'] == userId, orElse: () => {});
  }

  /// Get online users
  List<Map<String, dynamic>> getOnlineUsers() {
    return _users.where((user) => user['status'] == 'online').toList();
  }

  /// Get users by status
  List<Map<String, dynamic>> getUsersByStatus(String status) {
    return _users.where((user) => user['status'] == status).toList();
  }

  /// Get recently active users
  List<Map<String, dynamic>> getRecentlyActiveUsers() {
    final now = DateTime.now();
    return _users.where((user) {
      if (user['lastActive'] == null) return false;
      final lastActive = DateTime.parse(user['lastActive']);
      return now.difference(lastActive).inHours < 24;
    }).toList();
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    final user = getUserById(userId);
    return user?['status'] == 'online';
  }

  /// Get user presence status
  String getUserStatus(String userId) {
    final user = getUserById(userId);
    return user?['status'] ?? 'offline';
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh users
  Future<void> refresh() async {
    await loadUsers(forceRefresh: true);
  }
}
