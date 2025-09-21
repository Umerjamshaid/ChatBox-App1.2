// lib/services/call_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chatbox/models/user_model.dart';
import 'package:chatbox/services/notification_service.dart';
import 'package:chatbox/widgets/call_notification_overlay.dart';
import 'package:chatbox/screens/calls/voice_call_screen.dart';
import 'package:chatbox/screens/calls/video_call_screen.dart';

enum CallType { voice, video }

enum CallStatus { ringing, connected, ended, missed }

class CallParticipant {
  final String id;
  final String name;
  final bool isMuted;
  final bool isVideoEnabled;
  final bool isScreenSharing;

  const CallParticipant({
    required this.id,
    required this.name,
    this.isMuted = false,
    this.isVideoEnabled = true,
    this.isScreenSharing = false,
  });

  CallParticipant copyWith({
    String? id,
    String? name,
    bool? isMuted,
    bool? isVideoEnabled,
    bool? isScreenSharing,
  }) {
    return CallParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      isMuted: isMuted ?? this.isMuted,
      isVideoEnabled: isVideoEnabled ?? this.isVideoEnabled,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
    );
  }
}

class CallSession {
  final String id;
  final CallType type;
  final List<CallParticipant> participants;
  final DateTime startTime;
  CallStatus status;

  CallSession({
    required this.id,
    required this.type,
    required this.participants,
    required this.startTime,
    this.status = CallStatus.ringing,
  });
}

class CallHistory {
  final String id;
  final String callerId;
  final String callerName;
  final List<String> participants;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int duration; // in seconds

  const CallHistory({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.participants,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.duration = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'callerId': callerId,
      'callerName': callerName,
      'participants': participants,
      'type': type.toString(),
      'status': status.toString(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration,
    };
  }

  factory CallHistory.fromJson(Map<String, dynamic> json) {
    return CallHistory(
      id: json['id'],
      callerId: json['callerId'],
      callerName: json['callerName'],
      participants: List<String>.from(json['participants'] ?? []),
      type: CallType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => CallType.voice,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => CallStatus.ended,
      ),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'] ?? 0,
    );
  }
}

class CallService {
  static const String _callHistoryKey = 'call_history';

  final SharedPreferences _prefs;
  final NotificationService _notificationService;

  // Call state
  CallSession? _currentCall;
  bool _isMuted = false;
  bool _isVideoEnabled = true;
  bool _isSpeakerOn = false;
  bool _isScreenSharing = false;
  bool _isRecording = false;

  // Network and quality monitoring
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  List<ConnectivityResult> _currentConnectivity = [ConnectivityResult.none];
  int _networkQuality = 5; // 1-5 scale (5 being best)
  Timer? _qualityCheckTimer;

  // Callbacks
  Function(CallHistory)? _onCallEnded;
  Function(CallSession)? _onIncomingCall;
  Function(ConnectivityResult)? _onConnectivityChanged;
  Function(int)? _onQualityChanged;

  // Timer for call duration
  Timer? _callTimer;

  // Incoming call overlay
  OverlayEntry? _incomingCallOverlay;

  CallService(this._prefs, this._notificationService) {
    _initialize();
  }

