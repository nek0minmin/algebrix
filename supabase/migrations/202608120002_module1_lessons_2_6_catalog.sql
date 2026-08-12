-- Module 1 catalog extension for Lessons 1.2 through 1.6.
-- Requires 202608120001_account_progress.sql.

BEGIN;

DO $$
BEGIN
  IF to_regclass('public.learning_step_catalog') IS NULL THEN
    RAISE EXCEPTION
      'public.learning_step_catalog is required; apply 202608120001 first';
  END IF;

  IF to_regprocedure(
    'public.record_lesson_step(text,text,text,integer,boolean,integer)'
  ) IS NULL THEN
    RAISE EXCEPTION
      'public.record_lesson_step is required; apply 202608120001 first';
  END IF;
END;
$$;

-- Prevent concurrent catalog migrations from interleaving validation.
LOCK TABLE public.learning_step_catalog IN SHARE ROW EXCLUSIVE MODE;

-- Catalog history is immutable after rewards can reference it. Conflicting
-- primary-key or lesson-index conflicts are left untouched and the exact-map
-- validation below fails if any existing row differs from this definition.
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
  ('module1', 'm1_l2', 'm1_l2_s01', 1, 0, FALSE, 0, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s02', 1, 1, FALSE, 0, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s03', 1, 2, FALSE, 0, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s04', 1, 3, FALSE, 0, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s05', 1, 4, TRUE, 10, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s06', 1, 5, FALSE, 0, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s07', 1, 6, TRUE, 10, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s08', 1, 7, TRUE, 10, FALSE),
  ('module1', 'm1_l2', 'm1_l2_s09', 1, 8, FALSE, 0, TRUE),

  ('module1', 'm1_l3', 'm1_l3_s01', 1, 0, FALSE, 0, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s02', 1, 1, FALSE, 0, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s03', 1, 2, FALSE, 0, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s04', 1, 3, FALSE, 0, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s05', 1, 4, TRUE, 10, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s06', 1, 5, TRUE, 10, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s07', 1, 6, FALSE, 0, FALSE),
  ('module1', 'm1_l3', 'm1_l3_s08', 1, 7, FALSE, 0, TRUE),

  ('module1', 'm1_l4', 'm1_l4_s01', 1, 0, FALSE, 0, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s02', 1, 1, FALSE, 0, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s03', 1, 2, FALSE, 0, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s04', 1, 3, FALSE, 0, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s05', 1, 4, FALSE, 0, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s06', 1, 5, TRUE, 10, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s07', 1, 6, TRUE, 10, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s08', 1, 7, TRUE, 10, FALSE),
  ('module1', 'm1_l4', 'm1_l4_s09', 1, 8, FALSE, 0, TRUE),

  ('module1', 'm1_l5', 'm1_l5_s01', 1, 0, FALSE, 0, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s02', 1, 1, FALSE, 0, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s03', 1, 2, FALSE, 0, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s04', 1, 3, FALSE, 0, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s05', 1, 4, FALSE, 0, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s06', 1, 5, TRUE, 10, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s07', 1, 6, TRUE, 10, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s08', 1, 7, TRUE, 10, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s09', 1, 8, FALSE, 0, FALSE),
  ('module1', 'm1_l5', 'm1_l5_s10', 1, 9, FALSE, 0, TRUE),

  ('module1', 'm1_l6', 'm1_l6_s01', 1, 0, FALSE, 0, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s02', 1, 1, FALSE, 0, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s03', 1, 2, TRUE, 10, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s04', 1, 3, FALSE, 0, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s05', 1, 4, FALSE, 0, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s06', 1, 5, FALSE, 0, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s07', 1, 6, TRUE, 10, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s08', 1, 7, TRUE, 10, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s09', 1, 8, TRUE, 10, FALSE),
  ('module1', 'm1_l6', 'm1_l6_s10', 1, 9, FALSE, 0, TRUE)
ON CONFLICT DO NOTHING;

-- Assert byte-for-byte catalog semantics instead of mutating prior history.
DO $$
DECLARE
  mismatch_count INTEGER;
  invalid_lesson_count INTEGER;
BEGIN
  WITH expected (
    module_id,
    lesson_id,
    step_id,
    content_version,
    step_index,
    is_answer_step,
    xp_reward,
    is_final
  ) AS (
    VALUES
      ('module1', 'm1_l2', 'm1_l2_s01', 1, 0, FALSE, 0, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s02', 1, 1, FALSE, 0, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s03', 1, 2, FALSE, 0, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s04', 1, 3, FALSE, 0, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s05', 1, 4, TRUE, 10, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s06', 1, 5, FALSE, 0, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s07', 1, 6, TRUE, 10, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s08', 1, 7, TRUE, 10, FALSE),
      ('module1', 'm1_l2', 'm1_l2_s09', 1, 8, FALSE, 0, TRUE),
      ('module1', 'm1_l3', 'm1_l3_s01', 1, 0, FALSE, 0, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s02', 1, 1, FALSE, 0, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s03', 1, 2, FALSE, 0, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s04', 1, 3, FALSE, 0, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s05', 1, 4, TRUE, 10, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s06', 1, 5, TRUE, 10, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s07', 1, 6, FALSE, 0, FALSE),
      ('module1', 'm1_l3', 'm1_l3_s08', 1, 7, FALSE, 0, TRUE),
      ('module1', 'm1_l4', 'm1_l4_s01', 1, 0, FALSE, 0, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s02', 1, 1, FALSE, 0, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s03', 1, 2, FALSE, 0, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s04', 1, 3, FALSE, 0, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s05', 1, 4, FALSE, 0, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s06', 1, 5, TRUE, 10, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s07', 1, 6, TRUE, 10, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s08', 1, 7, TRUE, 10, FALSE),
      ('module1', 'm1_l4', 'm1_l4_s09', 1, 8, FALSE, 0, TRUE),
      ('module1', 'm1_l5', 'm1_l5_s01', 1, 0, FALSE, 0, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s02', 1, 1, FALSE, 0, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s03', 1, 2, FALSE, 0, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s04', 1, 3, FALSE, 0, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s05', 1, 4, FALSE, 0, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s06', 1, 5, TRUE, 10, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s07', 1, 6, TRUE, 10, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s08', 1, 7, TRUE, 10, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s09', 1, 8, FALSE, 0, FALSE),
      ('module1', 'm1_l5', 'm1_l5_s10', 1, 9, FALSE, 0, TRUE),
      ('module1', 'm1_l6', 'm1_l6_s01', 1, 0, FALSE, 0, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s02', 1, 1, FALSE, 0, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s03', 1, 2, TRUE, 10, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s04', 1, 3, FALSE, 0, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s05', 1, 4, FALSE, 0, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s06', 1, 5, FALSE, 0, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s07', 1, 6, TRUE, 10, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s08', 1, 7, TRUE, 10, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s09', 1, 8, TRUE, 10, FALSE),
      ('module1', 'm1_l6', 'm1_l6_s10', 1, 9, FALSE, 0, TRUE)
  ),
  actual AS (
    SELECT
      module_id,
      lesson_id,
      step_id,
      content_version,
      step_index,
      is_answer_step,
      xp_reward,
      is_final
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
    RAISE EXCEPTION
      'Module 1 Lessons 1.2-1.6 catalog differs from the immutable v1 map (% mismatches)',
      mismatch_count;
  END IF;

  SELECT COUNT(*)
  INTO invalid_lesson_count
  FROM (
    SELECT
      lesson_id,
      COUNT(*) AS step_count,
      COUNT(DISTINCT step_index) AS distinct_index_count,
      MIN(step_index) AS minimum_index,
      MAX(step_index) AS maximum_index,
      COUNT(*) FILTER (WHERE is_final) AS final_count,
      MAX(step_index) FILTER (WHERE is_final) AS final_index,
      COUNT(*) FILTER (WHERE is_answer_step) AS answer_count,
      COUNT(*) FILTER (WHERE is_answer_step AND xp_reward = 10)
        AS valid_answer_reward_count,
      COUNT(*) FILTER (WHERE NOT is_answer_step AND xp_reward <> 0)
        AS invalid_nonanswer_reward_count
    FROM public.learning_step_catalog
    WHERE module_id = 'module1'
      AND lesson_id IN ('m1_l2', 'm1_l3', 'm1_l4', 'm1_l5', 'm1_l6')
      AND content_version = 1
    GROUP BY lesson_id
  ) AS lesson
  WHERE step_count <> distinct_index_count
     OR minimum_index <> 0
     OR maximum_index <> step_count - 1
     OR final_count <> 1
     OR final_index <> maximum_index
     OR answer_count = 0
     OR answer_count <> valid_answer_reward_count
     OR invalid_nonanswer_reward_count <> 0;

  IF invalid_lesson_count <> 0 THEN
    RAISE EXCEPTION
      'Module 1 Lessons 1.2-1.6 contain % structurally invalid catalogs',
      invalid_lesson_count;
  END IF;
END;
$$;

-- This migration adds rows only; PostgREST schema cache reload is unnecessary.
COMMIT;
