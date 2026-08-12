import 'package:flutter/material.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/models/lesson_content_model.dart';

class TermSelectionActivity extends StatefulWidget {
  const TermSelectionActivity({
    super.key,
    required this.data,
    required this.onAnswered,
    this.enabled = true,
  });

  final TermSelectionActivityData data;
  final Future<void> Function(bool isCorrect) onAnswered;
  final bool enabled;

  @override
  State<TermSelectionActivity> createState() => _TermSelectionActivityState();
}

class _TermSelectionActivityState extends State<TermSelectionActivity> {
  final Set<String> _selectedIds = {};
  bool _submitting = false;

  void _toggle(TermToken token) {
    if (!widget.enabled || _submitting) return;
    setState(() {
      if (!_selectedIds.add(token.id)) _selectedIds.remove(token.id);
    });
  }

  Future<void> _check() async {
    if (!widget.enabled || _submitting || _selectedIds.isEmpty) return;
    final expectedIds = widget.data.tokens
        .where((token) => token.isTerm)
        .map((token) => token.id)
        .toSet();
    final isCorrect =
        _selectedIds.length == expectedIds.length &&
        _selectedIds.containsAll(expectedIds);
    setState(() => _submitting = true);
    try {
      await widget.onAnswered(isCorrect);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !_submitting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final token in widget.data.tokens)
              Semantics(
                button: true,
                selected: _selectedIds.contains(token.id),
                label: 'Expression part ${token.label}',
                child: InkWell(
                  key: ValueKey('term-token-${token.id}'),
                  onTap: enabled ? () => _toggle(token) : null,
                  borderRadius: BorderRadius.circular(14),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedIds.contains(token.id)
                          ? AppColors.extraLightPink
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedIds.contains(token.id)
                            ? AppColors.pink
                            : AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      token.label,
                      maxLines: 1,
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: enabled && _selectedIds.isNotEmpty ? _check : null,
          child: Text(_submitting ? 'Checking…' : 'Check terms'),
        ),
      ],
    );
  }
}
