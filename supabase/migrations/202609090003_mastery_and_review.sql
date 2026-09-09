-- Concept mastery & spaced review.
--
-- Two tables plus four RPCs that together answer: which concepts does this
-- learner keep missing, and when should each one come back?
--
--   lesson_answer_reviews    -- missed LESSON answers (quizzes already have
--                               quiz_attempt_reviews)
--   concept_review_schedule  -- Leitner-box spaced repetition, one row per
--                               lesson the learner has struggled with
--
-- Apply after 202609090002_quiz_attempt_reviews.sql. This migration is
-- rerunnable.
--
-- Design note: strength and miss_count are computed server-side inside
-- SECURITY DEFINER functions, so the client gets SELECT/DELETE on these tables
-- and no INSERT or UPDATE grant at all. A learner can read and clear their own
-- history, but cannot fabricate mastery.

BEGIN;

-- ============================================================================
-- 1. Lesson mistake log
-- ============================================================================
-- One row per (lesson, step) rather than per attempt: repeating the same
-- mistake bumps miss_count instead of appending, which is what makes
-- "you have missed this 3 times" possible.

CREATE TABLE IF NOT EXISTS public.lesson_answer_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  step_id TEXT NOT NULL,
  step_index INT NOT NULL DEFAULT 0,
  question TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]'::JSONB,
  correct_index INT NOT NULL DEFAULT -1,
  selected_index INT NOT NULL DEFAULT -1,
  explanation TEXT NOT NULL DEFAULT '',
  miss_count INT NOT NULL DEFAULT 1,
  resolved BOOLEAN NOT NULL DEFAULT FALSE,
  first_missed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_missed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ,
  UNIQUE (user_id, module_id, lesson_id, step_id),
  CONSTRAINT lesson_answer_reviews_module_id_valid CHECK (
    module_id = BTRIM(module_id)
    AND CHAR_LENGTH(module_id) BETWEEN 1 AND 64
    AND module_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT lesson_answer_reviews_lesson_id_valid CHECK (
    lesson_id = BTRIM(lesson_id)
    AND CHAR_LENGTH(lesson_id) BETWEEN 1 AND 64
    AND lesson_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT lesson_answer_reviews_step_id_valid CHECK (
    step_id = BTRIM(step_id)
    AND CHAR_LENGTH(step_id) BETWEEN 1 AND 64
    AND step_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT lesson_answer_reviews_question_valid CHECK (
    CHAR_LENGTH(question) BETWEEN 1 AND 1000
  ),
  CONSTRAINT lesson_answer_reviews_options_shape CHECK (
    jsonb_typeof(options) = 'array'
    AND jsonb_array_length(options) <= 12
    AND OCTET_LENGTH(options::TEXT) <= 8000
  ),
  CONSTRAINT lesson_answer_reviews_miss_count_valid CHECK (
    miss_count BETWEEN 1 AND 1000
  )
);

COMMENT ON TABLE public.lesson_answer_reviews IS
  'Open and resolved lesson-answer mistakes, one row per lesson step.';
COMMENT ON COLUMN public.lesson_answer_reviews.resolved IS
  'True once the learner later answered this step correctly.';

CREATE INDEX IF NOT EXISTS lesson_answer_reviews_user_open_idx
  ON public.lesson_answer_reviews (user_id, resolved, last_missed_at DESC);

CREATE INDEX IF NOT EXISTS lesson_answer_reviews_user_lesson_idx
  ON public.lesson_answer_reviews (user_id, lesson_id);

-- ============================================================================
-- 2. Spaced review schedule
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.concept_review_schedule (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  strength SMALLINT NOT NULL DEFAULT 0,
  due_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_outcome TEXT NOT NULL DEFAULT 'missed',
  last_reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, lesson_id),
  CONSTRAINT concept_review_schedule_module_id_valid CHECK (
    module_id = BTRIM(module_id)
    AND CHAR_LENGTH(module_id) BETWEEN 1 AND 64
    AND module_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT concept_review_schedule_lesson_id_valid CHECK (
    lesson_id = BTRIM(lesson_id)
    AND CHAR_LENGTH(lesson_id) BETWEEN 1 AND 64
    AND lesson_id ~ '^[A-Za-z0-9_-]+$'
  ),
  CONSTRAINT concept_review_schedule_strength_valid CHECK (
    strength BETWEEN 0 AND 5
  ),
  CONSTRAINT concept_review_schedule_outcome_valid CHECK (
    last_outcome IN ('missed', 'reviewed')
  )
);

COMMENT ON TABLE public.concept_review_schedule IS
  'Leitner-box spaced repetition state, one row per struggled-with lesson.';
COMMENT ON COLUMN public.concept_review_schedule.strength IS
  'Leitner box 0-5. Missing demotes by one, reviewing promotes by one.';

CREATE INDEX IF NOT EXISTS concept_review_schedule_user_due_idx
  ON public.concept_review_schedule (user_id, due_at);

-- ============================================================================
-- 3. Review interval ladder
-- ============================================================================

CREATE OR REPLACE FUNCTION public.algebrix_review_interval(p_strength SMALLINT)
RETURNS INTERVAL
LANGUAGE sql
IMMUTABLE
SET search_path = public, pg_temp
AS $$
  SELECT CASE p_strength
           WHEN 0 THEN INTERVAL '0 days'   -- due immediately
           WHEN 1 THEN INTERVAL '1 day'
           WHEN 2 THEN INTERVAL '3 days'
           WHEN 3 THEN INTERVAL '7 days'
           WHEN 4 THEN INTERVAL '14 days'
           ELSE INTERVAL '30 days'
         END;
$$;

COMMENT ON FUNCTION public.algebrix_review_interval(SMALLINT) IS
  'Leitner interval ladder: 0d, 1d, 3d, 7d, 14d, 30d.';

-- ============================================================================
-- 4. RPCs
-- ============================================================================
-- All four are SECURITY DEFINER and act only on auth.uid()'s own rows, which
-- is why the tables carry no INSERT/UPDATE grant.

CREATE OR REPLACE FUNCTION public.record_lesson_miss(
  p_module_id TEXT,
  p_lesson_id TEXT,
  p_step_id TEXT,
  p_step_index INT DEFAULT 0,
  p_question TEXT DEFAULT '',
  p_options JSONB DEFAULT '[]'::JSONB,
  p_correct_index INT DEFAULT -1,
  p_selected_index INT DEFAULT -1,
  p_explanation TEXT DEFAULT ''
)
RETURNS public.lesson_answer_reviews
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
  result public.lesson_answer_reviews;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required.'
      USING ERRCODE = '28000';
  END IF;

  INSERT INTO public.lesson_answer_reviews AS existing (
    user_id, module_id, lesson_id, step_id, step_index,
    question, options, correct_index, selected_index, explanation
  )
  VALUES (
    caller, p_module_id, p_lesson_id, p_step_id, GREATEST(p_step_index, 0),
    LEFT(COALESCE(p_question, ''), 1000),
    COALESCE(p_options, '[]'::JSONB),
    p_correct_index, p_selected_index,
    COALESCE(p_explanation, '')
  )
  ON CONFLICT (user_id, module_id, lesson_id, step_id) DO UPDATE
  SET miss_count = LEAST(existing.miss_count + 1, 1000),
      selected_index = EXCLUDED.selected_index,
      question = EXCLUDED.question,
      options = EXCLUDED.options,
      correct_index = EXCLUDED.correct_index,
      explanation = EXCLUDED.explanation,
      step_index = EXCLUDED.step_index,
      resolved = FALSE,
      resolved_at = NULL,
      last_missed_at = NOW()
  RETURNING * INTO result;

  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.record_lesson_miss IS
  'Records or re-counts a missed lesson answer for the calling learner.';

CREATE OR REPLACE FUNCTION public.resolve_lesson_miss(
  p_lesson_id TEXT,
  p_step_id TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
  affected INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required.'
      USING ERRCODE = '28000';
  END IF;

  UPDATE public.lesson_answer_reviews
  SET resolved = TRUE,
      resolved_at = NOW()
  WHERE user_id = caller
    AND lesson_id = p_lesson_id
    AND step_id = p_step_id
    AND resolved = FALSE;

  GET DIAGNOSTICS affected = ROW_COUNT;

  -- True only when this actually closed an open mistake, so the client knows
  -- whether the correct answer was a genuine recovery.
  RETURN affected > 0;
END;
$$;

COMMENT ON FUNCTION public.resolve_lesson_miss IS
  'Marks a lesson mistake resolved. Returns true if one was actually open.';

CREATE OR REPLACE FUNCTION public.schedule_concept_review(
  p_module_id TEXT,
  p_lesson_id TEXT,
  p_outcome TEXT
)
RETURNS public.concept_review_schedule
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
  current_strength SMALLINT;
  next_strength SMALLINT;
  result public.concept_review_schedule;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required.'
      USING ERRCODE = '28000';
  END IF;

  IF p_outcome NOT IN ('missed', 'reviewed') THEN
    RAISE EXCEPTION 'Outcome must be ''missed'' or ''reviewed'', got %',
      p_outcome USING ERRCODE = '22023';
  END IF;

  SELECT strength INTO current_strength
  FROM public.concept_review_schedule
  WHERE user_id = caller AND lesson_id = p_lesson_id;

  IF current_strength IS NULL THEN
    -- First encounter: a miss starts at box 0 (due now), a successful review
    -- starts at box 1 (due tomorrow).
    next_strength := CASE WHEN p_outcome = 'reviewed' THEN 1 ELSE 0 END;
  ELSIF p_outcome = 'reviewed' THEN
    next_strength := LEAST(current_strength + 1, 5);
  ELSE
    next_strength := GREATEST(current_strength - 1, 0);
  END IF;

  INSERT INTO public.concept_review_schedule AS existing (
    user_id, module_id, lesson_id, strength, due_at,
    last_outcome, last_reviewed_at
  )
  VALUES (
    caller, p_module_id, p_lesson_id, next_strength,
    NOW() + public.algebrix_review_interval(next_strength),
    p_outcome,
    CASE WHEN p_outcome = 'reviewed' THEN NOW() ELSE NULL END
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE
  SET module_id = EXCLUDED.module_id,
      strength = EXCLUDED.strength,
      due_at = EXCLUDED.due_at,
      last_outcome = EXCLUDED.last_outcome,
      last_reviewed_at = COALESCE(
        EXCLUDED.last_reviewed_at,
        existing.last_reviewed_at
      ),
      updated_at = NOW()
  RETURNING * INTO result;

  RETURN result;
END;
$$;

COMMENT ON FUNCTION public.schedule_concept_review IS
  'Advances or demotes a concept in the Leitner ladder for the caller.';

CREATE OR REPLACE FUNCTION public.clear_concept_history(p_lesson_id TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required.'
      USING ERRCODE = '28000';
  END IF;

  DELETE FROM public.lesson_answer_reviews
  WHERE user_id = caller AND lesson_id = p_lesson_id;

  DELETE FROM public.concept_review_schedule
  WHERE user_id = caller AND lesson_id = p_lesson_id;
END;
$$;

COMMENT ON FUNCTION public.clear_concept_history IS
  'Forgets every mistake and review-schedule row for one lesson.';

-- ============================================================================
-- 5. Row Level Security
-- ============================================================================
-- Read and delete only. Every write path goes through the RPCs above so the
-- client cannot set its own miss_count, strength, or due_at.

ALTER TABLE public.lesson_answer_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.concept_review_schedule ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own lesson mistakes"
  ON public.lesson_answer_reviews;
DROP POLICY IF EXISTS "Users can delete own lesson mistakes"
  ON public.lesson_answer_reviews;

CREATE POLICY "Users can view own lesson mistakes"
  ON public.lesson_answer_reviews
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own lesson mistakes"
  ON public.lesson_answer_reviews
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view own review schedule"
  ON public.concept_review_schedule;
DROP POLICY IF EXISTS "Users can delete own review schedule"
  ON public.concept_review_schedule;

CREATE POLICY "Users can view own review schedule"
  ON public.concept_review_schedule
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can delete own review schedule"
  ON public.concept_review_schedule
  FOR DELETE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

REVOKE ALL ON TABLE public.lesson_answer_reviews FROM anon, authenticated;
REVOKE ALL ON TABLE public.concept_review_schedule FROM anon, authenticated;

GRANT SELECT, DELETE ON TABLE public.lesson_answer_reviews TO authenticated;
GRANT SELECT, DELETE ON TABLE public.concept_review_schedule TO authenticated;

REVOKE ALL ON FUNCTION public.record_lesson_miss(
  TEXT, TEXT, TEXT, INT, TEXT, JSONB, INT, INT, TEXT
) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.resolve_lesson_miss(TEXT, TEXT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.schedule_concept_review(TEXT, TEXT, TEXT)
  FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.clear_concept_history(TEXT) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.record_lesson_miss(
  TEXT, TEXT, TEXT, INT, TEXT, JSONB, INT, INT, TEXT
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.resolve_lesson_miss(TEXT, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.schedule_concept_review(TEXT, TEXT, TEXT)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.clear_concept_history(TEXT) TO authenticated;

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
