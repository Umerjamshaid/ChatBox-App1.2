import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/app_constants.dart';

class StreamChatService {
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
    try {
      final user = User(id: userId, name: name, image: image);
      await _client.connectUser(user, userToken);
      _isConnected = true;
      print('✅ Successfully connected to GetStream');
    } catch (e) {
      _isConnected = false;
      print('❌ Failed to connect to GetStream: $e');
      rethrow;
    }
  }

  Future<void> disconnectUser() async {
    await _client.disconnectUser();
    _isConnected = false;
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
