// lib/constants/channel_types.dart

/// Channel types supported by ChatBox
class ChannelTypes {
  // Core messaging types
  static const String messaging = 'messaging';
  static const String team = 'team';
  static const String gaming = 'gaming';
  static const String commerce = 'commerce';

  // Get all available channel types
  static List<String> get all => [messaging, team, gaming, commerce];

  // Get display name for channel type
  static String getDisplayName(String type) {
    switch (type) {
      case messaging:
        return 'Direct Message';
      case team:
        return 'Team Chat';
      case gaming:
        return 'Gaming';
      case commerce:
        return 'Commerce';
      default:
        return 'Chat';
    }
  }

  // Get icon for channel type
  static String getIcon(String type) {
    switch (type) {
      case messaging:
        return '💬';
      case team:
        return '👥';
      case gaming:
        return '🎮';
      case commerce:
        return '🛒';
      default:
        return '💬';
    }
  }

  // Get description for channel type
  static String getDescription(String type) {
    switch (type) {
      case messaging:
        return 'Private conversations between users';
      case team:
        return 'Collaborative workspace for teams';
      case gaming:
        return 'Gaming communities and matches';
      case commerce:
        return 'Business and marketplace discussions';
      default:
        return 'General chat channel';
    }
  }
}

/// Channel configuration for different types
class ChannelConfig {
  final String type;
  final bool isPublic;
  final int maxMembers;
  final List<String> allowedRoles;
  final Map<String, dynamic> defaultSettings;

  const ChannelConfig({
    required this.type,
    required this.isPublic,
    required this.maxMembers,
    required this.allowedRoles,
    required this.defaultSettings,
  });

  static ChannelConfig getConfig(String type) {
    switch (type) {
      case ChannelTypes.messaging:
        return const ChannelConfig(
          type: ChannelTypes.messaging,
          isPublic: false,
          maxMembers: 2,
          allowedRoles: ['user'],
          defaultSettings: {
            'typing_events': true,
            'read_events': true,
            'connect_events': true,
            'search': true,
            'reactions': true,
            'replies': true,
            'mutes': true,
          },
        );

      case ChannelTypes.team:
        return const ChannelConfig(
          type: ChannelTypes.team,
          isPublic: false,
          maxMembers: 100,
          allowedRoles: ['owner', 'admin', 'member'],
          defaultSettings: {
            'typing_events': true,
            'read_events': true,
            'connect_events': true,
            'search': true,
            'reactions': true,
            'replies': true,
            'mutes': true,
            'push_notifications': true,
            'message_retention_days': 365,
          },
        );

      case ChannelTypes.gaming:
        return const ChannelConfig(
          type: ChannelTypes.gaming,
          isPublic: true,
          maxMembers: 50,
          allowedRoles: ['owner', 'moderator', 'member'],
          defaultSettings: {
            'typing_events': true,
            'read_events': true,
            'connect_events': true,
            'search': true,
            'reactions': true,
            'replies': true,
            'mutes': true,
            'slow_mode': true,
            'custom_emojis': true,
          },
        );

      case ChannelTypes.commerce:
        return const ChannelConfig(
          type: ChannelTypes.commerce,
          isPublic: true,
          maxMembers: 200,
          allowedRoles: ['owner', 'admin', 'seller', 'buyer'],
          defaultSettings: {
            'typing_events': false,
            'read_events': true,
            'connect_events': true,
            'search': true,
            'reactions': true,
            'replies': true,
            'mutes': true,
            'message_retention_days': 90,
            'file_upload': true,
            'image_upload': true,
          },
        );

      default:
        return const ChannelConfig(
          type: ChannelTypes.messaging,
          isPublic: false,
          maxMembers: 2,
          allowedRoles: ['user'],
          defaultSettings: {
            'typing_events': true,
            'read_events': true,
            'connect_events': true,
            'search': true,
            'reactions': true,
            'replies': true,
            'mutes': true,
          },
        );
    }
  }
}
