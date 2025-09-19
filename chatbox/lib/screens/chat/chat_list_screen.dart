// lib/screens/chat/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/screens/chat/chat_screen.dart';
import 'package:chatbox/screens/groups/create_group_screen.dart';
import 'package:chatbox/screens/groups/group_info_screen.dart';
import 'package:chatbox/services/group_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateOptions,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search Bar
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: AppStyles.textFieldDecoration.copyWith(
                  hintText: 'Search chats...',
                  prefixIcon: Icon(Icons.search, color: AppColors.grey600),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.clear, color: AppColors.grey600),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                    },
                  ),
                ),
                onChanged: (value) {
                  // TODO: Implement search filtering
                },
              ),
            ),

          // Chat List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshChats,
              child: StreamChannelListView(
                controller: StreamChannelListController(
                  client: StreamChat.of(context).client,
                ),
                itemBuilder: (context, channels, index, defaultWidget) {
                  return _buildChannelPreview(channels[index]);
                },
                emptyBuilder: (context) {
                  return _buildEmptyState();
                },
                errorBuilder: (context, error) {
                  return _buildErrorState(error);
                },
                loadingBuilder: (context) {
                  return _buildLoadingState();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelPreview(Channel channel) {
    return StreamBuilder<Message?>(
      stream: channel.state?.lastMessageStream,
      builder: (context, snapshot) {
        final lastMessage = snapshot.data;
        final unreadCount = channel.state?.unreadCount ?? 0;

        // Handle offline state
        final isOnline = channel.state?.isUpToDate ?? true;

        // Check if this is a group chat
        final isGroup = channel.type == 'team';
        final memberCount = channel.state?.members?.length ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: unreadCount > 0
                ? AppColors.primary.withOpacity(0.05)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unreadCount > 0
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.grey300,
              width: 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.grey200,
                  backgroundImage: channel.image != null
                      ? NetworkImage(channel.image!)
                      : null,
                  child: channel.image == null
                      ? Icon(
                          isGroup ? Icons.group : Icons.person,
                          color: AppColors.grey600,
                          size: 24,
                        )
                      : null,
                ),
                if (unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                if (isGroup)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(Icons.group, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    channel.name ?? 'Unknown Chat',
                    style: TextStyle(
                      fontWeight: unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isOnline)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: AppColors.grey500,
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isGroup)
                  Text(
                    '$memberCount members',
                    style: TextStyle(color: AppColors.grey600, fontSize: 12),
                  ),
                if (lastMessage != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatMessagePreview(lastMessage),
                          style: TextStyle(
                            color: AppColors.grey600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(lastMessage.createdAt),
                        style: TextStyle(
                          color: AppColors.grey500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'No messages yet',
                    style: TextStyle(
                      color: AppColors.grey500,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatScreen(channel: channel),
                ),
              );
            },
            onLongPress: () => _showChannelOptions(channel),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a new chat to begin messaging',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: AppColors.danger),
          const SizedBox(height: 16),
          Text(
            'Failed to load chats',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.danger,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshChats,
            style: AppStyles.primaryButton,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading chats...',
            style: TextStyle(fontSize: 16, color: AppColors.grey600),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshChats() async {
    // TODO: Implement pull-to-refresh
    await Future.delayed(const Duration(seconds: 1));
  }

  String _formatMessagePreview(Message message) {
    if (message.text?.isNotEmpty == true) {
      return message.text!;
    }

    if (message.attachments?.isNotEmpty == true) {
      final attachment = message.attachments!.first;
      switch (attachment.type) {
        case 'image':
          return '📷 Photo';
        case 'video':
          return '🎥 Video';
        case 'file':
          return '📎 File';
        default:
          return '📎 Attachment';
      }
    }

    return 'Message';
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
      }
    });
  }

  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Start a new conversation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.group_add, color: AppColors.primary),
              ),
              title: const Text('Create Group'),
              subtitle: const Text('Start a group conversation'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person_add, color: AppColors.secondary),
              ),
              title: const Text('New Chat'),
              subtitle: const Text('Start a private conversation'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to contact selection for private chat
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Private chat coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelOptions(Channel channel) {
    final isGroup = channel.type == 'team';
    final groupService = GroupService();
    final currentUserId = StreamChat.of(context).client.state.currentUser?.id;
    final isAdmin =
        currentUserId != null &&
        groupService.isUserAdmin(channel, currentUserId);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Info'),
              onTap: () {
                Navigator.pop(context);
                if (isGroup) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupInfoScreen(channel: channel),
                    ),
                  );
                } else {
                  // TODO: Show private chat info
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Private chat info coming soon!'),
                    ),
                  );
                }
              },
            ),
            if (isGroup && !isAdmin)
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                title: const Text('Leave Group'),
                onTap: () {
                  Navigator.pop(context);
                  _leaveGroup(channel);
                },
              ),
            if (isGroup && isAdmin)
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.danger),
                title: const Text('Delete Group'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteGroup(channel);
                },
              ),
            ListTile(
              leading: const Icon(Icons.notifications_off),
              title: const Text('Mute Notifications'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement mute functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mute functionality coming soon!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _leaveGroup(Channel channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final groupService = GroupService();
        await groupService.leaveGroup(channel);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('You left the group')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
      }
    }
  }

  Future<void> _deleteGroup(Channel channel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text(
          'Are you sure you want to delete this group? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final groupService = GroupService();
        await groupService.deleteGroup(channel);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group deleted')));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete group: $e')));
      }
    }
  }
}
