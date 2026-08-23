-- Quest Map progression system: unlockable game worlds and per-user level stars.
-- Apply after the base auth schema. This migration is rerunnable.

BEGIN;

-- ============================================================================
-- 1. Quest Lands — registry of unlockable game worlds
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.quest_lands (
  id TEXT PRIMARY KEY,                              -- e.g. 'balands'
  name TEXT NOT NULL,                               -- 'Balands'
  subtitle TEXT NOT NULL,                           -- 'The Land of Balancing'
  sort_order INT NOT NULL DEFAULT 0,                -- display ordering
  total_levels INT NOT NULL DEFAULT 10,
  unlock_stars_required INT NOT NULL DEFAULT 0,     -- 0 for first land, 25 for second, etc.
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE public.quest_lands IS
  'Registry of unlockable quest-map game worlds (admin-only data).';

-- ============================================================================
-- 2. Quest Level Progress — per-user, per-level star tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.quest_level_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  land_id TEXT NOT NULL REFERENCES public.quest_lands(id),
  level_number INT NOT NULL CHECK (level_number >= 1 AND level_number <= 30),
  stars_earned INT NOT NULL DEFAULT 0 CHECK (stars_earned >= 0 AND stars_earned <= 3),
  best_moves INT,
  reasoning_passed BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, land_id, level_number)
);

COMMENT ON TABLE public.quest_level_progress IS
  'Per-user, per-level star tracking for quest-map progression.';

-- ============================================================================
-- 3. Indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS quest_level_progress_user_land_idx
  ON public.quest_level_progress (user_id, land_id);

-- ============================================================================
-- 4. Updated-at trigger (reusable helper function)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS quest_level_progress_set_updated_at
  ON public.quest_level_progress;

CREATE TRIGGER quest_level_progress_set_updated_at
  BEFORE UPDATE ON public.quest_level_progress
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- 5. Row-Level Security
-- ============================================================================

ALTER TABLE public.quest_lands ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quest_level_progress ENABLE ROW LEVEL SECURITY;

-- quest_lands: authenticated users can read (public metadata, admin-only writes)

DROP POLICY IF EXISTS "Authenticated users can read quest lands"
  ON public.quest_lands;

CREATE POLICY "Authenticated users can read quest lands"
  ON public.quest_lands
  FOR SELECT
  TO authenticated
  USING (TRUE);

-- quest_level_progress: users own their rows

DROP POLICY IF EXISTS "Users can view own quest level progress"
  ON public.quest_level_progress;
DROP POLICY IF EXISTS "Users can create own quest level progress"
  ON public.quest_level_progress;
DROP POLICY IF EXISTS "Users can update own quest level progress"
  ON public.quest_level_progress;

CREATE POLICY "Users can view own quest level progress"
  ON public.quest_level_progress
  FOR SELECT
  TO authenticated
  USING ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can create own quest level progress"
  ON public.quest_level_progress
  FOR INSERT
  TO authenticated
  WITH CHECK ((SELECT auth.uid()) = user_id);

CREATE POLICY "Users can update own quest level progress"
  ON public.quest_level_progress
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = user_id)
  WITH CHECK ((SELECT auth.uid()) = user_id);

-- ============================================================================
-- 6. Grants
-- ============================================================================

REVOKE ALL ON TABLE public.quest_lands FROM anon, authenticated;
GRANT SELECT ON TABLE public.quest_lands TO authenticated;

REVOKE ALL ON TABLE public.quest_level_progress FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.quest_level_progress TO authenticated;

-- ============================================================================
-- 7. Seed Data
-- ============================================================================

INSERT INTO public.quest_lands (id, name, subtitle, sort_order, total_levels, unlock_stars_required)
VALUES 
  ('balands', 'Balands', 'The Land of Balancing', 1, 10, 0),
  ('pairadise', 'Pairadise', 'The Land of Pairs', 2, 10, 25)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  subtitle = EXCLUDED.subtitle,
  sort_order = EXCLUDED.sort_order,
  total_levels = EXCLUDED.total_levels,
  unlock_stars_required = EXCLUDED.unlock_stars_required;

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
