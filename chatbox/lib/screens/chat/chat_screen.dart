// lib/screens/chat/chat_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/services/storage_service.dart';
import 'package:chatbox/services/media_service.dart';
import 'package:chatbox/widgets/message_bubble.dart';
import 'package:chatbox/widgets/voice_recorder.dart';
import 'package:chatbox/widgets/emoji_picker.dart';
import 'package:chatbox/widgets/enhanced_voice_recorder.dart';
import 'package:chatbox/screens/media/image_preview_screen.dart';
import 'package:chatbox/screens/media/location_sharing_screen.dart';
import 'package:chatbox/screens/media/media_gallery_screen.dart';
import 'package:chatbox/screens/groups/group_info_screen.dart';
import 'package:chatbox/screens/calls/voice_call_screen.dart';
import 'package:chatbox/screens/calls/video_call_screen.dart';
import 'package:chatbox/services/group_service.dart';
import 'package:file_picker/file_picker.dart';

class ChatScreen extends StatefulWidget {
  final Channel channel;

  const ChatScreen({super.key, required this.channel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  bool _isRecording = false;
  bool _showEmojiPicker = false;
  bool _showMentions = false;
  Message? _replyingTo;
  Message? _editingMessage;
  XFile? _selectedAttachment;
  List<Member> _groupMembers = [];
  bool _isGroup = false;
  bool _isBroadcastMode = false;

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();

    // Initialize group-specific features
    _initializeGroupFeatures();
  }

  Future<void> _initializeGroupFeatures() async {
    _isGroup = widget.channel.type == 'team';
    if (_isGroup) {
      await widget.channel.watch();
      _groupMembers = widget.channel.state?.members ?? [];
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamChannel(
      channel: widget.channel,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildCustomAppBar(),
        body: SafeArea(
          child: Column(
            children: [
              // Messages List with Custom Design
              Expanded(
                child: Stack(
                  children: [
                    StreamMessageListView(
                      messageBuilder: _buildCustomMessage,
                      showScrollToBottom: true,
                      scrollPhysics: const BouncingScrollPhysics(),
                      loadingBuilder: (context) => _buildLoadingIndicator(),
                      emptyBuilder: (context) => _buildEmptyState(),
                      errorBuilder: (context, error) => _buildErrorState(error),
                    ),

                    // Reply Preview
                    if (_replyingTo != null) _buildReplyPreview(),

                    // Voice Recording Overlay
                    if (_isRecording) _buildVoiceRecordingOverlay(),
                  ],
                ),
              ),

              // Custom Message Input
              _buildCustomMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildCustomAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          // Profile Avatar with Online Status
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.grey200,
                backgroundImage: widget.channel.image != null
                    ? NetworkImage(widget.channel.image!)
                    : null,
                child: widget.channel.image == null
                    ? Text(
                        widget.channel.name?.substring(0, 1).toUpperCase() ??
                            '#',
                        style: TextStyle(
                          color: AppColors.grey600,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.channel.name ?? 'Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                StreamBuilder<List<Member>>(
                  stream: widget.channel.state?.membersStream,
                  builder: (context, snapshot) {
                    final members = snapshot.data ?? [];
                    final onlineMembers = members
                        .where((member) => member.user?.online == true)
                        .length;

                    return Text(
                      onlineMembers > 0 ? '$onlineMembers online' : 'Offline',
                      style: TextStyle(fontSize: 12, color: AppColors.grey600),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Broadcast button for group admins
        if (_isGroup)
          IconButton(
            icon: Icon(
              Icons.campaign,
              color: _isBroadcastMode ? AppColors.primary : AppColors.onSurface,
            ),
            onPressed: _sendBroadcastMessage,
            tooltip: 'Send broadcast message',
          ),

        IconButton(
          icon: Icon(Icons.call, color: AppColors.onSurface),
          onPressed: () => _startVoiceCall(),
        ),
        IconButton(
          icon: Icon(Icons.videocam, color: AppColors.onSurface),
          onPressed: () => _startVideoCall(),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.onSurface),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            if (_isGroup)
              const PopupMenuItem(
                value: 'group_info',
                child: Text('Group Info'),
              ),
            const PopupMenuItem(
              value: 'view_profile',
              child: Text('View Profile'),
            ),
            const PopupMenuItem(value: 'media', child: Text('Shared Media')),
            const PopupMenuItem(
              value: 'search',
              child: Text('Search Messages'),
            ),
            const PopupMenuItem(
              value: 'mute',
              child: Text('Mute Notifications'),
            ),
            if (!_isGroup)
              const PopupMenuItem(value: 'report', child: Text('Report')),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomMessage(
    BuildContext context,
    MessageDetails details,
    List<Message> messages,
    StreamMessageWidget defaultWidget,
  ) {
    final message = details.message;
    final isMyMessage = _isMessageFromCurrentUser(message);

    return MessageBubble(
      message: message,
      isMyMessage: isMyMessage,
      onReply: () => _setReplyTo(message),
      onEdit: () => _setEditMessage(message),
      onDelete: () => _deleteMessage(message),
      onReact: () => _showReactionPicker(message),
      showStatus: true,
      showTimestamp: true,
    );
  }

  Widget _buildReplyPreview() {
    if (_replyingTo == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.grey300, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            color: AppColors.primary,
            margin: const EdgeInsets.only(right: 8),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyingTo!.user?.name ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _replyingTo!.text ?? 'Attachment',
                  style: TextStyle(fontSize: 14, color: AppColors.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.grey600),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecordingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(child: VoiceRecorder()),
    );
  }

  Widget _buildCustomMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.grey300, width: 1)),
      ),
      child: Column(
        children: [
          // Attachment Preview
          if (_selectedAttachment != null) _buildAttachmentPreview(),

          Row(
            children: [
              // Attachment Button
              IconButton(
                icon: Icon(Icons.attach_file, color: AppColors.grey600),
                onPressed: _showAttachmentOptions,
              ),

              // Voice Recording Button
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.red : AppColors.grey600,
                ),
                onPressed: _toggleVoiceRecording,
              ),

              // Emoji Button
              IconButton(
                icon: Icon(
                  Icons.emoji_emotions,
                  color: _showEmojiPicker
                      ? AppColors.primary
                      : AppColors.grey600,
                ),
                onPressed: () =>
                    setState(() => _showEmojiPicker = !_showEmojiPicker),
              ),

              // Message Input Field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    maxLines: null,
                    decoration: AppStyles.textFieldDecoration.copyWith(
                      hintText: _editingMessage != null
                          ? 'Edit message...'
                          : _isBroadcastMode
                          ? '📢 Broadcast to all members...'
                          : 'Type a message...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      // Auto-resize based on content
                      setState(() {});

                      // Handle @ mentions for groups
                      if (_isGroup && value.endsWith('@')) {
                        _showMentionsList();
                      } else if (_showMentions && !value.contains('@')) {
                        setState(() => _showMentions = false);
                      }
                    },
                  ),
                ),
              ),

              // @ Mention Button (for groups)
              if (_isGroup)
                IconButton(
                  icon: Icon(
                    Icons.alternate_email,
                    color: _showMentions
                        ? AppColors.primary
                        : AppColors.grey600,
                  ),
                  onPressed: _showMentionsList,
                ),

              // Send Button
              AnimatedBuilder(
                animation: _fabAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _fabAnimation.value,
                    child: IconButton(
                      icon: Icon(
                        _editingMessage != null ? Icons.check : Icons.send,
                        color: AppColors.primary,
                      ),
                      onPressed: _sendMessage,
                    ),
                  );
                },
              ),
            ],
          ),

          // Emoji Picker
          if (_showEmojiPicker) _buildEmojiPicker(),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview() {
    if (_selectedAttachment == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.attach_file, color: AppColors.grey600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedAttachment!.name,
              style: TextStyle(color: AppColors.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.grey600),
            onPressed: () => setState(() => _selectedAttachment = null),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250,
      child: EmojiPicker(
        onEmojiSelected: (emoji) {
          _messageController.text += emoji;
          setState(() {});
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
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
            'Failed to load messages',
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
            onPressed: () {
              // Retry loading messages
              setState(() {});
            },
            style: AppStyles.primaryButton,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'group_info':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupInfoScreen(channel: widget.channel),
          ),
        );
        break;
      case 'view_profile':
        // TODO: Navigate to profile screen
        break;
      case 'media':
        _openMediaGallery();
        break;
      case 'search':
        // TODO: Show search interface
        break;
      case 'mute':
        // TODO: Toggle mute notifications
        break;
      case 'report':
        // TODO: Show report dialog
        break;
    }
  }

  void _openMediaGallery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaGalleryScreen(channel: widget.channel),
      ),
    );
  }

