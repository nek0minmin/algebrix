import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_form_screen.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/widgets/ai_feedback_card.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:algebrix/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NoteDetailScreen extends StatefulWidget {
  const NoteDetailScreen({super.key, required this.note});

  final StudyNote note;

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late StudyNote _displayNote;

  @override
  void initState() {
    super.initState();
    _displayNote = widget.note;
  }

  StudyNote _latestNote(NotesProvider provider) {
    for (final candidate in provider.notes) {
      if (candidate.id == widget.note.id) return candidate;
    }
    return _displayNote;
  }

  Future<void> _edit() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteFormScreen(note: _displayNote)),
    );
    if (!mounted) return;
    // Refresh note from provider AFTER the transition animation completes —
    // avoids rebuilding mid-transition which causes RenderTransform hasSize errors.
    final provider = context.read<NotesProvider>();
    setState(() {
      _displayNote = _latestNote(provider);
    });
    if (updated == true) {
      SoundService.playComplete();
      showAlgebrixSnackBar(
        context,
        message: 'Study note updated.',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _delete() async {
    context.read<NotesProvider>().clearError();
    final deleted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeleteNoteDialog(note: _displayNote),
    );
    if (deleted == true && context.mounted) {
      SoundService.playComplete();
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use context.read (NOT watch) to avoid rebuilds during route transitions.
    // Note data is refreshed manually in _edit() after navigation returns.
    final provider = context.read<NotesProvider>();
    final isDeleting = provider.isDeletingNote(_displayNote.id);
    final aiFeedback = _displayNote.aiFeedbackResult;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const SecondaryPageAppBar(
        title: 'Note details',
        supportingText: 'Your explanation, saved.',
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LessonChip(label: noteLessonLabel(_displayNote.lessonId)),
                  const SizedBox(height: 14),
                  Text(
                    _displayNote.title,
                    style: AppTextStyles.heading1.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: AppColors.subtitle,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        formatNoteUpdatedAt(_displayNote.updatedAt),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _ExplanationCard(content: _displayNote.displayContent),
                  if (aiFeedback != null) ...[
                    const SizedBox(height: 20),
                    AiFeedbackCard(feedback: aiFeedback),
                  ],
                  const SizedBox(height: 20),
                  _NoteActions(
                    isDeleting: isDeleting,
                    onEdit: _edit,
                    onDelete: _delete,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 5,
              color: AppColors.pink,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.extraLightPink,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.functions_rounded,
                        color: AppColors.pink,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'My explanation',
                      style: AppTextStyles.subtitle1.copyWith(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  content,
                  style: AppTextStyles.body1.copyWith(height: 1.65),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteActions extends StatelessWidget {
  const _NoteActions({
    required this.isDeleting,
    required this.onEdit,
    required this.onDelete,
  });

  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final editButton = Tooltip(
      message: 'Edit study note',
      child: OutlinedButton.icon(
        key: const Key('edit-note-button'),
        onPressed: isDeleting ? null : onEdit,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: const Text('Edit note'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          foregroundColor: AppColors.pink,
          side: const BorderSide(color: AppColors.pink, width: 1.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonSmall,
        ),
      ),
    );
    final deleteButton = Tooltip(
      message: 'Delete study note',
      child: OutlinedButton.icon(
        key: const Key('delete-note-button'),
        onPressed: isDeleting ? null : onDelete,
        icon: const Icon(Icons.delete_outline_rounded, size: 18),
        label: const Text('Delete note'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: AppTextStyles.buttonSmall,
        ),
      ),
    );

    return Row(
      children: [
        Expanded(child: editButton),
        const SizedBox(width: 12),
        Expanded(child: deleteButton),
      ],
    );
  }
}

class _DeleteNoteDialog extends StatelessWidget {
  const _DeleteNoteDialog({required this.note});

  final StudyNote note;

  Future<void> _confirm(BuildContext context) async {
    final provider = context.read<NotesProvider>();
    final deleted = await provider.deleteNote(note.id);
    if (deleted && context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    final isDeleting = provider.isDeletingNote(note.id);

    return PopScope(
      canPop: !isDeleting,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
          ),
        ),
        title: Text(
          'Delete study note?',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w900),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '“${note.title}” will be permanently deleted. This can’t be undone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  provider.errorMessage!,
                  style: AppTextStyles.body2.copyWith(color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: isDeleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text('Keep note'),
          ),
          FilledButton(
            key: const Key('confirm-delete-note-button'),
            onPressed: isDeleting ? null : () => _confirm(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              textStyle: AppTextStyles.buttonSmall,
              minimumSize: const Size(96, 44),
            ),
            child: isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  const _LessonChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.extraLightPink,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.lightPink),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.darkPink,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String formatNoteUpdatedAt(DateTime timestamp) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = timestamp.toLocal();
  return 'Updated ${months[local.month - 1]} ${local.day}, ${local.year}';
}
