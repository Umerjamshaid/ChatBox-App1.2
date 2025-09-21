// lib/widgets/call_notification_overlay.dart
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';
import 'package:chatbox/services/call_service.dart';

class CallNotificationOverlay extends StatefulWidget {
  final String callerId;
  final String callerName;
  final CallType callType;
  final String callId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const CallNotificationOverlay({
    super.key,
    required this.callerId,
    required this.callerName,
    required this.callType,
    required this.callId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<CallNotificationOverlay> createState() =>
      _CallNotificationOverlayState();
}

class _CallNotificationOverlayState extends State<CallNotificationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8),
      child: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Caller avatar
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withOpacity(0.8),
                              AppColors.primary.withOpacity(0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.callType == CallType.video
                              ? Icons.videocam
                              : Icons.call,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Caller name
                      Text(
                        widget.callerName,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Call type
                      Text(
                        '${widget.callType == CallType.video ? 'Video' : 'Voice'} Call',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Incoming call text
                      Text(
                        'Incoming call...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Decline button
                          _buildActionButton(
                            icon: Icons.call_end,
                            label: 'Decline',
                            color: AppColors.danger,
                            onPressed: () {
                              _animationController.reverse().then((_) {
                                widget.onDecline();
                              });
                            },
                          ),

                          // Accept button
                          _buildActionButton(
                            icon: widget.callType == CallType.video
                                ? Icons.videocam
                                : Icons.call,
                            label: 'Accept',
                            color: AppColors.success,
                            onPressed: () {
                              _animationController.reverse().then((_) {
                                widget.onAccept();
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Reminder text
                      Text(
                        'Swipe up to dismiss',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 32),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
