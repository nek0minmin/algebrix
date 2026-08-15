-- Run after supabase/migrations/202608150001_study_notes.sql against a
-- disposable Supabase database:
--   psql -v ON_ERROR_STOP=1 "$DATABASE_URL" \
--     -f supabase/tests/study_notes_contract_test.sql

BEGIN;

DO $$
DECLARE
  missing_columns TEXT[];
  invalid_policy_count INTEGER;
  notes_index_definition TEXT;
  update_function_definition TEXT;
BEGIN
  IF to_regclass('public.study_notes') IS NULL THEN
    RAISE EXCEPTION 'public.study_notes is missing';
  END IF;

  SELECT ARRAY_AGG(required.column_name ORDER BY required.column_name)
  INTO missing_columns
  FROM (
    VALUES
      ('id'),
      ('user_id'),
      ('module_id'),
      ('lesson_id'),
      ('title'),
      ('content'),
      ('created_at'),
      ('updated_at')
  ) AS required(column_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns AS actual
    WHERE actual.table_schema = 'public'
      AND actual.table_name = 'study_notes'
      AND actual.column_name = required.column_name
      AND actual.is_nullable = 'NO'
  );

  IF missing_columns IS NOT NULL THEN
    RAISE EXCEPTION
      'study_notes is missing required NOT NULL columns: %',
      missing_columns;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'study_notes'
      AND column_name = 'user_id'
      AND column_default LIKE '%auth.uid%'
  ) THEN
    RAISE EXCEPTION 'study_notes.user_id must default to auth.uid()';
  END IF;

  IF (
    SELECT COUNT(*)
    FROM pg_constraint
    WHERE conrelid = 'public.study_notes'::regclass
      AND conname IN (
        'study_notes_module_id_valid',
        'study_notes_lesson_id_valid',
        'study_notes_title_valid',
        'study_notes_content_valid'
      )
  ) <> 4 THEN
    RAISE EXCEPTION 'study_notes validation constraints are incomplete';
  END IF;

  IF NOT (
    SELECT relrowsecurity
    FROM pg_class
    WHERE oid = 'public.study_notes'::regclass
  ) THEN
    RAISE EXCEPTION 'RLS must be enabled on public.study_notes';
  END IF;

  IF (
    SELECT COUNT(*)
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'study_notes'
      AND roles = ARRAY['authenticated']::name[]
      AND cmd IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
  ) <> 4 THEN
    RAISE EXCEPTION 'Expected four authenticated CRUD policies';
  END IF;

  SELECT COUNT(*)
  INTO invalid_policy_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'study_notes'
    AND (
      roles <> ARRAY['authenticated']::name[]
      OR cmd NOT IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE')
      OR COALESCE(qual, with_check, '') NOT LIKE '%auth.uid()%user_id%'
    );

  IF invalid_policy_count <> 0 THEN
    RAISE EXCEPTION 'Every study_notes policy must enforce auth.uid ownership';
  END IF;

  IF has_table_privilege('anon', 'public.study_notes', 'SELECT')
     OR has_table_privilege('anon', 'public.study_notes', 'INSERT')
     OR has_table_privilege('anon', 'public.study_notes', 'UPDATE')
     OR has_table_privilege('anon', 'public.study_notes', 'DELETE') THEN
    RAISE EXCEPTION 'Anonymous users must not receive study_notes privileges';
  END IF;

  IF NOT has_table_privilege('authenticated', 'public.study_notes', 'SELECT')
     OR NOT has_table_privilege('authenticated', 'public.study_notes', 'DELETE')
     OR has_table_privilege('authenticated', 'public.study_notes', 'INSERT')
     OR has_table_privilege('authenticated', 'public.study_notes', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.study_notes', 'TRUNCATE') THEN
    RAISE EXCEPTION 'Authenticated study_notes grants are not least privilege';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM (VALUES
      ('module_id'), ('lesson_id'), ('title'), ('content')
    ) AS editable(column_name)
    WHERE NOT has_column_privilege(
      'authenticated',
      'public.study_notes',
      editable.column_name,
      'INSERT'
    ) OR NOT has_column_privilege(
      'authenticated',
      'public.study_notes',
      editable.column_name,
      'UPDATE'
    )
  ) OR EXISTS (
    SELECT 1
    FROM (VALUES
      ('id'), ('user_id'), ('created_at'), ('updated_at')
    ) AS protected(column_name)
    WHERE has_column_privilege(
      'authenticated',
      'public.study_notes',
      protected.column_name,
      'INSERT'
    ) OR has_column_privilege(
      'authenticated',
      'public.study_notes',
      protected.column_name,
      'UPDATE'
    )
  ) THEN
    RAISE EXCEPTION 'Study note editable-column grants are invalid';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_trigger
    WHERE tgrelid = 'public.study_notes'::regclass
      AND tgname = 'study_notes_set_updated_at'
      AND tgenabled <> 'D'
  ) THEN
    RAISE EXCEPTION 'study_notes updated_at trigger is missing or disabled';
  END IF;

  SELECT pg_get_functiondef(
    'public.algebrix_prepare_study_note_update()'::regprocedure
  )
  INTO update_function_definition;

  IF update_function_definition NOT LIKE '%NEW.id := OLD.id%'
     OR update_function_definition NOT LIKE '%NEW.user_id := OLD.user_id%'
     OR update_function_definition NOT LIKE '%NEW.created_at := OLD.created_at%'
     OR update_function_definition NOT LIKE '%NEW.updated_at := NOW()%'
  THEN
    RAISE EXCEPTION 'Study note update trigger must protect server-owned fields';
  END IF;

  SELECT pg_get_indexdef(indexrelid)
  INTO notes_index_definition
  FROM pg_index
  WHERE indrelid = 'public.study_notes'::regclass
    AND indexrelid = 'public.study_notes_user_updated_idx'::regclass;

  IF notes_index_definition NOT LIKE '%(user_id, updated_at DESC)%' THEN
    RAISE EXCEPTION 'Account/sort index is missing or malformed';
  END IF;
END;
$$;

ROLLBACK;
