-- Module 3 catalog extension for Lessons 3.1 through 3.8.
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

-- Insert all step definitions for Module 3 Lessons 1 through 8.
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
  -- Lesson 3.1: Understanding Equations (6 steps)
  ('module3', 'm3_l1', 'm3_l1_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l1', 'm3_l1_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l1', 'm3_l1_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l1', 'm3_l1_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l1', 'm3_l1_s05', 1, 4, TRUE, 10, FALSE),
  ('module3', 'm3_l1', 'm3_l1_s06', 1, 5, FALSE, 0, TRUE),

  -- Lesson 3.2: Inverse Operations (7 steps)
  ('module3', 'm3_l2', 'm3_l2_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l2', 'm3_l2_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l2', 'm3_l2_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l2', 'm3_l2_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l2', 'm3_l2_s05', 1, 4, FALSE, 0, FALSE),
  ('module3', 'm3_l2', 'm3_l2_s06', 1, 5, TRUE, 10, FALSE),
  ('module3', 'm3_l2', 'm3_l2_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 3.3: One-Step Equations (7 steps)
  ('module3', 'm3_l3', 'm3_l3_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l3', 'm3_l3_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l3', 'm3_l3_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l3', 'm3_l3_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l3', 'm3_l3_s05', 1, 4, FALSE, 0, FALSE),
  ('module3', 'm3_l3', 'm3_l3_s06', 1, 5, TRUE, 10, FALSE),
  ('module3', 'm3_l3', 'm3_l3_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 3.4: Two-Step Equations (8 steps)
  ('module3', 'm3_l4', 'm3_l4_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s05', 1, 4, FALSE, 0, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s06', 1, 5, FALSE, 0, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s07', 1, 6, TRUE, 10, FALSE),
  ('module3', 'm3_l4', 'm3_l4_s08', 1, 7, FALSE, 0, TRUE),

  -- Lesson 3.5: Variables on Both Sides (6 steps)
  ('module3', 'm3_l5', 'm3_l5_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l5', 'm3_l5_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l5', 'm3_l5_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l5', 'm3_l5_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l5', 'm3_l5_s05', 1, 4, FALSE, 0, FALSE),
  ('module3', 'm3_l5', 'm3_l5_s06', 1, 5, FALSE, 0, TRUE),

  -- Lesson 3.6: Equations with Parentheses (6 steps)
  ('module3', 'm3_l6', 'm3_l6_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l6', 'm3_l6_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l6', 'm3_l6_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l6', 'm3_l6_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l6', 'm3_l6_s05', 1, 4, TRUE, 10, FALSE),
  ('module3', 'm3_l6', 'm3_l6_s06', 1, 5, FALSE, 0, TRUE),

  -- Lesson 3.7: Checking Solutions (6 steps)
  ('module3', 'm3_l7', 'm3_l7_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l7', 'm3_l7_s02', 1, 1, FALSE, 0, FALSE),
  ('module3', 'm3_l7', 'm3_l7_s03', 1, 2, FALSE, 0, FALSE),
  ('module3', 'm3_l7', 'm3_l7_s04', 1, 3, FALSE, 0, FALSE),
  ('module3', 'm3_l7', 'm3_l7_s05', 1, 4, TRUE, 10, FALSE),
  ('module3', 'm3_l7', 'm3_l7_s06', 1, 5, FALSE, 0, TRUE),

  -- Lesson 3.8: Module 3 Challenge (12 steps)
  ('module3', 'm3_l8', 'm3_l8_s01', 1, 0, FALSE, 0, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s02', 1, 1, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s03', 1, 2, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s04', 1, 3, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s05', 1, 4, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s06', 1, 5, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s07', 1, 6, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s08', 1, 7, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s09', 1, 8, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s10', 1, 9, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s11', 1, 10, TRUE, 10, FALSE),
  ('module3', 'm3_l8', 'm3_l8_s12', 1, 11, FALSE, 0, TRUE)
ON CONFLICT (module_id, lesson_id, step_id, content_version)
DO UPDATE SET
  step_index = EXCLUDED.step_index,
  is_answer_step = EXCLUDED.is_answer_step,
  xp_reward = EXCLUDED.xp_reward,
  is_final = EXCLUDED.is_final;

COMMIT;
