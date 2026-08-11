import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';

/// Clean, crisp rounded (pill-shaped) dynamic text input field widget for Algebrix.
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
    this.borderRadius = 30.0,
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

    // Crisp white background fill instead of pink fill
    Color effectiveFill;
    if (!widget.enabled) {
      effectiveFill = AppColors.divider.withValues(alpha: 0.3);
    } else if (hasError) {
      effectiveFill = AppColors.error.withValues(alpha: 0.03);
    } else if (_isFocused) {
      effectiveFill = widget.activeFillColor ?? const Color(0xFFFAFAFA);
    } else {
      effectiveFill = widget.fillColor ?? Colors.white;
    }

    Color effectiveBorderColor;
    if (hasError) {
      effectiveBorderColor = AppColors.error;
    } else if (_isFocused) {
      effectiveBorderColor = widget.focusedBorderColor ?? AppColors.pink;
    } else {
      effectiveBorderColor = AppColors.border;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Text(
              widget.label!,
              style: AppTextStyles.subtitle2.copyWith(
                color: hasError
                    ? AppColors.error
                    : (_isFocused ? AppColors.pink : AppColors.text),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: effectiveFill,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: effectiveBorderColor,
              width: _isFocused || hasError ? 2.0 : 1.2,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.pink.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
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
            style: AppTextStyles.body1.copyWith(
              color: widget.enabled ? AppColors.text : AppColors.subtitle,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              filled: false,
              fillColor: Colors.transparent,
              hintText: widget.hintText,
              hintStyle: AppTextStyles.body1.copyWith(
                color: AppColors.subtitle.withValues(alpha: 0.6),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              prefixIcon: widget.prefixWidget ??
                  (widget.prefixIcon != null
                      ? Icon(
                          widget.prefixIcon,
                          color: hasError
                              ? AppColors.error
                              : (_isFocused ? AppColors.pink : AppColors.subtitle),
                          size: 22,
                        )
                      : null),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: _isFocused ? AppColors.pink : AppColors.subtitle,
                        size: 22,
                      ),
                      onPressed: _togglePasswordVisibility,
                      tooltip: _obscureText ? 'Show password' : 'Hide password',
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 14),
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
