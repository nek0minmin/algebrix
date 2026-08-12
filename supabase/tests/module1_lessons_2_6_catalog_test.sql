-- Run after 202608120002_module1_lessons_2_6_catalog.sql against a disposable
-- local or staging Supabase database.

BEGIN;

DO $$
DECLARE
  mismatch_count INTEGER;
  invalid_summary_count INTEGER;
  function_definition TEXT;
BEGIN
  IF to_regclass('public.learning_step_catalog') IS NULL THEN
    RAISE EXCEPTION 'public.learning_step_catalog is missing';
  END IF;

  WITH expected (
    lesson_id,
    step_id,
    step_index,
    is_answer_step,
    xp_reward,
    is_final
  ) AS (
    VALUES
      ('m1_l2', 'm1_l2_s01', 0, FALSE, 0, FALSE),
      ('m1_l2', 'm1_l2_s02', 1, FALSE, 0, FALSE),
      ('m1_l2', 'm1_l2_s03', 2, FALSE, 0, FALSE),
      ('m1_l2', 'm1_l2_s04', 3, FALSE, 0, FALSE),
      ('m1_l2', 'm1_l2_s05', 4, TRUE, 10, FALSE),
      ('m1_l2', 'm1_l2_s06', 5, FALSE, 0, FALSE),
      ('m1_l2', 'm1_l2_s07', 6, TRUE, 10, FALSE),
      ('m1_l2', 'm1_l2_s08', 7, TRUE, 10, FALSE),
      ('m1_l2', 'm1_l2_s09', 8, FALSE, 0, TRUE),
      ('m1_l3', 'm1_l3_s01', 0, FALSE, 0, FALSE),
      ('m1_l3', 'm1_l3_s02', 1, FALSE, 0, FALSE),
      ('m1_l3', 'm1_l3_s03', 2, FALSE, 0, FALSE),
      ('m1_l3', 'm1_l3_s04', 3, FALSE, 0, FALSE),
      ('m1_l3', 'm1_l3_s05', 4, TRUE, 10, FALSE),
      ('m1_l3', 'm1_l3_s06', 5, TRUE, 10, FALSE),
      ('m1_l3', 'm1_l3_s07', 6, FALSE, 0, FALSE),
      ('m1_l3', 'm1_l3_s08', 7, FALSE, 0, TRUE),
      ('m1_l4', 'm1_l4_s01', 0, FALSE, 0, FALSE),
      ('m1_l4', 'm1_l4_s02', 1, FALSE, 0, FALSE),
      ('m1_l4', 'm1_l4_s03', 2, FALSE, 0, FALSE),
      ('m1_l4', 'm1_l4_s04', 3, FALSE, 0, FALSE),
      ('m1_l4', 'm1_l4_s05', 4, FALSE, 0, FALSE),
      ('m1_l4', 'm1_l4_s06', 5, TRUE, 10, FALSE),
      ('m1_l4', 'm1_l4_s07', 6, TRUE, 10, FALSE),
      ('m1_l4', 'm1_l4_s08', 7, TRUE, 10, FALSE),
      ('m1_l4', 'm1_l4_s09', 8, FALSE, 0, TRUE),
      ('m1_l5', 'm1_l5_s01', 0, FALSE, 0, FALSE),
      ('m1_l5', 'm1_l5_s02', 1, FALSE, 0, FALSE),
      ('m1_l5', 'm1_l5_s03', 2, FALSE, 0, FALSE),
      ('m1_l5', 'm1_l5_s04', 3, FALSE, 0, FALSE),
      ('m1_l5', 'm1_l5_s05', 4, FALSE, 0, FALSE),
      ('m1_l5', 'm1_l5_s06', 5, TRUE, 10, FALSE),
      ('m1_l5', 'm1_l5_s07', 6, TRUE, 10, FALSE),
      ('m1_l5', 'm1_l5_s08', 7, TRUE, 10, FALSE),
      ('m1_l5', 'm1_l5_s09', 8, FALSE, 0, FALSE),
      ('m1_l5', 'm1_l5_s10', 9, FALSE, 0, TRUE),
      ('m1_l6', 'm1_l6_s01', 0, FALSE, 0, FALSE),
      ('m1_l6', 'm1_l6_s02', 1, FALSE, 0, FALSE),
      ('m1_l6', 'm1_l6_s03', 2, TRUE, 10, FALSE),
      ('m1_l6', 'm1_l6_s04', 3, FALSE, 0, FALSE),
      ('m1_l6', 'm1_l6_s05', 4, FALSE, 0, FALSE),
      ('m1_l6', 'm1_l6_s06', 5, FALSE, 0, FALSE),
      ('m1_l6', 'm1_l6_s07', 6, TRUE, 10, FALSE),
      ('m1_l6', 'm1_l6_s08', 7, TRUE, 10, FALSE),
      ('m1_l6', 'm1_l6_s09', 8, TRUE, 10, FALSE),
      ('m1_l6', 'm1_l6_s10', 9, FALSE, 0, TRUE)
  ),
  actual AS (
    SELECT lesson_id, step_id, step_index, is_answer_step, xp_reward, is_final
    FROM public.learning_step_catalog
    WHERE module_id = 'module1'
      AND lesson_id IN ('m1_l2', 'm1_l3', 'm1_l4', 'm1_l5', 'm1_l6')
      AND content_version = 1
  ),
  mismatch AS (
    (SELECT * FROM expected EXCEPT SELECT * FROM actual)
    UNION ALL
    (SELECT * FROM actual EXCEPT SELECT * FROM expected)
  )
  SELECT COUNT(*) INTO mismatch_count FROM mismatch;

  IF mismatch_count <> 0 THEN
    RAISE EXCEPTION 'Catalog exact-map mismatch count: %', mismatch_count;
  END IF;

  WITH expected_summary (
    lesson_id,
    row_count,
    answer_count,
    answer_reward,
    final_step_id
  ) AS (
    VALUES
      ('m1_l2', 9, 3, 30, 'm1_l2_s09'),
      ('m1_l3', 8, 2, 20, 'm1_l3_s08'),
      ('m1_l4', 9, 3, 30, 'm1_l4_s09'),
      ('m1_l5', 10, 3, 30, 'm1_l5_s10'),
      ('m1_l6', 10, 4, 40, 'm1_l6_s10')
  ),
  actual_summary AS (
    SELECT
      lesson_id,
      COUNT(*)::INTEGER AS row_count,
      COUNT(*) FILTER (WHERE is_answer_step)::INTEGER AS answer_count,
      COALESCE(SUM(xp_reward) FILTER (WHERE is_answer_step), 0)::INTEGER
        AS answer_reward,
      MAX(step_id) FILTER (WHERE is_final) AS final_step_id
    FROM public.learning_step_catalog
    WHERE module_id = 'module1'
      AND lesson_id IN ('m1_l2', 'm1_l3', 'm1_l4', 'm1_l5', 'm1_l6')
      AND content_version = 1
    GROUP BY lesson_id
  ),
  invalid AS (
    (SELECT * FROM expected_summary EXCEPT SELECT * FROM actual_summary)
    UNION ALL
    (SELECT * FROM actual_summary EXCEPT SELECT * FROM expected_summary)
  )
  SELECT COUNT(*) INTO invalid_summary_count FROM invalid;

  IF invalid_summary_count <> 0 THEN
    RAISE EXCEPTION 'Catalog summary mismatch count: %', invalid_summary_count;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.learning_step_catalog
    WHERE module_id = 'module1' AND lesson_id = 'm1_l7'
  ) THEN
    RAISE EXCEPTION 'm1_l7 must not be cataloged by the Lessons 1.2-1.6 release';
  END IF;

  SELECT pg_get_functiondef(
    'public.record_lesson_step(text,text,text,integer,boolean,integer)'::regprocedure
  )
  INTO function_definition;

  IF STRPOS(function_definition, 'v_required_answers') = 0
     OR STRPOS(function_definition, 'v_correct_answers') = 0
     OR STRPOS(function_definition, 'v_catalog.is_final') = 0 THEN
    RAISE EXCEPTION 'RPC no longer requires all catalog answer steps';
  END IF;

  IF STRPOS(function_definition, '''lesson_completion''') = 0
     OR STRPOS(function_definition, 'v_completion_xp') = 0
     OR function_definition !~ '[[:space:]]25[[:space:]]' THEN
    RAISE EXCEPTION 'RPC no longer grants the existing 25 completion XP';
  END IF;
END;
$$;

ROLLBACK;
