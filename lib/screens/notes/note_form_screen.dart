import 'dart:async';

import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/ai_notes_provider.dart';
import 'package:algebrix/core/providers/lesson_provider.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/note_correction_model.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/services/ai_tutor_service.dart';
import 'package:algebrix/widgets/ai_feedback_card.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/services/note_correction_service.dart';
import 'package:algebrix/widgets/notes/correction_suggestion_card.dart';
import 'package:algebrix/widgets/notes/correction_text_controller.dart';
import 'package:algebrix/widgets/notes/math_formatting_bar.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class NoteFormScreen extends StatefulWidget {
  const NoteFormScreen({super.key, this.note});

  final StudyNote? note;

  bool get isEditing => note != null;

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CorrectionTextEditingController _titleController;
  late final CorrectionTextEditingController _contentController;
  String? _lessonId;

  static const _correctionService = NoteCorrectionService();

  /// Every correction Xy found in the current note, across both fields.
  List<NoteCorrection> _corrections = const [];

  /// The correction whose suggestion card is open, if any.
  NoteCorrection? _activeCorrection;

  /// The correction currently showing a sparkle burst, cleared on a timer.
  NoteCorrection? _sparklingCorrection;
  Timer? _sparkleTimer;

  /// Last seen field text, used to tell a caret tap from a keystroke.
  String _lastTitleText = '';
  String _lastContentText = '';

  @override
  void initState() {
    super.initState();
    _titleController =
        CorrectionTextEditingController(text: widget.note?.title);
    _contentController = CorrectionTextEditingController(
      text: widget.note?.displayContent,
    );
    _lastTitleText = _titleController.text;
    _lastContentText = _contentController.text;
    _titleController.addListener(_handleTitleCaret);
    _contentController.addListener(_handleContentCaret);
    _lessonId = noteLessonOptionFor(widget.note?.lessonId ?? '')?.lessonId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        try {
          final aiProvider = context.read<AiNotesProvider?>();
          if (aiProvider != null) {
            if (widget.note?.aiFeedbackResult != null) {
              aiProvider.setFeedback(widget.note!.aiFeedbackResult!);
            } else {
              aiProvider.clearFeedback();
            }
          }
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _sparkleTimer?.cancel();
    _titleController.removeListener(_handleTitleCaret);
    _contentController.removeListener(_handleContentCaret);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Inline corrections ─────────────────────────────────────────────────────

  void _handleTitleCaret() => _handleCaretMove(
        NoteCorrectionTarget.title,
        _titleController,
        _lastTitleText,
        (value) => _lastTitleText = value,
      );

  void _handleContentCaret() => _handleCaretMove(
        NoteCorrectionTarget.body,
        _contentController,
        _lastContentText,
        (value) => _lastContentText = value,
      );

  /// Opens the suggestion card when the learner puts the caret inside a
  /// highlighted mistake.
  ///
  /// A [TextEditingController] fires for text edits and caret moves alike, so
  /// this only reacts when the text is unchanged — otherwise the card would pop
  /// open every time someone typed a letter inside a flagged word.
  void _handleCaretMove(
    NoteCorrectionTarget target,
    CorrectionTextEditingController controller,
    String previousText,
    ValueChanged<String> rememberText,
  ) {
    final text = controller.text;
    final textChanged = text != previousText;
    rememberText(text);
    if (textChanged) {
      // Editing invalidates stale highlights; drop any open card for this field.
      if (_activeCorrection?.target == target &&
          !(_activeCorrection?.matches(text) ?? false)) {
        setState(() => _activeCorrection = null);
      }
      return;
    }

    final selection = controller.selection;
    if (!selection.isValid || !selection.isCollapsed) return;

    final hit = controller.correctionAt(selection.baseOffset);
    if (hit?.id == _activeCorrection?.id) return;

    setState(() => _activeCorrection = hit);
  }

  /// Re-scans the note after an analysis and paints any mistakes Xy found.
  void _refreshCorrections(AiFeedbackResult? feedback) {
    final detected = _correctionService.detect(
      title: _titleController.text,
      body: _contentController.text,
      feedback: feedback,
    );

    setState(() {
      _corrections = detected;
      _activeCorrection = null;
      _syncControllerCorrections();
    });
  }

  void _syncControllerCorrections() {
    _titleController.corrections = _corrections
        .where((c) => c.target == NoteCorrectionTarget.title)
        .toList();
    _contentController.corrections = _corrections
        .where((c) => c.target == NoteCorrectionTarget.body)
        .toList();
  }

  /// Swaps the flagged word for the chosen suggestion, keeping the caret and
  /// every other highlight in the right place.
  void _applyCorrection(NoteCorrection correction, String replacement) {
    final controller = correction.target == NoteCorrectionTarget.title
        ? _titleController
        : _contentController;

    final result = applyNoteCorrection(
      text: controller.text,
      corrections: _corrections,
      correction: correction,
      replacement: replacement,
    );
    if (result.text == controller.text) return;

    // Assigning .value rather than .text keeps the caret at the end of the
    // replaced word instead of jumping to the start of the field.
    controller.value = TextEditingValue(
      text: result.text,
      selection: TextSelection.collapsed(offset: result.applied.end),
    );

    if (correction.target == NoteCorrectionTarget.title) {
      _lastTitleText = result.text;
    } else {
      _lastContentText = result.text;
    }

    _sparkleTimer?.cancel();
    setState(() {
      _corrections = result.corrections;
      _activeCorrection = result.applied;
      _sparklingCorrection = result.applied;
      _syncControllerCorrections();
    });

    SoundService.playStar();

    _sparkleTimer = Timer(const Duration(milliseconds: 950), () {
      if (mounted) setState(() => _sparklingCorrection = null);
    });
  }

  /// Sparkle overlay for [target], positioned over the corrected word.
  ///
  /// The word's rectangle is measured with a [TextPainter] laid out at the same
  /// width and style as the field. Decorative only — if the geometry cannot be
  /// resolved the burst is simply skipped.
  Widget _sparkleOverlay(NoteCorrectionTarget target, EdgeInsets padding) {
    final sparkling = _sparklingCorrection;
    if (sparkling == null || sparkling.target != target) {
      return const SizedBox.shrink();
    }

    final controller = target == NoteCorrectionTarget.title
        ? _titleController
        : _contentController;

    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth - padding.horizontal;
            if (maxWidth <= 0) return const SizedBox.shrink();

            final painter = TextPainter(
              text: TextSpan(
                text: controller.text,
                style: AppTextStyles.body1,
              ),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: maxWidth);

            final boxes = painter.getBoxesForSelection(
              TextSelection(
                baseOffset: sparkling.start,
                extentOffset: sparkling.end,
              ),
            );
            if (boxes.isEmpty) return const SizedBox.shrink();

            final rect = boxes.first.toRect();
            final burstSize = Size(rect.width + 28, rect.height + 28);
            final left = padding.left + rect.center.dx - burstSize.width / 2;
            final top = padding.top + rect.center.dy - burstSize.height / 2;

            // Off-screen in a scrolled multi-line field: skip rather than
            // draw the burst in the wrong place.
            if (top < -burstSize.height ||
                top > constraints.maxHeight) {
              return const SizedBox.shrink();
            }

            return Stack(
              children: [
                Positioned(
                  left: left.clamp(0.0, constraints.maxWidth),
                  top: top,
                  child: CorrectionSparkleBurst(size: burstSize),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The suggestion card for [target], shown directly beneath its field.
  Widget _correctionCard(NoteCorrectionTarget target) {
    final active = _activeCorrection;
    if (active == null || active.target != target) {
      return const SizedBox.shrink();
    }

    return CorrectionSuggestionCard(
      correction: active,
      onApply: (replacement) => _applyCorrection(active, replacement),
      onDismiss: () => setState(() => _activeCorrection = null),
    );
  }

  Future<void> _analyzeWithAi() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (content.length < 20) {
      _formKey.currentState?.validate();
      showAlgebrixSnackBar(
        context,
        message: 'Write at least 20 characters so Xy can analyze your note!',
        icon: Icons.lightbulb_outline_rounded,
        isError: true,
      );
      return;
    }

    _formKey.currentState?.validate();
    final aiProvider = context.read<AiNotesProvider?>();
    if (aiProvider == null) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final lessonLabel = noteLessonOptionFor(_lessonId ?? '')?.label ?? 'Algebra';
    final topicContext = title.isNotEmpty ? '$title (Lesson: $lessonLabel)' : lessonLabel;

    if (content.toLowerCase().contains('problem') || content.contains('=')) {
      await aiProvider.checkWorkedExample(problem: topicContext, solution: content);
    } else if (content.toLowerCase().contains('question') || content.endsWith('?')) {
      await aiProvider.getSocraticHint(question: '$content (Context: $topicContext)');
    } else {
      await aiProvider.evaluateExplanation(topic: topicContext, explanation: content);
    }

    if (!mounted) return;

    // Check if Xy's analysis suggests a better-fitting lesson tag
    final newFeedback = aiProvider.currentFeedback;

    // Paint any mistakes the feedback names onto the note itself.
    _refreshCorrections(newFeedback);

    if (newFeedback != null) {
      SoundService.playStar();
      if (newFeedback.providerUsed != 'Algebrix Topic Guard') {
        final suggestedLesson = detectBestFittingLesson(
          title: title,
          content: content,
          keyConcept: newFeedback.keyConcept,
          aiTitle: newFeedback.title,
          aiMessage: newFeedback.message,
        );

        if (suggestedLesson != null && suggestedLesson.lessonId != _lessonId) {
          setState(() {
            _lessonId = suggestedLesson.lessonId;
          });
          showAlgebrixSnackBar(
            context,
            message: '✨ Xy updated lesson tag to "${suggestedLesson.title}" based on your note!',
            icon: Icons.auto_awesome_rounded,
          );
        }
      }
    }
  }

  Future<void> _submit() async {
    final rawTitle = _titleController.text.trim();
    final rawContent = _contentController.text.trim();

    // If title and content are provided but user hasn't explicitly selected a lesson,
    // auto-detect best fitting lesson or fallback to Module 1 so off-topic/general notes save smoothly.
    if (_lessonId == null && rawTitle.length >= 3 && rawContent.length >= 20) {
      final detected = detectBestFittingLesson(
        title: rawTitle,
        content: rawContent,
      );
      setState(() {
        _lessonId = detected?.lessonId ?? 'm1_l1';
      });
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lesson = noteLessonOptionFor(_lessonId ?? 'm1_l1') ?? noteLessonOptions.first;

    FocusManager.instance.primaryFocus?.unfocus();

    final service = AiTutorService();
    final combinedNoteText = '$rawTitle\n$rawContent';

    final notesProvider = context.read<NotesProvider>();
    final aiProvider = context.read<AiNotesProvider?>();
    final currentFeedback = aiProvider?.currentFeedback;

    final isAiDetectedOffTopic = currentFeedback != null &&
        (currentFeedback.providerUsed == 'Algebrix Topic Guard' ||
            currentFeedback.title.toLowerCase().contains('focus on algebra') ||
            currentFeedback.message.toLowerCase().contains('recipe') ||
            currentFeedback.message.toLowerCase().contains('lumpia') ||
            currentFeedback.message.toLowerCase().contains('food') ||
            currentFeedback.message.toLowerCase().contains('cake') ||
            currentFeedback.message.toLowerCase().contains('ice cream') ||
            currentFeedback.keyConcept == 'Algebrix Topic Boundary');

    // Check if the note content or AI feedback indicates off-topic
    if (service.isOffTopicText(combinedNoteText) || isAiDetectedOffTopic) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.extraLightPink,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      AppAssets.xyNotes,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Off-topic Note Detected',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This note doesn\'t seem to be related to algebra. Do you still want to proceed with saving it?',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel & edit',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: AppColors.text,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppColors.pink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Save anyway',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      if (confirm != true) return;
    }

    // Encode AI feedback persistently into note content if generated
    final encodedContent = StudyNote.encodeContentWithAiFeedback(
      _contentController.text,
      currentFeedback,
    );

    final success = widget.isEditing
        ? await notesProvider.updateNote(
            noteId: widget.note!.id,
            moduleId: lesson.moduleId,
            lessonId: lesson.lessonId,
            title: _titleController.text,
            content: encodedContent,
          )
        : await notesProvider.createNote(
            moduleId: lesson.moduleId,
            lessonId: lesson.lessonId,
            title: _titleController.text,
            content: encodedContent,
          );

    if (!mounted) return;
    if (success) {
      SoundService.playComplete();
      Navigator.of(context).pop(true);
      return;
    }

    showAlgebrixSnackBar(
      context,
      message: notesProvider.errorMessage ??
          'Your study note could not be saved. Please try again.',
      isError: true,
    );
  }

  void _insertPrompt(_ThinkingPrompt prompt) {
    SoundService.playClick();
    final value = _contentController.value;
    final rawOffset = value.selection.isValid
        ? value.selection.extentOffset
        : value.text.length;
    final offset = rawOffset.clamp(0, value.text.length);
    final before = value.text.substring(0, offset);
    final after = value.text.substring(offset);
    final prefix = before.trim().isEmpty ? '' : '\n\n';
    final suffix = after.trim().isEmpty ? '' : '\n\n';
    final insertion = '$prefix${prompt.template}$suffix';
    final nextText = '$before$insertion$after';

    if (nextText.length > 2000) {
      showAlgebrixSnackBar(
        context,
        message: 'Make a little room before adding this prompt.',
        isError: true,
      );
      return;
    }

    _contentController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: offset + insertion.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<NotesProvider>().isSaving;
    final aiProvider = context.watch<AiNotesProvider?>();
    final isAnalyzing = aiProvider?.isAnalyzing ?? false;
    final currentFeedback = aiProvider?.currentFeedback;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: SecondaryPageAppBar(
        title: widget.isEditing ? 'Edit note' : 'New note',
        supportingText: widget.isEditing
            ? 'Make your explanation even clearer.'
            : 'Explain one idea in your own words.',
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _FieldLabel(
                      label: 'Lesson tag',
                      helper:
                          'Connect your note to an Algebra module so it stays organized.',
                    ),
                    const SizedBox(height: 10),
                    FormField<String>(
                      initialValue: _lessonId,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) => (_lessonId == null && value == null)
                          ? 'Choose a lesson for this note.'
                          : null,
                      builder: (field) => _LessonSelector(
                        value: _lessonId,
                        enabled: !isSaving,
                        errorText: field.errorText,
                        onSelected: (value) {
                          setState(() => _lessonId = value);
                          field.didChange(value);
                          field.validate();
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _FieldLabel(label: 'Note title'),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        TextFormField(
                          key: const Key('note-title-field'),
                          controller: _titleController,
                          enabled: !isSaving,
                          style: AppTextStyles.body1,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.next,
                          maxLength: 100,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                          decoration: _fieldDecoration(
                            hintText: 'e.g. Why constants stay fixed',
                            icon: Icons.title_rounded,
                            radius: 18,
                          ),
                          validator: (value) {
                            final length = value?.trim().length ?? 0;
                            if (length < 3) {
                              return 'Enter at least 3 characters.';
                            }
                            if (length > 100) {
                              return 'Use no more than 100 characters.';
                            }
                            return null;
                          },
                        ),
                        // Leading icon plus field padding, so the burst lands
                        // over the word rather than the field origin.
                        _sparkleOverlay(
                          NoteCorrectionTarget.title,
                          const EdgeInsets.fromLTRB(48, 16, 16, 16),
                        ),
                      ],
                    ),
                    _correctionCard(NoteCorrectionTarget.title),
                    const SizedBox(height: 18),
                    const _FieldLabel(
                      label: 'Start with a thinking prompt',
                      helper:
                          'Choose a structure, then make the explanation your own.',
                    ),
                    const SizedBox(height: 10),
                    _PromptGrid(enabled: !isSaving, onSelected: _insertPrompt),
                    const SizedBox(height: 24),
                    const _FieldLabel(
                      label: 'Your explanation',
                      helper:
                          'Use words, examples, and equations that make sense to you.',
                    ),
                    const SizedBox(height: 10),

                    // Quick-Insert Math Formatting Bar & Exponent Palette
                    MathFormattingBar(
                      controller: _contentController,
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),

                    // Explanation Box with Floating FAB inside bottom right!
                    Stack(
                      children: [
                        TextFormField(
                          key: const Key('note-content-field'),
                          controller: _contentController,
                          enabled: !isSaving,
                          style: AppTextStyles.body1,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 8,
                          maxLines: 16,
                          maxLength: 2000,
                          inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                          decoration: _fieldDecoration(
                            hintText: 'Explain the idea in your own words…',
                            radius: 20,
                          ).copyWith(
                            contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 58),
                          ),
                          validator: (value) {
                            final length = value?.trim().length ?? 0;
                            if (length < 20) {
                              return 'Write at least 20 characters explaining your idea.';
                            }
                            if (length > 2000) {
                              return 'Use no more than 2000 characters.';
                            }
                            return null;
                          },
                        ),
                        _sparkleOverlay(
                          NoteCorrectionTarget.body,
                          const EdgeInsets.fromLTRB(16, 16, 16, 58),
                        ),
                        Positioned(
                          bottom: 34,
                          right: 14,
                          child: Material(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(99),
                            elevation: 2,
                            shadowColor: AppColors.pink.withValues(alpha: 0.2),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(99),
                              onTap: (isSaving || isAnalyzing)
                                  ? null
                                  : _analyzeWithAi,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(
                                    color: AppColors.pink,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isAnalyzing)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.pink,
                                        ),
                                      )
                                    else
                                      Image.asset(
                                        AppAssets.xyNotes,
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isAnalyzing
                                          ? "Thinking..."
                                          : "Ask Xy's Insights!",
                                      style: AppTextStyles.caption.copyWith(
                                        color: AppColors.darkPink,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    _correctionCard(NoteCorrectionTarget.body),

                    // Active Xy AI Feedback Card
                    if (currentFeedback != null) ...[
                      const SizedBox(height: 14),
                      AiFeedbackCard(
                        feedback: currentFeedback,
                        onClose: () => aiProvider?.clearFeedback(),
                        onChipSelected: (chipText) {
                          aiProvider?.getSocraticHint(question: chipText, hintType: chipText);
                        },
                      ),
                    ],

                    const SizedBox(height: 24),
                    PrimaryButton(
                      key: const Key('save-note-button'),
                      label: widget.isEditing ? 'Save changes' : 'Save note',
                      icon: Icons.check_rounded,
                      isLoading: isSaving,
                      onPressed: isSaving ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, this.helper});

  final String label;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.subtitle1.copyWith(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 3),
          Text(
            helper!,
            style: AppTextStyles.body2.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  IconData? icon,
  required double radius,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radius),
    borderSide: const BorderSide(color: AppColors.border),
  );
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTextStyles.body2.copyWith(color: AppColors.subtitle),
    counterStyle: AppTextStyles.caption,
    filled: true,
    fillColor: Colors.white,
    prefixIcon: icon == null
        ? null
        : Icon(icon, color: AppColors.pink, size: 21),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.pink, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
  );
}

class _LessonSelector extends StatelessWidget {
  const _LessonSelector({
    required this.value,
    required this.enabled,
    required this.onSelected,
    this.errorText,
  });

  final String? value;
  final bool enabled;
  final ValueChanged<String> onSelected;
  final String? errorText;

  Future<void> _openPicker(BuildContext context) async {
    if (!enabled) return;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: AppColors.text.withValues(alpha: 0.35),
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _LessonPickerSheet(selectedLessonId: value),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final option = value == null ? null : noteLessonOptionFor(value!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: errorText == null ? AppColors.border : AppColors.error,
              width: errorText == null ? 1 : 1.2,
            ),
          ),
          child: InkWell(
            key: const Key('note-lesson-selector-button'),
            onTap: enabled ? () => _openPicker(context) : null,
            borderRadius: BorderRadius.circular(18),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.extraLightPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.pink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option?.label ?? 'Choose a lesson',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body1.copyWith(
                          color: option == null
                              ? AppColors.subtitle
                              : AppColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.pink,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ],
    );
  }
}

class _LessonPickerSheet extends StatelessWidget {
  const _LessonPickerSheet({this.selectedLessonId});

  final String? selectedLessonId;

  @override
  Widget build(BuildContext context) {
    final lessonProvider = Provider.of<LessonProvider?>(context);

    // Group options by Module
    final module1Options = noteLessonOptions
        .where((opt) => opt.moduleId == 'module1')
        .toList(growable: false);
    final module2Options = noteLessonOptions
        .where((opt) => opt.moduleId == 'module2')
        .toList(growable: false);
    final module3Options = noteLessonOptions
        .where((opt) => opt.moduleId == 'module3')
        .toList(growable: false);

    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.extraLightPink,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: AppColors.darkPink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose a lesson',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.text,
                        ),
                      ),
                      Text(
                        'Select the lesson topic for your note.',
                        style: GoogleFonts.nunito(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  // Module 1 Section
                  _buildModuleHeader('Module 1 • Foundations of Algebra', AppColors.pink, AppColors.extraLightPink),
                  const SizedBox(height: 8),
                  ...module1Options.map((opt) => _buildLessonTile(context, opt, lessonProvider)),

                  const SizedBox(height: 16),

                  // Module 2 Section
                  _buildModuleHeader('Module 2 • Operations & Simplification', AppColors.purple, AppColors.lightPurple),
                  const SizedBox(height: 8),
                  ...module2Options.map((opt) => _buildLessonTile(context, opt, lessonProvider)),

                  const SizedBox(height: 16),

                  // Module 3 Section
                  _buildModuleHeader('Module 3 • Solving Equations', AppColors.mint, AppColors.mint.withValues(alpha: 0.15)),
                  const SizedBox(height: 8),
                  ...module3Options.map((opt) => _buildLessonTile(context, opt, lessonProvider)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleHeader(String title, Color accent, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        title,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: accent,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildLessonTile(BuildContext context, NoteLessonOption option, LessonProvider? lessonProvider) {
    final selected = option.lessonId == selectedLessonId;
    final isFinished = lessonProvider?.isLessonCompleted(option.lessonId) ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.extraLightPink : const Color(0xFFF9FAFC),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.pink : AppColors.border.withValues(alpha: 0.8),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          key: Key('lesson-option-${option.lessonId}'),
          onTap: () => Navigator.of(context).pop(option.lessonId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Lesson number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.pink : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? AppColors.pink : AppColors.border,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option.lessonNumber,
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Lesson title
                Expanded(
                  child: Text(
                    option.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                      color: selected ? AppColors.darkPink : AppColors.text,
                    ),
                  ),
                ),

                // Completed badge
                if (isFinished) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightMint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 12,
                          color: Color(0xFF00796B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Completed',
                          style: GoogleFonts.nunito(
                            color: const Color(0xFF00796B),
                            fontWeight: FontWeight.w900,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Selected Checkmark
                if (selected) ...[
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.pink,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromptGrid extends StatelessWidget {
  const _PromptGrid({required this.enabled, required this.onSelected});

  final bool enabled;
  final ValueChanged<_ThinkingPrompt> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 380 ? 2 : 1;
        final width = columns == 2
            ? (constraints.maxWidth - 10) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: thinkingPrompts
              .map(
                (prompt) => SizedBox(
                  width: width,
                  child: _PromptCard(
                    prompt: prompt,
                    enabled: enabled,
                    onTap: () => onSelected(prompt),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({
    required this.prompt,
    required this.enabled,
    required this.onTap,
  });

  final _ThinkingPrompt prompt;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      enabled: enabled,
      label: 'Insert ${prompt.label} prompt',
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            key: Key('note-prompt-${prompt.keyName}'),
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: prompt.surfaceColor,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        prompt.icon,
                        color: prompt.accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        prompt.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThinkingPrompt {
  const _ThinkingPrompt({
    required this.keyName,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.surfaceColor,
    required this.template,
  });

  final String keyName;
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color surfaceColor;
  final String template;
}

const thinkingPrompts = [
  _ThinkingPrompt(
    keyName: 'explain-why',
    label: 'Explain why',
    icon: Icons.lightbulb_outline_rounded,
    accentColor: AppColors.pink,
    surfaceColor: AppColors.extraLightPink,
    template: 'What I’m explaining:\n\nWhy it works:\n\nA simple example:\n',
  ),
  _ThinkingPrompt(
    keyName: 'worked-example',
    label: 'Worked example',
    icon: Icons.calculate_outlined,
    accentColor: AppColors.purple,
    surfaceColor: AppColors.lightPurple,
    template: 'Problem:\n\nMy steps:\n1. \n2. \n3. \n\nWhy each step works:\n',
  ),
  _ThinkingPrompt(
    keyName: 'mistake-reflection',
    label: 'Mistake reflection',
    icon: Icons.replay_rounded,
    accentColor: AppColors.warning,
    surfaceColor: AppColors.lightYellow,
    template:
        'Problem I tried:\n\nMy answer:\n\nWhat went wrong:\n\nWhat I’ll remember next time:\n',
  ),
  _ThinkingPrompt(
    keyName: 'question',
    label: 'Question',
    icon: Icons.help_outline_rounded,
    accentColor: AppColors.mint,
    surfaceColor: AppColors.lightMint,
    template: 'My question:\n\nWhat I already know:\n\nWhere I got stuck:\n',
  ),
];
