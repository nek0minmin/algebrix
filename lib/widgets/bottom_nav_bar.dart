import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_strings.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Ultra-modern Floating Animated Pill Navigation Bar for Algebrix.
///
/// Features a gliding indicator pod, spring-pop active icons, tactile squeeze,
/// and subtle haptic feedback.
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_NavItemData> _items = [
    _NavItemData(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: AppStrings.navHome,
    ),
    _NavItemData(
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book_rounded,
      label: AppStrings.navLessons,
    ),
    _NavItemData(
      icon: Icons.psychology_outlined,
      activeIcon: Icons.psychology_rounded,
      label: AppStrings.navPractice,
    ),
    _NavItemData(
      icon: Icons.note_alt_outlined,
      activeIcon: Icons.note_alt_rounded,
      label: AppStrings.navNotes,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding > 0 ? bottomPadding : 14),
      child: Container(
        height: 66,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.8),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D2D2D).withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: AppColors.pink.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth / _items.length;

            return Stack(
              children: [
                // Gliding Animated Active Pod
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  left: currentIndex * itemWidth + 5,
                  top: 5,
                  bottom: 5,
                  width: itemWidth - 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.extraLightPink,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppColors.pink.withValues(alpha: 0.28),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),

                // Navigation Item Row
                Row(
                  children: List.generate(_items.length, (index) {
                    final item = _items[index];
                    final isSelected = currentIndex == index;

                    return Expanded(
                      child: BouncyPressable(
                        shrinkFactor: 0.92,
                        duration: const Duration(milliseconds: 120),
                        enableHaptics: true,
                        onTap: () {
                          if (currentIndex != index) {
                            HapticFeedback.lightImpact();
                            onTap(index);
                          }
                        },
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedScale(
                                scale: isSelected ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  isSelected ? item.activeIcon : item.icon,
                                  color: isSelected
                                      ? AppColors.pink
                                      : AppColors.navInactive,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 3),
                              AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: TextStyle(
                                  fontFamily: 'Nunito',
                                  fontSize: 11.5,
                                  fontWeight: isSelected
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.pink
                                      : AppColors.navInactive,
                                  letterSpacing: 0.2,
                                ),
                                child: Text(
                                  item.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
