// lib/screens/groups/group_info_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/constants/styles.dart';
import 'package:chatbox/services/group_service.dart';
import 'package:chatbox/models/user_model.dart';

class GroupInfoScreen extends StatefulWidget {
  final Channel channel;

  const GroupInfoScreen({super.key, required this.channel});

  @override
  State<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends State<GroupInfoScreen> {
  final GroupService _groupService = GroupService();
  late List<Member> _members;
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    setState(() => _isLoading = true);

    try {
      // Get current user
      _currentUserId = StreamChat.of(context).client.state.currentUser?.id;

      // Load members
      await widget.channel.watch();
      _members = widget.channel.state?.members ?? [];
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load group data: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateGroupName() async {
    final controller = TextEditingController(text: widget.channel.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new group name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null &&
        newName.isNotEmpty &&
        newName != widget.channel.name) {
      try {
        await _groupService.updateGroupInfo(widget.channel, name: newName);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group name updated')));
        setState(() {}); // Refresh UI
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update group name: $e')),
        );
      }
    }
  }

  Future<void> _updateGroupDescription() async {
    final controller = TextEditingController(
      text: (widget.channel.extraData?['description'] as String?) ?? '',
    );
    final newDescription = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Description'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter group description',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newDescription != null &&
        newDescription != (widget.channel.extraData?['description'] ?? '')) {
      try {
        await _groupService.updateGroupInfo(
          widget.channel,
          description: newDescription,
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Description updated')));
        setState(() {}); // Refresh UI
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update description: $e')),
        );
      }
    }
  }

