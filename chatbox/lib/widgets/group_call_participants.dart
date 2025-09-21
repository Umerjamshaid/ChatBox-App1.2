// lib/widgets/group_call_participants.dart
import 'package:flutter/material.dart';
import 'package:chatbox/services/call_service.dart';
import 'package:chatbox/constants/colors.dart';

class GroupCallParticipants extends StatelessWidget {
  final List<CallParticipant> participants;
  final bool isVideoCall;
  final Function(String, bool)? onMuteToggle;
  final Function(String, bool)? onVideoToggle;
  final Function(String)? onRemoveParticipant;

  const GroupCallParticipants({
    super.key,
    required this.participants,
    this.isVideoCall = false,
    this.onMuteToggle,
    this.onVideoToggle,
    this.onRemoveParticipant,
  });

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const Center(
        child: Text(
          'No participants',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getGridColumns(participants.length),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: isVideoCall ? 0.75 : 1.0,
      ),
      itemCount: participants.length,
      itemBuilder: (context, index) {
        final participant = participants[index];
        return _ParticipantTile(
          participant: participant,
          isVideoCall: isVideoCall,
          onMuteToggle: onMuteToggle != null
              ? (muted) => onMuteToggle!(participant.id, muted)
              : null,
          onVideoToggle: onVideoToggle != null
              ? (enabled) => onVideoToggle!(participant.id, enabled)
              : null,
          onRemove: onRemoveParticipant != null
              ? () => onRemoveParticipant!(participant.id)
              : null,
        );
      },
    );
  }

  int _getGridColumns(int participantCount) {
    if (participantCount <= 1) return 1;
    if (participantCount <= 4) return 2;
    if (participantCount <= 9) return 3;
    return 4;
  }
}

class _ParticipantTile extends StatelessWidget {
  final CallParticipant participant;
  final bool isVideoCall;
  final Function(bool)? onMuteToggle;
  final Function(bool)? onVideoToggle;
  final VoidCallback? onRemove;

  const _ParticipantTile({
    required this.participant,
    required this.isVideoCall,
    this.onMuteToggle,
    this.onVideoToggle,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: participant.isScreenSharing
              ? AppColors.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // Video placeholder or avatar
          Center(
            child: isVideoCall && participant.isVideoEnabled
                ? _buildVideoPlaceholder()
                : _buildAvatar(),
          ),

          // Participant info overlay
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      participant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (participant.isMuted)
                    const Icon(Icons.mic_off, color: Colors.red, size: 16),
                  if (!participant.isVideoEnabled && isVideoCall)
                    const Icon(Icons.videocam_off, color: Colors.red, size: 16),
                ],
              ),
            ),
          ),

          // Control buttons
          if (onMuteToggle != null || onVideoToggle != null || onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (onMuteToggle != null)
                    _buildControlButton(
                      icon: participant.isMuted ? Icons.mic_off : Icons.mic,
                      color: participant.isMuted ? Colors.red : Colors.white,
                      onPressed: () => onMuteToggle!(!participant.isMuted),
                    ),
                  if (onVideoToggle != null && isVideoCall)
                    _buildControlButton(
                      icon: participant.isVideoEnabled
                          ? Icons.videocam
                          : Icons.videocam_off,
                      color: participant.isVideoEnabled
                          ? Colors.white
                          : Colors.red,
                      onPressed: () =>
                          onVideoToggle!(!participant.isVideoEnabled),
                    ),
                  if (onRemove != null)
                    _buildControlButton(
                      icon: Icons.close,
                      color: Colors.red,
                      onPressed: onRemove!,
                    ),
                ],
              ),
            ),

          // Screen sharing indicator
          if (participant.isScreenSharing)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.screen_share, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Sharing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.videocam, color: Colors.white54, size: 48),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 40,
      backgroundColor: AppColors.primary.withOpacity(0.8),
      child: Text(
        participant.name.isNotEmpty ? participant.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 16),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
