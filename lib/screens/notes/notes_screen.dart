import 'package:algebrix/core/constants/app_assets.dart';
import 'package:algebrix/core/constants/app_colors.dart';
import 'package:algebrix/core/constants/app_text_styles.dart';
import 'package:algebrix/core/providers/notes_provider.dart';
import 'package:algebrix/models/study_note_model.dart';
import 'package:algebrix/screens/notes/note_detail_screen.dart';
import 'package:algebrix/screens/notes/note_form_screen.dart';
import 'package:algebrix/screens/notes/note_lesson_options.dart';
import 'package:algebrix/widgets/app_snack_bar.dart';
import 'package:algebrix/widgets/primary_button.dart';
import 'package:algebrix/widgets/page_headers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:algebrix/widgets/search_bar_widget.dart';

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  Future<void> _createNote(BuildContext context) async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NoteFormScreen()));
    if (created == true && context.mounted) {
      showAlgebrixSnackBar(
        context,
        message: 'Study note created!',
        icon: Icons.check_circle_rounded,
      );
    }
  }

  Future<void> _openNote(BuildContext context, StudyNote note) async {
    context.read<NotesProvider>().selectNote(note.id);
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(note: note)),
    );
    if (deleted == true && context.mounted) {
      showAlgebrixSnackBar(
        context,
        message: 'Study note deleted.',
        icon: Icons.delete_outline_rounded,
      );
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
                subtitle: 'Keep your algebra ideas close.',
                mascotAsset: AppAssets.xyNotes,
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

class _NotesBody extends StatefulWidget {
  const _NotesBody({
    required this.provider,
    required this.onCreate,
    required this.onOpen,
  });

  final NotesProvider provider;
  final VoidCallback onCreate;
  final ValueChanged<StudyNote> onOpen;

  @override
  State<_NotesBody> createState() => _NotesBodyState();
}

class _NotesBodyState extends State<_NotesBody> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.provider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final displayNotes = provider.filteredNotes;

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
      return _EmptyNotes(onCreate: widget.onCreate);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: SearchBarWidget(
            controller: _searchController,
            onChanged: (query) => provider.setSearchQuery(query),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            children: [
              _SortChip(
                label: 'Newest',
                isSelected: provider.sortOption == NoteSortOption.newest,
                onTap: () => provider.setSortOption(NoteSortOption.newest),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Oldest',
                isSelected: provider.sortOption == NoteSortOption.oldest,
                onTap: () => provider.setSortOption(NoteSortOption.oldest),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'Title A-Z',
                isSelected: provider.sortOption == NoteSortOption.title,
                onTap: () => provider.setSortOption(NoteSortOption.title),
              ),
              const SizedBox(width: 8),
              _SortChip(
                label: 'By Lesson',
                isSelected: provider.sortOption == NoteSortOption.lesson,
                onTap: () => provider.setSortOption(NoteSortOption.lesson),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: displayNotes.isEmpty
              ? _EmptySearchResult(query: provider.searchQuery)
              : RefreshIndicator(
                  color: AppColors.pink,
                  onRefresh: () async {
                    await provider.loadNotes();
                  },
                  child: ListView.separated(
                    key: const PageStorageKey('study-notes-list'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    itemCount: displayNotes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final note = displayNotes[index];
                      return _NoteCard(note: note, onTap: () => widget.onOpen(note));
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: isSelected ? Colors.white : AppColors.text,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.white,
      selectedColor: AppColors.pink,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.pink : AppColors.border,
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.subtitle,
            ),
            const SizedBox(height: 12),
            Text(
              'No notes match "$query"',
              style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching with a different keyword or topic.',
              style: AppTextStyles.body2.copyWith(color: AppColors.subtitle),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.extraLightPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_alt_outlined,
                  size: 34,
                  color: AppColors.pink,
                  semanticLabel: 'Empty notes',
                ),
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
                          note.displayContent,
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
