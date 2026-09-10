-- Module 4 catalog extension for Lessons 4.1 through 4.5 (Inequalities).
-- Requires 202608120001_account_progress.sql. This migration is rerunnable.
--
-- xp_reward is 0 throughout: Algebrix no longer has a points economy, and the
-- column is retained only so the existing record_lesson_step RPC signature
-- stays untouched.

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

-- Insert all step definitions for Module 4 Lessons 1 through 5.
-- Generated directly from lib/data/module4/ so the catalog cannot drift from
-- the shipped lesson content.
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
  -- Lesson 4.1: Understanding Inequalities (9 steps)
  ('module4', 'm4_l1', 'm4_l1_s01', 1, 0, FALSE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s02', 1, 1, FALSE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s03', 1, 2, FALSE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s04', 1, 3, FALSE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s05', 1, 4, FALSE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s06', 1, 5, TRUE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s07', 1, 6, FALSE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s08', 1, 7, TRUE, 0, FALSE),
  ('module4', 'm4_l1', 'm4_l1_s09', 1, 8, FALSE, 0, TRUE),

  -- Lesson 4.2: One-Step Inequalities (10 steps)
  ('module4', 'm4_l2', 'm4_l2_s01', 1, 0, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s02', 1, 1, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s03', 1, 2, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s04', 1, 3, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s05', 1, 4, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s06', 1, 5, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s07', 1, 6, TRUE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s08', 1, 7, FALSE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s09', 1, 8, TRUE, 0, FALSE),
  ('module4', 'm4_l2', 'm4_l2_s10', 1, 9, FALSE, 0, TRUE),

  -- Lesson 4.3: The Negative Number Rule (9 steps)
  ('module4', 'm4_l3', 'm4_l3_s01', 1, 0, FALSE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s02', 1, 1, FALSE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s03', 1, 2, FALSE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s04', 1, 3, TRUE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s05', 1, 4, FALSE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s06', 1, 5, FALSE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s07', 1, 6, FALSE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s08', 1, 7, TRUE, 0, FALSE),
  ('module4', 'm4_l3', 'm4_l3_s09', 1, 8, FALSE, 0, TRUE),

  -- Lesson 4.4: Two-Step Inequalities (10 steps)
  ('module4', 'm4_l4', 'm4_l4_s01', 1, 0, FALSE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s02', 1, 1, FALSE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s03', 1, 2, FALSE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s04', 1, 3, FALSE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s05', 1, 4, FALSE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s06', 1, 5, TRUE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s07', 1, 6, FALSE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s08', 1, 7, TRUE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s09', 1, 8, TRUE, 0, FALSE),
  ('module4', 'm4_l4', 'm4_l4_s10', 1, 9, FALSE, 0, TRUE),

  -- Lesson 4.5: Graphing Inequalities (11 steps)
  ('module4', 'm4_l5', 'm4_l5_s01', 1, 0, FALSE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s02', 1, 1, FALSE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s03', 1, 2, FALSE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s04', 1, 3, FALSE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s05', 1, 4, FALSE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s06', 1, 5, TRUE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s07', 1, 6, TRUE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s08', 1, 7, TRUE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s09', 1, 8, TRUE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s10', 1, 9, TRUE, 0, FALSE),
  ('module4', 'm4_l5', 'm4_l5_s11', 1, 10, FALSE, 0, TRUE)

ON CONFLICT (module_id, lesson_id, step_id, content_version)
DO UPDATE SET
  step_index = EXCLUDED.step_index,
  is_answer_step = EXCLUDED.is_answer_step,
  xp_reward = EXCLUDED.xp_reward,
  is_final = EXCLUDED.is_final;

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
