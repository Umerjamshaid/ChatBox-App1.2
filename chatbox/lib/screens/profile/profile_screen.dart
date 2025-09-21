// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _statusController = TextEditingController();

  ChatUser? _currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      _currentUser = await authService.getCurrentChatUser();

      if (_currentUser != null) {
        _nameController.text = _currentUser!.name ?? '';
        _bioController.text = _currentUser!.bio ?? '';
        _statusController.text =
            _currentUser!.extraData?['status_message'] ?? '';
        _selectedImageUrl = _currentUser!.image;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image != null) {
        // In a real app, you would upload this to storage
        // For now, we'll just use a placeholder
        setState(() {
          _selectedImageUrl =
              'https://via.placeholder.com/200x200/0066FF/FFFFFF?text=Profile';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      await authService.updateProfile(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim().isNotEmpty
            ? _bioController.text.trim()
            : null,
        profileImageUrl: _selectedImageUrl,
      );

      // Update status message in extra data
      if (_statusController.text.trim().isNotEmpty) {
        await authService.updateUserStatus(
          UserStatus.online,
        ); // This will trigger an update
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );

      // Reload profile to reflect changes
      await _loadUserProfile();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Image Section
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.grey200,
                      image: _selectedImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_selectedImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImageUrl == null
                        ? Icon(Icons.person, size: 60, color: AppColors.grey600)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: _pickProfileImage,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Profile Information
            const Text(
              'Profile Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // Name Field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Bio Field
            TextFormField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Tell others about yourself',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.info),
              ),
              validator: (value) {
                if (value != null && value.length > 500) {
                  return 'Bio must be less than 500 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Status Message Field
            TextFormField(
              controller: _statusController,
              decoration: const InputDecoration(
                labelText: 'Status Message',
                hintText: 'What\'s on your mind?',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.chat_bubble),
              ),
              validator: (value) {
                if (value != null && value.length > 100) {
                  return 'Status message must be less than 100 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 32),

            // Account Information (Read-only)
            const Text(
              'Account Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // Email (Read-only)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: AppColors.grey600),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                        Text(
                          _currentUser?.email ?? 'Not available',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Member Since
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppColors.grey600),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Member Since',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.grey600,
                          ),
                        ),
                        Text(
                          _currentUser?.createdAt != null
                              ? '${_currentUser!.createdAt!.month}/${_currentUser!.createdAt!.day}/${_currentUser!.createdAt!.year}'
                              : 'Not available',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Settings Navigation
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Settings
            ListTile(
              leading: Icon(Icons.privacy_tip, color: AppColors.primary),
              title: const Text('Privacy Settings'),
              subtitle: const Text('Control your privacy preferences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/privacy_settings');
              },
            ),

            // Notification Settings
            ListTile(
              leading: Icon(Icons.notifications, color: AppColors.primary),
              title: const Text('Notification Settings'),
              subtitle: const Text('Manage your notification preferences'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/notification_settings');
              },
            ),

            // Account Settings
            ListTile(
              leading: Icon(Icons.account_circle, color: AppColors.primary),
              title: const Text('Account Settings'),
              subtitle: const Text('Manage your account and data'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pushNamed(context, '/account_settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}
