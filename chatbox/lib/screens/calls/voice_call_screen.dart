// lib/screens/calls/voice_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/call_service.dart';
import 'package:chatbox/services/notification_service.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/widgets/group_call_participants.dart';

class VoiceCallScreen extends StatefulWidget {
  final List<String> participantIds;
  final String? callId;
  final bool isIncoming;

  const VoiceCallScreen({
    super.key,
    required this.participantIds,
    this.callId,
    this.isIncoming = false,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  late CallService _callService;
  CallSession? _currentCall;
  Timer? _callTimer;
  int _callDuration = 0;
  bool _isCallConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();
  }

  Future<void> _initializeCall() async {
    _callService = CallService(
      Provider.of(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
    );

    if (widget.isIncoming) {
      // Handle incoming call
      _showIncomingCallDialog();
    } else {
      // Start outgoing call
      await _startCall();
    }
  }

  Future<void> _startCall() async {
    final call = await _callService.startCall(
      participantIds: widget.participantIds,
      type: CallType.voice,
      callId: widget.callId,
    );

    if (call != null) {
      setState(() {
        _currentCall = call;
        _isCallConnected = true;
      });

      _startCallTimer();
    } else {
      // Call failed
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to start call')));
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration++;
      });
    });
  }

  void _showIncomingCallDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.primary,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                widget.participantIds.isNotEmpty
                    ? widget.participantIds.first
                    : 'Unknown',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Voice Call',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCallButton(
                    icon: Icons.call_end,
                    color: AppColors.danger,
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(); // Go back to previous screen
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.call,
                    color: AppColors.success,
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _startCall();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 28),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _addParticipant() async {
    // Show dialog to add participant
    final participantId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Participant'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter participant ID or name',
            labelText: 'Participant',
          ),
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Get the text from the TextField
              final textField = context.findRenderObject() as RenderBox?;
              // For now, just use a placeholder
              Navigator.of(
                context,
              ).pop('new_participant_${DateTime.now().millisecondsSinceEpoch}');
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (participantId != null && participantId.isNotEmpty) {
      final success = await _callService.addParticipant(
        participantId,
        participantId,
      );
      if (success) {
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added $participantId to the call')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add participant')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primary.withOpacity(0.8),
                    AppColors.primary.withOpacity(0.4),
                  ],
                ),
              ),
            ),

            // Call content
            Column(
              children: [
                // Header with call duration
                if (_isCallConnected)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _formatDuration(_callDuration),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Spacer
                const Spacer(),

                // Participant info or group view
                Expanded(
                  child: _callService.isGroupCall && _currentCall != null
                      ? GroupCallParticipants(
                          participants: _currentCall!.participants,
                          isVideoCall: false,
                          onMuteToggle: _callService.muteParticipant,
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 80,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Icon(
                                Icons.person,
                                size: 80,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              widget.participantIds.isNotEmpty
                                  ? widget.participantIds.first
                                  : 'Unknown Caller',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isCallConnected ? 'Connected' : 'Calling...',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                ),

                // Spacer
                const Spacer(),

                // Call controls
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      // Add participant button for group calls
                      if (_callService.isGroupCall)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildControlButton(
                            icon: Icons.person_add,
                            label: 'Add Participant',
                            onPressed: _addParticipant,
                            color: AppColors.primary,
                          ),
                        ),

                      // Main controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: _callService.isMuted
                                ? Icons.mic_off
                                : Icons.mic,
                            label: _callService.isMuted ? 'Unmute' : 'Mute',
                            onPressed: () => _callService.toggleMute(),
                            isActive: _callService.isMuted,
                          ),
                          _buildControlButton(
                            icon: _callService.isSpeakerOn
                                ? Icons.volume_up
                                : Icons.volume_down,
                            label: 'Speaker',
                            onPressed: () => _callService.toggleSpeaker(),
                            isActive: _callService.isSpeakerOn,
                          ),
                          _buildControlButton(
                            icon: Icons.call_end,
                            label: 'End Call',
                            onPressed: _endCall,
                            color: AppColors.danger,
                            isActive: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
    bool isActive = false,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isActive
                ? (color ?? AppColors.primary)
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white.withOpacity(0.8),
              size: 28,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Future<void> _endCall() async {
    await _callService.endCall();
    _callTimer?.cancel();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    super.dispose();
  }
}
