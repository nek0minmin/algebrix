-- Quiz review log: a rolling window of the learner's 3 most recent attempts
-- per module, kept so questions can be revisited after the quiz is over.
-- Apply after 202608240002_module_quizzes.sql. This migration is rerunnable.
--
-- Deliberately separate from module_quiz_progress: that table owns scoring and
-- module unlocks, this one is a read-only-after-write archive. Nothing here
-- feeds back into progression, so quiz logic is untouched.

BEGIN;

-- ============================================================================
-- 1. Attempt archive
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.quiz_attempt_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,                    -- e.g. 'module1'
  module_title TEXT NOT NULL,                 -- denormalized for the review list
  score INT NOT NULL,                         -- correct answers in this attempt
  total_questions INT NOT NULL,
  items JSONB NOT NULL,                       -- full question + chosen answer log
  taken_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT quiz_attempt_reviews_module_id_valid CHECK (
    module_id = BTRIM(module_id)
    AND CHAR_LENGTH(module_id) BETWEEN 1 AND 64
    AND module_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT quiz_attempt_reviews_module_title_valid CHECK (
    module_title = BTRIM(module_title)
    AND CHAR_LENGTH(module_title) BETWEEN 1 AND 120
  ),
  CONSTRAINT quiz_attempt_reviews_total_valid CHECK (
    total_questions BETWEEN 1 AND 50
  ),
  CONSTRAINT quiz_attempt_reviews_score_valid CHECK (
    score >= 0 AND score <= total_questions
  ),
  CONSTRAINT quiz_attempt_reviews_items_shape CHECK (
    jsonb_typeof(items) = 'array'
    AND jsonb_array_length(items) BETWEEN 1 AND 50
    AND OCTET_LENGTH(items::TEXT) <= 60000
  )
);

COMMENT ON TABLE public.quiz_attempt_reviews IS
  'Rolling archive of the 3 most recent quiz attempts per module, per user.';
COMMENT ON COLUMN public.quiz_attempt_reviews.items IS
  'JSON array of {question, options, correctIndex, selectedIndex, explanation, subLessonTitle, difficulty}. selectedIndex is -1 when unanswered.';

CREATE INDEX IF NOT EXISTS quiz_attempt_reviews_user_module_taken_idx
  ON public.quiz_attempt_reviews (user_id, module_id, taken_at DESC);

CREATE INDEX IF NOT EXISTS quiz_attempt_reviews_user_taken_idx
  ON public.quiz_attempt_reviews (user_id, taken_at DESC);

-- ============================================================================
-- 2. Retention -- keep only the newest 3 attempts per module
-- ============================================================================
-- Enforced server-side so the client never has to prune, and so an offline
-- client that syncs a backlog cannot blow past the cap.

CREATE OR REPLACE FUNCTION public.algebrix_trim_quiz_attempt_reviews()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  DELETE FROM public.quiz_attempt_reviews AS stale
  WHERE stale.user_id = NEW.user_id
    AND stale.module_id = NEW.module_id
    AND stale.id NOT IN (
      SELECT keep.id
      FROM public.quiz_attempt_reviews AS keep
      WHERE keep.user_id = NEW.user_id
        AND keep.module_id = NEW.module_id
      ORDER BY keep.taken_at DESC, keep.id DESC
      LIMIT 3
    );
  RETURN NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.algebrix_trim_quiz_attempt_reviews() FROM PUBLIC;

DROP TRIGGER IF EXISTS quiz_attempt_reviews_enforce_retention
  ON public.quiz_attempt_reviews;
CREATE TRIGGER quiz_attempt_reviews_enforce_retention
  AFTER INSERT ON public.quiz_attempt_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.algebrix_trim_quiz_attempt_reviews();

-- ============================================================================
-- 3. Row Level Security
-- ============================================================================
-- No UPDATE policy or grant: a recorded attempt is immutable. A learner can
-- read their own attempts and clear them, nothing else.

ALTER TABLE public.quiz_attempt_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can create own quiz attempt reviews"
  ON public.quiz_attempt_reviews;
DROP POLICY IF EXISTS "Users can view own quiz attempt reviews"
  ON public.quiz_attempt_reviews;
DROP POLICY IF EXISTS "Users can delete own quiz attempt reviews"
  ON public.quiz_attempt_reviews;

CREATE POLICY "Users can create own quiz attempt reviews"
  ON public.quiz_attempt_reviews
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can view own quiz attempt reviews"
  ON public.quiz_attempt_reviews
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own quiz attempt reviews"
  ON public.quiz_attempt_reviews
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

REVOKE ALL ON TABLE public.quiz_attempt_reviews FROM anon, authenticated;
GRANT SELECT, DELETE ON TABLE public.quiz_attempt_reviews TO authenticated;
GRANT INSERT (module_id, module_title, score, total_questions, items)
  ON TABLE public.quiz_attempt_reviews TO authenticated;

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
