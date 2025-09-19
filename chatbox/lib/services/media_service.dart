// lib/services/media_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:chatbox/constants/colors.dart';

class MediaService {
  final ImagePicker _imagePicker = ImagePicker();
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  // Image Picker with enhanced options
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? imageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality ?? 80,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Video Picker
  Future<XFile?> pickVideo({
    ImageSource source = ImageSource.gallery,
    Duration? maxDuration,
  }) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      return video;
    } catch (e) {
      throw Exception('Failed to pick video: $e');
    }
  }

  // File Picker for documents
  Future<FilePickerResult?> pickFiles({
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );
      return result;
    } catch (e) {
      throw Exception('Failed to pick files: $e');
    }
  }

  // Image Compression
  Future<Uint8List?> compressImage(
    File imageFile, {
    int quality = 80,
    int minWidth = 800,
    int minHeight = 600,
  }) async {
    try {
      final Uint8List? compressedBytes =
          await FlutterImageCompress.compressWithFile(
            imageFile.absolute.path,
            quality: quality,
            minWidth: minWidth,
            minHeight: minHeight,
          );
      return compressedBytes;
    } catch (e) {
      throw Exception('Failed to compress image: $e');
    }
  }

  // Video Thumbnail Generation
  Future<Uint8List?> generateVideoThumbnail(
    String videoPath, {
    int imageQuality = 80,
    int maxWidth = 300,
    int maxHeight = 200,
  }) async {
    try {
      final Uint8List? thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        quality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      return thumbnail;
    } catch (e) {
      throw Exception('Failed to generate video thumbnail: $e');
    }
  }

  // Location Services
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Reverse Geocoding
  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return 'Unknown location';
    } catch (e) {
      throw Exception('Failed to get address: $e');
    }
  }

  // File Type Detection
  String getFileType(String filePath) {
    final mimeType = lookupMimeType(filePath);
    if (mimeType == null) return 'unknown';

    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType.startsWith('video/')) return 'video';
    if (mimeType.startsWith('audio/')) return 'audio';
    if (mimeType == 'application/pdf') return 'pdf';
    if (mimeType.contains('document') || mimeType.contains('word'))
      return 'document';
    if (mimeType.contains('spreadsheet') || mimeType.contains('excel'))
      return 'spreadsheet';

    return 'file';
  }

  // Get File Icon
  IconData getFileIcon(String fileType) {
    switch (fileType) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'document':
        return Icons.description;
      case 'spreadsheet':
        return Icons.table_chart;
      default:
        return Icons.insert_drive_file;
    }
  }

  // Get File Size String
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Download and Cache File
  Future<File> downloadAndCacheFile(String url, String fileName) async {
    try {
      final file = await _cacheManager.getSingleFile(url);
      return file;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  // Get Local File Path
  Future<String> getLocalFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }

  // Save File Locally
  Future<String> saveFileLocally(Uint8List bytes, String fileName) async {
    try {
      final filePath = await getLocalFilePath(fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      throw Exception('Failed to save file: $e');
    }
  }

  // Check if file exists locally
  Future<bool> fileExistsLocally(String filePath) async {
    return await File(filePath).exists();
  }

  // Get cached file
  Future<File?> getCachedFile(String url) async {
    try {
      return await _cacheManager.getSingleFile(url);
    } catch (e) {
      return null;
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    await _cacheManager.emptyCache();
  }

  // Get cache size
  Future<int> getCacheSize() async {
    final cacheDir = await getTemporaryDirectory();
    int totalSize = 0;

    try {
      final files = cacheDir.listSync(recursive: true);
      for (var file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      // Handle error
    }

    return totalSize;
  }
}

// Media Item Model
class MediaItem {
  final String id;
  final String type; // 'image', 'video', 'audio', 'file', 'location'
  final String url;
  final String? thumbnailUrl;
  final String? localPath;
  final String? fileName;
  final int? fileSize;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  MediaItem({
    required this.id,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.localPath,
    this.fileName,
    this.fileSize,
    this.metadata,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'],
      type: json['type'],
      url: json['url'],
      thumbnailUrl: json['thumbnailUrl'],
      localPath: json['localPath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'],
      metadata: json['metadata'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'localPath': localPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

// Location Data Model
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      address: json['address'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
