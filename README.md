# Algebrix

A Flutter algebra-learning app for Grade 7–8 learners, backed by Supabase.
Six modules, 41 lessons, AI-generated module quizzes, study notes with inline
correction, and a mastery/spaced-review system.

## Running it

```bash
flutter pub get
flutter run
```

The app needs **no local secrets**. Supabase's project URL and publishable anon
key are compile-time constants in `lib/core/constants/app_constants.dart`; the
anon key is meant to be public and is protected by row level security.

## Backend setup

### 1. Migrations

Apply everything in `supabase/migrations/` in filename order. Each migration is
rerunnable, so applying one twice is harmless.

Until a module's catalog migration is applied, lesson progress for that module
silently fails to save — `record_lesson_step` rejects steps it does not know.

### 2. AI proxy

Provider keys live in Edge Function secrets, never in the app bundle.

```bash
supabase functions deploy ai-proxy

supabase secrets set GEMINI_API_KEY=...
supabase secrets set GROQ_API_KEY=...
supabase secrets set NVIDIA_API_KEY=...
```

`supabase/migrations/202609120001_ai_usage_quota.sql` must be applied first —
the function charges a per-user hourly quota before spending an upstream call.

If the proxy is not deployed the app still works: quizzes fall back to a curated
offline seed bank and Xy falls back to offline hints.

See [API.md](API.md) for the full endpoint specification.

## Tests

```bash
flutter analyze
flutter test
```

CI runs both on every push and pull request (`.github/workflows/ci.yml`).

`test/no_bundled_secrets_test.dart` is a standing guard: it fails if an env file
is ever added back to the asset bundle, if `flutter_dotenv` returns, or if any
code under `lib/` starts calling an AI provider directly instead of going
through `AiGateway`.
