import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/widgets/bouncy_pressable.dart';

/// Full-width gradient pink pill button with tactile spring compression.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Widget? iconWidget;
  final double height;
  final double? width;
  final double borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? textColor;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.iconWidget,
    this.height = 52,
    this.width,
    this.borderRadius = 30,
    this.gradient,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;
    final effectiveGradient = isDisabled
        ? null
        : (gradient ??
              (backgroundColor == null ? AppColors.primaryGradient : null));
    final effectiveColor = isDisabled
        ? AppColors.divider
        : (backgroundColor ?? (gradient == null ? null : Colors.transparent));

    return BouncyPressable(
      shrinkFactor: 0.96,
      enableHaptics: true,
      onTap: isDisabled ? null : onPressed,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          color: effectiveColor,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isDisabled
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadow.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconWidget != null) ...[
                      iconWidget!,
                      const SizedBox(width: 8),
                    ] else if (icon != null) ...[
                      Icon(icon, color: textColor ?? Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.button.copyWith(
                          color: textColor ?? Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
