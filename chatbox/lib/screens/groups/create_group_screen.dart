// lib/screens/groups/create_group_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/services/group_service.dart';
import 'package:chatbox/services/media_service.dart';
import 'package:chatbox/widgets/progress_indicator.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedImageUrl;
  List<ChatUser> _availableUsers = [];
  final List<String> _selectedUserIds = [];
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  bool _isPrivate = true;
  bool _isBroadcast = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableUsers() async {
    setState(() => _isLoadingUsers = true);

    try {
      // In a real app, you would fetch users from your backend
      // For now, we'll create some mock users
      _availableUsers = [
        ChatUser(
          id: 'user1',
          name: 'Alice Johnson',
          email: 'alice@example.com',
          image: 'https://randomuser.me/api/portraits/women/1.jpg',
        ),
        ChatUser(
          id: 'user2',
          name: 'Bob Smith',
          email: 'bob@example.com',
          image: 'https://randomuser.me/api/portraits/men/2.jpg',
        ),
        ChatUser(
          id: 'user3',
          name: 'Charlie Brown',
          email: 'charlie@example.com',
          image: 'https://randomuser.me/api/portraits/men/3.jpg',
        ),
        ChatUser(
          id: 'user4',
          name: 'Diana Prince',
          email: 'diana@example.com',
          image: 'https://randomuser.me/api/portraits/women/4.jpg',
        ),
        ChatUser(
          id: 'user5',
          name: 'Eve Wilson',
          email: 'eve@example.com',
          image: 'https://randomuser.me/api/portraits/women/5.jpg',
        ),
      ];
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load users: $e')));
    } finally {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _pickGroupImage() async {
    try {
      final image = await MediaService().pickImage(source: ImageSource.gallery);
      if (image != null) {
        // In a real app, you would upload this to your storage
        // For now, we'll just use a placeholder
        setState(() {
          _selectedImageUrl =
              'https://via.placeholder.com/200x200/0066FF/FFFFFF?text=Group';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one participant')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final groupService = GroupService();
      final channel = await groupService.createGroup(
        name: _nameController.text.trim(),
        memberIds: _selectedUserIds,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        imageUrl: _selectedImageUrl,
        privacy: _isPrivate ? GroupPrivacy.private : GroupPrivacy.public,
        isBroadcast: _isBroadcast,
      );

      if (channel != null) {
        Navigator.pop(context);
        // Navigate to the created group chat
        // You would implement this navigation
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create group: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Group'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createGroup,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Create',
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
            // Group Image
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.grey200,
                      shape: BoxShape.circle,
                      image: _selectedImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_selectedImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _selectedImageUrl == null
                        ? const Icon(
                            Icons.group,
                            size: 40,
                            color: AppColors.grey600,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: _pickGroupImage,
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Group Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'Enter group name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a group name';
                }
                if (value.trim().length < 3) {
                  return 'Group name must be at least 3 characters';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Group Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Enter group description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // Group Settings
            const Text(
              'Group Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),

            const SizedBox(height: 16),

            // Privacy Setting
            SwitchListTile(
              title: const Text('Private Group'),
              subtitle: const Text('Only invited members can join'),
              value: _isPrivate,
              onChanged: (value) => setState(() => _isPrivate = value),
            ),

            // Broadcast Setting
            SwitchListTile(
              title: const Text('Broadcast Group'),
              subtitle: const Text('Only admins can send messages'),
              value: _isBroadcast,
              onChanged: (value) => setState(() => _isBroadcast = value),
            ),

            const SizedBox(height: 24),

            // Participants Section
            Row(
              children: [
                Text(
                  'Add Participants (${_selectedUserIds.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selectedUserIds.length} selected',
                  style: TextStyle(fontSize: 14, color: AppColors.grey600),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Participants List
            if (_isLoadingUsers)
              const Center(child: CircularProgressIndicator())
            else
              ..._availableUsers.map((user) => _buildUserTile(user)),

            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Group (${_selectedUserIds.length + 1} members)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTile(ChatUser user) {
    final isSelected = _selectedUserIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.grey200,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.image != null
              ? NetworkImage(user.image!)
              : null,
          child: user.image == null
              ? Text(
                  user.name?.substring(0, 1).toUpperCase() ?? '?',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        title: Text(
          user.name ?? 'Unknown User',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          user.email ?? '',
          style: TextStyle(color: AppColors.grey600, fontSize: 12),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) => _toggleUserSelection(user.id),
          activeColor: AppColors.primary,
        ),
        onTap: () => _toggleUserSelection(user.id),
      ),
    );
  }
}
