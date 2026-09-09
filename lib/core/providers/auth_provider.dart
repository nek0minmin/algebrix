import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:algebrix/core/utils/error_formatter.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/services/account_repository.dart';
import 'package:algebrix/services/auth_service.dart';

/// Provider and state manager for handling user authentication & 6-digit OTP state in Algebrix.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final AccountRepository? _accountRepository;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  bool _rememberMe = true;

  AuthProvider({AuthService? authService, AccountRepository? accountRepository})
      : _authService = authService ?? AuthService(),
        _accountRepository = accountRepository ?? _defaultAccountRepository() {
    checkCurrentUser();
  }

  /// Builds the live account repository, or null when Supabase is unavailable
  /// (widget tests, offline first launch). Account settings degrade to a
  /// clear message instead of throwing.
  static AccountRepository? _defaultAccountRepository() {
    try {
      return SupabaseAccountRepository();
    } catch (_) {
      return null;
    }
  }

  // --- State Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null || _authService.isAuthenticated;
  bool get rememberMe => _rememberMe;

  /// Update remember me preference.
  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  /// Synchronize the current user state from [AuthService].
  void checkCurrentUser() {
    _currentUser = _authService.getCurrentUser();
    notifyListeners();
  }

  /// Sign in user with email and password.
  Future<bool> login({
    String? email,
    String? password,
  }) async {
    if (email == null || password == null) {
      _errorMessage = 'Email and password are required.';
      notifyListeners();
      return false;
    }
    return loginWithEmail(email, password);
  }

  Future<bool> loginWithEmail(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithEmail(email, password);
      if (response != null && response.user != null) {
        _currentUser = _authService.getCurrentUser();
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Invalid login credentials.';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign up user with email, password, and optional name.
  Future<bool> register({
    String? name,
    String? email,
    String? password,
  }) async {
    if (email == null || password == null) {
      _errorMessage = 'Email and password are required.';
      notifyListeners();
      return false;
    }
    return signUpWithEmail(email, password, name);
  }

  Future<bool> signUpWithEmail(
    String email,
    String password, [
    String? name,
  ]) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUpWithEmail(email, password, name);
      _setLoading(false);
      return response != null;
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Verify 6-digit email sign-up OTP code.
  Future<bool> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyEmailOTP(email: email, token: token);
      if (response != null && (response.user != null || response.session != null)) {
        _currentUser = _authService.getCurrentUser();
        _setLoading(false);
        return true;
      }
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? 'Verification failed. Please check the 6-digit code.');
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Verify 6-digit OTP code (supports OtpType.signup, OtpType.recovery, etc.).
  Future<bool> verifyOTP({
    required String email,
    required String token,
    OtpType type = OtpType.signup,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyOTP(
        email: email,
        token: token,
        type: type,
      );
      if (response != null && (response.user != null || response.session != null)) {
        _currentUser = _authService.getCurrentUser();
        _setLoading(false);
        return true;
      }
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? 'Verification failed. Please check the 6-digit code.');
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Update user password via client.auth.updateUser and sign out temporary session.
  Future<bool> updatePassword(String newPassword) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.updatePassword(newPassword);
      if (!success) {
        _errorMessage = _formatErrorMessage(_authService.errorMessage ?? 'Failed to update password.');
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Resend 6-digit OTP code to email.
  Future<bool> resendOTP({required String email}) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resendOTP(email: email);
      if (_authService.errorMessage != null) {
        _errorMessage = _formatErrorMessage(_authService.errorMessage!);
        _setLoading(false);
        return false;
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Verify password recovery OTP and update password.
  Future<bool> verifyPasswordResetOTP({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.verifyPasswordResetOTP(
        email: email,
        token: token,
        newPassword: newPassword,
      );
      if (!success) {
        _errorMessage = _formatErrorMessage(_authService.errorMessage ?? 'Invalid code or failed to reset password.');
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Sign in user with Google.
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.loginWithGoogle();
      if (success) {
        _currentUser = _authService.getCurrentUser();
      } else {
        _errorMessage = _formatErrorMessage(_authService.errorMessage ?? 'Google Sign-In was cancelled or failed.');
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email.
  Future<bool> resetPassword({String? email}) async {
    if (email == null || email.isEmpty) {
      _errorMessage = 'Email address is required.';
      notifyListeners();
      return false;
    }
    return resetPasswordEmail(email);
  }

  Future<bool> resetPasswordEmail(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _formatErrorMessage(_authService.errorMessage ?? e.toString());
      _setLoading(false);
      return false;
    }
  }

  // --- Account Settings ---

  /// Whether the account can rotate its password in-app (email/password only).
  bool get canChangePassword => _authService.hasEmailPasswordIdentity;

  /// Update the learner's display name and preset avatar.
  ///
  /// Returns true on success; inspect [errorMessage] otherwise.
  Future<bool> updateAccountDetails({
    required String name,
    String? avatarKey,
  }) async {
    final repository = _accountRepository;
    if (repository == null) {
      _errorMessage = 'Account settings are unavailable right now.';
      notifyListeners();
      return false;
    }

    final trimmed = name.trim();
    if (trimmed.length < 2 || trimmed.length > 40) {
      _errorMessage = 'Your name must be between 2 and 40 characters.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await repository.updateAccount(name: trimmed, avatarKey: avatarKey);
      _currentUser = _authService.refreshCurrentUser();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }
  }

  /// Change the password of the signed-in learner, keeping the session alive.
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (success) {
        _currentUser = _authService.getCurrentUser();
      } else {
        _errorMessage = _formatErrorMessage(
          _authService.errorMessage ?? 'Failed to update password.',
        );
      }
      _setLoading(false);
      return success;
    } catch (e) {
      _errorMessage = _formatErrorMessage(
        _authService.errorMessage ?? e.toString(),
      );
      _setLoading(false);
      return false;
    }
  }

  /// Permanently delete the account, then clear local session state.
  Future<bool> deleteAccount() async {
    final repository = _accountRepository;
    if (repository == null) {
      _errorMessage = 'Account deletion is unavailable right now.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await repository.deleteAccount();
    } catch (e) {
      _errorMessage = _formatErrorMessage(e.toString());
      _setLoading(false);
      return false;
    }

    // The account is gone server-side. Clear the local session even if sign-out
    // complains — the refresh token it would revoke no longer resolves.
    try {
      await _authService.signOut();
    } catch (_) {}

    _currentUser = null;
    _clearError();
    _setLoading(false);
    return true;
  }

  /// Sign out current user.
  Future<void> logout() async {
    return signOut();
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.signOut();
    } catch (e) {
      _errorMessage = _formatErrorMessage(
        _authService.errorMessage ?? e.toString(),
      );
    } finally {
      _currentUser = null;
      _setLoading(false);
    }
  }

  UserModel? getCurrentUser() {
    _currentUser = _authService.getCurrentUser();
    return _currentUser;
  }

  // --- Helper Methods ---
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _formatErrorMessage(String error) {
    return ErrorFormatter.formatAuthError(error);
  }
}
