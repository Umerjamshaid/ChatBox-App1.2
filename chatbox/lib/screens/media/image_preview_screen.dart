// lib/screens/media/image_preview_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/services/media_service.dart';

class ImagePreviewScreen extends StatefulWidget {
  final XFile imageFile;
  final Function(XFile)? onSend;

  const ImagePreviewScreen({super.key, required this.imageFile, this.onSend});

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  final TextEditingController _captionController = TextEditingController();
  bool _isCompressing = false;
  Uint8List? _compressedImage;
  double _compressionQuality = 0.8;

  @override
  void initState() {
    super.initState();
    _compressImage();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _compressImage() async {
    setState(() => _isCompressing = true);

    try {
      final file = File(widget.imageFile.path);
      final compressedBytes = await MediaService().compressImage(
        file,
        quality: (_compressionQuality * 100).toInt(),
      );

      if (mounted) {
        setState(() {
          _compressedImage = compressedBytes;
          _isCompressing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCompressing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to compress image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Preview'),
        actions: [
          TextButton(
            onPressed: _sendImage,
            child: const Text(
              'Send',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: _isCompressing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : _compressedImage != null
                      ? Image.memory(_compressedImage!, fit: BoxFit.contain)
                      : Image.file(
                          File(widget.imageFile.path),
                          fit: BoxFit.contain,
                        ),
                ),

                // Compression indicator
                if (_isCompressing)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Compressing...',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),

                // Quality selector
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quality',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text(
                              'Low',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _compressionQuality,
                                min: 0.1,
                                max: 1.0,
                                divisions: 9,
                                activeColor: AppColors.primary,
                                inactiveColor: Colors.white30,
                                onChanged: (value) {
                                  setState(() => _compressionQuality = value);
                                  _compressImage();
                                },
                              ),
                            ),
                            const Text(
                              'High',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${(_compressionQuality * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Caption Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _captionController,
                  decoration: InputDecoration(
                    hintText: 'Add a caption...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.grey100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Add more options
                    IconButton(
                      icon: Icon(
                        Icons.add_photo_alternate,
                        color: AppColors.grey600,
                      ),
                      onPressed: () {
                        // TODO: Add more images
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.emoji_emotions,
                        color: AppColors.grey600,
                      ),
                      onPressed: () {
                        // TODO: Add emoji to caption
                      },
                    ),
                    const Spacer(),
                    // Send button
                    ElevatedButton.icon(
                      onPressed: _sendImage,
                      icon: const Icon(Icons.send, color: Colors.white),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendImage() {
    if (widget.onSend != null) {
      widget.onSend!(widget.imageFile);
    }
    Navigator.pop(context);
  }
}