  Future<void> _initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize connectivity monitoring
    await _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    // Get initial connectivity status
    final result = await _connectivity.checkConnectivity();
    _currentConnectivity = result;

    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _currentConnectivity = results;
      // Use the first (primary) connectivity result
      if (results.isNotEmpty) {
        _onConnectivityChanged?.call(results.first);
      }
      _updateNetworkQuality();
    });
  }

  void _updateNetworkQuality() {
    // Simulate network quality based on connectivity type
    // In a real implementation, this would measure actual latency, packet loss, etc.
    final primaryConnectivity = _currentConnectivity.isNotEmpty
        ? _currentConnectivity.first
        : ConnectivityResult.none;

    switch (primaryConnectivity) {
      case ConnectivityResult.wifi:
        _networkQuality = 5; // Excellent WiFi
        break;
      case ConnectivityResult.mobile:
        _networkQuality = 3; // Variable mobile quality
        break;
      case ConnectivityResult.ethernet:
        _networkQuality = 5; // Excellent Ethernet
        break;
      case ConnectivityResult.vpn:
        _networkQuality = 4; // Good VPN
        break;
      case ConnectivityResult.none:
        _networkQuality = 1; // No connection
        break;
      default:
        _networkQuality = 2; // Unknown/poor
    }

    _onQualityChanged?.call(_networkQuality);
  }

  void _startQualityMonitoring() {
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateNetworkQuality();
    });
  }

  void _stopQualityMonitoring() {
    _qualityCheckTimer?.cancel();
    _qualityCheckTimer = null;
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.phone,
    ].request();
  }

  Future<bool> requestScreenSharePermissions() async {
    // Request screen capture permission (system overlay permission may also be needed)
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  Future<bool> requestRecordingPermissions() async {
    // Request microphone and storage permissions for recording
    final micStatus = await Permission.microphone.request();
    final storageStatus = await Permission.storage.request();
    return micStatus.isGranted && storageStatus.isGranted;
  }

  // Public API

  Future<bool> initializeCallService() async {
    // Initialize call service (placeholder for future Stream Video integration)
    return true;
  }

  Future<CallSession?> startCall({
    required List<String> participantIds,
    required CallType type,
    String? callId,
  }) async {
    try {
      final session = CallSession(
        id: callId ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        participants: participantIds
            .map((id) => CallParticipant(id: id, name: id))
            .toList(),
        startTime: DateTime.now(),
        status: CallStatus.connected,
      );

      _currentCall = session;

      // Start call timer
      _startCallTimer();

      // Start network quality monitoring
      _startQualityMonitoring();

      // Simulate call connection
      await Future.delayed(const Duration(seconds: 1));

      return session;
    } catch (e) {
      print('Failed to start call: $e');
      return null;
    }
  }

  Future<bool> joinCall(String callId) async {
    try {
      // Simulate joining call
      final session = CallSession(
        id: callId,
        type: CallType.voice, // Default, would be determined from call data
        participants: [],
        startTime: DateTime.now(),
        status: CallStatus.connected,
      );

      _currentCall = session;
      _startCallTimer();

      return true;
    } catch (e) {
      print('Failed to join call: $e');
      return false;
    }
  }

  Future<void> endCall() async {
    if (_currentCall != null) {
      final history = CallHistory(
        id: _currentCall!.id,
        callerId: _currentCall!.participants.isNotEmpty
            ? _currentCall!.participants.first.id
            : 'unknown',
        callerName: _currentCall!.participants.isNotEmpty
            ? _currentCall!.participants.first.name
            : 'Unknown',
        participants: _currentCall!.participants.map((p) => p.id).toList(),
        type: _currentCall!.type,
        status: CallStatus.ended,
        startTime: _currentCall!.startTime,
        endTime: DateTime.now(),
        duration: DateTime.now().difference(_currentCall!.startTime).inSeconds,
      );

      _saveCallHistory(history);
      _onCallEnded?.call(history);

      _currentCall = null;
      _stopCallTimer();
      _stopQualityMonitoring();
    }
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Update call duration
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    // In a real implementation, this would control microphone
  }

  Future<void> toggleVideo() async {
    _isVideoEnabled = !_isVideoEnabled;
    // In a real implementation, this would control camera
  }

  Future<void> toggleSpeaker() async {
    _isSpeakerOn = !_isSpeakerOn;
    // Implementation depends on platform-specific audio routing
  }

  Future<void> toggleScreenShare() async {
    if (!_isScreenSharing) {
      // Request permissions before starting screen share
      final hasPermission = await requestScreenSharePermissions();
      if (!hasPermission) {
        throw Exception('Screen sharing permission denied');
      }
    }

    _isScreenSharing = !_isScreenSharing;

    // In a real implementation with GetStream Video SDK, this would:
    // - Start/stop screen capture
    // - Publish screen share stream to participants
    // - Handle screen share events

    // For now, just toggle the state
    // The UI will reflect this change
  }

  Future<void> switchCamera() async {
    // In a real implementation, this would switch camera
  }

  Future<void> toggleRecording() async {
    if (!_isRecording) {
      // Request permissions before starting recording
      final hasPermission = await requestRecordingPermissions();
      if (!hasPermission) {
        throw Exception('Recording permission denied');
      }
    }

    _isRecording = !_isRecording;

    // In a real implementation with GetStream Video SDK, this would:
    // - Start/stop call recording
    // - Save recording to device storage
    // - Handle recording events

    // For now, just toggle the state
    // The UI will reflect this change
  }

  // Group call management
  Future<bool> addParticipant(
    String participantId,
    String participantName,
  ) async {
    if (_currentCall == null) return false;

    try {
      final newParticipant = CallParticipant(
        id: participantId,
        name: participantName,
      );

      _currentCall!.participants.add(newParticipant);

      // In a real implementation, this would send an invitation to the participant
      // and handle the WebRTC connection

      return true;
    } catch (e) {
      print('Failed to add participant: $e');
      return false;
    }
  }

  Future<bool> removeParticipant(String participantId) async {
    if (_currentCall == null) return false;

    try {
      _currentCall!.participants.removeWhere((p) => p.id == participantId);

      // In a real implementation, this would close the WebRTC connection
      // for the removed participant

      return true;
    } catch (e) {
      print('Failed to remove participant: $e');
      return false;
    }
  }

  Future<void> muteParticipant(String participantId, bool muted) async {
    if (_currentCall == null) return;

    final participantIndex = _currentCall!.participants.indexWhere(
      (p) => p.id == participantId,
    );
    if (participantIndex >= 0) {
      _currentCall!.participants[participantIndex] = _currentCall!
          .participants[participantIndex]
          .copyWith(isMuted: muted);
    }
  }

  Future<void> toggleParticipantVideo(
    String participantId,
    bool enabled,
  ) async {
    if (_currentCall == null) return;

    final participantIndex = _currentCall!.participants.indexWhere(
      (p) => p.id == participantId,
    );
    if (participantIndex >= 0) {
      _currentCall!.participants[participantIndex] = _currentCall!
          .participants[participantIndex]
          .copyWith(isVideoEnabled: enabled);
    }
  }

  // Check if current call is a group call
  bool get isGroupCall => (_currentCall?.participants.length ?? 0) > 1;

  // Get active participants (excluding self if needed)
  List<CallParticipant> get activeParticipants =>
      _currentCall?.participants ?? [];

  // Call history management
  Future<List<CallHistory>> getCallHistory() async {
    try {
      final historyJson = _prefs.getString(_callHistoryKey);
      if (historyJson == null) return [];

      final historyList = List<Map<String, dynamic>>.from(
        (jsonDecode(historyJson) as List).map(
          (item) => item as Map<String, dynamic>,
        ),
      );

      return historyList.map((json) => CallHistory.fromJson(json)).toList();
    } catch (e) {
      print('Error loading call history: $e');
      return [];
    }
  }

  Future<void> _saveCallHistory(CallHistory history) async {
    try {
      final historyList = await getCallHistory();
      historyList.insert(0, history); // Add to beginning

      // Keep only last 100 calls
      if (historyList.length > 100) {
        historyList.removeRange(100, historyList.length);
      }

      final historyJson = jsonEncode(
        historyList.map((h) => h.toJson()).toList(),
      );
      await _prefs.setString(_callHistoryKey, historyJson);
    } catch (e) {
      print('Error saving call history: $e');
    }
  }

  Future<void> clearCallHistory() async {
    await _prefs.remove(_callHistoryKey);
  }

  // Getters
  CallSession? get currentCall => _currentCall;
  bool get isMuted => _isMuted;
  bool get isVideoEnabled => _isVideoEnabled;
  bool get isSpeakerOn => _isSpeakerOn;
  bool get isScreenSharing => _isScreenSharing;
  bool get isRecording => _isRecording;

  // Network getters
  List<ConnectivityResult> get currentConnectivity => _currentConnectivity;
  int get networkQuality => _networkQuality;
  ConnectivityResult get primaryConnectivity => _currentConnectivity.isNotEmpty
      ? _currentConnectivity.first
      : ConnectivityResult.none;

  // Callbacks
  set onCallEnded(Function(CallHistory) callback) {
    _onCallEnded = callback;
  }

  set onIncomingCall(Function(CallSession) callback) {
    _onIncomingCall = callback;
  }

  set onConnectivityChanged(Function(ConnectivityResult) callback) {
    _onConnectivityChanged = callback;
  }

  set onQualityChanged(Function(int) callback) {
    _onQualityChanged = callback;
  }

  // Incoming call notification methods
  Future<void> showIncomingCallNotification({
    required String callerId,
    required String callerName,
    required CallType callType,
    required String callId,
  }) async {
    await _notificationService.showIncomingCallNotification(
      callerId: callerId,
      callerName: callerName,
      callType: callType,
      callId: callId,
    );
  }

  Future<void> cancelIncomingCallNotification(String callId) async {
    await _notificationService.cancelIncomingCallNotification(callId);
  }

  Future<void> showMissedCallNotification({
    required String callerId,
    required String callerName,
    required CallType callType,
  }) async {
    await _notificationService.showMissedCallNotification(
      callerId: callerId,
      callerName: callerName,
      callType: callType,
    );
  }

  // Simulate incoming call (for testing)
  Future<void> simulateIncomingCall(
    BuildContext context, {
    required String callerId,
    required String callerName,
    required CallType callType,
  }) async {
    final callId = 'incoming_${DateTime.now().millisecondsSinceEpoch}';

    // Show notification
    await showIncomingCallNotification(
      callerId: callerId,
      callerName: callerName,
      callType: callType,
      callId: callId,
    );

    // Show overlay
    showIncomingCallOverlay(
      context,
      callerId: callerId,
      callerName: callerName,
      callType: callType,
      callId: callId,
      onAccept: () async {
        hideIncomingCallOverlay();
        await cancelIncomingCallNotification(callId);

        // Navigate to call screen
        final route = callType == CallType.video
            ? MaterialPageRoute(
                builder: (context) => VideoCallScreen(
                  participantIds: [callerId],
                  callId: callId,
                  isIncoming: true,
                ),
              )
            : MaterialPageRoute(
                builder: (context) => VoiceCallScreen(
                  participantIds: [callerId],
                  callId: callId,
                  isIncoming: true,
                ),
              );

        Navigator.push(context, route);
      },
      onDecline: () async {
        hideIncomingCallOverlay();
        await cancelIncomingCallNotification(callId);

        // Show missed call notification
        await showMissedCallNotification(
          callerId: callerId,
          callerName: callerName,
          callType: callType,
        );
      },
    );
  }

  // Show incoming call overlay
  void showIncomingCallOverlay(
    BuildContext context, {
    required String callerId,
    required String callerName,
    required CallType callType,
    required String callId,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    _incomingCallOverlay?.remove();

    _incomingCallOverlay = OverlayEntry(
      builder: (context) => CallNotificationOverlay(
        callerId: callerId,
        callerName: callerName,
        callType: callType,
        callId: callId,
        onAccept: onAccept,
        onDecline: onDecline,
      ),
    );

    Overlay.of(context).insert(_incomingCallOverlay!);
  }

  // Hide incoming call overlay
  void hideIncomingCallOverlay() {
    _incomingCallOverlay?.remove();
    _incomingCallOverlay = null;
  }

  // Cleanup
  void dispose() {
    _stopCallTimer();
    hideIncomingCallOverlay();
  }
}
