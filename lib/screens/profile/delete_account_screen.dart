import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/screens/auth/login_screen.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';

/// Permanent account deletion, gated behind a typed confirmation.
///
/// Deletion runs through the `delete_own_account` RPC, which removes the
/// `auth.users` row and cascades to every table the learner owns.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const String _confirmationPhrase = 'DELETE';

  final _confirmationController = TextEditingController();
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _confirmationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  bool get _isConfirmed =>
      _confirmationController.text.trim().toUpperCase() == _confirmationPhrase;

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Text(
          'Delete account?',
          style: GoogleFonts.nunito(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
          ),
        ),
        content: Text(
          'This cannot be undone. Your progress, notes, stars, and quiz '
          'history will be permanently erased.',
          style: GoogleFonts.nunito(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            key: const Key('delete-account-dialog-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Keep my account',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            key: const Key('delete-account-dialog-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete forever',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.deleteAccount();

    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      showAlgebrixSnackBar(
        context,
        message: 'Your account has been deleted.',
        icon: Icons.check_circle_rounded,
      );
    } else {
      showAlgebrixSnackBar(
        context,
        message: authProvider.errorMessage ?? 'Could not delete your account.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AlgebrixAppBar(
        title: 'Delete Account',
        subtitle: 'This cannot be undone',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 26,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'You will permanently lose',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const _LossItem(
                          icon: Icons.school_rounded,
                          label: 'All lesson progress and XP',
                        ),
                        const _LossItem(
                          icon: Icons.star_rounded,
                          label: 'Every quest star and level you have earned',
                        ),
                        const _LossItem(
                          icon: Icons.sticky_note_2_rounded,
                          label: 'All of your study notes',
                        ),
                        const _LossItem(
                          icon: Icons.quiz_rounded,
                          label: 'Quiz scores and review history',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Type $_confirmationPhrase to confirm',
                    style: AppTextStyles.subtitle2.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppInputField(
                    key: const Key('delete-account-confirmation-field'),
                    controller: _confirmationController,
                    hintText: _confirmationPhrase,
                    prefixIcon: Icons.keyboard_rounded,
                    textInputAction: TextInputAction.done,
                    enabled: !_isDeleting,
                  ),
                  const SizedBox(height: 24),

                  PrimaryButton(
                    key: const Key('delete-account-submit-button'),
                    label: 'Delete My Account',
                    icon: Icons.delete_forever_rounded,
                    backgroundColor: AppColors.error,
                    isLoading: _isDeleting,
                    onPressed:
                        _isConfirmed && !_isDeleting ? _handleDelete : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Changed your mind? Just go back — nothing has happened yet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LossItem extends StatelessWidget {
  const _LossItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.error.withValues(alpha: 0.75)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
