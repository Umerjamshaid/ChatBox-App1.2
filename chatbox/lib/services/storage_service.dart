// lib/services/storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      return image;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      return image;
    } catch (e) {
      throw Exception('Failed to take photo: $e');
    }
  }

  // Upload profile image to Firebase Storage
  Future<String> uploadProfileImage(String userId, XFile imageFile) async {
    try {
      // Create a unique filename
      final String fileName =
          '${userId}_profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';
      final Reference ref = _storage.ref().child('profile_images/$fileName');

      // Upload the file
      final UploadTask uploadTask = ref.putFile(File(imageFile.path));

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get the download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete profile image from Firebase Storage
  Future<void> deleteProfileImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete image: $e');
    }
  }

  // Update profile image (delete old one and upload new one)
  Future<String> updateProfileImage(
    String userId,
    XFile newImageFile,
    String? oldImageUrl,
  ) async {
    try {
      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteProfileImage(oldImageUrl);
      }

      // Upload new image
      final String newImageUrl = await uploadProfileImage(userId, newImageFile);

      return newImageUrl;
    } catch (e) {
      throw Exception('Failed to update image: $e');
    }
  }

  // Get image picker options
  Future<XFile?> showImagePickerOptions() async {
    // This would typically show a dialog to choose camera or gallery
    // For now, we'll default to gallery
    return await pickImageFromGallery();
  }
}
