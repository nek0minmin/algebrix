# 📖 Algebrix API Documentation

This document provides complete technical specifications for all external and backend REST APIs integrated into the **Algebrix** application.

---

## 📑 Table of Contents
1. [Supabase REST & Authentication API](#1-supabase-rest--authentication-api)
2. [Algebrix AI Proxy (Supabase Edge Function)](#2-algebrix-ai-proxy-supabase-edge-function)
3. [MathJS REST API](#3-mathjs-rest-api)
4. [Newton Math REST API](#4-newton-math-rest-api)

---

## 1. Supabase REST & Authentication API

### Overview
* **Base URL**: `https://<YOUR_SUPABASE_PROJECT_ID>.supabase.co`
* **Protocol**: HTTPS REST / Postgrest
* **Authentication**: Bearer Token / API Key in HTTP Headers.

### Common Required Headers
```http
apikey: <YOUR_SUPABASE_ANON_KEY>
Authorization: Bearer <USER_SESSION_JWT_TOKEN>
Content-Type: application/json
```

---

### Endpoints

#### A. User Signup (Authentication)
* **Endpoint**: `POST /auth/v1/signup`
* **Description**: Registers a new learner account and triggers automatic profile creation in `public.profiles`.
* **Request Body**:
```json
{
  "email": "learner@example.com",
  "password": "SecurePassword123!",
  "data": {
    "full_name": "Math Learner"
  }
}
```
* **Response (200 OK)**:
```json
{
  "id": "u1234567-89ab-cdef-0123-456789abcdef",
  "email": "learner@example.com",
  "created_at": "2026-08-19T12:00:00Z"
}
```

#### B. Fetch Study Notes (Read CRUD)
* **Endpoint**: `GET /rest/v1/study_notes?select=*&order=updated_at.desc`
* **Description**: Retrieves all study notes belonging to the authenticated learner. Enforced by Row Level Security (RLS).
* **Response (200 OK)**:
```json
[
  {
    "id": "note_01",
    "user_id": "u1234567-89ab-cdef-0123-456789abcdef",
    "module_id": "m1",
    "lesson_id": "m1_l2",
    "title": "Algebraic Variables",
    "content": "A variable represents an unknown quantity like x or y.",
    "created_at": "2026-08-19T10:00:00Z",
    "updated_at": "2026-08-19T10:30:00Z"
  }
]
```

#### C. Create Study Note (Create CRUD)
* **Endpoint**: `POST /rest/v1/study_notes`
* **Request Body**:
```json
{
  "module_id": "m1",
  "lesson_id": "m1_l2",
  "title": "Properties of Equality",
  "content": "Adding the same quantity to both sides preserves equality."
}
```
* **Response (201 Created)**: Returns inserted note JSON object.

#### D. Update Study Note (Update CRUD)
* **Endpoint**: `PATCH /rest/v1/study_notes?id=eq.<NOTE_ID>`
* **Request Body**:
```json
{
  "title": "Updated Title",
  "content": "Updated content..."
}
```
* **Response (200 OK)**: Returns updated note JSON object.

#### E. Delete Study Note (Delete CRUD)
* **Endpoint**: `DELETE /rest/v1/study_notes?id=eq.<NOTE_ID>`
* **Response (200 OK / 204 No Content)**: Deletes specified record.

---

## 2. Algebrix AI Proxy (Supabase Edge Function)

### Overview
Every AI call the app makes goes through one endpoint. The Gemini, Groq and
NVIDIA keys live in Edge Function secrets and never reach the device, so an
installed APK contains no provider credential.

* **Endpoint**: `POST https://<YOUR_SUPABASE_PROJECT_ID>.supabase.co/functions/v1/ai-proxy`
* **Protocol**: HTTPS REST POST
* **Authentication**: the learner's own Supabase session JWT. Anonymous calls are rejected with `401`.
* **Source**: `supabase/functions/ai-proxy/index.ts`
* **Client**: `lib/services/ai_gateway.dart`

### Deploying

```bash
supabase functions deploy ai-proxy

supabase secrets set GEMINI_API_KEY=...
supabase secrets set GROQ_API_KEY=...
supabase secrets set NVIDIA_API_KEY=...
```

Apply `supabase/migrations/202609120001_ai_usage_quota.sql` first — the
function refuses to spend an upstream call without it.

### Request Specification
* **Headers**:
```http
apikey: <YOUR_SUPABASE_ANON_KEY>
Authorization: Bearer <USER_SESSION_JWT_TOKEN>
Content-Type: application/json
```
* **Request Body**:
```json
{
  "task": "quiz",
  "system": "You are Xy, the expert educational AI quiz master in Algebrix...",
  "user": "Generate a fresh, unique 10-question progressive quiz for module5.",
  "jsonMode": true
}
```

| Field | Type | Notes |
|---|---|---|
| `task` | string | `quiz` or `tutor`. Decides the provider chain and the hourly limit. |
| `system` | string | Max 24,000 characters. |
| `user` | string | Max 8,000 characters. |
| `jsonMode` | boolean | Defaults to `true`. Set `false` for prose (note polishing). |

### Provider chain
| Task | Order | Hourly limit per learner |
|---|---|---|
| `quiz` | Gemini → Groq → NVIDIA NIM | 20 |
| `tutor` | Groq → NVIDIA NIM | 60 |

### Response Specification
* **Response (200 OK)**:
```json
{
  "text": "{\"questions\":[ ... ]}",
  "provider": "Gemini (gemini-2.5-flash)"
}
```
* **Errors**:

| Status | `code` | Meaning |
|---|---|---|
| 400 | `bad_request` | Unknown task, or a prompt over the size cap. |
| 401 | `unauthenticated` | No or invalid session JWT. |
| 429 | `rate_limited` | Hourly quota spent. Includes `resetsAt`. |
| 502 | `providers_unavailable` | No upstream provider answered. |
| 503 | `quota_unavailable` | The quota RPC could not be reached. |

Every error is a soft failure for the learner: `ModuleQuizService` falls back to
its offline seed bank and `AiTutorService` to its offline hints, so the app
stays usable with no network and no AI at all.

### Usage RPCs
* `consume_ai_quota(p_task text)` — spends one request, returns `allowed`, `used`, `hourly_limit`, `resets_at`. Called by the Edge Function, not the app.
* `ai_quota_status(p_task text)` — reads the current hour's usage without spending one.

---

## 3. MathJS REST API

### Overview
* **Base URL**: `https://api.mathjs.org/v4/`
* **Protocol**: HTTPS REST POST
* **Purpose**: Evaluates mathematical expressions and step-by-step equality for the Balance Scale visualizer.

### Request Specification
* **Method**: `POST`
* **Headers**: `Content-Type: application/json`
* **Request Body**:
```json
{
  "expr": [
    "x = 6",
    "left = 2 * x + 6 - 6",
    "right = 18 - 6"
  ]
}
```

### Response Specification
* **Response (200 OK)**:
```json
{
  "result": [
    "6",
    "12",
    "12"
  ],
  "error": null
}
```

---

## 4. Newton Math REST API

### Overview
* **Base URL**: `https://newton.vercel.app/api/v2/`
* **Protocol**: HTTPS REST GET
* **Purpose**: Simplifies algebraic expressions and factors terms for interactive activities.

### Endpoints

#### A. Simplify Expression
* **Endpoint**: `GET /api/v2/simplify/<URL_ENCODED_EXPRESSION>`
* **Example Request**: `GET https://newton.vercel.app/api/v2/simplify/2x%2B6-6`
* **Response (200 OK)**:
```json
{
  "operation": "simplify",
  "expression": "2x+6-6",
  "result": "2 x"
}
```

#### B. Factor Polynomial
* **Endpoint**: `GET /api/v2/factor/<URL_ENCODED_EXPRESSION>`
* **Example Request**: `GET https://newton.vercel.app/api/v2/factor/x%5E2-1`
* **Response (200 OK)**:
```json
{
  "operation": "factor",
  "expression": "x^2-1",
  "result": "(x - 1) (x + 1)"
}
```
