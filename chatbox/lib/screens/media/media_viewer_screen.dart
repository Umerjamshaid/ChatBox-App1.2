// lib/screens/media/media_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import 'package:chatbox/services/media_service.dart';

class MediaViewerScreen extends StatefulWidget {
  final String mediaUrl;
  final String mediaType; // 'image', 'video'
  final String? fileName;
  final String? senderName;

  const MediaViewerScreen({
    super.key,
    required this.mediaUrl,
    required this.mediaType,
    this.fileName,
    this.senderName,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _initializeVideo();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.network(widget.mediaUrl);
      await _videoController!.initialize();
      setState(() => _isVideoInitialized = true);
    } catch (e) {
      // If network video fails, try local file
      try {
        final localFile = await MediaService().getCachedFile(widget.mediaUrl);
        if (localFile != null) {
          _videoController = VideoPlayerController.file(localFile);
          await _videoController!.initialize();
          setState(() => _isVideoInitialized = true);
        }
      } catch (e) {
        print('Failed to load video: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.7),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.senderName != null)
              Text(
                widget.senderName!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            if (widget.fileName != null)
              Text(
                widget.fileName!,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        actions: [
          // Download button
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _downloadMedia,
          ),

          // Share button
          IconButton(icon: const Icon(Icons.share), onPressed: _shareMedia),
        ],
      ),
      body: Stack(
        children: [
          // Media content
          Center(
            child: widget.mediaType == 'image'
                ? _buildImageViewer()
                : _buildVideoViewer(),
          ),

          // Loading indicator
          if (_isDownloading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
      bottomNavigationBar: widget.mediaType == 'video' && _isVideoInitialized
          ? _buildVideoControls()
          : null,
    );
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: NetworkImage(widget.mediaUrl),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      loadingBuilder: (context, event) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[900],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 64),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoViewer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return AspectRatio(
      aspectRatio: _videoController!.value.aspectRatio,
      child: VideoPlayer(_videoController!),
    );
  }

  Widget _buildVideoControls() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Play/Pause button
          IconButton(
            icon: Icon(
              _videoController!.value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
            onPressed: () {
              setState(() {
                _videoController!.value.isPlaying
                    ? _videoController!.pause()
                    : _videoController!.play();
              });
            },
          ),

          // Progress bar
          Expanded(
            child: VideoProgressIndicator(
              _videoController!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.white,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white24,
              ),
            ),
          ),

          // Duration
          Text(
            _formatDuration(_videoController!.value.duration),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadMedia() async {
    setState(() => _isDownloading = true);

    try {
      final fileName =
          widget.fileName ?? 'media_${DateTime.now().millisecondsSinceEpoch}';
      await MediaService().downloadAndCacheFile(widget.mediaUrl, fileName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media downloaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to download media: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _shareMedia() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sharing coming soon!')));
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
