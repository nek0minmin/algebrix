import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_detail_screen.dart';
import 'package:algebrix/screens/notes/note_form_screen.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  Future<void> _createNote(BuildContext context) async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NoteFormScreen()));
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Study note created.')));
    }
  }

  Future<void> _openNote(BuildContext context, StudyNote note) async {
    context.read<NotesProvider>().selectNote(note.id);
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
    if (deleted == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Study note deleted.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              RootPageHeader(
                title: 'Notes',
                subtitle: 'Write the why in your own words.',
                trailing: FilledButton.icon(
                  key: const Key('new-note-button'),
                  onPressed: () => _createNote(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New note'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                    textStyle: AppTextStyles.buttonSmall,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                compactTrailing: IconButton.filled(
                  key: const Key('new-note-button-compact'),
                  tooltip: 'New note',
                  onPressed: () => _createNote(context),
                  icon: const Icon(Icons.add_rounded),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    backgroundColor: AppColors.pink,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: _NotesBody(
                  provider: provider,
                  onCreate: () => _createNote(context),
                  onOpen: (note) => _openNote(context, note),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesBody extends StatelessWidget {
  const _NotesBody({
    required this.provider,
    required this.onCreate,
    required this.onOpen,
  });

  final NotesProvider provider;
  final VoidCallback onCreate;
  final ValueChanged<StudyNote> onOpen;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.notes.isEmpty) {
      return const _LoadingNotes();
    }
    if (provider.errorMessage != null && provider.notes.isEmpty) {
      return _NotesError(
        message: provider.errorMessage!,
        onRetry: () => provider.loadNotes(),
      );
    }
    if (provider.notes.isEmpty) {
      return _EmptyNotes(onCreate: onCreate);
    }

    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: () async {
        await provider.loadNotes();
      },
      child: ListView.separated(
        key: const PageStorageKey('study-notes-list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        itemCount: provider.notes.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final note = provider.notes[index];
          return _NoteCard(note: note, onTap: () => onOpen(note));
        },
      ),
    );
  }
}

class _LoadingNotes extends StatelessWidget {
  const _LoadingNotes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.pink),
          const SizedBox(height: 14),
          Text('Loading your notes…', style: AppTextStyles.subtitle1),
        ],
      ),
    );
  }
}

class _NotesError extends StatelessWidget {
  const _NotesError({required this.message, required this.onRetry});

  final String message;
  final Future<bool> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 54,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              'We couldn’t load your study notes.',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: PrimaryButton(
                label: 'Try again',
                onPressed: () => onRetry(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AppAssets.xyPointing,
                width: 112,
                height: 112,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Text(
                'Your ideas belong here',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Save explanations in your own words and revisit the why anytime.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 240,
                child: PrimaryButton(
                  label: 'Create your first note',
                  icon: Icons.add_rounded,
                  onPressed: onCreate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note, required this.onTap});

  final StudyNote note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        key: Key('study-note-${note.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 5, color: AppColors.pink),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.extraLightPink,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.lightPink),
                          ),
                          child: Text(
                            noteLessonLabel(note.lessonId),
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.darkPink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          note.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          note.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Text(
                          formatNoteUpdatedAt(note.updatedAt),
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.pink,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
