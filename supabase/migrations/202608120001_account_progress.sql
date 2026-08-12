-- Account-scoped Module 1 progress and server-authoritative XP.
-- This migration is intentionally additive. Legacy profile columns remain
-- available during the Flutter rollout and can be retired separately.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NULL THEN
    RAISE EXCEPTION
      'public.profiles is required; apply supabase_schema.sql first';
  END IF;
END;
$$;

-- Existing Algebrix deployments predate the repository schema and may not
-- contain every learning aggregate column. Establish only the columns this
-- migration and RPC require. ADD COLUMN IF NOT EXISTS keeps reruns safe.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS xp INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS level INTEGER DEFAULT 1,
  ADD COLUMN IF NOT EXISTS level_title TEXT DEFAULT 'Math Beginner',
  ADD COLUMN IF NOT EXISTS streak INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS completed_lesson_ids TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS last_active TIMESTAMPTZ DEFAULT NOW(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.profiles
  ALTER COLUMN xp SET DEFAULT 0,
  ALTER COLUMN level SET DEFAULT 1,
  ALTER COLUMN level_title SET DEFAULT 'Math Beginner',
  ALTER COLUMN streak SET DEFAULT 0,
  ALTER COLUMN completed_lesson_ids SET DEFAULT '{}',
  ALTER COLUMN last_active SET DEFAULT NOW(),
  ALTER COLUMN updated_at SET DEFAULT NOW();

-- Normalize legacy client-written values and nullable legacy columns before
-- enforcing invariants. No created_at column is assumed.
UPDATE public.profiles
SET xp = GREATEST(COALESCE(xp, 0), 0),
    level = GREATEST(COALESCE(level, 1), 1),
    level_title = COALESCE(NULLIF(BTRIM(level_title), ''), 'Math Beginner'),
    streak = GREATEST(COALESCE(streak, 0), 0),
    completed_lesson_ids = COALESCE(
      completed_lesson_ids,
      ARRAY[]::TEXT[]
    ),
    last_active = COALESCE(last_active, NOW()),
    updated_at = COALESCE(updated_at, NOW())
WHERE xp IS NULL
   OR xp < 0
   OR level IS NULL
   OR level < 1
   OR level_title IS NULL
   OR BTRIM(level_title) = ''
   OR streak IS NULL
   OR streak < 0
   OR completed_lesson_ids IS NULL
   OR last_active IS NULL
   OR updated_at IS NULL;

ALTER TABLE public.profiles
  ALTER COLUMN xp SET NOT NULL,
  ALTER COLUMN level SET NOT NULL,
  ALTER COLUMN level_title SET NOT NULL,
  ALTER COLUMN streak SET NOT NULL,
  ALTER COLUMN completed_lesson_ids SET NOT NULL,
  ALTER COLUMN last_active SET NOT NULL,
  ALTER COLUMN updated_at SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_xp_nonnegative'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_xp_nonnegative CHECK (xp >= 0);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_level_positive'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_level_positive CHECK (level >= 1);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_streak_nonnegative'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_streak_nonnegative CHECK (streak >= 0);
  END IF;
END;
$$;

CREATE TABLE IF NOT EXISTS public.learning_step_catalog (
  module_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  step_id TEXT NOT NULL,
  content_version INTEGER NOT NULL DEFAULT 1 CHECK (content_version >= 1),
  step_index INTEGER NOT NULL CHECK (step_index >= 0),
  is_answer_step BOOLEAN NOT NULL DEFAULT FALSE,
  xp_reward INTEGER NOT NULL DEFAULT 0 CHECK (xp_reward >= 0),
  is_final BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (module_id, lesson_id, step_id, content_version),
  UNIQUE (module_id, lesson_id, content_version, step_index)
);

INSERT INTO public.learning_step_catalog (
  module_id,
  lesson_id,
  step_id,
  content_version,
  step_index,
  is_answer_step,
  xp_reward,
  is_final
)
VALUES
  ('module1', 'm1_l1', 'step1', 1, 0, FALSE, 0, FALSE),
  ('module1', 'm1_l1', 'step2', 1, 1, FALSE, 0, FALSE),
  ('module1', 'm1_l1', 'step3', 1, 2, FALSE, 0, FALSE),
  ('module1', 'm1_l1', 'step4', 1, 3, TRUE, 10, FALSE),
  ('module1', 'm1_l1', 'step5', 1, 4, TRUE, 10, FALSE),
  ('module1', 'm1_l1', 'step6', 1, 5, TRUE, 10, FALSE),
  ('module1', 'm1_l1', 'step7', 1, 6, FALSE, 0, TRUE)
ON CONFLICT (module_id, lesson_id, step_id, content_version)
DO UPDATE SET
  step_index = EXCLUDED.step_index,
  is_answer_step = EXCLUDED.is_answer_step,
  xp_reward = EXCLUDED.xp_reward,
  is_final = EXCLUDED.is_final;

CREATE TABLE IF NOT EXISTS public.lesson_progress (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  module_id TEXT NOT NULL,
  lesson_id TEXT NOT NULL,
  content_version INTEGER NOT NULL DEFAULT 1 CHECK (content_version >= 1),
  last_step_id TEXT,
  last_step_index INTEGER CHECK (last_step_index >= 0),
  status TEXT NOT NULL DEFAULT 'in_progress'
    CHECK (status IN ('in_progress', 'completed')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (user_id, lesson_id),
  CHECK (
    (status = 'completed' AND completed_at IS NOT NULL)
    OR (status = 'in_progress' AND completed_at IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS lesson_progress_user_module_idx
  ON public.lesson_progress (user_id, module_id);

CREATE TABLE IF NOT EXISTS public.xp_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  event_key TEXT NOT NULL,
  event_type TEXT NOT NULL CHECK (
    event_type IN (
      'migration_opening_balance',
      'lesson_step_correct',
      'lesson_completion'
    )
  ),
  module_id TEXT,
  lesson_id TEXT,
  step_id TEXT,
  content_version INTEGER CHECK (content_version IS NULL OR content_version >= 1),
  amount INTEGER NOT NULL CHECK (amount >= 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, event_key)
);

CREATE INDEX IF NOT EXISTS xp_events_user_created_idx
  ON public.xp_events (user_id, created_at DESC);

-- Establish an auditable starting point without re-awarding existing XP.
INSERT INTO public.xp_events (
  user_id,
  event_key,
  event_type,
  amount
)
SELECT
  id,
  'migration:opening_balance:v1',
  'migration_opening_balance',
  xp
FROM public.profiles
ON CONFLICT (user_id, event_key) DO NOTHING;

-- Preserve legacy completions as progress rows, but never grant migration XP.
INSERT INTO public.lesson_progress (
  user_id,
  module_id,
  lesson_id,
  content_version,
  last_step_id,
  last_step_index,
  status,
  completed_at
)
SELECT
  profile.id,
  CASE
    WHEN legacy.lesson_id LIKE 'm1\_%' ESCAPE '\' THEN 'module1'
    ELSE 'legacy'
  END,
  legacy.lesson_id,
  1,
  CASE WHEN legacy.lesson_id = 'm1_l1' THEN 'step7' END,
  CASE WHEN legacy.lesson_id = 'm1_l1' THEN 6 END,
  'completed',
  COALESCE(profile.updated_at, NOW())
FROM public.profiles AS profile
CROSS JOIN LATERAL unnest(
  COALESCE(profile.completed_lesson_ids, ARRAY[]::TEXT[])
) AS legacy(lesson_id)
WHERE BTRIM(legacy.lesson_id) <> ''
ON CONFLICT (user_id, lesson_id) DO UPDATE SET
  status = 'completed',
  completed_at = COALESCE(
    public.lesson_progress.completed_at,
    EXCLUDED.completed_at
  ),
  updated_at = NOW();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.learning_step_catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.xp_events ENABLE ROW LEVEL SECURITY;

-- Replace legacy profile policies, including the read-all leaderboard policy.
DO $$
DECLARE
  existing_policy RECORD;
BEGIN
  FOR existing_policy IN
    SELECT policyname
    FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'profiles'
  LOOP
    EXECUTE format(
      'DROP POLICY %I ON public.profiles',
      existing_policy.policyname
    );
  END LOOP;
END;
$$;

DROP POLICY IF EXISTS "Authenticated users can read learning catalog"
  ON public.learning_step_catalog;
DROP POLICY IF EXISTS "Users can view own lesson progress"
  ON public.lesson_progress;
DROP POLICY IF EXISTS "Users can view own XP events"
  ON public.xp_events;

CREATE POLICY "Users can view own profile"
  ON public.profiles
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = id);

CREATE POLICY "Authenticated users can read learning catalog"
  ON public.learning_step_catalog
  FOR SELECT
  TO authenticated
  USING (TRUE);

CREATE POLICY "Users can view own lesson progress"
  ON public.lesson_progress
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can view own XP events"
  ON public.xp_events
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

REVOKE ALL ON TABLE public.profiles FROM anon, authenticated;
REVOKE ALL ON TABLE public.learning_step_catalog FROM anon, authenticated;
REVOKE ALL ON TABLE public.lesson_progress FROM anon, authenticated;
REVOKE ALL ON TABLE public.xp_events FROM anon, authenticated;

GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.learning_step_catalog TO authenticated;
GRANT SELECT ON TABLE public.lesson_progress TO authenticated;
GRANT SELECT ON TABLE public.xp_events TO authenticated;

CREATE OR REPLACE FUNCTION public.record_lesson_step(
  p_module_id TEXT,
  p_lesson_id TEXT,
  p_step_id TEXT,
  p_step_index INTEGER,
  p_answer_correct BOOLEAN DEFAULT FALSE,
  p_content_version INTEGER DEFAULT 1
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_catalog public.learning_step_catalog%ROWTYPE;
  v_progress public.lesson_progress%ROWTYPE;
  v_step_xp INTEGER := 0;
  v_completion_xp INTEGER := 0;
  v_total_awarded INTEGER := 0;
  v_required_answers INTEGER := 0;
  v_correct_answers INTEGER := 0;
  v_requirements_met BOOLEAN := FALSE;
  v_total_xp INTEGER;
  v_level INTEGER;
  v_level_title TEXT;
  v_was_completed BOOLEAN := FALSE;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING
      ERRCODE = '28000',
      MESSAGE = 'An authenticated account is required.';
  END IF;

  IF p_step_index < 0 OR p_content_version < 1 THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'Invalid step index or content version.';
  END IF;

  SELECT *
  INTO v_catalog
  FROM public.learning_step_catalog
  WHERE module_id = p_module_id
    AND lesson_id = p_lesson_id
    AND step_id = p_step_id
    AND content_version = p_content_version;

  IF NOT FOUND OR v_catalog.step_index <> p_step_index THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'Unknown lesson step or mismatched step index.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = v_user_id
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'The authenticated account has no profile.';
  END IF;

  INSERT INTO public.lesson_progress (
    user_id,
    module_id,
    lesson_id,
    content_version,
    last_step_id,
    last_step_index,
    status,
    completed_at
  )
  VALUES (
    v_user_id,
    p_module_id,
    p_lesson_id,
    p_content_version,
    p_step_id,
    p_step_index,
    'in_progress',
    NULL
  )
  ON CONFLICT (user_id, lesson_id) DO UPDATE SET
    module_id = EXCLUDED.module_id,
    content_version = EXCLUDED.content_version,
    last_step_id = EXCLUDED.last_step_id,
    last_step_index = EXCLUDED.last_step_index,
    updated_at = NOW()
  RETURNING * INTO v_progress;

  -- A completed lesson is immutable for reward purposes. This also prevents
  -- legacy completed rows from receiving retroactive XP when replayed.
  v_was_completed := v_progress.status = 'completed';

  IF NOT v_was_completed
     AND p_answer_correct
     AND v_catalog.is_answer_step
     AND v_catalog.xp_reward > 0 THEN
    INSERT INTO public.xp_events (
      user_id,
      event_key,
      event_type,
      module_id,
      lesson_id,
      step_id,
      content_version,
      amount
    )
    VALUES (
      v_user_id,
      format(
        'lesson:%s:%s:%s:correct:v%s',
        p_module_id,
        p_lesson_id,
        p_step_id,
        p_content_version
      ),
      'lesson_step_correct',
      p_module_id,
      p_lesson_id,
      p_step_id,
      p_content_version,
      v_catalog.xp_reward
    )
    ON CONFLICT (user_id, event_key) DO NOTHING
    RETURNING amount INTO v_step_xp;

    v_step_xp := COALESCE(v_step_xp, 0);
  END IF;

  SELECT COUNT(*)
  INTO v_required_answers
  FROM public.learning_step_catalog
  WHERE module_id = p_module_id
    AND lesson_id = p_lesson_id
    AND content_version = p_content_version
    AND is_answer_step;

  SELECT COUNT(DISTINCT catalog.step_id)
  INTO v_correct_answers
  FROM public.learning_step_catalog AS catalog
  JOIN public.xp_events AS event
    ON event.user_id = v_user_id
   AND event.event_type = 'lesson_step_correct'
   AND event.module_id = catalog.module_id
   AND event.lesson_id = catalog.lesson_id
   AND event.step_id = catalog.step_id
   AND event.content_version = catalog.content_version
  WHERE catalog.module_id = p_module_id
    AND catalog.lesson_id = p_lesson_id
    AND catalog.content_version = p_content_version
    AND catalog.is_answer_step;

  v_requirements_met := v_was_completed OR (
    v_required_answers > 0 AND v_correct_answers = v_required_answers
  );

  IF v_catalog.is_final AND v_requirements_met AND NOT v_was_completed THEN
    UPDATE public.lesson_progress
    SET status = 'completed',
        completed_at = COALESCE(completed_at, NOW()),
        updated_at = NOW()
    WHERE user_id = v_user_id AND lesson_id = p_lesson_id
    RETURNING * INTO v_progress;

    INSERT INTO public.xp_events (
      user_id,
      event_key,
      event_type,
      module_id,
      lesson_id,
      step_id,
      content_version,
      amount
    )
    VALUES (
      v_user_id,
      format(
        'lesson:%s:%s:complete:v%s',
        p_module_id,
        p_lesson_id,
        p_content_version
      ),
      'lesson_completion',
      p_module_id,
      p_lesson_id,
      p_step_id,
      p_content_version,
      25
    )
    ON CONFLICT (user_id, event_key) DO NOTHING
    RETURNING amount INTO v_completion_xp;

    v_completion_xp := COALESCE(v_completion_xp, 0);
  END IF;

  v_total_awarded := v_step_xp + v_completion_xp;

  UPDATE public.profiles
  SET xp = xp + v_total_awarded,
      level = ((xp + v_total_awarded) / 1000) + 1,
      level_title = CASE
        WHEN ((xp + v_total_awarded) / 1000) + 1 = 1
          THEN 'Math Beginner'
        WHEN ((xp + v_total_awarded) / 1000) + 1 <= 5
          THEN 'Math Explorer'
        WHEN ((xp + v_total_awarded) / 1000) + 1 <= 10
          THEN 'Algebra Adventurer'
        ELSE 'Algebra Master'
      END,
      completed_lesson_ids = CASE
        WHEN v_progress.status = 'completed'
             AND NOT (p_lesson_id = ANY(completed_lesson_ids))
          THEN array_append(completed_lesson_ids, p_lesson_id)
        ELSE completed_lesson_ids
      END,
      last_active = NOW(),
      updated_at = NOW()
  WHERE id = v_user_id
  RETURNING xp, level, level_title
  INTO v_total_xp, v_level, v_level_title;

  RETURN jsonb_build_object(
    'progress', to_jsonb(v_progress),
    'xp_awarded', v_total_awarded,
    'step_xp_awarded', v_step_xp,
    'completion_xp_awarded', v_completion_xp,
    'total_xp', v_total_xp,
    'level', v_level,
    'level_title', v_level_title,
    'completion_requirements_met', v_requirements_met
  );
END;
$$;

COMMENT ON FUNCTION public.record_lesson_step(
  TEXT,
  TEXT,
  TEXT,
  INTEGER,
  BOOLEAN,
  INTEGER
) IS
  'Records account-scoped resume progress and awards idempotent server-defined XP.';

REVOKE ALL ON FUNCTION public.record_lesson_step(
  TEXT,
  TEXT,
  TEXT,
  INTEGER,
  BOOLEAN,
  INTEGER
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.record_lesson_step(
  TEXT,
  TEXT,
  TEXT,
  INTEGER,
  BOOLEAN,
  INTEGER
) TO authenticated;

-- PostgREST receives this only after the surrounding transaction commits.
-- It makes the new tables and RPC visible without a manual API restart.
NOTIFY pgrst, 'reload schema';

COMMIT;
