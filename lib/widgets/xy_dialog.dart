import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/constants/app_assets.dart';

/// Xy speech bubble component.
class XyDialog extends StatelessWidget {
  final String message;
  final String xyAsset;
  final double xySize;

  const XyDialog({
    super.key,
    required this.message,
    this.xyAsset = AppAssets.xyDefault,
    this.xySize = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          xyAsset,
          width: xySize,
          height: xySize,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.extraLightPink,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message,
              style: AppTextStyles.body2,
            ),
          ),
        ),
      ],
    );
  }
}
