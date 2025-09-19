import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/app_constants.dart';

class StreamChatService {
  static final StreamChatService _instance = StreamChatService._internal();
  late StreamChatClient _client;

  factory StreamChatService() {
    return _instance;
  }

  StreamChatService._internal() {
    _client = StreamChatClient(AppConstants.streamApiKey, logLevel: Level.INFO);
  }

  StreamChatClient get client => _client;

  // Check if user is connected
  bool get isConnected => _client.state.currentUser != null;

  // Get current user
  User? get currentUser => _client.state.currentUser;

  Future<void> connectUser(
    String userId,
    String userToken, {
    String? name,
  }) async {
    final user = User(id: userId, name: name);
    await _client.connectUser(user, userToken);
  }

  Future<void> disconnectUser() async {
    await _client.disconnectUser();
  }

  Future<Channel> createChannel(
    String channelId,
    String channelType,
    List<String> memberIds, {
    String? name,
    String? image,
  }) async {
    return _client.channel(
      channelType,
      id: channelId,
      extraData: {'name': name, 'image': image, 'members': memberIds},
    );
  }
}
