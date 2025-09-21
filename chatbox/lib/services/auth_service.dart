// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatbox/services/stream_chat_service.dart';
import 'package:chatbox/services/token_service.dart';
import 'package:chatbox/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamChatService _streamService = StreamChatService();

  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final currentUser = _auth.currentUser;
    return currentUser != null;
  }

  // Get current user as ChatUser
  Future<ChatUser?> getCurrentChatUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    // Try to get user from GetStream
    try {
      final streamUser = _streamService.client.state.currentUser;
      if (streamUser != null) {
        return ChatUser.fromStreamUser(streamUser);
      }
    } catch (e) {
      // If GetStream user not found, create from Firebase
    }

    return ChatUser.fromFirebaseUser(firebaseUser);
  }

  // Sign in with email and password
  Future<ChatUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final chatUser = ChatUser.fromFirebaseUser(userCredential.user!);

      // Try to connect to GetStream
      try {
        print(
          'AuthService: Generating token for user ${userCredential.user!.uid}',
        );
        final token = await TokenService.generateToken(
          userCredential.user!.uid,
        );
        print('AuthService: Token generated successfully');

        print('AuthService: Connecting to GetStream...');
        await _streamService.connectUser(
          userCredential.user!.uid,
          token,
          name: chatUser.name,
        );
        print('AuthService: Successfully connected to GetStream');

        // Update user status to online
        await updateUserStatus(UserStatus.online);
        print('AuthService: User status updated to online');
      } catch (streamError) {
        // Log the error but don't fail the login
        print('AuthService: GetStream connection failed: $streamError');
        print('AuthService: Continuing with Firebase authentication only');
        print(
          'AuthService: Note: Chat features will be limited without GetStream connection',
        );
      }

      return chatUser;
    } catch (e) {
      throw Exception('Failed to sign in: ${_getErrorMessage(e)}');
    }
  }

  // Sign up with email and password
  Future<ChatUser?> signUpWithEmailAndPassword(
    String email,
    String password,
    String name, {
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update Firebase user profile
      await userCredential.user!.updateDisplayName(name);
      if (profileImageUrl != null) {
        await userCredential.user!.updatePhotoURL(profileImageUrl);
      }

      // Create ChatUser object
      final chatUser = ChatUser(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        image: profileImageUrl,
        bio: bio,
        status: UserStatus.online,
        createdAt: DateTime.now(),
      );

      // Try to connect to GetStream
      try {
        print(
          'AuthService: Generating token for new user ${userCredential.user!.uid}',
        );
        final token = await TokenService.generateToken(
          userCredential.user!.uid,
        );
        print('AuthService: Token generated for signup');

        print('AuthService: Connecting new user to GetStream...');
        await _streamService.connectUser(
          userCredential.user!.uid,
          token,
          name: name,
        );
        print('AuthService: New user successfully connected to GetStream');
      } catch (streamError) {
        // Log the error but don't fail the signup
        print(
          'AuthService: GetStream connection failed during signup: $streamError',
        );
        print('AuthService: Continuing with Firebase authentication only');
        print(
          'AuthService: Note: Chat features will be limited without GetStream connection',
        );
      }

      return chatUser;
    } catch (e) {
      throw Exception('Failed to sign up: ${_getErrorMessage(e)}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update status to offline before disconnecting
      await updateUserStatus(UserStatus.offline);

      await _streamService.disconnectUser();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Update user status
  Future<void> updateUserStatus(UserStatus status) async {
    try {
      final currentUser = _streamService.client.state.currentUser;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          extraData: {
            ...currentUser.extraData,
            'status': status.toString(),
            'lastSeen': status == UserStatus.offline
                ? DateTime.now().toIso8601String()
                : null,
          },
        );
        await _streamService.client.updateUser(updatedUser);
      }
    } catch (e) {
      // Silently fail for status updates
      print('Failed to update user status: $e');
    }
  }

  // Update user profile
  Future<ChatUser?> updateProfile({
    String? name,
    String? bio,
    String? profileImageUrl,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      // Update Firebase profile
      if (name != null) {
        await firebaseUser.updateDisplayName(name);
      }
      if (profileImageUrl != null) {
        await firebaseUser.updatePhotoURL(profileImageUrl);
      }

      // Update GetStream user
      final currentUser = _streamService.client.state.currentUser;
      if (currentUser != null) {
        final updatedUser = currentUser.copyWith(
          name: name ?? currentUser.name,
          image: profileImageUrl ?? currentUser.image,
          extraData: {
            ...currentUser.extraData,
            'bio': bio ?? currentUser.extraData['bio'],
          },
        );
        await _streamService.client.updateUser(updatedUser);

        return ChatUser.fromStreamUser(updatedUser);
      }

      return ChatUser.fromFirebaseUser(firebaseUser);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get Firebase user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream for auth state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Check if user is connected to both Firebase and GetStream
  Future<bool> isUserFullyConnected() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return false;

    // Check if GetStream is connected
    return _streamService.isConnected;
  }

  // Check if user is connected to GetStream
  bool isConnectedToStream() {
    return _streamService.isConnected;
  }

  // Get connection status for debugging
  Map<String, dynamic> getConnectionStatus() {
    return {
      'firebaseUser': _auth.currentUser?.uid,
      'streamConnected': _streamService.isConnected,
      'streamUser': _streamService.currentUser?.id,
      'firebaseInitialized': _auth.app != null,
    };
  }

  // Helper method to get user-friendly error messages
  String _getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email.';
        case 'wrong-password':
          return 'Wrong password provided.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'weak-password':
          return 'Password is too weak.';
        case 'invalid-email':
          return 'Invalid email address.';
        default:
          return error.message ?? 'Authentication failed.';
      }
    }
    return error.toString();
  }
}
