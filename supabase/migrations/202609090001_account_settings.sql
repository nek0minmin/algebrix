-- Account self-service settings: display name, avatar selection, and account deletion.
-- Apply after 202608120001_account_progress.sql. This migration is rerunnable.
--
-- Background: 202608120001 revoked every write grant on public.profiles and
-- dropped all of its UPDATE policies, so the client is currently SELECT-only.
-- This migration re-opens exactly two columns -- name and avatar_url -- and
-- nothing else. XP, level, streak, and completed lessons stay server-owned.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.profiles') IS NULL THEN
    RAISE EXCEPTION
      'public.profiles is required; apply supabase_schema.sql first';
  END IF;
END;
$$;

-- ============================================================================
-- 1. Columns
-- ============================================================================

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS name TEXT,
  ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- ============================================================================
-- 2. Display-name normalizer
-- ============================================================================
-- Collapses whitespace runs, trims, caps at 40 characters, and falls back to
-- 'Learner' for anything shorter than 2 characters. Used by both the backfill
-- below and the update trigger, so a client can never store a name that
-- violates the CHECK constraint -- it gets normalized instead of rejected.

CREATE OR REPLACE FUNCTION public.algebrix_normalize_display_name(raw TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SET search_path = public, pg_temp
AS $$
  SELECT CASE
           WHEN CHAR_LENGTH(cleaned) < 2 THEN 'Learner'
           ELSE cleaned
         END
  FROM (
    SELECT BTRIM(
             LEFT(
               BTRIM(REGEXP_REPLACE(COALESCE(raw, ''), '\s+', ' ', 'g')),
               40
             )
           ) AS cleaned
  ) AS normalized;
$$;

COMMENT ON FUNCTION public.algebrix_normalize_display_name(TEXT) IS
  'Collapses whitespace, trims, caps at 40 chars, falls back to ''Learner''.';

-- Normalize any legacy rows before the CHECK constraint is added.
UPDATE public.profiles
SET name = public.algebrix_normalize_display_name(name)
WHERE name IS DISTINCT FROM public.algebrix_normalize_display_name(name);

ALTER TABLE public.profiles
  ALTER COLUMN name SET NOT NULL;

-- Clear any legacy avatar value that would not survive the new constraint.
-- NOTE: the URL length bound lives in CHAR_LENGTH, not in the pattern.
-- Postgres caps regex {m,n} repetition counts at 255, so an inline {3,300}
-- fails with "invalid repetition count(s)".
UPDATE public.profiles
SET avatar_url = NULL
WHERE avatar_url IS NOT NULL
  AND NOT (
    avatar_url ~ '^[a-z0-9][a-z0-9-]{0,39}$'
    OR (
      avatar_url ~ '^https://[A-Za-z0-9./_%+-]+$'
      AND CHAR_LENGTH(avatar_url) BETWEEN 11 AND 300
    )
  );

-- ============================================================================
-- 3. Constraints
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_name_valid'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_name_valid CHECK (
        name = BTRIM(name)
        AND CHAR_LENGTH(name) BETWEEN 2 AND 40
      );
  END IF;

  -- Algebrix ships preset mascot avatars, stored as a short slug such as
  -- 'xy-happy'. An https URL is also accepted so a future upload feature can
  -- reuse this column without another migration.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_avatar_url_valid'
      AND conrelid = 'public.profiles'::regclass
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_avatar_url_valid CHECK (
        avatar_url IS NULL
        OR avatar_url ~ '^[a-z0-9][a-z0-9-]{0,39}$'
        OR (
          avatar_url ~ '^https://[A-Za-z0-9./_%+-]+$'
          AND CHAR_LENGTH(avatar_url) BETWEEN 11 AND 300
        )
      );
  END IF;
END;
$$;

-- ============================================================================
-- 4. Update guard -- keeps progress columns server-owned
-- ============================================================================

CREATE OR REPLACE FUNCTION public.algebrix_prepare_profile_update()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $$
BEGIN
  -- These are awarded by record_lesson_step and must never move because a
  -- client sent them, even if a future grant is accidentally widened.
  NEW.id := OLD.id;
  NEW.xp := OLD.xp;
  NEW.level := OLD.level;
  NEW.level_title := OLD.level_title;
  NEW.streak := OLD.streak;
  NEW.completed_lesson_ids := OLD.completed_lesson_ids;

  -- Learner-editable fields, normalized on the way in.
  NEW.name := public.algebrix_normalize_display_name(NEW.name);
  NEW.avatar_url := NULLIF(BTRIM(COALESCE(NEW.avatar_url, '')), '');

  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.algebrix_prepare_profile_update() FROM PUBLIC;

DROP TRIGGER IF EXISTS profiles_prepare_update ON public.profiles;
CREATE TRIGGER profiles_prepare_update
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.algebrix_prepare_profile_update();

-- ============================================================================
-- 5. Row Level Security
-- ============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles
  FOR UPDATE
  TO authenticated
  USING ((SELECT auth.uid()) = id)
  WITH CHECK ((SELECT auth.uid()) = id);

-- SELECT was granted by 202608120001; repeated here so this file stands alone.
GRANT SELECT ON TABLE public.profiles TO authenticated;
GRANT UPDATE (name, avatar_url) ON TABLE public.profiles TO authenticated;

COMMENT ON COLUMN public.profiles.name IS
  'Learner display name. Client-editable, normalized by trigger.';
COMMENT ON COLUMN public.profiles.avatar_url IS
  'Preset mascot avatar slug (e.g. ''xy-happy'') or an https URL.';

-- ============================================================================
-- 6. Account deletion
-- ============================================================================
-- The anon/authenticated roles cannot touch auth.users, so deletion runs
-- through a SECURITY DEFINER function that can only ever delete the caller's
-- own row. Removing the auth.users row cascades to public.profiles and every
-- other user-owned table (lesson_progress, xp_events, study_notes,
-- quest_level_progress, module_quiz_progress, quiz_attempt_reviews).
--
-- NOTE: run this migration as an owner with DELETE on auth.users -- the
-- postgres role in the Supabase SQL editor qualifies.

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required to delete an account.'
      USING ERRCODE = '28000';
  END IF;

  DELETE FROM auth.users WHERE id = caller;
END;
$$;

COMMENT ON FUNCTION public.delete_own_account() IS
  'Permanently deletes the calling user and cascades every account-owned row.';

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
