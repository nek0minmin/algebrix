# 📖 Algebrix API Documentation

This document provides complete technical specifications for all external and backend REST APIs integrated into the **Algebrix** application.

---

## 📑 Table of Contents
1. [Supabase REST & Authentication API](#1-supabase-rest--authentication-api)
2. [Google Gemini AI Tutor API](#2-google-gemini-ai-tutor-api)
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

## 2. Google Gemini AI Tutor API

### Overview
* **Base URL**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent`
* **Protocol**: HTTPS REST POST
* **Authentication**: API Key via URL Parameter (`?key=YOUR_GEMINI_API_KEY`)

### Request Specification
* **Method**: `POST`
* **Headers**: `Content-Type: application/json`
* **Request Body**:
```json
{
  "contents": [
    {
      "parts": [
        {
          "text": "Explain in simple terms why subtracting 6 from both sides of 2x + 6 = 18 helps isolate x."
        }
      ]
    }
  ]
}
```

### Response Specification
* **Response (200 OK)**:
```json
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Subtracting 6 removes the constant on the left, leaving 2x = 12. Because we did it to both sides, the balance is maintained!"
          }
        ]
      }
    }
  ]
}
```

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
