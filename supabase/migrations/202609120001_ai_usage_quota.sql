-- Per-user hourly quota for the server-side AI proxy.
--
-- The provider keys (Gemini, Groq, NVIDIA) moved out of the app bundle and
-- into Edge Function secrets, so they can no longer be extracted from an
-- installed APK. What that alone does NOT stop is a signed-in learner calling
-- the proxy in a loop and spending the project's credits, so every proxied
-- call first has to buy a slot here.
--
-- Apply after 202608120001_account_progress.sql. This migration is rerunnable.
--
-- Design note: the counter is written only inside a SECURITY DEFINER function
-- and the table carries no INSERT or UPDATE grant, so a learner cannot reset
-- their own usage. Calling consume_ai_quota directly only spends their own
-- allowance, which is why EXECUTE is safe to grant.

BEGIN;

-- ============================================================================
-- 1. Usage counter
-- ============================================================================
-- One row per (user, task, hour). Hour buckets keep the table small and make
-- "resets at" a value we can show the learner rather than a mystery.

CREATE TABLE IF NOT EXISTS public.ai_usage_quota (
  user_id UUID NOT NULL DEFAULT auth.uid()
    REFERENCES auth.users(id) ON DELETE CASCADE,
  task TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  request_count INT NOT NULL DEFAULT 0,
  last_request_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, task, window_start),
  CONSTRAINT ai_usage_quota_task_valid CHECK (
    task = BTRIM(task)
    AND CHAR_LENGTH(task) BETWEEN 1 AND 32
    AND task ~ '^[a-z0-9_-]+$'
  ),
  CONSTRAINT ai_usage_quota_count_valid CHECK (
    request_count BETWEEN 0 AND 100000
  ),
  CONSTRAINT ai_usage_quota_window_aligned CHECK (
    window_start = date_trunc('hour', window_start)
  )
);

COMMENT ON TABLE public.ai_usage_quota IS
  'Hourly AI proxy call counts, one row per user per task per hour.';
COMMENT ON COLUMN public.ai_usage_quota.request_count IS
  'Capped at the task limit plus one, so a refused caller stops incrementing.';

CREATE INDEX IF NOT EXISTS ai_usage_quota_window_idx
  ON public.ai_usage_quota (window_start);

-- ============================================================================
-- 2. Limits
-- ============================================================================
-- Deliberately generous for a real learner and useless for a scraper. A quiz
-- is one call per attempt; tutor feedback fires per note or worked example.

CREATE OR REPLACE FUNCTION public.algebrix_ai_task_limit(p_task TEXT)
RETURNS INT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_task
    WHEN 'quiz' THEN 20
    WHEN 'tutor' THEN 60
    ELSE 0
  END;
$$;

COMMENT ON FUNCTION public.algebrix_ai_task_limit(TEXT) IS
  'Requests allowed per user per hour for a proxied AI task; 0 means unknown.';

-- ============================================================================
-- 3. Spend one request
-- ============================================================================

CREATE OR REPLACE FUNCTION public.consume_ai_quota(p_task TEXT)
RETURNS TABLE (
  allowed BOOLEAN,
  used INT,
  hourly_limit INT,
  resets_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
  v_window TIMESTAMPTZ := date_trunc('hour', NOW());
  v_limit INT;
  v_count INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required.'
      USING ERRCODE = '28000';
  END IF;

  v_limit := public.algebrix_ai_task_limit(p_task);
  IF v_limit = 0 THEN
    RAISE EXCEPTION 'Unknown AI task: %', p_task
      USING ERRCODE = '22023';
  END IF;

  -- Old buckets are dead weight once their hour has passed. Pruning on a small
  -- fraction of calls keeps the table bounded without needing pg_cron.
  IF random() < 0.02 THEN
    DELETE FROM public.ai_usage_quota
    WHERE window_start < NOW() - INTERVAL '2 days';
  END IF;

  INSERT INTO public.ai_usage_quota AS q (
    user_id,
    task,
    window_start,
    request_count,
    last_request_at
  )
  VALUES (caller, p_task, v_window, 1, NOW())
  ON CONFLICT (user_id, task, window_start)
  DO UPDATE SET
    -- Stop counting one past the limit: a refused caller should not be able to
    -- inflate the row forever.
    request_count = LEAST(q.request_count + 1, v_limit + 1),
    last_request_at = NOW()
  RETURNING q.request_count INTO v_count;

  RETURN QUERY SELECT
    v_count <= v_limit,
    v_count,
    v_limit,
    v_window + INTERVAL '1 hour';
END;
$$;

COMMENT ON FUNCTION public.consume_ai_quota(TEXT) IS
  'Spends one AI proxy request for the caller and reports whether it was allowed.';

-- ============================================================================
-- 4. Read your own usage
-- ============================================================================
-- Lets the app show "you have used 4 of 20 quizzes this hour" without spending
-- a request to find out.

CREATE OR REPLACE FUNCTION public.ai_quota_status(p_task TEXT)
RETURNS TABLE (
  used INT,
  hourly_limit INT,
  resets_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
  caller UUID := auth.uid();
  v_window TIMESTAMPTZ := date_trunc('hour', NOW());
  v_limit INT;
BEGIN
  IF caller IS NULL THEN
    RAISE EXCEPTION 'An authenticated session is required.'
      USING ERRCODE = '28000';
  END IF;

  v_limit := public.algebrix_ai_task_limit(p_task);
  IF v_limit = 0 THEN
    RAISE EXCEPTION 'Unknown AI task: %', p_task
      USING ERRCODE = '22023';
  END IF;

  RETURN QUERY
  SELECT
    COALESCE(q.request_count, 0),
    v_limit,
    v_window + INTERVAL '1 hour'
  FROM (SELECT 1) AS anchor
  LEFT JOIN public.ai_usage_quota AS q
    ON q.user_id = caller
   AND q.task = p_task
   AND q.window_start = v_window;
END;
$$;

COMMENT ON FUNCTION public.ai_quota_status(TEXT) IS
  'Reports the caller''s AI proxy usage for the current hour without spending one.';

-- ============================================================================
-- 5. Row level security and grants
-- ============================================================================

ALTER TABLE public.ai_usage_quota ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own AI usage" ON public.ai_usage_quota;

CREATE POLICY "Users can view own AI usage"
  ON public.ai_usage_quota
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- No INSERT, UPDATE or DELETE grant anywhere: every write goes through
-- consume_ai_quota, which runs as the definer.
REVOKE ALL ON TABLE public.ai_usage_quota FROM anon, authenticated;
GRANT SELECT ON TABLE public.ai_usage_quota TO authenticated;

REVOKE ALL ON FUNCTION public.consume_ai_quota(TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.ai_quota_status(TEXT) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.algebrix_ai_task_limit(TEXT) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.consume_ai_quota(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ai_quota_status(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.algebrix_ai_task_limit(TEXT) TO authenticated;

-- PostgREST receives this after commit and refreshes its schema cache.
NOTIFY pgrst, 'reload schema';

COMMIT;
