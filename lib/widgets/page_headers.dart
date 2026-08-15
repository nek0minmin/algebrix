import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

/// Shared title treatment for the four primary destinations.
class RootPageHeader extends StatelessWidget {
  const RootPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.compactTrailing,
    this.padding = const EdgeInsets.fromLTRB(20, 18, 20, 12),
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget? compactTrailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 350;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading1.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                if (isCompact && compactTrailing != null)
                  compactTrailing!
                else
                  trailing!,
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Branded nested-page app bar used by Notes create, edit, and details.
class SecondaryPageAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const SecondaryPageAppBar({
    super.key,
    required this.title,
    this.eyebrow = 'NOTES',
    this.actions,
  });

  final String title;
  final String eyebrow;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 68,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            eyebrow,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.pink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
