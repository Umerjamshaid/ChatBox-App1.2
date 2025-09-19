// lib/providers/channel_provider.dart
import 'package:flutter/foundation.dart';
import 'package:chatbox/services/chat_service.dart';

class ChannelProvider with ChangeNotifier {
  final ChatService _chatService;

  List<Map<String, dynamic>> _channels = [];
  bool _isLoading = false;
  String? _error;
  String? _selectedChannelId;

  ChannelProvider(this._chatService) {
    _initialize();
  }

  // Getters
  List<Map<String, dynamic>> get channels => _channels;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedChannelId => _selectedChannelId;
  Map<String, dynamic>? get selectedChannel {
    if (_selectedChannelId == null) return null;
    return _channels.firstWhere(
      (channel) => channel['id'] == _selectedChannelId,
      orElse: () => {},
    );
  }

  void _initialize() {
    // Listen to channel updates from ChatService
    _chatService.channelsStream.listen((channels) {
      _channels = channels;
      _error = null;
      notifyListeners();
    });
  }

  /// Load channels
  Future<void> loadChannels({bool forceRefresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _chatService.loadChannels(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a channel
  void selectChannel(String channelId) {
    _selectedChannelId = channelId;
    notifyListeners();
  }

  /// Create a new channel
  Future<Map<String, dynamic>?> createChannel({
    required String name,
    required List<String> memberIds,
    String? image,
  }) async {
    try {
      final channel = await _chatService.createChannel(
        name: name,
        memberIds: memberIds,
        image: image,
      );

      // Auto-select the newly created channel
      _selectedChannelId = channel['id'];
      notifyListeners();

      return channel;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Mark channel as read
  Future<void> markChannelAsRead(String channelId) async {
    try {
      await _chatService.markChannelAsRead(channelId);

      // Update local channel state
      final index = _channels.indexWhere((c) => c['id'] == channelId);
      if (index != -1) {
        _channels[index]['unreadCount'] = 0;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get channel by ID
  Map<String, dynamic>? getChannelById(String channelId) {
    return _channels.firstWhere(
      (channel) => channel['id'] == channelId,
      orElse: () => {},
    );
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh channels
  Future<void> refresh() async {
    await loadChannels(forceRefresh: true);
  }
}
