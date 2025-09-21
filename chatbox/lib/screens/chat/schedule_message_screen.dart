// lib/screens/chat/schedule_message_screen.dart
import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/scheduled_message_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ScheduleMessageScreen extends StatefulWidget {
  final Channel channel;
  final String? initialText;
  final List<Attachment>? initialAttachments;

  const ScheduleMessageScreen({
    super.key,
    required this.channel,
    this.initialText,
    this.initialAttachments,
  });

  @override
  State<ScheduleMessageScreen> createState() => _ScheduleMessageScreenState();
}

class _ScheduleMessageScreenState extends State<ScheduleMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late ScheduledMessageService _scheduledService;

  @override
  void initState() {
    super.initState();
    _initializeService();
    if (widget.initialText != null) {
      _messageController.text = widget.initialText!;
    }
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    _scheduledService = ScheduledMessageService(prefs);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Message'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _scheduleMessage,
            child: const Text(
              'Schedule',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    backgroundImage: widget.channel.image != null
                        ? NetworkImage(widget.channel.image!)
                        : null,
                    child: widget.channel.image == null
                        ? Text(
                            widget.channel.name
                                    ?.substring(0, 1)
                                    .toUpperCase() ??
                                '#',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'To: ${widget.channel.name ?? 'Unnamed Chat'}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Message input
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppColors.grey100,
              ),
            ),
            const SizedBox(height: 24),

            // Schedule time picker
            const Text(
              'Schedule Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Date picker
            InkWell(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select date',
                        style: TextStyle(
                          color: _selectedDate != null
                              ? AppColors.onSurface
                              : AppColors.grey600,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.grey600),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time picker
            InkWell(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.grey300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select time',
                        style: TextStyle(
                          color: _selectedTime != null
                              ? AppColors.onSurface
                              : AppColors.grey600,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: AppColors.grey600),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Scheduled time preview
            if (_selectedDate != null && _selectedTime != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Message will be sent on ${_formatScheduledTime()}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  String _formatScheduledTime() {
    if (_selectedDate == null || _selectedTime == null) return '';

    final dateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'today at ${_selectedTime!.format(context)}';
    } else if (difference.inDays == 1) {
      return 'tomorrow at ${_selectedTime!.format(context)}';
    } else {
      return '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} at ${_selectedTime!.format(context)}';
    }
  }

  Future<void> _scheduleMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final scheduledDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (scheduledDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a future time')),
      );
      return;
    }

    try {
      final currentUser = StreamChat.of(context).currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not authenticated')));
        return;
      }

      await _scheduledService.scheduleMessage(
        channelId: widget.channel.id!,
        text: _messageController.text.trim(),
        scheduledTime: scheduledDateTime,
        attachments: widget.initialAttachments ?? [],
        userId: currentUser.id,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message scheduled for ${_formatScheduledTime()}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to schedule message: $e')));
    }
  }
}
