-- Run after migrations against a disposable local Supabase database:
--   psql -v ON_ERROR_STOP=1 "$DATABASE_URL" \
--     -f supabase/tests/account_progress_contract_test.sql

BEGIN;

DO $$
DECLARE
  answer_step_count INTEGER;
  answer_reward_sum INTEGER;
  final_step_count INTEGER;
  profile_policy_count INTEGER;
  function_is_security_definer BOOLEAN;
  function_definition TEXT;
  missing_profile_columns TEXT[];
BEGIN
  IF to_regclass('public.lesson_progress') IS NULL
     OR to_regclass('public.learning_step_catalog') IS NULL
     OR to_regclass('public.xp_events') IS NULL THEN
    RAISE EXCEPTION 'Account progress tables are missing';
  END IF;

  SELECT ARRAY_AGG(required.column_name ORDER BY required.column_name)
  INTO missing_profile_columns
  FROM (
    VALUES
      ('xp'),
      ('level'),
      ('level_title'),
      ('streak'),
      ('completed_lesson_ids'),
      ('last_active'),
      ('updated_at')
  ) AS required(column_name)
  WHERE NOT EXISTS (
    SELECT 1
    FROM information_schema.columns AS actual
    WHERE actual.table_schema = 'public'
      AND actual.table_name = 'profiles'
      AND actual.column_name = required.column_name
  );

  IF missing_profile_columns IS NOT NULL THEN
    RAISE EXCEPTION
      'Profiles is missing required progress columns: %',
      missing_profile_columns;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name IN (
        'xp',
        'level',
        'level_title',
        'streak',
        'completed_lesson_ids',
        'last_active',
        'updated_at'
      )
      AND is_nullable <> 'NO'
  ) THEN
    RAISE EXCEPTION 'Required profile progress columns must be NOT NULL';
  END IF;

  SELECT COUNT(*), COALESCE(SUM(xp_reward), 0)
  INTO answer_step_count, answer_reward_sum
  FROM public.learning_step_catalog
  WHERE module_id = 'module1'
    AND lesson_id = 'm1_l1'
    AND content_version = 1
    AND is_answer_step;

  IF answer_step_count <> 3 OR answer_reward_sum <> 30 THEN
    RAISE EXCEPTION
      'Expected three answer steps worth 30 XP; got % steps and % XP',
      answer_step_count,
      answer_reward_sum;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.learning_step_catalog
    WHERE module_id = 'module1'
      AND lesson_id = 'm1_l1'
      AND content_version = 1
      AND is_answer_step
      AND (step_id NOT IN ('step4', 'step5', 'step6') OR xp_reward <> 10)
  ) THEN
    RAISE EXCEPTION 'Module 1 answer reward catalog is invalid';
  END IF;

  SELECT COUNT(*)
  INTO final_step_count
  FROM public.learning_step_catalog
  WHERE module_id = 'module1'
    AND lesson_id = 'm1_l1'
    AND content_version = 1
    AND step_id = 'step7'
    AND step_index = 6
    AND is_final;

  IF final_step_count <> 1 THEN
    RAISE EXCEPTION 'Module 1 final step catalog is invalid';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_class
    WHERE oid IN (
      'public.profiles'::regclass,
      'public.lesson_progress'::regclass,
      'public.learning_step_catalog'::regclass,
      'public.xp_events'::regclass
    )
      AND relrowsecurity
    GROUP BY relrowsecurity
    HAVING COUNT(*) = 4
  ) THEN
    RAISE EXCEPTION 'RLS must be enabled on all account progress tables';
  END IF;

  SELECT COUNT(*)
  INTO profile_policy_count
  FROM pg_policies
  WHERE schemaname = 'public' AND tablename = 'profiles';

  IF profile_policy_count <> 1 OR EXISTS (
    SELECT 1
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'profiles'
      AND (cmd <> 'SELECT' OR roles <> ARRAY['authenticated']::name[])
  ) THEN
    RAISE EXCEPTION 'Profiles must have exactly one authenticated SELECT policy';
  END IF;

  IF has_table_privilege('authenticated', 'public.profiles', 'UPDATE')
     OR has_table_privilege('authenticated', 'public.lesson_progress', 'INSERT')
     OR has_table_privilege('authenticated', 'public.xp_events', 'INSERT') THEN
    RAISE EXCEPTION 'Authenticated clients still have direct progress/XP writes';
  END IF;

  IF has_function_privilege(
       'anon',
       'public.record_lesson_step(text,text,text,integer,boolean,integer)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Anonymous users can execute record_lesson_step';
  END IF;

  IF NOT has_function_privilege(
       'authenticated',
       'public.record_lesson_step(text,text,text,integer,boolean,integer)',
       'EXECUTE'
     ) THEN
    RAISE EXCEPTION 'Authenticated users cannot execute record_lesson_step';
  END IF;

  SELECT prosecdef
  INTO function_is_security_definer
  FROM pg_proc
  WHERE oid =
    'public.record_lesson_step(text,text,text,integer,boolean,integer)'::regprocedure;

  IF NOT function_is_security_definer THEN
    RAISE EXCEPTION 'record_lesson_step must be SECURITY DEFINER';
  END IF;

  SELECT pg_get_functiondef(
    'public.record_lesson_step(text,text,text,integer,boolean,integer)'::regprocedure
  )
  INTO function_definition;

  IF function_definition !~
     'v_requirements_met\s*:=\s*v_was_completed\s+OR' THEN
    RAISE EXCEPTION
      'Existing completed progress must satisfy completion requirements';
  END IF;

  IF function_definition !~
     'v_catalog\.is_final\s+AND\s+v_requirements_met\s+AND\s+NOT\s+v_was_completed' THEN
    RAISE EXCEPTION
      'Existing completed progress must remain immutable for completion XP';
  END IF;
END;
$$;

ROLLBACK;
