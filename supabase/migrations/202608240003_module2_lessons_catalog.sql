-- Module 2 catalog extension for Lessons 2.1 through 2.7.
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

-- Insert all step definitions for Module 2 Lessons 1 through 7.
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
  -- Lesson 2.1: Like and Unlike Terms (7 steps)
  ('module2', 'm2_l1', 'm2_l1_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l1', 'm2_l1_s02', 1, 1, FALSE, 0, FALSE),
  ('module2', 'm2_l1', 'm2_l1_s03', 1, 2, FALSE, 0, FALSE),
  ('module2', 'm2_l1', 'm2_l1_s04', 1, 3, FALSE, 0, FALSE),
  ('module2', 'm2_l1', 'm2_l1_s05', 1, 4, TRUE, 10, FALSE),
  ('module2', 'm2_l1', 'm2_l1_s06', 1, 5, TRUE, 10, FALSE),
  ('module2', 'm2_l1', 'm2_l1_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 2.2: Combining Like Terms (7 steps)
  ('module2', 'm2_l2', 'm2_l2_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l2', 'm2_l2_s02', 1, 1, FALSE, 0, FALSE),
  ('module2', 'm2_l2', 'm2_l2_s03', 1, 2, FALSE, 0, FALSE),
  ('module2', 'm2_l2', 'm2_l2_s04', 1, 3, FALSE, 0, FALSE),
  ('module2', 'm2_l2', 'm2_l2_s05', 1, 4, TRUE, 10, FALSE),
  ('module2', 'm2_l2', 'm2_l2_s06', 1, 5, FALSE, 0, FALSE),
  ('module2', 'm2_l2', 'm2_l2_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 2.3: Distributive Property (7 steps)
  ('module2', 'm2_l3', 'm2_l3_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l3', 'm2_l3_s02', 1, 1, FALSE, 0, FALSE),
  ('module2', 'm2_l3', 'm2_l3_s03', 1, 2, FALSE, 0, FALSE),
  ('module2', 'm2_l3', 'm2_l3_s04', 1, 3, FALSE, 0, FALSE),
  ('module2', 'm2_l3', 'm2_l3_s05', 1, 4, TRUE, 10, FALSE),
  ('module2', 'm2_l3', 'm2_l3_s06', 1, 5, FALSE, 0, FALSE),
  ('module2', 'm2_l3', 'm2_l3_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 2.4: Properties of Operations (8 steps)
  ('module2', 'm2_l4', 'm2_l4_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s02', 1, 1, FALSE, 0, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s03', 1, 2, FALSE, 0, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s04', 1, 3, FALSE, 0, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s05', 1, 4, FALSE, 0, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s06', 1, 5, FALSE, 0, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s07', 1, 6, TRUE, 10, FALSE),
  ('module2', 'm2_l4', 'm2_l4_s08', 1, 7, FALSE, 0, TRUE),

  -- Lesson 2.5: Simplifying Expressions (7 steps)
  ('module2', 'm2_l5', 'm2_l5_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l5', 'm2_l5_s02', 1, 1, FALSE, 0, FALSE),
  ('module2', 'm2_l5', 'm2_l5_s03', 1, 2, FALSE, 0, FALSE),
  ('module2', 'm2_l5', 'm2_l5_s04', 1, 3, FALSE, 0, FALSE),
  ('module2', 'm2_l5', 'm2_l5_s05', 1, 4, FALSE, 0, FALSE),
  ('module2', 'm2_l5', 'm2_l5_s06', 1, 5, TRUE, 10, FALSE),
  ('module2', 'm2_l5', 'm2_l5_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 2.6: Evaluating Expressions (7 steps)
  ('module2', 'm2_l6', 'm2_l6_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l6', 'm2_l6_s02', 1, 1, FALSE, 0, FALSE),
  ('module2', 'm2_l6', 'm2_l6_s03', 1, 2, FALSE, 0, FALSE),
  ('module2', 'm2_l6', 'm2_l6_s04', 1, 3, FALSE, 0, FALSE),
  ('module2', 'm2_l6', 'm2_l6_s05', 1, 4, TRUE, 10, FALSE),
  ('module2', 'm2_l6', 'm2_l6_s06', 1, 5, FALSE, 0, FALSE),
  ('module2', 'm2_l6', 'm2_l6_s07', 1, 6, FALSE, 0, TRUE),

  -- Lesson 2.7: Expression Challenge (12 steps)
  ('module2', 'm2_l7', 'm2_l7_s01', 1, 0, FALSE, 0, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s02', 1, 1, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s03', 1, 2, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s04', 1, 3, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s05', 1, 4, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s06', 1, 5, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s07', 1, 6, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s08', 1, 7, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s09', 1, 8, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s10', 1, 9, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s11', 1, 10, TRUE, 10, FALSE),
  ('module2', 'm2_l7', 'm2_l7_s12', 1, 11, FALSE, 0, TRUE)
ON CONFLICT (module_id, lesson_id, step_id, content_version) DO NOTHING;

COMMIT;
