import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/widgets/xy_mascot.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared mascot-led title treatment for the primary navigation destinations.
///
/// Features a prominent, legible mascot illustration on the left and a structured
/// column on the right containing the Title, Subtitle, and an integrated pill Search Bar.
class RootPageHeader extends StatelessWidget {
  const RootPageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.mascotAsset,
    this.searchPlaceholder,
    this.onSearchChanged,
    this.searchController,
    this.searchBar,
    this.trailing,
    this.compactTrailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  final String title;
  final String subtitle;
  final String? mascotAsset;
  final String? searchPlaceholder;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final Widget? searchBar;
  final Widget? trailing;
  final Widget? compactTrailing;
  final EdgeInsetsGeometry padding;

  String _resolveMascotAsset() {
    if (mascotAsset != null) return mascotAsset!;
    final lower = title.toLowerCase();
    if (lower.contains('welcome') || lower.contains('home')) {
      return AppAssets.xyWelcome;
    }
    if (lower.contains('lesson')) {
      return AppAssets.xyLessons;
    }
    if (lower.contains('practice')) {
      return AppAssets.xyPractice;
    }
    if (lower.contains('note')) {
      return AppAssets.xyNotes;
    }
    if (lower.contains('quiz')) {
      return AppAssets.xyQuestion;
    }
    return AppAssets.xyDefault;
  }

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final useCompactAction = viewportWidth < 560;
    final mascotSize = viewportWidth < 360 ? 92.0 : 108.0;

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
                  mascotAsset: _resolveMascotAsset(),
                  mascotSize: mascotSize,
                  titleSize: 26,
                  supportingTextSize: 14.5,
                  searchBar: searchBar,
                  searchPlaceholder: searchPlaceholder,
                  onSearchChanged: onSearchChanged,
                  searchController: searchController,
                ),
              ),
              if (trailing != null || compactTrailing != null) ...[
                const SizedBox(width: 8),
                if (useCompactAction && compactTrailing != null)
                  compactTrailing!
                else if (trailing != null)
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
    this.mascotAsset,
    this.actions,
  });

  final String title;
  final String? supportingText;
  final String? mascotAsset;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final mascotSize = MediaQuery.sizeOf(context).width < 340 ? 52.0 : 64.0;
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
                    mascotAsset: mascotAsset,
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
    this.searchBar,
    this.searchPlaceholder,
    this.onSearchChanged,
    this.searchController,
  });

  final String title;
  final String? supportingText;
  final double mascotSize;
  final double titleSize;
  final double supportingTextSize;
  final String? mascotAsset;
  final Widget? searchBar;
  final String? searchPlaceholder;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tight = constraints.maxWidth < (mascotSize + 60);
        final effectiveMascotSize = tight
            ? (constraints.maxWidth * 0.42).clamp(36.0, mascotSize)
            : mascotSize;
        final spacing = tight ? 8.0 : 14.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (mascotAsset != null) ...[
              XyMascot(
                asset: mascotAsset!,
                imageKey: const Key('page-header-xy'),
                size: effectiveMascotSize,
                shadowBlur: 5.0,
                shadowOpacity: 0.22,
              ),
              SizedBox(width: spacing),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: AppColors.text,
                  height: 1.15,
                ),
              ),
              if (supportingText != null) ...[
                const SizedBox(height: 2),
                Text(
                  supportingText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                    color: AppColors.textSecondary,
                    fontSize: supportingTextSize,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
              if (searchBar != null) ...[
                const SizedBox(height: 8),
                searchBar!,
              ] else if (searchPlaceholder != null) ...[
                const SizedBox(height: 8),
                _HeaderPillSearchBar(
                  placeholder: searchPlaceholder!,
                  onChanged: onSearchChanged,
                  controller: searchController,
                ),
              ],
            ],
          ),
        ),
      ],
    );
      },
    );
  }
}

/// Pill-shaped search bar with pink search magnifying glass icon
class _HeaderPillSearchBar extends StatelessWidget {
  const _HeaderPillSearchBar({
    required this.placeholder,
    this.onChanged,
    this.controller,
  });

  final String placeholder;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.nunito(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9CA3AF),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          const Icon(
            Icons.search_rounded,
            color: AppColors.pink,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Standard top App Bar across all sub-pages (Modules, Lessons, Quizzes, Notes)
/// matching the signature Algebrix circular pink back-button and bold title style.
class AlgebrixAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AlgebrixAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.icon = Icons.arrow_back_rounded,
    this.actions,
    this.toolbarHeight = 64,
  });

  final String title;
  final VoidCallback? onBack;
  final IconData icon;
  final List<Widget>? actions;
  final double toolbarHeight;

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);

  @override
  Widget build(BuildContext context) {
    void handleBack() {
      if (onBack != null) {
        onBack!();
      } else {
        Navigator.of(context).maybePop();
      }
    }

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Back',
              child: IconButton(
                onPressed: handleBack,
                icon: Icon(icon),
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
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.nunito(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (actions case final actions?) ...[
              const SizedBox(width: 8),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
}
