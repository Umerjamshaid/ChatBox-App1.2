// lib/screens/calls/video_call_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/call_service.dart';
import 'package:chatbox/services/notification_service.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/widgets/group_call_participants.dart';
import 'package:chatbox/widgets/network_status_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class VideoCallScreen extends StatefulWidget {
  final List<String> participantIds;
  final String? callId;
  final bool isIncoming;

  const VideoCallScreen({
    super.key,
    required this.participantIds,
    this.callId,
    this.isIncoming = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  late CallService _callService;
  CallSession? _currentCall;
  Timer? _callTimer;
  int _callDuration = 0;
  bool _isCallConnected = false;
  bool _isFrontCamera = true;

  // Network status
  ConnectivityResult _connectivity = ConnectivityResult.none;
  int _networkQuality = 5;

  @override
  void initState() {
    super.initState();
    _initializeNetworkStatus();
    _initializeCall();
  }

  void _initializeNetworkStatus() {
    _connectivity = _callService.primaryConnectivity;
    _networkQuality = _callService.networkQuality;

    // Listen to network changes
    _callService.onConnectivityChanged = (connectivity) {
      setState(() {
        _connectivity = connectivity;
      });
    };

    _callService.onQualityChanged = (quality) {
      setState(() {
        _networkQuality = quality;
      });
    };
  }

  Future<void> _initializeCall() async {
    _callService = CallService(
      Provider.of(context, listen: false),
      Provider.of<NotificationService>(context, listen: false),
    );

    if (widget.isIncoming) {
      _showIncomingCallDialog();
    } else {
      await _startCall();
    }
  }

  Future<void> _startCall() async {
    final call = await _callService.startCall(
      participantIds: widget.participantIds,
      type: CallType.video,
      callId: widget.callId,
    );

    if (call != null) {
      setState(() {
        _currentCall = call;
        _isCallConnected = true;
      });

      _startCallTimer();
    } else {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to start video call')),
      );
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
                child: const Icon(
                  Icons.videocam,
                  size: 50,
                  color: Colors.white,
                ),
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
                'Video Call',
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
                      Navigator.of(context).pop();
                    },
                  ),
                  _buildCallButton(
                    icon: Icons.videocam,
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main video area or group participants
            _callService.isGroupCall && _currentCall != null
                ? GroupCallParticipants(
                    participants: _currentCall!.participants,
                    isVideoCall: true,
                    onMuteToggle: _callService.muteParticipant,
                    onVideoToggle: _callService.toggleParticipantVideo,
                  )
                : Container(
                    color: Colors.black,
                    child: const Center(
                      child: Icon(
                        Icons.videocam_off,
                        size: 100,
                        color: Colors.white54,
                      ),
                    ),
                  ),

            // Call duration overlay
            if (_isCallConnected)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _formatDuration(_callDuration),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // Network status indicator
            if (_isCallConnected)
              Positioned(
                top: 16,
                right: 16,
                child: NetworkStatusIndicator(
                  connectivity: _callService.primaryConnectivity,
                  quality: _callService.networkQuality,
                ),
              ),

            // Screen sharing indicator
            if (_callService.isScreenSharing)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.screen_share, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Sharing Screen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Participant name overlay
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.participantIds.isNotEmpty
                        ? widget.participantIds.first
                        : 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            // Self video preview (bottom right corner)
            Positioned(
              bottom: 120,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Icon(Icons.person, size: 40, color: Colors.white54),
                ),
              ),
            ),

            // Call controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Column(
                  children: [
                    // Add participant button for group calls
                    if (_callService.isGroupCall)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildControlButton(
                          icon: Icons.person_add,
                          label: 'Add',
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
                          icon: _callService.isVideoEnabled
                              ? Icons.videocam
                              : Icons.videocam_off,
                          label: _callService.isVideoEnabled
                              ? 'Video Off'
                              : 'Video On',
                          onPressed: () => _callService.toggleVideo(),
                          isActive: !_callService.isVideoEnabled,
                        ),
                        _buildControlButton(
                          icon: Icons.flip_camera_ios,
                          label: 'Flip',
                          onPressed: () => _callService.switchCamera(),
                        ),
                        _buildControlButton(
                          icon: Icons.screen_share,
                          label: _callService.isScreenSharing
                              ? 'Stop'
                              : 'Share',
                          onPressed: () async {
                            try {
                              await _callService.toggleScreenShare();
                              setState(() {}); // Refresh UI
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Screen sharing failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          isActive: _callService.isScreenSharing,
                        ),
                        _buildControlButton(
                          icon: Icons.videocam,
                          label: _callService.isRecording
                              ? 'Stop Rec'
                              : 'Record',
                          onPressed: () async {
                            try {
                              await _callService.toggleRecording();
                              setState(() {}); // Refresh UI
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Recording failed: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          isActive: _callService.isRecording,
                          color: _callService.isRecording ? Colors.red : null,
                        ),
                        _buildControlButton(
                          icon: Icons.call_end,
                          label: 'End',
                          onPressed: _endCall,
                          color: AppColors.danger,
                          isActive: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isActive
                ? (color ?? AppColors.primary)
                : Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? Colors.white : Colors.white,
              size: 24,
            ),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
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
