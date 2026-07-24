import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';

/// Small XP reward badge.
class XpBadge extends StatelessWidget {
  final int amount;

  const XpBadge({
    super.key,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '+$amount XP',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
