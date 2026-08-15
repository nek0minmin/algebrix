-- Account-owned study notes for the Algebrix CRUD assignment.
-- Apply after the base profile/auth schema. This migration is rerunnable.

BEGIN;

CREATE TABLE IF NOT EXISTS public.study_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT study_notes_module_id_valid CHECK (
    module_id = BTRIM(module_id)
    AND CHAR_LENGTH(module_id) BETWEEN 1 AND 64
    AND module_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT study_notes_lesson_id_valid CHECK (
    lesson_id = BTRIM(lesson_id)
    AND CHAR_LENGTH(lesson_id) BETWEEN 1 AND 64
    AND lesson_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT study_notes_title_valid CHECK (
    title = BTRIM(title)
    AND CHAR_LENGTH(title) BETWEEN 3 AND 100
  ),
  CONSTRAINT study_notes_content_valid CHECK (
    content = BTRIM(content)
    AND CHAR_LENGTH(content) BETWEEN 3 AND 2000
  )
);

CREATE INDEX IF NOT EXISTS study_notes_user_updated_idx
  ON public.study_notes (user_id, updated_at DESC);

CREATE INDEX IF NOT EXISTS study_notes_user_lesson_idx
  ON public.study_notes (user_id, module_id, lesson_id);

CREATE OR REPLACE FUNCTION public.algebrix_prepare_study_note_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  -- These values are server-owned, even if a future grant is accidentally
  -- widened. Students may only edit the lesson link and note text.
  NEW.id := OLD.id;
  NEW.user_id := OLD.user_id;
  NEW.created_at := OLD.created_at;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.algebrix_prepare_study_note_update() FROM PUBLIC;

DROP TRIGGER IF EXISTS study_notes_set_updated_at ON public.study_notes;
CREATE TRIGGER study_notes_set_updated_at
  BEFORE UPDATE ON public.study_notes
  FOR EACH ROW
  EXECUTE FUNCTION public.algebrix_prepare_study_note_update();

ALTER TABLE public.study_notes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create own study notes" ON public.study_notes;
DROP POLICY IF EXISTS "Users can view own study notes" ON public.study_notes;
DROP POLICY IF EXISTS "Users can update own study notes" ON public.study_notes;
DROP POLICY IF EXISTS "Users can delete own study notes" ON public.study_notes;

CREATE POLICY "Users can create own study notes"
  ON public.study_notes
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can view own study notes"
  ON public.study_notes
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own study notes"
  ON public.study_notes
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own study notes"
  ON public.study_notes
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

REVOKE ALL ON TABLE public.study_notes FROM anon, authenticated;
GRANT SELECT, DELETE ON TABLE public.study_notes TO authenticated;
GRANT INSERT (module_id, lesson_id, title, content)
  ON TABLE public.study_notes TO authenticated;
GRANT UPDATE (module_id, lesson_id, title, content)
  ON TABLE public.study_notes TO authenticated;

COMMENT ON TABLE public.study_notes IS
  'Account-owned lesson study notes supporting student CRUD operations.';
COMMENT ON COLUMN public.study_notes.user_id IS
  'Defaults to auth.uid(); RLS prevents cross-account access.';

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
