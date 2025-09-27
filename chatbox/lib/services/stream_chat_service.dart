import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/app_constants.dart';

class StreamChatService with ChangeNotifier {
  static final StreamChatService _instance = StreamChatService._internal();
  late StreamChatClient _client;
  bool _isConnected = false;

  factory StreamChatService() {
    return _instance;
  }

  StreamChatService._internal() {
    _client = StreamChatClient(AppConstants.streamApiKey, logLevel: Level.INFO);
  }

  StreamChatClient get client => _client;

  // Check if user is connected
  bool get isConnected => _isConnected;

  // Get current user
  User? get currentUser => _client.state.currentUser;

  Future<void> connectUser(
    String userId,
    String userToken, {
    String? name,
    String? image,
  }) async {
    final user = User(id: userId, name: name, image: image);

    try {
      // Always disconnect first to ensure clean state
      if (_client.state.currentUser != null) {
        print('🔄 Disconnecting existing user before connecting...');
        await _client.disconnectUser();
        _isConnected = false;
        notifyListeners();
      }

      await _client.connectUser(user, userToken);
      _isConnected = true;
      print('StreamChatService: Notifying listeners of connection change');
      notifyListeners();
      print('✅ Successfully connected to GetStream');
    } catch (e) {
      _isConnected = false;
      notifyListeners();
      print('❌ Failed to connect to GetStream: $e');

      // Handle specific Stream Chat errors
      if (e.toString().contains('already exist') ||
          e.toString().contains('already getting connected')) {
        print('🔄 Attempting to force disconnect and retry...');
        try {
          await _client.disconnectUser();
          _isConnected = false;
          notifyListeners();
          // Wait a moment before retrying
          await Future.delayed(const Duration(milliseconds: 500));
          await _client.connectUser(user, userToken);
          _isConnected = true;
          notifyListeners();
          print('✅ Successfully connected after retry');
          return;
        } catch (retryError) {
          _isConnected = false;
          notifyListeners();
          print('❌ Retry also failed: $retryError');
        }
      }

      rethrow;
    }
  }

  Future<void> disconnectUser() async {
    await _client.disconnectUser();
    _isConnected = false;
    notifyListeners();
  }

  // Add a method to check connection before querying
  Future<void> ensureConnected() async {
    if (!_isConnected) {
      throw Exception('User not connected to GetStream');
    }
  }

  Future<Channel> createChannel(
    String channelId,
    String channelType,
    List<String> memberIds, {
    String? name,
    String? image,
  }) async {
    await ensureConnected();
    return _client.channel(
      channelType,
      id: channelId,
      extraData: {'name': name, 'image': image, 'members': memberIds},
    );
  }
}
