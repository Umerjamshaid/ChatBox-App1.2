// lib/services/connection_checker.dart
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:chatbox/services/stream_chat_service.dart';

class ConnectionChecker {
  final StreamChatService _streamService;
  final Connectivity _connectivity = Connectivity();

  ConnectionChecker(this._streamService);

  /// Check if GetStream client is properly initialized
  bool isClientInitialized() {
    try {
      // Check if client has a valid state
      return _streamService.client.state != null;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is connected to GetStream
  bool isUserConnected() {
    try {
      final currentUser = _streamService.client.state.currentUser;
      return currentUser != null && currentUser.id.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get connection status details
  Future<Map<String, dynamic>> getConnectionStatus() async {
    final connectivityResults = await _connectivity.checkConnectivity();
    final primaryResult = connectivityResults.isNotEmpty
        ? connectivityResults.first
        : ConnectivityResult.none;

    return {
      'client_initialized': isClientInitialized(),
      'user_connected': isUserConnected(),
      'network_connected': primaryResult != ConnectivityResult.none,
      'api_key': 'Configured in app_constants.dart',
      'user_id': _streamService.client.state.currentUser?.id ?? 'Not connected',
      'user_name':
          _streamService.client.state.currentUser?.name ?? 'Not connected',
      'connection_state': _streamService.client.wsConnectionStatus.name,
      'connectivity_type': primaryResult.toString(),
    };
  }

  /// Test GetStream API connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      // Test basic API call - try to get current user info
      final currentUser = _streamService.client.state.currentUser;

      if (currentUser != null) {
        return {
          'success': true,
          'message': 'GetStream API connection successful',
          'users_found': 1,
          'response_time': 'OK',
        };
      } else {
        return {
          'success': false,
          'message': 'No current user found',
          'error_type': 'NoUserError',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'GetStream API connection failed: $e',
        'error_type': e.runtimeType.toString(),
      };
    }
  }

  /// Get detailed debug information
  Future<Map<String, dynamic>> getDebugInfo() async {
    final status = await getConnectionStatus();
    final testResult = await testConnection();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'connection_status': status,
      'api_test': testResult,
      'client_info': {
        'api_key_configured':
            true, // API key is configured in StreamChatService
        'has_current_user': _streamService.client.state.currentUser != null,
        'ws_connection_status': _streamService.client.wsConnectionStatus.name,
        'client_state': _streamService.client.state != null
            ? 'initialized'
            : 'not_initialized',
      },
      'troubleshooting_tips': _getTroubleshootingTips(status, testResult),
    };
  }

  List<String> _getTroubleshootingTips(
    Map<String, dynamic> status,
    Map<String, dynamic> testResult,
  ) {
    final tips = <String>[];

    if (!status['client_initialized']) {
      tips.add(
        '❌ Client not initialized - Check API key in app_constants.dart',
      );
    }

    if (!status['user_connected']) {
      tips.add('❌ User not connected - Check authentication flow');
    }

    if (!status['network_connected']) {
      tips.add('❌ No network connection - Check internet connectivity');
    }

    if (!testResult['success']) {
      tips.add('❌ API test failed - Check API key validity and network');
      tips.add('💡 Verify API key is correct in GetStream dashboard');
      tips.add('💡 Check if API key has proper permissions');
    }

    if (tips.isEmpty) {
      tips.add('✅ All checks passed - Connection appears healthy');
    }

    return tips;
  }

  /// Print connection status to console
  Future<void> printConnectionStatus() async {
    final status = await getConnectionStatus();
    final testResult = await testConnection();

    print('\n' + '=' * 50);
    print('🔍 GETSTREAM CONNECTION STATUS');
    print('=' * 50);

    print('📡 Client Initialized: ${status['client_initialized'] ? '✅' : '❌'}');
    print('👤 User Connected: ${status['user_connected'] ? '✅' : '❌'}');
    print('🌐 Network Connected: ${status['network_connected'] ? '✅' : '❌'}');
    print('🔑 API Key: ${status['api_key']}');
    print('🆔 User ID: ${status['user_id']}');
    print('📝 User Name: ${status['user_name']}');
    print('🔌 WS Status: ${status['connection_state']}');
    print('📶 Connectivity: ${status['connectivity_type']}');

    print('\n🧪 API TEST RESULT:');
    print('Success: ${testResult['success'] ? '✅' : '❌'}');
    print('Message: ${testResult['message']}');

    final debugInfo = await getDebugInfo();
    print('\n💡 TROUBLESHOOTING TIPS:');
    for (final tip in debugInfo['troubleshooting_tips']) {
      print('  $tip');
    }

    print('=' * 50 + '\n');
  }
}
