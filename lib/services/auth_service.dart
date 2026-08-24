import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:algebrix/core/utils/error_formatter.dart';
import 'package:algebrix/models/user_model.dart';

typedef GoogleSignOut = Future<void> Function();

/// Authentication service managing auth state, Provider state updates,
/// 6-digit OTP email verification, password recovery, and Supabase Auth.
class AuthService extends ChangeNotifier {
  final SupabaseClient? _customClient;
  final GoogleSignOut _googleSignOut;

  AuthService({SupabaseClient? client, GoogleSignOut? googleSignOut})
    : _customClient = client,
      _googleSignOut = googleSignOut ?? _defaultGoogleSignOut;

  static Future<void> _defaultGoogleSignOut() => GoogleSignIn().signOut();

  SupabaseClient? get _client {
    if (_customClient != null) return _customClient;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = true;

  UserModel? get currentUser => _currentUser ?? getCurrentUser();
  bool get isAuthenticated => (_client?.auth.currentUser != null) || _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sign up a new user with email, password, and display name.
  Future<AuthResponse?> signUpWithEmail(
    String email,
    String password, [
    String? name,
  ]) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: 'io.supabase.algebrix://login-callback/',
        data: {
          if (name != null && name.isNotEmpty) 'full_name': name,
          'xp': 0,
          'level': 1,
          'level_title': 'Math Beginner',
          'streak': 0,
        },
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Registration failed. Please try again.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Registration failed. Please try again.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Verify 6-digit email sign-up OTP code.
  Future<AuthResponse?> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      _isLoading = false;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.signup,
      );

      _currentUser = getCurrentUser();
      _isLoading = false;
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Invalid or expired verification code.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Invalid or expired verification code.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Resend 6-digit OTP code to email.
  Future<void> resendOTP({required String email}) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await client.auth.resend(
        email: email,
        type: OtpType.signup,
      );
      _isLoading = false;
      notifyListeners();
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Failed to resend code. Please wait a moment.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Failed to resend code. Please wait a moment.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sign in an existing user with email and password.
  Future<AuthResponse?> signInWithEmail(
    String email,
    String password,
  ) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _currentUser = getCurrentUser();
      _isLoading = false;
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Login failed. Please check your credentials.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Login failed. Please check your credentials.');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Native Google Sign-In popup flow.
  Future<bool> signInWithGoogle() async {
    return loginWithGoogle();
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      final client = _client;
      if (client != null) {
        if (idToken == null) {
          throw Exception('No ID Token returned from Google Sign-In.');
        }

        final authResponse = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (authResponse.user != null) {
          _currentUser = getCurrentUser();
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _currentUser = UserModel(
        id: googleUser.id,
        name: googleUser.displayName ?? 'Google Student',
        avatarUrl: googleUser.photoUrl,
        xp: 150,
        level: 2,
        levelTitle: 'Math Explorer',
        streak: 1,
        lastActive: DateTime.now(),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Google Sign-In failed. Please try again.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Request password reset 6-digit OTP code to email.
  Future<void> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.algebrix://reset-callback/',
      );
      _isLoading = false;
      notifyListeners();
    } on AuthException catch (e) {
      final msgLower = e.message.toLowerCase();
      if (msgLower.contains('user not found') || msgLower.contains('user_not_found') || e.statusCode == '404') {
        _errorMessage = 'No registered user found with this email address.';
      } else {
        _errorMessage = _parseAuthException(e, fallback: 'Failed to send reset code. Please check your email.');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('user not found') || errStr.contains('user_not_found')) {
        _errorMessage = 'No registered user found with this email address.';
      } else {
        _errorMessage = _parseGeneralException(e, fallback: 'Failed to send reset code. Please check your email.');
      }
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Verify 6-digit OTP code (supports OtpType.signup, OtpType.recovery, etc.).
  Future<AuthResponse?> verifyOTP({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      _isLoading = false;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: type,
      );

      _currentUser = getCurrentUser();
      _isLoading = false;
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Invalid or expired verification code.');
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Invalid or expired verification code.');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Update user password via client.auth.updateUser and sign out temporary session.
  Future<bool> updatePassword(String newPassword) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        await client.auth.signOut();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Failed to update password.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Failed to update password.');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Failed to update password.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Verify 6-digit password recovery OTP and set new password.
  Future<bool> verifyPasswordResetOTP({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final client = _client;
    if (client == null) {
      _errorMessage = 'Supabase client is not initialized.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await client.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      );

      if (response.session != null || response.user != null) {
        await client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
        await client.auth.signOut();
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _errorMessage = 'Invalid code or failed to reset password.';
      _isLoading = false;
      notifyListeners();
      return false;
    } on AuthException catch (e) {
      _errorMessage = _parseAuthException(e, fallback: 'Invalid code or failed to reset password.');
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _parseGeneralException(e, fallback: 'Invalid code or failed to reset password.');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Helper to convert Supabase AuthException to user-friendly messages.
  String _parseAuthException(AuthException e, {required String fallback}) {
    return ErrorFormatter.formatAuthError(e);
  }

  /// Helper to convert general exceptions to user-friendly messages.
  String _parseGeneralException(Object e, {required String fallback}) {
    return ErrorFormatter.formatAuthError(e);
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    Object? failure;
    StackTrace? failureStackTrace;
    final client = _client;
    if (client != null) {
      try {
        await client.auth.signOut();
      } catch (error, stackTrace) {
        failure = error;
        failureStackTrace = stackTrace;
      }
    }
    try {
      await _googleSignOut();
    } catch (error, stackTrace) {
      failure ??= error;
      failureStackTrace ??= stackTrace;
    }

    _currentUser = null;
    if (failure != null) {
      _errorMessage = _parseGeneralException(
        failure,
        fallback: 'Sign out failed. Please try again.',
      );
      notifyListeners();
      Error.throwWithStackTrace(failure, failureStackTrace!);
    }

    _errorMessage = null;
    notifyListeners();
  }

  /// Get current user mapped to [UserModel].
  UserModel? getCurrentUser() {
    final client = _client;
    final user = client?.auth.currentUser;
    if (user == null) return _currentUser;

    final metadata = user.userMetadata ?? {};
    return UserModel(
      id: user.id,
      name: metadata['full_name'] as String? ??
          metadata['name'] as String? ??
          user.email?.split('@').first ??
          'Learner',
      avatarUrl: metadata['avatar_url'] as String?,
      xp: (metadata['xp'] as num?)?.toInt() ?? 0,
      level: (metadata['level'] as num?)?.toInt() ?? 1,
      levelTitle: metadata['level_title'] as String? ?? 'Math Beginner',
      streak: (metadata['streak'] as num?)?.toInt() ?? 0,
      badges: (metadata['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      completedLessonIds: (metadata['completed_lesson_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      lastActive: DateTime.tryParse(user.lastSignInAt ?? '') ?? DateTime.now(),
    );
  }
}
