-- Module Quizzes progression system: per-user module quiz high scores, attempts, and mastery tracking.
-- Apply after the base auth schema and account progress. This migration is rerunnable.

BEGIN;

-- ============================================================================
-- 1. Module Quiz Progress — per-user, per-module quiz high scores and attempts
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.module_quiz_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,                          -- e.g. 'module1', 'module2'
  high_score INT NOT NULL DEFAULT 0,                -- highest number of correct items (e.g. 13)
  total_questions INT NOT NULL DEFAULT 15,          -- total questions in quiz (default 15)
  best_percentage DOUBLE PRECISION NOT NULL DEFAULT 0.0, -- best accuracy % (e.g. 86.67)
  passed BOOLEAN NOT NULL DEFAULT false,            -- true if best_percentage >= 60.0%
  attempts_count INT NOT NULL DEFAULT 0,            -- total number of attempts taken
  last_score INT NOT NULL DEFAULT 0,                -- score from the most recent attempt
  last_percentage DOUBLE PRECISION NOT NULL DEFAULT 0.0, -- % from the most recent attempt
  last_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, module_id)
);

COMMENT ON TABLE public.module_quiz_progress IS
  'Per-user module quiz scores, attempts, and unlock prerequisites for subsequent modules.';

-- ============================================================================
-- 2. Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS module_quiz_progress_user_module_idx
  ON public.module_quiz_progress (user_id, module_id);

-- ============================================================================
-- 3. Row Level Security (RLS)
-- ============================================================================

ALTER TABLE public.module_quiz_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own quiz progress" ON public.module_quiz_progress;
CREATE POLICY "Users can read own quiz progress"
  ON public.module_quiz_progress
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own quiz progress" ON public.module_quiz_progress;
CREATE POLICY "Users can insert own quiz progress"
  ON public.module_quiz_progress
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own quiz progress" ON public.module_quiz_progress;
CREATE POLICY "Users can update own quiz progress"
  ON public.module_quiz_progress
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- 4. Trigger
-- ============================================================================

DROP TRIGGER IF EXISTS set_module_quiz_progress_updated_at ON public.module_quiz_progress;
CREATE TRIGGER set_module_quiz_progress_updated_at
  BEFORE UPDATE ON public.module_quiz_progress
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

COMMIT;
