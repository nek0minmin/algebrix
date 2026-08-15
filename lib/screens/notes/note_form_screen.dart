import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  String? _lessonId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title);
    _contentController = TextEditingController(text: widget.note?.content);
    _lessonId = noteLessonOptionFor(widget.note?.lessonId ?? '')?.lessonId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lesson = noteLessonOptionFor(_lessonId!);
    if (lesson == null) return;

    FocusManager.instance.primaryFocus?.unfocus();
    final notesProvider = context.read<NotesProvider>();
    final success = widget.isEditing
        ? await notesProvider.updateNote(
            noteId: widget.note!.id,
            moduleId: lesson.moduleId,
            lessonId: lesson.lessonId,
            title: _titleController.text,
            content: _contentController.text,
          )
        : await notesProvider.createNote(
            moduleId: lesson.moduleId,
            lessonId: lesson.lessonId,
            title: _titleController.text,
            content: _contentController.text,
          );

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notesProvider.errorMessage ??
              'Your study note could not be saved. Please try again.',
        ),
      ),
    );
  }

  void _insertPrompt(_ThinkingPrompt prompt) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Make a little room before adding this prompt.'),
        ),
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
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel(
                      label: 'Lesson',
                      helper: 'Connect this note to what you are learning.',
                    ),
                    const SizedBox(height: 10),
                    FormField<String>(
                      key: const Key('note-lesson-field'),
                      initialValue: _lessonId,
                      validator: (value) => value == null
                          ? 'Choose a lesson for this note.'
                          : null,
                      builder: (field) => _LessonSelector(
                        value: _lessonId,
                        enabled: !isSaving,
                        errorText: field.errorText,
                        onSelected: (value) {
                          setState(() => _lessonId = value);
                          field.didChange(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _FieldLabel(label: 'Note title'),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: const Key('note-title-field'),
                      controller: _titleController,
                      enabled: !isSaving,
                      style: AppTextStyles.body1,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      inputFormatters: [LengthLimitingTextInputFormatter(100)],
                      decoration: _fieldDecoration(
                        hintText: 'e.g. Why constants stay fixed',
                        icon: Icons.title_rounded,
                        radius: 18,
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        if (length < 3) return 'Enter at least 3 characters.';
                        if (length > 100) {
                          return 'Use no more than 100 characters.';
                        }
                        return null;
                      },
                    ),
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
                      ),
                      validator: (value) {
                        final length = value?.trim().length ?? 0;
                        if (length < 3) return 'Enter at least 3 characters.';
                        if (length > 2000) {
                          return 'Use no more than 2000 characters.';
                        }
                        return null;
                      },
                    ),
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
    return FractionallySizedBox(
      heightFactor: 0.76,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Choose a lesson',
              style: AppTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your note will stay connected to this topic.',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: noteLessonOptions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = noteLessonOptions[index];
                  final selected = option.lessonId == selectedLessonId;
                  return Material(
                    color: selected ? AppColors.extraLightPink : AppColors.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: selected
                            ? AppColors.lightPink
                            : AppColors.border,
                      ),
                    ),
                    child: InkWell(
                      key: Key('lesson-option-${option.lessonId}'),
                      onTap: () => Navigator.of(context).pop(option.lessonId),
                      borderRadius: BorderRadius.circular(16),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 54),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  option.label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body1.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (selected) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.pink,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
