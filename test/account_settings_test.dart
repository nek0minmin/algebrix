import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_avatars.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/models/lesson_progress_model.dart';
import 'package:algebrix/screens/profile/account_settings_screen.dart';
import 'package:algebrix/screens/profile/change_password_screen.dart';
import 'package:algebrix/screens/profile/delete_account_screen.dart';
import 'package:algebrix/services/account_repository.dart';
import 'package:algebrix/services/auth_service.dart';
import 'package:algebrix/services/progress_repository.dart';
import 'package:algebrix/widgets/primary_button.dart';

/// Progress repository stub so ProfileScreen-adjacent widgets can build without
/// a live backend.
class _StubProgressRepository implements ProgressRepository {
  @override
  Future<LearningProfileSnapshot> fetchCurrentProfile() async =>
      const LearningProfileSnapshot(
        userId: 'student_1',
      );

  @override
  Future<List<LessonProgress>> fetchModuleProgress(String moduleId) async => [];

  @override
  Future<RecordLessonStepResult> recordLessonStep({
    required String moduleId,
    required String lessonId,
    required String stepId,
    required int stepIndex,
    bool answerCorrect = false,
    int contentVersion = 1,
  }) =>
      Future.error(StateError('not used in this test'));
}

void main() {
  group('AppAvatars', () {
    test('every preset key satisfies the profiles_avatar_url constraint', () {
      final pattern = RegExp(r'^[a-z0-9][a-z0-9-]{0,39}$');
      for (final option in AppAvatars.options) {
        expect(
          pattern.hasMatch(option.key),
          isTrue,
          reason: '${option.key} would be rejected by the database CHECK',
        );
      }
    });

    test('preset keys are unique', () {
      final keys = AppAvatars.options.map((o) => o.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('resolves known keys and rejects unknown ones', () {
      expect(AppAvatars.assetForKey('xy-happy'), isNotNull);
      expect(AppAvatars.assetForKey('not-a-real-avatar'), isNull);
      expect(AppAvatars.assetForKey(null), isNull);
      expect(AppAvatars.assetForKey(''), isNull);
      expect(AppAvatars.isKnownKey(AppAvatars.defaultKey), isTrue);
    });
  });

  group('AuthProvider account settings', () {
    late MemoryAccountRepository repository;
    late AuthProvider provider;

    setUp(() {
      repository = MemoryAccountRepository();
      provider = AuthProvider(
        authService: AuthService(),
        accountRepository: repository,
      );
    });

    test('rejects a name shorter than 2 characters', () async {
      final success = await provider.updateAccountDetails(name: 'A');

      expect(success, isFalse);
      expect(provider.errorMessage, contains('between 2 and 40'));
      expect(repository.lastName, isNull);
    });

    test('rejects a name longer than 40 characters', () async {
      final success =
          await provider.updateAccountDetails(name: 'x' * 41);

      expect(success, isFalse);
      expect(repository.lastName, isNull);
    });

    test('rejects a whitespace-only name', () async {
      final success = await provider.updateAccountDetails(name: '    ');

      expect(success, isFalse);
      expect(repository.lastName, isNull);
    });

    test('trims and forwards a valid name and avatar', () async {
      final success = await provider.updateAccountDetails(
        name: '  Jass Carpio  ',
        avatarKey: 'xy-idea',
      );

      expect(success, isTrue);
      expect(repository.lastName, 'Jass Carpio');
      expect(repository.lastAvatarKey, 'xy-idea');
    });

    test('a null avatar key clears the avatar', () async {
      await provider.updateAccountDetails(name: 'Jass', avatarKey: null);

      expect(repository.lastAvatarKey, isNull);
    });

    test('surfaces a repository failure instead of throwing', () async {
      repository.failure = StateError('network down');

      final success = await provider.updateAccountDetails(name: 'Jass');

      expect(success, isFalse);
      expect(provider.errorMessage, isNotNull);
      expect(provider.isLoading, isFalse);
    });

    test('deleteAccount reports success and clears the session', () async {
      final success = await provider.deleteAccount();

      expect(success, isTrue);
      expect(repository.wasDeleted, isTrue);
      expect(provider.currentUser, isNull);
    });

    test('deleteAccount keeps the session when the RPC fails', () async {
      repository.failure = StateError('rpc unavailable');

      final success = await provider.deleteAccount();

      expect(success, isFalse);
      expect(repository.wasDeleted, isFalse);
      expect(provider.errorMessage, isNotNull);
    });

    test('account actions degrade gracefully with no repository', () async {
      final offline = AuthProvider(
        authService: AuthService(),
        accountRepository: null,
      );

      // A null repository is indistinguishable from the default here because
      // Supabase is not initialised under test, so both paths must be safe.
      expect(await offline.updateAccountDetails(name: 'Jass'), isFalse);
      expect(offline.errorMessage, isNotNull);
    });
  });

  group('Account settings screens', () {
    /// The change-password form is taller than the default 600px test
    /// viewport, so give it room rather than scrolling before every assertion.
    Future<void> useTallSurface(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
    }

    Widget wrap(Widget child, {MemoryAccountRepository? repository}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
            create: (_) => AuthProvider(
              authService: AuthService(),
              accountRepository: repository ?? MemoryAccountRepository(),
            ),
          ),
          ChangeNotifierProvider<LessonProvider>(
            create: (_) => LessonProvider(repository: _StubProgressRepository()),
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets('AccountSettingsScreen renders name, avatars, and danger zone',
        (tester) async {
      await tester.pumpWidget(wrap(const AccountSettingsScreen()));
      await tester.pump();

      expect(find.byKey(const Key('account-settings-name-field')), findsOneWidget);
      expect(find.text('Your Avatar'), findsOneWidget);
      expect(find.text('Display Name'), findsOneWidget);
      expect(
        find.byKey(const Key('account-settings-delete-account-row')),
        findsOneWidget,
      );
    });

    testWidgets('Save is disabled until something actually changes',
        (tester) async {
      await tester.pumpWidget(wrap(const AccountSettingsScreen()));
      await tester.pump();

      final saveFinder = find.byKey(const Key('account-settings-save-button'));
      expect(
        tester.widget<PrimaryButton>(saveFinder).onPressed,
        isNull,
        reason: 'nothing has been edited yet',
      );

      await tester.enterText(
        find.byKey(const Key('account-settings-name-field')),
        'New Name',
      );
      await tester.pump();

      expect(tester.widget<PrimaryButton>(saveFinder).onPressed, isNotNull);
    });

    testWidgets('DeleteAccountScreen stays disabled until DELETE is typed',
        (tester) async {
      await tester.pumpWidget(wrap(const DeleteAccountScreen()));
      await tester.pump();

      final submitFinder =
          find.byKey(const Key('delete-account-submit-button'));
      expect(tester.widget<PrimaryButton>(submitFinder).onPressed, isNull);

      await tester.enterText(
        find.byKey(const Key('delete-account-confirmation-field')),
        'delete me',
      );
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(submitFinder).onPressed,
        isNull,
        reason: 'only the exact confirmation phrase should unlock deletion',
      );

      await tester.enterText(
        find.byKey(const Key('delete-account-confirmation-field')),
        'delete',
      );
      await tester.pump();
      expect(
        tester.widget<PrimaryButton>(submitFinder).onPressed,
        isNotNull,
        reason: 'the phrase is matched case-insensitively',
      );
    });

    testWidgets('DeleteAccountScreen spells out what is lost', (tester) async {
      await tester.pumpWidget(wrap(const DeleteAccountScreen()));
      await tester.pump();

      expect(find.text('You will permanently lose'), findsOneWidget);
      expect(find.text('All of your study notes'), findsOneWidget);
      expect(find.text('All lesson progress and XP'), findsOneWidget);
    });

    testWidgets('ChangePasswordScreen validates before calling the backend',
        (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(wrap(const ChangePasswordScreen()));
      await tester.pump();

      await tester.tap(find.byKey(const Key('change-password-submit-button')));
      await tester.pump();

      expect(find.text('Please enter your current password'), findsOneWidget);
      expect(find.text('Please enter a new password'), findsOneWidget);
    });

    testWidgets('ChangePasswordScreen rejects a weak or mismatched password',
        (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(wrap(const ChangePasswordScreen()));
      await tester.pump();

      await tester.enterText(
        find.byKey(const Key('change-password-current-field')),
        'OldPass123',
      );
      await tester.enterText(
        find.byKey(const Key('change-password-new-field')),
        'short',
      );
      await tester.enterText(
        find.byKey(const Key('change-password-confirm-field')),
        'different',
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('change-password-submit-button')));
      await tester.pump();

      expect(
        find.text('Password must be at least 8 characters long'),
        findsOneWidget,
      );
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('ChangePasswordScreen blocks reusing the current password',
        (tester) async {
      await useTallSurface(tester);
      await tester.pumpWidget(wrap(const ChangePasswordScreen()));
      await tester.pump();

      const samePassword = 'SamePass123';
      for (final key in [
        'change-password-current-field',
        'change-password-new-field',
        'change-password-confirm-field',
      ]) {
        await tester.enterText(find.byKey(Key(key)), samePassword);
      }
      await tester.pump();

      await tester.tap(find.byKey(const Key('change-password-submit-button')));
      await tester.pump();

      expect(
        find.text('Your new password must be different from the current one'),
        findsOneWidget,
      );
    });
  });
}
