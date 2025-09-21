// lib/screens/media/media_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/screens/media/media_viewer_screen.dart';

class MediaGalleryScreen extends StatefulWidget {
  final Channel channel;

  const MediaGalleryScreen({super.key, required this.channel});

  @override
  State<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends State<MediaGalleryScreen> {
  List<Message> _mediaMessages = [];
  bool _isLoading = true;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    _loadMediaMessages();
  }

  Future<void> _loadMediaMessages() async {
    try {
      // Load messages with attachments
      final messages = await widget.channel.query(
        messagesPagination: const PaginationParams(limit: 100),
      );

      setState(() {
        _mediaMessages =
            messages.messages
                ?.where((message) => (message.attachments.isNotEmpty ?? false))
                .toList() ??
            [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load media: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Gallery'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMediaGrid(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('All', 'all'),
          const SizedBox(width: 8),
          _buildTabButton('Images', 'images'),
          const SizedBox(width: 8),
          _buildTabButton('Videos', 'videos'),
          const SizedBox(width: 8),
          _buildTabButton('Files', 'files'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String value) {
    final isSelected = _selectedTab == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = value),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.grey100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    final filteredMessages = _getFilteredMessages();

    if (filteredMessages.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: filteredMessages.length,
      itemBuilder: (context, index) {
        final message = filteredMessages[index];
        final attachment = message.attachments.first;

        return GestureDetector(
          onTap: () => _openMediaViewer(message, attachment),
          child: _buildMediaItem(attachment),
        );
      },
    );
  }

  List<Message> _getFilteredMessages() {
    return _mediaMessages.where((message) {
      final attachment = message.attachments.first;
      switch (_selectedTab) {
        case 'images':
          return attachment.type == 'image';
        case 'videos':
          return attachment.type == 'video';
        case 'files':
          return attachment.type == 'file';
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildMediaItem(Attachment attachment) {
    switch (attachment.type) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            attachment.assetUrl ?? attachment.imageUrl ?? '',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.grey200,
                child: Icon(Icons.broken_image, color: AppColors.grey600),
              );
            },
          ),
        );

      case 'video':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail placeholder
              Icon(Icons.video_file, color: AppColors.grey600, size: 32),
              // Play button overlay
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
              ),
            ],
          ),
        );

      case 'file':
        return Container(
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getFileIcon(attachment.title ?? ''),
            color: AppColors.grey600,
            size: 32,
          ),
        );

      default:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.attach_file, color: AppColors.grey600, size: 32),
        );
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getEmptyStateIcon(), size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            _getEmptyStateMessage(),
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getEmptyStateIcon() {
    switch (_selectedTab) {
      case 'images':
        return Icons.image_not_supported;
      case 'videos':
        return Icons.video_file;
      case 'files':
        return Icons.folder_open;
      default:
        return Icons.photo_library;
    }
  }

  String _getEmptyStateMessage() {
    switch (_selectedTab) {
      case 'images':
        return 'No images shared yet';
      case 'videos':
        return 'No videos shared yet';
      case 'files':
        return 'No files shared yet';
      default:
        return 'No media shared yet';
    }
  }

  void _openMediaViewer(Message message, Attachment attachment) {
    final mediaUrl = attachment.assetUrl ?? attachment.imageUrl ?? '';
    final mediaType = attachment.type ?? 'image';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaViewerScreen(
          mediaUrl: mediaUrl,
          mediaType: mediaType,
          fileName: attachment.title,
          senderName: message.user?.name,
        ),
      ),
    );
  }
}
