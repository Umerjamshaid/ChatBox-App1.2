// lib/widgets/voice_recorder.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';

class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({super.key});

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

class _VoiceRecorderState extends State<VoiceRecorder>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  int _recordingDuration = 0;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording indicator
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isRecording ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isRecording ? Colors.red : AppColors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? Colors.red : AppColors.primary)
                            .withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Recording status
          Text(
            _isRecording ? 'Recording...' : 'Tap to start recording',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          // Recording duration
          if (_isRecording)
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button
              if (_isRecording)
                TextButton.icon(
                  onPressed: _cancelRecording,
                  icon: Icon(Icons.close, color: AppColors.danger),
                  label: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),

              const SizedBox(width: 24),

              // Record/Stop button
              ElevatedButton.icon(
                onPressed: _toggleRecording,
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                ),
                label: Text(
                  _isRecording ? 'Stop' : 'Record',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording
                      ? AppColors.danger
                      : AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),

              const SizedBox(width: 24),

              // Send button
              if (_isRecording)
                TextButton.icon(
                  onPressed: _sendRecording,
                  icon: Icon(Icons.send, color: AppColors.primary),
                  label: Text(
                    'Send',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Instructions
          Text(
            _isRecording
                ? 'Tap stop when finished, or cancel to discard'
                : 'Hold the record button or tap to start recording',
            style: TextStyle(fontSize: 12, color: AppColors.grey600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startRecording();
    } else {
      _stopRecording();
    }
  }

  void _startRecording() {
    _recordingDuration = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration++;
      });
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    _timer = null;
  }

  void _cancelRecording() {
    _stopRecording();
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
    // Navigate back or close the recorder
    Navigator.of(context).pop();
  }

  void _sendRecording() {
    _stopRecording();
    // TODO: Send the recorded audio file
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voice message sent!')));
    Navigator.of(context).pop();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