  void _setReplyTo(Message message) {
    setState(() {
      _replyingTo = message;
      _editingMessage = null;
    });
    _messageFocusNode.requestFocus();
  }

  void _setEditMessage(Message message) {
    setState(() {
      _editingMessage = message;
      _replyingTo = null;
      _messageController.text = message.text ?? '';
    });
    _messageFocusNode.requestFocus();
  }

  Future<void> _deleteMessage(Message message) async {
    try {
      await widget.channel.deleteMessage(message);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
    }
  }

  void _showReactionPicker(Message message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Reaction', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['👍', '❤️', '😂', '😮', '😢', '😡'].map((emoji) {
                return GestureDetector(
                  onTap: () async {
                    try {
                      await widget.channel.sendReaction(message, emoji);
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add reaction: $e')),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.grey300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.grey600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Options grid
            Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _AttachmentOption(
                    icon: Icons.image,
                    label: 'Gallery',
                    color: AppColors.primary,
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await MediaService().pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        _previewImage(image);
                      }
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: AppColors.success,
                    onTap: () async {
                      Navigator.pop(context);
                      final image = await MediaService().pickImage(
                        source: ImageSource.camera,
                      );
                      if (image != null) {
                        _previewImage(image);
                      }
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: AppColors.warning,
                    onTap: () async {
                      Navigator.pop(context);
                      final video = await MediaService().pickVideo();
                      if (video != null) {
                        _previewVideo(video);
                      }
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.attach_file,
                    label: 'Document',
                    color: AppColors.info,
                    onTap: () async {
                      Navigator.pop(context);
                      final result = await MediaService().pickFiles(
                        allowedExtensions: [
                          'pdf',
                          'doc',
                          'docx',
                          'txt',
                          'xls',
                          'xlsx',
                        ],
                      );
                      if (result != null && result.files.isNotEmpty) {
                        _handleFileAttachment(result.files.first);
                      }
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.location_on,
                    label: 'Location',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _shareLocation();
                    },
                  ),
                  _AttachmentOption(
                    icon: Icons.mic,
                    label: 'Voice',
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      _showVoiceRecorder();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVoiceRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // Start recording
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice recording started...')),
      );
    } else {
      // Stop recording and send
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Voice message sent!')));
    }
  }

  void _previewImage(XFile image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageFile: image,
          onSend: (XFile image) {
            setState(() => _selectedAttachment = image);
          },
        ),
      ),
    );
  }

