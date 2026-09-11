// Algebrix AI proxy.
//
// Every AI call the app makes now goes through here. The provider keys live in
// Edge Function secrets and never reach the device, which is the whole point:
// before this, `.env` shipped inside the APK and anyone could unzip it.
//
// Deploy:
//   supabase functions deploy ai-proxy
//
// Secrets (set once, never committed):
//   supabase secrets set GEMINI_API_KEY=...
//   supabase secrets set GROQ_API_KEY=...
//   supabase secrets set NVIDIA_API_KEY=...
//
// Requires migration 202609120001_ai_usage_quota.sql for the per-user limit.

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.45.4';

// ---------------------------------------------------------------------------
// Limits
// ---------------------------------------------------------------------------
// Sized for the real prompts: a module quiz system prompt is a little over
// 4 KB. Anything far past that is not Algebrix asking.

const MAX_SYSTEM_CHARS = 24_000;
const MAX_USER_CHARS = 8_000;
const MAX_OUTPUT_TOKENS = 4_096;
const UPSTREAM_TIMEOUT_MS = 20_000;

/** Which providers each task may use, in order of preference. */
const TASK_PROVIDERS: Record<string, readonly string[]> = {
  quiz: ['gemini', 'groq', 'nvidia'],
  tutor: ['groq', 'nvidia'],
};

const GROQ_MODELS = [
  'openai/gpt-oss-120b',
  'openai/gpt-oss-20b',
  'qwen/qwen3.6-27b',
];

const GEMINI_MODELS = [
  'gemini-2.5-flash',
  'gemini-2.5-flash-lite',
  'gemini-flash-latest',
  'gemini-2.5-pro',
];

const NVIDIA_MODEL = 'meta/llama-3.3-70b-instruct';

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface ProxyRequest {
  task: string;
  system: string;
  user: string;
  jsonMode?: boolean;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, 'Content-Type': 'application/json' },
  });
}

function fail(code: string, message: string, status: number, extra: Record<string, unknown> = {}) {
  return json({ error: message, code, ...extra }, status);
}

/**
 * Validates the request body. Returns the parsed request or an error string —
 * never a partially trusted object.
 */
function parseRequest(raw: unknown): ProxyRequest | string {
  if (typeof raw !== 'object' || raw === null) return 'Body must be a JSON object.';
  const body = raw as Record<string, unknown>;

  const task = body.task;
  if (typeof task !== 'string' || !(task in TASK_PROVIDERS)) {
    return `Unknown task. Expected one of: ${Object.keys(TASK_PROVIDERS).join(', ')}.`;
  }

  const system = body.system;
  if (typeof system !== 'string' || system.trim().length === 0) {
    return 'system must be a non-empty string.';
  }
  if (system.length > MAX_SYSTEM_CHARS) {
    return `system exceeds ${MAX_SYSTEM_CHARS} characters.`;
  }

  const user = body.user;
  if (typeof user !== 'string' || user.trim().length === 0) {
    return 'user must be a non-empty string.';
  }
  if (user.length > MAX_USER_CHARS) {
    return `user exceeds ${MAX_USER_CHARS} characters.`;
  }

  const jsonMode = body.jsonMode;
  if (jsonMode !== undefined && typeof jsonMode !== 'boolean') {
    return 'jsonMode must be a boolean.';
  }

  return { task, system, user, jsonMode: jsonMode ?? true };
}

async function postJson(
  url: string,
  headers: Record<string, string>,
  body: unknown,
): Promise<Response> {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), UPSTREAM_TIMEOUT_MS);
  try {
    return await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...headers },
      body: JSON.stringify(body),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timer);
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
// Each returns the raw completion text, or throws. The chain and the model
// lists are the same ones the Dart services used to walk client-side.

