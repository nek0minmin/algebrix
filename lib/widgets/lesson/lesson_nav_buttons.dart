import 'package:flutter/material.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/secondary_button.dart';

class LessonNavButtons extends StatefulWidget {
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final bool showBack;
  final bool isNextEnabled;
  final bool isLoading;

  const LessonNavButtons({
    super.key,
    this.onBack,
    required this.onNext,
    this.nextLabel = 'Continue',
    this.showBack = true,
    this.isNextEnabled = true,
    this.isLoading = false,
  });

  @override
  State<LessonNavButtons> createState() => _LessonNavButtonsState();
}

class _LessonNavButtonsState extends State<LessonNavButtons>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.showBack)
                Expanded(
                  flex: 1,
                  child: SecondaryButton(
                    label: 'Back',
                    onPressed: widget.onBack,
                  ),
                )
              else
                const Spacer(flex: 1),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: widget.nextLabel,
                  onPressed: widget.isNextEnabled ? widget.onNext : null,
                  isLoading: widget.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
