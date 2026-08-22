import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Shared mascot-led title treatment for the four primary destinations.
class RootPageHeader extends StatelessWidget {
  const RootPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.mascotAsset,
    this.trailing,
    this.compactTrailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  final String title;
  final String subtitle;
  final String? mascotAsset;
  final Widget? trailing;
  final Widget? compactTrailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final useCompactAction = viewportWidth < 560;
    final mascotSize = viewportWidth < 340 ? 56.0 : 72.0;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _PageHeaderIdentity(
                  title: title,
                  supportingText: subtitle,
                  mascotAsset: mascotAsset,
                  mascotSize: mascotSize,
                  titleSize: 24,
                  supportingTextSize: 14,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                if (useCompactAction && compactTrailing != null)
                  compactTrailing!
                else
                  trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared nested-page header used by Notes create, edit, and details.
class SecondaryPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SecondaryPageAppBar({
    super.key,
    required this.title,
    this.supportingText,
    this.actions,
  });

  final String title;
  final String? supportingText;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final mascotSize = MediaQuery.sizeOf(context).width < 340 ? 48.0 : 56.0;
    void goBack() => Navigator.of(context).maybePop();

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 96,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Semantics(
                  container: true,
                  excludeSemantics: true,
                  button: true,
                  label: 'Back to Notes',
                  onTap: goBack,
                  child: Tooltip(
                    message: 'Back to Notes',
                    excludeFromSemantics: true,
                    child: IconButton(
                      key: const Key('secondary-page-back-button'),
                      onPressed: goBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(44),
                        maximumSize: const Size.square(44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.extraLightPink,
                        foregroundColor: AppColors.darkPink,
                        side: const BorderSide(color: AppColors.lightPink),
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PageHeaderIdentity(
                    title: title,
                    supportingText: supportingText,
                    mascotSize: mascotSize,
                    titleSize: 22,
                    supportingTextSize: 13,
                  ),
                ),
                if (actions case final actions?) ...[
                  const SizedBox(width: 8),
                  ...actions,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageHeaderIdentity extends StatelessWidget {
  const _PageHeaderIdentity({
    required this.title,
    required this.supportingText,
    required this.mascotSize,
    required this.titleSize,
    required this.supportingTextSize,
    this.mascotAsset,
  });

  final String title;
  final String? supportingText;
  final double mascotSize;
  final double titleSize;
  final double supportingTextSize;
  final String? mascotAsset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          mascotAsset ?? AppAssets.xyDefault,
          key: const Key('page-header-xy'),
          width: mascotSize,
          height: mascotSize,
          fit: BoxFit.contain,
          excludeFromSemantics: true,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading2.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (supportingText != null) ...[
                const SizedBox(height: 1),
                Text(
                  supportingText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: supportingTextSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

