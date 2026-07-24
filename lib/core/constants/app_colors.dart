import 'package:flutter/material.dart';

/// Centralized color palette for Algebrix.
///
/// Colors are organized into primary, accent, semantic, and neutral groups.
/// Always reference these constants instead of using inline color values.
class AppColors {
  AppColors._();

  // ── Primary ───────────────────────────────────────────────────────────────
  static const Color pink = Color(0xFFFF5CA8);
  static const Color darkPink = Color(0xFFE91E8C);
  static const Color lightPink = Color(0xFFFFD6EA);
  static const Color extraLightPink = Color(0xFFFFF0F7);

  // ── Accent ────────────────────────────────────────────────────────────────
  static const Color purple = Color(0xFFA98CFF);
  static const Color lightPurple = Color(0xFFEDE7FF);
  static const Color mint = Color(0xFF62D9C7);
  static const Color lightMint = Color(0xFFE0F7F3);
  static const Color yellow = Color(0xFFFFC857);
  static const Color lightYellow = Color(0xFFFFF8E7);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  static const Color background = Color(0xFFFDFBFF);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF5A5A5A);
  static const Color subtitle = Color(0xFF8A8A8A);
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);
  static const Color navInactive = Color(0xFFAAAAAA);
  static const Color shimmer = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x0A000000);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [pink, darkPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFFFFF0F7), Colors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}