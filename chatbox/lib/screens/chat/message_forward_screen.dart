// lib/screens/chat/message_forward_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/stream_chat_service.dart';

class MessageForwardScreen extends StatefulWidget {
  final Message messageToForward;

  const MessageForwardScreen({super.key, required this.messageToForward});

  @override
  State<MessageForwardScreen> createState() => _MessageForwardScreenState();
}

class _MessageForwardScreenState extends State<MessageForwardScreen> {
  final Set<String> _selectedChannels = {};
  bool _isLoading = true;
  List<Channel> _channels = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
  }

  Future<void> _loadChannels() async {
    try {
      final client = StreamChat.of(context).client;
      final channels = await client.queryChannels().first;

      setState(() {
        _channels = channels;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load channels: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forward Message'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedChannels.isNotEmpty)
            TextButton(
              onPressed: _forwardMessages,
              child: Text(
                'Send (${_selectedChannels.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _channels.isEmpty
          ? const Center(child: Text('No chats available'))
          : ListView.builder(
              itemCount: _channels.length,
              itemBuilder: (context, index) {
                final channel = _channels[index];
                final isSelected = _selectedChannels.contains(channel.id);

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.grey200,
                    backgroundImage: channel.image != null
                        ? NetworkImage(channel.image!)
                        : null,
                    child: channel.image == null
                        ? Text(
                            channel.name?.substring(0, 1).toUpperCase() ?? '#',
                            style: TextStyle(
                              color: AppColors.grey600,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(channel.name ?? 'Unnamed Chat'),
                  subtitle: Text(
                    channel.type == 'team' ? 'Group' : 'Direct Message',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedChannels.add(channel.id!);
                        } else {
                          _selectedChannels.remove(channel.id!);
                        }
                      });
                    },
                  ),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedChannels.remove(channel.id!);
                      } else {
                        _selectedChannels.add(channel.id!);
                      }
                    });
                  },
                );
              },
            ),
      bottomNavigationBar: _selectedChannels.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.grey300)),
              ),
              child: Row(
                children: [
                  // Message preview
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.messageToForward.text ?? 'Attachment',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _forwardMessages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Send (${_selectedChannels.length})'),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Future<void> _forwardMessages() async {
    if (_selectedChannels.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final client = StreamChat.of(context).client;
      int successCount = 0;

      for (final channelId in _selectedChannels) {
        try {
          final channel = client.channel('messaging', id: channelId);
          await channel.sendMessage(
            widget.messageToForward.copyWith(
              id: null, // Generate new ID
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          successCount++;
        } catch (e) {
          print('Failed to forward to channel $channelId: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Message forwarded to $successCount chat${successCount != 1 ? 's' : ''}',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to forward message: $e')));
    }
  }
}