async function callOpenAiCompatible(
  label: string,
  url: string,
  apiKey: string,
  models: readonly string[],
  req: ProxyRequest,
): Promise<{ text: string; provider: string }> {
  let lastError: unknown;

  for (const model of models) {
    try {
      const payload: Record<string, unknown> = {
        model,
        messages: [
          { role: 'system', content: req.system },
          { role: 'user', content: req.user },
        ],
        temperature: 0.3,
        max_tokens: MAX_OUTPUT_TOKENS,
      };
      if (req.jsonMode) payload.response_format = { type: 'json_object' };

      const response = await postJson(url, { Authorization: `Bearer ${apiKey}` }, payload);

      if (!response.ok) {
        // The upstream body can echo request details; keep it server-side.
        lastError = new Error(`${label} ${model} returned ${response.status}`);
        continue;
      }

      const data = await response.json();
      const text = data?.choices?.[0]?.message?.content;
      if (typeof text !== 'string' || text.length === 0) {
        lastError = new Error(`${label} ${model} returned no content`);
        continue;
      }

      return { text, provider: `${label} (${model})` };
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? new Error(`All ${label} models failed.`);
}

async function callGemini(
  apiKey: string,
  req: ProxyRequest,
): Promise<{ text: string; provider: string }> {
  let lastError: unknown;

  for (const model of GEMINI_MODELS) {
    try {
      const response = await postJson(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`,
        { 'x-goog-api-key': apiKey },
        {
          contents: [{ parts: [{ text: `${req.system}\n\n${req.user}` }] }],
          generationConfig: {
            temperature: 0.7,
            maxOutputTokens: MAX_OUTPUT_TOKENS,
            ...(req.jsonMode ? { responseMimeType: 'application/json' } : {}),
          },
        },
      );

      if (!response.ok) {
        lastError = new Error(`Gemini ${model} returned ${response.status}`);
        continue;
      }

      const data = await response.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (typeof text !== 'string' || text.length === 0) {
        lastError = new Error(`Gemini ${model} returned no content`);
        continue;
      }

      return { text, provider: `Gemini (${model})` };
    } catch (error) {
      lastError = error;
    }
  }

  throw lastError ?? new Error('All Gemini models failed.');
}

async function runProvider(
  name: string,
  req: ProxyRequest,
): Promise<{ text: string; provider: string }> {
  switch (name) {
    case 'gemini': {
      const key = Deno.env.get('GEMINI_API_KEY');
      if (!key) throw new Error('GEMINI_API_KEY is not configured.');
      return await callGemini(key, req);
    }
    case 'groq': {
      const key = Deno.env.get('GROQ_API_KEY');
      if (!key) throw new Error('GROQ_API_KEY is not configured.');
      return await callOpenAiCompatible(
        'Groq',
        'https://api.groq.com/openai/v1/chat/completions',
        key,
        GROQ_MODELS,
        req,
      );
    }
    case 'nvidia': {
      const key = Deno.env.get('NVIDIA_API_KEY');
      if (!key) throw new Error('NVIDIA_API_KEY is not configured.');
      return await callOpenAiCompatible(
        'NVIDIA NIM',
        'https://integrate.api.nvidia.com/v1/chat/completions',
        key,
        [NVIDIA_MODEL],
        req,
      );
    }
    default:
      throw new Error(`Unsupported provider: ${name}`);
  }
}

// ---------------------------------------------------------------------------
// Handler
// ---------------------------------------------------------------------------

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (request.method !== 'POST') {
    return fail('method_not_allowed', 'Use POST.', 405);
  }

  const authorization = request.headers.get('Authorization') ?? '';
  if (!authorization.toLowerCase().startsWith('bearer ')) {
    return fail('unauthenticated', 'A signed-in session is required.', 401);
  }

  let parsedBody: unknown;
  try {
    parsedBody = await request.json();
  } catch {
    return fail('bad_request', 'Body must be valid JSON.', 400);
  }

  const parsed = parseRequest(parsedBody);
  if (typeof parsed === 'string') {
    return fail('bad_request', parsed, 400);
  }

  // The caller's own JWT is forwarded, so auth.uid() resolves inside the
  // database and the quota is charged to the right learner.
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? '',
    { global: { headers: { Authorization: authorization } } },
  );

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) {
    return fail('unauthenticated', 'A signed-in session is required.', 401);
  }

  const { data: quota, error: quotaError } = await supabase
    .rpc('consume_ai_quota', { p_task: parsed.task })
    .single();

  if (quotaError) {
    console.error('quota error', quotaError.message);
    return fail('quota_unavailable', 'Could not check your AI usage.', 503);
  }

  if (!quota?.allowed) {
    return fail(
      'rate_limited',
      'You have used this hour\'s AI requests. Algebrix will use its offline question bank until it resets.',
      429,
      { hourlyLimit: quota?.hourly_limit, resetsAt: quota?.resets_at },
    );
  }

  const providers = TASK_PROVIDERS[parsed.task];
  const failures: string[] = [];

  for (const name of providers) {
    try {
      const { text, provider } = await runProvider(name, parsed);
      return json({ text, provider }, 200);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      failures.push(`${name}: ${message}`);
      console.error(`provider ${name} failed`, message);
    }
  }

  // The app has its own offline fallback, so this is a soft failure for the
  // learner: the seed bank takes over.
  return fail('providers_unavailable', 'No AI provider answered.', 502, {
    tried: failures.length,
  });
});
