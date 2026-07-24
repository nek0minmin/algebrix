import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Centralized typography system for Algebrix.
///
/// Uses Nunito (rounded, friendly, approachable) loaded via Google Fonts.
/// All text styles should be referenced from here for consistency.
class AppTextStyles {
  AppTextStyles._();

  // ── Headings ──────────────────────────────────────────────────────────────

  static TextStyle get heading1 => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.text,
        height: 1.3,
      );

  static TextStyle get heading2 => GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.3,
      );

  static TextStyle get heading3 => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.3,
      );

  // ── Subtitles ─────────────────────────────────────────────────────────────

  static TextStyle get subtitle1 => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  static TextStyle get subtitle2 => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.subtitle,
        height: 1.4,
      );

  // ── Body ──────────────────────────────────────────────────────────────────

  static TextStyle get body1 => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      );

  static TextStyle get body2 => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.text,
        height: 1.5,
      );

  // ── Caption ───────────────────────────────────────────────────────────────

  static TextStyle get caption => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.subtitle,
        height: 1.4,
      );

  // ── Button ────────────────────────────────────────────────────────────────

  static TextStyle get button => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get buttonSmall => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.2,
      );

  // ── Special ───────────────────────────────────────────────────────────────

  /// Pink highlighted text used for emphasis in lesson content.
  static TextStyle get highlight => GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.pink,
        height: 1.3,
      );

  /// Large heading with pink emphasis — used for lesson titles.
  static TextStyle get headingHighlight => GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: AppColors.pink,
        height: 1.3,
      );

  /// Greeting text style for the dashboard.
  static TextStyle get greeting => GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.text,
        height: 1.3,
      );

  // ── Navigation ────────────────────────────────────────────────────────────

  static TextStyle navLabel({required bool isActive}) => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
        color: isActive ? AppColors.pink : AppColors.navInactive,
      );
}
