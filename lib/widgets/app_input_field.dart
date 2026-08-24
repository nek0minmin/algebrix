import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

/// Clean, crisp rounded stadium pill text input field widget for Algebrix
/// with pink icons, soft off-white fill, and drop shadow matching Figma designs.
class AppInputField extends StatefulWidget {
  final String? label;
  final String? hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final bool isPassword;
  final String? errorText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final Color? fillColor;
  final Color? activeFillColor;
  final Color? focusedBorderColor;
  final int maxLines;
  final double borderRadius;

  const AppInputField({
    super.key,
    this.label,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.isPassword = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.fillColor,
    this.activeFillColor,
    this.focusedBorderColor,
    this.maxLines = 1,
    this.borderRadius = 36.0,
  });

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  late bool _obscureText;
  late FocusNode _effectiveFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _effectiveFocusNode = widget.focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _effectiveFocusNode.dispose();
    } else {
      _effectiveFocusNode.removeListener(_handleFocusChange);
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _effectiveFocusNode.hasFocus;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    Color effectiveFill;
    if (!widget.enabled) {
      effectiveFill = AppColors.divider.withValues(alpha: 0.3);
    } else if (hasError) {
      effectiveFill = const Color(0xFFFFF5F5);
    } else if (_isFocused) {
      effectiveFill = widget.activeFillColor ?? const Color(0xFFF7F8FA);
    } else {
      effectiveFill = widget.fillColor ?? const Color(0xFFF7F8FA);
    }

    Color effectiveBorderColor;
    if (hasError) {
      effectiveBorderColor = AppColors.error;
    } else if (_isFocused) {
      effectiveBorderColor = widget.focusedBorderColor ?? AppColors.pink;
    } else {
      effectiveBorderColor = const Color(0xFFE2E8F0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 14.0),
            child: Text(
              widget.label!,
              style: GoogleFonts.nunito(
                color: hasError
                    ? AppColors.error
                    : (_isFocused ? AppColors.pink : AppColors.text),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: effectiveBorderColor,
              width: _isFocused || hasError ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _isFocused
                    ? AppColors.pink.withValues(alpha: 0.16)
                    : const Color(0x14000000),
                blurRadius: _isFocused ? 16 : 14,
                offset: const Offset(0, 5),
                spreadRadius: 0,
              ),
            ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocusNode,
            obscureText: widget.isPassword ? _obscureText : false,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            maxLines: widget.isPassword ? 1 : widget.maxLines,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onFieldSubmitted,
            validator: widget.validator,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: widget.enabled ? AppColors.text : AppColors.subtitle,
            ),
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF8E9BAE),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: widget.prefixWidget ??
                  (widget.prefixIcon != null
                      ? Padding(
                          padding: const EdgeInsets.only(left: 16, right: 12),
                          child: Icon(
                            widget.prefixIcon,
                            color: hasError ? AppColors.error : AppColors.pink,
                            size: 24,
                          ),
                        )
                      : null),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 52,
                minHeight: 24,
              ),
              suffixIcon: widget.isPassword
                  ? Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: hasError ? AppColors.error : AppColors.pink,
                          size: 24,
                        ),
                        onPressed: _togglePasswordVisibility,
                        tooltip: _obscureText ? 'Show password' : 'Hide password',
                      ),
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: AppColors.error,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