  void _previewVideo(XFile video) {
    // TODO: Implement video preview
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Video preview coming soon!')));
  }

  void _handleFileAttachment(PlatformFile file) {
    // TODO: Handle file attachment
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('File attached: ${file.name}')));
  }

  void _shareLocation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSharingScreen(
          onLocationSelected: (locationData) {
            // TODO: Send location message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location shared: ${locationData.address}'),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showVoiceRecorder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        child: const EnhancedVoiceRecorder(
          onRecordingComplete: null, // TODO: Handle recording completion
          onCancel: null,
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedAttachment == null) return;

    try {
      if (_editingMessage != null) {
        // Edit existing message
        final updatedMessage = _editingMessage!.copyWith(text: text);
        await widget.channel.updateMessage(updatedMessage);
        setState(() {
          _editingMessage = null;
          _messageController.clear();
        });
      } else {
        // Send new message (handle broadcast for groups)
        final messageText = _isBroadcastMode && _isGroup ? '📢 $text' : text;

        final message = Message(
          text: messageText,
          attachments: _selectedAttachment != null
              ? [
                  Attachment(
                    type: 'image',
                    assetUrl: _selectedAttachment!.path,
                    title: _selectedAttachment!.name,
                  ),
                ]
              : [],
          parentId: _replyingTo?.id,
        );

        await widget.channel.sendMessage(message);

        setState(() {
          _messageController.clear();
          _replyingTo = null;
          _selectedAttachment = null;
          _isBroadcastMode = false; // Reset broadcast mode
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  void _showMentionsList() {
    if (!_isGroup || _groupMembers.isEmpty) return;

    setState(() => _showMentions = true);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Mention a member',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _groupMembers.length,
                itemBuilder: (context, index) {
                  final member = _groupMembers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: member.user?.image != null
                          ? NetworkImage(member.user!.image!)
                          : null,
                      child: member.user?.image == null
                          ? Text(
                              member.user?.name.substring(0, 1).toUpperCase() ??
                                  '?',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : null,
                    ),
                    title: Text(member.user?.name ?? 'Unknown User'),
                    onTap: () {
                      final mention = '@${member.user?.name ?? 'Unknown'} ';
                      _messageController.text += mention;
                      setState(() => _showMentions = false);
                      Navigator.pop(context);
                      _messageFocusNode.requestFocus();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => setState(() => _showMentions = false));
  }

  Future<void> _sendBroadcastMessage() async {
    if (!_isGroup) return;

    final groupService = GroupService();
    final currentUserId = _getCurrentUserId();

    if (currentUserId == null) return;

    final isAdmin = groupService.isUserAdmin(widget.channel, currentUserId);
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only admins can send broadcast messages'),
        ),
      );
      return;
    }

    setState(() => _isBroadcastMode = !_isBroadcastMode);

    if (_isBroadcastMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Broadcast mode enabled. Your message will be sent to all members.',
          ),
        ),
      );
    }
  }

  bool _isMessageFromCurrentUser(Message message) {
    try {
      final currentUser = StreamChat.of(context).currentUser;
      return message.user?.id == currentUser?.id;
    } catch (e) {
      // If StreamChat context is not available, assume it's not from current user
      return false;
    }
  }

  String? _getCurrentUserId() {
    try {
      return StreamChat.of(context).currentUser?.id;
    } catch (e) {
      return null;
    }
  }

  void _sendGroupEventMessage(String eventType, String userName) {
    if (!_isGroup) return;

    final eventMessages = {
      'join': '👋 $userName joined the group',
      'leave': '👋 $userName left the group',
      'admin': '⭐ $userName was made an admin',
      'moderator': '⭐ $userName was made a moderator',
    };

    final messageText = eventMessages[eventType] ?? '$userName $eventType';

    final message = Message(
      text: messageText,
      type: 'system',
      extraData: {'event_type': eventType, 'user_name': userName},
    );

    widget.channel.sendMessage(message);
  }

  void _startVoiceCall() {
    // Get participant IDs from the channel
    final participantIds =
        widget.channel.state?.members
            .where((member) => member.user?.id != _getCurrentUserId())
            .map((member) => member.user?.id ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    if (participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No participants available for call')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceCallScreen(participantIds: participantIds),
      ),
    );
  }

  void _startVideoCall() {
    // Get participant IDs from the channel
    final participantIds =
        widget.channel.state?.members
            .where((member) => member.user?.id != _getCurrentUserId())
            .map((member) => member.user?.id ?? '')
            .where((id) => id.isNotEmpty)
            .toList() ??
        [];

    if (participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No participants available for call')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoCallScreen(participantIds: participantIds),
      ),
    );
  }
}

class _AttachmentOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachmentOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