  Future<void> _changeMemberRole(String memberId, MemberRole newRole) async {
    try {
      await _groupService.updateMemberRole(widget.channel, memberId, newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Member role updated to ${newRole.toString().split('.').last}',
          ),
        ),
      );
      _loadGroupData(); // Refresh members
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update member role: $e')),
      );
    }
  }

  Future<void> _removeMember(String memberId, String memberName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text(
          'Are you sure you want to remove $memberName from the group?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _groupService.removeMember(widget.channel, memberId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$memberName removed from group')),
        );
        _loadGroupData(); // Refresh members
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove member: $e')));
      }
    }
  }

  Future<void> _leaveGroup() async {
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
        await _groupService.leaveGroup(widget.channel);
        Navigator.pop(context); // Go back to chat list
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

  Future<void> _deleteGroup() async {
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
        await _groupService.deleteGroup(widget.channel);
        Navigator.pop(context); // Go back to chat list
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

  void _showMemberOptions(Member member) {
    final isCurrentUser = member.userId == _currentUserId;
    final isAdmin = _groupService.isUserAdmin(widget.channel, _currentUserId!);
    final memberRole = _groupService.getMemberRole(
      widget.channel,
      member.userId!,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundImage: member.user?.image != null
                    ? NetworkImage(member.user!.image!)
                    : null,
                child: member.user?.image == null
                    ? Text(
                        member.user?.name?.substring(0, 1).toUpperCase() ?? '?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
              title: Text(member.user?.name ?? 'Unknown User'),
              subtitle: Text(_getRoleText(memberRole)),
            ),
            const Divider(),
            if (isAdmin && !isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Make Admin'),
                onTap: () {
                  Navigator.pop(context);
                  _changeMemberRole(member.userId!, MemberRole.admin);
                },
              ),
              ListTile(
                leading: const Icon(Icons.supervisor_account),
                title: const Text('Make Moderator'),
                onTap: () {
                  Navigator.pop(context);
                  _changeMemberRole(member.userId!, MemberRole.moderator);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Make Member'),
                onTap: () {
                  Navigator.pop(context);
                  _changeMemberRole(member.userId!, MemberRole.member);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(
                  Icons.remove_circle,
                  color: AppColors.danger,
                ),
                title: const Text('Remove from Group'),
                onTap: () {
                  Navigator.pop(context);
                  _removeMember(
                    member.userId!,
                    member.user?.name ?? 'Unknown User',
                  );
                },
              ),
            ],
            if (isCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: AppColors.danger),
                title: const Text('Leave Group'),
                onTap: () {
                  Navigator.pop(context);
                  _leaveGroup();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRoleText(MemberRole role) {
    switch (role) {
      case MemberRole.admin:
        return 'Admin';
      case MemberRole.moderator:
        return 'Moderator';
      case MemberRole.member:
        return 'Member';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        _currentUserId != null &&
        _groupService.isUserAdmin(widget.channel, _currentUserId!);
    final stats = _groupService.getGroupStats(widget.channel);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit_name':
                    _updateGroupName();
                    break;
                  case 'edit_description':
                    _updateGroupDescription();
                    break;
                  case 'delete_group':
                    _deleteGroup();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit_name',
                  child: Text('Edit Group Name'),
                ),
                const PopupMenuItem(
                  value: 'edit_description',
                  child: Text('Edit Description'),
                ),
                const PopupMenuItem(
                  value: 'delete_group',
                  child: Text('Delete Group'),
                ),
              ],
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Group Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: AppColors.surface,
                  child: Column(
                    children: [
                      // Group Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: widget.channel.image != null
                            ? NetworkImage(widget.channel.image!)
                            : null,
                        child: widget.channel.image == null
                            ? const Icon(
                                Icons.group,
                                size: 50,
                                color: AppColors.grey600,
                              )
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Group Name
                      Text(
                        widget.channel.name ?? 'Unnamed Group',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      // Group Description
                      if (widget.channel.extraData?['description'] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.channel.extraData!['description'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.grey600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      // Group Stats
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildStat('${stats['memberCount']}', 'Members'),
                          const SizedBox(width: 24),
                          _buildStat('${stats['messageCount']}', 'Messages'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Members Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Members (${_members.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Members List
                ..._members.map((member) => _buildMemberTile(member)),

                const SizedBox(height: 24),

                // Group Settings (Admin only)
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Group Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Broadcast Setting
                  SwitchListTile(
                    title: const Text('Broadcast Mode'),
                    subtitle: const Text('Only admins can send messages'),
                    value:
                        (widget.channel.extraData?['is_broadcast'] as bool?) ??
                        false,
                    onChanged: (value) async {
                      try {
                        await _groupService.makeChannelBroadcast(
                          widget.channel,
                          value,
                        );
                        setState(() {});
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Failed to update broadcast setting: $e',
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  // Invite Link
                  ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Invite Link'),
                    subtitle: const Text('Generate link to invite members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      final inviteLink = _groupService.generateInviteLink(
                        widget.channel.id!,
                      );
                      // TODO: Show invite link dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invite link: $inviteLink')),
                      );
                    },
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.grey600)),
      ],
    );
  }

  Widget _buildMemberTile(Member member) {
    final isCurrentUser = member.userId == _currentUserId;
    final memberRole = _groupService.getMemberRole(
      widget.channel,
      member.userId!,
    );
    final isAdmin =
        _currentUserId != null &&
        _groupService.isUserAdmin(widget.channel, _currentUserId!);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: member.user?.image != null
            ? NetworkImage(member.user!.image!)
            : null,
        child: member.user?.image == null
            ? Text(
                member.user?.name?.substring(0, 1).toUpperCase() ?? '?',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              )
            : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              member.user?.name ?? 'Unknown User',
              style: TextStyle(
                fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (memberRole != MemberRole.member)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: memberRole == MemberRole.admin
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleText(memberRole),
                style: TextStyle(
                  fontSize: 12,
                  color: memberRole == MemberRole.admin
                      ? AppColors.primary
                      : AppColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        isCurrentUser ? 'You' : 'Member',
        style: TextStyle(color: AppColors.grey600, fontSize: 12),
      ),
      trailing: (isAdmin || isCurrentUser) ? const Icon(Icons.more_vert) : null,
      onTap: (isAdmin || isCurrentUser)
          ? () => _showMemberOptions(member)
          : null,
    );
  }
}
