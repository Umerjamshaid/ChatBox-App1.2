// lib/services/error_handler.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

/// Comprehensive error handling service for ChatBox
class ErrorHandler {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // Error types
  static const String networkError = 'network_error';
  static const String authenticationError = 'auth_error';
  static const String streamError = 'stream_error';
  static const String firebaseError = 'firebase_error';
  static const String permissionError = 'permission_error';
  static const String validationError = 'validation_error';
  static const String unknownError = 'unknown_error';

  // Error messages
  static const Map<String, String> errorMessages = {
    networkError:
        'Network connection error. Please check your internet connection.',
    authenticationError: 'Authentication failed. Please sign in again.',
    streamError: 'Chat service error. Please try again.',
    firebaseError: 'Database error. Please try again.',
    permissionError:
        'Permission denied. Please grant the required permissions.',
    validationError: 'Invalid input. Please check your data.',
    unknownError: 'An unexpected error occurred. Please try again.',
  };

  ErrorHandler() {
    _initializeConnectivityMonitoring();
  }

  /// Initialize connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _handleConnectivityChange(results);
    });
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Check if any result indicates connectivity
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnection) {
      _handleOnline();
    } else {
      _handleOffline();
    }
  }

  /// Handle offline state
  void _handleOffline() {
    print('Device is offline');
    // Emit offline event or show offline banner
  }

  /// Handle online state
  void _handleOnline() {
    print('Device is online');
    // Emit online event or hide offline banner
  }

  /// Handle different types of errors
  String handleError(dynamic error) {
    if (error is StreamChatError) {
      return _handleStreamError(error);
    } else if (error is FirebaseException) {
      return _handleFirebaseError(error);
    } else if (error is SocketException) {
      return _handleNetworkError(error);
    } else if (error is FormatException) {
      return errorMessages[validationError]!;
    } else {
      return _handleGenericError(error);
    }
  }

  /// Handle GetStream specific errors
  String _handleStreamError(StreamChatError error) {
    // StreamChatError doesn't have errorCode in newer versions
    // Use the error message to determine the type
    final message = error.message?.toLowerCase() ?? '';

    if (message.contains('authentication') ||
        message.contains('unauthorized')) {
      return errorMessages[authenticationError]!;
    } else if (message.contains('permission') ||
        message.contains('forbidden')) {
      return errorMessages[permissionError]!;
    } else if (message.contains('not found')) {
      return 'Resource not found.';
    } else {
      return errorMessages[streamError]!;
    }
  }

  /// Handle Firebase specific errors
  String _handleFirebaseError(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return errorMessages[permissionError]!;
      case 'unavailable':
        return errorMessages[networkError]!;
      case 'cancelled':
        return 'Operation was cancelled.';
      case 'deadline-exceeded':
        return 'Operation timed out. Please try again.';
      default:
        return errorMessages[firebaseError]!;
    }
  }

  /// Handle network errors
  String _handleNetworkError(SocketException error) {
    return errorMessages[networkError]!;
  }

  /// Handle generic errors
  String _handleGenericError(dynamic error) {
    print('Unhandled error: $error');
    return errorMessages[unknownError]!;
  }

  /// Check if error is retryable
  bool isRetryableError(dynamic error) {
    if (error is StreamChatError) {
      // Retry for network-related errors based on message content
      final message = error.message?.toLowerCase() ?? '';
      return message.contains('network') ||
          message.contains('timeout') ||
          message.contains('connection');
    } else if (error is FirebaseException) {
      // Retry for network-related Firebase errors
      return [
        'unavailable',
        'deadline-exceeded',
        'cancelled',
      ].contains(error.code);
    } else if (error is SocketException) {
      return true;
    }
    return false;
  }

  /// Get user-friendly error message
  String getErrorMessage(String errorType) {
    return errorMessages[errorType] ?? errorMessages[unknownError]!;
  }

  /// Log error for debugging
  void logError(dynamic error, {String? context, StackTrace? stackTrace}) {
    final errorInfo = {
      'error': error.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
      'stackTrace': stackTrace?.toString(),
    };

    print('Error logged: $errorInfo');

    // In a production app, you would send this to a logging service
    // like Firebase Crashlytics, Sentry, etc.
  }

  /// Handle async operation with error handling
  Future<T?> handleAsyncOperation<T>(
    Future<T> Function() operation, {
    String? context,
    bool showUserMessage = true,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      logError(error, context: context, stackTrace: stackTrace);

      if (showUserMessage) {
        final message = handleError(error);
        // In a real app, you would show this to the user via a snackbar or dialog
        print('User message: $message');
      }

      return null;
    }
  }

  /// Retry operation with exponential backoff
  Future<T?> retryOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    String? context,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;

        if (attempt >= maxRetries || !isRetryableError(error)) {
          logError(error, context: context);
          rethrow;
        }

        print('Retrying operation in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      }
    }

    return null;
  }

  /// Check network connectivity
  Future<bool> isConnected() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Get current connectivity status
  Future<ConnectivityResult> getConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      // Return the first result or none if empty
      return results.isNotEmpty ? results.first : ConnectivityResult.none;
    } catch (e) {
      return ConnectivityResult.none;
    }
  }

  /// Clean up resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Error reporting service for production
class ErrorReportingService {
  static final ErrorReportingService _instance =
      ErrorReportingService._internal();
  factory ErrorReportingService() => _instance;
  ErrorReportingService._internal();

  /// Report error to external service
  Future<void> reportError(
    dynamic error, {
    String? context,
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) async {
    final errorReport = {
      'error': error.toString(),
      'context': context,
      'stackTrace': stackTrace?.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'additionalData': additionalData,
    };

    // In production, send to error reporting service
    print('Error report: $errorReport');
  }

  /// Report non-fatal error
  Future<void> reportNonFatal(
    String message, {
    Map<String, dynamic>? data,
  }) async {
    final report = {
      'message': message,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'type': 'non_fatal',
    };

    print('Non-fatal report: $report');
  }
}
