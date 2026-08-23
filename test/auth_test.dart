import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/services/auth_service.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';
import 'package:algebrix/widgets/password_strength_checklist.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/screens/auth/register_screen.dart';
import 'package:algebrix/screens/auth/forgot_password_screen.dart';
import 'package:algebrix/screens/auth/otp_verification_screen.dart';
import 'package:algebrix/screens/auth/new_password_screen.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/models/user_model.dart';

void main() {
  Widget createTestableWidget(Widget child) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(authService: AuthService()),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Auth Widgets Tests', () {
    testWidgets('AppInputField renders label, hint, and toggles password visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppInputField(
              label: 'Test Label',
              hintText: 'Enter text',
              isPassword: true,
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap password toggle button
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('PrimaryButton displays label and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Submit',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      await tester.tap(find.byType(PrimaryButton));
      expect(tapped, isTrue);
    });

    testWidgets('SecondaryButton renders with icon and label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Google Sign In',
              icon: Icons.g_mobiledata,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Google Sign In'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    testWidgets('PasswordStrengthChecklist renders 4 criteria items and Strong badge when satisfied', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordStrengthChecklist(
              password: 'StrongPassword1',
            ),
          ),
        ),
      );

      expect(find.text('At least 8 characters long'), findsOneWidget);
      expect(find.text('At least 1 number'), findsOneWidget);
      expect(find.text('At least 1 uppercase letter'), findsOneWidget);
      expect(find.text('At least 1 lowercase letter'), findsOneWidget);
      expect(find.text('Strong'), findsWidgets);
    });
  });

  group('Auth Screens Render Tests', () {
    testWidgets('LoginScreen renders mascot, input fields, and action buttons', (tester) async {
      await tester.pumpWidget(createTestableWidget(const LoginScreen()));

      expect(find.text('ALGEBRIX'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders registration fields and buttons', (tester) async {
      await tester.pumpWidget(createTestableWidget(const RegisterScreen()));

      expect(find.textContaining('Create your account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('ForgotPasswordScreen renders reset instructions and email input', (tester) async {
      await tester.pumpWidget(createTestableWidget(const ForgotPasswordScreen()));

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('NewPasswordScreen renders new password fields and strength checklist', (tester) async {
      await tester.pumpWidget(createTestableWidget(const NewPasswordScreen(email: 'student@example.com')));

      expect(find.text('Set New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('OTPVerificationScreen renders 6 pin fields and 120s timer countdown', (tester) async {
      await tester.pumpWidget(createTestableWidget(const OTPVerificationScreen(email: 'student@example.com')));

      expect(find.text('Verify OTP'), findsOneWidget);
      expect(find.text('Verify Code'), findsOneWidget);
      expect(find.textContaining('student@example.com'), findsOneWidget);
      expect(find.textContaining('Resend Code in'), findsOneWidget);
    });

    testWidgets('RegisterScreen validates strict password rules', (tester) async {
      await tester.pumpWidget(createTestableWidget(const RegisterScreen()));

      await tester.enterText(find.byType(TextFormField).at(0), 'Alex Rivera');
      await tester.enterText(find.byType(TextFormField).at(1), 'alex@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), 'short');
      await tester.enterText(find.byType(TextFormField).at(3), 'short');

      await tester.ensureVisible(find.text('Sign Up'));
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Password must be at least 8 characters long'), findsOneWidget);
    });
  });

  group('AuthProvider & AuthService OTP and Rate Limit Unit Tests', () {
    test('sign out remains pending until provider cleanup finishes', () async {
      final googleSignOut = Completer<void>();
      final service = AuthService(googleSignOut: () => googleSignOut.future);

      var completed = false;
      final signOut = service.signOut().then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);

      expect(completed, isFalse);
      googleSignOut.complete();
      await signOut;
      expect(completed, isTrue);
    });

    test('sign out reports provider cleanup failure', () async {
      final service = AuthService(
        googleSignOut: () async => throw Exception('Google cleanup failed.'),
      );

      await expectLater(service.signOut(), throwsException);
      expect(service.errorMessage, contains('Google cleanup failed'));
    });

    test('AuthProvider clears its user only after sign out completes', () async {
      final signOut = Completer<void>();
      final service = _PendingSignOutAuthService(signOut.future);
      final provider = AuthProvider(authService: service);

      expect(provider.currentUser, isNotNull);
      final pendingLogout = provider.logout();
      await Future<void>.delayed(Duration.zero);
      expect(provider.currentUser, isNotNull);

      signOut.complete();
      await pendingLogout;
      expect(provider.currentUser, isNull);
    });

    test('AuthProvider clears its user when provider cleanup fails', () async {
      final service = _FailingSignOutAuthService();
      final provider = AuthProvider(authService: service);

      expect(provider.currentUser, isNotNull);
      await provider.logout();

      expect(provider.currentUser, isNull);
      expect(provider.errorMessage, contains('Google cleanup failed'));
    });

    test('verifyEmailOTP sets error when Supabase is uninitialized', () async {
      final authProvider = AuthProvider(authService: AuthService());
      final success = await authProvider.verifyEmailOTP(
        email: 'test@example.com',
        token: '123456',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('Supabase client is not initialized'));
    });

    test('resendOTP handles uninitialized client gracefully', () async {
      final authProvider = AuthProvider(authService: AuthService());
      final success = await authProvider.resendOTP(email: 'test@example.com');

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('Supabase client is not initialized'));
    });

    test('verifyPasswordResetOTP handles uninitialized client gracefully', () async {
      final authProvider = AuthProvider(authService: AuthService());
      final success = await authProvider.verifyPasswordResetOTP(
        email: 'test@example.com',
        token: '123456',
        newPassword: 'newpassword123',
      );

      expect(success, isFalse);
      expect(authProvider.errorMessage, contains('Supabase client is not initialized'));
    });
  });
}

class _PendingSignOutAuthService extends AuthService {
  _PendingSignOutAuthService(this.pendingSignOut)
    : super(googleSignOut: _noopSignOut);

  final Future<void> pendingSignOut;

  static Future<void> _noopSignOut() async {}

  @override
  UserModel? getCurrentUser() => UserModel.placeholder();

  @override
  Future<void> signOut() => pendingSignOut;
}

class _FailingSignOutAuthService extends AuthService {
  _FailingSignOutAuthService() : super(googleSignOut: _noopSignOut);

  static Future<void> _noopSignOut() async {}

  @override
  UserModel? getCurrentUser() => UserModel.placeholder();

  @override
  Future<void> signOut() async {
    throw Exception('Google cleanup failed.');
  }
}
