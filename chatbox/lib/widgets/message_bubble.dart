// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMyMessage;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onReact;
  final bool showStatus;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReact,
    this.showStatus = true,
    this.showTimestamp = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMyMessage
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMyMessage) _buildAvatar(),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage && showTimestamp) _buildSenderInfo(),
                _buildMessageContent(),
                if (showStatus) _buildMessageStatus(),
              ],
            ),
          ),
          if (isMyMessage) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.grey200,
      backgroundImage: message.user?.image != null
          ? NetworkImage(message.user!.image!)
          : null,
      child: message.user?.image == null
          ? Text(
              message.user?.name?.substring(0, 1).toUpperCase() ?? '?',
              style: TextStyle(
                color: AppColors.grey600,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            )
          : null,
    );
  }

  Widget _buildSenderInfo() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        message.user?.name ?? 'Unknown',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.grey600,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMessageContent() {
    return GestureDetector(
      onLongPress: _showMessageOptions,
      child: Container(
        constraints: BoxConstraints(maxWidth: 280, minWidth: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMyMessage ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMyMessage ? 18 : 4),
            bottomRight: Radius.circular(isMyMessage ? 4 : 18),
          ),
          border: Border.all(
            color: AppColors.grey300.withOpacity(0.5),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reply preview
            if (message.parentId != null) _buildReplyPreview(),

            // Message text
            if (message.text?.isNotEmpty == true)
              Text(
                message.text!,
                style: TextStyle(
                  color: isMyMessage ? Colors.white : AppColors.onSurface,
                  fontSize: 16,
                ),
              ),

            // Attachments
            if (message.attachments?.isNotEmpty == true) _buildAttachments(),

            // Reactions
            if (message.reactionGroups?.isNotEmpty == true) _buildReactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.grey100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            color: AppColors.primary,
            margin: const EdgeInsets.only(right: 8),
          ),
          Expanded(
            child: Text(
              'Replied to message', // TODO: Get actual parent message text
              style: TextStyle(
                fontSize: 12,
                color: AppColors.grey600,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachments() {
    return Column(
      children: message.attachments!.map((attachment) {
        switch (attachment.type) {
          case 'image':
            return Container(
              margin: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => _openMediaViewer(
                  attachment.assetUrl ?? attachment.imageUrl ?? '',
                  'image',
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    attachment.assetUrl ?? attachment.imageUrl ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 100,
                        width: 100,
                        color: AppColors.grey200,
                        child: Icon(
                          Icons.broken_image,
                          color: AppColors.grey600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          case 'video':
            return Container(
              margin: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () =>
                    _openMediaViewer(attachment.assetUrl ?? '', 'video'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Video thumbnail (placeholder for now)
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: AppColors.grey200,
                        child: Icon(
                          Icons.video_file,
                          size: 48,
                          color: AppColors.grey600,
                        ),
                      ),
                      // Play button overlay
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          case 'file':
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
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
                      attachment.title ?? 'File',
                      style: TextStyle(color: AppColors.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.download, color: AppColors.primary),
                    onPressed: () => _downloadFile(attachment),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          case 'location':
            return Container(
              margin: const EdgeInsets.only(top: 8),
              child: GestureDetector(
                onTap: () => _openLocation(attachment),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Shared Location',
                          style: TextStyle(color: AppColors.onSurface),
                        ),
                      ),
                      Icon(Icons.map, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      }).toList(),
    );
  }

  Widget _buildReactions() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: message.reactionGroups!.entries.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Text(
              '${entry.key} ${entry.value.count}',
              style: TextStyle(fontSize: 12, color: AppColors.onSurface),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageStatus() {
    if (!isMyMessage) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showTimestamp)
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(fontSize: 10, color: AppColors.grey500),
            ),
          const SizedBox(width: 4),
          // Simple sent indicator for now
          Icon(Icons.check, size: 12, color: AppColors.grey500),
        ],
      ),
    );
  }

  void _showMessageOptions() {
    showModalBottomSheet(
      context: _getContext(),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: Icon(Icons.reply, color: AppColors.primary),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            if (isMyMessage && onEdit != null)
              ListTile(
                leading: Icon(Icons.edit, color: AppColors.primary),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit!();
                },
              ),
            if (onReact != null)
              ListTile(
                leading: Icon(Icons.emoji_emotions, color: AppColors.primary),
                title: const Text('Add Reaction'),
                onTap: () {
                  Navigator.pop(context);
                  onReact!();
                },
              ),
            if (isMyMessage && onDelete != null)
              ListTile(
                leading: Icon(Icons.delete, color: AppColors.danger),
                title: const Text('Delete'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(dateTime);
    } else {
      return DateFormat('dd/MM').format(dateTime);
    }
  }

  void _openMediaViewer(String mediaUrl, String mediaType) {
    // TODO: Navigate to media viewer screen
    // This would require access to BuildContext, which we don't have here
    // In a real implementation, you'd pass a callback from the parent widget
    print('Opening media viewer: $mediaUrl ($mediaType)');
  }

  void _downloadFile(Attachment attachment) {
    // TODO: Implement file download
    print('Downloading file: ${attachment.title}');
  }

  void _openLocation(Attachment attachment) {
    // TODO: Open location in maps
    print('Opening location: ${attachment.title}');
  }

  BuildContext _getContext() {
    // This is a workaround since we don't have direct access to context
    // In a real implementation, you'd pass the context as a parameter
    return null as BuildContext; // This will need to be fixed
  }
}
