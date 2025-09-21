// lib/screens/calls/call_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/call_service.dart';
import 'package:chatbox/services/notification_service.dart';
import 'package:chatbox/models/user_model.dart';

class CallHistoryScreen extends StatefulWidget {
  const CallHistoryScreen({super.key});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  late CallService _callService;
  List<CallHistory> _callHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    _callService = CallService(
      Provider.of(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
    );
    await _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    setState(() => _isLoading = true);
    final history = await _callService.getCallHistory();
    setState(() {
      _callHistory = history;
      _isLoading = false;
    });
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Call History'),
        content: const Text('Are you sure you want to clear all call history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _callService.clearCallHistory();
      await _loadCallHistory();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Call history cleared')));
    }
  }

  String _formatCallTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  String _formatCallDuration(int seconds) {
    if (seconds == 0) return '';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _getCallIcon(CallStatus status, CallType type) {
    switch (status) {
      case CallStatus.missed:
        return Icons.call_missed;
      case CallStatus.ended:
        return type == CallType.video ? Icons.videocam : Icons.call;
      case CallStatus.connected:
        return type == CallType.video ? Icons.videocam : Icons.call;
      case CallStatus.ringing:
        return Icons.call_received;
    }
  }

  Color _getCallIconColor(CallStatus status) {
    switch (status) {
      case CallStatus.missed:
        return AppColors.danger;
      case CallStatus.ended:
        return AppColors.grey600;
      case CallStatus.connected:
        return AppColors.success;
      case CallStatus.ringing:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call History'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_callHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearHistory,
              tooltip: 'Clear history',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _callHistory.isEmpty
          ? _buildEmptyState()
          : _buildCallHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call, size: 80, color: AppColors.grey400),
          const SizedBox(height: 16),
          Text(
            'No call history',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your call history will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCallHistoryList() {
    // Group calls by date
    final groupedCalls = <String, List<CallHistory>>{};

    for (final call in _callHistory) {
      final dateKey = _getDateKey(call.startTime);
      groupedCalls.putIfAbsent(dateKey, () => []).add(call);
    }

    return ListView.builder(
      itemCount: groupedCalls.length,
      itemBuilder: (context, index) {
        final dateKey = groupedCalls.keys.elementAt(index);
        final calls = groupedCalls[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.grey100,
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey700,
                ),
              ),
            ),

            // Calls for this date
            ...calls.map((call) => _buildCallHistoryItem(call)),
          ],
        );
      },
    );
  }

  Widget _buildCallHistoryItem(CallHistory call) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getCallIconColor(call.status).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getCallIcon(call.status, call.type),
          color: _getCallIconColor(call.status),
          size: 20,
        ),
      ),
      title: Text(
        call.callerName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Row(
        children: [
          if (call.participants.length > 1)
            Text('${call.participants.length} participants • '),
          Text(_formatCallTime(call.startTime)),
          if (call.duration > 0) ...[
            const Text(' • '),
            Text(_formatCallDuration(call.duration)),
          ],
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          call.type == CallType.video ? Icons.videocam : Icons.call,
          color: AppColors.primary,
        ),
        onPressed: () {
          // TODO: Start call with this person
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Call ${call.callerName}')));
        },
      ),
      onTap: () {
        // TODO: Show call details
        _showCallDetails(call);
      },
    );
  }

  void _showCallDetails(CallHistory call) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getCallIconColor(call.status).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCallIcon(call.status, call.type),
                    color: _getCallIconColor(call.status),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        call.callerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        call.type == CallType.video
                            ? 'Video Call'
                            : 'Voice Call',
                        style: TextStyle(color: AppColors.grey600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Date', _formatCallTime(call.startTime)),
            if (call.duration > 0)
              _buildDetailRow('Duration', _formatCallDuration(call.duration)),
            _buildDetailRow(
              'Participants',
              call.participants.length.toString(),
            ),
            _buildDetailRow(
              'Status',
              call.status.toString().split('.').last.toUpperCase(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Start call
                    },
                    icon: Icon(
                      call.type == CallType.video ? Icons.videocam : Icons.call,
                    ),
                    label: const Text('Call Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // TODO: Navigate to chat
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.grey600, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getDateKey(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (callDate == today) {
      return 'Today';
    } else if (callDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
