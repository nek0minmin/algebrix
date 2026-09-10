import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:algebrix/core/animations/app_page_route.dart';
import 'package:algebrix/core/constants/app_avatars.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/auth_provider.dart';
import 'package:algebrix/models/user_model.dart';
import 'package:algebrix/screens/profile/change_password_screen.dart';
import 'package:algebrix/screens/profile/delete_account_screen.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:algebrix/widgets/app_input_field.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';

/// Account Settings: edit display name and avatar, change password, and
/// delete the account.
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late final TextEditingController _nameController;

  String? _selectedAvatarKey;
  String? _nameError;
  bool _isSaving = false;

  /// Baseline used to decide whether Save should be enabled.
  late String _savedName;
  String? _savedAvatarKey;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _savedName = user?.name ?? '';
    _savedAvatarKey =
        AppAvatars.isKnownKey(user?.avatarUrl) ? user!.avatarUrl : null;
    _nameController = TextEditingController(text: _savedName);
    _selectedAvatarKey = _savedAvatarKey;
    _nameController.addListener(_handleNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (_nameError != null) {
      setState(() => _nameError = null);
    } else {
      setState(() {});
    }
  }

  bool get _hasUnsavedChanges =>
      _nameController.text.trim() != _savedName.trim() ||
      _selectedAvatarKey != _savedAvatarKey;

  String? _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Please enter your name';
    if (trimmed.length < 2) return 'Your name needs at least 2 characters';
    if (trimmed.length > 40) return 'Your name can be at most 40 characters';
    return null;
  }

  Future<void> _handleSave() async {
    final error = _validateName(_nameController.text);
    if (error != null) {
      setState(() => _nameError = error);
      return;
    }

    setState(() {
      _isSaving = true;
      _nameError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateAccountDetails(
      name: _nameController.text,
      avatarKey: _selectedAvatarKey,
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (success) {
        _savedName = _nameController.text.trim();
        _savedAvatarKey = _selectedAvatarKey;
        _nameController.text = _savedName;
      }
    });

    if (success) {
      SoundService.playComplete();
      showAlgebrixSnackBar(
        context,
        message: 'Profile updated!',
        icon: Icons.check_circle_rounded,
      );
    } else {
      showAlgebrixSnackBar(
        context,
        message: authProvider.errorMessage ?? 'Could not save your changes.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser ?? UserModel.placeholder();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AlgebrixAppBar(
        title: 'Account Settings',
        subtitle: 'Your name, avatar, and security',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SettingsCard(
                    title: 'Your Avatar',
                    subtitle: 'Pick the Xy that feels most like you.',
                    child: _AvatarPicker(
                      selectedKey: _selectedAvatarKey,
                      fallbackInitial: user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'U',
                      onSelected: (key) {
                        SoundService.playTileSelect();
                        setState(() {
                          _selectedAvatarKey =
                              _selectedAvatarKey == key ? null : key;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    title: 'Display Name',
                    subtitle: 'This is what Xy calls you across the app.',
                    child: AppInputField(
                      key: const Key('account-settings-name-field'),
                      controller: _nameController,
                      hintText: 'Your name',
                      prefixIcon: Icons.person_rounded,
                      textInputAction: TextInputAction.done,
                      errorText: _nameError,
                      enabled: !_isSaving,
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    key: const Key('account-settings-save-button'),
                    label: 'Save Changes',
                    icon: Icons.check_rounded,
                    isLoading: _isSaving,
                    onPressed:
                        _hasUnsavedChanges && !_isSaving ? _handleSave : null,
                  ),
                  const SizedBox(height: 28),

                  _SectionLabel(label: 'Security'),
                  const SizedBox(height: 12),
                  if (authProvider.canChangePassword)
                    _SettingsRow(
                      key: const Key('account-settings-change-password-row'),
                      icon: Icons.lock_rounded,
                      iconColor: AppColors.purple,
                      iconBackground: AppColors.lightPurple,
                      title: 'Change Password',
                      subtitle: 'Update the password you sign in with',
                      onTap: () {
                        Navigator.push(
                          context,
                          AppPageRoute(child: const ChangePasswordScreen()),
                        );
                      },
                    )
                  else
                    const _InfoRow(
                      icon: Icons.g_mobiledata_rounded,
                      title: 'Signed in with Google',
                      subtitle:
                          'Your password is managed in your Google Account.',
                    ),

                  const SizedBox(height: 28),
                  _SectionLabel(label: 'Danger Zone', color: AppColors.error),
                  const SizedBox(height: 12),
                  _SettingsRow(
                    key: const Key('account-settings-delete-account-row'),
                    icon: Icons.delete_forever_rounded,
                    iconColor: AppColors.error,
                    iconBackground: const Color(0xFFFFF0F0),
                    titleColor: AppColors.error,
                    title: 'Delete Account',
                    subtitle: 'Permanently erase your account and progress',
                    onTap: () {
                      Navigator.push(
                        context,
                        AppPageRoute(child: const DeleteAccountScreen()),
                      );
                    },
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

// ── Avatar picker ───────────────────────────────────────────────────────────

class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({
    required this.selectedKey,
    required this.fallbackInitial,
    required this.onSelected,
  });

  final String? selectedKey;
  final String fallbackInitial;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Large preview of the current selection.
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.extraLightPink,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.lightPink, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: _AvatarArtwork(
            avatarKey: selectedKey,
            fallbackInitial: fallbackInitial,
            fallbackFontSize: 38,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          selectedKey == null
              ? 'Using your initial'
              : 'Tap again to go back to your initial',
          style: GoogleFonts.nunito(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 320 ? 3 : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: AppAvatars.options.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                final option = AppAvatars.options[index];
                final isSelected = option.key == selectedKey;

                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: '${option.label} avatar',
                  child: BouncyPressable(
                    // Sound is handled by onSelected so the avatar tap gets its
                    // own tile-select chime rather than the generic click.
                    enableSound: false,
                    onTap: () => onSelected(option.key),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.extraLightPink
                                    : AppColors.card,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.pink
                                      : AppColors.border,
                                  width: isSelected ? 2.5 : 1.5,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(
                                option.asset,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          option.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 10.5,
                            fontWeight:
                                isSelected ? FontWeight.w900 : FontWeight.w700,
                            color: isSelected
                                ? AppColors.darkPink
                                : AppColors.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Renders a stored avatar key, falling back to the learner's initial.
class _AvatarArtwork extends StatelessWidget {
  const _AvatarArtwork({
    required this.avatarKey,
    required this.fallbackInitial,
    this.fallbackFontSize = 24,
  });

  final String? avatarKey;
  final String fallbackInitial;
  final double fallbackFontSize;

  @override
  Widget build(BuildContext context) {
    final asset = AppAvatars.assetForKey(avatarKey);
    if (asset == null) {
      return Center(
        child: Text(
          fallbackInitial,
          style: GoogleFonts.nunito(
            fontSize: fallbackFontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.pink,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(asset, fit: BoxFit.contain),
    );
  }
}

// ── Layout primitives ───────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.subtitle1.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.subtitle),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
        color: color ?? AppColors.subtitle,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: BouncyPressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: titleColor ?? AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: titleColor ?? AppColors.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightMint.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.mint, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
