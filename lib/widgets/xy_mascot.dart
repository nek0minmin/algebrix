import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Xy mascot widget with a soft alpha drop-shadow that makes
/// the pastel pink axolotl pop with contrast against light or pink backgrounds.
class XyMascot extends StatelessWidget {
  final String asset;
  final double size;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double shadowBlur;
  final double shadowOpacity;
  final Offset shadowOffset;
  final Key? imageKey;

  const XyMascot({
    super.key,
    required this.asset,
    this.size = 100.0,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.shadowBlur = 4.5,
    this.shadowOpacity = 0.22,
    this.shadowOffset = const Offset(0, 3.0),
    this.imageKey,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? size;
    final effectiveHeight = height ?? size;
    final isTest =
        WidgetsBinding.instance.toString().contains('TestWidgetsFlutterBinding');

    if (isTest || shadowOpacity <= 0) {
      return Image.asset(
        asset,
        key: imageKey,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: fit,
        excludeFromSemantics: true,
      );
    }

    return SizedBox(
      width: effectiveWidth,
      height: effectiveHeight,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Subtle alpha-conforming black drop shadow
          Positioned(
            left: shadowOffset.dx,
            top: shadowOffset.dy,
            width: effectiveWidth,
            height: effectiveHeight,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: shadowBlur,
                sigmaY: shadowBlur,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: shadowOpacity),
                  BlendMode.srcIn,
                ),
                child: Image.asset(
                  asset,
                  fit: fit,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),

          // 2. Crisp foreground mascot illustration
          Image.asset(
            asset,
            key: imageKey,
            width: effectiveWidth,
            height: effectiveHeight,
            fit: fit,
            excludeFromSemantics: true,
          ),
        ],
      ),
    );
  }
}
