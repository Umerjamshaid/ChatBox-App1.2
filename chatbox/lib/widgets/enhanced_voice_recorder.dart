// lib/widgets/enhanced_voice_recorder.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:chatbox/constants/colors.dart';

class EnhancedVoiceRecorder extends StatefulWidget {
  final Function(String)? onRecordingComplete;
  final Function()? onCancel;

  const EnhancedVoiceRecorder({
    super.key,
    this.onRecordingComplete,
    this.onCancel,
  });

  @override
  State<EnhancedVoiceRecorder> createState() => _EnhancedVoiceRecorderState();
}

class _EnhancedVoiceRecorderState extends State<EnhancedVoiceRecorder>
    with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  Timer? _timer;
  Timer? _waveformTimer;

  // Waveform data
  List<double> _waveformData = [];
  double _currentAmplitude = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize waveform data
    _waveformData = List.generate(50, (index) => Random().nextDouble() * 0.3);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveformTimer?.cancel();
    _pulseController.dispose();
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
          // Header
          Row(
            children: [
              Icon(
                Icons.mic,
                color: _isRecording ? Colors.red : AppColors.grey600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                _isRecording
                    ? (_isPaused ? 'Recording Paused' : 'Recording...')
                    : 'Voice Message',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.grey600),
                onPressed: _cancelRecording,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Recording visualization
          if (_isRecording) ...[
            // Waveform visualization
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(300, 60),
                  painter: WaveformPainter(
                    waveformData: _waveformData,
                    color: _isPaused ? AppColors.grey500 : Colors.red,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recording duration
            Text(
              _formatDuration(_recordingDuration),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: _isPaused ? AppColors.grey600 : Colors.red,
              ),
            ),

            const SizedBox(height: 8),

            // Recording quality indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.circle, color: _getQualityColor(), size: 8),
                const SizedBox(width: 8),
                Text(
                  _getQualityText(),
                  style: TextStyle(fontSize: 12, color: AppColors.grey600),
                ),
              ],
            ),
          ] else ...[
            // Recording instructions
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.mic_none, size: 48, color: AppColors.grey500),
                  const SizedBox(height: 16),
                  Text(
                    'Tap and hold to record',
                    style: TextStyle(fontSize: 16, color: AppColors.grey600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Release to send, slide up to cancel',
                    style: TextStyle(fontSize: 12, color: AppColors.grey500),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isRecording) ...[
                // Pause/Resume button
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPaused ? Icons.play_arrow : Icons.pause,
                      color: AppColors.onSurface,
                    ),
                    onPressed: _togglePause,
                  ),
                ),

                const SizedBox(width: 24),

                // Stop/Send button
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isRecording && !_isPaused
                          ? _pulseAnimation.value
                          : 1.0,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isPaused ? AppColors.grey500 : Colors.red,
                          shape: BoxShape.circle,
                          boxShadow: _isRecording && !_isPaused
                              ? [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ]
                              : null,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.stop, color: Colors.white, size: 32),
                          onPressed: _stopRecording,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 24),

                // Cancel button
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.delete, color: AppColors.danger),
                    onPressed: _cancelRecording,
                  ),
                ),
              ] else ...[
                // Start recording button
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 40),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Instructions
          Text(
            _getInstructionText(),
            style: TextStyle(fontSize: 12, color: AppColors.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _recordingDuration = 0;
    });

    // Start duration timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          _recordingDuration++;
        });
      }
    });

    // Start waveform simulation
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted && !_isPaused) {
        setState(() {
          // Simulate audio amplitude changes
          _currentAmplitude = Random().nextDouble();
          _waveformData.removeAt(0);
          _waveformData.add(_currentAmplitude);
        });
      }
    });
  }

  void _stopRecording() {
    _timer?.cancel();
    _waveformTimer?.cancel();

    if (_recordingDuration > 0) {
      // TODO: Save recording and get file path
      final recordingPath =
          'recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      if (widget.onRecordingComplete != null) {
        widget.onRecordingComplete!(recordingPath);
      }
    }

    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _cancelRecording() {
    _timer?.cancel();
    _waveformTimer?.cancel();

    setState(() {
      _isRecording = false;
      _isPaused = false;
      _recordingDuration = 0;
    });

    if (widget.onCancel != null) {
      widget.onCancel!();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getQualityColor() {
    if (_currentAmplitude > 0.7) return Colors.green;
    if (_currentAmplitude > 0.4) return Colors.yellow;
    return Colors.red;
  }

  String _getQualityText() {
    if (_currentAmplitude > 0.7) return 'Good';
    if (_currentAmplitude > 0.4) return 'Fair';
    return 'Low';
  }

  String _getInstructionText() {
    if (_isRecording) {
      if (_isPaused) {
        return 'Tap play to resume recording';
      }
      return 'Tap stop to finish, pause to hold, or cancel to discard';
    }
    return 'Tap and hold the microphone to start recording';
  }
}

class WaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;

  WaveformPainter({required this.waveformData, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    final barWidth = size.width / waveformData.length;

    for (int i = 0; i < waveformData.length; i++) {
      final barHeight = waveformData[i] * size.height;
      final x = i * barWidth + barWidth / 2;
      final topY = centerY - barHeight / 2;
      final bottomY = centerY + barHeight / 2;

      canvas.drawLine(Offset(x, topY), Offset(x, bottomY), paint);
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData ||
        oldDelegate.color != color;
  }
}
